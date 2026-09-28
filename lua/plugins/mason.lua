return {
    {
        "williamboman/mason.nvim",
        build = ":MasonUpdate",
        config = true,
    },

    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        dependencies = { "williamboman/mason.nvim" },
        opts = {
            ensure_installed = {
                -- Python
                "black",
                "isort",
                "ruff",              -- 超快 lint + format（可选替代 black）
                "pyright",

                -- C/C++
                "clang-format",
                "clangd",

                -- Lua
                "lua-language-server",
                "stylua",

                -- Shell
                "shfmt",

                -- JS/TS/Web（prettierd 是 prettier 的守护进程版，启动更快）
                "prettierd",
                "typescript-language-server",
                "html-lsp",
                "css-lsp",
                "json-lsp",
                "htmlhint",

                -- 构建系统
                "cmakelang",          -- 提供 cmake-format 命令（Mason 包名不同）

                -- 配置文件
                "taplo",             -- TOML 格式化（Rust 实现，速度极快）
            },
            auto_update = false,
            run_on_start = true,
            start_delay = 1500,
        },
    },

    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
        },
        config = function()
            local ok, mason_lsp = pcall(require, "mason-lspconfig")
            if not ok then return end

            mason_lsp.setup({})
            local mason_path = vim.fn.glob(vim.fn.stdpath("data") .. "/mason/")

            local function mason_cmd(name, ...)
                local cmd = { mason_path .. "bin/" .. name }
                for _, extra in ipairs({ ... }) do
                    cmd[#cmd + 1] = extra
                end
                return cmd
            end

            -- 新版 LSP 配置（Neovim 0.11+）
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities.textDocument.completion.completionItem.snippetSupport = true

            local on_attach = function(client, bufnr)
                local opts = { buffer = bufnr, noremap = true, silent = true }

                vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "重命名" }))
                vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "代码动作" }))
                vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "引用" }))

                -- ✅ 新版诊断跳转（无废弃警告）
                vim.keymap.set("n", "<leader>]", function()
                    vim.diagnostic.jump({ count = 1, float = true })
                end, vim.tbl_extend("force", opts, { desc = "下一个错误" }))

                vim.keymap.set("n", "<leader>[", function()
                    vim.diagnostic.jump({ count = -1, float = true })
                end, vim.tbl_extend("force", opts, { desc = "上一个错误" }))

                vim.keymap.set("n", "<leader>dl", vim.diagnostic.setloclist, vim.tbl_extend("force", opts, { desc = "错误列表" }))
                vim.keymap.set("n", "<leader>dh", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "悬浮错误" }))

                -- ========== Python 专用增强 ==========
                if vim.bo[bufnr].filetype ~= "python" then return end

                -- 通用 LSP 快捷键（所有 LSP 服务器都适用）
                vim.keymap.set("n", "gI", vim.lsp.buf.implementation,
                    vim.tbl_extend("force", opts, { desc = "跳转到实现" }))

                if client.name == "pyright" then
                    -- 自动检测虚拟环境路径
                    local venv_paths = {
                        vim.fn.getcwd() .. "/.venv",
                        vim.fn.getcwd() .. "/venv",
                        vim.fn.getcwd() .. "/.env",
                        -- pipenv 虚拟环境
                        vim.fn.expand("~/.local/share/virtualenvs/*"),
                    }
                    local venv = ""
                    for _, path in ipairs(venv_paths) do
                        if vim.fn.isdirectory(path) == 1 then
                            venv = path
                            break
                        end
                    end

                    client:notify("workspace/didChangeConfiguration", {
                        settings = {
                            python = {
                                analysis = {
                                    typeCheckingMode = "basic",
                                    autoSearchPaths = true,
                                    useLibraryCodeForTypes = true,
                                    diagnosticMode = "workspace",
                                    reportMissingImports = "warning",
                                    reportMissingTypeStubs = false,
                                    reportUnusedVariable = "warning",
                                    reportUnusedImport = "warning",
                                    reportGeneralTypeIssues = "warning",
                                    venvPath = venv ~= "" and vim.fn.fnamemodify(venv, ":h") or "",
                                    venv = venv ~= "" and vim.fn.fnamemodify(venv, ":t") or "",
                                },
                            },
                        },
                    })

                    -- Python 专用快捷键
                    vim.keymap.set("n", "gT", vim.lsp.buf.type_definition,
                        vim.tbl_extend("force", opts, { desc = "Python: 跳转到类型定义" }))
                end
            end

            -- 服务器配置（新版格式）
            local servers = {
                lua_ls = {
                    cmd = mason_cmd("lua-language-server"),
                    on_attach = on_attach,
                    capabilities = capabilities,
                    settings = {
                        Lua = {
                            runtime = { version = "LuaJIT" },
                            diagnostics = { globals = { "vim" } },
                            workspace = { checkThirdParty = false },
                        },
                    },
                },
                ts_ls = {
                    cmd = mason_cmd("typescript-language-server", "--stdio"),
                    on_attach = on_attach,
                    capabilities = capabilities,
                },
                html = {
                    cmd = mason_cmd("vscode-html-language-server", "--stdio"),
                    on_attach = on_attach,
                    capabilities = capabilities,
                },
                cssls = {
                    cmd = mason_cmd("vscode-css-language-server", "--stdio"),
                    on_attach = on_attach,
                    capabilities = capabilities,
                },
                jsonls = {
                    cmd = mason_cmd("vscode-json-language-server", "--stdio"),
                    on_attach = on_attach,
                    capabilities = capabilities,
                },
                pyright = {
                    cmd = mason_cmd("pyright-langserver", "--stdio"),
                    on_attach = on_attach,
                    capabilities = capabilities,
                },
                clangd = {
                    cmd = mason_cmd("clangd"),
                    on_attach = on_attach,
                    capabilities = capabilities,
                },
            }

            -- ========== clangd：C++20 fallback 配置（同步到官方 YAML） ==========
            -- clangd 22 已移除 --fallback-flags 命令行参数（传了会 exit 1），
            -- 改用官方 YAML 配置：全局生效，无 compile_commands.json（fallback）时按 C++20 解析，
            -- 解决 std::source_location 等 C++20 类型的误报。
            -- 注意：CompileFlags.Add 也会附加到 compile_commands.json 提供的命令上。
            -- 每次启动幂等同步到 ~/.config/clangd/config.yaml（纳入 dotfiles 管理）。
            local clangd_cfg_body = [==[
# 由 nvim 配置自动生成（lua/plugins/mason.lua）
# 全局生效：所有项目按 C++20 解析（无 compile_commands.json 时尤其必要）
CompileFlags:
  Add: -std=gnu++20
]==]
            local clangd_cfg_path = vim.fn.expand("~/.config/clangd/config.yaml")
            local exists = vim.fn.filereadable(clangd_cfg_path) == 1
            local same = exists and vim.fn.join(vim.fn.readfile(clangd_cfg_path), "\n") == clangd_cfg_body
            if not same then
                vim.fn.mkdir(vim.fn.fnamemodify(clangd_cfg_path, ":h"), "p")
                vim.fn.writefile(vim.split(clangd_cfg_body, "\n", { plain = true }), clangd_cfg_path)
            end

            -- ✅ 新版启动方式（无废弃警告）
            for name, config in pairs(servers) do
                vim.lsp.config(name, config)
                vim.lsp.enable(name)
            end
        end,
    },
}
