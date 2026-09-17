import logging
import os
import base64
from datetime import datetime
from email.message import EmailMessage
from pathlib import Path
from string import Template

from app.database import PROJECT_DIR
from app.services.gmail_auth import token_path, load_send_credentials
from app.utils.time import utc_display, utc_now

logger = logging.getLogger(__name__)

ADMIN_EMAIL = os.getenv("ADMIN_EMAIL", "ranjithvijay1225@gmail.com")
ADMIN_API_KEY = os.getenv("ADMIN_API_KEY")
GMAIL_SENDER_EMAIL = os.getenv("GMAIL_SENDER_EMAIL", ADMIN_EMAIL)
EMAIL_DELIVERY_MODE = os.getenv("EMAIL_DELIVERY_MODE", "log").strip().lower()
EMAIL_OUTBOX_DIR = Path(os.getenv("EMAIL_OUTBOX_DIR", "./dev_outbox"))
TEMPLATE_DIR = PROJECT_DIR.parent / "email_template"


def render_template(name: str, *, css_name: str, **values: str) -> str:
    html = (TEMPLATE_DIR / name).read_text(encoding="utf-8")
    css = (TEMPLATE_DIR / css_name).read_text(encoding="utf-8")
    return Template(html).substitute(css=css, **values)


def can_send_real_email() -> bool:
    return EMAIL_DELIVERY_MODE == "gmail_api" and bool(GMAIL_SENDER_EMAIL and ADMIN_EMAIL and token_path().is_file())


def is_email_configured() -> bool:
    if EMAIL_DELIVERY_MODE == "log":
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


def send_email(to_email: str, subject: str, body: str, *, reply_to: str | None = None, plain_body: str | None = None) -> bool:
    html_body = body if body.lstrip().lower().startswith("<!doctype html>") else _render_email_html(body)

    if EMAIL_DELIVERY_MODE == "disabled":
        logger.info("Email delivery disabled. Skipping send for subject '%s'.", subject)
        return False

    if EMAIL_DELIVERY_MODE == "log":
        output_path = _write_email_to_outbox(to_email, subject, html_body)
        logger.info("Email written to dev outbox: %s", output_path)
        return True

    if EMAIL_DELIVERY_MODE != "gmail_api":
        logger.error("Unknown email delivery mode: %s", EMAIL_DELIVERY_MODE)
        return False

    if not can_send_real_email():
        logger.warning("Gmail API is not configured or authorized. Skipping email send.")
        return False

    try:
        from googleapiclient.discovery import build

        msg = EmailMessage()
        msg["From"] = GMAIL_SENDER_EMAIL
        msg["To"] = to_email
        msg["Subject"] = subject
        if reply_to:
            msg["Reply-To"] = reply_to
        msg.set_content(plain_body or "Portfolio message. Please view the HTML version.")
        msg.add_alternative(html_body, subtype="html")
        encoded = base64.urlsafe_b64encode(msg.as_bytes()).decode("ascii")
        gmail = build("gmail", "v1", credentials=load_send_credentials(), cache_discovery=False)
        result = gmail.users().messages().send(userId="me", body={"raw": encoded}).execute()
        logger.info("Gmail accepted email to %s: message_id=%s", to_email, result.get("id"))
        return True
    except Exception as exc:
        logger.error("Gmail send failed: %s", exc)
        return False
