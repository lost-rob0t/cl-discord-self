(in-package #:cl-discord-self)

(defconstant +fnv-1a-offset-basis+ #xcbf29ce484222325)
(defconstant +fnv-1a-prime+ #x100000001b3)

(defstruct (%queue (:constructor %make-queue ()))
  head
  tail)

(defun %queue-empty-p (queue)
  (null (%queue-head queue)))

(defun %queue-push (queue value)
  (let ((cell (list value)))
    (if (%queue-tail queue)
        (setf (cdr (%queue-tail queue)) cell)
        (setf (%queue-head queue) cell))
    (setf (%queue-tail queue) cell)
    value))

(defun %queue-pop (queue)
  (let ((head (%queue-head queue)))
    (if (null head)
        (values nil nil)
        (progn
          (setf (%queue-head queue) (cdr head))
          (when (null (%queue-head queue))
            (setf (%queue-tail queue) nil))
          (values (car head) t)))))

(defun %queue-values (queue)
  (loop for cell on (%queue-head queue)
        collect (car cell)))

(defun %copy-value (value)
  (typecase value
    (cons (copy-tree value))
    (string (copy-seq value))
    (vector (copy-seq value))
    (t value)))

(defun %plist-key-present-p (plist key)
  (loop for cursor on plist by #'cddr
        while cursor
        thereis (eq (car cursor) key)))

(defun %fnv-1a-octet (hash octet)
  (ldb (byte 64 0)
       (* (logxor hash (ldb (byte 8 0) octet))
          +fnv-1a-prime+)))

(defun %fnv-1a-string (hash string)
  (loop with result = hash
        for character across string
        do (setf result (%fnv-1a-octet result (char-code character)))
        finally (return result)))

(defun %fnv-1a-value (hash value)
  (typecase value
    (string (%fnv-1a-string hash value))
    ((vector (unsigned-byte 8))
     (loop with result = hash
           for octet across value
           do (setf result (%fnv-1a-octet result octet))
           finally (return result)))
    (vector
     (%fnv-1a-string hash (prin1-to-string value)))
    (t
     (%fnv-1a-string hash (prin1-to-string value)))))

(defun %stable-event-id (name sequence raw-payload)
  (let ((hash +fnv-1a-offset-basis+))
    (setf hash (%fnv-1a-string hash name))
    (setf hash (%fnv-1a-string hash "|"))
    (setf hash (%fnv-1a-string hash (prin1-to-string sequence)))
    (setf hash (%fnv-1a-string hash "|"))
    (setf hash (%fnv-1a-value hash raw-payload))
    (format nil "~16,'0X" hash)))

(defclass transport () ())

(defgeneric transport-open (transport))
(defgeneric transport-receive (transport))
(defgeneric transport-send (transport message))
(defgeneric transport-close (transport))
(defgeneric transport-open-p (transport))

(defclass replay-transport (transport)
  ((frames
    :initarg :frames
    :reader %replay-frames)
   (cursor
    :initform 0
    :accessor %replay-cursor)
   (state
    :initform :new
    :accessor %replay-state)
   (sent
    :initform (%make-queue)
    :reader %replay-sent)))

(defun make-replay-transport (frames)
  (make-instance 'replay-transport
                 :frames (coerce (map 'list #'%copy-value frames) 'vector)))

(defmethod transport-open-p ((transport replay-transport))
  (eq :open (%replay-state transport)))

(defmethod transport-open ((transport replay-transport))
  (unless (eq :new (%replay-state transport))
    (error 'cl-discord-self.conditions:transport-state-error
           :state (%replay-state transport)
           :operation :open))
  (setf (%replay-state transport) :open)
  transport)

(defmethod transport-receive ((transport replay-transport))
  (unless (transport-open-p transport)
    (error 'cl-discord-self.conditions:transport-state-error
           :state (%replay-state transport)
           :operation :receive))
  (let ((cursor (%replay-cursor transport))
        (frames (%replay-frames transport)))
    (if (< cursor (length frames))
        (progn
          (incf (%replay-cursor transport))
          (values (%copy-value (aref frames cursor)) t))
        (values nil nil))))

(defmethod transport-send ((transport replay-transport) message)
  (unless (transport-open-p transport)
    (error 'cl-discord-self.conditions:transport-state-error
           :state (%replay-state transport)
           :operation :send))
  (%queue-push (%replay-sent transport) (%copy-value message))
  message)

(defmethod transport-close ((transport replay-transport))
  (unless (eq :closed (%replay-state transport))
    (setf (%replay-state transport) :closed))
  transport)

(defun replay-sent-messages (transport)
  (mapcar #'%copy-value (%queue-values (%replay-sent transport))))

(defstruct (dispatch-event
             (:constructor %make-dispatch-event
                 (&key id name sequence payload raw-payload)))
  (id "" :type string :read-only t)
  (name "" :type string :read-only t)
  (sequence nil :read-only t)
  (payload nil :read-only t)
  (raw-payload nil :read-only t))

(defclass client ()
  ((transport
    :initarg :transport
    :reader %client-transport)
   (state
    :initform :new
    :reader client-state)
   (mailbox
    :initform (%make-queue)
    :reader %client-mailbox)
   (events
    :initform (%make-queue)
    :reader %client-events)
   (last-sequence
    :initform nil
    :reader client-last-sequence)
   (session-id
    :initform nil
    :reader client-session-id)))

(defun make-client (transport)
  (check-type transport transport)
  (make-instance 'client :transport transport))

(defun client-running-p (client)
  (eq :running (client-state client)))

(defun %set-client-state (client state)
  (setf (slot-value client 'state) state))

(defun %set-client-last-sequence (client sequence)
  (setf (slot-value client 'last-sequence) sequence))

(defun %set-client-session-id (client session-id)
  (setf (slot-value client 'session-id) session-id))

(defun %post-client-message (client message)
  (%queue-push (%client-mailbox client) message))

(defun %invalid-client-state (client operation)
  (error 'cl-discord-self.conditions:client-state-error
         :state (client-state client)
         :operation operation))

(defun %validate-dispatch-frame (frame)
  (unless (and (listp frame)
               (%plist-key-present-p frame :name)
               (%plist-key-present-p frame :raw))
    (error 'cl-discord-self.conditions:protocol-frame-error :frame frame))
  (let ((name (getf frame :name))
        (sequence (getf frame :sequence)))
    (unless (and (stringp name) (plusp (length name)))
      (error 'cl-discord-self.conditions:protocol-frame-error :frame frame))
    (unless (or (null sequence)
                (and (integerp sequence) (not (minusp sequence))))
      (error 'cl-discord-self.conditions:protocol-frame-error :frame frame))))

(defun %dispatch-frame (client frame)
  (%validate-dispatch-frame frame)
  (let* ((name (getf frame :name))
         (sequence (getf frame :sequence))
         (payload (getf frame :payload))
         (raw-payload (getf frame :raw))
         (last-sequence (client-last-sequence client)))
    (when (and sequence last-sequence (< sequence last-sequence))
      (error 'cl-discord-self.conditions:protocol-frame-error :frame frame))
    (when sequence
      (%set-client-last-sequence client sequence))
    (when (and (string= name "READY")
               (listp payload)
               (%plist-key-present-p payload :session-id))
      (%set-client-session-id client (getf payload :session-id)))
    (let ((event
            (%make-dispatch-event
             :id (%stable-event-id name sequence raw-payload)
             :name (copy-seq name)
             :sequence sequence
             :payload (%copy-value payload)
             :raw-payload (%copy-value raw-payload))))
      (%queue-push (%client-events client) event)
      :event)))

(defun %handle-frame (client frame)
  (unless (and (listp frame) (%plist-key-present-p frame :type))
    (error 'cl-discord-self.conditions:protocol-frame-error :frame frame))
  (case (getf frame :type)
    (:dispatch
     (%dispatch-frame client frame))
    (:closed
     (transport-close (%client-transport client))
     (%set-client-state client :stopped)
     :closed)
    (otherwise
     (error 'cl-discord-self.conditions:protocol-frame-error :frame frame))))

(defun %handle-client-message (client message)
  (case (first message)
    (:start
     (transport-open (%client-transport client))
     (%set-client-state client :running)
     :started)
    (:stop
     (transport-close (%client-transport client))
     (%set-client-state client :stopped)
     :stopped)
    (:frame
     (%handle-frame client (second message)))
    (otherwise
     (error 'cl-discord-self.conditions:protocol-frame-error :frame message))))

(defun start-client (client)
  (unless (eq :new (client-state client))
    (%invalid-client-state client :start))
  (%post-client-message client '(:start))
  (client-step client)
  client)

(defun client-step (client)
  (multiple-value-bind (message message-p)
      (%queue-pop (%client-mailbox client))
    (cond
      (message-p
       (%handle-client-message client message))
      ((client-running-p client)
       (multiple-value-bind (frame frame-p)
           (transport-receive (%client-transport client))
         (if frame-p
             (%handle-client-message client (list :frame frame))
             :idle)))
      (t
       :idle))))

(defun run-client (client &key (max-steps 1024))
  (unless (client-running-p client)
    (%invalid-client-state client :run))
  (check-type max-steps (integer 1 *))
  (loop with processed = 0
        repeat max-steps
        for result = (client-step client)
        do (case result
             (:event (incf processed))
             ((:idle :closed :stopped) (return processed)))
        finally (return processed)))

(defun poll-event (client)
  (%queue-pop (%client-events client)))

(defun stop-client (client)
  (case (client-state client)
    (:stopped client)
    (:new
     (%set-client-state client :stopped)
     client)
    (:running
     (%post-client-message client '(:stop))
     (client-step client)
     client)
    (otherwise
     (%invalid-client-state client :stop))))
