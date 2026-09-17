"""One-time local browser authorization for Gmail send access."""

from google_auth_oauthlib.flow import InstalledAppFlow

from app.services.gmail_auth import GMAIL_SCOPES, oauth_client_path, save_credentials, token_path


def main() -> None:
    client = oauth_client_path()
    if not client.is_file():
        raise SystemExit(f"OAuth desktop client file missing: {client}")
    flow = InstalledAppFlow.from_client_secrets_file(str(client), GMAIL_SCOPES)
    credentials = flow.run_local_server(port=0, access_type="offline", prompt="consent")
    if not credentials.refresh_token:
        raise SystemExit("Google did not return a refresh token. Authorization was not saved.")
    save_credentials(credentials)
    print(f"Gmail send authorization saved to {token_path()}")


if __name__ == "__main__":
    main()
