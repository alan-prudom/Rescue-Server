# Implementation Plan - Feature 004: Proxy Download Cache

**Branch**: `004-download-proxy-cache` | **Date**: 2026-01-22 | **Spec**: [specs/004-download-proxy-cache/spec.md](spec.md)

## Summary
Implement a caching proxy endpoint `/proxy` on the rescue server to allow the PC (which may have limited DNS/internet access) to download drivers/tools via the Mac's connection, while caching them for future use.

## Phase 1: Server Logic
- [ ] Create `downloads_cache/` directory.
- [ ] Update `server/rescue_server.py`:
    - [ ] Implement `do_GET` extension to intercept `/proxy` path.
    - [ ] Validate URL scheme (http/https) and block local IP ranges.
    - [ ] Implement download logic (stream from remote to disk, then disk to client).
    - [ ] Implement cache check (if file exists, serve immediately).

## Phase 2: Client Tooling
- [ ] Implement `create_fetch_tool_script` in `setup_rescue_server.sh`.
- [ ] Script should use `curl` to hit the proxy endpoint.

## Phase 3: Integration
- [ ] Update dashboard to show a "Proxy Download" helper box.
- [ ] Update `system_help.html` with instructions.
