# cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True
# distutils: language = c
"""
Cython bindings that expose a Python-friendly interface to the Mongoose
embedded networking library.
"""

from cpython.ref cimport PyObject, Py_INCREF, Py_DECREF
from cpython.bytes cimport PyBytes_FromStringAndSize
from cpython.unicode cimport PyUnicode_DecodeUTF8
from libc.stdint cimport uintptr_t, uint16_t
from libc.string cimport memset
from libc.stddef cimport size_t
from libc.stdlib cimport free
from cython cimport sizeof

cdef extern from *:
    """
    #ifdef __APPLE__
    #include <machine/endian.h>
    #include <libkern/OSByteOrder.h>
    #define ntohs(x) OSSwapBigToHostInt16(x)
    #else
    #include <arpa/inet.h>
    #endif
    """
    uint16_t ntohs(uint16_t netshort) nogil

from .mongoose cimport (
    MG_EV_ERROR as C_MG_EV_ERROR,
    MG_EV_OPEN as C_MG_EV_OPEN,
    MG_EV_POLL as C_MG_EV_POLL,
    MG_EV_RESOLVE as C_MG_EV_RESOLVE,
    MG_EV_CONNECT as C_MG_EV_CONNECT,
    MG_EV_ACCEPT as C_MG_EV_ACCEPT,
    MG_EV_TLS_HS as C_MG_EV_TLS_HS,
    MG_EV_READ as C_MG_EV_READ,
    MG_EV_WRITE as C_MG_EV_WRITE,
    MG_EV_CLOSE as C_MG_EV_CLOSE,
    MG_EV_HTTP_HDRS as C_MG_EV_HTTP_HDRS,
    MG_EV_HTTP_MSG as C_MG_EV_HTTP_MSG,
    MG_EV_WS_OPEN as C_MG_EV_WS_OPEN,
    MG_EV_WS_MSG as C_MG_EV_WS_MSG,
    MG_EV_WS_CTL as C_MG_EV_WS_CTL,
    MG_EV_WAKEUP as C_MG_EV_WAKEUP,
    MG_EV_USER as C_MG_EV_USER,
    mg_addr,
    mg_connection,
    mg_event_handler_t,
    mg_http_header,
    mg_http_listen,
    mg_http_message,
    mg_http_connect,
    mg_http_reply,
    mg_http_serve_dir,
    mg_http_serve_file,
    mg_http_serve_opts,
    mg_http_get_header,
    mg_http_get_var,
    mg_http_parse,
    mg_http_get_request_len,
    mg_http_printf_chunk,
    mg_http_write_chunk,
    mg_http_delete_chunk,
    mg_http_upload,
    mg_json_get,
    mg_json_get_tok,
    mg_json_get_num,
    mg_json_get_bool,
    mg_json_get_long,
    mg_json_get_str,
    mg_json_get_hex,
    mg_json_get_b64,
    mg_json_unescape,
    mg_json_next,
    mg_mgr,
    mg_mgr_init,
    mg_mgr_poll,
    mg_mgr_free,
    mg_listen,
    mg_connect,
    mg_send,
    mg_printf,
    mg_close_conn,
    mg_str,
    mg_str_n,
    mg_ws_message,
    mg_ws_send,
    mg_ws_printf,
    mg_ws_upgrade,
    mg_tls_opts,
    mg_tls_init,
    mg_tls_free,
    mg_wakeup,
    mg_wakeup_init,
    WEBSOCKET_OP_TEXT as C_WEBSOCKET_OP_TEXT,
    WEBSOCKET_OP_BINARY as C_WEBSOCKET_OP_BINARY,
    WEBSOCKET_OP_PING as C_WEBSOCKET_OP_PING,
    WEBSOCKET_OP_PONG as C_WEBSOCKET_OP_PONG,
)

import traceback

