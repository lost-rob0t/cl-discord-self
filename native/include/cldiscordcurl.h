#ifndef CLDISCORDCURL_H
#define CLDISCORDCURL_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define CDC_ABI_VERSION 1u

typedef struct cdc_runtime cdc_runtime;
typedef uint64_t cdc_request_id;
typedef uint64_t cdc_socket_id;

typedef enum cdc_error_code {
  CDC_OK = 0,
  CDC_ERR_INVALID_ARGUMENT = -1,
  CDC_ERR_ABI_MISMATCH = -2,
  CDC_ERR_PROFILE_UNAVAILABLE = -3,
  CDC_ERR_RUNTIME_STOPPING = -4,
  CDC_ERR_QUEUE_FULL = -5,
  CDC_ERR_OPERATION_NOT_FOUND = -6,
  CDC_ERR_TIMEOUT = -7,
  CDC_ERR_CANCELLED = -8,
  CDC_ERR_DNS_FAILURE = -9,
  CDC_ERR_TLS_FAILURE = -10,
  CDC_ERR_CERTIFICATE_FAILURE = -11,
  CDC_ERR_PROXY_FAILURE = -12,
  CDC_ERR_HTTP_PROTOCOL_FAILURE = -13,
  CDC_ERR_WEBSOCKET_PROTOCOL_FAILURE = -14,
  CDC_ERR_RESPONSE_LIMIT_EXCEEDED = -15,
  CDC_ERR_INTERNAL_NATIVE_FAILURE = -16
} cdc_error_code;

typedef enum cdc_event_type {
  CDC_EVENT_NONE = 0,
  CDC_EVENT_HTTP_HEADERS,
  CDC_EVENT_HTTP_BODY,
  CDC_EVENT_HTTP_COMPLETE,
  CDC_EVENT_WS_OPEN,
  CDC_EVENT_WS_FRAME,
  CDC_EVENT_WS_CLOSED,
  CDC_EVENT_CANCELLED,
  CDC_EVENT_ERROR,
  CDC_EVENT_RUNTIME_STOPPED
} cdc_event_type;

typedef enum cdc_ws_frame_flag {
  CDC_WS_FRAME_TEXT = 1u << 0,
  CDC_WS_FRAME_BINARY = 1u << 1,
  CDC_WS_FRAME_CONTINUATION = 1u << 2,
  CDC_WS_FRAME_FINAL = 1u << 3
} cdc_ws_frame_flag;

typedef struct cdc_runtime_options {
  uint32_t struct_size;
  uint32_t abi_version;
  uint32_t event_queue_capacity;
  uint32_t max_http_connections;
  uint32_t max_websockets;
  const char *profile_name;
  const char *ca_bundle_path;
} cdc_runtime_options;

typedef struct cdc_http_request {
  uint32_t struct_size;
  const char *method;
  const char *url;
  const uint8_t *headers_json;
  size_t headers_json_len;
  const uint8_t *body;
  size_t body_len;
  uint32_t connect_timeout_ms;
  uint32_t total_timeout_ms;
  uint64_t max_response_bytes;
} cdc_http_request;

typedef struct cdc_ws_request {
  uint32_t struct_size;
  const char *url;
  const uint8_t *headers_json;
  size_t headers_json_len;
  uint32_t connect_timeout_ms;
  uint64_t max_frame_bytes;
} cdc_ws_request;

typedef struct cdc_event {
  uint32_t struct_size;
  uint32_t type;
  uint64_t operation_id;
  int32_t stable_code;
  int32_t native_code;
  uint32_t flags;
  uint16_t close_code;
  const uint8_t *data;
  size_t data_len;
} cdc_event;

#define CDC_RUNTIME_OPTIONS_V1_SIZE ((uint32_t)sizeof(cdc_runtime_options))
#define CDC_HTTP_REQUEST_V1_SIZE ((uint32_t)sizeof(cdc_http_request))
#define CDC_WS_REQUEST_V1_SIZE ((uint32_t)sizeof(cdc_ws_request))
#define CDC_EVENT_V1_SIZE ((uint32_t)sizeof(cdc_event))

/*
 * Public struct versioning
 * ------------------------
 * Callers zero-initialize every input struct and set struct_size to the matching
 * CDC_*_V1_SIZE constant. Libraries accept a struct at least as large as the
 * v1 prefix they understand and ignore zeroed trailing fields. Library-created
 * events set struct_size to the number of bytes actually available.
 *
 * Enum declarations provide named constants only. Public struct fields and
 * function results use fixed-width integer types so compiler enum-size choices
 * cannot change the ABI.
 */

