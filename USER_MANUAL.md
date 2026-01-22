# 🚑 Rescue Server User Manual

This manual provides instructions and examples for using the Rescue Server to assist a LAN-locked PC during recovery operations.

---

## 1. Setup & Deployment (Mac Side)

The Rescue Server is deployed on a Mac to serve tools to a PC.

### Initialization
Run the setup utility to provision the rescue site:
```bash
bash setup_rescue_server.sh
```
*   **Default Location**: `~/Desktop/rescue-site`
*   **Result**: Creates folders for scripts, manuals, drivers, and evidence. Initializes a Git repository for auditing.

### Starting the Server
Navigate to the rescue site and launch the custom uplink server:
```bash
cd ~/Desktop/rescue-site
uv run python server/rescue_server.py 8000
```

---

## 2. Accessing the Dashboard (PC Side)

Open a web browser on the PC and enter the Mac's IP address:
`http://[MAC-IP]:8000`

The dashboard provides structured access to all folders and an "Instant Evidence" tool for troubleshooting.

---

## 3. Script Examples (PC/Technician)

### A. Downloading Tools
To download a script directly to the PC terminal:
```bash
# Example: Download the connection test tool
wget http://192.168.1.8:8000/scripts/test_connection.sh

# Run the tool
bash test_connection.sh
```

### B. Uploading Logs/Screenshots
Use the `push_evidence.sh` utility to send files back to the Mac for review:
```bash
# First, download the uploader
wget http://192.168.1.8:8000/scripts/push_evidence.sh

# Upload a log or screenshot
bash push_evidence.sh crash_dump.txt
bash push_evidence.sh bluescreen.png
```
*   **Where it goes**: Files are stored in the `evidence/` folder on the Mac with a timestamp prefix.

### C. Instant Text Evidence
If you have a snippet of text (like a terminal error) but don't want to save a file:
1.  Copy the text on the PC.
2.  Go to the **Web Dashboard**.
3.  Paste into the **Instant Evidence** box.
4.  Click **Save Evidence**.
5.  The AI on the Mac can now see it in `evidence/[DATE]_paste.txt`.

---

## 4. Managing Evidence (Mac/AI Side)

When evidence is uploaded, the Mac operator (or AI assistant) can view it using standard tools:

```bash
# List all received evidence
ls ~/Desktop/rescue-site/evidence/

# View a text log
cat ~/Desktop/rescue-site/evidence/20260122_1200_crash.txt
```

---

## 5. Audit Compliance

Every setup and deployment action is logged automatically.
-   **Audit Log**: `~/Desktop/rescue-site/audit_logs/server_audit.log`
-   **Versioning**: Use `git log` inside the rescue site to see the history of changes.

```bash
cd ~/Desktop/rescue-site
git log --oneline
```

---

## ❓ Getting Help
Every deployment includes an offline-friendly help guide. Visit:
`http://[MAC-IP]:8000/manuals/system_help.html`
