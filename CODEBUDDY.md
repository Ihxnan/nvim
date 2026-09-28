# CODEBUDDY.md

This file provides guidance to CodeBuddy Code when working with code in this repository.

## What this is

Personal Neovim config (Lua, plugin-managed by **lazy.nvim**) — a dotfiles repo, not a
build project. Leader = `Space`, local leader = `\`. Targets **Neovim 0.11+** (runtime is
currently 0.12.5).

This directory is `user/.config/nvim` inside the dotfiles repo at `/home/ihxnan/Github/dotfiles`;
`~/.config/nvim` is a **symlink to here**, so edits land in the git repo — run git from the repo
root. There is **no build system, no tests, no CI, no linter**. The repo-root
`/home/ihxnan/Github/dotfiles/AGENTS.md` covers the wider dotfiles repo (installers, symlink
deployment, matugen/theming); `REASONIX.md` in this directory is the exhaustive working-notes
document — read it before non-trivial changes.

## Commands

- Run / inspect: `nvim .`; `:Lazy` (plugin UI), `:Mason` (LSP/tool installs), `:checkhealth`.
- Quick smoke test a change loads (from `AGENTS.md`): `nvim --headless +qa`.
- Compile-check every Lua file without loading plugins (run after editing `lua/config/`):

```sh
nvim --headless -u NONE -c 'lua for _,f in ipairs(vim.fn.glob("**/*.lua",false,true)) do local ok,e=loadfile(f); if not ok then error(f..": "..tostring(e)) end end print("all lua files compile OK")' -c 'qa!'
```

- Formatting is **manual** (auto-format-on-save is disabled): `<Tab>` or `<leader>f` (conform,
  `lsp_fallback = true`). CLI: `~/.local/share/nvim/mason/bin/stylua <file>` (no `.stylua.toml`;
  stylua comes from Mason, not a system install).
- **Side effect to expect:** a normal startup idempotently rewrites the clangd config
  (`~/.config/clangd/config.yaml`) — see `lua/plugins/mason.lua`.

## Architecture

Entry point `init.lua` requires `config.lazy`, `config.options`, `config.keymaps`.

**Config layer** (`lua/config/`, loaded at startup):
- `lazy.lua` — bootstraps lazy.nvim and auto-imports every `lua/plugins/*.lua` via `{ import = "plugins" }`;
  sets `mapleader`/`maplocalleader`.
- `options.lua` — global vim options, restore-cursor autocmd, NeoTree transparent highlights.
- `keymaps.lua` — all mappings + the C/C++/Python/CUDA run functions; calls `clipboard.lua`.
- `clipboard.lua` — exports `copy_all_with_info` (template inliner), `setup_system_clipboard()`,
  `setup_template_copy()`; `keymaps.lua` calls all.

**Plugin layer** (`lua/plugins/`, ~29 spec files, one per plugin, mostly lazy-loaded by
`event`/`ft`/`keys`). `lazy-lock.json` pins commits.

**LSP layer** (`lua/plugins/mason.lua`) — 7 servers registered with the 0.11+ API
(`vim.lsp.config` + `vim.lsp.enable`): `lua_ls`, `ts_ls`, `html`, `cssls`, `jsonls`, `pyright`,
`clangd`. `mason-tool-installer` auto-installs formatters/LSPs (black, isort, ruff, clang-format,
clangd, lua-language-server, stylua, shfmt, prettierd, ts/html/css/json language servers, htmlhint,
cmakelang, taplo). Server `cmd`s point at `~/.local/share/nvim/mason/bin/`.

**Filetype layer** (`after/ftplugin/cpp.lua`) — disables Treesitter indent, enables `cindent` with
Allman/Microsoft `cinoptions`.

**Formatter layer** (`lua/plugins/formatter.lua`) — conform.nvim; per-filetype formatter chains
(e.g. Python = isort→black at line-length 100; C/C++ = clang-format preferring a project
`.clang-format`).

## Cross-cutting conventions & gotchas

- **Run shortcuts** live in `keymaps.lua`: `rc/rd/rl/rp/ru`, `dp`, `cp/cd/ct`. The data
  file is `/tmp/data`. C/C++ builds use `g++ -O2 -fsanitize=address,undefined,leak` into a terminal split.
- **Style:** ASCII-art banner comment atop each config file, comments in Chinese, transparent
  backgrounds, 4-space expandtab indentation.
- **Not loaded by Neovim / ignore:** `lua/config/REASONIX.md` (unrelated C++ contest-template memory),
  `lua/config/test.py` (scratch), and `.reasonix/truncated-results/` (agent session artifacts, safe to ignore).
- `reasonix.toml` only configures the Reasonix agent's permissions/sandbox — no effect on Neovim.
- `options.lua` sets `foldmethod='indent'`, so the co-located `foldexpr='nvim_treesitter#foldexpr()'`
  does **not** take effect; folding is indent-based.
