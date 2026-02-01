---
description: "Task list for Rescue Command Centre"
---

# Tasks: Rescue Command Centre

**Input**: Design documents from `/specs/005-rescue-command-centre/`

## Phase 1: Real-time Display

- [x] T001 Implement `live_feed.html` with grid-based PC cards.
- [x] T002 Implement server-side logic in `rescue_server.py` to aggregate IP-specific logs.
- [x] T003 [P] Create auto-scroll terminal view for global activity stream.

## Phase 2: Interactive Controls

- [x] T004 Implement Context Menu for PC cards (Copy IP, VNC, SSH).
- [x] T005 Wire up `vnc://` URI scheme handlers for native macOS Screen Sharing.
- [x] T006 [P] Implement `diag_vnc` endpoint for integrated port checking.

## Phase 3: Performance & Polish

- [x] T007 Implement Light/Dark theme toggle with `localStorage` persistence.
- [x] T008 Implement Exponential Backoff for dashboard refresh to reduce server load.
- [x] T009 [P] Add mouse/keyboard event listeners to reset backoff on activity.

## Phase 4: Integration

- [x] T010 Display Tailscale IP prominently on cards if available.
- [x] T011 Verify "Handshake" confirmation flow works for injected instructions.
