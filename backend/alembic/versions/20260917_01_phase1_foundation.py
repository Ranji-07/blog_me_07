"""Create the Phase 1 database foundation safely for existing installations."""

from alembic import op
import sqlalchemy as sa


revision = "20260917_01"
down_revision = None
branch_labels = None
depends_on = None


def _table_names(bind) -> set[str]:
    return set(sa.inspect(bind).get_table_names())


def _column_names(bind, table_name: str) -> set[str]:
    return {column["name"] for column in sa.inspect(bind).get_columns(table_name)}


def _index_names(bind, table_name: str) -> set[str]:
    return {index["name"] for index in sa.inspect(bind).get_indexes(table_name)}


def _add_column_if_missing(bind, table_name: str, column: sa.Column) -> None:
    if column.name not in _column_names(bind, table_name):
        with op.batch_alter_table(table_name) as batch:
            batch.add_column(column)


def upgrade() -> None:
    bind = op.get_bind()
    tables = _table_names(bind)
    timestamp = sa.DateTime(timezone=True)

    if "portfolio_data" not in tables:
        op.create_table(
            "portfolio_data",
            sa.Column("id", sa.Integer(), primary_key=True),
            sa.Column("section", sa.String(length=50), nullable=False, unique=True),
            sa.Column("content", sa.Text(), nullable=False),
            sa.Column("created_at", timestamp, nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
            sa.Column("updated_at", timestamp, nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
            sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        )
        op.create_index("ix_portfolio_data_section", "portfolio_data", ["section"])
    else:
        _add_column_if_missing(bind, "portfolio_data", sa.Column("created_at", timestamp, nullable=True))
        _add_column_if_missing(bind, "portfolio_data", sa.Column("updated_at", timestamp, nullable=True))

    if "contact_submissions" not in tables:
        op.create_table(
            "contact_submissions",
            sa.Column("id", sa.Integer(), primary_key=True),
            sa.Column("name", sa.String(length=100), nullable=False),
            sa.Column("email", sa.String(length=255), nullable=False),
            sa.Column("message", sa.Text(), nullable=False),
            sa.Column("created_at", timestamp, nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
            sa.Column("updated_at", timestamp, nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
            sa.Column("is_read", sa.Boolean(), nullable=False, server_default=sa.false()),
        )
    else:
        _add_column_if_missing(bind, "contact_submissions", sa.Column("updated_at", timestamp, nullable=True))

    if "visit_logs" not in tables:
        op.create_table(
            "visit_logs",
            sa.Column("id", sa.Integer(), primary_key=True),
            sa.Column("ip", sa.String(length=64), nullable=True),
            sa.Column("user_agent", sa.Text(), nullable=True),
            sa.Column("visited_at", timestamp, nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        )
        op.create_index("ix_visit_logs_visited_at", "visit_logs", ["visited_at"])

    if "projects" not in tables:
        op.create_table(
            "projects",
            sa.Column("id", sa.Integer(), primary_key=True),
            sa.Column("source_id", sa.String(length=100), nullable=False, unique=True),
            sa.Column("title", sa.String(length=255), nullable=False),
            sa.Column("slug", sa.String(length=255), nullable=False, unique=True),
            sa.Column("category", sa.String(length=100), nullable=False),
            sa.Column("timeline_date", sa.String(length=32)),
            sa.Column("timeline_parent", sa.String(length=255)),
            sa.Column("short_description", sa.Text()),
            sa.Column("description", sa.Text()),
            sa.Column("technologies", sa.JSON(), nullable=False),
            sa.Column("features", sa.JSON(), nullable=False),
            sa.Column("images", sa.JSON(), nullable=False),
            sa.Column("github_url", sa.String(length=2048)),
            sa.Column("live_demo_url", sa.String(length=2048)),
            sa.Column("featured", sa.Boolean(), nullable=False, server_default=sa.false()),
            sa.Column("status", sa.String(length=32), nullable=False, server_default="published"),
            sa.Column("created_at", timestamp, nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
            sa.Column("updated_at", timestamp, nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        )
        for name, columns in (
            ("ix_projects_source_id", ["source_id"]), ("ix_projects_slug", ["slug"]),
            ("ix_projects_category", ["category"]), ("ix_projects_timeline_date", ["timeline_date"]),
            ("ix_projects_featured", ["featured"]), ("ix_projects_status", ["status"]),
        ):
            op.create_index(name, "projects", columns)

    tables = _table_names(bind)
    if "journey_events" not in tables:
        op.create_table(
            "journey_events",
            sa.Column("id", sa.Integer(), primary_key=True),
            sa.Column("source_id", sa.String(length=100), nullable=False, unique=True),
            sa.Column("event_type", sa.String(length=50), nullable=False),
            sa.Column("date_label", sa.String(length=100), nullable=False),
            sa.Column("timeline_date", sa.String(length=32)),
            sa.Column("organization", sa.String(length=255), nullable=False),
            sa.Column("title", sa.String(length=255), nullable=False),
            sa.Column("timeline_label", sa.String(length=255)),
            sa.Column("description", sa.Text()),
            sa.Column("technologies", sa.JSON(), nullable=False),
            sa.Column("highlights", sa.JSON(), nullable=False),
            sa.Column("is_current", sa.Boolean(), nullable=False, server_default=sa.false()),
            sa.Column("display_order", sa.Integer(), nullable=False, server_default="0"),
            sa.Column("project_id", sa.Integer(), sa.ForeignKey("projects.id", ondelete="SET NULL")),
            sa.Column("created_at", timestamp, nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
            sa.Column("updated_at", timestamp, nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        )
        for name, columns in (
            ("ix_journey_events_source_id", ["source_id"]), ("ix_journey_events_event_type", ["event_type"]),
            ("ix_journey_events_timeline_date", ["timeline_date"]), ("ix_journey_events_organization", ["organization"]),
            ("ix_journey_events_is_current", ["is_current"]), ("ix_journey_events_project_id", ["project_id"]),
        ):
            op.create_index(name, "journey_events", columns)

    if "skill_categories" not in tables:
        op.create_table(
            "skill_categories",
            sa.Column("id", sa.Integer(), primary_key=True),
            sa.Column("name", sa.String(length=150), nullable=False, unique=True),
            sa.Column("display_order", sa.Integer(), nullable=False, server_default="0"),
            sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
            sa.Column("created_at", timestamp, nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
            sa.Column("updated_at", timestamp, nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        )
        op.create_index("ix_skill_categories_is_active", "skill_categories", ["is_active"])

    if "skills" not in tables:
        op.create_table(
            "skills",
            sa.Column("id", sa.Integer(), primary_key=True),
            sa.Column("category_id", sa.Integer(), sa.ForeignKey("skill_categories.id", ondelete="CASCADE"), nullable=False),
            sa.Column("name", sa.String(length=150), nullable=False),
            sa.Column("icon", sa.String(length=255)),
            sa.Column("display_order", sa.Integer(), nullable=False, server_default="0"),
            sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
            sa.Column("created_at", timestamp, nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
            sa.Column("updated_at", timestamp, nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
            sa.UniqueConstraint("category_id", "name", name="uq_skill_category_name"),
        )
        op.create_index("ix_skills_category_id", "skills", ["category_id"])
        op.create_index("ix_skills_is_active", "skills", ["is_active"])

    if "email_events" not in tables:
        op.create_table(
            "email_events",
            sa.Column("id", sa.Integer(), primary_key=True),
            sa.Column("contact_submission_id", sa.Integer(), sa.ForeignKey("contact_submissions.id", ondelete="CASCADE")),
            sa.Column("event_type", sa.String(length=80), nullable=False),
            sa.Column("recipient", sa.String(length=255), nullable=False),
            sa.Column("provider", sa.String(length=80), nullable=False, server_default="gmail_api"),
            sa.Column("delivery_status", sa.String(length=32), nullable=False, server_default="pending"),
            sa.Column("provider_message_id", sa.String(length=255)),
            sa.Column("error_message", sa.Text()),
            sa.Column("created_at", timestamp, nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
            sa.Column("updated_at", timestamp, nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        )
        for name, columns in (
            ("ix_email_events_contact_submission_id", ["contact_submission_id"]),
            ("ix_email_events_event_type", ["event_type"]), ("ix_email_events_recipient", ["recipient"]),
            ("ix_email_events_delivery_status", ["delivery_status"]),
            ("ix_email_events_provider_message_id", ["provider_message_id"]),
        ):
            op.create_index(name, "email_events", columns)


def downgrade() -> None:
    # Preserve legacy content, contact, and analytics tables on downgrade.
    for table_name in ("email_events", "skills", "skill_categories", "journey_events", "projects"):
        if table_name in _table_names(op.get_bind()):
            op.drop_table(table_name)
