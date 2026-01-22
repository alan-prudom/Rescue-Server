---
description: "Tasks for Evidence Uplink"
---

# Tasks: Evidence Uplink

## Phase 1: Foundation
- [x] T001 Create `server/rescue_server.py` with custom `SimpleHTTPRequestHandler`
- [x] T002 Implement basic `do_GET` (parity with `http.server`)
- [x] T003 [P] Implement `do_POST` for file uploads (FR-001)

## Phase 2: Client Tooling
- [x] T004 Implement `create_push_evidence_script` in `setup_rescue_server.sh` (FR-002)
- [x] T005 [P] Create unit test for upload script in `tests/integration/test_upload.sh`

## Phase 3: Dashboard & UX
- [x] T006 Update `create_index_html` to add evidence folder link (FR-006)
- [x] T007 Integration: Launch the new server script during setup
