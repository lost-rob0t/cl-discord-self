# AGENTS.md

## Repository identity

`cl-discord-self` is a standalone Common Lisp Discord user-session protocol library. The initial supported surface is bounded and read-only. StarIntel integration belongs behind a narrow downstream adapter; this repository must remain independently usable.

The authoritative implementation design is `STAR-DISCORD-001 cl-discord-self Runtime Architecture`. The approved portability decision is `STAR-RESEARCH-006 cl-discord-self Common Lisp Port`.

## Mandatory startup

Before changing this repository:

1. Read this file completely, then read any nested `AGENTS.md` that governs the files you will touch.
2. Read the selected GitHub issue and all comments.
3. Read `README`, `CONTRIBUTING`, design links, tests, and relevant implementation history when present.
4. Search for an existing package, condition, protocol, helper, fixture, or test before inventing one.
5. Confirm the expected base branch, issue branch, and writable file ownership.

Repository instructions and explicit issue decisions override general assumptions. Do not start implementation from a title alone.

## Forge Loop

Use Issue-Driven Agentic Development: spec -> issue -> branch -> implementation -> tests -> PR -> checks -> merge -> next issue.

1. Select exactly one open, unblocked issue whose dependencies are merged.
2. Claim it with a concise issue comment stating the intended slice and validation plan.
3. Create a dedicated branch named `codex/issue-<number>-<slug>-a<attempt>` from the current base branch.
4. Restate the acceptance criteria as executable checks before editing.
5. Implement the smallest production-quality vertical slice that satisfies the issue. Do not mix unrelated cleanup.
6. Add or update regression tests with the implementation.
7. Run all relevant format, lint, compile, unit, replay, compatibility, integration, and Nix checks available for the changed boundary.
8. Review the complete diff for architecture violations, secrets, generated-file drift, unbounded work, hidden global state, and accidental API expansion.
9. Commit intentionally, push the issue branch, and open a pull request linked to the issue. Draft status is only for genuinely incomplete or blocked work.
10. Resolve every blocking review thread and explicit blocker. Non-blocking comments and the absence of ceremonial approval do not delay a green merge.
11. When the current PR head is mergeable, all required checks are green, and no blocking thread, explicit blocker, or dependency conflict remains, merge immediately. If repository auto-merge is unavailable, merge directly using the verified current head SHA.
12. Close the issue only when the merged result satisfies its exit gate, then start the next issue from the updated base branch. Never stack unrelated issue work on an unmerged branch.

Only merged changes update repository truth. Draft work, local notes, and unmerged PR claims are not durable project memory.

## Merge-on-green policy

Merge-on-green is the default operating mode for agent-authored pull requests.

A PR must be merged without additional waiting when all of the following are true:

- the PR is open, non-draft, and GitHub reports it mergeable;
- the exact current head SHA has completed every required CI check successfully;
- the branch is based on the intended target and has no dependency conflict;
- there are no unresolved blocking review threads or explicitly recorded blockers;
- the diff contains no discovered secret, architecture violation, destructive migration, or unrelated work.

Do not invent a review gate, wait for ceremonial approval, or leave a green mergeable PR idle. A self-review may verify the merge conditions; it must not be represented as independent approval. When repository-level auto-merge is disabled, call the direct merge operation immediately after verifying the conditions and pass the expected head SHA whenever the tool supports it.

If CI fails, the head changes, GitHub reports a conflict, or a blocker appears, do not merge. Fix or record the blocker, rerun the required checks, and apply this policy again to the new head.

## Work-state rules

- One issue, one worker, and one branch at a time.
- One writable owner per file. Parallel agents may perform bounded read-only research or independent validation.
- A worker may delegate a sharply bounded question, but the parent owns synthesis, the final diff, and validation.
- Do not create duplicate issues or duplicate implementations. Search the issue and PR history first.
- Do not rewrite the base branch, force-push shared branches, or silently absorb unrelated changes.
- Preserve unrelated worktree and repository changes.

## Architecture boundaries

The repository has three separately testable layers:

