#!/usr/bin/env python3
"""pymongoose HTTP server for performance benchmarking."""

import threading
from pymongoose import Manager, MG_EV_HTTP_MSG


def run_server(port: int = 8001):
    """Run pymongoose HTTP server."""
    # Simple JSON response
    json_response = b'{"message":"Hello, World!"}'

    def handler(conn, ev, data):
        if ev == MG_EV_HTTP_MSG:
            conn.reply(
                200,
                json_response,
                headers={"Content-Type": "application/json"}
            )

    manager = Manager(handler)
    manager.listen(f"http://0.0.0.0:{port}", http=True)
    print(f"pymongoose server listening on http://0.0.0.0:{port}", flush=True)

    # Run event loop
    try:
        while True:
            manager.poll(1000)
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    import sys
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8001
    run_server(port)
