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

    def do_GET(self):
        # Feature 004: Proxy Download Cache
        if self.path.startswith('/proxy'):
            self._handle_proxy_request()
            return
            
        super().do_GET()

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

            evidence_dir = Path("evidence")
            evidence_dir.mkdir(exist_ok=True)
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")

            # Case 1: File Upload (Multi-part)
            if 'multipart/form-data' in content_type:
                boundary = content_type.split("boundary=")[1].encode()
                data = self.rfile.read(content_length)
                
                filename = "uploaded_file"
                if b'filename="' in data:
                    filename = data.split(b'filename="')[1].split(b'"')[0].decode()
                
                filename = os.path.basename(filename)
                safe_filename = f"{timestamp}_{filename}"

                # Simplified multipart split
                parts = data.split(b'\r\n\r\n')
                if len(parts) > 1:
                    file_content = b'\r\n\r\n'.join(parts[1:])
                    file_content = file_content.split(b'\r\n--' + boundary)[0]
                    
                    with open(evidence_dir / safe_filename, "wb") as f:
                        f.write(file_content)
                    
                    self._success_response(f"File stored as {safe_filename}")
                else:
                    self.send_error(400, "Invalid multipart data")

            # Case 2: Text Paste (Urlencoded)
            elif 'application/x-www-form-urlencoded' in content_type:
                data = self.rfile.read(content_length).decode('utf-8')
                params = urllib.parse.parse_qs(data)
                
                if 'content' in params:
                    text_content = params['content'][0]
                    print(f"[*] Incoming Status: {text_content}")
                    note_filename = f"{timestamp}_paste.txt"
                    
                    with open(evidence_dir / note_filename, "w") as f:
                        f.write(text_content)
                    
                    self._success_response(f"Text saved as {note_filename}")
                else:
                    self.send_error(400, "Missing 'content' field")

            else:
                self.send_error(415, "Unsupported Media Type")

        except Exception as e:
            print(f"[!] POST Error: {e}")
            self.send_error(500, str(e))

    def _success_response(self, message):
        self.send_response(201)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.end_headers()
        response = f"<html><head><meta charset='UTF-8'></head><body><h2>✅ Success</h2><p>{message}</p><a href='/'>Back to Dashboard</a></body></html>"
        self.wfile.write(response.encode('utf-8'))

if __name__ == "__main__":
    import sys
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
    print(f"[*] Starting PC Rescue Station Uplink on port {port}...")
    # Use HTTPServer directly for better control
    server_address = ('', port)
    httpd = http.server.HTTPServer(server_address, RescueHTTPRequestHandler)
    httpd.serve_forever()
