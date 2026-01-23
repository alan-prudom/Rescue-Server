# 🚑 Rescue Server

A lightweight utility to set up a file-sharing and evidence-uplink server on a Mac for PC rescue operations. Fully compliant with Bash 3.2+ and standard Python 3.

## 📖 Documentation

For detailed instructions and examples, see the **[USER_MANUAL.md](USER_MANUAL.md)**.

## ⚡ Quick Start

1. **Setup**: Run the setup script to create the site structure.
   ```bash
   ./setup_rescue_server.sh
   ```
2. **Launch**: Start the custom server from the created directory.
   ```bash
   cd ~/Desktop/rescue-site
   uv run python server/rescue_server.py 8000
   ```
3. **Access**: On the target PC, visit `http://[MAC-IP]:8000`.

## 📂 Features

- **File Delivery**: Serve scripts, drivers, and manuals to the PC.
- **Evidence Uplink**: Upload logs and screenshots from the PC to the Mac.
- **One-Click Rescue**: Consolidated bootstrap script for instant PC prep.
- **VNC Remote Desktop**: Automatic GUI remote control (optimized for Mac Screen Sharing).
- **Heartbeat Monitoring**: Real-time PC status updates in the Mac console.
- **Instant Paste**: Browser-based text sharing for quick log analysis.
- **Audit Ready**: Automatic Git versioning and append-only logging.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
