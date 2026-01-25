import socket
import struct
import sys

def test_vnc_handshake(host, port=5900):
    print(f"[*] Connecting to {host}:{port}...")
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(5)
        s.connect((host, port))
        
        # 1. ProtocolVersion
        version = s.recv(12)
        print(f"[+] Server Version: {version.decode().strip()}")
        
        # Respond with 3.3 (Safest common denominator)
        s.send(b"RFB 003.003\n")
        print("[*] Sent Client Version: RFB 003.003")
        
        # 2. Security Handshake
        # Read 4 bytes (SecurityType count)
        sec_bytes = s.recv(4)
        if not sec_bytes:
            print("[!] Connection closed by server during security handshake")
            return
            
        sec_val = int.from_bytes(sec_bytes, "big")
        print(f"[+] Security Auth Type: {sec_val}")
        
        if sec_val == 0:
            print("[!] Connection Failed (Reason follows)")
            reason_len = int.from_bytes(s.recv(4), "big")
            reason = s.recv(reason_len)
            print(f"[-] Failure Reason: {reason.decode()}")
            return
            
        if sec_val == 1:
            # None (No Auth)
            print("[+] Authentication Successful (None required)")
        else:
            print(f"[!] Server requested Auth Type {sec_val} (We only support None/1 for this test)")
            
        # 3. ClientInit (Shared=1)
        print("[*] Sending ClientInit (Shared Session)...")
        s.send(b"\x01")
        
        # 4. ServerInit
        print("[*] Waiting for ServerInit (Screen Resolution)...")
        server_init = s.recv(24)
        if len(server_init) < 24:
            print("[!] Failed to receive ServerInit")
            return
            
        w, h = struct.unpack(">HH", server_init[0:4])
        name_len = int.from_bytes(server_init[20:24], "big")
        name = s.recv(name_len).decode()
        
        print(f"[+] 🚀 SUCCESS! Connected to Desktop.")
        print(f"    Resolution: {w}x{h}")
        print(f"    Desktop Name: {name}")
        
    except Exception as e:
        print(f"[-] Error: {e}")
    finally:
        s.close()

def probe_vnc(host):
    print(f"[*] Probing {host} for VNC (5900-5905)...")
    results = []
    for port in range(5900, 5906):
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.settimeout(2)
            res = s.connect_ex((host, port))
            if res == 0:
                print(f"[+] Found open port: {port}")
                # Try handshake
                s.settimeout(5)
                version = s.recv(12)
                if version.startswith(b"RFB"):
                    s.send(b"RFB 003.003\n")
                    sec_bytes = s.recv(4)
                    if not sec_bytes:
                        results.append((port, "Handshake failed"))
                        continue
                    sec_val = int.from_bytes(sec_bytes, "big")
                    
                    # Try to get desktop name via ClientInit/ServerInit
                    s.send(b"\x01") # ClientInit (Shared)
                    server_init = s.recv(24)
                    name = "Unknown"
                    if len(server_init) >= 24:
                        name_len = int.from_bytes(server_init[20:24], "big")
                        name = s.recv(name_len).decode()
                    
                    results.append((port, f"UP (Auth:{sec_val}, Name:{name})"))
            s.close()
        except:
            pass
    
    if results:
        best_port, status = results[0]
        print(f"RESULT: {best_port} | {status}")
        return best_port, status
    else:
        print("RESULT: FAIL")
        return None, "No VNC server found"

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 vnc_diag.py <IP_ADDRESS> [PORT]")
    else:
        host = sys.argv[1]
        if len(sys.argv) > 2:
            test_vnc_handshake(host, int(sys.argv[2]))
        else:
            probe_vnc(host)
