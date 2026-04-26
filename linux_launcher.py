#!/usr/bin/env python3
import os
import threading
import http.server
import socketserver
import subprocess
import time
import urllib.request
import webbrowser

PORT = 8585
WEB_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "build", "web")
URL = f"http://localhost:{PORT}"

def is_server_running():
    try:
        urllib.request.urlopen(URL, timeout=1)
        return True
    except Exception:
        return False

class QuietHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)
    def log_message(self, format, *args):
        pass  # Peidame serveri logid

def start_server():
    with socketserver.TCPServer(("localhost", PORT), QuietHandler) as httpd:
        httpd.serve_forever()

if __name__ == "__main__":
    if not is_server_running():
        t = threading.Thread(target=start_server, daemon=True)
        t.start()
        time.sleep(0.5)

    # Proovime avada Chrome/Chromium/Brave äpi režiimis
    browsers = [
        ["google-chrome", f"--app={URL}"],
        ["chromium-browser", f"--app={URL}"],
        ["brave-browser", f"--app={URL}"]
    ]
    
    opened = False
    for cmd in browsers:
        try:
            # Käivitame brauseri ja eraldame protsessi
            subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            opened = True
            break
        except FileNotFoundError:
            continue
            
    if not opened:
        # Kui sobivat brauserit ei leitud, ava süsteemi vaikimisi brauseris
        webbrowser.open(URL)
        
    # Hoiame skripti elus, et server töötaks (kui kasutaja terminalist käivitab)
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        pass
