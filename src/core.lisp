(in-package #:cl-discord-self)

(defparameter +library-version+ "0.0.1-phase0"
  "Public library version string.

This is a parameter rather than a DEFCONSTANT because Common Lisp does not
require separately evaluated string literals to be EQL. SBCL correctly rejects
reloading a string DEFCONSTANT when the new string object is not EQL to the
previous value.")

(defun library-version ()
  +library-version+)
