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


![Autoresearch dashboard screenshot](packages/vscode-extension/images/screenshot.jpg)


## Contents

- [Quick start (your own project)](#quick-start-your-own-project)
- [What you get](#what-you-get)
- [How it works](#how-it-works)
- [Cursor rule](#cursor-rule)
- [Add rules and skills to your project](#add-rules-and-skills-to-your-project)
- [Install for Cursor](#install-for-cursor)
- [Install for VS Code](#install-for-vs-code)
- [Skills](#skills)
- [Extension](#extension)
- [Example: faster tests](#example-faster-tests)
- [Configuration](#configuration)
- [Technology stack](#technology-stack)
- [npm packages](#npm-packages)
- [Requirements](#requirements)
- [Build (from a clone)](#build-from-a-clone)
- [Develop this repository](#develop-this-repository)

---

## Quick start (your own project)

Do this in **the repo you want to optimize** — open that folder as your workspace. The MCP server must see that folder via `AUTORESEARCH_CWD` (usually `${workspaceFolder}`).

**Prerequisites:** **Node.js 18+** to run the published MCP via `npx` (same floor as [`@modelcontextprotocol/sdk`](https://www.npmjs.com/package/@modelcontextprotocol/sdk)). Use **Node.js 22+** only if you are **developing this repository** (`pnpm install` / CI — see [Requirements](#requirements)). [One-shot bootstrap](#one-shot-bootstrap) also needs **git** on your `PATH`.

### Cursor

1. **Add the MCP server** (pick one):
   - **Automated:** run [One-shot bootstrap](#one-shot-bootstrap) — clones this repo, merges `~/.cursor/mcp.json`, and symlinks skills under `~/.agents/skills/`.
   - **Manual:** merge the JSON from the [MCP config snippet](#cursor-mcp-json) into your user `~/.cursor/mcp.json` (or use Cursor’s MCP UI). `AUTORESEARCH_CWD` must be `${workspaceFolder}` so tools run in the project you opened.
2. **Restart Cursor** so MCP picks up the change.
3. **Install the rule and workspace skills** into that project (from the project root):

   ```bash
   curl -fsSL https://raw.githubusercontent.com/ergenekonyigit/cursor-autoresearch/main/scripts/add-to-your-project.sh | bash -s -- --all
   ```

   More options (target dir, skills-only, symlinks): [Add rules and skills to your project](#add-rules-and-skills-to-your-project).

4. **Install the extension (recommended)** for the status bar, dashboard, and results webview: [Extension](#extension) (Visual Studio Marketplace or `.vsix`).

**Then** add `autoresearch.md`, `autoresearch.sh`, and drive the loop with the MCP tools — see [Example: faster tests](#example-faster-tests) and [How it works](#how-it-works).

### VS Code (GitHub Copilot + MCP)

Use the `servers` block in [Install for VS Code](#install-for-vs-code). Reload the window after editing `mcp.json`. Steps 3–4 above still apply if you want `.cursor/rules` and `.cursor/skills` in the repo; VS Code does not load `~/.agents/skills/` automatically.

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

## Cursor rule

[`.cursor/rules/autoresearch-active.mdc`](.cursor/rules/autoresearch-active.mdc) nudges the agent to use MCP tools and keep `autoresearch.md` in sync when `autoresearch.jsonl` exists. Install it with step 3 of [Quick start (your own project)](#quick-start-your-own-project), or see [Add rules and skills to your project](#add-rules-and-skills-to-your-project) for flags and advanced options.

---

## Add rules and skills to your project

This is [Quick start (your own project)](#quick-start-your-own-project) step 3 for Cursor (and optional workspace files in VS Code). Run these from the **root of the project you want to equip** (the folder you open in the editor). The script downloads files from GitHub by default; no clone of this repository is required.

**Rules + skills (default)**

```bash
curl -fsSL https://raw.githubusercontent.com/ergenekonyigit/cursor-autoresearch/main/scripts/add-to-your-project.sh | bash -s -- --all
```

**Rules only**

```bash
curl -fsSL https://raw.githubusercontent.com/ergenekonyigit/cursor-autoresearch/main/scripts/add-to-your-project.sh | bash -s -- --rules
```

**Skills only** (installs under `.cursor/skills/` in that project)

```bash
curl -fsSL https://raw.githubusercontent.com/ergenekonyigit/cursor-autoresearch/main/scripts/add-to-your-project.sh | bash -s -- --skills
```

**Install into a specific directory** (without changing your shell’s current directory)

```bash
TARGET="/path/to/your/project" curl -fsSL https://raw.githubusercontent.com/ergenekonyigit/cursor-autoresearch/main/scripts/add-to-your-project.sh | bash -s -- --all
```

**Use a local clone instead of `curl` (copy files)** — set `AUTORESEARCH_ROOT` to your `cursor-autoresearch` checkout:

```bash
AUTORESEARCH_ROOT="/path/to/cursor-autoresearch" curl -fsSL https://raw.githubusercontent.com/ergenekonyigit/cursor-autoresearch/main/scripts/add-to-your-project.sh | bash -s -- --all
```

**Symlink from a local clone** (updates when you pull the upstream repo; requires `AUTORESEARCH_ROOT`):

```bash
AUTORESEARCH_ROOT="/path/to/cursor-autoresearch" curl -fsSL https://raw.githubusercontent.com/ergenekonyigit/cursor-autoresearch/main/scripts/add-to-your-project.sh | bash -s -- --all --symlink
```

If you already cloned this repository, you can also run the script from disk:

```bash
/path/to/cursor-autoresearch/scripts/add-to-your-project.sh /path/to/your/project --all
```

From this repository’s root, `pnpm add-to-project` runs the same script (pass a target path and flags after `--`):

```bash
pnpm add-to-project -- /path/to/your/project --all
```

| Variable / flag    | Meaning                                                                                                   |
| ------------------ | --------------------------------------------------------------------------------------------------------- |
| `TARGET`           | Project directory to write into (default: current working directory).                                     |
| `REF`              | Git branch or tag on GitHub (default: `main`).                                                           |
| `REPO_SLUG`        | `owner/repo` used for `raw.githubusercontent.com` (default: `ergenekonyigit/cursor-autoresearch`).       |
| `AUTORESEARCH_ROOT`| Local checkout of this repo; when set, files are read from disk (copy) instead of downloaded.             |
| `--symlink`        | Symlink rule and skill folders into `AUTORESEARCH_ROOT` instead of copying (live updates on `git pull`). |

---

## Install for Cursor

Details for [Quick start (your own project)](#quick-start-your-own-project) step 1 when you use **Cursor**.

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

<a id="cursor-mcp-json"></a>

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

Use this when you work in **VS Code** with **GitHub Copilot** and [MCP servers](https://code.visualstudio.com/docs/copilot/customization/mcp-servers). This is the MCP part of [Quick start (your own project)](#quick-start-your-own-project) for VS Code.

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

You can also symlink into `.cursor/skills/` (e.g. `autoresearch-create` → `../../skills/autoresearch-create`) for workspace-only discovery. Nothing in the build requires these symlinks. The [Add rules and skills to your project](#add-rules-and-skills-to-your-project) script can populate `.cursor/skills/` for a single workspace without touching `~/.agents/skills/`.

---

## Extension

Optional but recommended after [Quick start (your own project)](#quick-start-your-own-project) step 4: status bar controls, local dashboard, and the results webview.

Install from Visual Studio Marketplace:

- https://marketplace.visualstudio.com/items?itemName=ergenekonyigit.autoresearch

Or build a `.vsix` and install via **Extensions: Install from VSIX…**

```bash
pnpm package:extension
```

**Shortcuts:** **Ctrl+Alt+X** (expanded status), **Ctrl+Alt+Shift+X** (results webview).

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

Run MCP server directly with npx:

```bash
npx -y @ergenekonyigit/cursor-autoresearch-mcp-server
```

---

## Requirements

- **Node.js**
  - **22 or newer** to **develop this repository** ([`engines.node`](package.json) in the root `package.json`, [`.node-version`](.node-version), CI).
  - **18 or newer** to **run the published MCP server** with `npx` ([`@modelcontextprotocol/sdk`](https://www.npmjs.com/package/@modelcontextprotocol/sdk) declares Node **≥ 18**; the published autoresearch packages do not set a tighter `engines` field).
- **pnpm** — only needed when working from a **clone** of this repo; enable with [Corepack](https://nodejs.org/api/corepack.html) (`corepack enable`) or install manually to match the pinned version.

---

## Build (from a clone)

```bash
git clone https://github.com/ergenekonyigit/cursor-autoresearch.git
cd cursor-autoresearch
pnpm install
pnpm build
```

The MCP entrypoint after build is `packages/mcp-server/dist/index.js` if you prefer local path-based setup.

The [Install for Cursor](#install-for-cursor) and [Install for VS Code](#install-for-vs-code) examples use `npx -y @ergenekonyigit/cursor-autoresearch-mcp-server` for simpler setup.

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
