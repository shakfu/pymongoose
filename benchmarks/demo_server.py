#!/usr/bin/env python3
"""
Demo pymongoose HTTP server.

Run this and visit http://localhost:8765/ in your browser or use curl.
Press Ctrl+C to stop.
"""
from pymongoose import Manager, MG_EV_HTTP_MSG

def handler(conn, ev, data):
    """Handle HTTP requests."""
    if ev == MG_EV_HTTP_MSG:
        # Log the request
        print(f"{data.method} {data.uri}")

        # Send JSON response
        conn.reply(
            200,
            b'{"message":"Hello from pymongoose!","server":"C-based event loop"}',
            headers={"Content-Type": "application/json"}
        )

def main():
    port = 8765
    manager = Manager(handler)
    manager.listen(f'http://0.0.0.0:{port}', http=True)

    print(f"🚀 pymongoose HTTP server running on http://localhost:{port}/")
    print(f"   Press Ctrl+C to stop")
    print(f"   USE_NOGIL optimization enabled")
    print()

    try:
        while True:
            manager.poll(1000)
    except KeyboardInterrupt:
        print("\n✋ Server stopped")

if __name__ == "__main__":
    main()
