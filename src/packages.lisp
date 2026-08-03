(defpackage #:cl-discord-self.conditions
  (:use #:cl)
  (:export
   #:discord-condition
   #:discord-error
   #:configuration-error
   #:abi-mismatch
   #:profile-unavailable
   #:runtime-stopping
   #:queue-full
   #:operation-not-found
   #:transport-timeout
   #:operation-cancelled
   #:dns-failure
   #:tls-failure
   #:certificate-failure
   #:proxy-failure
   #:http-protocol-failure
   #:websocket-protocol-failure
   #:response-limit-exceeded
   #:native-failure
   #:client-state-error
   #:transport-state-error
   #:protocol-frame-error
   #:condition-operation-id
   #:condition-context
   #:condition-state
   #:condition-operation
   #:condition-frame
   #:expected-abi-version
   #:actual-abi-version
   #:unavailable-profile-name
   #:native-error-code
   #:response-byte-limit
   #:response-bytes-received))

(defpackage #:cl-discord-self
  (:use #:cl)
  (:export
   #:+library-version+
   #:library-version
   #:transport
   #:transport-open
   #:transport-receive
   #:transport-send
   #:transport-close
   #:transport-open-p
   #:replay-transport
   #:make-replay-transport
   #:replay-sent-messages
   #:dispatch-event
   #:dispatch-event-id
   #:dispatch-event-name
   #:dispatch-event-sequence
   #:dispatch-event-payload
   #:dispatch-event-raw-payload
   #:client
   #:make-client
   #:start-client
   #:client-step
   #:run-client
   #:poll-event
   #:stop-client
   #:client-state
   #:client-running-p
   #:client-last-sequence
   #:client-session-id))

(defpackage #:cl-discord-self.tests
  (:use #:cl)
  (:import-from #:cl-discord-self
                #:+library-version+
                #:library-version
                #:make-replay-transport
                #:transport-open-p
                #:make-client
                #:start-client
                #:client-step
                #:run-client
                #:poll-event
                #:stop-client
                #:client-state
                #:client-running-p
                #:client-last-sequence
                #:client-session-id
                #:dispatch-event-id
                #:dispatch-event-name
                #:dispatch-event-sequence
                #:dispatch-event-payload
                #:dispatch-event-raw-payload)
  (:import-from #:cl-discord-self.conditions
                #:queue-full
                #:abi-mismatch
                #:condition-operation-id
                #:expected-abi-version
                #:actual-abi-version)
  (:export #:run-tests))
