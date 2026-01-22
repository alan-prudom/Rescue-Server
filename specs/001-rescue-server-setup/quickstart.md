# Rescue Server Quickstart

## 1. Prerequisites
- **macOS** (Host)
- **Terminal** access
- **Git** installed (`git --version`)
- **Python 3** installed (`python3 --version`)

## 2. Setup
Run the setup script from the project root:

```bash
./setup_rescue_server.sh
```

The script will:
1. Create `~/Desktop/rescue-site`.
2. Generate the dashboard.
3. Initialize the audit log (Git).
4. Ask to launch the server.

## 3. Operations

### Start Server Manually
```bash
cd ~/Desktop/rescue-site
uv python -m http.server 8000
```

### Accessing Dashboard
On the broken PC, open a browser and navigate to:
`http://[MAC-IP]:8000`

### Auditing
View the history of the rescue site:
```bash
cd ~/Desktop/rescue-site
git log
tail audit_logs/server_audit.log
```
