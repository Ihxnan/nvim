# CODEBUDDY.md

This file provides guidance to CodeBuddy Code when working with code in this repository.

## What this is

Personal Neovim config in Lua, plugin-managed by **lazy.nvim** — a config repo, not a build
project. Leader = `Space`, local leader = `\`. Targets **Neovim 0.11+** (runtime currently
0.12.x).

The repo is standalone: `link.sh` symlinks this directory to `~/.config/nvim` (idempotent;
backs up an existing target), so edits land directly in git — run git from the repo root.
There is **no build system, no tests, no CI, no linter**. `REASONIX.md` is the longer
working-notes document; it can lag behind the code, so trust the source when they disagree.

## Commands

- Run / inspect: `nvim .`; `:Lazy` (plugin UI), `:Mason` (LSP/tool installs), `:checkhealth`.
- Smoke test that the config loads: `nvim --headless +qa`.
- Compile-check every Lua file without loading plugins (run after editing `lua/config/`):

```sh
nvim --headless -u NONE -c 'lua for _,f in ipairs(vim.fn.glob("**/*.lua",false,true)) do local ok,e=loadfile(f); if not ok then error(f..": "..tostring(e)) end end print("all lua files compile OK")' -c 'qa!'
```

- Formatting is **manual** (auto-format-on-save is disabled): `<Tab>` or `<leader>f` (conform,
  `lsp_fallback = true`). CLI: `~/.local/share/nvim/mason/bin/stylua <file>` (no `.stylua.toml`;
  stylua comes from Mason, not a system install).
- **Side effect to expect:** every normal startup idempotently rewrites
  `~/.config/clangd/config.yaml` — see `lua/plugins/mason.lua`.

## Architecture

`init.lua` disables built-in netrw **before** lazy.nvim (ordering matters, otherwise E117 on
VimEnter), then requires `config.lazy`, `config.options`, `config.keymaps`, and finally starts
`require("config.companion").setup()`.

**Config layer** (`lua/config/`, loaded at startup):
- `lazy.lua` — bootstraps lazy.nvim, auto-imports every `lua/plugins/*.lua` via `{ import = "plugins" }`,
  sets `mapleader`/`maplocalleader`.
- `options.lua` — global options, `BufReadPost` restore-cursor autocmd, NeoTree transparent
  highlights, `autochdir`, indent folding.
- `keymaps.lua` — general mappings (insert/terminal/visual/window/buffer/search/editing) plus
  `ru`/`rk`/`dp`/`cd`/`cp`/`ct`; requires `clipboard.lua`, `paths.lua` and `run.lua`.
- `run.lua` — the run/judge engine (`run_code`, `append_multi_tests`, `run_script`, colored diff,
  RE hinting) and the `rc`/`rd`/`rp`/`rn`/`rl` mappings; exports `e`/`C`/`run_script`/
  `paste_to_data` for `keymaps.lua` (`rk`, `cp`).
- `paths.lua` — single source of truth for per-problem data paths (`parts`, `in_file`,
  `out_file`, `txt_file`, `clear_tests`, `ensure_dir`); shared with `companion.lua`.
- `companion.lua` — Competitive Companion listener on `127.0.0.1:27121`; decodes the problem JSON,
  calls `paths.clear_tests()` to drop that file's previous samples, then writes `<名>.N.in` /
  `<名>.N.out` for the **current buffer's** derived path.
- `clipboard.lua` — `copy_all_with_info()` (template inliner) plus `setup_system_clipboard()` /
  `setup_template_copy()`, both called from `keymaps.lua`.

**Plugin layer** (`lua/plugins/`, 28 spec files, one per plugin, mostly lazy-loaded by
`event`/`ft`/`keys`). `lazy-lock.json` pins commits.

**LSP layer** (`lua/plugins/mason.lua`) — 7 servers registered with the 0.11+ API
(`vim.lsp.config` + `vim.lsp.enable`): `lua_ls`, `ts_ls`, `html`, `cssls`, `jsonls`, `pyright`,
`clangd`; `mason-tool-installer` auto-installs formatters/LSPs (black, isort, ruff, clang-format,
stylua, shfmt, prettierd, htmlhint, cmakelang, taplo…). Server `cmd`s point at
`~/.local/share/nvim/mason/bin/`.

**Debug layer** (`lua/plugins/dap.lua`) — nvim-dap + dap-ui + virtual-text with the Mason-installed
`codelldb` adapter. Launching (`<leader>dc`) first compiles the current buffer with
`g++/gcc -g -O0 -DIHXNAN` through `program = build` (compiler errors land in quickfix and cancel
the session). Keys follow VS Code: `F5` start/continue, `F9` breakpoint, `F10` step over,
`F11` step into, `S-F11` step out, `S-F5` terminate; `<leader>du` toggles the UI and
`<leader>dB` sets a conditional breakpoint. (`F6` opens the cwd in VS Code — `F5` used to do that.)

**Filetype layer** (`after/ftplugin/cpp.lua`) — disables Treesitter indent, enables `cindent` with
Allman/Microsoft `cinoptions`.

**Formatter layer** (`lua/plugins/formatter.lua`) — conform.nvim; per-filetype chains
(Python = isort→black at line-length 100; C/C++ = clang-format preferring a project `.clang-format`).

## Run / judge workflow (the part that needs several files to understand)

Data files are derived from the **source file path**, not stored in a fixed place:
`~/Data/<源文件父目录名>/<源文件名>.N.in|.N.out` (plugin samples, numbered) and `…/<名>.txt`
(manual input). Derivation lives only in `paths.lua`; `companion.lua` writes, `run.lua` reads.

- `rc` — judge all plugin samples (`.N.in` vs `.N.out`), no `-DIHXNAN`.
- `rd` — same judging as `rc` but with `-DIHXNAN`; it bails out with a hint when no `.1.in`
  exists (running without samples would block on stdin).
- Both are wrapped in `timeout` (`TIME_LIMIT` in `run.lua`, 2 s per sample): exit code 124
  is reported as `Time Limit Exceeded (TLE)` and skips the diff. The per-run exit code comes from
  `${PIPESTATUS[0]}` — `tee` would otherwise always report 0. `paths.clear_tests()` is still available
  for manual resets (`:lua require("config.paths").clear_tests()`), it is no longer bound to any key.
- `rn` — run with the manual `<名>.txt` (no judging); `rp` — paste clipboard into `<名>.txt`, then run.
- `rk` — compile with `-g -O0 -DIHXNAN` and open `gdb` in the terminal split; `rl` — local
  debug C/C++ with `-DIHXNAN`; `ru` — CUDA/C/C++ via `nvcc`.
- `cp` — overwrite `<名>.txt` from clipboard; `cd` — open `<名>.txt`; `ct` — open `~/Github/Template`.

Implementation details worth keeping: commands are written to `/tmp/ihxnan_run.sh` and executed by
`vsplit | terminal bash <script>` (avoids Ex line-length limits and `%`/`<` escaping); judging
outputs go to `/tmp/ihxnan_run.out` (stdout for diff) and `/tmp/ihxnan_run.raw` (merged stream);
with `-DIHXNAN` program output is wrapped in `\033[35m`, which is how debug lines are filtered
out of the judged stdout. Diff comparisons strip ANSI codes and trailing whitespace first.

## Conventions & gotchas

- **Style:** ASCII-art banner comment atop each config file, comments in Chinese, transparent
  backgrounds, 4-space expandtab indentation.
- **Netrw stays disabled in `init.lua` first** — moving it after lazy starts netrw and breaks startup.
- `options.lua` sets `foldmethod='indent'`, so the co-located `foldexpr='nvim_treesitter#foldexpr()'`
  does **not** take effect; folding is indent-based.
- `autochdir` is on, so relative paths in mappings/commands follow the current file's directory —
  prefer absolute paths (`vim.fn.expand("%:p")`, `paths.lua`) in run commands.
- `reasonix.toml` only configures the Reasonix agent's permissions/sandbox — no effect on Neovim.
- `snippets/` holds VS Code–style snippet JSON (cmake, cpp, html, python); they are opened/browsed
  from the alpha dashboard via Telescope, not auto-loaded into completion.
