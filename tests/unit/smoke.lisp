(in-package #:cl-discord-self.tests)

(defun %client-fixture-frames ()
  (list
   (list :type :dispatch
         :name "READY"
         :sequence 1
         :payload (list :session-id "session-1" :user-id "42")
         :raw "{\"op\":0,\"t\":\"READY\",\"s\":1}")
   (list :type :dispatch
         :name "MESSAGE_CREATE"
         :sequence 2
         :payload (list :id "100" :channel-id "200" :content "hello")
         :raw "{\"op\":0,\"t\":\"MESSAGE_CREATE\",\"s\":2}")))

(defun %run-client-fixture ()
  (let* ((transport (make-replay-transport (%client-fixture-frames)))
         (client (make-client transport)))
    (start-client client)
    (assert (client-running-p client))
    (assert (transport-open-p transport))
    (assert (= 2 (run-client client)))
    (assert (eq :idle (client-step client)))
    (values client transport)))

(defun %test-client-lifecycle ()
  (multiple-value-bind (client transport)
      (%run-client-fixture)
    (let ((ready (poll-event client))
          (message (poll-event client)))
      (assert (string= "READY" (dispatch-event-name ready)))
      (assert (= 1 (dispatch-event-sequence ready)))
      (assert (string= "session-1" (getf (dispatch-event-payload ready) :session-id)))
      (assert (string= "{\"op\":0,\"t\":\"READY\",\"s\":1}"
                       (dispatch-event-raw-payload ready)))
      (assert (string= "MESSAGE_CREATE" (dispatch-event-name message)))
      (assert (= 2 (dispatch-event-sequence message)))
      (assert (string= "hello" (getf (dispatch-event-payload message) :content)))
      (assert (null (poll-event client)))
      (assert (= 2 (client-last-sequence client)))
      (assert (string= "session-1" (client-session-id client)))
      (stop-client client)
      (assert (eq :stopped (client-state client)))
      (assert (not (transport-open-p transport)))
      (values (dispatch-event-id ready)
              (dispatch-event-id message)))))

(defun %test-deterministic-event-identifiers ()
  (multiple-value-bind (first-ready-id first-message-id)
      (%test-client-lifecycle)
    (multiple-value-bind (client transport)
        (%run-client-fixture)
      (declare (ignore transport))
      (let ((ready (poll-event client))
            (message (poll-event client)))
        (assert (string= first-ready-id (dispatch-event-id ready)))
        (assert (string= first-message-id (dispatch-event-id message)))
        (stop-client client)))))

(defun run-tests ()
  (assert (string= +library-version+ (library-version)))

  (let ((condition
          (make-condition 'queue-full
                          :operation-id 42
                          :context :fixture-runtime)))
    (assert (= 42 (condition-operation-id condition))))

  (let ((condition
          (make-condition 'abi-mismatch
                          :expected-version 1
                          :actual-version 2)))
    (assert (= 1 (expected-abi-version condition)))
    (assert (= 2 (actual-abi-version condition))))

  (%test-deterministic-event-identifiers)
  t)
