# Feature Specification: Intelligent Rescue Agent (v1.5.0)

**Feature Branch**: `006-intelligent-agent`
**Created**: 2026-01-25
**Status**: Stable / Implemented

## Overview
The Intelligent Rescue Agent is a Python-based client that replaces the standard Bash bootstrap on advanced systems (like Chromebooks). It provides self-updating, checksum-verified synchronization, and verbose status reporting.

## User Scenarios

### User Story 1 - Self-Healing Agent (Priority: P1)
As a technician, I want the agent to automatically update itself when I push a new version to the Mac server, so I don't have to manually re-run `wget` commands on every client.

**Acceptance Scenarios**:
1. **Given** an agent is running v1.4.0, **When** the `rescue_agent.py` on the Mac is updated to v1.5.0, **Then** the agent downloads the new version, verifies its hash, and restarts itself using `os.execv`.

### User Story 2 - Full Loop Transparency (Priority: P2)
As an operator monitoring the dashboard, I want to see exactly what phase of the loop the agent is in, so I can distinguish between "waiting for instructions" and "checking for updates."

**Acceptance Scenarios**:
1. **When** the agent heartbeats, **Then** it must include its current phase (e.g., `[1/3] Sync`, `[3/3] Heartbeat`) in the status message.

---

## Functional Requirements

- **FR-AGT-01**: Agent MUST calculate MD5 checksums of all files in the server's `scripts/` directory before downloading.
- **FR-AGT-02**: Agent MUST download updated scripts to a `.tmp` file and verify the hash BEFORE overwriting the live script.
- **FR-AGT-03**: Agent MUST perform a "Hot Swap" of itself if `rescue_agent.py` has a hash mismatch, preserving CLI arguments.
- **FR-AGT-04**: Agent MUST implement a three-phase cycle:
    1. **Sync**: Verify manifest hashes.
    2. **Injected Instruction**: Check for `instructions.sh` changes and execute if detected.
    3. **Heartbeat**: Report status and enter exponential backoff sleep.
- **FR-AGT-05**: Agent MUST use `garcon-url-handler` (if available) or `xdg-open` to pop HTML reports on the client side.
- **FR-AGT-06**: Agent MUST set the Mac server's IP dynamically by probing a known list of common IPs if no server URL is provided on launch.

## Success Criteria

- **SC-AGT-01**: Agent successfully transitions between versions (e.g., 1.4.1 -> 1.5.0) in under 60 seconds without manual intervention.
- **SC-AGT-02**: Checksum mismatch results in a re-download; identical hashes result in zero network transfer for existing scripts.
