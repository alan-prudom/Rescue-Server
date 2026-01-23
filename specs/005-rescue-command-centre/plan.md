# Spec 005: Rescue Command Centre

## Objective
Transform the basic web dashboard into a premium, real-time command center for monitoring and controlling rescue operations.

## Proposed Features
- **⚡ Live Activity Feed**: Real-time display of `[HEARTBEAT]` and `[BOOTSTRAP]` messages via Auto-Refresh or WebSockets.
- **🟢 Multi-PC Monitoring**: Grid view showing status cards for every PC that has connected (IP, VNC status, Last Seen).
- **🖱️ One-Click Remote**: Prominent "Connect" button that triggers the Mac's `vnc://` handler for the specific PC.
- **🎨 Premium Interface**: 
  - Dark mode support by default.
  - Glassmorphism effects for a modern look.
  - Progress bars showing installation stages synced from the PC's `log_status`.
- **📁 Integrated Evidence Viewer**: Quick-view modal for images and text files uploaded from the PC directly in the browser.

## Status: Proposed / Future Upgrade
This spec documents the vision for the "Command Centre" upgrade as discussed on Jan 23, 2026.
