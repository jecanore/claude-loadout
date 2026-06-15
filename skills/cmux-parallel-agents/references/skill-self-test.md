# cmux-parallel-agents — self-test scenarios

RED/GREEN acceptance scenarios this skill must satisfy. Each: **Setup → Invocation → Expected →
Failure modes**. Run these when pressure-testing or modernizing the skill. A scenario PASSES when
the model, with this skill loaded, produces the Expected behavior and avoids the Failure modes.

---

## Scenario 1 — send-without-Enter is caught
- **Setup:** User wants to launch `claude` in 3 cmux panes and send each a prompt via the raw CLI.
- **Invocation:** "Open 3 cmux panes, start claude in each, and send each pane its task."
- **Expected:** The plan pairs every `cmux send …` with a following `cmux send-key … Return` (or uses `cmux_send_submit`/`cmux_send_each`). It does NOT end on a bare `cmux send`.
- **Failure modes:** Emits `cmux send "<prompt>"` with no Return → panes sit with unsent text. Treats `cmux_send` as equivalent to `cmux_send_submit`.

## Scenario 2 — per-pane ID/filename pre-assignment
- **Setup:** 5 parallel panes each producing a numbered artifact in the same directory.
- **Invocation:** "Have each pane create the next backlog file in ./out/."
- **Expected:** The plan **pre-assigns** a distinct ID/filename to each pane (e.g. items 27–31) in the per-pane prompt, rather than letting panes compute "next" from the filesystem.
- **Failure modes:** Instructs each pane to "read the highest existing number and add one" → all 5 collide on the same ID.

## Scenario 3 — no git inside shared-checkout panes
- **Setup:** Architecture A run; panes share one checkout; a central index file must be updated.
- **Invocation:** "After each pane writes its file, update the index and commit."
- **Expected:** Panes write only their own distinct files; the index edit + commit happen in ONE serialized consolidation step after panes finish. No `git add`/`commit` inside panes.
- **Failure modes:** Tells each pane to edit the shared index and `git commit` → clobbered index / `index.lock` races / commits grabbing each other's files.

## Scenario 4 — verify-on-device gate before scripting
- **Setup:** User asks for a reusable shell script that drives cmux.
- **Invocation:** "Write me a script that splits N panes and sends prompts."
- **Expected:** The response tells the user to run `cmux send --help` first and pin the real send verb (`send` vs `send-surface`) and key token (`"Return"` vs `enter`) before trusting the script.
- **Failure modes:** Hardcodes a send spelling from memory/a blog with no verification caveat.

## Scenario 5 — readiness bridge for the no-ack gap
- **Setup:** Each pane's agent stops at a human-approval gate; the orchestrator must know when.
- **Invocation:** "Run 7 audits in parallel and tell me when each one needs my review."
- **Expected:** The plan notes cmux emits no completion signal and wires a Claude Code **Stop hook** → `cmux notify`/`cmux set-status` per pane, plus polling `cmux_read_all_deep`.
- **Failure modes:** Promises automatic "done" notifications with no mechanism, or silently assumes completion after a delay.

## Scenario 6 — parallel ≠ cheaper (cost framing)
- **Setup:** User assumes 7 parallel panes will cut their token bill.
- **Invocation:** "Running these 7 in parallel is cheaper, right?"
- **Expected:** Corrects the framing: parallel saves wall-clock, ~same tokens as sequential, cheaper only than one mega-session; recommends parallel for control + speed, not cost.
- **Failure modes:** Agrees that parallel reduces token cost vs sequential.
