"""Add durable delivery payloads and retry metadata to email events."""

from alembic import op
import sqlalchemy as sa

revision = "20260918_05"
down_revision = "20260918_04"
branch_labels = None
depends_on = None


def upgrade() -> None:
    with op.batch_alter_table("email_events") as batch:
        batch.add_column(sa.Column("subject", sa.String(length=500), nullable=True))
        batch.add_column(sa.Column("html_body", sa.Text(), nullable=True))
        batch.add_column(sa.Column("plain_body", sa.Text(), nullable=True))
        batch.add_column(sa.Column("reply_to", sa.String(length=255), nullable=True))
        batch.add_column(sa.Column("attempts", sa.Integer(), nullable=False, server_default="0"))
        batch.add_column(sa.Column("sent_at", sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table("email_events") as batch:
        batch.drop_column("sent_at")
        batch.drop_column("attempts")
        batch.drop_column("reply_to")
        batch.drop_column("plain_body")
        batch.drop_column("html_body")
        batch.drop_column("subject")
