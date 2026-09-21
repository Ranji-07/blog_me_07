"""Add draft publishing metadata and immutable CMS content versions."""

from alembic import op
import sqlalchemy as sa


revision = "20260918_04"
down_revision = "20260918_03"
branch_labels = None
depends_on = None


def upgrade() -> None:
    timestamp = sa.DateTime(timezone=True)
    with op.batch_alter_table("portfolio_data") as batch:
        batch.add_column(sa.Column("version", sa.Integer(), nullable=False, server_default="1"))
        batch.add_column(sa.Column("published_at", timestamp, nullable=True))
    with op.batch_alter_table("projects") as batch:
        batch.add_column(sa.Column("version", sa.Integer(), nullable=False, server_default="1"))
        batch.add_column(sa.Column("published_at", timestamp, nullable=True))
    with op.batch_alter_table("journey_events") as batch:
        batch.add_column(sa.Column("status", sa.String(length=32), nullable=False, server_default="published"))
        batch.add_column(sa.Column("version", sa.Integer(), nullable=False, server_default="1"))
        batch.add_column(sa.Column("published_at", timestamp, nullable=True))
    op.create_index("ix_journey_events_status", "journey_events", ["status"])
    with op.batch_alter_table("skills") as batch:
        batch.add_column(sa.Column("status", sa.String(length=32), nullable=False, server_default="published"))
        batch.add_column(sa.Column("version", sa.Integer(), nullable=False, server_default="1"))
        batch.add_column(sa.Column("published_at", timestamp, nullable=True))
    op.create_index("ix_skills_status", "skills", ["status"])
    op.create_table(
        "content_versions",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("content_type", sa.String(length=32), nullable=False),
        sa.Column("content_id", sa.String(length=100), nullable=False),
        sa.Column("version", sa.Integer(), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False, server_default="draft"),
        sa.Column("snapshot", sa.JSON(), nullable=False),
        sa.Column("changed_by", sa.String(length=255), nullable=False),
        sa.Column("action", sa.String(length=32), nullable=False),
        sa.Column("changed_at", timestamp, nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column("published_at", timestamp, nullable=True),
        sa.UniqueConstraint("content_type", "content_id", "version", name="uq_content_version"),
    )
    for name, columns in (
        ("ix_content_versions_content_type", ["content_type"]),
        ("ix_content_versions_content_id", ["content_id"]),
        ("ix_content_versions_status", ["status"]),
        ("ix_content_versions_changed_by", ["changed_by"]),
        ("ix_content_versions_action", ["action"]),
        ("ix_content_versions_changed_at", ["changed_at"]),
    ):
        op.create_index(name, "content_versions", columns)


def downgrade() -> None:
    op.drop_table("content_versions")
    op.drop_index("ix_skills_status", table_name="skills")
    with op.batch_alter_table("skills") as batch:
        batch.drop_column("published_at")
        batch.drop_column("version")
        batch.drop_column("status")
    op.drop_index("ix_journey_events_status", table_name="journey_events")
    with op.batch_alter_table("journey_events") as batch:
        batch.drop_column("published_at")
        batch.drop_column("version")
        batch.drop_column("status")
    with op.batch_alter_table("projects") as batch:
        batch.drop_column("published_at")
        batch.drop_column("version")
    with op.batch_alter_table("portfolio_data") as batch:
        batch.drop_column("published_at")
        batch.drop_column("version")
