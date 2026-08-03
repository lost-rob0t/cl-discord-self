# Compatibility tests

This suite compares canonical records from the pinned `discord.py-self` oracle with Common Lisp parser output.

Python is permitted only inside this test boundary. Compatibility output must exclude tokens, cookies, Python repr strings, memory addresses, and private cache state. Unexplained semantic differences fail the suite.