__all__ = [
    "Manager",
    "Connection",
    "HttpMessage",
    "WsMessage",
    "MG_EV_ERROR",
    "MG_EV_OPEN",
    "MG_EV_POLL",
    "MG_EV_RESOLVE",
    "MG_EV_CONNECT",
    "MG_EV_ACCEPT",
    "MG_EV_TLS_HS",
    "MG_EV_READ",
    "MG_EV_WRITE",
    "MG_EV_CLOSE",
    "MG_EV_HTTP_HDRS",
    "MG_EV_HTTP_MSG",
    "MG_EV_WS_OPEN",
    "MG_EV_WS_MSG",
    "MG_EV_WS_CTL",
    "MG_EV_WAKEUP",
    "MG_EV_USER",
    "WEBSOCKET_OP_TEXT",
    "WEBSOCKET_OP_BINARY",
    "WEBSOCKET_OP_PING",
    "WEBSOCKET_OP_PONG",
    "json_get",
    "json_get_num",
    "json_get_bool",
    "json_get_long",
    "json_get_str",
]

MG_EV_ERROR = C_MG_EV_ERROR
MG_EV_OPEN = C_MG_EV_OPEN
MG_EV_POLL = C_MG_EV_POLL
MG_EV_RESOLVE = C_MG_EV_RESOLVE
MG_EV_CONNECT = C_MG_EV_CONNECT
MG_EV_ACCEPT = C_MG_EV_ACCEPT
MG_EV_TLS_HS = C_MG_EV_TLS_HS
MG_EV_READ = C_MG_EV_READ
MG_EV_WRITE = C_MG_EV_WRITE
MG_EV_CLOSE = C_MG_EV_CLOSE
MG_EV_HTTP_HDRS = C_MG_EV_HTTP_HDRS
MG_EV_HTTP_MSG = C_MG_EV_HTTP_MSG
MG_EV_WS_OPEN = C_MG_EV_WS_OPEN
MG_EV_WS_MSG = C_MG_EV_WS_MSG
MG_EV_WS_CTL = C_MG_EV_WS_CTL
MG_EV_WAKEUP = C_MG_EV_WAKEUP
MG_EV_USER = C_MG_EV_USER

WEBSOCKET_OP_TEXT = C_WEBSOCKET_OP_TEXT
WEBSOCKET_OP_BINARY = C_WEBSOCKET_OP_BINARY
WEBSOCKET_OP_PING = C_WEBSOCKET_OP_PING
WEBSOCKET_OP_PONG = C_WEBSOCKET_OP_PONG


cdef inline bytes _mg_str_to_bytes(mg_str value):
    """Return a bytes copy of an mg_str."""
    if value.buf == NULL or value.len == 0:
        return b""
    return PyBytes_FromStringAndSize(value.buf, value.len)


cdef inline str _mg_str_to_text(mg_str value):
    """Return a Unicode string, decoding with UTF-8 and surrogate escape."""
    if value.buf == NULL or value.len == 0:
        return ""
    return PyUnicode_DecodeUTF8(value.buf, value.len, "surrogateescape")


cdef class HttpMessage:
    """Lightweight view over a struct mg_http_message."""

    cdef mg_http_message *_msg

    cdef void _assign(self, mg_http_message *msg):
        self._msg = msg

    def __bool__(self):
        return self._msg != NULL

    property method:
        def __get__(self):
            return _mg_str_to_text(self._msg.method) if self._msg != NULL else ""

    property uri:
        def __get__(self):
            return _mg_str_to_text(self._msg.uri) if self._msg != NULL else ""

    property query:
        def __get__(self):
            return _mg_str_to_text(self._msg.query) if self._msg != NULL else ""

    property proto:
        def __get__(self):
            return _mg_str_to_text(self._msg.proto) if self._msg != NULL else ""

    property body_bytes:
        def __get__(self):
            return _mg_str_to_bytes(self._msg.body) if self._msg != NULL else b""

    property body_text:
        def __get__(self):
            return _mg_str_to_text(self._msg.body) if self._msg != NULL else ""

    def header(self, name: str, default=None):
        """Return a HTTP header value or default when not present."""
        if self._msg == NULL:
            return default
        cdef bytes lookup = name.encode("utf-8")
        cdef mg_str *result = mg_http_get_header(self._msg, lookup)
        if result == NULL:
            return default
        return _mg_str_to_text(result[0])

    def headers(self):
        """Return all HTTP headers as a list of (name, value) tuples."""
        if self._msg == NULL:
            return []
        cdef mg_http_header header
        cdef size_t idx
        result = []
        for idx in range(30):
            header = self._msg.headers[idx]
            if header.name.len == 0:
                break
            result.append((_mg_str_to_text(header.name), _mg_str_to_text(header.value)))
        return result

    def query_var(self, name: str):
        """Extract a query string parameter."""
        if self._msg == NULL:
            return None
        cdef bytes name_b = name.encode("utf-8")
        cdef char buffer[256]
        cdef int rc = mg_http_get_var(&self._msg.query, name_b, buffer, sizeof(buffer))
        if rc <= 0:
            return None
        return buffer[:rc].decode("utf-8", "surrogateescape")


