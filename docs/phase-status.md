# Portfolio Build Status

Last verified: 2026-09-04

## Phase 0 - FastAPI CMS Backend

- [x] Content files exist for about, projects, experience, and contact.
- [x] Content validates against the JSON schema and seeds four active database rows.
- [x] Public endpoints return seeded dummy data, including project category filtering and the bundled response.
- [x] Contact-form endpoint saves submissions and can dispatch admin email through a background task.
- [x] Admin confirmation, schema validation, version history, and rollback are covered by backend tests.
- [x] Image upload endpoint applies MIME and 5 MB limits.
- [ ] Replace all dummy profile, project, experience, and contact values with real portfolio data before production.
- [ ] Verify SMTP delivery with real production credentials before production.

## Phase 1 - Flutter Shell

- [x] Dark and light themes use the near-black, cream, and orange brand palette.
- [x] Outfit font, spacing, radii, and text tokens are defined in the Flutter theme.
- [x] AppShell routes between Landing, About, Projects, and Contact using `PortfolioSection`.
- [x] Landing hides navigation until Enter is selected.
- [x] Desktop text navigation and mobile icon navigation are responsive and use 48px targets.
- [x] Screen navigation uses a fade transition.
- [x] Responsive helpers include breakpoints, container, and adaptive grid utilities.
- [x] Secure external-link opener uses `noopener,noreferrer` on web.
- [x] Resume opens as a preview dialog with Share and Save actions; mobile shows a five-second action state.
- [ ] Verify desktop and mobile rendering manually in a browser before production.
