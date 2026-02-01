# Feature Specification: Client Evidence Uplink

**Feature Branch**: `002-client-evidence-uplink`
**Created**: 2026-01-22
**Status**: Draft
**Input**: User request: "send screenshots and any text logs back to the mac server"

## User Scenarios & Testing

### User Story 1 - Evidence Upload (Priority: P1)
As a technician working on the PC, I want to run a script to upload a screenshot or a log file to the Mac server so that the diagnostic AI on the Mac can analyze it.

**Why this priority**: Essential for remote debugging when the technician can't physically show the screen.

**Acceptance Scenarios**:
1. **Given** a log file `error.txt` exists on the PC, **When** the user runs `bash push_evidence.sh error.txt`, **Then** the file is stored in `incoming_evidence/` on the Mac.
2. **Given** a screenshot `crash.png` exists on the PC, **When** uploaded, **Then** it is visible to the Mac's filesystem tools.

---

### User Story 3 - Instant Evidence (Priority: P1)
As a technician, I want to paste terminal output or notes directly into a browser text area on the PC and have it saved as a file on the Mac server.

**Why this priority**: Saves time when dealing with single-line errors or short logs that don't warrant a file transfer.

**Acceptance Scenarios**:
1. **When** the user pastes text into the "Instant Evidence" area and clicks save, **Then** a timestamped `.txt` file is created in the `evidence/` directory on the Mac.

## Functional Requirements

- **FR-001**: System MUST provide an upload endpoint on the Mac (Python).
- **FR-002**: System MUST generate a `scripts/push_evidence.sh` Bash script on the PC side.
- **FR-003**: System MUST store uploaded files in a dedicated `evidence/` directory.
- **FR-004**: System MUST timestamp and prefix uploaded files to prevent name collisions.
- **FR-005**: System MUST prevent path traversal attacks (don't allow writing outside the evidence directory).
- **FR-006**: System MUST update the `index.html` dashboard to include a "Browse Uploaded Evidence" link and an "Instant Evidence" paste area.
- **FR-007**: System MUST support `application/x-www-form-urlencoded` POST requests for text pastes.

## Success Criteria

- **SC-001**: File transfers complete over a 100Mbps LAN in <2s for a 5MB image.
- **SC-002**: Uploaded images are viewable by the AI using `view_file`.
