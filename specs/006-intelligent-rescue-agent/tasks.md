---
description: "Task list for Intelligent Rescue Agent"
---

# Tasks: Intelligent Rescue Agent (v1.5.0)

**Input**: Design documents from `/specs/006-intelligent-rescue-agent/`

## Phase 1: Python Agent Core

- [x] T001 Implement `get_file_hash` MD5 hashing utility.
- [x] T002 Implement `find_server` socket probe for known Mac IPs.
- [x] T003 [P] Implement `sync_files` with manifest parsing and checksum comparison.

## Phase 2: Updating & Persistence

- [x] T004 Implement `os.execv` self-update logic for version swaps.
- [x] T005 [P] Add file rename and `chmod` logic for safe updates.
- [x] T006 [P] Verify agent persists through a self-update without losing connection.

## Phase 3: Reporting & Feedback

- [x] T007 Implement 3-Phase verbose loop logging (`[1/3] Sync`, etc.).
- [x] T008 Add `garcon-url-handler` integration for ChromeOS popup support.
- [x] T009 [P] Implement exponential backoff for heartbeat polling (30s -> 300s).

## Phase 4: Integration

- [x] T010 Wire up the agent to the `pc_rescue_bootstrap.sh` handover logic.
- [x] T011 Verify end-to-end sync of `instructions.sh` results.
- [x] T012 [P] Confirm agent v1.5.0 reports "Cycle Complete" back to Mac.
