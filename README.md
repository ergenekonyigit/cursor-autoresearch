# ◈ Cursor Autoresearch

<p align="center">
  <img src="packages/vscode-extension/images/icon.png" alt="Autoresearch icon" />
</p>

**Autoresearch** is a single workflow for **Cursor** and **VS Code**: MCP tools drive a measurable optimization loop, results append to `autoresearch.jsonl`, you can add an optional browser dashboard and packaged **agent skills** (`autoresearch-create`, `autoresearch-finalize`).

| Field                        | Details                                                                                                   |
| ---------------------------- | --------------------------------------------------------------------------------------------------------- |
| **Open-source project name** | Cursor Autoresearch                                                                                       |
| **GitHub repo**              | [cursor-autoresearch](https://github.com/ergenekonyigit/cursor-autoresearch) (easy to discover and share) |
| **Product / UI name**        | **Autoresearch** (MCP server and marketplace extension)                                                   |

Port of **[pi-autoresearch](https://github.com/davebcn87/pi-autoresearch)** for editors that use **[pi](https://pi.dev/)** upstream in the terminal. Same idea as **[karpathy/autoresearch](https://github.com/karpathy/autoresearch)**: try a change, benchmark, keep wins, revert losses, repeat — for **any** primary metric (test time, bundle size, build time, Lighthouse, and more).

---

## Contents

- [What you get](#what-you-get)
- [How it works](#how-it-works)
- [Technology stack](#technology-stack)
- [npm packages](#npm-packages)
- [Requirements](#requirements)
- [Build (from a clone)](#build-from-a-clone)
- [Cursor rule](#cursor-rule)
- [Install for Cursor](#install-for-cursor)
- [Install for VS Code](#install-for-vs-code)
- [Skills](#skills)
- [Extension](#extension)
- [Screenshot](#screenshot)
- [Example: faster tests](#example-faster-tests)
- [Configuration](#configuration)
- [Develop this repository](#develop-this-repository)

---

## What you get

- **Closed optimization loop** in your repo: one primary metric (e.g. wall-clock seconds, lower is better), agent edits code, a fixed benchmark script measures outcomes, every run is recorded so sessions can resume.
- **Three MCP tools:** `init_experiment` → `run_experiment` → `log_experiment` (see [How it works](#how-it-works)).
- **Session artifacts:** `autoresearch.md` (goal, scope, what you tried), `autoresearch.sh` (repeatable benchmark; stdout must emit `METRIC name=value`), optional `autoresearch.config.json`.
- **Monorepo packages:** shared engine in `packages/core`, `packages/mcp-server` (stdio MCP), `packages/vscode-extension` (status bar, commands, local HTTP + SSE dashboard, results webview).
- **Skills** under [`skills/`](skills/) for starting and finalizing autoresearch sessions (Cursor-oriented paths documented below).

---

## How it works

1. `init_experiment` — Name the run and set metric direction (higher/lower is better).
2. `run_experiment` — Runs your benchmark (commonly `./autoresearch.sh`). Parses `METRIC name=value` from **stdout**.
3. `log_experiment` — Appends a line to `autoresearch.jsonl`. Outcomes like `keep` can auto-commit; `discard`, `crash`, or failed checks can revert code while keeping autoresearch files.

**Typical workspace layout**

| File / convention          | Role                                                             |
| -------------------------- | ---------------------------------------------------------------- |
| `autoresearch.md`          | Goal, scope, “what we tried” — keep it current.                  |
| `autoresearch.sh`          | Repeatable benchmark; metric names must match `init_experiment`. |
| `autoresearch.config.json` | Optional — e.g. `maxIterations`, `workingDir`.                   |
| Branch name                | Often `autoresearch/<goal>-<date>`.                              |

> [!NOTE]
> `AUTORESEARCH_CWD` must point at the **project you optimize** (where `autoresearch.jsonl` and `autoresearch.md` live), usually `${workspaceFolder}` — not necessarily the clone of this repo.

---

## Technology stack

| Layer               | Details                                                                                   |
| ------------------- | ----------------------------------------------------------------------------------------- |
| **Runtime**         | Node.js **≥ 22** (CI uses 22.x; see [`.node-version`](.node-version))                     |
| **Package manager** | **pnpm** 10.x (pinned in root `packageManager`)                                           |
| **Language**        | TypeScript **6.x**                                                                        |
| **Core / MCP**      | `@modelcontextprotocol/sdk`, workspace package `@ergenekonyigit/cursor-autoresearch-core` |
| **Extension**       | esbuild bundle, `@vscode/vsce`, VS Code engine **^1.105.0**                               |
| **Tests**           | Vitest **4.x** (`pnpm test` runs all packages)                                            |
| **Lint**            | ESLint **10.x** (`pnpm lint`)                                                             |

---

## npm packages

Published packages:

- [`@ergenekonyigit/cursor-autoresearch-core`](https://www.npmjs.com/package/@ergenekonyigit/cursor-autoresearch-core)
- [`@ergenekonyigit/cursor-autoresearch-mcp-server`](https://www.npmjs.com/package/@ergenekonyigit/cursor-autoresearch-mcp-server)

Install:

```bash
pnpm add @ergenekonyigit/cursor-autoresearch-core
pnpm add -D @ergenekonyigit/cursor-autoresearch-mcp-server
```

Run MCP server directly with npx:

```bash
npx -y @ergenekonyigit/cursor-autoresearch-mcp-server
```

---

## Requirements

- **Node.js** 22 or newer ([`engines.node`](package.json) in root `package.json`).
- **pnpm** — enable with [Corepack](https://nodejs.org/api/corepack.html) (`corepack enable`) or install manually to match the pinned version.

---

## Build (from a clone)

```bash
git clone https://github.com/ergenekonyigit/cursor-autoresearch.git
cd cursor-autoresearch
pnpm install
pnpm build
```

The MCP entrypoint after build is `packages/mcp-server/dist/index.js` if you prefer local path-based setup.

The JSON examples below use `npx -y @ergenekonyigit/cursor-autoresearch-mcp-server` for simpler setup.

---

## Cursor rule

[`.cursor/rules/autoresearch-active.mdc`](.cursor/rules/autoresearch-active.mdc) nudges the agent to use MCP tools and keep `autoresearch.md` in sync when `autoresearch.jsonl` exists. Copy or symlink into another repo’s `.cursor/rules/` if useful.

---

## Install for Cursor

### One-shot bootstrap

Clones to `~/.local/share/cursor-autoresearch` by default, merges `~/.cursor/mcp.json`, symlinks skills:

```bash
curl -fsSL https://raw.githubusercontent.com/ergenekonyigit/cursor-autoresearch/main/scripts/bootstrap.sh | bash
```

| Variable      | Default                                                     | Meaning                                               |
| ------------- | ----------------------------------------------------------- | ----------------------------------------------------- |
| `INSTALL_DIR` | `$HOME/.local/share/cursor-autoresearch`                    | Clone path                                            |
| `REPO_URL`    | `https://github.com/ergenekonyigit/cursor-autoresearch.git` | Git remote                                            |
| `SKIP_MCP`    | —                                                           | Set to `1` to skip writing `~/.cursor/mcp.json`       |
| `SKIP_SKILLS` | —                                                           | Set to `1` to skip symlinks under `~/.agents/skills/` |

### Already cloned this repo?

```bash
pnpm install:cursor   # same as ./scripts/install.sh
```

Restart **Cursor** so MCP reloads.

### `~/.cursor/mcp.json`

```json
{
  "mcpServers": {
    "autoresearch": {
      "command": "npx",
      "args": ["-y", "@ergenekonyigit/cursor-autoresearch-mcp-server"],
      "env": {
        "AUTORESEARCH_CWD": "${workspaceFolder}"
      }
    }
  }
}
```

References: [Cursor MCP](https://cursor.com/docs/mcp/install-links), [Plugins / MCP](https://cursor.com/docs/plugins).

---

## Install for VS Code

Use this when you work in **VS Code** with **GitHub Copilot** and [MCP servers](https://code.visualstudio.com/docs/copilot/customization/mcp-servers).

1. If you use `npx` in the config below, no local clone is required. If you prefer a local path-based setup, complete [Build (from a clone)](#build-from-a-clone).
2. Add `mcp.json`:
   - **Workspace:** `.vscode/mcp.json` in the folder you open, or
   - **User:** Command Palette → **MCP: Open User Configuration**.
3. Use the `servers` shape (not `mcpServers`):

```json
{
  "servers": {
    "autoresearch": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@ergenekonyigit/cursor-autoresearch-mcp-server"],
      "env": {
        "AUTORESEARCH_CWD": "${workspaceFolder}"
      }
    }
  }
}
```

4. Reload the window (**Developer: Reload Window**) or restart VS Code.

Reference: [MCP configuration (VS Code)](https://code.visualstudio.com/docs/copilot/reference/mcp-configuration).

> [!TIP]
> **Bootstrap / `pnpm install:cursor`** only updates `~/.cursor/mcp.json`. For VS Code–only setups, run the bootstrap script with `SKIP_MCP=1` if you want clone + build + skills without changing Cursor’s config, then add `.vscode/mcp.json` or user `mcp.json` as above.

**Skills path:** Files under `~/.agents/skills/` are aimed at Cursor-style loading. VS Code does not use that path automatically — use Copilot instructions, prompts, or adapt ideas from [`skills/`](skills/).

**Rules:** [`.cursor/rules/`](.cursor/rules/) apply in Cursor; for VS Code, copy the intent into project or user instructions if you want similar behavior.

---

## Skills

If you did not use bootstrap or `pnpm install:cursor`:

```bash
ln -sfn "$PWD/skills/autoresearch-create" ~/.agents/skills/autoresearch-create
ln -sfn "$PWD/skills/autoresearch-finalize" ~/.agents/skills/autoresearch-finalize
```

You can also symlink into `.cursor/skills/` (e.g. `autoresearch-create` → `../../skills/autoresearch-create`) for workspace-only discovery. Nothing in the build requires these symlinks.

---

## Extension

Install from Visual Studio Marketplace:

- https://marketplace.visualstudio.com/items?itemName=ergenekonyigit.autoresearch

Or build a `.vsix` and install via **Extensions: Install from VSIX…**

```bash
pnpm package:extension
```

**Shortcuts:** **Ctrl+Alt+X** (expanded status), **Ctrl+Alt+Shift+X** (results webview).

---

## Screenshot

![Autoresearch dashboard screenshot](packages/vscode-extension/images/screenshot.jpg)

---

## Example: faster tests (e.g. Vitest)

**Prompt idea:** _Reduce how long `npm run test` takes — set up autoresearch and speed it up._ (Use `pnpm test`, `pnpm vitest run`, etc., to match your repo.)

1. Create a branch such as `autoresearch/vitest-speed-<date>`.
2. Add `autoresearch.md` and `autoresearch.sh`, commit so the next session can resume.
3. MCP: `init_experiment` (e.g. metric `vitest_seconds`, lower is better) → baseline `run_experiment` + `log_experiment`.
4. Iterate: change config → `run_experiment` → `log_experiment` with **keep** / **discard** until done or `maxIterations` hits.

Minimal benchmark (adjust the inner command; metric names must match `init_experiment`):

```bash
#!/usr/bin/env bash
set -euo pipefail
SECS="$(/usr/bin/time -p npm run test 2>&1 | awk '/^real/ {print $2}')"
echo "METRIC vitest_seconds=$SECS"
```

If you use `pnpm exec vitest run`, substitute accordingly. For very fast suites, averaging or median inside the script can stabilize the metric.

---

## Configuration

Place `autoresearch.config.json` next to `autoresearch.jsonl` — under the directory `AUTORESEARCH_CWD` points at (usually `${workspaceFolder}`), i.e. your **optimized project**, not the `cursor-autoresearch` clone.

| Key             | Purpose                                                                                                                                                                                                |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `maxIterations` | Cap on counted runs in the current segment; start a new segment with `init_experiment` after that. Omit for no cap.                                                                                    |
| `workingDir`    | Run benchmarks / resolve paths relative to this directory (absolute or relative to workspace root). The JSON file stays at workspace root; validation fails if the path is missing or not a directory. |

```json
{
  "workingDir": "/path/to/project",
  "maxIterations": 50
}
```

Omit the file if defaults are enough.

---

## Develop this repository

```bash
pnpm install
pnpm build
pnpm test
```

| Command                  | Purpose                                               |
| ------------------------ | ----------------------------------------------------- |
| `pnpm lint`              | ESLint across the repo                                |
| `pnpm typecheck`         | TypeScript `--noEmit` for all workspace packages      |
| `pnpm build`             | Build `core`, `mcp-server`, and the VS Code extension |
| `pnpm test`              | All package tests                                     |
| `pnpm clean`             | Remove `packages/*/dist`                              |
| `pnpm package:extension` | Produce `.vsix` under `packages/vscode-extension/`    |

After `pnpm clean`, run `pnpm build` before `pnpm test` so workspace resolution and Vitest aliases stay consistent.

**Run MCP locally** (after `pnpm build`):

```bash
AUTORESEARCH_CWD=/path/to/your/project node packages/mcp-server/dist/index.js
```

Contributor setup, docs deployment, local MCP, and PR expectations: **[CONTRIBUTING.md](CONTRIBUTING.md)**. Releases: **[RELEASING.md](RELEASING.md)**. Security reporting: **[SECURITY.md](SECURITY.md)**. Change history: **[CHANGELOG.md](CHANGELOG.md)**. **License:** MIT — see **[LICENSE](LICENSE)**.