cdef class WsMessage:
    """View over an incoming WebSocket frame."""

    cdef mg_ws_message *_msg

    cdef void _assign(self, mg_ws_message *msg):
        self._msg = msg

    property data:
        def __get__(self):
            return _mg_str_to_bytes(self._msg.data) if self._msg != NULL else b""

    property text:
        def __get__(self):
            return _mg_str_to_text(self._msg.data) if self._msg != NULL else ""

    property flags:
        def __get__(self):
            return self._msg.flags if self._msg != NULL else 0


cdef class Connection:
    """Wrapper around mg_connection pointers."""

    cdef mg_connection *_conn
    cdef Manager _manager
    cdef object _handler
    cdef object _userdata

    def __cinit__(self):
        self._conn = NULL
        self._manager = None
        self._handler = None
        self._userdata = None

    cdef void _bind(self, Manager manager, mg_connection *conn, object handler):
        self._manager = manager
        self._conn = conn
        self._handler = handler

    cdef mg_connection *_ptr(self):
        if self._conn == NULL:
            raise RuntimeError("Connection has been closed")
        return self._conn

    @property
    def handler(self):
        return self._handler

    def set_handler(self, handler):
        """Assign a per-connection event handler."""
        self._handler = handler

    @property
    def userdata(self):
        return self._userdata

    @userdata.setter
    def userdata(self, value):
        self._userdata = value

    @property
    def id(self):
        """Return connection ID."""
        return self._conn.id if self._conn != NULL else 0

    @property
    def is_listening(self):
        return self._conn.is_listening != 0 if self._conn != NULL else False

    @property
    def is_closing(self):
        return self._conn.is_closing != 0 if self._conn != NULL else True

    @property
    def local_addr(self):
        """Return local address as (ip, port, is_ipv6) tuple."""
        if self._conn == NULL:
            return None
        cdef mg_addr addr = self._conn.loc
        cdef bytes ip_bytes = bytes(addr.ip[:16])
        cdef uint16_t host_port = ntohs(addr.port)
        if addr.is_ip6:
            # IPv6 address formatting
            parts = []
            for i in range(8):
                parts.append(f"{addr.ip[i*2]:02x}{addr.ip[i*2+1]:02x}")
            ip_str = ":".join(parts)
        else:
            # IPv4 address
            ip_str = f"{addr.ip[0]}.{addr.ip[1]}.{addr.ip[2]}.{addr.ip[3]}"
        return (ip_str, host_port, bool(addr.is_ip6))

    @property
    def remote_addr(self):
        """Return remote address as (ip, port, is_ipv6) tuple."""
        if self._conn == NULL:
            return None
        cdef mg_addr addr = self._conn.rem
        cdef bytes ip_bytes = bytes(addr.ip[:16])
        cdef uint16_t host_port = ntohs(addr.port)
        if addr.is_ip6:
            # IPv6 address formatting
            parts = []
            for i in range(8):
                parts.append(f"{addr.ip[i*2]:02x}{addr.ip[i*2+1]:02x}")
            ip_str = ":".join(parts)
        else:
            # IPv4 address
            ip_str = f"{addr.ip[0]}.{addr.ip[1]}.{addr.ip[2]}.{addr.ip[3]}"
        return (ip_str, host_port, bool(addr.is_ip6))

    def send(self, data):
        """Send raw bytes to the peer."""
        cdef bytes payload
        if isinstance(data, str):
            payload = (<str>data).encode("utf-8")
        else:
            payload = bytes(data)
        cdef const char *buf = payload
        cdef size_t length = len(payload)
        if not mg_send(self._ptr(), buf, length):
            raise RuntimeError("mg_send failed")

    def reply(self, int status_code, body=b"", headers=None):
        """Send a HTTP reply (final response)."""
        if isinstance(body, str):
            body_bytes = body.encode("utf-8")
        else:
            body_bytes = bytes(body)
        if headers is None:
            header_lines = ["Content-Type: text/plain\r\n"]
        else:
            header_lines = [f"{k}: {v}\r\n" for k, v in headers.items()]
        headers_bytes = "".join(header_lines).encode("utf-8")
        cdef bytes headers_b = headers_bytes
        cdef bytes body_b = body_bytes
        cdef const char *headers_c = headers_b if headers_b else b""
        cdef const char *body_fmt_c = b"%s"
        cdef const char *body_c = body_b
        mg_http_reply(self._ptr(), status_code, headers_c, body_fmt_c, body_c)

    def serve_dir(self, HttpMessage message, root_dir: str, extra_headers: str = "", mime_types: str = "", page404: str = ""):
        """Serve files from a directory using Mongoose's built-in static handler."""
        if message._msg == NULL:
            raise ValueError("HttpMessage is not valid for this event")
        cdef mg_http_serve_opts opts
        memset(&opts, 0, sizeof(mg_http_serve_opts))
        cdef bytes root_b = root_dir.encode("utf-8")
        opts.root_dir = root_b
        extra_headers_b = None
        mime_types_b = None
        page404_b = None
        if extra_headers:
            extra_headers_b = extra_headers.encode("utf-8")
            opts.extra_headers = extra_headers_b
        if mime_types:
            mime_types_b = mime_types.encode("utf-8")
            opts.mime_types = mime_types_b
        if page404:
            page404_b = page404.encode("utf-8")
            opts.page404 = page404_b
        mg_http_serve_dir(self._ptr(), message._msg, &opts)

    def serve_file(self, HttpMessage message, path: str, extra_headers: str = "", mime_types: str = ""):
        """Serve a single file using Mongoose's built-in static handler."""
        if message._msg == NULL:
            raise ValueError("HttpMessage is not valid for this event")
        cdef mg_http_serve_opts opts
        memset(&opts, 0, sizeof(mg_http_serve_opts))
        cdef bytes path_b = path.encode("utf-8")
        extra_headers_b = None
        mime_types_b = None
        if extra_headers:
            extra_headers_b = extra_headers.encode("utf-8")
            opts.extra_headers = extra_headers_b
        if mime_types:
            mime_types_b = mime_types.encode("utf-8")
            opts.mime_types = mime_types_b
        mg_http_serve_file(self._ptr(), message._msg, path_b, &opts)

    def ws_upgrade(self, HttpMessage message, extra_headers=None):
        """Upgrade HTTP connection to WebSocket.

        Args:
            message: The HttpMessage from MG_EV_HTTP_MSG event
            extra_headers: Optional dict of extra headers to send in upgrade response
        """
        if message._msg == NULL:
            raise ValueError("HttpMessage is not valid for this event")

        cdef const char *fmt = NULL
        if extra_headers:
            headers_str = "\r\n".join(f"{k}: {v}" for k, v in extra_headers.items())
            headers_bytes = headers_str.encode("utf-8")
            fmt = headers_bytes

        mg_ws_upgrade(self._ptr(), message._msg, fmt)

    def ws_send(self, data, op=WEBSOCKET_OP_TEXT):
        """Send a WebSocket frame."""
        if isinstance(data, str):
            payload = data.encode("utf-8")
        else:
            payload = bytes(data)
        cdef bytes payload_b = payload
        cdef const char *buf = payload_b
        mg_ws_send(self._ptr(), buf, len(payload_b), op)

    def close(self):
        """Schedule closing of the connection."""
        if self._conn != NULL:
            mg_close_conn(self._conn)

    def __repr__(self):
        if self._conn == NULL:
            return "<Connection closed>"
        return f"<Connection id={self._conn.id} readable={bool(self._conn.is_readable)} writable={bool(self._conn.is_writable)}>"


