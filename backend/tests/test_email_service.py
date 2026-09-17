import base64
import unittest
from email import message_from_bytes
from unittest.mock import patch

from app.services import email_service


class GmailDeliveryTests(unittest.TestCase):
    def test_gmail_api_sends_mime_with_reply_address_and_html(self):
        with patch.object(email_service, "EMAIL_DELIVERY_MODE", "gmail_api"), patch.object(
            email_service, "GMAIL_SENDER_EMAIL", "owner@example.com"
        ), patch.object(email_service, "can_send_real_email", return_value=True), patch.object(
            email_service, "load_send_credentials", return_value=object()
        ), patch("googleapiclient.discovery.build") as build:
            send = build.return_value.users.return_value.messages.return_value.send
            send.return_value.execute.return_value = {"id": "gmail-message-1"}
            result = email_service.send_email(
                "visitor@example.com",
                "Your message",
                "<p>Hello</p>",
                reply_to="owner@example.com",
                plain_body="Hello",
            )

        self.assertTrue(result)
        raw = send.call_args.kwargs["body"]["raw"]
        message = message_from_bytes(base64.urlsafe_b64decode(raw))
        self.assertEqual(message["To"], "visitor@example.com")
        self.assertEqual(message["Reply-To"], "owner@example.com")
        self.assertEqual(message["From"], "owner@example.com")
        self.assertIn("<p>Hello</p>", message.get_payload()[1].get_payload(decode=True).decode())


if __name__ == "__main__":
    unittest.main()
