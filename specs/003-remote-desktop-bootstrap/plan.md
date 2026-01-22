# Implementation Plan - Feature 003: Remote Desktop Bootstrap

**Branch**: `003-remote-desktop-bootstrap` | **Date**: 2026-01-22 | **Spec**: [specs/003-remote-desktop-bootstrap/spec.md](spec.md)

## Summary
Provide a "one-click" script on the Mac server that uses the Linux PC's package manager to bootstrap a VNC server compatible with macOS Screen Sharing, allowing full GUI remote control.

## Phase 1: Environment Detection
- [ ] Create `scripts/boot_vnc.sh` foundation.
- [ ] Implement distro detection (Debian/Ubuntu/Fedora/Arch/SystemRescue).
- [ ] Implement display server detection (X11 vs Wayland) - *Critical*: VNC often fails on Wayland.

## Phase 2: Dependency Management
- [ ] Check for existing VNC servers (`x11vnc`, `tigervnc`, `vino`).
- [ ] Implement package installation fallback (`apt-get install`, `dnf install`, `pacman -S`).
- [ ] Handle "offline mode" (warn user if internet is required but missing).

## Phase 3: Configuration & Launch
- [ ] Configure `x11vnc` for one-time password auth.
- [ ] **Crucial**: Disable encryption/TLS to ensure Mac Screen Sharing compatibility.
- [ ] Output the connection string `vnc://<IP>:5900` in bold green text.

## Phase 4: Integration
- [ ] Add `boot_vnc.sh` to the main setup script generation list.
- [ ] Update `system_help.html` with VNC instructions.
