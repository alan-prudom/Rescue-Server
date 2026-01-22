# Feature Specification: Proxy Download Cache

**Feature Branch**: `004-download-proxy-cache`  
**Created**: 2026-01-22  
**Status**: Draft  
**Input**: User request: "PC requests Mac downloads files to cache, then PC gets them from Mac"

## User Scenarios & Testing

### User Story 1 - Proxy Download (Priority: P1)
As a technician on an air-gapped PC (or one with flaky DNS), I want to ask the Mac server to download a tool from the internet and serve it to me over the LAN.

**Why this priority**: Solves the "no internet drivers" chicken-and-egg problem on the PC.

**Acceptance Scenarios**:
1. **Given** the Mac has internet, **When** the PC requests `http://[MAC-IP]:8000/proxy?url=https://example.com/driver.run`, **Then** the Mac downloads the file to `cache/` and serves it back to the PC.
2. **Given** the file is already in `cache/`, **When** requested again, **Then** the Mac serves the local copy instantly without re-downloading.

### User Story 2 - CLI Tool (Priority: P2)
As a technician, I want a simple wrapping script `fetch_tool.sh` so I don't have to construct complex URLs manually.

**Acceptance Scenarios**:
1. **When** run as `bash fetch_tool.sh https://example.com/tool.zip`, **Then** it curls the Mac proxy endpoint and saves `tool.zip` locally.

## Functional Requirements

- **FR-001**: Server MUST expose a GET endpoint (e.g., `/proxy?url=...`).
- **FR-002**: Server MUST validate the URL (http/https only) and prevent SSRF to local Mac resources (no localhost/127.0.0.1).
- **FR-003**: Server MUST download the remote file to a `downloads_cache/` directory in the rescue site.
- **FR-004**: Server MUST stream the file content to the client in the response.
- **FR-005**: System MUST generate a `scripts/fetch_tool.sh` client utility.

## Success Criteria

- **SC-001**: Can successfully download a 10MB test file via the proxy.
- **SC-002**: Second request for the same URL is served from disk (cache hit).
