# Neovim Config — Working Knowledge

Personal full-IDE Neovim config in Lua, plugin-managed by `lazy.nvim`; a dotfiles
repo, not a build project. Leader = space, local leader = `\`. Targets Neovim 0.11+
(当前 runtime 0.12.5)。本目录是 dotfiles 仓库 `/home/ihxnan/Github/dotfiles` 内的 `user/.config/nvim`
（`~/.config/nvim` 是指向它的 symlink），因此改动会直接进入该仓库；git 操作在仓库根执行。

## Project

- Entry point `init.lua`: `require("config.lazy"), config.options, config.keymaps`.
- `lua/config/lazy.lua` bootstraps lazy.nvim and auto-imports every `lua/plugins/*.lua` spec.

## Stack

- **lazy.nvim** — plugin loader (auto-discovers `lua/plugins/`); `lazy-lock.json` pins commits.
- **nvim-treesitter** + **nvim-ts-autotag** — syntax trees (fold, highlight, autotag).
- **mason.nvim** + **mason-tool-installer.nvim** + **nvim-lspconfig** — LSP/format tooling gateway.
- **blink.cmp** — completion (v1.x, preset `none`; accept with `<C-y>`).
- **tokyonight** (transparent), **alpha-nvim** (dashboard; disables snacks dashboard), **lualine** (musicode + macro), **bufferline**, **which-key**.
- **neo-tree** v3.x (replaces netrw), **telescope** (transparent), **flash**, **Comment.nvim**, **nvim-autopairs**, **indent-blankline** (ibl), **mini.icons**, **noice** + **nui**, **toggleterm**, **suda** (sudo write), **vim-fetch**, **vim-table-mode**.
- Markdown: **render-markdown**, **live-preview** (chromium), **image.nvim** (kitty backend).
- **conform.nvim** (formatting), **gitsigns**, **opencode.nvim**.

## Layout

| Path | Purpose |
|------|---------|
| `init.lua` | Entry point — requires `config.lazy`, `config.options`, `config.keymaps` |
| `lua/config/` | Core: `lazy.lua`, `options.lua`, `keymaps.lua`, `clipboard.lua` |
| `lua/plugins/` | One `.lua` file per plugin spec (29 files), discovered by `{ import = "plugins" }` |
| `after/ftplugin/cpp.lua` | C++ overrides — disables Treesitter indent, Allman/Microsoft `cinoptions` |
| `snippets/` | VS Code–style snippets (cmake, cpp, html, python) |
| `lazy-lock.json` | Lockfile pinning plugin commits |
| `reasonix.toml` | Reasonix 权限/沙箱配置（见 Notes） |
| `lua/config/test.py`, `.reasonix/` | Scratch — not loaded by Neovim |

## Commands

- No build/test/lint — pure config. Run with `nvim .`; 插件 UI `:Lazy`，LSP/tool 安装 `:Mason`，健康检查 `:checkhealth`。
- Lua 语法校验（不加载插件，改完 config 后跑；输出 `all lua files compile OK`）：
  `nvim --headless -u NONE -c 'lua for _,f in ipairs(vim.fn.glob("**/*.lua",false,true)) do local ok,e=loadfile(f); if not ok then error(f..": "..tostring(e)) end end print("all lua files compile OK")' -c 'qa!'`
- Format inside nvim with `<Tab>` or `<leader>f` (conform, `lsp_fallback = true`); CLI 可用 `~/.local/share/nvim/mason/bin/stylua <file>`（仓库无 `.stylua.toml`，stylua 无独立安装，由 Mason 提供）。
- 副作用注意：正常启动 nvim 会幂等重写 clangd 配置（`~/.config/clangd/config.yaml`，见 `lua/plugins/mason.lua`）。

## Architecture

- **Config layer** (`lua/config/`, loaded at startup):
  - `lazy.lua` — lazy.nvim bootstrap + `{ import = "plugins" }`；设置 `mapleader`/`maplocalleader`。
  - `options.lua` — global vim options; `BufReadPost` restore-cursor autocmd; NeoTree transparent highlights; `autochdir`; indent-based fold.
  - `keymaps.lua` — all mappings + code-run functions; requires `clipboard.lua`.
  - `clipboard.lua` — exports `copy_all_with_info` (inliner) plus `setup_system_clipboard()` / `setup_template_copy()`; `keymaps.lua` calls both.
