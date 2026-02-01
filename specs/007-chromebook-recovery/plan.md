# Plan: Chromebook Recovery & Integration

**Spec**: `007-chromebook-recovery/spec.md`
**Goal**: Resolve environmental blocks and ensure smooth agent lifecycle on ChromeOS/Crostini.

## 1. System Repair (The "Fix" Script)
- [x] Create `chromebook_fix.sh` with lock-buster logic.
- [x] Add logic to comment out malformed `apt` sources.
- [x] Add auto-detection of the Mac IP within the script to ensure standalone runtime.

## 2. Integrated Handover
- [x] Modify `pc_rescue_bootstrap.sh` to include a Chromebook-check.
- [x] Implement `exec python3 rescue_agent.py` to handover process control.
- [x] Add `xdg-settings` fix for browser redirection.

## 3. Power Pack
- [x] Implement `cb_power_pack.sh` for optional performance and integration improvements (e.g., shared folder link).

## 4. Documentation
- [x] Create `CHROMEBOOK_MANUAL.md` with walkthroughs for common "Dangerous File" blocks and privilege escalation.
