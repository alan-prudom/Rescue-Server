# Implementation Plan - Feature 003: Remote Desktop Bootstrap

**Branch**: `003-remote-desktop-bootstrap` | **Date**: 2026-01-22 | **Spec**: [specs/003-remote-desktop-bootstrap/spec.md](spec.md)

## Summary
Provide a "one-click" script on the Mac server that uses the Linux PC's package manager to bootstrap a VNC server compatible with macOS Screen Sharing, allowing full GUI remote control.

## Phase 1: Environment Detection

- [x] Create `scripts/boot_vnc.sh` foundation.
- [x] Implement distro detection (Debian/Ubuntu/Fedora/Arch/SystemRescue).
- [x] Implement display server detection (X11 vs Wayland) - *Critical*: VNC often fails on Wayland.

## Phase 2: Dependency Management
- [x] Implement package installation fallback (`apt-get install`, `dnf install`, `pacman -S`).
- [x] Handle "offline mode" (warn user if internet is required but missing).


- [x] Configure `x11vnc` for one-time password auth.
- [x] **Crucial**: Disable encryption/TLS to ensure Mac Screen Sharing compatibility.
- [x] Output the connection string `vnc://<IP>:5900` in bold green text.


- [x] Add `boot_vnc.sh` to the main setup script generation list.
- [x] Update `system_help.html` with VNC instructions.

## Phase 5: Diagnostics & Hardening (Live CD Focus)
- [x] Implement `vnc_stderr.log` capture for hidden startup errors.
- [x] Add automated log upload on failure (Feature 002 integration).
- [x] Implement multi-path Xauthority search (GDM/LightDM/generic).
- [x] Add `noxdamage` and `noxfixes` flags for Screen Sharing compatibility.