- **Plugin layer** (`lua/plugins/`) — 29 spec files, mostly lazy-loaded by `event`/`ft`/`keys`.
- **LSP layer** (`lua/plugins/mason.lua`) — 7 servers via `vim.lsp.config` + `vim.lsp.enable` (0.11+ API): `lua_ls`, `ts_ls`, `html`, `cssls`, `jsonls`, `pyright`, `clangd`（cmd 指向 `~/.local/share/nvim/mason/bin/`）。Writes `~/.config/clangd/config.yaml` with `-std=gnu++20` fallback. Mason auto-installs (via `mason-tool-installer`): black, isort, ruff, clang-format, clangd, lua-language-server, stylua, shfmt, prettierd, typescript-language-server, html-lsp, css-lsp, json-lsp, htmlhint, cmakelang, taplo.
- **Filetype layer** (`after/ftplugin/cpp.lua`) — Treesitter indent off, `cindent` + Allman `cinoptions`.

## Conventions

- **Escape**: `jk` in insert/terminal modes; `ii` in visual mode.
- **Windows**: nav `<C-h/j/k/l>` in n/i/t modes; `<leader>wv` horizontal split, `<leader>wh` vertical split; move `gw{h,j,k,l}`; close `gwd`/`gwo`; resize `<M-=>`/`<M-->`.
- **Buffers**: `H`/`L` save-then-cycle tabs (bufferline); `gbh`/`gbl` prev/next; `gbd` delete; `gbo` close others.
- **Run shortcuts**: `rc` = clipboard→`/tmp/data` + copy full code + run (no macro); `rl` local debug (`-DIHXNAN`); `rd` run with data (`-DIHXNAN`); `rp` paste+run; `ru` CUDA/C/C++ (`nvcc -arch=sm_89`); `dp` dp tool; `cp` paste clipboard→`/tmp/data`; `cd` open `/tmp/data`; `ct` open `~/Github/Template`. C/C++ builds with `g++ -O2 -fsanitize=address,undefined,leak` into a `vsplit` terminal.
- **HTML preview**: `gmp` start / `gmc` close (LivePreview).
- **LSP**: `<leader>rn` rename, `<leader>ca` action, `gr` references, `gI` implementation, `gT` type def (Python only), `<leader>]`/`<leader>[` diagnostic jump, `<leader>dl`/`<leader>dh` diagnostics.
- **Format is MANUAL** — auto-format on save is disabled in `lua/plugins/formatter.lua`; use `<Tab>` or `<leader>f`.
- **Clipboard**: `unnamedplus`; `"+` register. Normal `<C-x>`/`<C-c>`/`<C-v>`, `<C-a><C-c>` copy all, `<C-a><C-i>` inline template + copy; visual `<C-c>` copies.
- **Terminals/tools**: `<leader>t` vertical fish terminal, `<leader>s` horizontal, `<leader>i` reasonix, `<A-t>` toggleterm, `Ctrl+g` lazygit tab, `F5` open dir in VS Code.
- **Search/nav**: `<leader>ff` telescope files; `n`/`N` auto-center (`nzz`/`Nzz`); `<leader>nh` clear highlight; `j`/`k` = `gj`/`gk`; `J`/`K` jump 5 lines.
- **Files/git**: `<leader>e` toggle neo-tree; gitsigns for gutter/blame/hunks.
- **Save**: `<C-S>` normal mode, `<C-s>` insert mode.
- **Style**: ASCII-art banner comment at top of each config file; comments in Chinese; transparent backgrounds (tokyonight/neo-tree/telescope); `tabstop=shiftwidth=softtabstop=4` + `expandtab`.

## Notes

- `lua/config/REASONIX.md` is unrelated Reasonix memory（C++ 竞赛模板；同目录 `test.py` 是依赖 `ihxnan` 包的临时脚本，可随时删除）— not loaded by Neovim.
- `.reasonix/truncated-results/`（根目录与 `lua/plugins/` 下各一份）是 agent 会话产物，可忽略/删除。
- `reasonix.toml` — `[permissions] allow = []`，`[sandbox] allow_write = ["${HOME}/.config/Code/User"]`。
- `options.lua` 设 `foldmethod='indent'`，因此同一文件里的 `foldexpr='nvim_treesitter#foldexpr()'` 实际不生效（折叠行为本质是 indent 折叠）。
