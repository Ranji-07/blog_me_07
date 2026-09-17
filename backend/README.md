# Portfolio backend

FastAPI serves portfolio JSON, stores contact submissions, and emails both sides of a new conversation. Content upload and email approval routes are not active.

## Local setup

From `backend/`:

```bat
py -3.12 -m venv .venv312
.\.venv312\Scripts\pip install -r requirements.txt
.\.venv312\Scripts\python -m app.init_db
.\start-local.bat
```

`init_db` copies `content/*.json` into the database. Run it for a new database or when you deliberately want to replace the stored sections. `start-local.bat` only starts the API and does not reseed. API: `http://127.0.0.1:8000`; API docs: `/docs`.

## Gmail API for contact mail

The contact form saves the visitor's name, email, and message. It sends an owner notification to `ADMIN_EMAIL` with `Reply-To` set to the visitor, then sends the visitor a copy with `Reply-To` set to the owner. Both can continue in their normal email inboxes. The API requests only Google's `gmail.send` permission; it does not read the inbox.

1. In Google Cloud, enable the Gmail API, configure the OAuth consent screen, and create an **OAuth client ID for a Desktop app**. Use the Google account you want to send from as a test user if the consent screen requests one. Follow the [official Python setup](https://developers.google.com/workspace/gmail/api/quickstart/python).
2. Download the client JSON into `backend/.secrets/gmail_client.json`. Never commit or share this file.
3. In the ignored `backend/.env`, set `EMAIL_DELIVERY_MODE=gmail_api`, `ADMIN_EMAIL=ranjithvijay1225@gmail.com`, and `GMAIL_SENDER_EMAIL=ranjithvijay1225@gmail.com`. Set `ADMIN_API_KEY` for the contact-submission admin endpoints. The optional paths `GMAIL_OAUTH_CLIENT_FILE` and `GMAIL_TOKEN_FILE` default to `.secrets/gmail_client.json` and `.secrets/gmail_token.json` relative to `backend/`.
4. Run `.\.venv312\Scripts\python -m app.authorize_gmail` from `backend/`, sign in with the same Gmail account, and approve the send-only permission. The refresh token is saved in `backend/.secrets/gmail_token.json`. Treat it as a password and keep it in persistent private storage.
5. Start the API, submit the contact form, and verify both inbox copies and their Reply-To addresses. The server returns an error when the owner notification fails. If the owner receives it but the visitor copy fails, the response reports that partial delivery.

For local template review without Google authorization, set `EMAIL_DELIVERY_MODE=log`; messages are written to `backend/dev_outbox/`. `disabled` prevents contact submissions from claiming email delivery.

Deployment needs the OAuth client and token files in private persistent storage. The checked-in `render.yaml` does not provision that storage by itself. The OAuth desktop flow is a local setup path; choose a suitable server-side credential storage and consent design before production deployment.

## Content and admin data

Edit `content/*.json` and validate/reseed deliberately until a new content management flow is planned. The runtime schemas are in `app/schema_files/`; `email_template/JSON_FIELDS.md` lists current fields and values. No public or admin endpoint currently uploads JSON/images, emails content approvals, or changes portfolio sections. Existing historical database tables are left in place so old databases remain readable.

`GET /api/admin/submissions`, `DELETE /api/admin/submissions/{id}`, and `POST /api/admin/submissions/purge` require `auth_email=ADMIN_EMAIL` and the `X-Admin-Token` header. Contact retention defaults to 90 days.
