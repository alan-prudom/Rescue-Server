# Protocol Reference: PC Rescue Station Communication

This document defines the two-way communication landscape between the **Mac Rescue Server (Host)** and the **PC Rescue Agent (Client)**.

---

## 🏗️ 1. Architecture Overview

The system operates using a **Bidirectional Handshake** model. While the PC Agent primarily connects "upwards" to the Mac for safety/firewall traversal, the Mac can "Pulse" the PC to trigger immediate actions.

| Direction | protocol | Port | Role |
| :--- | :--- | :--- | :--- |
| **PC → Mac** | HTTP | 8000 | **Uplink**: Status, Evidence, Heartbeats, Sync. |
| **Mac → PC** | HTTP | 8001 | **Pulse**: Immediate trigger for the next agent cycle. |
| **Mac → PC** | SSH | 22 | **Remote Console**: Direct shell access (X11 enabled). |
| **Mac → PC** | VNC | 5900+ | **GUI Access**: Remote desktop interaction. |

---

## 🟢 2. PC → Mac Uplink (Port 8000)

The PC Rescue Agent (Python) or Bootstrap Script (Bash) initiates all state changes via the Mac Server's HTTP API.

### A. Smart Sync (Agent v1.5+)

- **Endpoint**: `GET /manifest/`
- **Logic**: The PC fetches a JSON manifest containing MD5 hashes of all tools in `scripts/`. It compares them locally and only downloads updated or missing files.

### B. Heartbeat & Telemetry

- **Endpoint**: `POST /` (urlencoded)
- **Fields**: `content=[TAG] message`
- **Behavior**:
  - `[BOOTSTRAP]`: Signals a fresh start; the Mac truncates previous logs.
  - `[HEARTBEAT]`: Periodic status check (Defaults to 30s - 300s backoff).
  - `[AGENT]`: Process-level logs from the Python engine.

### C. Evidence Uplink

- **Endpoint**: `POST /` (multipart/form-data)
- **Behavior**: Saves files (logs, captures) into the machine-specific silo: `evidence/<PC_IP>/`.

---

## 🔵 3. Mac → PC Downlink (Port 8001+)

To avoid "waiting" for the next 5-minute heartbeat, the Mac can push signals to the PC.

### A. Pulse Protocol (Port 8001) - *New in v1.6.0*

- **Mechanism**: The Mac sends a GET request to `http://[PC_IP]:8001/trigger`.
- **Client Response**: The Agent's interruptible sleep is broken instantly. It immediately starts its next loop (Sync → Instruction → Heartbeat).
- **Transport preference**: The Mac server intelligently prefers the **Tailscale Managed IP** for pulses to ensure traversal.

### B. Remote Desktop (Port 5900)

- **Protocol**: RFB (Remote Frame Buffer).
- **Launched via**: `vnc://[PC_IP]:5900` (Native macOS) or `com.realvnc.vncviewer.connect://[PC_IP]`.

### C. SSH Terminal (Port 22)

- **Command**: `ssh -X rescue@[PC_IP]`
- **Role**: Provides a high-bandwidth command shell. Support for X11 forwarding allows running GUI apps from the PC displayed on the Mac.

---

## 🛡️ 4. Resilience & Transport

1. **Tailscale VPN**: The primary transport layer. It provides a stable global IP (100.x.x.x) and handles NAT traversal, ensuring the Mac can "find" the PC even on guest or restricted networks.
2. **Local Fallback**: All protocols are IP-agnostic. If Tailscale is down, the system automatically attempts communication over the physical LAN (192.168.x.x).
3. **Self-Updating**: If communication logic is changed on the Mac side, the Agent will detect the hash change, rebuild its own `rescue_agent.py`, and restart the service without operator intervention on the PC.
