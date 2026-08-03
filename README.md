# cl-discord-self

A standalone Common Lisp library for bounded Discord user-session protocol handling.

## Status

Phase 0: repository and contract bootstrap. There is no live Discord transport or account integration in the repository yet.

The initial compatibility profile is read-only and fixture-first:

- account-session lifecycle contracts;
- Gateway state, heartbeat, resume, reconnect, and typed dispatch events;
- bounded message history and message lookup;
- bounded attachment retrieval;
- deterministic checkpoints and replay;
- capability discovery.

The library is not tied to StarIntel. Downstream applications own authorization, collection scope, storage, normalization, and publication.

## Architecture

The implementation is split into three independently testable layers:

1. `libcldiscordcurl`: stable, poll-based native transport ABI;
2. `cl-discord-self`: Common Lisp protocol, model, event, state, fixture, and compatibility systems;
3. downstream adapters: application policy and durable side effects.

No native worker thread may call arbitrary Lisp code. The Lisp runtime polls bounded native events and routes immutable values to owning components.

## Non-goals for the initial profile

- message sending or unsolicited messaging;
- interaction or command automation;
- automatic transport-profile rotation;
- challenge solving;
- mass-account orchestration;
- voice transport;
- billing, store, promotion, payment, or subscription helpers;
- StarIntel-specific policy or persistence inside the library.

## Development

Read `AGENTS.md` before changing the repository. Work follows the issue-driven Forge Loop: one issue, one branch, one worker, tests, draft PR, independent review, then merge.

Default validation is offline and deterministic. CI must never require a live Discord account or production credential.

## Design sources

- `STAR-DISCORD-001 cl-discord-self Runtime Architecture`
- `STAR-RESEARCH-006 cl-discord-self Common Lisp Port`

The source documents currently live in `lost-rob0t/starintel-auto-research`.
