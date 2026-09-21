"""Protected upload and management endpoints for portfolio assets."""
from pathlib import Path
from uuid import uuid4
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from sqlalchemy.orm import Session
from app.database import BASE_DIR, get_db
from app.models import AdminUser, Asset, Project
from app.services.auth import get_current_admin

router = APIRouter(prefix="/api/admin/assets", tags=["Admin assets"])
UPLOAD_DIR = BASE_DIR / "uploaded_images"
MAX_BYTES = 5 * 1024 * 1024
ALLOWED = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp", "image/gif": ".gif", "image/svg+xml": ".svg", "application/pdf": ".pdf"}
TYPES = {"project_image", "company_logo", "skill_icon", "certification"}

def _serialize(asset: Asset): return {"id": asset.id, "filename": asset.filename, "url": f"/images/{asset.filename}" if asset.is_public and asset.mime_type != "application/pdf" else None, "mime_type": asset.mime_type, "file_size": asset.file_size, "asset_type": asset.asset_type, "associated_project_id": asset.associated_project_id, "is_public": asset.is_public, "created_at": asset.created_at}

@router.post("", status_code=status.HTTP_201_CREATED)
async def upload_asset(file: UploadFile = File(...), asset_type: str = Form(...), associated_project_id: int | None = Form(None), is_public: bool = Form(False), _: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    if asset_type not in TYPES: raise HTTPException(422, "Unsupported asset type")
    if file.content_type not in ALLOWED: raise HTTPException(415, "Unsupported file type")
    if associated_project_id and db.query(Project.id).filter(Project.id == associated_project_id).scalar() is None: raise HTTPException(422, "Unknown project")
    content = await file.read(MAX_BYTES + 1)
    if not content or len(content) > MAX_BYTES: raise HTTPException(413, "File must be between 1 byte and 5 MB")
    extension = ALLOWED[file.content_type]
    if file.content_type == "image/svg+xml" and b"<svg" not in content[:500].lower(): raise HTTPException(415, "Invalid SVG")
    filename = f"{uuid4().hex}{extension}"
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    path = UPLOAD_DIR / filename
    path.write_bytes(content)
    asset = Asset(filename=filename, storage_path=str(path.relative_to(BASE_DIR)), mime_type=file.content_type, file_size=len(content), asset_type=asset_type, associated_project_id=associated_project_id, is_public=is_public)
    db.add(asset); db.commit(); db.refresh(asset)
    return _serialize(asset)

@router.get("")
async def list_assets(_: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)): return {"assets": [_serialize(asset) for asset in db.query(Asset).order_by(Asset.created_at.desc()).all()]}

@router.delete("/{asset_id}")
async def delete_asset(asset_id: int, _: AdminUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    asset = db.query(Asset).filter(Asset.id == asset_id).one_or_none()
    if asset is None: raise HTTPException(404, "Asset not found")
    path = BASE_DIR / asset.storage_path
    if path.parent.resolve() != UPLOAD_DIR.resolve(): raise HTTPException(409, "Invalid asset storage path")
    if path.exists(): path.unlink()
    db.delete(asset); db.commit()
    return {"status": "success", "message": "Asset deleted"}
