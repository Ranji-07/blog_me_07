# Email Templates

## Delivery Modes

- `EMAIL_DELIVERY_MODE=log`
  Local-safe mode. Emails are written to `dev_outbox/` as HTML files and no SMTP connection is attempted.
- `EMAIL_DELIVERY_MODE=disabled`
  No email is sent or saved. Useful for tests.
- `EMAIL_DELIVERY_MODE=smtp`
  Real SMTP delivery. Requires `SMTP_SERVER`, `SMTP_PORT`, `SMTP_EMAIL`, `SMTP_PASSWORD`, `ADMIN_EMAIL`, and `ADMIN_API_KEY` for full admin flow.

For local development, `start-local.bat` now forces `EMAIL_DELIVERY_MODE=log`.

These templates are for the mail-controlled admin flow where the user sends JSON commands and receives confirmation or result emails.

## 1. Update Confirmation

Subject:

```text
Confirm Portfolio Update
```

HTML template:

```html
<h2>Confirm Portfolio Update</h2>
<p>A content update was requested for your portfolio.</p>
<p><strong>Action:</strong> {{action}}</p>
<p><strong>Section:</strong> {{section}}</p>
<p><strong>Status:</strong> {{status}}</p>
<pre>{{payload_json}}</pre>
<p>
  <a href="{{confirmation_url}}" style="display:inline-block;padding:12px 20px;border-radius:999px;background:#16A34A;color:#fff;text-decoration:none;">
    Confirm Update
  </a>
</p>
<p>If you did not request this update, ignore this email.</p>
```

## 2. Update Success

Subject:

```text
Portfolio Updated Successfully
```

HTML template:

```html
<h2>Portfolio Updated</h2>
<p>Your portfolio content has been updated successfully.</p>
<ul>
  <li><strong>Action:</strong> {{action}}</li>
  <li><strong>Section:</strong> {{section}}</li>
  <li><strong>Visibility:</strong> {{visibility}}</li>
  <li><strong>State:</strong> {{state}}</li>
</ul>
<p><strong>Updated by:</strong> {{updated_by}}</p>
<p><strong>Updated at:</strong> {{updated_at}}</p>
```

## 3. Delete Confirmation

Subject:

```text
Confirm Portfolio Delete Action
```

HTML template:

```html
<h2>Confirm Delete Action</h2>
<p>A delete request was made for portfolio content.</p>
<ul>
  <li><strong>Action:</strong> delete</li>
  <li><strong>Section:</strong> {{section}}</li>
  <li><strong>Target ID:</strong> {{target_id}}</li>
</ul>
<pre>{{payload_json}}</pre>
<p>
  <a href="{{confirmation_url}}" style="display:inline-block;padding:12px 20px;border-radius:999px;background:#DC2626;color:#fff;text-decoration:none;">
    Confirm Delete
  </a>
</p>
```

## 4. Visibility / In-Progress Status Change

Subject:

```text
Portfolio Visibility Status Updated
```

HTML template:

```html
<h2>Visibility Status Updated</h2>
<p>The portfolio visibility or progress status has changed.</p>
<ul>
  <li><strong>Section:</strong> {{section}}</li>
  <li><strong>Visibility:</strong> {{visibility}}</li>
  <li><strong>State:</strong> {{state}}</li>
  <li><strong>Status Message:</strong> {{status_message}}</li>
</ul>
```

## 5. Asset Upload Success

Subject:

```text
Portfolio Asset Uploaded
```

HTML template:

```html
<h2>Asset Uploaded</h2>
<p>A portfolio asset was uploaded successfully.</p>
<ul>
  <li><strong>File name:</strong> {{file_name}}</li>
  <li><strong>Asset URL:</strong> {{asset_url}}</li>
  <li><strong>Asset Type:</strong> {{asset_type}}</li>
</ul>
<p>Use this URL inside JSON fields like <code>image_url</code> or <code>icon_url</code>.</p>
```

## 6. Incoming Mail Command JSON Format

Recommended JSON body for admin mail-triggered commands:

```json
{
  "action": "update",
  "section": "about",
  "target_id": null,
  "auth_email": "admin@portfolio.dev",
  "payload": {
    "status": {
      "visibility": "visible",
      "state": "published",
      "status_message": "Live"
    }
  }
}
```

Supported actions:

- `create`
- `update`
- `delete`
- `set_visibility`
- `set_status`
- `upload_asset`

Supported visibility/state values:

- visibility: `visible`, `hidden`, `in_progress`
- state: `draft`, `published`, `archived`
