# Portfolio Build Status

Last verified: 2026-09-16

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
- [x] Verify desktop and mobile rendering manually in a browser.

## Phase 2 - Landing Page

- [x] Landing fetches the bundled portfolio response once and passes it into Contact as cached content.
- [x] Skeleton placeholders and a shimmer transition prevent a blank first render.
- [x] The responsive visual layout uses top-left identity, top-right status and resume controls, a centered editorial hero layer, bottom-left social icons, and bottom CTA actions.
- [x] Backend-controlled name typography, availability state, role size, cycling roles, value statement, avatar URL, and portrait URL are implemented with fallbacks.
- [x] Avatar failures fall back to initials, and portrait failures leave the atmospheric background clean.
- [x] Explore Portfolio records a visit without delaying navigation; View Projects routes to `/auth-demo`.
- [x] Resume and contact actions reuse the existing shared widgets.
- [x] Visit logging stores IP, user agent, and timestamp through `POST /api/analytics/visit`.
- [x] Verify the final desktop and mobile layout in a running Flutter browser session.

## Phase 3 - About Page

- [x] `PortfolioApi.fetchAbout()` loads the public about endpoint when no landing cache is available.
- [x] `AboutProfile` parses profile, image, skills, technology, and highlight data.
- [x] Landing content is reused when available, avoiding a second request after Explore Portfolio.
- [x] The About page has loading, error, and data states through `FutureBuilder`.
- [x] Profile, skills, and highlights are separated into reusable screen widgets.
- [x] Layout adapts from one column on mobile to two columns on larger screens and fades in after load.
- [x] Verify the final desktop and mobile layout in a running Flutter browser session.

## Navigation and Simplified Contact - Complete

- [x] The portfolio uses one continuous outer scroll: Landing, About, Projects, and Contact.
- [x] Desktop and mobile navigation smoothly scroll to each section.
- [x] The Contact section has Name, Email, and Message fields and submits through the FastAPI contact endpoint.
- [x] The destination email, social links, and footer metadata load from portfolio content.
- [x] Shared navigation and the simplified Contact flow were manually verified on desktop and mobile.

## Pre-Projects Backend Hardening - Complete

- [x] CORS allows explicit origins only, security response headers are applied, and public configuration state is not exposed.
- [x] Admin credentials use request headers only; they are not stored with commands or included in confirmation URLs.
- [x] Confirmation links open a review page and require a separate POST to apply a pending write.
- [x] Uploads use server-generated filenames, MIME/signature matching, and a 5 MB read limit.
- [x] Contact and analytics endpoints have request limits, contact payloads are validated server-side, and email HTML escapes user content.
- [x] SMTP uses a verified TLS context and connection timeout.
- [x] Contact submissions have automatic retention cleanup plus authenticated deletion and purge endpoints.
- [ ] Before production: configure HTTPS, explicit production CORS origins, real SMTP credentials, and a shared Redis rate limiter for multi-instance deployment.

## Phase 5 - Contact Page

- [x] Shared Email, GitHub, and LinkedIn icons support secure opening, tooltips, copy feedback, focus, pressed, busy, and long-press states.
- [x] The email dialog shows the loaded email address and provides Mail Him, Copy Email, and Close actions.
- [x] The simplified contact form includes Name, Email, and Message only.
- [x] Email suffix suggestions, opt-in name suggestion, and keyboard/touch message suggestions are implemented.
- [x] Validation rejects empty, placeholder, repeated-character, malformed, and out-of-range required values with field-level errors.
- [x] The form accepts Unicode, emojis, pasted text, and pasted links; backend email HTML safely escapes user content.
- [x] FastAPI stores the submission and sends the owner notification; the success dialog also prepares the visitor's encoded `mailto:` draft.
- [x] Privacy copy, native mobile keyboard types, 48px submit target, screen-reader labels, and keyboard focus flow are implemented.
- [ ] Manually verify the complete contact flow across supported desktop and mobile browsers.
- [ ] Rework the visual design after the final Contact behavior is complete.

## Deferred Phase 3 Work

- [ ] Redesign the About section after Phase 5.
- [ ] Add the education and certification timeline, desktop horizontal layout, mobile swipe/auto-advance behavior, and detail dialog.
