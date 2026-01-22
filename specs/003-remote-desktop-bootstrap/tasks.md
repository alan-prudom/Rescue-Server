# Tasks: Remote Desktop Bootstrap

## Phase 1: Foundation
- [ ] T001: Create start_vnc.sh framework and OS detection
- [ ] T002: Implement X11/Wayland check (fail fast on Wayland if needed)
- [ ] T003: Implement VNC server capability check (x11vnc, etc.)

## Phase 2: Configuration
- [ ] T004: Implement password setup ("rescue")
- [ ] T005: Add macOS compatibility flags (-noxdamage, -nopw, etc. as needed)
- [ ] T006: Add internet check and package install fallback

## Phase 3: Integration
- [ ] T007: Embed `start_vnc.sh` generator into main `setup_rescue_server.sh`
- [ ] T008: Update `system_help.html` guide
- [ ] T009: Test with macOS Screen Sharing
