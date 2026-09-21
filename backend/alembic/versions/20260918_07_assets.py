"""Add metadata for managed portfolio assets."""
from alembic import op
import sqlalchemy as sa
revision = "20260918_07"
down_revision = "20260918_06"
branch_labels = None
depends_on = None
def upgrade():
    op.create_table("assets", sa.Column("id", sa.Integer(), primary_key=True), sa.Column("filename", sa.String(255), nullable=False, unique=True), sa.Column("storage_path", sa.String(500), nullable=False), sa.Column("mime_type", sa.String(100), nullable=False), sa.Column("file_size", sa.Integer(), nullable=False), sa.Column("asset_type", sa.String(32), nullable=False), sa.Column("associated_project_id", sa.Integer(), sa.ForeignKey("projects.id", ondelete="SET NULL")), sa.Column("is_public", sa.Boolean(), nullable=False, server_default=sa.false()), sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")))
    for name, col in (("ix_assets_filename", "filename"), ("ix_assets_asset_type", "asset_type"), ("ix_assets_associated_project_id", "associated_project_id"), ("ix_assets_is_public", "is_public")): op.create_index(name, "assets", [col])
def downgrade(): op.drop_table("assets")
