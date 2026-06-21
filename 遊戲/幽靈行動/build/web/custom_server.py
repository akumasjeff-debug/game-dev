import http.server
import socketserver
import os

class CustomHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

    def log_message(self, format, *args):
        pass  # 靜音

os.chdir(r"d:\開發遊戲\遊戲\幽靈行動\build\web")
with socketserver.TCPServer(("", 8766), CustomHandler) as httpd:
    httpd.serve_forever()
