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

The skill documents **verified** behaviour. Notable framework features that work
today:

- Repository parameter binding (`@Path`, `@Query`, `@Body`, `@Header`) is wired.
- `@Authenticated()` routes through the session-aware adapter.
- The form-validation subsystem compiles and integrates with v2 state managers.
- `@PathParam` / `@QueryParam` extract route parameters in generated route builders.
- Component-level barrel (`injector.dragonfly.dart`) provides a single-import
  shortcut.

If you add or fix a capability, update the skill in the same change.
