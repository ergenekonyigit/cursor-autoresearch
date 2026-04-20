# Cursor Autoresearch Extension

The Marketplace package is listed as **Autoresearch**. This package provides the VS Code UI layer for the Cursor Autoresearch workflow: status visibility, session actions, dashboard export, and a results panel.

Repository: [ergenekonyigit/cursor-autoresearch](https://github.com/ergenekonyigit/cursor-autoresearch)

---

## Contents

- [One-shot setup](#one-shot-setup)
- [What this extension does](#what-this-extension-does)
- [How it fits into the full workflow](#how-it-fits-into-the-full-workflow)
- [Requirements](#requirements)
- [Install](#install)
- [Commands](#commands)
- [Keyboard shortcuts](#keyboard-shortcuts)
- [Dashboard and results panel](#dashboard-and-results-panel)
- [Screenshot](#screenshot)
- [Typical usage flow](#typical-usage-flow)
- [Develop from source](#develop-from-source)
- [Package a VSIX](#package-a-vsix)
- [Troubleshooting](#troubleshooting)
- [Related docs](#related-docs)
- [License](#license)

---

## One-shot setup

For a quick setup, you can run the following one-shot script which installs dependencies, builds the project, and configures the MCP server and skills:

```bash
curl -fsSL https://raw.githubusercontent.com/ergenekonyigit/cursor-autoresearch/main/scripts/bootstrap.sh | bash
```

---

## What this extension does

- Adds session-aware status integration in VS Code.
- Adds commands for help, session control, dashboard export, and results view.
- Serves a local dashboard over HTTP with server-sent events (SSE) updates.
- Opens a results webview panel for fast session inspection inside VS Code.

The extension is intentionally thin: the optimization loop and metric logic are implemented in shared packages and MCP tools in the same monorepo.

---

## How it fits into the full workflow

Autoresearch is a closed optimization loop:

1. Initialize an experiment and metric direction.
2. Run benchmark iterations.
3. Log outcomes and keep or discard changes.

This extension improves observability and ergonomics for that loop inside VS Code. The MCP server and core engine remain source-of-truth for experiment execution.

For end-to-end setup (MCP config, benchmark script, `autoresearch.jsonl`, and skills), use the main repository README:

- [Main README](https://github.com/ergenekonyigit/cursor-autoresearch#readme)

---

## Requirements

- VS Code: **1.105.0 or newer**
- Node.js: **22 or newer** for building/packaging from source
- pnpm: version aligned with the monorepo root

---

## Install

### From Marketplace

1. Open Extensions in VS Code.
2. Search for **Autoresearch**.
3. Install and reload if prompted.

### From VSIX

1. Build/package the extension (see [Package a VSIX](#package-a-vsix)).
2. Run **Extensions: Install from VSIX...**.
3. Select the generated `.vsix` file.

---

## Commands

The extension contributes these commands:

- `Autoresearch: Help` (`autoresearch.showHelp`)
- `Autoresearch: Export dashboard (browser)` (`autoresearch.exportDashboard`)
- `Autoresearch: Turn mode off` (`autoresearch.modeOff`)
- `Autoresearch: Clear session (delete autoresearch.jsonl)` (`autoresearch.clearSession`)
- `Autoresearch: Start or resume (paste prompt)` (`autoresearch.resumePrompt`)
- `Autoresearch: Toggle expanded status` (`autoresearch.toggleExpanded`)
- `Autoresearch: Open results panel` (`autoresearch.openResultsPanel`)

Use Command Palette and search for "Autoresearch".

---

## Keyboard shortcuts

- Toggle expanded status: **Ctrl+Alt+X**
- Open results panel: **Ctrl+Alt+Shift+X**

Note: keybindings are active when at least one workspace folder is open.

---

## Dashboard and results panel

### Export dashboard

`Autoresearch: Export dashboard (browser)` generates dashboard HTML from extension assets and current session data, then serves it on localhost.

### Live updates

The dashboard endpoint uses SSE so updates in `autoresearch.jsonl` can be pushed without manual refresh.

### Results panel

`Autoresearch: Open results panel` opens an in-editor summary view for quick inspection.

---

## Screenshot

![Autoresearch dashboard screenshot](packages/vscode-extension/images/screenshot.jpg)

---

## Typical usage flow

1. Configure MCP for your workspace or user profile (VS Code `mcp.json`).
2. Start or resume a session with `Autoresearch: Start or resume (paste prompt)`.
3. Run your benchmark-driven iteration loop with MCP tools.
4. Use the results panel and/or browser dashboard to monitor progress.
5. End the session or clear it when needed.

---

## Develop from source

From repository root:

```bash
pnpm install
pnpm build
```

For extension-only checks:

```bash
pnpm --filter autoresearch test
pnpm --filter autoresearch build
```

---

## Package a VSIX

From repository root:

```bash
pnpm package:extension
```

Or directly in this package:

```bash
pnpm run package
```

Expected output path:

- `packages/vscode-extension/autoresearch-<version>.vsix`

---

## Troubleshooting

### Packaging error about version mismatch

If `@types/vscode` is greater than `engines.vscode`, packaging fails. Keep these compatible in this package's `package.json`.

### Dashboard not updating

- Confirm `autoresearch.jsonl` exists in the active workspace/project.
- Re-run dashboard export command to restart the local dashboard server.

### Commands not appearing

- Reload the window (`Developer: Reload Window`).
- Confirm extension is enabled in current workspace.

---

## Related docs

- [Main repository README](https://github.com/ergenekonyigit/cursor-autoresearch#readme)
- [Contributing guide](https://github.com/ergenekonyigit/cursor-autoresearch/blob/main/CONTRIBUTING.md)
- [Release guide](https://github.com/ergenekonyigit/cursor-autoresearch/blob/main/RELEASING.md)
- [Security policy](https://github.com/ergenekonyigit/cursor-autoresearch/blob/main/SECURITY.md)

---

## License

MIT. See [LICENSE](https://github.com/ergenekonyigit/cursor-autoresearch/blob/main/LICENSE).
