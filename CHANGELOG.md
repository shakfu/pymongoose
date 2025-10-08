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


## [0.1.0] - Initial Release

### Added
- Cython bindings for Mongoose that provide `Manager`, `Connection`, `HttpMessage`, and `WsMessage` types.
- HTTP helpers for replies, static file serving, header lookup, and query parameter parsing.
- WebSocket utilities including frame wrappers and ws_send helper with opcode constants.
- Packaging metadata, Makefile build targets, and bundled mongoose sources for distribution.
