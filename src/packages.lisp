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
   #:condition-operation-id
   #:condition-context
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
   #:library-version))

(defpackage #:cl-discord-self.tests
  (:use #:cl)
  (:import-from #:cl-discord-self
                #:+library-version+
                #:library-version)
  (:import-from #:cl-discord-self.conditions
                #:queue-full
                #:abi-mismatch
                #:condition-operation-id
                #:expected-abi-version
                #:actual-abi-version)
  (:export #:run-tests))
