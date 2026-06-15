# cmux command + MCP tool reference

Companion to `SKILL.md`. cmux is **macOS-only** (Swift/AppKit). The CLI binary is `cmux`,
symlinked out of the app bundle. Sources: `cmux.com/docs/{api,getting-started,notifications}`
and `github.com/multiagentcognition/cmux-agent-mcp` (`src/cmux-mcp.ts`, README). The cmux
**app** itself is `github.com/manaflow-ai/cmux` (AGPL-3.0; `brew tap manaflow-ai/cmux`, verified
2026-06); `cmux-agent-mcp` is the separate MCP-server repo.

> **Verify before scripting.** Three tokens drift across cmux's own docs AND across builds: the
> targeted-send verb (`cmux send --surface` vs `send-surface`), the Enter token (`"Return"` vs
> `enter`), and the surface-enumeration command (older docs say `list-surfaces`; current builds use
> `list-pane-surfaces` / `list-panes` / `tree`). Run `cmux send --help` and `cmux --help` on the
> actual machine and pin the real tokens. Everything below is "best documented form" — confirm it.

## Table of contents
1. Install
2. Addressing (refs)
3. Raw CLI commands
4. MCP tools (cmux-agent-mcp)
5. Stop-hook → notify bridge
6. Worktree-per-pane (Architecture B) sketch

---

## 1. Install

**App:**
```bash
brew tap manaflow-ai/cmux && brew install --cask cmux   # or download the DMG from cmux.com
```
**CLI symlink** (if `cmux` isn't on PATH after install):
```bash
sudo ln -sf "/Applications/cmux.app/Contents/Resources/bin/cmux" /usr/local/bin/cmux
```
**MCP server** (optional, preferred for orchestration):
```bash
npm i -g cmux-agent-mcp
cmux-agent-mcp init          # registers globally in ~/.claude.json etc.; --project for cwd only
```
`init` only registers the server in config files — it installs **no** prompt, skill, or hook. The
orchestration guidance is entirely on you (hence this skill).

## 2. Addressing (refs)

Targets are typed string refs, **not** bare numbers:
- `surface:N` — a pane's content (a terminal or an agent CLI).
- `workspace:N` — a group of splits.
- `pane:N` — a pane container.

Enumerate live refs first:
```bash
cmux list-pane-surfaces            # machine-readable; script against this (also: list-panes, tree)
```
MCP equivalents: `cmux_identify`, `cmux_list_pane_surfaces`, `cmux_tree`, `cmux_status`.

## 3. Raw CLI commands

| Goal | Command |
|------|---------|
| List surfaces | `cmux list-pane-surfaces` (also `cmux list-panes`, `cmux tree`) |
| Split a new pane | `cmux new-split right --workspace workspace:1` (dirs: `left｜right｜up｜down`) |
| New typed pane | `cmux new-pane --type browser --url <url>` |
| Send text (NO Enter) | `cmux send --surface surface:N "text"` |
| Press a key | `cmux send-key --surface surface:N "Return"` |
| Launch an agent | `cmux send --surface surface:N "claude"` then `cmux send-key --surface surface:N "Return"` |
| Read a pane | `cmux read-screen --surface surface:N` |
| Set a status pill | `cmux set-status build "compiling" --icon hammer --color "#ff9500" --priority 80` |
| Clear a status | `cmux clear-status <id>` |
| Log a line | `cmux log "message" --level error --source build` |
| Desktop notification | `cmux notify --title "…" --subtitle "…" --body "…"` |

**Critical pairing:** `send` never presses Enter. Every `cmux send …` that should *run* must be
followed by `cmux send-key … Return`. Prefer the MCP's `send_submit` to avoid this entirely.

## 4. MCP tools (cmux-agent-mcp)

Orchestration-relevant subset (full set is ~81 tools):

**Launch:** `cmux_open_cli`, `cmux_launch_agents` (e.g. `cli:"claude", count:N`), `cmux_launch_grid`,
`cmux_launch_mixed`, `cmux_orchestrate` (send different plans to different agents in one call),
`cmux_close_all`.

**Panes/splits:** `cmux_new_split`, `cmux_new_pane`, `cmux_list_panes`, `cmux_list_pane_surfaces`,
`cmux_focus_pane`, `cmux_resize_pane`.

**Text I/O:** `cmux_send` (no Enter), `cmux_send_submit` (text **+ Enter**), `cmux_send_key`,
`cmux_send_panel`.

**Bulk / fan-out:** `cmux_send_each` (distinct text per pane — the workhorse for "different prompt
per agent"), `cmux_broadcast` (same text + Enter to all), `cmux_send_submit_some`, `cmux_send_key_all`.

**Read / monitor:** `cmux_read_screen`, `cmux_capture_pane`, `cmux_read_all`,
`cmux_read_all_deep` (prompts idle agents "what have you done?"), `cmux_workspace_snapshot`.

**Status / notify:** `cmux_set_status`, `cmux_clear_status`, `cmux_list_status`, `cmux_set_progress`,
`cmux_log`, `cmux_sidebar_state`, `cmux_notify`, `cmux_list_notifications`, `cmux_clear_notifications`.

**Discovery:** `cmux_status`, `cmux_tree`, `cmux_identify`, `cmux_find`.

Typical MCP flow: `cmux_launch_agents` → `cmux_send_each` (distinct prompts) → poll `cmux_read_all_deep`.

## 5. Stop-hook → notify bridge

Because cmux emits no completion/ack signal, make each pane's Claude Code session *ring cmux* when it
goes idle (e.g. stops at a human-approval gate). Add a **Stop hook** to the agent session running in
each pane (configure via that session's settings/hooks) that runs something like:

```bash
cmux notify --title "Pane idle" --subtitle "$(basename "$PWD")" --body "Agent stopped — needs attention"
# optionally also: cmux set-status agent "waiting" --icon pause.circle --color "#ffcc00" --priority 90
```

This converts "silently waiting" into a desktop ring + sidebar badge, so the orchestrator/human can
treat N panes as a notification queue instead of polling blindly.

## 6. Worktree-per-pane (Architecture B) sketch

cmux does **not** auto-create worktrees. To isolate panes that must each commit:

```bash
# one tree per pane, each on its own branch off the base
for i in $(seq 1 N); do
  git worktree add "../wt-$i" -b "work/slice-$i"
done
# then, per pane: cd into its tree before launching/sending work
cmux send --surface surface:$i "cd ../wt-$i && claude"
cmux send-key --surface surface:$i "Return"
```

Each pane commits to its own branch; merge/rebase after. Note each worktree forks from the base
branch's current HEAD — if pane B depends on pane A's output, sequence them or rebase. For
read-heavy / light-write work, prefer Architecture A (shared checkout, deferred writes) instead.
