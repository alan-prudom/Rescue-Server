---
description: "Task list for Unified GUI Architecture"
---

# Tasks: Unified GUI Architecture (UI Completeness)

**Input**: Design documents from `/specs/005-gui-completeness/`

**Prerequisites**: plan.md (required), spec.md (required)

## Phase 1: Audit & Specification

- [x] T001 Conduct full scan of `templates/web/*.html` for undocumented buttons/forms.
- [x] T002 Draft `spec.md` defining G-001 (Identity Display) and G-002 (Instant Evidence).
- [x] T003 [P] Verify POST endpoints for G-002 match technical specifications in Spec 002.

## Phase 2: Command Centre Definition

- [x] T004 Define requirements for Status Cards (G-004) and contextual actions (Inspect Logs, VNC).
- [x] T005 Document the "Exponential Refresh Backoff" behavior (G-006) – mapping user interaction to timer reset.
- [x] T006 [P] Verify `sessionStorage` usage for backoff persistence complies with SC-GUI rules.

## Phase 3: Instruction & Security Traces

- [x] T007 Define Instruction Library grid (G-007) and "Execute" simulation behavior.
- [x] T008 Document the Security Command Trace lifecycle (G-009, G-010, G-011).
- [x] T009 [P] Confirm the "Handshake Server" confirmation GET request is specified as a mandatory client behavior.

## Phase 4: Verification

- [x] T010 Final cross-check of implementation vs documentation.
- [x] T011 [P] Ensure all buttons have unique IDs for browser testing compatibility.
