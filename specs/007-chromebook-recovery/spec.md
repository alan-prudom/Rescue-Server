# Feature Specification: Chromebook Recovery & Integration

**Feature Branch**: `007-chromebook-recovery`
**Created**: 2026-01-25
**Status**: Stable / Implemented

## Overview
This specification details the specialized recovery tools and integration fixes required to run the PC Rescue Station within the Google ChromeOS (Crostini) Linux container environment.

## User Scenarios

### User Story 1 - Broken Package Manager (Priority: P1)
As a user with a Chromebook, I often find that `apt` is locked by background tasks or the `sources.list` is malformed. I want a script that automatically "busts" these locks so I can install the rescue agent.

**Acceptance Scenarios**:
1. **Given** a locked `dpkg` database, **When** `chromebook_fix.sh` is run, **Then** it kills hung processes, removes lock files, and runs `dpkg --configure -a`.

### User Story 2 - Automated Handover (Priority: P1)
As an operator, I want to use my standard Mac bootstrap script on a Chromebook and have it automatically upgrade to the Intelligent Agent if it detects it's on a Chromebook.

**Acceptance Scenarios**:
1. **Given** a Chromebook (`penguin`), **When** the standard bootstrap is run, **Then** it detects the hostname and `python3`, and automatically `exec`s the `rescue_agent.py`.

---

## Functional Requirements

- **FR-CB-01**: System MUST provide a `chromebook_fix.sh` specialized for the Crostini environment.
- **FR-CB-02**: System MUST implement "Lock Buster" logic: `sudo killall apt apt-get dpkg` and `rm` on all standard lock files.
- **FR-CB-03**: System MUST repair common malformed `sources.list` entries (e.g., commenting out bad line 5).
- **FR-CB-04**: System MUST force browser integration: setting `xdg-settings set default-web-browser garcon-url-handler.desktop`.
- **FR-CB-05**: Master bootstrap MUST detect hostname `penguin` and perform a process handover to Python 3.

## Success Criteria

- **SC-CB-01**: `chromebook_fix.sh` successfully recovers a system with a locked package manager.
- **SC-CB-02**: Clicking a link in an injected report opens Chrome on the Chromebook instead of a terminal editor.
