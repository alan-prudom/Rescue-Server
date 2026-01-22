# Implementation Plan: Client Evidence Uplink

**Branch**: `002-client-evidence-uplink` | **Date**: 2026-01-22 | **Spec**: [specs/002-client-evidence-uplink/spec.md](spec.md)

## Summary
Upgrade the Rescue Server from a simple `http.server` to a custom Python module that supports both static file serving and POST file uploads. Provide a client-side Bash utility to facilitate easy uploading.

## Technical Context
- **Language**: Python 3 (standard lib `http.server` / `base64` / `pathlib`).
- **Protocol**: HTTP POST (Multipart/form-data).
- **Client**: Bash + `curl`.

## Structure
- `server/rescue_server.py`: The new custom server logic.
- `scripts/push_evidence.sh`: Generated client tool.
- `evidence/`: Destination folder.

## Task Breakdown
1. Create `server/rescue_server.py` replacing the default `http.server`.
2. Implement `do_POST` handler with file buffering and safety checks.
3. Update `setup_rescue_server.sh` to generate the new `push_evidence.sh`.
4. Update dashboard to link to the new evidence directory.
