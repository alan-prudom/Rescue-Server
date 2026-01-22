# Feature Specification: Rescue Server Setup Utility

**Feature Branch**: `001-rescue-server-setup`  
**Created**: 2026-01-22  
**Status**: Draft  
**Input**: User description: "examine setup_rescue_server.sh and deduce a specification"

## Clarifications

### Session 2026-01-22

- Q: Should the script handle permissions and auto-launch? → A: Yes, script should self-chmod +x and provide an interactive prompt to launch the server immediately.
- Q: How should we address the new Constitutional requirements? → A: Spec updated to mandate Git initialization, audit logging, and Bash interfaces (Option A).
- Q: How should the dashboard link to content? → A: Dynamic Linking (Link to /drivers/, rely on server auto-index).
- Q: What client tools are in scope for MVP? → A: `test_connection.sh` AND `push_evidence.sh` (as per Constitution V).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Structured Repository Creation (Priority: P1)

As a technician with a Mac and a PC, I want to run a single setup command on my Mac to create a structured repository of rescue tools so I can easily share them with my PC.

**Why this priority**: Essential for establishing the file structure and dashboard needed for the rescue operation.

**Independent Test**: Can be fully tested by running the setup script and verifying the creation of `~/Desktop/rescue-site/` with its subdirectories and `index.html`.

**Acceptance Scenarios**:

1. **Given** no rescue site exists, **When** the setup script is executed, **Then** a directory `~/Desktop/rescue-site` is created with `scripts`, `manuals`, `drivers`, and `audit_logs` subfolders.
2. **Given** the directories are created, **When** the script finishes, **Then** an `index.html` file exists in the root of the site directory.
3. **Given** the script creates a sample script `scripts/test_connection.sh`, **When** inspected, **Then** the file must have executable permissions (`chmod +x`).

---

### User Story 2 - Server Launch Automation (Priority: P1)

As a user who has just run the setup, I want the option to immediately start the file server without typing additional commands.

**Why this priority**: Streamlines the workflow to a "one-click" experience.

**Independent Test**: Run the script and interact with the "Start server?" prompt.

**Acceptance Scenarios**:

1. **Given** the setup is complete, **When** the script reaches the end, **Then** it prompts: "Do you want to start the server now? [y/N]".
2. **Given** the user answers "y" or "Y", **When** processed, **Then** the script executes `cd ~/Desktop/rescue-site && uv run python server/rescue_server.py 8000` and keeps running.
3. **Given** the user answers "n" or "N", **When** processed, **Then** the script exits and prints manual launch instructions.

---

### User Story 3 - Audit & Versioning Initialization (Priority: P1)

As a technician, I need all technical actions to be auditable. The system must initialize a Git repository to track changes to the rescue tools and logs.

**Why this priority**: Mandated by Constitution Principle V (State Auditing & Versioning).

**Independent Test**: Run setup and verify `.git` directory exists and `audit_logs` are tracked.

**Acceptance Scenarios**:

1. **Given** setup runs, **When** directories are created, **Then** `git init` must be executed in the `rescue-site` root.
2. **Given** git is initialized, **When** initial files are created, **Then** an initial commit "Initial commit: Rescue Server Setup" must be made.
3. **Given** the setup process runs, **When** complete, **Then** a log entry is written to `audit_logs/server_audit.log` (or similar) recording the initialization timestamp.
4. **Given** setup completes, **When** `scripts/` is checked, **Then** a `push_evidence.sh` script exists for client-side logging and uploads.

---

### User Story 4 - Dashboard Accessibility (Priority: P2)

As a user on the PC, I want to visit the server's URL and see a dashboard that allows me to browse and download scripts, manuals, and drivers.

**Why this priority**: Improves user experience and efficiency during the rescue process by providing a graphical interface.

**Independent Test**: Can be tested by starting the server and accessing the dashboard from another device on the same network.

**Acceptance Scenarios**:

