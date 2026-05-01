import os
import subprocess
import sys

def main():
    project_dir = os.getcwd()
    print("--- 1. Värskendan veebifaile ---")
    subprocess.run(["flutter", "build", "web", "--release"], shell=True, check=True)

    launcher_path = os.path.join(project_dir, "portable_launcher.py")
    
    # LÕPLIK KÄIVITAJA KOOD
    # LÕPLIK KÄIVITAJA KOOD
    launcher_code = """
import os
import sys
import threading
import http.server
import socketserver
import time
import webbrowser
import subprocess
import socket
import tempfile
import shutil

def get_resource_path(relative_path):
    if hasattr(sys, '_MEIPASS'):
        return os.path.join(sys._MEIPASS, relative_path)
    return os.path.join(os.path.abspath("."), relative_path)

def get_free_port():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(('127.0.0.1', 0))
        return s.getsockname()[1]

PORT = get_free_port()
WEB_DIR = get_resource_path(os.path.join("build", "web"))
URL = f"http://127.0.0.1:{PORT}"

class QuietHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)
    def log_message(self, format, *args):
        pass

def start_server():
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("127.0.0.1", PORT), QuietHandler) as httpd:
        httpd.serve_forever()

if __name__ == "__main__":
    t = threading.Thread(target=start_server, daemon=True)
    t.start()
    time.sleep(0.5)

    browsers = [
        r"C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
        r"C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe",
        r"C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
        r"C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe"
    ]

    browser_path = None
    for path in browsers:
        if os.path.exists(path):
            browser_path = path
            break

    if browser_path:
        # 1. PARANDUS: Loome püsiva, aga eraldiseisva profiili kausta Windowsi AppData alla
        app_data = os.environ.get('LOCALAPPDATA', os.path.expanduser('~'))
        persistent_profile = os.path.join(app_data, 'EstinolEditorProfile')
        os.makedirs(persistent_profile, exist_ok=True)
        
        # 2. Käivitame brauseri püsiva profiiliga
        subprocess.run([
            browser_path, 
            f'--app={URL}', 
            f'--user-data-dir={persistent_profile}',
            '--no-first-run',             
            '--no-default-browser-check', 
            '--disable-extensions',       
            '--disable-sync'              
        ])
        
        # 3. Me ENAM EI KUSTUTA profiili kausta pärast sulgemist, et mälu säiliks!
        sys.exit(0)
    else:
        webbrowser.open(URL)
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            pass
"""
    with open(launcher_path, "w", encoding="utf-8") as f:
        f.write(launcher_code)

    print("\\n--- 2. Pakendan kõik üheks EXE failiks ---")
    
    # Veendu, et sul on õige ikooni nimi! (Vajadusel muuda tagasi icon.png või estinol.ico)
    icon_path = os.path.join(project_dir, "assets", "estinol.ico") 
    
    pyinstall_cmd = [
        "python", "-m", "PyInstaller",
        "--onefile",
        "--noconsole",
        f"--icon={icon_path}" if os.path.exists(icon_path) else "",
        f"--add-data=build/web;build/web",
        "--name=Estinol_Editor_2",
        launcher_path
    ]
    
    pyinstall_cmd = [part for part in pyinstall_cmd if part]
    subprocess.run(pyinstall_cmd, shell=True, check=True)

    print("\\n--- VALMIS! ---")
    print("Sinu pakendatud programm asub 'dist' kaustas nimega Estinol_Editor_2.exe")

if __name__ == "__main__":
    main()