---
description: "Task list for Rescue Server Setup Utility"
---

# Tasks: Rescue Server Setup Utility

**Input**: Design documents from `/specs/001-rescue-server-setup/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and test harness setup

- [x] T001 Create `setup_rescue_server.sh` (if missing) and `tests/` directory structure per plan.md
- [x] T002 [P] Create `tests/unit/test_setup_functions.sh` skeleton
- [x] T003 [P] Create `tests/integration/test_setup_integration.sh` skeleton
- [x] T004 [P] Implement self-chmod logic in `setup_rescue_server.sh` header (FR-007)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core logic that all stories depend on

- [x] T005 Implement `get_ip_address` function for robust IP detection (FR-005) in `setup_rescue_server.sh`
- [x] T006 Implement `check_git_installed` function to gracefully handle missing git (Edge Case)
- [x] T007 [P] Create unit test for `get_ip_address` in `tests/unit/test_setup_functions.sh`
- [x] T027 [P] Create unit test for `check_git_installed` in `tests/unit/test_setup_functions.sh` (Constitution III)

**Checkpoint**: Core util functions ready

---

## Phase 3: User Story 1 - Structured Repository Creation (Priority: P1)

**Goal**: Create filesystem structure with permissions

**Independent Test**: Run script, verify directories exist

### Tests for User Story 1
- [x] T008 [P] [US1] Create test case "Structure is created" in `tests/integration/test_setup_integration.sh`

### Implementation for User Story 1
- [x] T009 [P] [US1] Implement `create_directories` function (scripts/manuals/drivers/audit_logs) (FR-002)
- [x] T010 [P] [US1] Implement `create_index_html` function for dashboard generation (FR-003)
- [x] T011 [US1] Implement `create_test_script` function (test_connection.sh) with +x permission (FR-004, FR-007)
- [x] T012 [US1] Integration: Wire up directory creation logic in main execution block

**Checkpoint**: Filesystem populated correctly

---

## Phase 4: User Story 3 - Audit & Versioning Initialization (Priority: P1)

**Goal**: Initialize Git and Audit Logs

**Independent Test**: Run script, verify .git exists and log file present

### Tests for User Story 3
- [x] T013 [P] [US3] Create test case "Git repo initialized with commit" in `tests/integration/test_setup_integration.sh`

### Implementation for User Story 3
- [x] T029 [US3] Implement `create_push_audit_script` function to generate `scripts/push_audit.sh` (FR-013)
- [x] T014 [US3] Implement `init_audit_log` function to write initial log entry (FR-002)
- [x] T015 [US3] Implement `init_git_repo` function (git init, add, commit) (FR-009, FR-010)
- [x] T016 [US3] Add `.gitignore` creation to `init_git_repo` (Constitution Check)
- [x] T017 [US3] Integration: Call audit/git functions after filesystem creation

**Checkpoint**: Repo is versioned and auditable

---

## Phase 5: User Story 2 - Server Launch Automation (Priority: P1)

**Goal**: Interactive launch

**Independent Test**: Interactive prompt allows starting server

### Tests for User Story 2
- [x] T018 [P] [US2] Create test case "Server launch instruction printed" (Dry run)
- [x] T028 [P] [US2] Create test case "Edge case: Missing interface trigger manual instructions" (Edge Case)

### Implementation for User Story 2
- [x] T019 [US2] Implement `print_manual_instructions` function (FR-006)
- [x] T020 [US2] Implement `prompt_and_launch` function with TTY check (if ! -t 0 then skip) (FR-008)
- [x] T021 [US2] Integration: Add prompt logic as final step of script

**Checkpoint**: Full end-to-end flow complete

---

## Phase 6: User Story 4 - Dashboard Accessibility (Priority: P2)

**Goal**: Verify Dashboard UX

**Independent Test**: Manual verification on browser

### Implementation for User Story 4
- [x] T022 [P] [US4] Refine `index.html` CSS for legacy browser support (Constitution Principle II)
- [X] T023 [US4] Verify all links in generated dashboard point to correct relative paths (Dynamic folders)

---

## Final Phase: Polish & Cross-Cutting Concerns

- [x] T024 Code cleanup: Ensure strict Bash style (Constitution V)
- [x] T025 Verify `README.md` instructions align with final script behavior
- [x] T026 Final Manual Test: Run entire flow against `checklists/audit_compliance.md`

## Dependencies & Execution Order

1. **Setup (Phase 1)**: Can start immediately.
2. **Foundational (Phase 2)**: Depends on T001.
3. **US1 (Structure)**: Depends on Foundational.
4. **US3 (Audit)**: Depends on US1 (needs files to commit).
5. **US2 (Launch)**: Depends on US3 (launch should happen after repo is safe).
6. **US4 (Dashboard)**: Can run in parallel with US1 implementation details.

## Implementation Strategy

1. **Skeleton & Utils**: Build the shell frame and IP detection.
2. **Core IO**: Build directory/file generation (US1).
3. **Audit**: Layer on Git/Logging (US3).
4. **Interactive**: Add the final prompt (US2).
5. **Refine**: CSS tweaks (US4).
