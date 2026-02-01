<!--
Sync Impact Report:
Version change: 1.0.0 → 1.0.1
Modified principles: Fixed formatting lints.
Added sections: None
Templates requiring updates: ✅ None
Follow-up TODOs: None
-->

# Rescue Server Constitution

## Core Principles

### I. Simplicity & Reliability

The Rescue Server exists to provide critical tools when other systems have failed. Therefore, the server itself must be extremely simple and robust. It MUST rely on standard, widely available technologies (Python's built-in `http.server`, standard HTML/CSS) and minimize external runtime dependencies. Complex frameworks or databases are strictly prohibited for the core file-serving functionality.

### II. Universal Accessibility

The client-side dashboard MUST be accessible by any device with a basic web browser. It MUST NOT require modern JavaScript features, complex rendering engines, or specific browser extensions, as the client machine may be running in a recovery mode or using legacy software.

### III. Test-First (NON-NEGOTIABLE)

Development MUST follow a Test-Driven Development (TDD) approach. Given the critical nature of rescue operations, every feature (setup scripts, proxy logic, file serving) MUST have a failing test case defined before implementation begins. This ensures the server behaves predictably when deployed in the field.

### IV. Verified Network Bridging

The Rescue Server acts as a gateway for the LAN-locked PC. This "Bridging" capability—where the client requests the server to fetch external resources—MUST be secured by a robust **Integration Test Layer**. We cannot assume the network stack works; we must verifying the complete round-trip (Client Request → Server Fetch → Client Response) in a controlled environment before deployment.

### V. State Auditing & Versioning

The Rescue Server MUST maintain a precise audit trail of all actions taken by the client PC. Ideally, state changes on the PC side should be tracked via Git (proxied by the server if necessary). All interactions and tools MUST be implemented as **Bash scripts** to ensure transparency, auditability, and compatibility with the versioned history workflow.

### VI. Clear & Actionable Guidance

The user interface (both CLI and Web Dashboard) MUST provide unambiguous, actionable instructions. Ambiguity leads to errors during crisis moments. Every error message or instruction step MUST tell the user exactly what to do next.

### VII. IP-Based Evidence Isolation

All data collected from client PCs (audit logs, screenshots, system profiles) MUST be organized into IP-specific subdirectories within the `audit_logs/` and `evidence/` roots. This ensuring forensic clarity and prevents data collision when multiple PCs are being rescued simultaneously.

### VIII. Live Command Centre Monitoring

The server MUST provide a "Live Command Centre" interface that aggregates real-time status from all connected PCs. This interface MUST support:

- **Hostname-First Identity**: PCs should be prominently identified by their hostname if available, then by Tailscale or Local IP.
- **Interactive Remote Management**: Quick-launch actions for VNC and SSH MUST be available directly from the status cards.
- **Exponential Backoff Polling**: To optimize performance, the feed refresh rate MUST use an exponential backoff strategy (up to 150s) while users are idle, resetting immediately upon user interaction.

## Operating Constraints

### Technology Stack

- **Server**: Python 3 (via `uv` or system generic).
- **Transport**: Standard HTTP (Port 8000 default).
- **Frontend**: Static HTML5 + CSS. No build steps (e.g., Webpack, React) for the dashboard.
- **Tools**: Bash Scripts (primary interface language).

### Security

- **Access Control**: Open access on the local network (LAN) by default to facilitate immediate connection.
- **Audit**: All state-changing operations MUST be logged to the audit trail/git history.

## Maintenance

### Directory Structure Integrity

The server relies on a strict directory structure (`scripts`, `manuals`, `drivers`, `audit_logs`). Tools and scripts MUST respect this structure and NOT create arbitrary folders in the root without a constitution amendment.

### Documentation

All scripts provided by the server MUST contain headers explaining their purpose, usage arguments, and expected output.

## Governance

This Constitution serves as the primary source of architectural truth for the Rescue Server project.

- **Supremacy**: All architectural decisions, feature requests, and code reviews must align with these principles.
- **Amendments**: Changes to this document require a Pull Request with explicit "Constitution Amendment" labeling and must include a rationale for the change.
- **Versioning**: This document follows Semantic Versioning. Major changes involve altering Core Principles; Minor changes involve adding sections; Patch changes involve clarifications.

**Version**: 1.0.2 | **Ratified**: 2026-01-30 | **Last Amended**: 2026-01-30
