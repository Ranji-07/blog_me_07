import os
import tempfile
import unittest
import warnings
from pathlib import Path

os.environ.setdefault("DATABASE_URL", f"sqlite:///{Path(tempfile.gettempdir()) / 'portfolio_test.db'}")
os.environ.setdefault("ADMIN_EMAIL", "admin@portfolio.dev")
os.environ.setdefault("ADMIN_API_KEY", "super-secret-admin-key")
os.environ.setdefault("SMTP_EMAIL", "admin@portfolio.dev")
os.environ.setdefault("SMTP_PASSWORD", "dummy-password")
os.environ.setdefault("EMAIL_DELIVERY_MODE", "disabled")

warnings.filterwarnings(
    "ignore",
    message="The 'app' shortcut is now deprecated.*",
    category=DeprecationWarning,
)
warnings.filterwarnings(
    "ignore",
    category=DeprecationWarning,
    module=r"httpx\._client",
)
warnings.simplefilter("ignore", DeprecationWarning)

from fastapi.testclient import TestClient

from app.database import Base, SessionLocal, engine
from app.init_db import init_database
from app.main import app
from app.models import VisitLog


class PortfolioApiTests(unittest.TestCase):
    admin_headers = {"X-Admin-Token": "super-secret-admin-key"}

    @classmethod
    def setUpClass(cls):
        Base.metadata.drop_all(bind=engine)
        Base.metadata.create_all(bind=engine)
        init_database()
        cls.client = TestClient(app)

    def test_public_sections_are_available(self):
        response = self.client.get("/api/portfolio/about")
        self.assertEqual(response.status_code, 200)
        self.assertIn("name", response.json())

    def test_visit_analytics_is_recorded(self):
        response = self.client.post(
            "/api/analytics/visit",
            headers={
                "x-forwarded-for": "203.0.113.10",
                "user-agent": "PortfolioApiTest/1.0",
            },
        )
        self.assertEqual(response.status_code, 204)

        db = SessionLocal()
        try:
            visit = db.query(VisitLog).order_by(VisitLog.id.desc()).first()
            self.assertIsNotNone(visit)
            self.assertEqual(visit.ip, "203.0.113.10")
            self.assertEqual(visit.user_agent, "PortfolioApiTest/1.0")
        finally:
            db.close()

    def test_admin_command_can_be_confirmed_end_to_end(self):
        request_payload = {
            "action": "set_status",
            "section": "about",
            "target_id": None,
            "payload": {
                "status": "draft"
            },
            "auth_email": "admin@portfolio.dev",
            "admin_token": "super-secret-admin-key",
        }
        pending = self.client.post("/api/admin/email-command", json=request_payload, headers=self.admin_headers)
        self.assertEqual(pending.status_code, 200)
        token = pending.json()["data"]["token"]

        confirmed = self.client.get(
            f"/api/admin/confirm/{token}",
            params={"auth_email": "admin@portfolio.dev", "admin_token": "super-secret-admin-key"},
            headers=self.admin_headers,
        )
        self.assertEqual(confirmed.status_code, 200)
        self.assertEqual(confirmed.json()["data"]["action"], "set_status")

        about = self.client.get("/api/portfolio/about")
        self.assertEqual(about.status_code, 200)
        self.assertEqual(about.json()["status"], "draft")

        history = self.client.get(
            "/api/admin/history",
            params={"auth_email": "admin@portfolio.dev", "admin_token": "super-secret-admin-key", "section": "about"},
            headers=self.admin_headers,
        )
        self.assertEqual(history.status_code, 200)
        self.assertGreaterEqual(len(history.json()["data"]["versions"]), 1)
        self.assertEqual(history.json()["data"]["versions"][0]["action"], "set_status")
        self.assertIn("+00:00", history.json()["data"]["versions"][0]["created_at"])

    def test_invalid_schema_payload_is_rejected_on_confirm(self):
        request_payload = {
            "action": "create",
            "section": "about",
            "target_id": None,
            "payload": {
                "name": "Broken Payload"
            },
            "auth_email": "admin@portfolio.dev",
            "admin_token": "super-secret-admin-key",
        }
        pending = self.client.post("/api/admin/email-command", json=request_payload, headers=self.admin_headers)
        self.assertEqual(pending.status_code, 200)
        token = pending.json()["data"]["token"]

        confirmed = self.client.get(
            f"/api/admin/confirm/{token}",
            params={"auth_email": "admin@portfolio.dev", "admin_token": "super-secret-admin-key"},
            headers=self.admin_headers,
        )
        self.assertEqual(confirmed.status_code, 400)
        self.assertIn("Schema validation failed", confirmed.json()["detail"])

    def test_admin_command_requires_token(self):
        request_payload = {
            "action": "set_status",
            "section": "about",
            "payload": {
                "status": "published"
            },
            "auth_email": "admin@portfolio.dev",
            "admin_token": "wrong-token-but-long-enough",
        }
        response = self.client.post("/api/admin/email-command", json=request_payload)
        self.assertEqual(response.status_code, 403)

    def test_history_rollback_restores_previous_snapshot(self):
        baseline_payload = {
            "action": "set_status",
            "section": "about",
            "payload": {
                "status": "published"
            },
            "auth_email": "admin@portfolio.dev",
            "admin_token": "super-secret-admin-key",
        }
        baseline_pending = self.client.post("/api/admin/email-command", json=baseline_payload, headers=self.admin_headers)
        self.assertEqual(baseline_pending.status_code, 200)
        baseline_token = baseline_pending.json()["data"]["token"]

        baseline_confirmed = self.client.get(
            f"/api/admin/confirm/{baseline_token}",
            params={"auth_email": "admin@portfolio.dev", "admin_token": "super-secret-admin-key"},
            headers=self.admin_headers,
        )
        self.assertEqual(baseline_confirmed.status_code, 200)

        request_payload = {
            "action": "set_status",
            "section": "about",
            "payload": {
                "status": "draft"
            },
            "auth_email": "admin@portfolio.dev",
            "admin_token": "super-secret-admin-key",
        }
        pending = self.client.post("/api/admin/email-command", json=request_payload, headers=self.admin_headers)
        self.assertEqual(pending.status_code, 200)
        token = pending.json()["data"]["token"]

        confirmed = self.client.get(
            f"/api/admin/confirm/{token}",
            params={"auth_email": "admin@portfolio.dev", "admin_token": "super-secret-admin-key"},
            headers=self.admin_headers,
        )
        self.assertEqual(confirmed.status_code, 200)

        history = self.client.get(
            "/api/admin/history",
            params={"auth_email": "admin@portfolio.dev", "admin_token": "super-secret-admin-key", "section": "about"},
            headers=self.admin_headers,
        )
        self.assertEqual(history.status_code, 200)
        target_version = next(
            item for item in history.json()["data"]["versions"]
            if item["action"] == "set_status" and item["snapshot_after"]["status"] == "draft"
        )

        rollback = self.client.post(
            f"/api/admin/history/{target_version['id']}/rollback",
            params={"auth_email": "admin@portfolio.dev", "admin_token": "super-secret-admin-key"},
            headers=self.admin_headers,
        )
        self.assertEqual(rollback.status_code, 200)
        self.assertEqual(rollback.json()["data"]["rolled_back_version_id"], target_version["id"])

        about = self.client.get("/api/portfolio/about")
        self.assertEqual(about.status_code, 200)
        self.assertNotEqual(about.json()["status"], "draft")

        history_after = self.client.get(
            "/api/admin/history",
            params={"auth_email": "admin@portfolio.dev", "admin_token": "super-secret-admin-key", "section": "about"},
            headers=self.admin_headers,
        )
        self.assertEqual(history_after.status_code, 200)
        self.assertEqual(history_after.json()["data"]["versions"][0]["action"], "rollback")


if __name__ == "__main__":
    unittest.main()
