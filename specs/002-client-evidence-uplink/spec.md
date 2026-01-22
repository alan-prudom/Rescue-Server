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

### User Story 2 - Real-time Log Streaming (Priority: P2)
As a technician, I want to pipe command output directly to the Mac server.

**Acceptance Scenarios**:
1. **When** the user runs `ls -la | bash push_evidence.sh -`, **Then** the output is saved as a timestamped log on the Mac.

## Functional Requirements

- **FR-001**: System MUST provide an upload endpoint on the Mac (Python).
- **FR-002**: System MUST generate a `scripts/push_evidence.sh` Bash script on the PC side.
- **FR-003**: System MUST store uploaded files in a dedicated `evidence/` directory.
- **FR-004**: System MUST timestamp and prefix uploaded files to prevent name collisions.
- **FR-005**: System MUST prevent path traversal attacks (don't allow writing outside the evidence directory).
- **FR-006**: System MUST update the `index.html` dashboard to include a "View Resident Evidence" link.

## Success Criteria

- **SC-001**: File transfers complete over a 100Mbps LAN in <2s for a 5MB image.
- **SC-002**: Uploaded images are viewable by the AI using `view_file`.
