import logging
import re
import os
import json
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, PlainTextResponse

from app.config import settings
from app.database import BASE_DIR
from app.routes.admin import router as admin_router
from app.routes.auth import router as auth_router
from app.routes.public import router as public_router
from app.routes.assets import router as assets_router
from app.database import SessionLocal
from app.models import Asset
from app.services.metrics import metrics

class JsonFormatter(logging.Formatter):
    def format(self, record):
        return json.dumps({"level": record.levelname, "logger": record.name, "message": record.getMessage()})

handler = logging.StreamHandler()
handler.setFormatter(JsonFormatter())
logging.basicConfig(level=logging.INFO, handlers=[handler], force=True)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(_: FastAPI):
    logger.info("application_started environment=%s", settings.environment)
    yield
    logger.info("application_stopped")

app = FastAPI(
    title="Portfolio API",
    description="Professional Portfolio Management System with Email Control",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=list(settings.cors_allow_origins),
    allow_origin_regex=settings.cors_allow_origin_regex,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(public_router)
app.include_router(auth_router)
app.include_router(admin_router)
app.include_router(assets_router)


@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    started = time.perf_counter()
    try:
        response = await call_next(request)
    except Exception:
        metrics.inc("http_errors_total", 'status="500"')
        logger.exception("request_failed method=%s path=%s", request.method, request.url.path)
        raise
    elapsed = time.perf_counter() - started
    metrics.inc("http_requests_total", f'method="{request.method}",status="{response.status_code}"')
    metrics.observe("http_request_latency", elapsed)
    if response.status_code >= 400:
        metrics.inc("http_errors_total", f'status="{response.status_code}"')
    logger.info("request_completed method=%s path=%s status=%s duration_ms=%.1f", request.method, request.url.path, response.status_code, elapsed * 1000)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "no-referrer"
    response.headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()"
    return response


@app.get("/metrics", include_in_schema=False)
async def prometheus_metrics():
    return PlainTextResponse(metrics.render(), media_type="text/plain; version=0.0.4")


@app.get("/images/{filename}", tags=["Assets"])
async def get_image(filename: str):
    if not re.fullmatch(r"[A-Za-z0-9_-]+\.(?:jpg|png|gif|webp|svg)", filename):
        raise HTTPException(status_code=404, detail="Image not found")
    file_path = BASE_DIR / "uploaded_images" / filename
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="Image not found")
    db = SessionLocal()
    try:
        asset = db.query(Asset).filter(Asset.filename == filename).one_or_none()
        if asset is not None and not asset.is_public:
            raise HTTPException(status_code=404, detail="Image not found")
    finally:
        db.close()
    return FileResponse(file_path)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        app,
        host=os.getenv("API_HOST", "0.0.0.0"),
        port=int(os.getenv("PORT", os.getenv("API_PORT", "8000"))),
    )
