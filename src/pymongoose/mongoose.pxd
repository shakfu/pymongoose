from libc.stdint cimport uintptr_t, int64_t, uint64_t, uint32_t, uint16_t, uint8_t, int8_t
from libc.stddef cimport size_t
from libc.stdio cimport FILE

cdef extern from "mongoose.h":
    ctypedef void (*mg_event_handler_t)(mg_connection *, int ev, void *ev_data)

    cdef enum:
        MG_MAX_HTTP_HEADERS = 30

    cdef enum:
        MG_EV_ERROR
        MG_EV_OPEN
        MG_EV_POLL
        MG_EV_RESOLVE
        MG_EV_CONNECT
        MG_EV_ACCEPT
        MG_EV_TLS_HS
        MG_EV_READ
        MG_EV_WRITE
        MG_EV_CLOSE
        MG_EV_HTTP_HDRS
        MG_EV_HTTP_MSG
        MG_EV_WS_OPEN
        MG_EV_WS_MSG
        MG_EV_WS_CTL
        MG_EV_MQTT_CMD
        MG_EV_MQTT_MSG
        MG_EV_MQTT_OPEN
        MG_EV_SNTP_TIME
        MG_EV_WAKEUP
        MG_EV_USER

    cdef enum:
        WEBSOCKET_OP_CONTINUE = 0
        WEBSOCKET_OP_TEXT = 1
        WEBSOCKET_OP_BINARY = 2
        WEBSOCKET_OP_CLOSE = 8
        WEBSOCKET_OP_PING = 9
        WEBSOCKET_OP_PONG = 10

    cdef struct mg_str:
        char *buf
        size_t len

    cdef struct mg_addr:
        uint8_t ip[16]
        uint16_t port
        uint8_t scope_id
        bint is_ip6

    cdef struct mg_iobuf:
        unsigned char *buf
        size_t size
        size_t len
        size_t align

    cdef struct mg_connection:
        mg_connection *next
        mg_mgr *mgr
        mg_addr loc
        mg_addr rem
        void *fd
        unsigned long id
        mg_iobuf recv
        mg_iobuf send
        mg_iobuf prof
        mg_iobuf rtls
        mg_event_handler_t fn
        void *fn_data
        mg_event_handler_t pfn
        void *pfn_data
        char data[32]
        void *tls
        unsigned int is_listening
        unsigned int is_client
        unsigned int is_accepted
        unsigned int is_resolving
        unsigned int is_arplooking
        unsigned int is_connecting
        unsigned int is_tls
        unsigned int is_tls_hs
        unsigned int is_udp
        unsigned int is_websocket
        unsigned int is_mqtt5
        unsigned int is_hexdumping
        unsigned int is_draining
        unsigned int is_closing
        unsigned int is_full
        unsigned int is_tls_throttled
        unsigned int is_resp
        unsigned int is_readable
        unsigned int is_writable

    cdef struct mg_mgr:
        mg_connection *conns
        void *userdata

    cdef struct mg_http_header:
        mg_str name
        mg_str value

    cdef struct mg_http_message:
        mg_str method
        mg_str uri
        mg_str query
        mg_str proto
        mg_http_header headers[MG_MAX_HTTP_HEADERS]
        mg_str body
        mg_str head
        mg_str message

    cdef struct mg_ws_message:
        mg_str data
        uint8_t flags

    cdef void mg_mgr_init(mg_mgr *mgr)
    cdef void mg_mgr_free(mg_mgr *mgr)
    cdef void mg_mgr_poll(mg_mgr *mgr, int msecs) nogil
    cdef mg_connection *mg_listen(mg_mgr *mgr, const char *url, mg_event_handler_t fn, void *fn_data)
    cdef mg_connection *mg_connect(mg_mgr *mgr, const char *url, mg_event_handler_t fn, void *fn_data)
    cdef bint mg_send(mg_connection *conn, const void *buf, size_t len)
    cdef size_t mg_printf(mg_connection *conn, const char *fmt, ...)
    cdef void mg_close_conn(mg_connection *conn)

    cdef mg_connection *mg_http_listen(mg_mgr *mgr, const char *url, mg_event_handler_t fn, void *fn_data)
    cdef mg_connection *mg_http_connect(mg_mgr *mgr, const char *url, mg_event_handler_t fn, void *fn_data)
    cdef void mg_http_reply(mg_connection *conn, int status_code, const char *headers, const char *body_fmt, ...)
    cdef void mg_http_serve_dir(mg_connection *conn, mg_http_message *hm, mg_http_serve_opts *opts)
    cdef mg_str *mg_http_get_header(mg_http_message *hm, const char *name)
    cdef int mg_http_get_var(const mg_str *buf, const char *name, char *dst, size_t dst_len)
    cdef int mg_url_decode(const char *s, size_t n, char *to, size_t to_len, int form)
    cdef int mg_http_parse(const char *s, size_t len, mg_http_message *hm)
    cdef int mg_http_get_request_len(const unsigned char *buf, size_t buf_len)
    cdef void mg_http_printf_chunk(mg_connection *cnn, const char *fmt, ...)
    cdef void mg_http_write_chunk(mg_connection *c, const char *buf, size_t len)
    cdef void mg_http_delete_chunk(mg_connection *c, mg_http_message *hm)
    cdef void mg_http_creds(mg_http_message *hm, char *user, size_t user_len, char *_pass, size_t pass_len)
    cdef long mg_http_upload(mg_connection *c, mg_http_message *hm, mg_fs *fs, const char *dir, size_t max_size)
    cdef void mg_http_bauth(mg_connection *c, const char *user, const char *_pass)
    cdef mg_str mg_http_get_header_var(mg_str s, mg_str v)
    cdef size_t mg_http_next_multipart(mg_str buf, size_t ofs, mg_http_part *part)
    cdef int mg_http_status(const mg_http_message *hm)
    cdef void mg_http_serve_ssi(mg_connection *c, const char *root, const char *fullpath)

    cdef mg_connection *mg_ws_connect(mg_mgr *mgr, const char *url, mg_event_handler_t fn, void *fn_data, const char *fmt, ...)
    cdef void mg_ws_upgrade(mg_connection *conn, mg_http_message *hm, const char *fmt, ...)
    cdef size_t mg_ws_send(mg_connection *conn, const void *buf, size_t len, int op)
    cdef size_t mg_ws_printf(mg_connection *conn, int op, const char *fmt, ...)
    cdef size_t mg_ws_wrap(mg_connection *c, size_t len, int op)
    # cdef size_t mg_ws_vprintf(mg_connection *c, int op, const char *fmt, va_list *ap)

    cdef struct mg_tls_opts:
        mg_str ca
        mg_str cert
        mg_str key
        mg_str name
        int skip_verification

    cdef void mg_tls_init(mg_connection *conn, const mg_tls_opts *opts)
    cdef void mg_tls_free(mg_connection *conn)

    cdef struct mg_http_serve_opts:
        const char *root_dir
        const char *ssi_pattern
        const char *extra_headers
        const char *mime_types
        const char *page404
        mg_fs *fs

    cdef struct mg_fs:
        pass

    cdef struct mg_http_part:
        mg_str name
        mg_str filename
        mg_str body

    cdef mg_str mg_str_n(const char *s, size_t n)
