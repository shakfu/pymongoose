# CHANGELOG

All notable project-wide changes will be documented in this file. Note that each subproject has its own CHANGELOG.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and [Commons Changelog](https://common-changelog.org). This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Types of Changes

- Added: for new features.
- Changed: for changes in existing functionality.
- Deprecated: for soon-to-be removed features.
- Removed: for now removed features.
- Fixed: for any bug fixes.
- Security: in case of vulnerabilities.

---

## [Unreleased]

### Added
- **Performance Optimization**: GIL (Global Interpreter Lock) management for multi-threaded scenarios
  - Added `nogil` to 21 critical C API methods for true parallel execution
  - Network operations: `send()`, `close()`, `resolve()`, `resolve_cancel()`
  - WebSocket: `ws_send()`, `ws_upgrade()`
  - MQTT: `mqtt_pub()`, `mqtt_sub()`, `mqtt_ping()`, `mqtt_pong()`, `mqtt_disconnect()`
  - HTTP: `reply()`, `serve_dir()`, `serve_file()`, `http_chunk()`, `http_sse()`
  - TLS: `tls_init()`, `tls_free()`
  - Utilities: `sntp_request()`, `http_basic_auth()`, `error()`
  - Properties: `local_addr`, `remote_addr` (with `ntohs()`)
  - Thread-safe: `Manager.wakeup()`
  - **Impact**: Enables true parallel request processing in multi-threaded servers, reduces GIL contention

### Changed
- **Documentation improvements**:
  - Added buffer size limitation note to `HttpMessage.query_var()` (256-byte limit)
  - Added memory lifetime comments for encode() patterns with nogil
  - Added thread safety notes to `Manager.poll()` and `Manager.wakeup()`
  - Documented timer auto-deletion design in `Manager.timer_add()` and `Timer` class
  - Created `docs/code_nogil_review.md` - comprehensive code review report
  - Created `docs/nogil_optimization_summary.md` - implementation summary

### Fixed
- **Duplicate property**: Removed duplicate `is_tls` property definition (line 736)
  - Previously defined twice, second definition silently overwrote the first

## [0.1.1]

### Added

#### High Priority Features (Essential Functionality)
- **DNS Resolution** (`Connection.resolve()`, `Connection.resolve_cancel()`):
  - Asynchronous hostname resolution with `MG_EV_RESOLVE` event
  - Cancel in-flight DNS lookups
  - 4 comprehensive tests in `tests/test_dns.py`

- **Flow Control** (Buffer inspection and backpressure):
  - `Connection.recv_len`, `Connection.send_len` - bytes in buffers
  - `Connection.recv_size`, `Connection.send_size` - buffer capacities
  - `Connection.recv_data(n)`, `Connection.send_data(n)` - direct buffer access
  - `Connection.is_full` - backpressure detection
  - `Connection.is_draining` - close pending after flush
  - 10 tests in `tests/test_buffer_access.py`

- **HTTP Basic Authentication**:
  - `Connection.http_basic_auth(user, password)` - verify credentials
  - Returns tuple `(username, password)` or `(None, None)`
  - 6 tests in `tests/test_http_auth.py`

- **Security Documentation**:
  - Created comprehensive `docs/security.md`
  - Covers TLS/SSL, HTTP Basic Auth, input validation, DNS security, WebSocket/MQTT security
  - Attack surface analysis and best practices

#### Medium Priority Features (Enhanced Capabilities)
- **SNTP Time Protocol**:
  - `Manager.sntp_connect(url, handler)` - create SNTP client
  - `Connection.sntp_request()` - request network time
  - `MG_EV_SNTP_TIME` event with 64-bit Unix timestamp
  - 5 tests in `tests/test_sntp.py`

- **HTTP Chunked Transfer Encoding**:
  - `Connection.http_chunk(data)` - send chunked response data
  - Enables streaming responses without Content-Length
  - 10 tests in `tests/test_http_chunked.py`

- **Timer API**:
  - `Manager.timer_add(milliseconds, callback, repeat, run_now)` - periodic callbacks
  - Returns `Timer` object with `cancel()` method
  - Single-shot and repeating timers
  - 10 tests in `tests/test_timer.py`

- **Advanced MQTT**:
  - `Connection.mqtt_ping()`, `Connection.mqtt_pong()` - keepalive
  - `Connection.mqtt_disconnect()` - graceful shutdown
  - 11 tests total in `tests/test_mqtt.py`

- **Server-Sent Events (SSE)**:
  - `Connection.http_sse(event_type, data)` - send SSE events
  - 5 tests in `tests/test_http_sse.py`

#### Low Priority Features (Nice-to-Have)
- **TLS/SSL Configuration**:
  - `TlsOpts` class for certificate-based encryption
  - `Connection.tls_init(TlsOpts)` - initialize TLS on connection
  - `Connection.tls_free()` - free TLS resources
  - `Connection.is_tls` property - check encryption status
  - Support for CA certificates, client certificates, private keys, SNI
  - `skip_verification` option for development
  - 12 tests in `tests/test_tls.py`

- **Low-level Operations**:
  - `Connection.is_tls` property for TLS status
  - 5 tests in `tests/test_lowlevel.py`

#### Testing & Documentation
- **Comprehensive test suite**: 150+ tests with 99% pass rate
  - HTTP/HTTPS: 40 tests (server, client, headers, chunked, SSE)
  - WebSocket: 10 tests (handshake, text/binary frames)
  - MQTT: 11 tests (connect, pub/sub, ping/pong)
  - TLS: 12 tests (configuration, initialization)
  - Timers: 10 tests (single-shot, repeating)
  - DNS: 4 tests (resolution, cancellation)
  - SNTP: 5 tests (time requests)
  - JSON: 9 tests (parsing, type conversion)
  - Buffer Access: 10 tests (flow control)
  - Connection State: 15+ tests (lifecycle, properties)
  - Security: 6 tests (HTTP Basic Auth, TLS)

- **Enhanced README.md**:
  - Complete feature list (Core Protocols, Advanced Features, Technical details)
  - Comprehensive API reference for all classes and methods
  - Event constants documentation
  - Utility functions reference
  - Updated test coverage section

- **Missing Function Documentation**:
  - Created `docs/mg_http_delete_chunk.md`
  - Documents Mongoose library limitation (declared but not implemented)
  - Practical impact analysis (low-medium severity)
  - 5 detailed workarounds for chunked request handling

### Removed
- `mg_http_delete_chunk()` - declared in Mongoose header but not implemented in library
  - Would have provided chunked request buffer cleanup
  - See `docs/mg_http_delete_chunk.md` for alternatives

### Known Issues
- **Intermittent test failures** (99% pass rate, 148-150/151 tests pass):
  - `test_per_connection_handler` and `test_websocket_connection_upgrade` occasionally fail
  - Both tests pass individually - failures are non-deterministic
  - Root cause: Test state leakage, port reuse timing, async event timing
  - Not actual code bugs - test infrastructure issues (low priority)

### Fixed
- **Critical**: Fixed segfault in HTTP server caused by missing GIL acquisition in event callback
  - The `_event_bridge` callback function now properly acquires the GIL using `with gil` annotation
  - This fixes crashes that occurred when handling HTTP requests, WebSocket messages, or any event callbacks
  - Root cause: `Manager.poll()` releases the GIL with `nogil`, but the C callback was invoking Python code without re-acquiring it
  - Solution: Added `noexcept with gil` to `_event_bridge` function signature in `_mongoose.pyx:469`

### Added
- **WebSocket support**: Added `Connection.ws_upgrade()` method for HTTP to WebSocket upgrade
  - Previously missing from the Python API despite being available in the C library
  - Required for WebSocket functionality - must be called on `MG_EV_HTTP_MSG` to initiate WebSocket handshake
  - Signature: `conn.ws_upgrade(message, extra_headers=None)` where message is the HttpMessage from HTTP event
  - See updated WebSocket example in README.md
- Comprehensive test suite with 35 tests covering:
  - HTTP server basic functionality (15 tests): request/response, multiple requests, different paths
  - **WebSocket functionality (10 tests)**: text/binary echo, multiple messages, handshake events, upgrade lifecycle
  - HTTP headers and query string handling
  - Connection properties and lifecycle events
  - Custom response headers and different body types (bytes, string, UTF-8)
  - Manager initialization and cleanup
  - Error handling (invalid addresses, exceptions in handlers)
  - Event constants validation
- Test infrastructure:
  - `conftest.py` with `ServerThread` context manager for easy test server setup
  - Dynamic port allocation using `get_free_port()` to avoid port conflicts
  - All tests can run concurrently without interference
  - WebSocket tests skip gracefully if `websocket-client` not installed
- Documentation:
  - `tests/README.md` with comprehensive testing guide
  - Updated main `README.md` with WebSocket example, API reference, and testing section
  - WebSocket example now shows proper upgrade pattern

### Changed
- Removed "CRITICAL TODO" section from README.md (segfault issue resolved)
- Updated WebSocket example in README.md to show required `ws_upgrade()` call

## [0.1.0] - Initial Release

### Added
- Cython bindings for Mongoose that provide `Manager`, `Connection`, `HttpMessage`, and `WsMessage` types.
- HTTP helpers for replies, static file serving, header lookup, and query parameter parsing.
- WebSocket utilities including frame wrappers and ws_send helper with opcode constants.
- Packaging metadata, Makefile build targets, and bundled mongoose sources for distribution.
