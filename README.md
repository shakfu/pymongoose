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
- **Comprehensive**: 150+ tests with 99% pass rate
- **GIL-optimized**: True parallel execution in multi-threaded scenarios (21 methods with `nogil`)

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

# Low-level
conn.error(message)                # Trigger error event
conn.close()                       # Close connection

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

The project includes a comprehensive test suite with **150+ tests** covering:

### Test Coverage by Feature
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

### Running Tests

```bash
make test                              # Run all tests
PYTHONPATH=src pytest tests/ -v        # Verbose output
pytest tests/test_http_server.py -v    # Run specific file
pytest tests/ -k "test_timer" -v       # Run matching tests
```

### Test Infrastructure
- Dynamic port allocation prevents conflicts
- Background polling threads for async operations
- Proper cleanup in finally blocks
- 99% pass rate with minimal intermittent failures
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

The wrapper is optimized for multi-threaded scenarios:
- **21 methods with `nogil`**: Network I/O, WebSocket, MQTT, HTTP, and TLS operations release the GIL
- **True parallel execution**: Multiple threads can process requests concurrently
- **Zero GIL contention**: C operations run without blocking Python threads
- **Thread-safe wakeup**: Cross-thread communication via `Manager.wakeup()`

See `docs/nogil_optimization_summary.md` for implementation details.

## License

MIT

## Links

- [Mongoose Documentation](https://mongoose.ws/)
- [GitHub Repository](https://github.com/shakfu/pymongoose)
