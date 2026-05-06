#!/bin/bash
set -euo pipefail

cat > /opt/secure-vpc-app.py <<'PYTHON_APP'
from http.server import BaseHTTPRequestHandler, HTTPServer

class SecureVPCHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"OK")
            return

        if self.path == "/":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"Secure VPC Exposure Lab - Private Application Instance")
            return

        self.send_response(404)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(b"Not Found")

    def log_message(self, format, *args):
        return

server = HTTPServer(("0.0.0.0", 8080), SecureVPCHandler)
server.serve_forever()
PYTHON_APP

cat > /etc/systemd/system/secure-vpc-app.service <<'SYSTEMD_SERVICE'
[Unit]
Description=Secure VPC Exposure Lab Private Application
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /opt/secure-vpc-app.py
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
SYSTEMD_SERVICE

systemctl daemon-reload
systemctl enable secure-vpc-app.service
systemctl start secure-vpc-app.service