1. `libcldiscordcurl`: stable, poll-based native transport ABI;
2. `cl-discord-self`: protocol, state, model, event, fixture, and compatibility systems;
3. downstream adapters such as `star-discord-watch`: policy, authorization, journaling, normalization, storage, and publication.

Enforce these rules:

- No actor calls raw libcurl functions.
- No native worker thread invokes arbitrary Lisp callbacks.
- No raw `CURL*`, socket descriptor, callback pointer, or native allocation address crosses the public boundary.
- No protocol package imports RabbitMQ, CouchDB, StarIntel documents, datasets, target policy, or LEO-specific authorization logic.
- The production closure does not require Python. Python is permitted only as a pinned compatibility-test oracle.
- Public events and models are immutable values and retain unknown fields and raw-event references.
- Missing JSON fields, explicit null values, and present values are distinct states.
- Client contexts and transport profiles are pinned, named, versioned, and changed only by explicit configuration revisions.
- Default and CI tests use fixture servers and replay transports, never live Discord accounts.

## Initial capability boundary

Profile A is read-only:

- account-session startup and shutdown;
- Gateway state, heartbeat, resume, reconnect, and typed dispatch events;
- bounded message history and message lookup;
- bounded attachment retrieval;
- deterministic checkpoints, fixtures, and replay;
- capability discovery.

Do not add unsolicited messaging, interaction automation, command frameworks, challenge solving, automatic profile rotation, mass-account orchestration, voice, billing, store, promotion, payment, or subscription behavior unless a later explicitly approved profile changes this boundary.

The library is reusable by any Common Lisp application. Do not require callers to use StarIntel.

## Safety and secret handling

- Never commit tokens, cookies, authorization headers, proxy passwords, captured credentials, or live-account fixtures.
- Logs, conditions, telemetry, checkpoints, and test output use stable references, never raw secrets.
- Redact authorization material before debug hooks.
- Every foreign allocation has exactly one documented owner and release path.
- Queue saturation returns a structured overload condition; never silently drop protocol events.
- All network, queue, retry, response-size, history, attachment, and shutdown work is bounded and cancellable.

## Implementation quality

- Prefer small explicit protocols, immutable structures, typed conditions, and actor-owned mutable state.
- Keep transport, protocol, model, state, fixture, and downstream policy concerns separated.
- Reuse established libraries and repository APIs before adding dependencies.
- Do not add placeholders, fake implementations, TODO-only paths, or success stubs unless the issue explicitly requests a scaffold and tests mark it incomplete.
- Generated files must be deterministic, checked in with their manifest, and reproducible from pinned inputs.
- A changed behavior requires a regression test.
- Never claim a command, check, or test passed unless it was executed. Record skipped checks and the exact reason.

## Validation order

Run the narrowest useful checks first, then the complete boundary checks:

1. formatter and static checks;
2. ASDF compile/load and unit tests;
3. native ABI/unit tests when C or FFI changes;
4. deterministic replay tests when transport, Gateway, clock, event, or checkpoint behavior changes;
5. compatibility-oracle tests when parsers, models, fixtures, or generated code change;
6. integration fixture tests;
7. Nix checks and reproducibility checks.

Live smoke tests are opt-in, disabled by default, never run in CI, and never substitute for deterministic fixtures.

## Blocker protocol

When blocked:

1. stop expanding scope;
2. leave one precise issue comment containing the attempted change, exact command or evidence, failure, suspected cause, and smallest next action;
3. keep partial code only when it is coherent, tested, and useful for review;
4. do not report success, close the issue, or merge around the blocker;
5. exit the worker loop with a failure state so orchestration cannot mistake a no-op for completion.

## PR handoff

Every PR description must include:

- linked issue;
- implemented acceptance criteria;
- architecture boundaries touched;
- exact validation commands and results;
- checks not run and why;
- generated or pinned-input changes;
- remaining risks or follow-up issues.

Reviewers must verify behavior, tests, boundary compliance, secret handling, deterministic output, and that the diff contains no unrelated work. Blocking review findings must be marked explicitly; advisory comments do not suspend merge-on-green.