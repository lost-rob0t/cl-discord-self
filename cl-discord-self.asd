(asdf:defsystem "cl-discord-self/core"
  :description "Protocol-neutral core contracts for cl-discord-self."
  :author "lost-rob0t"
  :license "MIT"
  :version "0.0.1"
  :serial t
  :components ((:file "src/packages")
               (:file "src/conditions")
               (:file "src/core")
               (:file "src/client")))

(asdf:defsystem "cl-discord-self"
  :description "Bounded read-only Discord user-session protocol library."
  :author "lost-rob0t"
  :license "MIT"
  :version "0.0.1"
  :depends-on ("cl-discord-self/core")
  :in-order-to ((asdf:test-op (asdf:test-op "cl-discord-self/tests"))))

(asdf:defsystem "cl-discord-self/tests"
  :description "Offline deterministic smoke tests for cl-discord-self."
  :author "lost-rob0t"
  :license "MIT"
  :depends-on ("cl-discord-self/core")
  :serial t
  :components ((:file "tests/unit/smoke"))
  :perform (asdf:test-op (operation component)
             (declare (ignore operation component))
             (unless (uiop:symbol-call :cl-discord-self.tests :run-tests)
               (error "cl-discord-self tests failed"))))
