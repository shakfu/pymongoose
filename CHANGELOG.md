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
