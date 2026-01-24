import http.server
import os
import signal
import sys

PORT = 8001
SIGNAL_FILE = ".trigger_sync"

class HandshakeHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/ping':
            print("[*] Handshake: Ping received from Mac!")
            # Create signal file to trigger immediate sync in bootstrap
            with open(SIGNAL_FILE, "w") as f:
                f.write("1")
            
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain')
            self.end_headers()
            self.wfile.write(b"OK")
        elif self.path == '/confirm':
            print("[*] Handshake: User confirmed execution in browser.")
            with open(".confirmed", "w") as f:
                f.write("1")
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(b"CONFIRMED")
        else:
            self.send_error(404)

    def log_message(self, format, *args):
        # Silence standard logs to keep PC console clean
        pass

if __name__ == "__main__":
    print(f"[*] PC Handshake Listener active on port {PORT}")
    server_address = ('', PORT)
    httpd = http.server.HTTPServer(server_address, HandshakeHandler)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        sys.exit(0)
