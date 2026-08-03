(in-package #:cl-discord-self.tests)

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

  t)
