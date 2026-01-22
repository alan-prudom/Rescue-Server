# Bridge Test Plan: Evidence Uplink (Feature 002)

**Status**: Required by Constitution IV (Verified Network Bridging)
**Domain**: Client (PC) to Server (Mac) Data Transfer

## Purpose
Verify that the "Bridge" between the LAN-locked PC and the Mac Server correctly handles file uploads (Evidence Uplink) without data corruption or path traversal.

## Test Matrix

| ID | Case | Input | Expected Outcome | Principle |
|---|---|---|---|---|
| B001 | Text Log Upload | `test.log` | File saved in `evidence/` with timestamp | IV, V |
| B002 | Image Binary Upload | `screenshot.png` | Binary integrity maintained (Hash match) | IV, II |
| B003 | Path Traversal Prevention | `../../secret.txt` | Error 400 or filename sanitized to basename | VI, Security |
| B004 | Empty File Handling | `empty.txt` | Request rejected or handled gracefully | Reliability |

## Automated Verification Script
The following bridge test will be implemented in `tests/integration/test_uplink_bridge.sh`.

### Setup
1. Start `server/rescue_server.py` on a test port.
2. Create dummy binary and text files.

### Execution
1. Invoke `scripts/push_evidence.sh` pointing to the test server.
2. Verify the response code is 201.
3. Verify file presence on disk in `evidence/`.
4. Run `cmp` to verify binary identity.

### Teardown
1. Stop the test server.
2. Clean up the `evidence/` directory.
