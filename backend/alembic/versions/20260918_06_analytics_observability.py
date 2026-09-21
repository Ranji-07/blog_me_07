"""Add privacy-aware analytics dimensions."""
from alembic import op
import sqlalchemy as sa

revision = "20260918_06"
down_revision = "20260918_05"
branch_labels = None
depends_on = None

def upgrade() -> None:
    with op.batch_alter_table("visit_logs") as batch:
        batch.add_column(sa.Column("visit_id", sa.String(64), nullable=True))
        batch.add_column(sa.Column("page", sa.String(255), nullable=True))
        batch.add_column(sa.Column("device_type", sa.String(32), nullable=True))
        batch.add_column(sa.Column("browser", sa.String(64), nullable=True))
        batch.add_column(sa.Column("operating_system", sa.String(64), nullable=True))
        batch.add_column(sa.Column("referrer", sa.String(255), nullable=True))
        batch.add_column(sa.Column("session_id", sa.String(64), nullable=True))
    for name, column, unique in (("ix_visit_logs_visit_id", "visit_id", True), ("ix_visit_logs_page", "page", False), ("ix_visit_logs_device_type", "device_type", False), ("ix_visit_logs_session_id", "session_id", False)):
        op.create_index(name, "visit_logs", [column], unique=unique)

def downgrade() -> None:
    for name in ("ix_visit_logs_session_id", "ix_visit_logs_device_type", "ix_visit_logs_page", "ix_visit_logs_visit_id"): op.drop_index(name, table_name="visit_logs")
    with op.batch_alter_table("visit_logs") as batch:
        for column in ("session_id", "referrer", "operating_system", "browser", "device_type", "page", "visit_id"): batch.drop_column(column)
