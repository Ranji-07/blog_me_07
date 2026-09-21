import os
import tempfile
import unittest
import warnings
from datetime import timedelta
from pathlib import Path
from unittest.mock import patch

os.environ["DATABASE_URL"] = f"sqlite:///{Path(tempfile.gettempdir()) / 'portfolio_test.db'}"
os.environ["ADMIN_EMAIL"] = "admin@portfolio.dev"
os.environ["JWT_SECRET_KEY"] = "test-jwt-secret-that-is-long-enough"
os.environ["JWT_ACCESS_TOKEN_MINUTES"] = "30"
os.environ["EMAIL_DELIVERY_MODE"] = "log"
os.environ["TRUST_PROXY_HEADERS"] = "true"

warnings.filterwarnings("ignore", category=DeprecationWarning)

from fastapi.testclient import TestClient

from app.database import Base, SessionLocal, engine
from app.init_db import init_database
from app.main import app
from app.models import AdminUser, Asset, ContactSubmission, VisitLog
from app.services.auth import create_access_token, hash_password
from app.services.rate_limiter import rate_limiter


class PortfolioApiTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        Base.metadata.drop_all(bind=engine)
        Base.metadata.create_all(bind=engine)
        init_database()
        db = SessionLocal()
        try:
            db.add(
                AdminUser(
                    email="admin@portfolio.dev",
                    password_hash=hash_password("correct-horse-battery-staple"),
                )
            )
            db.commit()
        finally:
            db.close()
        cls.client = TestClient(app)

    def setUp(self):
        rate_limiter._events.clear()

    def _contact(self, *, message="I would like to discuss a collaboration."):
        return self.client.post(
            "/api/portfolio/contact-form",
            json={"name": "Jordan Lee", "email": "jordan@example.com", "message": message},
        )

    def _login(self, *, email="admin@portfolio.dev", password="correct-horse-battery-staple"):
        return self.client.post("/api/auth/login", json={"email": email, "password": password})

    def _admin_headers(self):
        response = self._login()
        self.assertEqual(response.status_code, 200, response.text)
        return {"Authorization": f"Bearer {response.json()['access_token']}"}

    def test_public_content_and_project_filter(self):
        self.assertEqual(self.client.get("/api/portfolio/about").status_code, 200)
        projects = self.client.get("/api/portfolio/projects").json()
        self.assertGreater(len(projects["projects"]), 0)
        category = projects["projects"][0]["category"]
        filtered = self.client.get("/api/portfolio/projects", params={"category": category}).json()
        self.assertTrue(all(item["category"].lower() == category.lower() for item in filtered["projects"]))

    def test_health_and_readiness_checks(self):
        self.assertEqual(self.client.get("/health").status_code, 200)
        ready = self.client.get("/ready")
        self.assertEqual(ready.status_code, 200)
        self.assertEqual(ready.json()["status"], "ready")

    def test_contact_creates_observable_delivery_events(self):
        with patch("app.services.email_outbox.send_email", return_value=True) as send:
            response = self._contact(message="Let's talk about <this> project & next steps.")
        self.assertEqual(response.status_code, 200, response.text)
        self.assertFalse(response.json()["data"]["visitor_copy_sent"])
        self.assertEqual(send.call_count, 2)
        owner_call, visitor_call = send.call_args_list
        self.assertEqual(owner_call.args[0], "admin@portfolio.dev")
        self.assertEqual(owner_call.kwargs["reply_to"], "jordan@example.com")
        self.assertEqual(visitor_call.args[0], "jordan@example.com")
        self.assertEqual(visitor_call.kwargs["reply_to"], "admin@portfolio.dev")
        self.assertIn("&lt;this&gt;", owner_call.args[2])
        self.assertNotIn("<this>", owner_call.args[2])
        self.assertIn("&lt;this&gt;", visitor_call.args[2])
        db = SessionLocal()
        try:
            submission = db.query(ContactSubmission).order_by(ContactSubmission.id.desc()).first()
            self.assertEqual(submission.email, "jordan@example.com")
            self.assertEqual(len(submission.email_events), 2)
            self.assertTrue(all(event.delivery_status == "sent" for event in submission.email_events))
            event_id = submission.email_events[0].id
        finally:
            db.close()
        events = self.client.get("/api/admin/email-events", headers=self._admin_headers())
        self.assertEqual(events.status_code, 200)
        detail = self.client.get(f"/api/admin/email-events/{event_id}", headers=self._admin_headers())
        self.assertEqual(detail.status_code, 200)
        self.assertEqual(detail.json()["status"], "sent")

    def test_contact_records_delivery_failure_without_claiming_it_was_sent(self):
        with patch("app.services.email_outbox.send_email", side_effect=[True, False]):
            response = self._contact()
        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.json()["data"]["visitor_copy_sent"])

    def test_contact_returns_after_owner_delivery_failure(self):
        with patch("app.services.email_outbox.send_email", return_value=False) as send:
            response = self._contact()
        self.assertEqual(response.status_code, 200)
        self.assertEqual(send.call_count, 2)

    def test_contact_rejects_when_email_is_not_configured(self):
        with patch("app.routes.public.is_email_configured", return_value=False):
            response = self._contact()
        self.assertEqual(response.status_code, 503)

    def test_contact_form_is_rate_limited(self):
        with patch("app.services.email_outbox.send_email", return_value=True):
            for _ in range(5):
                self.assertEqual(self._contact().status_code, 200)
            self.assertEqual(self._contact().status_code, 429)

    def test_old_upload_and_email_approval_routes_are_gone(self):
        for path in (
            "/api/admin/proposals/new",
            "/api/admin/proposals/review/example",
            "/api/admin/confirm/example",
            "/api/admin/schema/content",
        ):
            self.assertEqual(self.client.get(path).status_code, 404, path)
        for path in ("/api/admin/proposals", "/api/admin/email-command", "/api/admin/upload-image", "/api/admin/seed"):
            self.assertEqual(self.client.post(path).status_code, 404, path)

    def test_admin_login_returns_bearer_token(self):
        response = self._login()
        self.assertEqual(response.status_code, 200, response.text)
        payload = response.json()
        self.assertEqual(payload["token_type"], "bearer")
        self.assertGreater(payload["expires_in"], 0)
        self.assertTrue(payload["access_token"])

    def test_admin_login_rejects_invalid_credentials_without_revealing_email(self):
        unknown = self._login(email="unknown@portfolio.dev")
        wrong_password = self._login(password="wrong-password")
        self.assertEqual(unknown.status_code, 401)
        self.assertEqual(wrong_password.status_code, 401)
        self.assertEqual(unknown.json()["detail"], "Invalid email or password")
        self.assertEqual(wrong_password.json()["detail"], "Invalid email or password")

    def test_admin_route_requires_bearer_token(self):
        response = self.client.get("/api/admin/submissions")
        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.headers["www-authenticate"], "Bearer")

    def test_admin_route_rejects_invalid_token(self):
        response = self.client.get(
            "/api/admin/submissions",
            headers={"Authorization": "Bearer invalid.token.value"},
        )
        self.assertEqual(response.status_code, 401)

    def test_admin_route_rejects_expired_token(self):
        db = SessionLocal()
        try:
            admin = db.query(AdminUser).filter(AdminUser.email == "admin@portfolio.dev").one()
            expired_token = create_access_token(admin, expires_delta=timedelta(seconds=-1))
        finally:
            db.close()
        response = self.client.get(
            "/api/admin/submissions",
            headers={"Authorization": f"Bearer {expired_token}"},
        )
        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.json()["detail"], "Authentication token has expired")

    def test_inactive_admin_cannot_log_in_or_use_token(self):
        db = SessionLocal()
        try:
            admin = db.query(AdminUser).filter(AdminUser.email == "admin@portfolio.dev").one()
            token = create_access_token(admin)
            admin.is_active = False
            db.commit()
        finally:
            db.close()
        try:
            self.assertEqual(self._login().status_code, 403)
            response = self.client.get(
                "/api/admin/submissions",
                headers={"Authorization": f"Bearer {token}"},
            )
            self.assertEqual(response.status_code, 403)
        finally:
            db = SessionLocal()
            try:
                admin = db.query(AdminUser).filter(AdminUser.email == "admin@portfolio.dev").one()
                admin.is_active = True
                db.commit()
            finally:
                db.close()

    def test_admin_can_read_saved_submissions_with_bearer_token(self):
        allowed = self.client.get("/api/admin/submissions", headers=self._admin_headers())
        self.assertEqual(allowed.status_code, 200)
        self.assertIn("submissions", allowed.json())

    def test_admin_cms_crud_and_public_project_runtime_source(self):
        headers = self._admin_headers()

        about = self.client.get("/api/admin/about", headers=headers)
        self.assertEqual(about.status_code, 200)
        self.assertIn("skill_categories", about.json())
        skill = self.client.post(
            "/api/admin/skills",
            headers=headers,
            json={"category": "Testing", "name": "Pytest", "display_order": 0},
        )
        self.assertEqual(skill.status_code, 201, skill.text)
        skill_id = skill.json()["id"]
        updated_skill = self.client.put(
            f"/api/admin/skills/{skill_id}",
            headers=headers,
            json={"name": "pytest", "is_active": False},
        )
        self.assertEqual(updated_skill.status_code, 200, updated_skill.text)

        project = self.client.post(
            "/api/admin/projects",
            headers=headers,
            json={
                "title": "CMS Integration Project",
                "slug": "cms-integration-project",
                "category": "Web",
                "description": "A project created through the authenticated CMS integration test.",
                "technologies": ["Python", "FastAPI"],
                "start_date": "2026-01-01",
                "associated_with": "Portfolio CMS",
                "github_url": "https://github.com/example/cms-project",
                "featured": True,
            },
        )
        self.assertEqual(project.status_code, 201, project.text)
        project_id = project.json()["id"]
        self.assertEqual(project.json()["status"], "draft")
        hidden_projects = self.client.get("/api/portfolio/projects", params={"category": "Web"}).json()["projects"]
        self.assertNotIn("CMS Integration Project", [item["title"] for item in hidden_projects])
        published_project = self.client.post(f"/api/admin/projects/{project_id}/publish", headers=headers)
        self.assertEqual(published_project.status_code, 200, published_project.text)
        project_update = self.client.put(
            f"/api/admin/projects/{project_id}",
            headers=headers,
            json={"short_description": "Updated through the CMS."},
        )
        self.assertEqual(project_update.status_code, 200, project_update.text)
        public_projects = self.client.get("/api/portfolio/projects", params={"category": "Web"})
        self.assertIn("CMS Integration Project", [item["title"] for item in public_projects.json()["projects"]])
        versions = self.client.get(f"/api/admin/projects/{project_id}/versions", headers=headers)
        self.assertEqual(versions.status_code, 200)
        self.assertGreaterEqual(len(versions.json()), 2)
        preview = self.client.get(f"/api/admin/projects/{project_id}/preview", headers=headers)
        self.assertEqual(preview.json()["status"], "draft")
        restored = self.client.post(f"/api/admin/projects/{project_id}/versions/1/restore", headers=headers)
        self.assertEqual(restored.status_code, 200, restored.text)

        journey = self.client.post(
            "/api/admin/journey",
            headers=headers,
            json={
                "event_type": "Certification",
                "date_label": "Sep 2026",
                "timeline_date": "2026-09-01",
                "organization": "Portfolio CMS",
                "title": "CMS Content Certification",
                "project_id": project_id,
                "certification_info": {"url": "https://example.com/certificate"},
            },
        )
        self.assertEqual(journey.status_code, 201, journey.text)
        journey_id = journey.json()["id"]
        journey_update = self.client.put(
            f"/api/admin/journey/{journey_id}",
            headers=headers,
            json={"timeline_label": "CMS certification"},
        )
        self.assertEqual(journey_update.status_code, 200, journey_update.text)

        self.assertEqual(self.client.delete(f"/api/admin/journey/{journey_id}", headers=headers).status_code, 200)
        self.assertEqual(self.client.delete(f"/api/admin/projects/{project_id}", headers=headers).status_code, 200)
        self.assertEqual(self.client.delete(f"/api/admin/skills/{skill_id}", headers=headers).status_code, 200)

    def test_visit_analytics_is_recorded(self):
        response = self.client.post(
            "/api/analytics/visit?page=/projects/example",
            headers={"x-forwarded-for": "203.0.113.10", "user-agent": "PortfolioApiTest/1.0"},
        )
        self.assertEqual(response.status_code, 204)
        db = SessionLocal()
        try:
            visit = db.query(VisitLog).order_by(VisitLog.id.desc()).first()
            self.assertIsNone(visit.ip)
            self.assertEqual(visit.page, "/projects/example")
            self.assertTrue(visit.visit_id)
            self.assertTrue(visit.device_type)
        finally:
            db.close()
        analytics = self.client.get("/api/admin/analytics/overview", headers=self._admin_headers())
        self.assertEqual(analytics.status_code, 200)
        self.assertIn("visits_today", analytics.json())

    def test_admin_asset_upload_validation_and_deletion(self):
        self.assertEqual(self.client.get("/api/admin/assets").status_code, 401)
        headers = self._admin_headers()
        upload = self.client.post("/api/admin/assets", headers=headers, data={"asset_type": "project_image", "is_public": "true"}, files={"file": ("../../unsafe.png", b"PNG data", "image/png")})
        self.assertEqual(upload.status_code, 201, upload.text)
        asset = upload.json()
        self.assertRegex(asset["filename"], r"^[a-f0-9]{32}\.png$")
        self.assertEqual(self.client.get(asset["url"]).status_code, 200)
        bad = self.client.post("/api/admin/assets", headers=headers, data={"asset_type": "project_image"}, files={"file": ("file.exe", b"x", "application/octet-stream")})
        self.assertEqual(bad.status_code, 415)
        self.assertEqual(self.client.delete(f"/api/admin/assets/{asset['id']}", headers=headers).status_code, 200)


if __name__ == "__main__":
    unittest.main()
