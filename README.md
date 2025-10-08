# pymongoose

Python bindings for the Mongoose embedded networking library, built with Cython.

## Overview

**pymongoose** provides Pythonic access to [Mongoose](https://github.com/cesanta/mongoose), a lightweight embedded networking library written in C. It supports HTTP servers, WebSocket, TCP/UDP sockets, and more through a clean, event-driven API.

## Features

- **HTTP Server**: Serve static files, handle dynamic requests, parse headers and query parameters
- **WebSocket**: Full WebSocket support with text/binary frames
- **Event-driven**: Non-blocking I/O with a simple event loop
- **Low overhead**: Thin Cython wrapper over native C library
- **Python 3.9+**: Modern Python with type hints

## Installation

### From source

```bash
# Clone the repository
git clone https://github.com/shakfu/pymongoose
cd pymongoose

# Install with uv (recommended)
uv sync

# Or with pip
pip install -e .
```

### Requirements

- Python 3.9 or higher
- Cython 3.0+
- C compiler (gcc, clang, or MSVC)

## Quick Start

### Simple HTTP Server

```python
from pymongoose import Manager, MG_EV_HTTP_MSG

def handler(conn, event, data):
    if event == MG_EV_HTTP_MSG:
        conn.reply(200, "Hello, World!")

mgr = Manager(handler)
mgr.listen("http://0.0.0.0:8000", http=True)

print("Server running on http://localhost:8000")
while True:
    mgr.poll(1000)
```

### Serve Static Files

```python
from pymongoose import Manager, MG_EV_HTTP_MSG

def handler(conn, event, data):
    if event == MG_EV_HTTP_MSG:
        conn.serve_dir(data, root_dir="./public")

mgr = Manager(handler)
mgr.listen("http://0.0.0.0:8000", http=True)

while True:
    mgr.poll(1000)
```

### WebSocket Echo Server

```python
from pymongoose import Manager, MG_EV_HTTP_MSG, MG_EV_WS_MSG

def handler(conn, event, data):
    if event == MG_EV_HTTP_MSG:
        conn.ws_upgrade(data)  # Upgrade HTTP to WebSocket
    elif event == MG_EV_WS_MSG:
        conn.ws_send(data.text)  # Echo back

mgr = Manager(handler)
mgr.listen("http://0.0.0.0:8000", http=True)

while True:
    mgr.poll(1000)
```

## API Reference

### Manager

The main event loop manager.

```python
mgr = Manager(handler=None)
```

- `poll(timeout_ms=0)` - Run one iteration of the event loop
- `listen(url, handler=None, http=False)` - Create a listening socket
- `connect(url, handler=None, http=False)` - Create an outbound connection
- `close()` - Free resources

### Connection

Represents a network connection.

```python
# Send data
conn.send(data)                    # Raw bytes
conn.reply(status, body, headers)  # HTTP response
conn.ws_upgrade(message)           # Upgrade HTTP to WebSocket
conn.ws_send(data, op)             # WebSocket frame

# Properties
conn.is_listening
conn.is_closing
conn.userdata                      # Attach custom data

# Methods
conn.set_handler(handler)          # Per-connection handler
conn.close()                       # Close connection
```

### HttpMessage

HTTP request/response view.

```python
msg.method          # "GET", "POST", etc.
msg.uri             # "/path"
msg.query           # "?key=value"
msg.body_text       # Body as string
msg.body_bytes      # Body as bytes
msg.header("Name")  # Get header value
msg.headers()       # All headers as list of tuples
msg.query_var("key") # Extract query parameter
```

### WsMessage

WebSocket frame data.

```python
ws.text    # Frame data as string
ws.data    # Frame data as bytes
ws.flags   # WebSocket flags
```

### Event Constants

```python
MG_EV_ERROR       # Error occurred
MG_EV_OPEN        # Connection created
MG_EV_POLL        # Poll iteration
MG_EV_CONNECT     # Outbound connection established
MG_EV_ACCEPT      # Inbound connection accepted
MG_EV_READ        # Data available to read
MG_EV_WRITE       # Data written
MG_EV_CLOSE       # Connection closed
MG_EV_HTTP_MSG    # HTTP message received
MG_EV_WS_OPEN     # WebSocket handshake complete
MG_EV_WS_MSG      # WebSocket message received
```

## Testing

The project includes a comprehensive test suite with 35 tests covering:
- HTTP server functionality (15 tests)
- WebSocket support (10 tests)
- Connection lifecycle and properties
- Custom headers and query parameters
- Event handling and callbacks
- Error handling and exception safety

```bash
make test                        # Run HTTP tests
PYTHONPATH=src uv run pytest tests/ -v  # Run all tests including WebSocket
```

WebSocket tests require `websocket-client` (install via `uv add --dev websocket-client`). All tests use dynamic port allocation to avoid conflicts and can run concurrently.

## Development

### Build

```bash
make build          # Build with CMake
make build CONFIG=Debug UNIVERSAL=1  # Debug build, universal binary (macOS)

# Force rebuild
uv pip install -e . --force-reinstall --no-deps
```

### Test

```bash
make test                    # Run all tests
pytest tests/ -v             # Verbose output
pytest tests/test_http_server.py -v  # Run specific test file
```

### Clean

```bash
make clean          # Remove build artifacts
```

## Architecture

- **Cython bindings** (`src/pymongoose/_mongoose.pyx`): Python wrapper classes
- **C declarations** (`src/pymongoose/mongoose.pxd`): Cython interface to Mongoose C API
- **Vendored Mongoose** (`thirdparty/mongoose/`): Embedded C library

## License

MIT

## Links

- [Mongoose Documentation](https://mongoose.ws/)
- [GitHub Repository](https://github.com/shakfu/pymongoose)
