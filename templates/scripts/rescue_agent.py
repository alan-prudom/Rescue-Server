import os
import sys
import time
import subprocess
import json
import socket
import hashlib

# PC Rescue Station: Unified Python Agent (v1.5.0)
# FEATURES: Verbose Loop Logging, Self-Updating, Checksum-Sync, Smart Polling

VERSION = "1.5.0"
MAC_IPS = ["192.168.1.61", "192.168.1.244", "192.168.1.8", "100.87.229.122"]
PORT = 8000

# Timing settings (seconds)
PROFILER_INTERVAL = 3600  
HEARTBEAT_MIN = 30        
HEARTBEAT_MAX = 300       

def get_file_hash(filepath):
    """Calculate MD5 hash of a local file."""
    if not os.path.exists(filepath):
        return ""
    hasher = hashlib.md5()
    with open(filepath, 'rb') as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hasher.update(chunk)
    return hasher.hexdigest()

def log_status(msg, mac_url):
    print(f"[*] {msg}")
    try:
        subprocess.run(["curl", "-s", "-d", f"content=[AGENT] {msg}", f"{mac_url}/"], capture_output=True)
    except:
        pass

def find_server():
    for ip in MAC_IPS:
        url = f"http://{ip}:{PORT}"
        try:
            socket.setdefaulttimeout(1)
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.connect((ip, PORT))
            s.close()
            return url
        except:
            continue
    return None

def sync_files(server_url):
    """Check manifest and download updated scripts based on checksums."""
    try:
        manifest_raw = subprocess.check_output(["curl", "-s", f"{server_url}/manifest/"]).decode()
        manifest = json.loads(manifest_raw)
        files = manifest.get("files", {})
        
        updated_any = False
        
        for remote_path, info in files.items():
            if not remote_path.startswith("scripts/"):
                continue
                
            local_filename = os.path.basename(remote_path)
            remote_hash = info.get("hash")
            local_hash = get_file_hash(local_filename)
            
            if remote_hash != local_hash:
                print(f"[*] Syncing {local_filename} (Hash mismatch)...")
                tmp_file = local_filename + ".tmp"
                subprocess.run(["curl", "-s", "-o", tmp_file, f"{server_url}/{remote_path}"])
                
                if get_file_hash(tmp_file) == remote_hash:
                    if local_filename == "rescue_agent.py":
                        print("🚀 SELF-UPDATE DETECTED. Restarting agent...")
                        log_status("Self-updating to newer agent version", server_url)
                        os.rename(tmp_file, local_filename)
                        os.chmod(local_filename, 0o755)
                        os.execv(sys.executable, ['python3'] + sys.argv)
                    
                    os.rename(tmp_file, local_filename)
                    os.chmod(local_filename, 0o755)
                    log_status(f"Synced script: {local_filename}", server_url)
                    updated_any = True
                else:
                    os.remove(tmp_file)
        
        return updated_any
    except Exception as e:
        print(f"⚠️  Sync failed: {e}")
        return False

def main():
    print(f"🚀 PC Rescue Agent v{VERSION} starting...")
    
    server_url = find_server()
    if not server_url:
        print("❌ Could not reach Mac server.")
        sys.exit(1)

    # Fix Browser Integration for Chromebooks
    try:
        if "penguin" in socket.gethostname():
            subprocess.run("xdg-settings set default-web-browser garcon-url-handler.desktop", shell=True, capture_output=True)
    except:
        pass

    log_status(f"Agent v{VERSION} online", server_url)

    last_profile_time = 0
    last_instr_hash = ""
    heartbeat_delay = HEARTBEAT_MIN

    while True:
        try:
            current_time = time.time()
            server_ip = server_url.replace('http://', '').replace(':8000', '')
            
            print(f"\n--- [Cycle Start: {time.strftime('%H:%M:%S')}] ---")
            
            # 1. Sync Phase
            print("[1/3] Checking file synchronization...")
            sync_files(server_url)
            
            # 2. Instruction Phase
            print("[2/3] Checking for injected instructions...")
            manifest_raw = subprocess.check_output(["curl", "-s", f"{server_url}/manifest/"]).decode()
            manifest = json.loads(manifest_raw)
            file_info = manifest.get("files", {}).get("scripts/instructions.sh", {})
            current_hash = file_info.get("hash", "")
            
            if current_hash and current_hash != last_instr_hash:
                print(f"🔥 FIRE: New instructions detected (Hash: {current_hash[:8]})")
                log_status(f"Executing injected instruction (Hash: {current_hash[:8]})", server_url)
                
                if os.path.exists("render_output.py"):
                    subprocess.run(f"python3 render_output.py result_template.html instructions.sh 'Latest' 'PENDING' > res.html", shell=True)
                    if subprocess.run("command -v garcon-url-handler", shell=True).returncode == 0:
                        subprocess.run("garcon-url-handler res.html &", shell=True)
                    else:
                        subprocess.run("xdg-open res.html &", shell=True)
                
                subprocess.run(f"./instructions.sh {server_ip}", shell=True)
                last_instr_hash = current_hash
            else:
                print("   (No new instructions)")
            
            # 3. Heartbeat Phase
            print(f"[3/3] Sending heartbeat. Sleeping for {int(heartbeat_delay)}s...")
            log_status(f"Cycle complete. Passive for {int(heartbeat_delay)}s.", server_url)
            
            time.sleep(heartbeat_delay)
            heartbeat_delay = min(heartbeat_delay * 1.5, HEARTBEAT_MAX)
            
        except KeyboardInterrupt:
            print("\n👋 Agent stopping.")
            break
        except Exception as e:
            print(f"⚠️  Error: {e}")
            time.sleep(10)
            server_url = find_server() or server_url

if __name__ == "__main__":
    main()
