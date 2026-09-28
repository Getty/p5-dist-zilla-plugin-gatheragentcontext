# Dist::Zilla::Plugin::GatherAgentContext

Snapshots a distribution's agent context (`.claude/`, `.codex/`, `CLAUDE.md`,
`AGENTS.md`, `skilletor.lock.json`, ...) into the build under
`misc/agent-context/` — not installed, present in the tarball — so you can see
which skills, agents and rules a distribution was built with, even when those
skills are fetched via skilletor and are not committed in the repository.
