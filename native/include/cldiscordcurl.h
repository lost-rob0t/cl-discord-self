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
  uint32_t abi_version;
  uint32_t event_queue_capacity;
  uint32_t max_http_connections;
  uint32_t max_websockets;
  const char *profile_name;
  const char *ca_bundle_path;
} cdc_runtime_options;

typedef struct cdc_http_request {
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
  const char *url;
  const uint8_t *headers_json;
  size_t headers_json_len;
  uint32_t connect_timeout_ms;
  uint64_t max_frame_bytes;
} cdc_ws_request;

typedef struct cdc_event {
  cdc_event_type type;
  uint64_t operation_id;
  int32_t stable_code;
  int32_t native_code;
  uint32_t flags;
  uint16_t close_code;
  const uint8_t *data;
  size_t data_len;
} cdc_event;

uint32_t cdc_abi_version(void);
const char *cdc_runtime_version(void);
const char *cdc_native_curl_version(void);

int cdc_runtime_create(const cdc_runtime_options *options,
                       cdc_runtime **out_runtime);
int cdc_runtime_shutdown(cdc_runtime *runtime, uint32_t deadline_ms);
void cdc_runtime_destroy(cdc_runtime *runtime);

int cdc_http_submit(cdc_runtime *runtime,
                    const cdc_http_request *request,
                    cdc_request_id *out_request_id);
int cdc_http_cancel(cdc_runtime *runtime, cdc_request_id request_id);

int cdc_ws_open(cdc_runtime *runtime,
                const cdc_ws_request *request,
                cdc_socket_id *out_socket_id);
int cdc_ws_send(cdc_runtime *runtime,
                cdc_socket_id socket_id,
                uint32_t frame_flags,
                const uint8_t *payload,
                size_t payload_len);
int cdc_ws_close(cdc_runtime *runtime,
                 cdc_socket_id socket_id,
                 uint16_t close_code,
                 const uint8_t *reason,
                 size_t reason_len);

int cdc_poll(cdc_runtime *runtime,
             uint32_t timeout_ms,
             cdc_event **out_event);
void cdc_event_free(cdc_event *event);

/*
 * Ownership contract
 * ------------------
 * Submission inputs remain owned by the caller for the duration of the call.
 * The runtime copies every accepted input before returning CDC_OK.
 *
 * A non-null event returned by cdc_poll is owned by the caller until exactly
 * one call to cdc_event_free. Event payload pointers remain valid only until
 * that event is freed.
 *
 * Runtime shutdown stops intake, cancels outstanding operations, emits
 * terminal events, and joins native threads before destruction is permitted.
 * No authorization header, token, cookie, message body, or proxy password may
 * appear in native error strings.
 */

#ifdef __cplusplus
}
#endif

#endif
