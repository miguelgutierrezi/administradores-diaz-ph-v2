# CLAUDE.md

Instructions for Claude Code in **Administradores Diaz PH v2**.

@AGENTS.md

## Claude Code specifics

- Treat `AGENTS.md` (imported above) as the source of truth; this file only adds notes specific to Claude Code as a tool.
- Do not create new `docs/*.md`, `AGENTS.md` sections, or other instruction files unless explicitly asked — this AI doc set (`AGENTS.md`, `.github/copilot-instructions.md`, `.cursor/rules/`, `docs/ai/`) already exists and should stay the single set.
- Before finishing a task, run the relevant check for what you touched (`flutter analyze`, `flutter test`) rather than assuming it passes.
- Prefer the plans under `docs/0X-*.md` over ad hoc architectural decisions; if a request conflicts with them, say so and propose the aligned path instead of silently picking one.
