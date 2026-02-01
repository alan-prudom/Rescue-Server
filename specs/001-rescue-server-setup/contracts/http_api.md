# API Contract: Rescue Server (v2.0)

**Protocol**: HTTP/1.0 or HTTP/1.1
**Port**: 8000 (Default)

---

## 🟢 GET Endpoints

### `GET /` or `GET /index.html`

- **Description**: Returns the dynamic PC Rescue Dashboard.
- **Parameters**: None.
- **Response**: `200 OK` (text/html). Injects Mac IP, PC IP, and PC Name into template.

### `GET /feed/`

- **Description**: Returns the Rescue Command Centre (Live activity feed).
- **Response**: `200 OK` (text/html). Aggregates IP-based logs into a unified view.

### `GET /manifest/`

- **Description**: Returns a JSON manifest of all files in the `scripts/` directory.
- **Response**: `200 OK` (application/json) containing filename, MD5 hash, and size.
- **Used By**: Intelligent Agent for Smart Sync.

### `GET /scripts/*`, `/manuals/*`, `/drivers/*`, `/evidence/*`

- **Description**: Static file serving from the respective directories.
- **Response**: `200 OK` with appropriate mime-type or `404 Not Found`.

### `GET /proxy?url=...`

- **Description**: Proxy download endpoint. Downloads remote URL to `downloads_cache/` and streams to client.
- **Response**: `200 OK` (file stream) or `400/500` on error.

### `GET /diag_vnc?ip=...`

- **Description**: Triggers a server-side VNC probe (using `vnc_diag.py`) against a target IP.
- **Response**: `200 OK` (application/json) with status, port, and log.

### `GET /shutdown`

- **Description**: Graceful remote shutdown of the Mac server.
- **Response**: `200 OK`. Server exits after 1 second delay.

---

## 🔵 POST Endpoints

### `POST /`

- **Description**: Multi-purpose upload and paste endpoint.
- **Supported Content-Types**:
  - `multipart/form-data`: Stores the uploaded file in `evidence/<CLIENT_IP>/` with a timestamp.
  - `application/x-www-form-urlencoded`: Expects a `content` field.
    - If `content` starts with `[BOOTSTRAP]`, `[AGENT]`, etc., it appends to `audit_logs/<CLIENT_IP>/client_activity.log`.
    - Otherwise, it saves the content as a timestamped `.txt` file in `evidence/<CLIENT_IP>/`.
  - `raw`: Stores any other POST body as a `.log` file in the evidence directory.
- **Response**: `200 OK` (text/plain) on success.

---

## 🛡️ Security & Constraints

- **Self-Healing Logs**: If a `[BOOTSTRAP]` message is received, the activity log for that IP is truncated to start a fresh session trace.
- **IP Isolation**: All logs and evidence are strictly partitioned by the client's source IP address.
- **UTF-8 Requirement**: All text responses MUST use UTF-8 encoding.
