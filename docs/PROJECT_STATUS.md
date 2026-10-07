# Portfolio project status

Last reviewed: 2026-10-07

## Public portfolio

The public Flutter portfolio is a static web application. Its content is read
from `frontend/config/portfolio.json`, bundled during the web build, and does
not require FastAPI at runtime.

- GitHub Pages address: <https://ranji-07.github.io/blog_me_07/>
- Deployment workflow: `.github/workflows/deploy-static.yml`
- Static content guide: `frontend/config/README.md`
- Contact form: opens a prefilled `mailto:` draft in the visitor's configured
  Gmail, Outlook, Apple Mail, or other email handler. It does not store or send
  a message on the static site.

The Pages workflow builds successfully. It was updated to use a unique
`portfolio-site` artifact after GitHub reported two artifacts named
`github-pages`. Confirm one successful Pages deployment before treating the
address above as live.

## Backend and admin

The FastAPI backend remains a separate, local or future hosted service. It is
not part of the static GitHub Pages deployment.

Completed backend phases are recorded in the root `bd_phase.md`:

1. Database foundation and Alembic migrations
2. JWT administrator authentication
3. CMS APIs for About, Skills, Projects, and Journey
4. Draft, publish, version, and restore support
5. Gmail API email outbox and contact reliability
6. Privacy-aware analytics APIs
7. Health, readiness, metrics, and operational logging
8. Protected asset upload and image serving
9. Flutter admin area

The `/admin/*` screens require a separately hosted backend and an API base URL.
They are not a production feature of the static site yet.

## Current Work page

The Work page refresh is complete:

- The Journey heading, timeline spacing, and the desktop/mobile curved timeline
  are more compact without changing timeline data.
- The project card grid is replaced by a project workspace terminal backed by
  the existing project config.
- Desktop shows Projects and Blog terminals side by side when there is room.
  Mobile shows one terminal with Projects and Blog tabs.
- Planned blog topics are in `frontend/config/portfolio.json`. Add a real HTTPS
  `url` when an article is published.

## Remaining decisions

1. Confirm GitHub Pages deployment and, later, configure a domain and DNS.
2. Decide whether the backend/admin will be hosted on Cloud Run, Render, or a
   different service.
3. Choose a managed PostgreSQL service before using the CMS in production.
4. Complete Gmail OAuth only when the hosted backend contact workflow is needed.
5. Replace placeholder contact details, links, resume data, and missing project
   demonstrations with verified public content.

## Verification commands

Static frontend build:

```bat
cd frontend
.\build-static.bat /blog_me_07/
```

Backend checks:

```bat
cd backend
.\.venv312\Scripts\python -m alembic upgrade head
.\.venv312\Scripts\python -m unittest discover -s tests -q
```
