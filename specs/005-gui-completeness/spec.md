# Feature Specification: Unified GUI Architecture (UI Completeness)

**Feature Branch**: `005-gui-completeness`
**Created**: 2026-01-25
**Status**: Stable

## Overview
This specification defines all Graphical User Interface (GUI) elements per the project's UI Completeness rule. It ensures every button, form, and display has a defined functional requirement, layout, and behavior.

---

## 1. Primary Dashboard (`index.html`)

### UI Elements & Behavior
- **Identity Display (G-001)**:
    - **Fields**: PC IP Address (`{{PC_IP}}`), PC Hostname/Name (`{{PC_NAME}}`).
    - **Layout**: Centered card with blue dashed border and light blue background.
    - **Behavior**: Auto-populated by the server's detection logic on page load.
- **Instant Evidence Form (G-002)**:
    - **Fields**: Large Textarea (`content`), Submit Button ("Save Evidence").
    - **Layout**: Full-width container at bottom of primary grid.
    - **Behavior**: POSTs content as `application/x-www-form-urlencoded` to `/`. Saves as timestamped `.txt` in the `evidence/` directory.
- **Navigation Links (G-003)**:
  - **Links**: `scripts/`, `manuals/`, `drivers/`, `evidence/`, `/feed/`, `/shutdown`.
  - **Behavior**:
    - Standard GET requests to server-indexed directories or specific routes.
    - **Shutdown Link**: Triggers a `confirm('Stop the Mac Rescue Server?')` browser dialog. If confirmed, sends a GET request to `/shutdown`, which triggers a `threading.Timer` on the server to exit after 1.0s.

---

## 2. Command Centre (`live_feed.html`)

### UI Elements & Behavior
- **PC Status Cards (G-004)**:
    - **Fields**: IP Address, VNC Status Badge (RUNNING/STOPPED), Last Seen Timestamp, Latest Activity Snippet.
    - **Layout**: Flex-grid of cards, wrapping on smaller screens.
    - **Behavior**: Right-click or left-click triggers the Context Menu.
- **Context Menu (G-005)**:
    - **Items**:
        - **Copy IP**: Copies active PC IP to clipboard.
        - **Inspect Logs**: Opens IP-specific `client_activity.log` in new tab.
        - **Diagnose VNC**: Triggers `/diag_vnc` endpoint; displays JSON result in browser alert.
        - **Launch VNC**: Redirects to `vnc://` or `com.realvnc.vncviewer.connect://` URI schemes.
        - **SSH Terminal**: Copies pre-formatted SSH command to clipboard.
    - **Layout**: Fixed-position popup anchored to click coordinates.
- **Global Activity Stream (G-006)**:
    - **Fields**: Aggregated log entries from all clients, Refresh countdown timer.
    - **Layout**: Fixed-height terminal window with auto-scroll to bottom.
    - **Behavior**: Page reloads automatically based on exponential backoff (10s to 150s). Timer resets to 10s on any user interaction (mouse/keyboard).

---

## 3. Instruction Library (`instructions.html`)

### UI Elements & Behavior
- **Instruction Grid (G-007)**:
    - **Fields**: Script Name, Title, Description, Expected Output Path, Status Badge (Ready, Running, Complete).
    - **Layout**: Tiled grid of cards with "▶️ Execute" button.
    - **Behavior**: Clicking "Execute" generates a one-liner `wget` command, copies it to clipboard, and triggers a simulated download event.
- **Execution Console (G-008)**:
    - **Layout**: Dark-themed terminal block at bottom of page.
    - **Behavior**: Toggles visibility (`display: block`) only when a script is being executed.

---

## 4. Security Command Trace (`command_output.html`)

### UI Elements & Behavior
- **Status Badge (G-009)**:
    - **States**: `PENDING`, `EXECUTING`, `COMPLETED`.
    - **Layout**: Color-coded pill in header (Yellow, Blue, Green).
- **Confirmation Banner (G-010)**:
    - **Field**: "START EXECUTION" button.
    - **Layout**: Full-width yellow banner below header.
    - **Behavior**: Only visible when state is `PENDING`. Clicking it sends a GET request to `http://localhost:8001/confirm` (Handshake Server) and updates local state.
- **Output Trace (G-011)**:
    - **Field**: Raw command output.
    - **Layout**: Large `<pre>` block with light-gray background and monospace text.
    - **Behavior**: Auto-scrolls to bottom on update.

---

## Requirements

- **FR-GUI-01**: All HTML templates MUST use semantic HTML5 elements (header, main, nav, footer).
- **FR-GUI-02**: All interactive buttons MUST have a distinct hover state and active state (visual feedback).
- **FR-GUI-03**: The Command Centre MUST persist theme (Light/Dark) preference in `localStorage`.
- **FR-GUI-04**: The Command Centre MUST persist refresh backoff state in `sessionStorage`.
- **FR-GUI-05**: Any "Simulation" UI (simulated progress bars/console output) MUST be clearly labeled as such to prevent operator confusion.
