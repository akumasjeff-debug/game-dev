import http.server, socketserver, os, sys

class H(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy","same-origin")
        self.send_header("Cross-Origin-Embedder-Policy","require-corp")
        super().end_headers()
    def log_message(self,f,*a): pass

os.chdir(r"d:\開發遊戲\遊戲\幽靈行動\build\web")
with socketserver.TCPServer(("",8767),H) as s:
    print("server ready", flush=True)
    s.serve_forever()
