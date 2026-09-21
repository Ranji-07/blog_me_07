Phase 1 — Backend Foundation & PostgreSQL
**Status: Completed — 2026-09-17**

Upgrade the existing FastAPI portfolio backend to a clean production-oriented database foundation.

Do not change the existing Flutter UI or remove any existing API functionality.

Current backend already has:
- FastAPI
- Portfolio content
- JSON seed files
- PostgreSQL / lightweight DB support
- Contact submissions
- Email service
- Analytics
- Admin submission endpoints
- CORS
- Security headers
- Rate limiting

For this phase, focus ONLY on the database foundation.

Move toward PostgreSQL as the primary production database while keeping lightweight/local development support where practical.

Create clean database models for:
- portfolio content
- projects
- journey / education / experience
- skills
- contact submissions
- visit analytics
- email events

Use SQLAlchemy models with proper relationships where appropriate.

Introduce Alembic database migrations instead of relying only on automatic table creation.

Create an initial migration for the existing schema.

Add:
- created_at
- updated_at
- appropriate primary keys
- indexes for frequently queried fields
- appropriate unique constraints
- foreign keys where required

Keep the existing JSON files as seed/default content. Do not delete them.

Create a reliable seed/initialization process:

JSON files
→ validation
→ database seed/update

Do not silently overwrite existing production data during initialization.

Improve configuration so database URLs, email settings, secrets, and environment-specific settings come from environment variables/configuration rather than hardcoded values.

Keep SQLite/lightweight local development support if it does not complicate the architecture.

Update /health and add /ready if appropriate.

Verify:
- application starts
- migrations run
- database connection works
- existing portfolio APIs continue working
- existing contact functionality continues working
- existing analytics functionality continues working

Do not implement authentication, CMS editing, versioning, or new UI in this phase.

At the end, provide a concise summary of:
1. files changed
2. database models created
3. migrations created
4. commands required to initialize/run the backend
5. any breaking changes
Phase 2 — JWT Admin Authentication
**Status: Completed — 2026-09-18**

Build a proper JWT-based authentication system for the existing FastAPI portfolio backend.

Do not change the public portfolio APIs or Flutter public-facing UI.

Replace the current admin authentication mechanism based on:
- auth_email
- X-Admin-Token

with a proper admin authentication flow.

Create:

POST /api/auth/login

Accept:
- email
- password

Return:
- access token
- token type
- expiration information

Use secure password hashing such as Argon2 or bcrypt.

Never store plaintext passwords.

Create an admin user model containing appropriate fields such as:
- id
- email
- password_hash
- is_active
- created_at
- updated_at
- last_login_at

Implement JWT authentication with:
Authorization: Bearer <token>

