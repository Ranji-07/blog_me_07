# Portfolio status and next work

Last reviewed: 2026-09-17. This is the single status document in `docs/`.

## Current product

- Flutter Web shows Landing, About, Work/Projects/Journey, and Contact. Public `/200`, `/under-construction`, and 404 screens use a build-time fallback name when content is unavailable.
- FastAPI serves JSON sections from SQLite. Editable source data is in `backend/content/`; runtime schemas are in `backend/app/schema_files/`. The current field inventory is `email_template/JSON_FIELDS.md`.
- The contact form stores name, email, and message. The backend sends an HTML notification to `ADMIN_EMAIL` with `Reply-To` set to the visitor, then emails the visitor a copy with `Reply-To` set to the owner. Replies continue in ordinary mail clients. The messages use `email_template/contact_admin.html`, `contact_visitor.html`, and `contact_email.css`.
- Gmail API is the selected sender. It requests only the `gmail.send` scope and stores its OAuth token in ignored `backend/.secrets/`. The earlier Gmail SMTP test reached Google but was rejected with `535 5.7.8`; SMTP is no longer the selected delivery mode.
- Admin API access is limited to reading, deleting, and purging stored contact submissions. Content upload, emailed approvals, email commands, and content update routes were removed. Existing historical database tables remain so local data is not destroyed.

## What is needed before a live contact email

1. Enable Gmail API and create a Google OAuth Desktop client, then place its downloaded JSON at `backend/.secrets/gmail_client.json`. Follow `backend/README.md` and Google's linked setup instructions.
2. Run `backend/.venv312/Scripts/python.exe -m app.authorize_gmail` **from `backend/`** and authorize the account matching `GMAIL_SENDER_EMAIL`. This saves the private refresh token at `backend/.secrets/gmail_token.json`.
3. Restart the API so it reads `EMAIL_DELIVERY_MODE=gmail_api` from ignored `backend/.env`. Submit one contact form using a real visitor inbox. Check delivery to both addresses and that Reply works in each direction.
4. For deployment, put the OAuth token and client file on private persistent storage; the checked-in Render service definition does not create that storage.

Until Gmail authorization is complete, the contact endpoint returns 503 instead of claiming an email was sent. `EMAIL_DELIVERY_MODE=log` is available for local template review in `backend/dev_outbox/`.

## Data and UI still to review

- The edited About and Contact seed files are valid, but the local SQLite rows can still hold older versions. Reseed only when it is acceptable to overwrite stored sections. Confirm brand name (`Tarzan`), sample phone number, `tarzan.dev` link, resume and image paths, and optional About value statement.
- Projects have eight records; several lack GitHub links and all lack demos/images. Missing links are hidden in the current UI. Review descriptions, ownership, and whether images are needed before polishing the cards.
- Check responsive layouts, status pages, keyboard focus, form validation, and the two-email success/failure states in a browser. Work now keeps Projects visible if Journey fails. Configure the web host separately if unknown URLs must return an HTTP 404 status.
- Replace the hardcoded summary in `frontend/lib/screens/resume_dialog.dart` with verified resume details or show the PDF itself. Confirm whether `Tarzan` is the final public brand before changing the name fallback in Flutter.
- Plan content editing and publishing separately later. The current manual path is to edit the seed JSON, validate it, back up the database, and deliberately run `python -m app.init_db`.

## Verification

Ten backend tests pass with `.venv312/Scripts/python.exe -m unittest discover -s tests -q` from `backend/`, and Flutter `dart analyze lib` reports no issues. The Gmail API message format was checked with a mocked send. A live Gmail API send requires the one-time Google OAuth authorization above.
