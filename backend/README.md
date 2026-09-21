# Portfolio backend

FastAPI serves portfolio JSON, stores contact submissions, and emails both sides of a new conversation. Content upload and email approval routes are not active.

The backend uses PostgreSQL in production and SQLite for lightweight local development. Database structure is managed through Alembic migrations; the application does not create tables at import time.

## Local setup

From `backend/`:

```bat
py -3.12 -m venv .venv312
.\.venv312\Scripts\pip install -r requirements.txt
.\.venv312\Scripts\python -m alembic upgrade head
.\.venv312\Scripts\python -m app.init_db
.\start-local.bat
```

`init_db` validates `content/*.json` and inserts only records that do not already exist. It will not replace stored data. To deliberately synchronize existing JSON-backed records, run `python -m app.init_db --force`. `start-local.bat` applies pending migrations and performs the safe seed before starting the API. API: `http://127.0.0.1:8000`; API docs: `/docs`.

For PostgreSQL, set `DATABASE_URL` in the ignored `.env`, for example:

```text
DATABASE_URL=postgresql+psycopg2://portfolio_user:strong-password@localhost:5432/portfolio
```

`GET /health` reports API and database health. `GET /ready` returns success only when the database connection is available.

## Gmail API for contact mail

The contact form saves the visitor's name, email, and message. It sends an owner notification to `ADMIN_EMAIL` with `Reply-To` set to the visitor, then sends the visitor a copy with `Reply-To` set to the owner. Both can continue in their normal email inboxes. The API requests only Google's `gmail.send` permission; it does not read the inbox.

1. In Google Cloud, enable the Gmail API, configure the OAuth consent screen, and create an **OAuth client ID for a Desktop app**. Use the Google account you want to send from as a test user if the consent screen requests one. Follow the [official Python setup](https://developers.google.com/workspace/gmail/api/quickstart/python).
2. Download the client JSON into `backend/.secrets/gmail_client.json`. Never commit or share this file.
3. In the ignored `backend/.env`, set `EMAIL_DELIVERY_MODE=gmail_api`, `ADMIN_EMAIL=ranjithvijay1225@gmail.com`, and `GMAIL_SENDER_EMAIL=ranjithvijay1225@gmail.com`. The optional paths `GMAIL_OAUTH_CLIENT_FILE` and `GMAIL_TOKEN_FILE` default to `.secrets/gmail_client.json` and `.secrets/gmail_token.json` relative to `backend/`.
4. Run `.\.venv312\Scripts\python -m app.authorize_gmail` from `backend/`, sign in with the same Gmail account, and approve the send-only permission. The refresh token is saved in `backend/.secrets/gmail_token.json`. Treat it as a password and keep it in persistent private storage.
5. Start the API, submit the contact form, and verify both inbox copies and their Reply-To addresses. The server returns an error when the owner notification fails. If the owner receives it but the visitor copy fails, the response reports that partial delivery.

For local template review without Google authorization, set `EMAIL_DELIVERY_MODE=log`; messages are written to `backend/dev_outbox/`. `disabled` prevents contact submissions from claiming email delivery.

Deployment needs the OAuth client and token files in private persistent storage. The checked-in `render.yaml` does not provision that storage by itself. The OAuth desktop flow is a local setup path; choose a suitable server-side credential storage and consent design before production deployment.

## Analytics and operations

`POST /api/analytics/visit?page=/work` stores privacy-aware portfolio statistics. New records do not retain visitor IP addresses; they contain only coarse device/browser/OS data, the page, referrer hostname, and an optional hashed session hint. Set `ANALYTICS_RETENTION_DAYS` to control automatic retention cleanup.

Authenticated administrators can use `/api/admin/analytics/overview`, `/pages`, `/projects`, and `/timeline`. The application exposes Prometheus-compatible process metrics at `GET /metrics`, including request volume, latency, HTTP errors, contact submissions, email delivery outcomes, and background-job failures.

For production, run FastAPI behind a TLS reverse proxy, set `DATABASE_URL` to PostgreSQL, apply `alembic upgrade head`, and scrape `/metrics` from Prometheus. Grafana can use that Prometheus source for dashboards. `/health` is the liveness probe; `/ready` checks database connectivity before a process receives traffic.

## Content and admin data

Edit `content/*.json` and validate/reseed deliberately until a new content management flow is planned. The runtime schemas are in `app/schema_files/`; `email_template/JSON_FIELDS.md` lists current fields and values. No public or admin endpoint currently uploads JSON/images, emails content approvals, or changes portfolio sections. Existing historical database tables are left in place so old databases remain readable.

## Admin authentication

Set a long, random `JWT_SECRET_KEY` in the ignored `.env`. Then create the first admin account after applying migrations:

```bat
.\.venv312\Scripts\python -m app.create_admin --email your-admin@example.com
```

The command asks for a password without echoing it and stores only an Argon2 hash. Log in through `POST /api/auth/login` with `email` and `password`; the response returns a bearer token and its expiration. Send that token as `Authorization: Bearer <token>` to `GET /api/admin/submissions`, `DELETE /api/admin/submissions/{id}`, and `POST /api/admin/submissions/purge`. Contact retention defaults to 90 days.

## Portfolio CMS API

With the same bearer token, `/docs` provides protected CMS endpoints for About, Skills, Projects, and Journey events:

- `GET` and `PUT /api/admin/about`
- `GET`, `POST`, `PUT`, and `DELETE /api/admin/skills`
- `GET`, `POST`, `PUT`, and `DELETE /api/admin/projects` (list requests support `page` and `page_size`)
- `GET`, `POST`, `PUT`, and `DELETE /api/admin/journey`

Projects, skills, and journey events now use their normalized database tables as the runtime source. The JSON files remain safe default seed data. Restart the backend after applying a new migration so the running server loads the updated API routes.
