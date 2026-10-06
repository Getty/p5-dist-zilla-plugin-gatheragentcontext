# Dist::Zilla::Plugin::GatherAgentContext

Snapshots a distribution's agent context (`.claude/`, `.codex/`, `CLAUDE.md`,
`AGENTS.md`, `skilletor.lock.json`, ...) into the build under
`misc/agent-context/` — not installed, present in the tarball — so you can see
which skills, agents and rules a distribution was built with, even when those
skills are fetched via skilletor and are not committed in the repository.

## Usage

    ; in your dist.ini
    [GatherAgentContext]

By default it snapshots both the Claude (`.claude/`, `CLAUDE.md`) and Codex
(`.codex/`, `.agents/skills`, `AGENTS.md`) context sets. Narrow or redirect it
with `harness`, `dir`, `file`, `to`, `exclude_match`, `prune_gitignore` and
`missing_ok` — see the module POD for details.

Below a harness directory (`.claude/`, `.codex/`) only agent content is taken:
`agents/`, `skills/`, `rules/`, `hooks/`, `commands/`, `CLAUDE.md`,
`skilletor.json`, `skilletor.lock.json` and `skilletor-rules.md`. Local state
the harness or you keep next to it — credentials, session transcripts, todos,
caches, `*.local.*` overrides — is never read, so it cannot end up in the
tarball.
