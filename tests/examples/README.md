# pymongoose Examples

This directory contains practical examples demonstrating how to use pymongoose for various networking scenarios. Each example is a runnable Python script that translates C tutorials from the Mongoose library.

## Priority 1: Core HTTP/WebSocket Examples

### HTTP Examples

#### 1. HTTP Server (`http/http_server.py`)

Comprehensive HTTP server demonstrating static file serving, TLS, file uploads, and API endpoints.

**Features**:
- Static file serving with `serve_dir()`
- File upload handling with multipart forms
- TLS/SSL configuration with self-signed certificates
- REST API endpoints
- Custom routing

**Usage**:
```bash
# Basic HTTP server on port 8000
python http/http_server.py

# Custom port
python http/http_server.py --port 8080

# HTTPS with self-signed certificate
python http/http_server.py --tls

# Custom web root directory
python http/http_server.py --root ./public
```

**Test**:
```bash
curl http://localhost:8000/
curl http://localhost:8000/api/info
curl -F "file=@README.md" http://localhost:8000/upload
```

**C Tutorial Reference**: `thirdparty/mongoose/tutorials/http/http-server/main.c`

---

#### 2. HTTP Client (`http/http_client.py`)

HTTP client with support for GET/POST requests, TLS, timeouts, and custom headers.

**Features**:
- Simple GET/POST requests
- TLS client configuration with CA certificates
- Connection timeout handling
- Custom headers
- Request/response processing

**Usage**:
```bash
# Simple GET request
python http/http_client.py https://httpbin.org/get

# POST with data
python http/http_client.py https://httpbin.org/post --method POST --data "hello=world"

# With custom headers
python http/http_client.py https://api.github.com/users/shakfu --header "User-Agent: pymongoose"

# With timeout
python http/http_client.py https://example.com --timeout 5

# Verbose output
python http/http_client.py https://httpbin.org/get --verbose
```

**Test**:
```bash
# Test with local server (run http_server.py first)
python http/http_client.py http://localhost:8000/api/info
```

**C Tutorial Reference**: `thirdparty/mongoose/tutorials/http/http-client/main.c`

---

### WebSocket Examples

#### 3. WebSocket Server (`websocket/websocket_server.py`)

WebSocket echo server with REST API and static file serving, demonstrating mixed HTTP+WS server.

**Features**:
- WebSocket upgrade from HTTP
- Echo server pattern (text and binary)
- REST API alongside WebSocket
- Static file serving
- Client tracking
- Interactive HTML interface

**Usage**:
```bash
# Start WebSocket server
python websocket/websocket_server.py

# Custom port
python websocket/websocket_server.py --port 8080

# Custom web root
python websocket/websocket_server.py --root ./public
```

**Test**:
```bash
# Open in browser (includes interactive WebSocket client)
open http://localhost:8000/

# Or test with Python websocket-client
python -c "
from websocket import create_connection
ws = create_connection('ws://localhost:8000/ws')
ws.send('Hello')
print(ws.recv())  # Echo: Hello
ws.close()
"

# Check stats API
curl http://localhost:8000/api/stats

# Broadcast to all clients
curl -X POST -d "Test message" http://localhost:8000/api/broadcast
```

**C Tutorial Reference**: `thirdparty/mongoose/tutorials/websocket/websocket-server/main.c`

---

#### 4. WebSocket Timer Broadcasting (`websocket/websocket_broadcast.py`)

WebSocket server with periodic broadcasting to all connected clients using timers.

**Features**:
- Periodic timer broadcasting to WebSocket clients
- Connection tracking with userdata
- Timer API with `MG_TIMER_REPEAT`
- Broadcasting to multiple connections
- Real-time push updates
- Statistics tracking

**Usage**:
```bash
# Start broadcast server (broadcasts every 1 second)
python websocket/websocket_broadcast.py

# Custom port and interval
python websocket/websocket_broadcast.py --port 8080 --interval 2.5
```

**Test**:
```bash
# Open multiple browser tabs to see synchronized broadcasts
open http://localhost:8000/
open http://localhost:8000/  # Second tab
open http://localhost:8000/  # Third tab

# All tabs will receive periodic broadcast messages
```

**C Tutorial Reference**: `thirdparty/mongoose/tutorials/core/timers/main.c`

---

## Running the Examples

### Prerequisites

```bash
# Install pymongoose in development mode
cd /path/to/pymongoose
uv sync

# Or with pip
pip install -e .
```

### Optional: WebSocket Client Library

For testing WebSocket clients from Python:

```bash
uv add --dev websocket-client
# or
pip install websocket-client
```

### Running Examples

All examples are standalone Python scripts that can be run directly:

```bash
# From the examples directory
cd tests/examples

# Run any example
python http/http_server.py
python http/http_client.py https://httpbin.org/get
python websocket/websocket_server.py
python websocket/websocket_broadcast.py
```

---

## Example Structure

Each example follows this pattern:

1. **Imports**: Standard library + pymongoose imports
2. **Event Handler**: Main event processing function
3. **Helper Functions**: Protocol-specific logic
4. **Main Function**: Argument parsing and setup
5. **Run Loop**: Event loop with `Manager.poll()`

This mirrors the structure of Mongoose C tutorials for easier comparison.

---

## Common Patterns

### Event Loop Pattern

```python
manager = Manager(handler)
manager.listen("http://0.0.0.0:8000", http=True)

try:
    while True:
        manager.poll(1000)  # Poll every 1000ms
except KeyboardInterrupt:
    print("Shutting down...")
finally:
    manager.close()
```

### HTTP Handler Pattern

```python
def handler(conn, event, data):
    if event == MG_EV_HTTP_MSG:
        uri = data.uri
        method = data.method

        if uri == "/api/endpoint":
            conn.reply(200, "Response")
        else:
            conn.serve_dir(data, root_dir="./public")
```

### WebSocket Handler Pattern

```python
def handler(conn, event, data):
    if event == MG_EV_HTTP_MSG and data.uri == "/ws":
        conn.ws_upgrade(data)  # Upgrade to WebSocket

    elif event == MG_EV_WS_MSG:
        conn.ws_send(data.text)  # Echo message
```

### Timer Pattern

```python
def timer_callback():
    print("Timer fired!")

timer = manager.timer_add(1000, timer_callback, repeat=True)
```

---

## Validation Benefits

These examples serve multiple purposes:

- **API Coverage**: Validates all wrapped functions work in real scenarios
- **Documentation**: Provides copy-paste examples for users
- **Testing**: Acts as integration tests for complex workflows
- **Debugging**: Exposes edge cases and API usability issues
- **Tutorial**: Helps C developers transition to Python wrapper

---

## Future Examples (Priority 2+)

See `CLAUDE.md` for the full list of examples to be implemented:

- MQTT Client/Server examples
- HTTP chunked/streaming examples
- SNTP time synchronization
- DNS resolution examples
- TLS mutual authentication
- Multi-threaded server with wakeup

---

## Contributing

When adding new examples:

1. Follow the existing structure and naming conventions
2. Include comprehensive docstrings with C tutorial reference
3. Add command-line argument parsing for flexibility
4. Include both programmatic and browser-based testing methods
5. Update this README with the new example
6. Test the example before committing

---

## License

MIT (same as pymongoose)
