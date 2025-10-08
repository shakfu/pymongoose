# pymongoose Tests

This directory contains pytest-based tests for pymongoose.

## Running Tests

```bash
# Run all tests (HTTP only)
make test

# Or directly with pytest
pytest tests/ -v

# Run with WebSocket tests (requires websocket-client)
pip install websocket-client
pytest tests/ -v

# Run specific test file
pytest tests/test_http_server.py -v

# Run specific test
pytest tests/test_http_server.py::TestHTTPServer::test_basic_http_request -v
```

## Test Structure

- `test_http_server.py` - Tests for HTTP server functionality (15 tests)
  - Basic HTTP request/response
  - Multiple concurrent requests
  - HTTP headers and query strings
  - HttpMessage data structure
  - Connection lifecycle events
  - Manager lifecycle
  - Error handling

- `test_connection.py` - Tests for Connection object (6 tests)
  - Connection properties (userdata, is_listening)
  - Per-connection handlers
  - Reply methods with different body types
  - Custom headers

- `test_constants.py` - Tests for exported constants (4 tests)
  - Event constants (MG_EV_*)
  - WebSocket operation constants

- `test_websocket.py` - Tests for WebSocket functionality (11 tests) **[Requires websocket-client]**
  - WebSocket echo server (text and binary)
  - Multiple message handling
  - WebSocket handshake and upgrade
  - WsMessage data structure
  - WebSocket opcodes

## Test Coverage

**HTTP Tests (25 tests - All passing):**
- ✓ Basic HTTP server setup and teardown
- ✓ HTTP request/response handling
- ✓ Multiple sequential requests
- ✓ Different URL paths
- ✓ HTTP headers (reading and writing)
- ✓ Query string parsing
- ✓ Connection userdata
- ✓ Per-connection event handlers
- ✓ Custom response headers
- ✓ Different body types (string, bytes, UTF-8)
- ✓ Connection lifecycle events
- ✓ Manager creation and cleanup
- ✓ Error handling (invalid addresses, exceptions in handlers)
- ✓ Constant exports

**WebSocket Tests (10 tests - All passing with websocket-client):**
- ✓ WebSocket text message echo
- ✓ WebSocket binary message echo
- ✓ Multiple WebSocket messages
- ✓ WebSocket handshake events (MG_EV_WS_OPEN)
- ✓ HTTP to WebSocket upgrade lifecycle
- ✓ WsMessage properties (text, data, flags)
- ✓ WsMessage binary data handling
- ✓ WebSocket opcodes (TEXT, BINARY constants)
- ✓ ws_send with explicit text opcode

## Port Management

Tests use dynamic port allocation via `get_free_port()` to avoid port binding conflicts. The `ServerThread` context manager in `conftest.py` provides a convenient way to:
- Automatically allocate a free port
- Start a server in a background thread
- Clean up resources on exit

This ensures all tests can run concurrently without conflicts.

## Future Test Additions

Areas that could use additional test coverage:
- TCP/UDP sockets
- Static file serving
- TLS/SSL connections
- Connection error scenarios
- Memory leak tests
- Performance benchmarks
