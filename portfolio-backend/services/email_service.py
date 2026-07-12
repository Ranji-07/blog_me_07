import logging
import os
import secrets
from datetime import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from pathlib import Path

import smtplib

from schemas import EmailCommandRequest
from utils.time import utc_display, utc_now

logger = logging.getLogger(__name__)

SMTP_SERVER = os.getenv("SMTP_SERVER", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_EMAIL = os.getenv("SMTP_EMAIL")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD")
ADMIN_EMAIL = os.getenv("ADMIN_EMAIL")
ADMIN_API_KEY = os.getenv("ADMIN_API_KEY")
EMAIL_DELIVERY_MODE = os.getenv("EMAIL_DELIVERY_MODE", "log").strip().lower()
EMAIL_OUTBOX_DIR = Path(os.getenv("EMAIL_OUTBOX_DIR", "./dev_outbox"))


def get_email_delivery_mode() -> str:
    return EMAIL_DELIVERY_MODE


def can_send_real_email() -> bool:
    return EMAIL_DELIVERY_MODE == "smtp" and all([SMTP_EMAIL, SMTP_PASSWORD, ADMIN_EMAIL])


def is_email_configured() -> bool:
    if EMAIL_DELIVERY_MODE in {"log", "disabled"}:
        return True
    return can_send_real_email()


def _render_email_html(body: str) -> str:
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }}
            .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
            .header {{ background: linear-gradient(135deg, #00C6FF 0%, #9333EA 100%); color: white; padding: 20px; border-radius: 10px 10px 0 0; }}
            .content {{ background: #1E1E2C; color: #E2E8F0; padding: 20px; border-radius: 0 0 10px 10px; }}
            .button {{ display: inline-block; background: linear-gradient(135deg, #00C6FF, #9333EA); color: white; padding: 12px 24px; text-decoration: none; border-radius: 25px; margin: 10px 0; }}
            pre {{ background: #0F172A; padding: 15px; border-radius: 8px; overflow-x: auto; }}
            code {{ color: #00C6FF; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h2 style="margin:0;">Portfolio Admin</h2>
            </div>
            <div class="content">
                {body}
            </div>
        </div>
    </body>
    </html>
    """


def _write_email_to_outbox(to_email: str, subject: str, html_body: str) -> Path:
    EMAIL_OUTBOX_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    safe_name = "".join(char if char.isalnum() else "-" for char in subject.lower()).strip("-") or "message"
    output_path = EMAIL_OUTBOX_DIR / f"{timestamp}-{safe_name}.html"
    output_path.write_text(
        "\n".join(
            [
                f"<!-- TO: {to_email} -->",
                f"<!-- SUBJECT: {subject} -->",
                f"<!-- GENERATED_AT: {utc_display(utc_now())} -->",
                html_body,
            ]
        ),
        encoding="utf-8",
    )
    return output_path


def send_email(to_email: str, subject: str, body: str) -> bool:
    html_body = _render_email_html(body)

    if EMAIL_DELIVERY_MODE == "disabled":
        logger.info("Email delivery disabled. Skipping send for subject '%s'.", subject)
        return False

    if EMAIL_DELIVERY_MODE == "log":
        output_path = _write_email_to_outbox(to_email, subject, html_body)
        logger.info("Email written to dev outbox: %s", output_path)
        return True

    if not all([SMTP_EMAIL, SMTP_PASSWORD, ADMIN_EMAIL]):
        logger.warning("SMTP email not fully configured. Skipping email send.")
        return False

    try:
        msg = MIMEMultipart("alternative")
        msg["From"] = SMTP_EMAIL
        msg["To"] = to_email
        msg["Subject"] = subject
        msg.attach(MIMEText(html_body, "html"))

        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_EMAIL, SMTP_PASSWORD)
            server.send_message(msg)

        logger.info("Email sent to %s: %s", to_email, subject)
        return True
    except Exception as exc:
        logger.error("Email error: %s", exc)
        return False


def generate_confirmation_token() -> str:
    return secrets.token_urlsafe(32)


def build_confirmation_email(command: EmailCommandRequest, confirmation_url: str) -> str:
    import json

    payload_json = json.dumps(command.payload, indent=2)
    return f"""
    <h2>Confirm Portfolio Update</h2>
    <p>A portfolio admin action is pending confirmation.</p>
    <ul>
      <li><strong>Action:</strong> {command.action.value}</li>
      <li><strong>Section:</strong> {command.section.value}</li>
      <li><strong>Target ID:</strong> {command.target_id or 'section-root'}</li>
    </ul>
    <pre>{payload_json}</pre>
    <p><a href="{confirmation_url}" class="button">Confirm Action</a></p>
    <p style="color:#94A3B8;">This link expires in 24 hours.</p>
    """


def build_success_email(action: str, section: str, detail: str) -> str:
    return f"""
    <h2>Portfolio Action Completed</h2>
    <p><strong>Action:</strong> {action}</p>
    <p><strong>Section:</strong> {section}</p>
    <p>{detail}</p>
    """
