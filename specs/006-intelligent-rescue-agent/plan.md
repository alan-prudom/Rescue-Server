# Plan: Intelligent Rescue Agent (v1.5.0)

**Spec**: `006-intelligent-agent/spec.md`
**Goal**: Transition from a "dumb" polling script to a "smart" self-updating agent that handles sync and reporting.

## 1. Core Logic Development
- [x] Implement `get_file_hash` using Python's `hashlib`.
- [x] Implement `sync_files` to fetch the Mac server's `/manifest/` and compare remote vs local hashes.
- [x] Create a safe "download-to-temp" verify-then-move logic.

## 2. Self-Update Mechanism
- [x] Implement the "Hot Swap" logic using `os.execv`.
- [x] Ensure permissions are preserved (`chmod +x`) after an overwrite.
- [x] Add heartbeat markers indicating a version upgrade is occurring.

## 3. Reporting & Cycle
- [x] Design the 3-phase loop: Sync -> Instruction -> Heartbeat.
- [x] Integrate `garcon-url-handler` for Chromebook-native browser popping of results.
- [x] Add exponential backoff (30s to 300s) to reduce Mac server load during idle times.

## 4. Verification
- [x] Verify that updating the Mac's `rescue_agent.py` triggers an auto-restart on the client (`penguin`).
- [x] Verify that `instructions.sh` injection triggers a result popup.
