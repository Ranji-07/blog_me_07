import os
import logging

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse

from app.database import BASE_DIR, Base, engine
from app.routes.admin import router as admin_router
from app.routes.public import router as public_router

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

Base.metadata.create_all(bind=engine)


def _allowed_origins() -> list[str]:
    raw_origins = os.getenv("CORS_ALLOW_ORIGINS", "*")
    if raw_origins.strip() == "*":
        return ["*"]
    return [origin.strip() for origin in raw_origins.split(",") if origin.strip()]

app = FastAPI(
    title="Portfolio API",
    description="Professional Portfolio Management System with Email Control",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=_allowed_origins(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(public_router)
app.include_router(admin_router)


@app.get("/images/{filename}", tags=["Assets"])
async def get_image(filename: str):
    file_path = BASE_DIR / "uploaded_images" / filename
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="Image not found")
    return FileResponse(file_path)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        app,
        host=os.getenv("API_HOST", "0.0.0.0"),
        port=int(os.getenv("PORT", os.getenv("API_PORT", "8000"))),
    )
