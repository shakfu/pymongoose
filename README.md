# pymongoose

Python bindings for the Mongoose embedded networking library, built with Cython.

## Overview

**pymongoose** provides Pythonic access to [Mongoose](https://github.com/cesanta/mongoose), a lightweight embedded networking library written in C. It supports HTTP servers, WebSocket, TCP/UDP sockets, and more through a clean, event-driven API.

## Features

### Core Protocols
- **HTTP/HTTPS**: Server and client with TLS support, chunked transfer encoding, SSE
- **WebSocket/WSS**: Full WebSocket support with text/binary frames over TLS
- **MQTT/MQTTS**: Publish/subscribe messaging with QoS support
- **TCP/UDP**: Raw socket support with custom protocols
- **DNS**: Asynchronous hostname resolution
- **SNTP**: Network time synchronization

### Advanced Features
- **TLS/SSL**: Certificate-based encryption with custom CA support
- **Timers**: Periodic callbacks with precise timing control
- **Flow Control**: Backpressure handling and buffer management
- **Authentication**: HTTP Basic Auth, MQTT credentials
- **JSON Parsing**: Built-in JSON extraction utilities
- **URL Encoding**: Safe URL parameter encoding

### Technical
- **Event-driven**: Non-blocking I/O with a simple event loop
- **Low overhead**: Thin Cython wrapper over native C library
- **Python 3.9+**: Modern Python with type hints
- **Comprehensive**: 210 tests, 100% pass rate
- **Production Examples**: 17 complete examples from Mongoose tutorials
- **TLS Support**: Built-in TLS/SSL encryption (MG_TLS_BUILTIN)
- **GIL Optimization**: 21 methods release GIL for true parallel execution
- **High Performance**: 60k+ req/sec (6-37x faster than pure Python frameworks)

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
import signal
from pymongoose import Manager, MG_EV_HTTP_MSG

shutdown_requested = False

def signal_handler(sig, frame):
    global shutdown_requested
    shutdown_requested = True

def handler(conn, event, data):
    if event == MG_EV_HTTP_MSG:
        conn.reply(200, "Hello, World!")

signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

mgr = Manager(handler)
mgr.listen("http://0.0.0.0:8000", http=True)

print("Server running on http://localhost:8000. Press Ctrl+C to stop.")
try:
    while not shutdown_requested:
        mgr.poll(100)
    print("Shutting down...")
finally:
    mgr.close()
```

### Serve Static Files

```python
import signal
from pymongoose import Manager, MG_EV_HTTP_MSG

shutdown_requested = False

def signal_handler(sig, frame):
    global shutdown_requested
    shutdown_requested = True

def handler(conn, event, data):
    if event == MG_EV_HTTP_MSG:
        conn.serve_dir(data, root_dir="./public")

signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

mgr = Manager(handler)
mgr.listen("http://0.0.0.0:8000", http=True)

try:
    while not shutdown_requested:
        mgr.poll(100)
finally:
    mgr.close()
```

### WebSocket Echo Server

```python
import signal
from pymongoose import Manager, MG_EV_HTTP_MSG, MG_EV_WS_MSG

shutdown_requested = False

def signal_handler(sig, frame):
    global shutdown_requested
    shutdown_requested = True

def handler(conn, event, data):
    if event == MG_EV_HTTP_MSG:
        conn.ws_upgrade(data)  # Upgrade HTTP to WebSocket
    elif event == MG_EV_WS_MSG:
        conn.ws_send(data.text)  # Echo back

signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

mgr = Manager(handler)
mgr.listen("http://0.0.0.0:8000", http=True)

try:
    while not shutdown_requested:
        mgr.poll(100)
finally:
    mgr.close()
```

## Examples

The project includes **17 complete, production-ready examples** translated from Mongoose C tutorials:

### Priority 1: Core HTTP/WebSocket (4 examples)
- **HTTP Server** - Static files, TLS, multipart uploads, REST API
- **HTTP Client** - GET/POST, TLS, timeouts, custom headers
- **WebSocket Server** - Echo, mixed HTTP+WS, client tracking
- **WebSocket Broadcasting** - Timer-based broadcasts to multiple clients

### Priority 2: MQTT (2 examples)
- **MQTT Client** - Pub/sub, QoS, reconnection, keepalive
- **MQTT Broker** - Message routing, topic matching, subscriptions

### Priority 3: Specialized HTTP (4 examples)
- **HTTP Streaming** - Chunked transfer encoding, large responses
- **HTTP File Upload** - Disk streaming, multipart forms
- **RESTful Server** - JSON API, CRUD operations, routing
- **Server-Sent Events** - Real-time push updates

### Priority 4: Network Protocols (4 examples)
- **SNTP Client** - Network time sync over UDP
- **DNS Client** - Async hostname resolution
- **TCP Echo Server** - Raw TCP sockets, custom protocols
- **UDP Echo Server** - Connectionless datagrams

### Priority 5: Advanced Features (3 examples)
- **TLS HTTPS Server** - Certificate-based encryption, SNI
- **HTTP Proxy Client** - CONNECT method tunneling
- **Multi-threaded Server** - Background workers, `Manager.wakeup()`

**All examples include:**
- Production-ready patterns (signal handlers, graceful shutdown)
- Command-line arguments for flexibility
- Comprehensive test coverage (42 tests)
- Detailed documentation with C tutorial references

See `tests/examples/README.md` for usage instructions and `tests/examples/` for source code.

## API Reference

### Manager

The main event loop manager.

```python
mgr = Manager(handler=None, enable_wakeup=False)
```

**Core Methods:**
- `poll(timeout_ms=0)` - Run one iteration of the event loop
- `listen(url, handler=None)` - Create a listening socket
- `connect(url, handler=None)` - Create an outbound connection
- `close()` - Free resources

**Protocol-Specific:**
- `http_listen(url, handler=None)` - Create HTTP server
- `http_connect(url, handler=None)` - Create HTTP client
- `ws_connect(url, handler=None)` - WebSocket client
- `mqtt_connect(url, handler=None, client_id, username, password, ...)` - MQTT client
- `mqtt_listen(url, handler=None)` - MQTT broker
- `sntp_connect(url, handler=None)` - SNTP time client
- `timer_add(milliseconds, callback, repeat=False, run_now=False)` - Add periodic timer
- `wakeup(connection_id, data)` - Wake connection from another thread

### Connection

Represents a network connection.

```python
# Send data
conn.send(data)                    # Raw bytes
conn.reply(status, body, headers)  # HTTP response
conn.ws_upgrade(message)           # Upgrade HTTP to WebSocket
conn.ws_send(data, op)             # WebSocket frame

# HTTP
conn.serve_dir(message, root_dir)  # Serve static files
conn.serve_file(message, path)     # Serve single file
conn.http_chunk(data)              # Send chunked data
conn.http_sse(event_type, data)    # Server-Sent Events
conn.http_basic_auth(user, pass)   # HTTP Basic Auth

# MQTT
conn.mqtt_pub(topic, message, qos=0, retain=False)
conn.mqtt_sub(topic, qos=0)
conn.mqtt_ping()
conn.mqtt_pong()
conn.mqtt_disconnect()

# SNTP
conn.sntp_request()                # Request time

# TLS
conn.tls_init(TlsOpts(...))        # Initialize TLS
conn.tls_free()                    # Free TLS resources

# DNS
conn.resolve(url)                  # Async DNS lookup
conn.resolve_cancel()              # Cancel DNS lookup

# Connection management
conn.drain()                       # Graceful close (flush buffer first)
conn.close()                       # Immediate close
conn.error(message)                # Trigger error event

# Properties
conn.is_listening      # Listener socket?
conn.is_websocket      # WebSocket connection?
conn.is_tls            # TLS/SSL enabled?
conn.is_udp            # UDP socket?
conn.is_readable       # Data available?
conn.is_writable       # Can write?
conn.is_full           # Buffer full? (backpressure)
conn.is_draining       # Draining before close?
conn.id                # Connection ID
conn.userdata          # Custom Python object
conn.local_addr        # (ip, port) tuple
conn.remote_addr       # (ip, port) tuple

# Buffer access
conn.recv_len          # Bytes in receive buffer
conn.send_len          # Bytes in send buffer
conn.recv_size         # Receive buffer capacity
conn.send_size         # Send buffer capacity
conn.recv_data(n)      # Read from receive buffer
conn.send_data(n)      # Read from send buffer
```

### TlsOpts

TLS/SSL configuration.

```python
opts = TlsOpts(
    ca=None,                    # CA certificate (PEM)
    cert=None,                  # Server/client certificate (PEM)
    key=None,                   # Private key (PEM)
    name=None,                  # Server name (SNI)
    skip_verification=False     # Skip cert validation (dev only!)
)
```

### HttpMessage

HTTP request/response view.

```python
msg.method          # "GET", "POST", etc.
msg.uri             # "/path"
msg.query           # "?key=value"
msg.proto           # "HTTP/1.1"
msg.body_text       # Body as string
msg.body_bytes      # Body as bytes
msg.header("Name")  # Get header value
msg.headers()       # All headers as list of tuples
msg.query_var("key") # Extract query parameter
msg.status()        # HTTP status code
msg.header_var(header, var) # Extract variable from header
```

### WsMessage

WebSocket frame data.

```python
ws.text    # Frame data as string
ws.data    # Frame data as bytes
ws.flags   # WebSocket flags
```

### MqttMessage

MQTT message data.

```python
mqtt.topic   # Topic as string
mqtt.data    # Payload as bytes
mqtt.id      # Message ID
mqtt.cmd     # MQTT command
mqtt.qos     # Quality of Service (0-2)
mqtt.ack     # Acknowledgment flag
```

### Event Constants

```python
# Core events
MG_EV_ERROR       # Error occurred
MG_EV_OPEN        # Connection created
MG_EV_POLL        # Poll iteration
MG_EV_RESOLVE     # DNS resolution complete
MG_EV_CONNECT     # Outbound connection established
MG_EV_ACCEPT      # Inbound connection accepted
MG_EV_TLS_HS      # TLS handshake complete
MG_EV_READ        # Data available to read
MG_EV_WRITE       # Data written
MG_EV_CLOSE       # Connection closed

# Protocol events
MG_EV_HTTP_MSG    # HTTP message received
MG_EV_WS_OPEN     # WebSocket handshake complete
MG_EV_WS_MSG      # WebSocket message received
MG_EV_MQTT_CMD    # MQTT command received
MG_EV_MQTT_MSG    # MQTT message received
MG_EV_MQTT_OPEN   # MQTT connection established
MG_EV_SNTP_TIME   # SNTP time received
MG_EV_WAKEUP      # Wakeup notification
```

### Utility Functions

```python
# JSON parsing
json_get(json_str, "$.path")           # Get JSON value
json_get_num(json_str, "$.number")     # Get as number
json_get_bool(json_str, "$.bool")      # Get as boolean
json_get_long(json_str, "$.int", default=0)  # Get as long
json_get_str(json_str, "$.string")     # Get as string

# URL encoding
url_encode(data)                       # Encode for URL

# Multipart forms
http_parse_multipart(body, offset=0)   # Parse multipart data
```

## Testing

The project includes a comprehensive test suite with **210 tests** (100% passing):

### Test Coverage by Feature

**Core Functionality (168 tests):**
- **HTTP/HTTPS**: Server, client, headers, query params, chunked encoding, SSE (40 tests)
- **WebSocket**: Handshake, text/binary frames, opcodes (10 tests)
- **MQTT**: Connect, publish, subscribe, ping/pong, disconnect (11 tests)
- **TLS/SSL**: Configuration, initialization, properties (12 tests)
- **Timers**: Single-shot, repeating, callbacks, cleanup (10 tests)
- **DNS**: Resolution, cancellation (4 tests)
- **SNTP**: Time requests, format validation (5 tests)
- **JSON**: Parsing, type conversion, nested access (9 tests)
- **Buffer Access**: Direct buffer inspection, flow control (10 tests)
- **Connection State**: Lifecycle, properties, events (15+ tests)
- **Security**: HTTP Basic Auth, TLS properties (6 tests)
- **Utilities**: URL encoding, multipart forms, wakeup (10 tests)
- **Flow Control**: Drain, backpressure (4 tests)

**Example Tests (42 tests):**
- Priority 1: HTTP/WebSocket examples (5 tests)
- Priority 2: MQTT examples (7 tests)
- Priority 3: Specialized HTTP examples (7 tests)
- Priority 4: Network protocols (8 tests)
- Priority 5: Advanced features (9 tests)
- README example validation (1 test)
- WebSocket broadcast examples (5 tests)

### Running Tests

```bash
make test                              # Run all tests (210 tests)
PYTHONPATH=src pytest tests/ -v        # Verbose output
pytest tests/test_http_server.py -v    # Run specific file
pytest tests/ -k "test_timer" -v       # Run matching tests
pytest tests/examples/ -v              # Run example tests only
```

### Test Infrastructure
- Dynamic port allocation prevents conflicts
- Background polling threads for async operations
- Proper cleanup in finally blocks
- 100% pass rate (210/210 tests passing)
- WebSocket tests require `websocket-client` (`uv add --dev websocket-client`)

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

### Performance Optimization

The wrapper achieves **C-level performance** through aggressive optimization:

**GIL Release (`nogil`):**
- **21 critical methods release GIL** for true parallel execution
- Network: `send()`, `close()`, `resolve()`, `resolve_cancel()`
- WebSocket: `ws_send()`, `ws_upgrade()`
- MQTT: `mqtt_pub()`, `mqtt_sub()`, `mqtt_ping()`, `mqtt_pong()`, `mqtt_disconnect()`
- HTTP: `reply()`, `serve_dir()`, `serve_file()`, `http_chunk()`, `http_sse()`
- TLS: `tls_init()`, `tls_free()`
- Utilities: `sntp_request()`, `http_basic_auth()`, `error()`
- Properties: `local_addr`, `remote_addr`
- Thread-safe: `Manager.wakeup()`

**TLS Compatibility:**
- TLS and `nogil` work together safely
- Mongoose's built-in TLS is event-loop based (no internal locks)
- Both optimizations enabled by default

**Benchmark Results** (Apple Silicon, `wrk -t4 -c100 -d10s`):
- **pymongoose**: 60,973 req/sec (1.67ms latency)
- aiohttp: 42,452 req/sec (1.44x slower)
- FastAPI/uvicorn: 9,989 req/sec (6.1x slower)
- Flask: 1,627 req/sec (37.5x slower)

See `docs/nogil_optimization_summary.md` and `benchmarks/RESULTS.md` for details.

## License

MIT

## Links

- [Mongoose Documentation](https://mongoose.ws/)
- [GitHub Repository](https://github.com/shakfu/pymongoose)