Protect all /api/admin/* endpoints using the authenticated admin dependency.

Add proper authentication failures:
- invalid credentials
- expired token
- inactive user
- missing authorization header

Do not expose whether an email exists during login failure.

Move authentication secrets into environment configuration.

Add token expiration.

Keep the existing admin submission functionality working:
- GET /api/admin/submissions
- DELETE /api/admin/submissions/{id}
- POST /api/admin/submissions/purge

Remove dependence on the old X-Admin-Token mechanism only after the new authentication path is working.

Do not build an admin UI yet.

Add tests for:
- successful login
- invalid login
- protected route without token
- protected route with invalid token
- expired token
- inactive admin
- valid authenticated request

At the end, provide:
1. authentication flow
2. new endpoints
3. environment variables
4. migration changes
5. test results
Phase 3 — Admin Portfolio CMS API
**Status: Completed — 2026-09-18**

Build a protected admin CMS API for managing the portfolio content.

Do not redesign the Flutter public UI in this phase.

The public portfolio currently reads content from JSON/database-backed portfolio data.

Make PostgreSQL the runtime source of truth while retaining JSON files as seed/default data.

Using the JWT authentication system from Phase 2, create protected CRUD endpoints for:

ABOUT
GET    /api/admin/about
PUT    /api/admin/about

SKILLS
GET    /api/admin/skills
POST   /api/admin/skills
PUT    /api/admin/skills/{id}
DELETE /api/admin/skills/{id}

PROJECTS
GET    /api/admin/projects
POST   /api/admin/projects
GET    /api/admin/projects/{id}
PUT    /api/admin/projects/{id}
DELETE /api/admin/projects/{id}

JOURNEY
GET    /api/admin/journey
POST   /api/admin/journey
PUT    /api/admin/journey/{id}
DELETE /api/admin/journey/{id}

Create proper Pydantic request/response schemas.

Project records should support fields such as:
- title
- slug
- description
- category
- technologies
- start_date
- end_date
- github_url
- live_url
- image
- associated_with
- featured
- status
- created_at
- updated_at

Journey records should support:
- date/year
- event type
- title
- organization
- description
- parent milestone
- project relationship
- certification information

Skills should support:
- category
- name
- icon
- display order
- active state

Ensure the public APIs continue returning only appropriate public content.

Validate URLs, dates, required fields, and content lengths.

Add pagination where project lists could grow.

Do not add draft/publish/versioning yet.

Do not add image upload yet.

At the end, verify all CRUD operations through FastAPI /docs and tests.
Phase 4 — Draft, Publish & Version History
**Status: Completed — 2026-09-18**
Add a publishing workflow and version history to the existing portfolio CMS.

Do not change the visual Flutter UI yet.

The goal is:

Admin edits content
        ↓
Draft
        ↓
Preview
        ↓
Publish
        ↓
Public portfolio

Add appropriate fields such as:
- status: draft / published / archived
- version
- created_at
- updated_at
- published_at

Public portfolio endpoints must return only published content.

Admin endpoints must be able to view draft and published content.

Add endpoints such as:

POST /api/admin/projects/{id}/publish
POST /api/admin/projects/{id}/unpublish
GET  /api/admin/projects/{id}/versions
POST /api/admin/projects/{id}/versions/{version}/restore

Implement equivalent publishing/versioning behavior for:
- About
- Skills
- Journey
- Projects

Never destroy the previous published version when a new version is created.

When restoring an old version:
- create a new version based on the old data
- do not mutate historical records
- allow the restored version to be reviewed before publishing

Add audit information:
- changed_at
- changed_by
- action

Ensure public users never see draft content.

Add database migrations and tests for:
- creating draft
- publishing
- unpublishing
- version creation
- restoring
- public API filtering
Phase 5 — Contact & Email Reliability
**Status: Completed — 2026-09-18**
Improve the existing contact and email system without changing the current Flutter contact-page design.

The existing flow is:

Flutter
→ FastAPI
→ validate
→ save submission
→ send owner email
→ send visitor confirmation

Keep this behavior, but make email delivery more reliable and observable.

Create an email event/outbox system.

Track:
- submission_id
- email type
- recipient
- provider
- status
- error message
- created_at
- sent_at

Support states such as:
- pending
- sent
- failed

Keep the existing email modes:
- log
- gmail_api
- disabled

Do not claim an email was sent when Gmail authorization or delivery fails.

Where practical, move email sending out of the request path into a background job/worker.

The contact API should primarily:
1. validate
2. save the submission
3. create email delivery jobs
4. return an accurate response

Implement retry handling for temporary email failures.

Do not retry permanent failures indefinitely.

Add protected admin endpoints:

GET /api/admin/email-events
GET /api/admin/email-events/{id}
POST /api/admin/email-events/{id}/retry

Keep the existing:
- 5 submissions/hour/IP rate limit
- 90-day retention
- validation
- visitor confirmation email
- owner notification

Add tests for:
- successful email
- Gmail unavailable
- failed email
- retry
- disabled email mode
- duplicate/repeated submission handling
Phase 6 — Analytics & Privacy-Aware Dashboard API
**Status: Completed — 2026-09-18**
Upgrade the existing portfolio analytics system.

The current analytics endpoint records:
- visitor IP
- user agent
- visit time

Keep analytics privacy-conscious and collect only information genuinely needed for portfolio statistics.

Improve the visit model with appropriate fields such as:
- visit_id
- timestamp
- page
- device type
- browser
- operating system
- referrer
- session identifier where appropriate

Avoid collecting unnecessary personal information.

Continue rate limiting analytics requests.

Create protected admin analytics endpoints:

GET /api/admin/analytics/overview
GET /api/admin/analytics/pages
GET /api/admin/analytics/projects
GET /api/admin/analytics/timeline

Return useful aggregate information such as:
- visits today
- visits this week
- visits this month
- popular pages
- project interactions
- contact submissions
- email delivery statistics

Do not expose raw visitor IP addresses through public APIs.

If raw analytics data is needed by administrators, ensure access is protected and retention is respected.

Add configurable retention cleanup for analytics data.

Do not build the analytics UI yet.

Add tests for aggregation, authorization, retention, and rate limiting.
Phase 7 — Observability & Production Operations
**Status: Completed — 2026-09-18**
Add production-oriented observability to the FastAPI portfolio backend.

Do not change the portfolio UI.

Implement structured application logging.

Logs should provide useful information for:
- request lifecycle
- authentication events
- database errors
- contact submissions
- email failures
- background jobs
- unexpected exceptions

Do not log:
- passwords
- JWT secrets
- Gmail OAuth secrets
- sensitive personal information
- complete contact-message contents unnecessarily

Add application metrics where appropriate.

Track:
- HTTP request count
- request latency
- HTTP error count
- database errors
- contact submissions
- email success/failure
- background job failures

Expose a metrics endpoint suitable for Prometheus.

Improve:
GET /health

and:

GET /ready

Use /health for liveness and /ready for application dependency readiness.

Ensure database connectivity is checked appropriately.

Make the application suitable for container deployment.

Add graceful startup/shutdown handling.

Document how to run:
- FastAPI
- PostgreSQL
- migrations
- Prometheus
- optional Grafana

Do not introduce Kubernetes configuration unless specifically requested in a later phase.
Phase 8 — Image & Asset Management
**Status: Completed — 2026-09-18**
Add secure portfolio image and asset management to the existing FastAPI backend.

The current backend has:

GET /images/{filename}

Do not break this route.

Add protected admin upload functionality for portfolio assets.

Support:
- project images
- company logos
- skill SVG icons
- certification documents/images where appropriate

Validate:
- file type
- extension
- MIME type
- file size
- filename
- path traversal attempts

Never allow arbitrary filesystem access.

Create:

POST   /api/admin/assets
GET    /api/admin/assets
DELETE /api/admin/assets/{id}

Store metadata in the database:

- id
- filename
- storage path
- MIME type
- file size
- associated project/content
- created_at

Keep actual binary files outside the database unless there is a strong reason otherwise.

Use generated safe filenames rather than trusting user-provided filenames.

Do not allow public access to private/admin assets.

Keep existing public image serving functionality working.

Add tests for:
- valid upload
- unsupported file
- oversized file
- malicious filename
- unauthorized upload
- deletion
Phase 9 — Flutter Admin Panel
**Status: Completed — 2026-09-18**

Only after the backend phases are stable, build the admin UI.

Create a separate authenticated admin area in the existing Flutter portfolio application.

Do not alter the existing public portfolio experience.

Create:

/admin/login
/admin/dashboard
/admin/projects
/admin/journey
/admin/skills
/admin/about
/admin/messages
/admin/analytics

Use the JWT authentication API already implemented.

Admin dashboard should show:
- portfolio status
- recent contact messages
- email delivery status
- basic analytics
- draft content
- recently updated projects

Projects should support:
- create
- edit
- delete
- draft
- preview
- publish
- version history

Journey should support:
- education
- employment
- projects
- certifications
- ordering

Skills should support:
- categories
- technologies
- SVG icon
- ordering
- active/inactive state

Messages should support:
- new
- read
- replied
- archived
- spam

Do not expose admin functionality to unauthenticated users.

Keep the existing public portfolio UI unchanged unless a small API integration change is required.
Recommended order

Don't give all nine prompts to the coding agent at once. Run them sequentially:

Phase 1  → PostgreSQL + migrations
   ↓
Phase 2  → JWT authentication
   ↓
Phase 3  → Admin CMS API
   ↓
Phase 4  → Draft + Publish + Versions
   ↓
Phase 5  → Reliable Email
   ↓
Phase 6  → Analytics
   ↓
Phase 7  → Observability
   ↓
Phase 8  → Asset management
   ↓
Phase 9  → Flutter Admin UI
