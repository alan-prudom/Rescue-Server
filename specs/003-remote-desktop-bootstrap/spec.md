# Feature Specification: Remote Desktop Bootstrap

**Feature Branch**: `003-remote-desktop-bootstrap`
**Created**: 2026-01-22
**Status**: Draft
**Input**: User request: "run a remote desktop (VNC) from the linux live CD to view it on my mac"

## User Scenarios & Testing

### User Story 1 - One-Click VNC Launch (Priority: P1)
As a technician, I want to download and run a single script on the Linux PC that automatically starts a VNC server so I can connect from my Mac.

**Why this priority**: Eliminates the manual configuration of X11/Wayland and auth settings, which is painful on live systems.

**Acceptance Scenarios**:
1. **Given** a PC running Ubuntu/Fedora Live ISO, **When** `bash start_vnc.sh` is run, **Then** it detects the desktop environment and starts a VNC server on port 5900.
2. **Given** the server starts, **When** successful, **Then** it prints a connection URL (e.g., `vnc://[PC-IP]:5900`) visible to the user.

### User Story 2 - Mac Compatibility (Priority: P1)
As a Mac user, I want the VNC server to be configured specifically for macOS "Screen Sharing.app" compatibility.

**Acceptance Scenarios**:
1. **When** the VNC server starts, **Then** it disables encryption/security types that are known to break macOS Screen Sharing (e.g., forcing standard VNC auth or no-auth).

## Functional Requirements

- **FR-001**: System MUST provide a `scripts/start_vnc.sh` script served via the Mac dashboard.
- **FR-002**: The script MUST detect the running OS/Distro (Ubuntu, Fedora, Debian, SystemRescue).
- **FR-003**: The script MUST attempt to locate pre-installed VNC binaries (e.g. `x11vnc`, `tigervnc`, `vino`).
- **FR-004**: If no VNC server is found, the script MUST attempt to install `x11vnc` via the package manager (`apt`, `dnf`, `pacman`) if internet is available.
- **FR-005**: The script MUST configure the VNC server to accept connections from the Mac (0.0.0.0 binding) with a simple password (default: "rescue").
- **FR-006**: The script MUST output a clear `vnc://` connection string for the user to copy.

## Success Criteria

- **SC-001**: `start_vnc.sh` successfully launches a VNC session on a standard Ubuntu 24.04 Live ISO.
- **SC-002**: macOS Screen Sharing can connect to the session without protocol errors.
