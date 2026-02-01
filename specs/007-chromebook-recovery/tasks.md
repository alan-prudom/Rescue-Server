---
description: "Task list for Chromebook Recovery & Integration"
---

# Tasks: Chromebook Recovery & Integration

**Input**: Design documents from `/specs/007-chromebook-recovery/`

## Phase 1: Lock Busting & Repair

- [x] T001 Implement `chromebook_fix.sh` specialized for Crostini locks.
- [x] T002 [P] Add aggressive `killall` and `rm` for all `/var/lib/dpkg/lock*` variants.
- [x] T003 [P] Add `sources.list` line repair logic (sed).

## Phase 2: Process Handover

- [x] T004 Update `pc_rescue_bootstrap.sh` to detect hostname `penguin`.
- [x] T005 [P] Implement `exec` handover to `rescue_agent.py` to avoid orphan shell processes.
- [x] T006 Implement `xdg-settings` browser handler fix (FR-CB-04).

## Phase 3: Performance & Documentation

- [x] T007 Create `cb_power_pack.sh` for Crostini storage linking.
- [x] T008 [P] Draft `CHROMEBOOK_MANUAL.md` evidence file.
- [x] T009 Update Help Guide (`system_help.html`) with VNC troubleshooting for ChromeOS.

## Phase 4: Verification

- [x] T010 Verify "One-Liner" from Mac dashboard works on fresh Chromebook Linux instance.
- [x] T011 [P] Confirm browser popping works via `garcon-url-handler`.