/*
 * Version strings are immutable, process-lifetime, UTF-8, NUL-terminated
 * storage owned by the library. The caller must not free or modify them.
 */
uint32_t cdc_abi_version(void);
const char *cdc_runtime_version(void);
const char *cdc_native_curl_version(void);

/*
 * On success, create copies all pointed-to option strings and writes a non-null
 * runtime to out_runtime. On failure, out_runtime is set to null and the caller
 * retains ownership of every option and pointed-to byte.
 */
int32_t cdc_runtime_create(const cdc_runtime_options *options,
                           cdc_runtime **out_runtime);

/*
 * The first shutdown call atomically stops intake and starts cancellation.
 * Every accepted operation produces exactly one terminal event. The
 * CDC_EVENT_RUNTIME_STOPPED event is queued last and no event follows it.
 *
 * CDC_OK means all native threads are joined and no more events can be
 * produced. CDC_ERR_TIMEOUT leaves the runtime in the stopping state; the
 * caller may continue polling and call shutdown again with another bounded
 * deadline. New submissions return CDC_ERR_RUNTIME_STOPPING after shutdown
 * begins.
 */
int32_t cdc_runtime_shutdown(cdc_runtime *runtime, uint32_t deadline_ms);

/*
 * A non-null runtime may be destroyed only after shutdown returned CDC_OK, the
 * caller observed and freed CDC_EVENT_RUNTIME_STOPPED, and every previously
 * returned event was freed. Passing null is a no-op.
 */
void cdc_runtime_destroy(cdc_runtime *runtime);

/* Accepted operation identifiers are nonzero. Output identifiers are zeroed on failure. */
int32_t cdc_http_submit(cdc_runtime *runtime,
                        const cdc_http_request *request,
                        cdc_request_id *out_request_id);

/*
 * A successful cancellation request does not synchronously free caller-visible
 * state. The operation still produces exactly one terminal event. If normal
 * completion wins the race, that normal terminal event is authoritative.
 */
int32_t cdc_http_cancel(cdc_runtime *runtime, cdc_request_id request_id);

int32_t cdc_ws_open(cdc_runtime *runtime,
                    const cdc_ws_request *request,
                    cdc_socket_id *out_socket_id);
int32_t cdc_ws_send(cdc_runtime *runtime,
                    cdc_socket_id socket_id,
                    uint32_t frame_flags,
                    const uint8_t *payload,
                    size_t payload_len);
int32_t cdc_ws_close(cdc_runtime *runtime,
                     cdc_socket_id socket_id,
                     uint16_t close_code,
                     const uint8_t *reason,
                     size_t reason_len);

/*
 * out_event must be non-null. cdc_poll sets *out_event to null before waiting.
 * CDC_OK returns exactly one non-null event. CDC_ERR_TIMEOUT returns no event.
 * Other errors also return no event.
 *
 * Queue capacity is bounded. The implementation reserves delivery capacity for
 * accepted operations' terminal events and CDC_EVENT_RUNTIME_STOPPED; terminal
 * events are never silently dropped because non-terminal traffic filled the
 * queue.
 */
int32_t cdc_poll(cdc_runtime *runtime,
                 uint32_t timeout_ms,
                 cdc_event **out_event);

/* Passing null is a no-op. A non-null event must be freed exactly once. */
void cdc_event_free(cdc_event *event);

/*
 * Ownership and data contract
 * ---------------------------
 * Runtime options and operation submission inputs remain owned by the caller
 * for the duration of the call. The runtime copies every accepted string and
 * byte range before returning CDC_OK. A pointer may be null only when its
 * corresponding length is zero, except documented optional NUL-terminated
 * strings in cdc_runtime_options.
 *
 * A non-null event returned by cdc_poll is owned by the caller until exactly
 * one call to cdc_event_free. Event data is immutable. event->data is null if
 * and only if event->data_len is zero, and remains valid only until that event
 * is freed. Freeing an event never frees or changes its runtime.
 *
 * Stable error codes cross the ABI. Native error codes are diagnostic only and
 * must not be used as portable control flow. No authorization header, token,
 * cookie, message body, proxy password, or other secret may appear in native
 * diagnostics, version strings, or event error payloads.
 */

#ifdef __cplusplus
}
#endif

#endif
