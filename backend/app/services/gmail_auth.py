"""Local OAuth credentials for sending portfolio mail through Gmail."""

import os
from pathlib import Path

from app.database import PROJECT_DIR

GMAIL_SEND_SCOPE = "https://www.googleapis.com/auth/gmail.send"
GMAIL_SCOPES = [GMAIL_SEND_SCOPE]


def _secret_path(name: str, default: str) -> Path:
    configured = Path(os.getenv(name, default))
    return configured if configured.is_absolute() else PROJECT_DIR / configured


def oauth_client_path() -> Path:
    return _secret_path("GMAIL_OAUTH_CLIENT_FILE", ".secrets/gmail_client.json")


def token_path() -> Path:
    return _secret_path("GMAIL_TOKEN_FILE", ".secrets/gmail_token.json")


def load_send_credentials():
    """Load a previously authorized token; refresh it without a browser."""
    from google.auth.transport.requests import Request
    from google.oauth2.credentials import Credentials

    path = token_path()
    if not path.is_file():
        raise RuntimeError("Gmail is not authorized. Run: python -m app.authorize_gmail")
    credentials = Credentials.from_authorized_user_file(str(path), GMAIL_SCOPES)
    if not credentials.has_scopes(GMAIL_SCOPES):
        raise RuntimeError("Gmail token lacks gmail.send permission. Reauthorize Gmail.")
    if not credentials.valid:
        if not credentials.refresh_token:
            raise RuntimeError("Gmail token cannot refresh. Reauthorize Gmail.")
        credentials.refresh(Request())
        save_credentials(credentials)
    return credentials


def save_credentials(credentials) -> None:
    path = token_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(credentials.to_json(), encoding="utf-8")
    if os.name != "nt":
        temporary.chmod(0o600)
    temporary.replace(path)
