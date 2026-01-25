import http.server
import os
import datetime
import urllib.parse
from pathlib import Path

class RescueHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """
    Custom handler for the Rescue Server.
    Supports GET (static files) and POST (file uploads + text pastes).
    """

    CACHE_DIR = os.path.join(os.getcwd(), 'downloads_cache')
    BOOTSTRAP_VERSION = "20260123.5"  # Protocol version

    def _get_client_dir(self, base_dir="evidence"):
        """Returns a Path object for the client-specific directory."""
        pc_ip = self.client_address[0]
        # Replace IPv6 loopback if encountered
        if pc_ip == '::1': pc_ip = '127.0.0.1'
        client_dir = Path(base_dir) / pc_ip
        client_dir.mkdir(parents=True, exist_ok=True)
        return client_dir

    def do_GET(self):
        # Feature: Remote Shutdown
        if self.path == '/shutdown':
            self.send_response(200)
            self.send_header('Content-Type', 'text/html')
            self.end_headers()
            self.wfile.write(b"<html><body><h1>Shutting down...</h1><p>The Rescue Server is stopping.</p></body></html>")
            print("[*] Shutdown request received. Exiting...")
            # We use a short delay to allow the response to be sent
            import threading
            threading.Timer(1.0, self.server.shutdown).start()
            return

        # Case: Instruction Fetch Logging (US: Record keeping by IP)
        if self.path == '/scripts/instructions.sh':
            client_log_dir = self._get_client_dir("audit_logs")
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            with open(client_log_dir / "client_activity.log", "a") as f:
                f.write(f"[{timestamp}] [SERVER] Client fetched instructions.sh\n")
            
            # Archive a copy of what was sent to this specific IP
            instr_src = Path("scripts/instructions.sh")
            if instr_src.exists():
                client_evidence = self._get_client_dir("evidence")
                import shutil
                shutil.copy2(instr_src, client_evidence / f"{timestamp}_instructions_sent.sh")

        # Feature 004: Proxy Download Cache
        if self.path.startswith('/proxy'):
            self._handle_proxy_request()
            return

        # Phase 5: Smart Sync Manifest
        if self.path == '/manifest' or self.path == '/manifest/':
            self._handle_manifest()
            return
            
        # Case: Index with dynamic IP
        if self.path == '/' or self.path == '/index.html':
            self._handle_index()
            return

        # Feature: Live Activity Feed (US: Real-time monitoring)
        if self.path == '/feed' or self.path == '/feed/':
            self._handle_live_feed()
            return

        # Case: VNC Diagnostic Action
        if self.path.startswith('/diag_vnc'):
            self._handle_diag_vnc()
            return

        # Case: Instruction Library Page
        if self.path == '/instructions' or self.path == '/instructions/':
            self._handle_instructions()
            return

        super().do_GET()

    def _handle_live_feed(self):
        """Displays an aggregated live activity log and PC status cards."""
        self.send_response(200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.end_headers()
        
        audit_root = Path("audit_logs")
        feed_content = []
        pc_cards_html = []
        
        if audit_root.exists():
            for log_file in audit_root.rglob("client_activity.log"):
                ip_addr = log_file.parent.name
                # Skip legacy top-level log file (US: IP-based organization fix)
                if ip_addr == "audit_logs" or ip_addr == ".": continue
                
                last_msg = "Unknown"
                last_time = "Never"
                vnc_status = "STOPPED"
                tailscale_ip = "N/A"
                
                # Try to get tailscale_ip from most recent capabilities.json
                evidence_dir = Path("evidence") / ip_addr
                if evidence_dir.exists():
                    cap_files = sorted(list(evidence_dir.glob("*_capabilities.json")), reverse=True)
                    if cap_files:
                        try:
                            import json
                            with open(cap_files[0], "r") as fcap:
                                cap_data = json.load(fcap)
                                tailscale_ip = cap_data.get("network", {}).get("tailscale_ip", "N/A")
                        except:
                            pass

                with open(log_file, "r") as f:
                    lines = f.readlines()
                    if lines:
                        # Extract PC Card info from last messages
                        latest_bootstrap_line = None
                        for line in reversed(lines):
                            if "[BOOTSTRAP]" in line:
                                latest_bootstrap_line = line
                                if not last_msg or last_msg == "Unknown":
                                    last_msg = line.split("]", 1)[1].strip()
                                    last_time = line.split("]", 1)[0].strip("[")
                            
                            if "[HEARTBEAT]" in line and last_msg == "Unknown":
                                last_msg = line.split("]", 1)[1].strip()
                                last_time = line.split("]", 1)[0].strip("[")
                                if "VNC: RUNNING" in line: vnc_status = "RUNNING"
                            
                            if "[CAPABILITIES]" in line and last_msg == "Unknown":
                                last_msg = line.split("]", 1)[1].strip()
                                last_time = line.split("]", 1)[0].strip("[")

                        # Add to scrolling log (last 15 entries for readability)
                        for line in lines[-15:]:
                            feed_content.append(f"[{ip_addr}] {line}")
                
                # Check for existing instruction files for this IP
                instr_link = f"/evidence/{ip_addr}"
                log_link = f"/audit_logs/{ip_addr}/client_activity.log"
                
                # Generate Card HTML with Metadata
                status_class = "status-running" if vnc_status == "RUNNING" else "status-stopped"
                card = f"""
                <div class="pc-card" onclick="showMenu(event, '{ip_addr}', '{instr_link}', '{log_link}')">
                    <div class="pc-card-header">
                        <span class="pc-ip">{ip_addr}</span>
                        <span class="vnc-badge {status_class}">VNC: {vnc_status}</span>
                    </div>
                    <div class="pc-card-body">
                        <div class="pc-last-seen">Last: {last_time}</div>
                        <div class="pc-tailscale">TS: {tailscale_ip}</div>
                        <div class="pc-activity">{last_msg}</div>
                    </div>
                </div>
                """
                pc_cards_html.append(card)
        
        # Sort and limit global log
        feed_content.sort(reverse=True)
        log_html = "".join([f'<div class="log-entry">{l}</div>' for l in feed_content[:50]])
        cards_html = "".join(pc_cards_html) if pc_cards_html else "<p>No PCs connected yet.</p>"

        # Load template
        template_path = Path("templates/web/live_feed.html")
        if template_path.exists():
            with open(template_path, "r") as f:
                html = f.read()
                html = html.replace("{{PC_CARDS}}", cards_html)
                html = html.replace("{{FEED_CONTENT}}", log_html)
        else:
            html = f"<html><body><h1>Cards</h1>{cards_html}<h1>Log</h1><pre>{log_html}</pre></body></html>"
        
        try:
            self.wfile.write(html.encode('utf-8'))
        except BrokenPipeError:
            # Client disconnected before we finished writing
            pass
        except Exception as e:
            print(f"[!] Error writing feed response: {e}")

    def _handle_index(self):
        """Serves index.html with dynamic IP and PC name."""
        pc_ip = self.client_address[0]
        if pc_ip == '::1': pc_ip = '127.0.0.1'
        
        # Try to get unique name
        import socket
        try:
            pc_name = socket.gethostbyaddr(pc_ip)[0]
        except:
            pc_name = "Unknown Device"

        # Get Mac IP
        import socket
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            s.connect(("8.8.8.8", 80))
            mac_ip = s.getsockname()[0]
        except:
            mac_ip = "localhost"
        finally:
            s.close()

        template_path = Path("templates/web/index.html")
        if template_path.exists():
            with open(template_path, "r") as f:
                html = f.read()
                html = html.replace("{{MAC_IP}}", mac_ip)
                html = html.replace("{{PC_IP}}", pc_ip)
                html = html.replace("{{PC_NAME}}", pc_name)
                
                self.send_response(200)
                self.send_header('Content-Type', 'text/html; charset=utf-8')
                self.end_headers()
                self.wfile.write(html.encode('utf-8'))
        else:
            self.send_error(404, "index.html template missing")

    def _handle_diag_vnc(self):
        """Runs the Python VNC diagnostic tool and updates the live feed."""
        from urllib.parse import urlparse, parse_qs
        import subprocess
        
        query_components = parse_qs(urlparse(self.path).query)
        target_ip = query_components.get('ip', [None])[0]
        
        if not target_ip:
            self.send_error(400, "Missing IP parameter")
            return

        print(f"[*] Running VNC Diagnostic for {target_ip}...")
        
        # Run the probe
        try:
            cmd = ["python3", "scripts/vnc_diag.py", target_ip]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
            output = result.stdout
            
            # Parse port from output "RESULT: 5901 | ..."
            final_port = "5900"
            if "RESULT:" in output and "FAIL" not in output:
                res_line = [l for l in output.split("\n") if "RESULT:" in l][0]
                final_port = res_line.split(":")[1].split("|")[0].strip()
                status = "RUNNING"
            else:
                status = "STOPPED"

            # Log to client activity log
            audit_dir = self._get_client_dir("audit_logs")
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            msg = f"[VNC-DIAG] VNC: {status} | Port: {final_port} | Details: {output.strip().replace('\n', ' ')}"
            
            with open(audit_dir / "client_activity.log", "a") as al:
                al.write(f"[{timestamp}] {msg}\n")

            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            import json
            self.wfile.write(json.dumps({"status": status, "port": final_port, "log": msg}).encode())

        except Exception as e:
            self.send_error(500, str(e))

    def _handle_instructions(self):
        """Serves the instruction library page with dynamic IP and PC name."""
        pc_ip = self.client_address[0]
        if pc_ip == '::1': pc_ip = '127.0.0.1'
        
        # Try to get unique name
        import socket
        try:
            pc_name = socket.gethostbyaddr(pc_ip)[0]
        except:
            pc_name = "Unknown Device"

        # Get Mac IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            s.connect(("8.8.8.8", 80))
            mac_ip = s.getsockname()[0]
        except:
            mac_ip = "localhost"
        finally:
            s.close()

        template_path = Path("templates/web/instructions.html")
        if template_path.exists():
            with open(template_path, "r") as f:
                html = f.read()
                html = html.replace("{{MAC_IP}}", mac_ip)
                html = html.replace("{{PC_IP}}", pc_ip)
                html = html.replace("{{PC_NAME}}", pc_name)
                
                self.send_response(200)
                self.send_header('Content-Type', 'text/html; charset=utf-8')
                self.end_headers()
                self.wfile.write(html.encode('utf-8'))
        else:
            self.send_error(404, "instructions.html template missing")

    def _handle_manifest(self):
        """Generates a JSON manifest of all manageable scripts and templates."""
        import hashlib
        import json
        
        manifest = {
            "version": datetime.datetime.now().strftime("%Y%m%d%H%M%S"),
            "protocol_version": self.BOOTSTRAP_VERSION,
            "files": {}
        }
        
        # Scan scripts and web templates
        dirs_to_scan = ['scripts', 'templates/web']
        for d in dirs_to_scan:
            path = Path(d)
            if path.exists():
                for f in path.rglob('*'):
                    if f.is_file():
                        rel_path = str(f)
                        with open(f, "rb") as file_to_hash:
                            f_hash = hashlib.md5(file_to_hash.read()).hexdigest()
                        manifest["files"][rel_path] = {
                            "hash": f_hash,
                            "size": f.stat().st_size
                        }
        
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(manifest, indent=4, sort_keys=True).encode())

    def _handle_proxy_request(self):
        """Downloads a remote file to cache and serves it."""
        from urllib.parse import urlparse, parse_qs
        import urllib.request
        import shutil
        import hashlib

        # Ensure cache exists
        if not os.path.exists(self.CACHE_DIR):
            os.makedirs(self.CACHE_DIR)

        # Parse query
        query_components = parse_qs(urlparse(self.path).query)
        if 'url' not in query_components:
            self.send_error(400, "Missing 'url' parameter")
            return
        
        target_url = query_components['url'][0]
        
        # Security: Basic validation
        if not target_url.startswith(('http://', 'https://')):
            self.send_error(400, "Invalid protocol (http/https only)")
            return
            
        if 'localhost' in target_url or '127.0.0.1' in target_url:
            self.send_error(403, "Access to local resources denied")
            return

        # Generate safe filename from URL
        filename = os.path.basename(urlparse(target_url).path)
        if not filename or filename == '/':
            # If no filename in URL, hash the URL
            filename = hashlib.md5(target_url.encode()).hexdigest() + ".bin"
            
        cache_path = os.path.join(self.CACHE_DIR, filename)

        try:
            # Check cache
            if not os.path.exists(cache_path):
                print(f"[*] Proxy: Downloading {target_url} to {cache_path}")
                # Download with timeout
                with urllib.request.urlopen(target_url, timeout=30) as response, open(cache_path, 'wb') as out_file:
                    shutil.copyfileobj(response, out_file)
            else:
                print(f"[*] Proxy: Cache hit for {filename}")

            # Serve the file
            self.send_response(200)
            self.send_header('Content-Type', 'application/octet-stream')
            self.send_header('Content-Disposition', f'attachment; filename="{filename}"')
            file_size = os.path.getsize(cache_path)
            self.send_header("Content-Length", str(file_size))
            self.end_headers()

            with open(cache_path, 'rb') as f:
                self.wfile.write(f.read())

        except Exception as e:
            print(f"[!] Proxy Error: {e}")
            self.send_error(500, f"Download failed: {str(e)}")

    def do_POST(self):
        """Handle uploads and pastes from the client."""
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            content_type = self.headers.get('Content-Type', '')

            if content_length == 0:
                self.send_error(400, "Empty request")
                return

            # Feature: IP-based folder organization
            evidence_dir = self._get_client_dir("evidence")
            audit_dir = self._get_client_dir("audit_logs")
            
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")

            # Case 1: File Upload (Multi-part)
            if 'multipart/form-data' in content_type:
                boundary = content_type.split("boundary=")[1].encode()
                data = self.rfile.read(content_length)
                
                # Extract filename more robustly
                import re
                filename_match = re.search(b'filename="([^"]+)"', data)
                filename = filename_match.group(1).decode() if filename_match else "uploaded_file"
                
                filename = os.path.basename(filename)
                safe_filename = f"{timestamp}_{filename}"

                # Find the actual content between boundaries
                parts = data.split(b'\r\n\r\n', 1)
                if len(parts) > 1:
                    # Content starts after the first \r\n\r\n and ends before the next boundary
                    content = parts[1]
                    footer = b'\r\n--' + boundary
                    if footer in content:
                        content = content.split(footer)[0]
                    
                    with open(evidence_dir / safe_filename, "wb") as f:
                        f.write(content)
                    
                    self._success_response(f"File stored as {safe_filename}")
                else:
                    self.send_error(400, "Invalid multipart data")

            # Case 2: Text Paste (Urlencoded)
            elif 'application/x-www-form-urlencoded' in content_type:
                data_bytes = self.rfile.read(content_length)
                try:
                    data = data_bytes.decode('utf-8')
                    params = urllib.parse.parse_qs(data)
                    
                    if 'content' in params:
                        text_content = params['content'][0]
                        print(f"[*] Incoming Status ({self.client_address[0]}): {text_content}")
                        
                        # Feature: Consecutive Bootstrap Overwrite (US: Fresh session detection)
                        # If a new bootstrap run starts, truncate the audit log to avoid massive history accumulation.
                        write_mode = "a"
                        if text_content.startswith("[BOOTSTRAP]") and "Checking dependencies" in text_content:
                            print(f"[*] New bootstrap detected for {self.client_address[0]}. Truncating log.")
                            write_mode = "w"

                        # Log to IP-specific audit log
                        audit_log = audit_dir / "client_activity.log"
                        with open(audit_log, write_mode) as al:
                            al.write(f"[{timestamp}] {text_content}\n")

                        note_filename = f"{timestamp}_paste.txt"
                        
                        with open(evidence_dir / note_filename, "w") as f:
                            f.write(text_content)
                        
                        # Only notify PC if this isn't just a heartbeat/status update
                        should_notify = not (text_content.startswith('[BOOTSTRAP]') or text_content.startswith('[VNC-STATUS]'))
                        self._success_response(f"Text saved as {note_filename}", notify=should_notify)
                    else:
                        # Fallback: if urlencoded is missing 'content', store as raw file
                        # This happens with wget --post-file if it defaults to this content-type
                        safe_filename = f"{timestamp}_post_data.log"
                        with open(evidence_dir / safe_filename, "wb") as f:
                            f.write(data_bytes)
                        self._success_response(f"Data stored as {safe_filename}", notify=True)
                except UnicodeDecodeError:
                    # Binary data sent with text content-type
                    safe_filename = f"{timestamp}_binary_post.log"
                    with open(evidence_dir / safe_filename, "wb") as f:
                        f.write(data_bytes)
                    self._success_response(f"Binary data stored as {safe_filename}", notify=True)

            # Case 3: Raw Binary Upload (fallback for wget --post-file)
            else:
                data = self.rfile.read(content_length)
                # Guess extension based on content? Or just use .log/bin
                safe_filename = f"{timestamp}_raw_upload.log"
                with open(evidence_dir / safe_filename, "wb") as f:
                    f.write(data)
                self._success_response(f"Raw data stored as {safe_filename}", notify=True)

        except Exception as e:
            print(f"[!] POST Error: {e}")
            self.send_error(500, str(e))

        except Exception as e:
            print(f"[!] POST Error: {e}")
            self.send_error(500, str(e))

    def _success_response(self, message, notify=False):
        self.send_response(201)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.end_headers()
        response = f"<html><head><meta charset='UTF-8'></head><body><h2>✅ Success</h2><p>{message}</p><a href='/'>Back to Dashboard</a></body></html>"
        self.wfile.write(response.encode('utf-8'))
        
        # Notify PC handshake server ONLY if requested (to avoid feedback loops)
        if notify:
            self._notify_pc_async()

    def _notify_pc_async(self):
        """Tries to ping the PC handshake server in the background."""
        import threading
        import urllib.request
        
        # We try to guess the PC IP from the last request or local cache
        # For now, let's look for heartbeats in the audit logs to find the IP
        def peer_ping():
            try:
                # Get IP of the client that just sent the POST
                pc_ip = self.client_address[0]
                if pc_ip and pc_ip != '127.0.0.1':
                    url = f"http://{pc_ip}:8001/ping"
                    print(f"[*] Notifying PC at {url}...")
                    with urllib.request.urlopen(url, timeout=2) as r:
                        pass
            except Exception as e:
                # PC server might not be up yet or firewall blocked
                pass

        threading.Thread(target=peer_ping, daemon=True).start()

if __name__ == "__main__":
    import sys
    import urllib.request
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
    
    # Feature: Automatic cleanup of existing server on same port
    try:
        print(f"[*] Checking for existing server on port {port}...")
        with urllib.request.urlopen(f"http://localhost:{port}/shutdown", timeout=1) as r:
            if r.status == 200:
                print("[*] Successfully sent shutdown signal to existing server. Waiting for port to clear...")
                import time
                time.sleep(2)
    except Exception:
        # No server running or different server type, continue
        pass

    print(f"[*] Starting PC Rescue Station Uplink on port {port}...")
    # Use HTTPServer directly for better control
    server_address = ('', port)
    try:
        httpd = http.server.HTTPServer(server_address, RescueHTTPRequestHandler)
        httpd.serve_forever()
    except OSError as e:
        if e.errno == 48:
            print(f"[!] Error: Port {port} is still in use. Try again in a few seconds.")
            sys.exit(1)
        raise e
