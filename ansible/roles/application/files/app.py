#!/usr/bin/env python3

import json
import os
import socket
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


APPLICATION_NAME = os.getenv("APPLICATION_NAME", "eapdp")
APPLICATION_VERSION = os.getenv("APPLICATION_VERSION", "unknown")
APPLICATION_ENVIRONMENT = os.getenv("APPLICATION_ENVIRONMENT", "unknown")
APPLICATION_PORT = int(os.getenv("APPLICATION_PORT", "8080"))


class ApplicationHandler(BaseHTTPRequestHandler):
    def send_json_response(self, status_code, payload):
        response_body = json.dumps(payload, indent=2).encode("utf-8")

        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(response_body)))
        self.end_headers()

        self.wfile.write(response_body)

    def do_GET(self):
        if self.path == "/health":
            self.send_json_response(
                200,
                {
                    "status": "healthy",
                    "application": APPLICATION_NAME,
                    "version": APPLICATION_VERSION,
                    "environment": APPLICATION_ENVIRONMENT,
                    "hostname": socket.gethostname(),
                },
            )
            return

        if self.path == "/":
            self.send_json_response(
                200,
                {
                    "message": "Enterprise AWS Platform Delivery Pipeline",
                    "application": APPLICATION_NAME,
                    "version": APPLICATION_VERSION,
                    "environment": APPLICATION_ENVIRONMENT,
                    "hostname": socket.gethostname(),
                },
            )
            return

        self.send_json_response(
            404,
            {
                "status": "not_found",
                "path": self.path,
            },
        )

    def log_message(self, format, *args):
        print(
            '%s - - [%s] %s'
            % (
                self.client_address[0],
                self.log_date_time_string(),
                format % args,
            ),
            flush=True,
        )


def main():
    server_address = ("0.0.0.0", APPLICATION_PORT)
    server = ThreadingHTTPServer(server_address, ApplicationHandler)

    print(
        f"Starting {APPLICATION_NAME} version {APPLICATION_VERSION} "
        f"on port {APPLICATION_PORT}",
        flush=True,
    )

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