cdef class Manager:
    """Manage Mongoose event loop and provide Python callbacks."""

    cdef mg_mgr _mgr
    cdef object _default_handler
    cdef dict _connections
    cdef PyObject *_self_ref
    cdef bint _freed

    def __cinit__(self, handler=None, enable_wakeup=False):
        self._default_handler = handler
        self._connections = {}
        self._self_ref = <PyObject*> self
        Py_INCREF(<object>self._self_ref)
        mg_mgr_init(&self._mgr)
        self._mgr.userdata = <void*> self
        self._freed = False
        if enable_wakeup:
            if not mg_wakeup_init(&self._mgr):
                raise RuntimeError("Failed to initialize wakeup support")

    def __dealloc__(self):
        if not self._freed:
            mg_mgr_free(&self._mgr)
            self._freed = True
        self._mgr.userdata = NULL
        if self._self_ref != NULL:
            Py_DECREF(<object>self._self_ref)
            self._self_ref = NULL

    cdef Connection _ensure_connection(self, mg_connection *conn):
        cdef uintptr_t key = <uintptr_t> conn
        cdef Connection py_conn
        py_conn = self._connections.get(key, None)
        if py_conn is None:
            py_conn = Connection.__new__(Connection)
            py_conn._bind(self, conn, None)
            self._connections[key] = py_conn
        elif py_conn._conn == NULL:
            py_conn._conn = conn
        return py_conn

    cdef void _drop_connection(self, mg_connection *conn):
        cdef uintptr_t key = <uintptr_t> conn
        cdef Connection py_conn
        py_conn = self._connections.pop(key, None)
        if py_conn is not None:
            py_conn._conn = <mg_connection*>NULL

    cdef object _resolve_handler(self, Connection conn):
        if conn._handler is not None:
            return conn._handler
        return self._default_handler

    cdef object _wrap_event_data(self, int ev, void *ev_data):
        cdef HttpMessage view
        cdef WsMessage ws
        cdef mg_str *wakeup_data
        if ev == MG_EV_HTTP_MSG or ev == MG_EV_HTTP_HDRS or ev == MG_EV_WS_OPEN:
            if ev_data != NULL:
                view = HttpMessage.__new__(HttpMessage)
                view._assign(<mg_http_message*> ev_data)
                return view
            return None
        elif ev == MG_EV_WS_MSG:
            if ev_data != NULL:
                ws = WsMessage.__new__(WsMessage)
                ws._assign(<mg_ws_message*> ev_data)
                return ws
            return None
        elif ev == MG_EV_ERROR and ev_data != NULL:
            return (<char*> ev_data).decode("utf-8", "ignore")
        elif ev == MG_EV_WAKEUP and ev_data != NULL:
            wakeup_data = <mg_str*> ev_data
            return _mg_str_to_bytes(wakeup_data[0])
        return None

    def poll(self, int timeout_ms=0):
        """Drive the event loop once."""
        if self._freed:
            raise RuntimeError("Manager has been freed")
        with nogil:
            mg_mgr_poll(&self._mgr, timeout_ms)

    def listen(self, url: str, handler=None, *, http=False):
        """Listen on a URL; handler is optional per-listener override."""
        cdef bytes url_b = url.encode("utf-8")
        cdef mg_connection *conn
        if http:
            conn = mg_http_listen(&self._mgr, url_b, _event_bridge, NULL)
        else:
            conn = mg_listen(&self._mgr, url_b, _event_bridge, NULL)
        if conn == NULL:
            raise RuntimeError(f"Failed to listen on '{url}'")
        py_conn = self._ensure_connection(conn)
        py_conn._handler = handler
        return py_conn

    def connect(self, url: str, handler=None, *, http=False):
        """Create an outbound connection and return immediately."""
        cdef bytes url_b = url.encode("utf-8")
        cdef mg_connection *conn
        if http:
            conn = mg_http_connect(&self._mgr, url_b, _event_bridge, NULL)
        else:
            conn = mg_connect(&self._mgr, url_b, _event_bridge, NULL)
        if conn == NULL:
            raise RuntimeError(f"Failed to connect to '{url}'")
        py_conn = self._ensure_connection(conn)
        py_conn._handler = handler
        return py_conn

    def wakeup(self, connection_id: int, data: bytes = b""):
        """Send a wakeup notification to a specific connection (thread-safe).

        Args:
            connection_id: The connection ID to wake up
            data: Optional data payload (delivered via MG_EV_WAKEUP event)

        Returns:
            True if wakeup was sent successfully
        """
        if self._freed:
            raise RuntimeError("Manager has been freed")
        cdef bytes data_b = data
        cdef const void *buf = <const void*><char*>data_b if len(data_b) > 0 else NULL
        cdef size_t len_data = len(data_b)
        return mg_wakeup(&self._mgr, <unsigned long>connection_id, buf, len_data)

    def close(self):
        """Free the underlying manager and release resources."""
        if not self._freed:
            mg_mgr_free(&self._mgr)
            self._freed = True
            self._connections.clear()
            self._mgr.userdata = NULL


