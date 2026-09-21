"""Add CMS-specific project and journey fields."""

from alembic import op
import sqlalchemy as sa


revision = "20260918_03"
down_revision = "20260918_02"
branch_labels = None
depends_on = None


def upgrade() -> None:
    with op.batch_alter_table("projects") as batch:
        batch.add_column(sa.Column("start_date", sa.String(length=32), nullable=True))
        batch.add_column(sa.Column("end_date", sa.String(length=32), nullable=True))
        batch.add_column(sa.Column("associated_with", sa.String(length=255), nullable=True))
    with op.batch_alter_table("journey_events") as batch:
        batch.add_column(sa.Column("parent_milestone", sa.String(length=255), nullable=True))
        batch.add_column(sa.Column("certification_info", sa.JSON(), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table("journey_events") as batch:
        batch.drop_column("certification_info")
        batch.drop_column("parent_milestone")
    with op.batch_alter_table("projects") as batch:
        batch.drop_column("associated_with")
        batch.drop_column("end_date")
        batch.drop_column("start_date")
