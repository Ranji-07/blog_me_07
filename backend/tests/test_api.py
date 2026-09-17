import os
import tempfile
import unittest
import warnings
from pathlib import Path
from unittest.mock import patch

os.environ["DATABASE_URL"] = f"sqlite:///{Path(tempfile.gettempdir()) / 'portfolio_test.db'}"
os.environ["ADMIN_EMAIL"] = "admin@portfolio.dev"
os.environ["ADMIN_API_KEY"] = "test-admin-key"
os.environ["EMAIL_DELIVERY_MODE"] = "log"
os.environ["TRUST_PROXY_HEADERS"] = "true"

warnings.filterwarnings("ignore", category=DeprecationWarning)

from fastapi.testclient import TestClient

from app.database import Base, SessionLocal, engine
from app.init_db import init_database
from app.main import app
from app.models import ContactSubmission, VisitLog
from app.services.rate_limiter import rate_limiter


class PortfolioApiTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        Base.metadata.drop_all(bind=engine)
        Base.metadata.create_all(bind=engine)
        init_database()
        cls.client = TestClient(app)

    def setUp(self):
        rate_limiter._events.clear()

    def _contact(self, *, message="I would like to discuss a collaboration."):
        return self.client.post(
            "/api/portfolio/contact-form",
            json={"name": "Jordan Lee", "email": "jordan@example.com", "message": message},
        )

    def test_public_content_and_project_filter(self):
        self.assertEqual(self.client.get("/api/portfolio/about").status_code, 200)
        projects = self.client.get("/api/portfolio/projects").json()
        self.assertGreater(len(projects["projects"]), 0)
        category = projects["projects"][0]["category"]
        filtered = self.client.get("/api/portfolio/projects", params={"category": category}).json()
        self.assertTrue(all(item["category"].lower() == category.lower() for item in filtered["projects"]))

    def test_contact_sends_owner_and_visitor_copies_with_reply_addresses(self):
        with patch("app.routes.public.send_email", return_value=True) as send:
            response = self._contact(message="Let's talk about <this> project & next steps.")
        self.assertEqual(response.status_code, 200, response.text)
        self.assertTrue(response.json()["data"]["visitor_copy_sent"])
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
        finally:
            db.close()

    def test_contact_reports_copy_failure_without_claiming_it_was_sent(self):
        with patch("app.routes.public.send_email", side_effect=[True, False]):
            response = self._contact()
        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.json()["data"]["visitor_copy_sent"])

    def test_contact_reports_owner_delivery_failure(self):
        with patch("app.routes.public.send_email", return_value=False) as send:
            response = self._contact()
        self.assertEqual(response.status_code, 503)
        self.assertEqual(send.call_count, 1)

    def test_contact_rejects_when_email_is_not_configured(self):
        with patch("app.routes.public.is_email_configured", return_value=False), patch(
            "app.routes.public.send_email"
        ) as send:
            response = self._contact()
        self.assertEqual(response.status_code, 503)
        send.assert_not_called()

    def test_contact_form_is_rate_limited(self):
        with patch("app.routes.public.send_email", return_value=True):
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

    def test_admin_can_read_saved_submissions_with_key(self):
        denied = self.client.get("/api/admin/submissions", params={"auth_email": "admin@portfolio.dev"})
        self.assertEqual(denied.status_code, 403)
        allowed = self.client.get(
            "/api/admin/submissions",
            params={"auth_email": "admin@portfolio.dev"},
            headers={"X-Admin-Token": "test-admin-key"},
        )
        self.assertEqual(allowed.status_code, 200)
        self.assertIn("submissions", allowed.json())

    def test_visit_analytics_is_recorded(self):
        response = self.client.post(
            "/api/analytics/visit",
            headers={"x-forwarded-for": "203.0.113.10", "user-agent": "PortfolioApiTest/1.0"},
        )
        self.assertEqual(response.status_code, 204)
        db = SessionLocal()
        try:
            visit = db.query(VisitLog).order_by(VisitLog.id.desc()).first()
            self.assertEqual(visit.ip, "203.0.113.10")
        finally:
            db.close()


if __name__ == "__main__":
    unittest.main()