cdef void _event_bridge(mg_connection *conn, int ev, void *ev_data) noexcept with gil:
    """Global callback that routes events back into Python."""
    cdef Manager manager
    cdef PyObject *manager_obj = NULL
    cdef Connection py_conn
    if conn.mgr == NULL:
        return
    manager_obj = <PyObject*> conn.mgr.userdata
    if manager_obj == NULL:
        return
    manager = <Manager> manager_obj
    py_conn = manager._ensure_connection(conn)
    handler = manager._resolve_handler(py_conn)
    payload = manager._wrap_event_data(ev, ev_data)
    if handler is None:
        return
    try:
        handler(py_conn, ev, payload)
    except Exception:
        traceback.print_exc()
    if ev == MG_EV_CLOSE:
        manager._drop_connection(conn)


# JSON utilities
def json_get(data, path: str):
    """Extract a value from JSON by path (e.g., '$.user.name').

    Args:
        data: JSON string or bytes
        path: JSON path (e.g., '$.items[0].id')

    Returns:
        String value at path, or None if not found
    """
    cdef bytes json_b
    if isinstance(data, str):
        json_b = data.encode("utf-8")
    else:
        json_b = bytes(data)
    cdef bytes path_b = path.encode("utf-8")
    cdef mg_str json_str = mg_str_n(json_b, len(json_b))
    cdef mg_str result = mg_json_get_tok(json_str, path_b)
    if result.buf == NULL:
        return None
    return _mg_str_to_text(result)


