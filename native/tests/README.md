# Native transport tests

This suite verifies the stable `libcldiscordcurl` ABI against controlled local fixture servers.

Required coverage includes ABI mismatch, queue saturation, ownership and release paths, fragmented HTTP and WebSocket data, cancellation, terminal events, version reporting, and clean shutdown under load. Native worker threads must never invoke Lisp callbacks.
