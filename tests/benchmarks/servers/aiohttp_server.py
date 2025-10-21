#!/usr/bin/env python3
"""aiohttp HTTP server for performance benchmarking."""

from aiohttp import web


async def handle(request):
    """Simple JSON response handler."""
    return web.json_response({"message": "Hello, World!"})


def run_server(port: int = 8002):
    """Run aiohttp HTTP server."""
    app = web.Application()
    app.router.add_get("/", handle)
    app.router.add_post("/", handle)
    app.router.add_route("*", "/{path:.*}", handle)

    print(f"aiohttp server listening on http://0.0.0.0:{port}")
    web.run_app(app, host="0.0.0.0", port=port, print=None)


if __name__ == "__main__":
    import sys

    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8002
    run_server(port)