1. **Given** the server is running, **When** a user visits the URL on a PC, **Then** they see the "PC Rescue Station" dashboard.
2. **Given** the dashboard is loaded, **When** the user clicks "Browse Scripts Directory", **Then** they are taken to the dynamic file listing of `/scripts/`.

---

### Edge Cases

- **What happens when the Mac has no active network interface?** The system should provide a placeholder instruction `http://[YOUR-IP-ADDRESS]:8000` and inform the user that auto-detection failed.
- **How does system handle existing directories?** The system uses `mkdir -p` to ensure it doesn't fail if directories already exist, effectively performing an "update" or "safe re-run".
- **What if the port 8000 is occupied?** The `http.server` module will fail. The script should ideally fail gracefully or the user will see the error output from python. For this spec, standard python error output is acceptable.
- **What if git is not installed?** Implementation should check for `git` presence. If missing, warn user but proceed with file operational setup (non-fatal, though degrades auditability).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST create a base directory for the rescue site at `$HOME/Desktop/rescue-site`.
- **FR-002**: System MUST create subdirectories for `scripts`, `manuals`, `drivers`, and `audit_logs`.
- **FR-003**: System MUST generate an `index.html` file that links to the subdirectory paths (e.g. `<a href="scripts/">`) to leverage dynamic server indexing.
- **FR-004**: System MUST include a sample test script (`scripts/test_connection.sh`) to verify connection.
- **FR-005**: System MUST attempt to automatically detect the Mac's IP address (prioritizing `en0` then `en1`).
- **FR-006**: System MUST output clear, actionable instructions for starting the server manually.
- **FR-007**: System MUST set executable permissions (`chmod +x`) on the generated scripts and the setup script itself.
- **FR-008**: System MUST offer an interactive prompt ("Start server now? [y/N]") to launch the custom `server/rescue_server.py` (skip if non-interactive TTY).
- **FR-009**: System MUST initialize a git repository in the rescue site root (`git init`).
- **FR-010**: System MUST create a `.gitignore` file that excludes OS-specific metadata (e.g., `.DS_Store`, `Thumbs.db`) and temporary files.
- **FR-011**: System MUST create an initial commit with the exact message "Initial commit: Rescue Server Setup" containing all generated files and the `.gitignore`.
- **FR-012**: System MUST ensure all generated tools (host and client) are written for **Bash 3.2+** compatibility to ensure execution on legacy systems.
- **FR-013**: System MUST prohibit the use of non-Bash interpreters (Python, Node) within the tools generated inside the `scripts/` directory.
- **FR-014**: System MUST append audit events to `audit_logs/server_audit.log` using the format: `[YYYY-MM-DD HH:MM:SS] ACTION: <Description>`.
- **FR-015**: System MUST ensure the audit log file is append-only and is NOT tracked by Git after the initial commit (to avoid merge conflicts during rapid logging).
- **FR-016**: System MUST generate a `scripts/push_evidence.sh` utility script for the client that uses `curl` to send log entries and files to the server's evidence endpoint.
- **FR-017**: System MUST provide an integrated help guide (`manuals/system_help.html`) describing the repository structure and script usage.
- **FR-018**: System MUST ensure all HTML and server responses use **UTF-8 encoding** to prevent visual glitches with emojis and special characters.

### Key Entities

- **Rescue Site**: The root container for all shared materials, represented by the filesystem directory on the Mac.
- **Dashboard**: The web interface (HTML/CSS) that allows the PC to navigate the shared files.
- **IP Address**: The network identifier of the Mac, crucial for remote access.
- **Audit Log**: A persistent record of significant system events (`audit_logs/`).
- **Git Repo**: The version control store for the site content.
- **Bash Context**: The execution environment for scripts, constrained to version 3.2+ for maximum compatibility.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Initial setup completes in under 5 seconds (excluding user wait).
- **SC-002**: A PC on the same network can successfully visit the Mac's IP at port 8000 and render the dashboard.
- **SC-003**: `git status` inside the created directory shows a clean working tree (nothing uncommitted) immediately after setup.
- **SC-004**: Success rate for automatic IP detection is >90% on standard Mac configurations.
