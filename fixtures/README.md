# Fixtures

Fixture data is append-only, deterministic, and secret-free.

Planned layout:

- `gateway/`: raw Gateway payloads and frame fragments;
- `http/`: request/response records from controlled local servers;
- `transcripts/`: ordered replay records;
- `expected/`: canonical digests, events, checkpoints, conditions, and results.

Never commit a live token, cookie, authorization header, proxy password, or unredacted account capture. Fixture capture tooling must fail closed when restricted headers are present.
