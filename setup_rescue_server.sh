#!/bin/bash

# 1. Define where the site will live (Desktop by default)
BASE_DIR="$HOME/Desktop/rescue-site"

echo "Setting up rescue server at: $BASE_DIR"

# 2. Create the directory structure
mkdir -p "$BASE_DIR/scripts"
mkdir -p "$BASE_DIR/manuals"
mkdir -p "$BASE_DIR/drivers"

# 3. Generate the index.html file
# We use 'cat' with a heredoc to write the HTML content instantly
cat << 'EOF' > "$BASE_DIR/index.html"
<!DOCTYPE html>
<html>
<head>
    <title>Rescue Dashboard</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; max-width: 800px; margin: 2rem auto; padding: 0 1rem; background: #f0f2f5; color: #333; }
        .container { background: white; padding: 2rem; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        h1 { margin-top: 0; color: #1a1a1a; border-bottom: 2px solid #007aff; padding-bottom: 1rem; }
        h2 { margin-top: 2rem; font-size: 1.25rem; color: #444; display: flex; align-items: center; }
        ul { list-style: none; padding: 0; }
        li { margin: 0.5rem 0; padding: 0.75rem; background: #f8f9fa; border-radius: 6px; border: 1px solid #e9ecef; transition: transform 0.1s; }
        li:hover { transform: translateX(5px); border-color: #007aff; }
        a { text-decoration: none; color: #007aff; font-weight: 600; display: block; }
        .ip-placeholder { background: #fff3cd; color: #856404; padding: 1rem; border-radius: 6px; margin-bottom: 2rem; border-left: 4px solid #ffc107; }
        code { background: rgba(0,0,0,0.05); padding: 0.2rem 0.4rem; border-radius: 4px; font-family: monospace; }
    </style>
</head>
<body>

<div class="container">
    <h1>🚑 PC Rescue Station</h1>
    
    <div class="ip-placeholder">
        <strong>💡 Tip:</strong> To download a file to the PC terminal, type:<br>
        <code>wget http://[YOUR-MAC-IP]:8000/scripts/filename.sh</code>
    </div>

    <h2>📂 Scripts & Tools</h2>
    <ul>
        <li><a href="scripts/">Browse Scripts Directory</a></li>
    </ul>

    <h2>📚 Manuals & PDFs</h2>
    <ul>
        <li><a href="manuals/">Browse Manuals Directory</a></li>
    </ul>

    <h2>💾 Drivers</h2>
    <ul>
        <li><a href="drivers/">Browse Drivers Directory</a></li>
    </ul>
</div>

</body>
</html>
EOF

# 4. Create a dummy test script so the folder isn't empty
cat << 'EOF' > "$BASE_DIR/scripts/test_connection.sh"
#!/bin/bash
echo "Success! The PC can read files from the Mac server."
echo "Current Date: $(date)"
EOF

# 5. Get the Mac's IP address (try Wi-Fi first, then Ethernet)
MY_IP=$(ipconfig getifaddr en0)
if [ -z "$MY_IP" ]; then
    MY_IP=$(ipconfig getifaddr en1)
fi

# 6. Output instructions
echo "-------------------------------------------------------"
echo "✅ Setup Complete!"
echo ""
echo "Files are located at: $BASE_DIR"
echo ""
echo "To start the server, run this command:"
echo "-------------------------------------------------------"
echo "cd $BASE_DIR && uv python -m http.server 8000"
echo "-------------------------------------------------------"
echo ""
echo "Then, on your PC, visit:"
if [ -n "$MY_IP" ]; then
    echo "http://$MY_IP:8000"
else
    echo "http://[YOUR-IP-ADDRESS]:8000 (Could not auto-detect IP)"
fi
echo ""