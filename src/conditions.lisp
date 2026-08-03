(in-package #:cl-discord-self.conditions)

(define-condition discord-condition (condition)
  ((operation-id
    :initarg :operation-id
    :initform nil
    :reader condition-operation-id)
   (context
    :initarg :context
    :initform nil
    :reader condition-context)))

(define-condition discord-error (discord-condition error) ())

(define-condition configuration-error (discord-error) ())

(define-condition abi-mismatch (configuration-error)
  ((expected-version
    :initarg :expected-version
    :reader expected-abi-version)
   (actual-version
    :initarg :actual-version
    :reader actual-abi-version))
  (:report
   (lambda (condition stream)
     (format stream
             "cl-discord-self ABI mismatch: expected ~D, received ~D"
             (expected-abi-version condition)
             (actual-abi-version condition)))))

(define-condition profile-unavailable (configuration-error)
  ((profile-name
    :initarg :profile-name
    :reader unavailable-profile-name))
  (:report
   (lambda (condition stream)
     (format stream
             "cl-discord-self transport profile is unavailable: ~A"
             (unavailable-profile-name condition)))))

(define-condition runtime-stopping (discord-error) ())
(define-condition queue-full (discord-error) ())
(define-condition operation-not-found (discord-error) ())
(define-condition transport-timeout (discord-error) ())
(define-condition operation-cancelled (discord-error) ())
(define-condition dns-failure (discord-error) ())
(define-condition tls-failure (discord-error) ())
(define-condition certificate-failure (tls-failure) ())
(define-condition proxy-failure (discord-error) ())
(define-condition http-protocol-failure (discord-error) ())
(define-condition websocket-protocol-failure (discord-error) ())

(define-condition response-limit-exceeded (discord-error)
  ((byte-limit
    :initarg :byte-limit
    :reader response-byte-limit)
   (bytes-received
    :initarg :bytes-received
    :reader response-bytes-received))
  (:report
   (lambda (condition stream)
     (format stream
             "cl-discord-self response limit exceeded: ~D of ~D bytes"
             (response-bytes-received condition)
             (response-byte-limit condition)))))

(define-condition native-failure (discord-error)
  ((native-code
    :initarg :native-code
    :reader native-error-code))
  (:report
   (lambda (condition stream)
     (format stream
             "cl-discord-self native transport failure: code ~D"
             (native-error-code condition)))))
