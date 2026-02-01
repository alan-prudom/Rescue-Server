# 🚑 Rescue Server: Advanced PC Emergency Station

[![Status](https://img.shields.io/badge/Status-Stable-success.svg)](https://github.com/alan-prudom/Rescue-Server)
[![Version](https://img.shields.io/badge/Version-2.0.0--Handshake-blue.svg)](https://github.com/alan-prudom/Rescue-Server)
[![Platform](https://img.shields.io/badge/Platform-Mac%20(Host)%20|%20PC%20(Client)-lightgrey.svg)](https://github.com/alan-prudom/Rescue-Server)

A high-performance, real-time command center and file server for orchestrating PC rescue operations over a LAN. Designed for technicians who need robust evidence uplink, remote desktop control, and intelligent agent monitoring in a zero-trust or isolated network environment.

---

## 🏗️ Monorepo Architecture

This repository follows a structured monorepo pattern to ensure absolute parity between the Mac server and the PC clients.

- **`specs/`**: Technical blueprints (001-007) for every feature, following the **UI Completeness** and **Audit First** project rules.
- **`templates/scripts/`**: The master source for 20+ rescue tools (Bash/Python) provisioned to the client.
- **`templates/web/`**: Real-time dashboard components (Command Centre, Instruction Library).
- **`server/`**: Custom asynchronous Python backend providing the Smart Sync manifest and IP-based partitioning.
- **`audit_logs/`**: Persistent append-only traces of all host-side operations.

---

## 🚀 Key Features

### 📺 1. Rescue Command Centre
A real-time, glassmorphic dashboard for monitoring an unlimited number of rescue clients.

- **PC Status Grid**: Live status cards showing connection state, VNC status, and Tailscale management IPs.
- **Contextual Actions**: Right-click controls to copy IPs, inspect logs, or launch remote desktop handlers.
- **Pulse Protocol (v1.6.0)**: Real-time, server-to-agent trigger to bypass polling delays.
- **Exponential Backoff**: Intelligent refresh logic that adapts to operator activity.

### 🤖 2. Intelligent Rescue Agent (v1.5.0)
A Python-based client engine that replaces "dumb" polling with a stateful loop.

- **Smart Sync**: Automatically updates local scripts using MD5 checksum validation.
- **Hot-Swapping**: The agent can rebuild its own code on-the-fly without losing connection.
- **Reporting**: Detailed three-phase telemetry (`[Sync]`, `[Instruction]`, `[Heartbeat]`).

### 💻 3. Chromebook (Crostini) Recovery
Surgical repair tools specifically for ChromeOS Linux containers.

- **Lock Buster**: Proactively kills hung package manager processes and repairs malformed sources.
- **Browser Integration**: Forcing reports to open in native Chrome via `garcon-url-handler`.

### 🛡️ 4. Security & Audit

- **Master Bootstrap**: A single one-liner to deploy the entire environment.
- **Uplink Partitioning**: Client evidence and logs are strictly siloed by machine IP.
- **Handshake Protocol**: Mandatory operator confirmation for high-side instructions.

---

## 🛠️ Deployment

### Host (Mac Side)

1. **Initialize**: `bash setup_rescue_server.sh`
2. **Launch**: `cd ~/Desktop/rescue-site && uv run python server/rescue_server.py`

### Client (PC Side)
Run the master one-liner to start the rescue loop:

```bash
wget -q -O - http://[MAC-IP]:8000/scripts/pc_rescue_bootstrap.sh | bash
```

---

## 📖 Reference & Manuals

- **[COMMUNICATION_PROTOCOLS.md](COMMUNICATION_PROTOCOLS.md)**: Technical detail on bidirectional Mac-to-PC comms.
- **[USER_MANUAL.md](USER_MANUAL.md)**: Operator's guide for command execution.
- **[CHROMEBOOK_MANUAL.md](evidence/192.168.1.6/CHROMEBOOK_MANUAL.md)**: specialized Crostini recovery guide.

---

## ⚖️ License
MIT License. Created by the Rescue-Server engineering team.