def json_get_num(data, path: str, default=None):
    """Extract a numeric value from JSON by path.

    Args:
        data: JSON string or bytes
        path: JSON path (e.g., '$.count')
        default: Default value if not found or not a number

    Returns:
        Float value at path, or default if not found
    """
    cdef bytes json_b
    if isinstance(data, str):
        json_b = data.encode("utf-8")
    else:
        json_b = bytes(data)
    cdef bytes path_b = path.encode("utf-8")
    cdef mg_str json_str = mg_str_n(json_b, len(json_b))
    cdef double value
    if mg_json_get_num(json_str, path_b, &value):
        return value
    return default


def json_get_bool(data, path: str, default=None):
    """Extract a boolean value from JSON by path.

    Args:
        data: JSON string or bytes
        path: JSON path (e.g., '$.enabled')
        default: Default value if not found or not a boolean

    Returns:
        Boolean value at path, or default if not found
    """
    cdef bytes json_b
    if isinstance(data, str):
        json_b = data.encode("utf-8")
    else:
        json_b = bytes(data)
    cdef bytes path_b = path.encode("utf-8")
    cdef mg_str json_str = mg_str_n(json_b, len(json_b))
    cdef bint value = 0
    if mg_json_get_bool(json_str, path_b, &value):
        # mg_json_get_bool returns true on success, value contains the actual boolean
        return value != 0
    return default


def json_get_long(data, path: str, default=0):
    """Extract an integer value from JSON by path.

    Args:
        data: JSON string or bytes
        path: JSON path (e.g., '$.id')
        default: Default value if not found or not an integer

    Returns:
        Integer value at path, or default if not found
    """
    cdef bytes json_b
    if isinstance(data, str):
        json_b = data.encode("utf-8")
    else:
        json_b = bytes(data)
    cdef bytes path_b = path.encode("utf-8")
    cdef mg_str json_str = mg_str_n(json_b, len(json_b))
    return mg_json_get_long(json_str, path_b, default)


def json_get_str(data, path: str):
    """Extract a string value from JSON by path (automatically unescapes).

    Args:
        data: JSON string or bytes
        path: JSON path (e.g., '$.message')

    Returns:
        Unescaped string value at path, or None if not found
    """
    cdef bytes json_b
    if isinstance(data, str):
        json_b = data.encode("utf-8")
    else:
        json_b = bytes(data)
    cdef bytes path_b = path.encode("utf-8")
    cdef mg_str json_str = mg_str_n(json_b, len(json_b))
    cdef char *result = mg_json_get_str(json_str, path_b)
    if result == NULL:
        return None
    try:
        return result.decode("utf-8", "surrogateescape")
    finally:
        free(result)
