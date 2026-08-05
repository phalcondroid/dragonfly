# Dragonfly AI bundle

Agent instructions for projects that **use** Dragonfly, shipped with the package so an AI
assistant in a consumer app knows the framework's conventions without guessing.

(For working on the framework itself, see the repo root `CLAUDE.md` and `docs/ai/`.)

## Install

From your app's root:

```bash
mkdir -p .claude/skills
cp -r <path-to-dragonfly-package>/ai/skills/dragonfly-app .claude/skills/
```

With a path dependency that is usually:

```bash
cp -r ../dragonfly/ai/skills/dragonfly-app .claude/skills/
```

If Dragonfly came from pub, locate the package first:

```bash
DF=$(dart pub cache list | grep -o '"[^"]*dragonfly-[0-9.]*"' | tr -d '"' | head -1)
cp -r "$DF/ai/skills/dragonfly-app" .claude/skills/
```

Agents that read `AGENTS.md` instead of skills can be pointed at the same file:

```markdown
<!-- AGENTS.md -->
When writing Dragonfly code, follow `.claude/skills/dragonfly-app/SKILL.md`.
```

## Contents

| Path | Purpose |
| ---- | ------- |
| `skills/dragonfly-app/SKILL.md` | Layer layout, annotations that actually work, codegen workflow, and the current limitations an agent must not paper over |

## Keeping it honest

The skill documents **verified** behaviour, which in a few places differs from the
framework's `README.md`. Notably, repository parameter binding (`@Path`, `@Query`,
`@Body`, `@Header`) is not implemented, and the form-validation subsystem does not yet
compile. The skill says so, so that agents do not generate code that silently does
nothing. When those land, update the skill in the same change.
