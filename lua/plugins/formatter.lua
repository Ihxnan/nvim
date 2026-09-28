return {
	-- ====================== 统一格式化引擎（conform.nvim） ======================
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<Tab>",
				function()
					require("conform").format({ async = true, lsp_fallback = true })
				end,
				desc = "格式化当前文件",
			},
			{
				"<leader>f",
				function()
					require("conform").format({ async = true, lsp_fallback = true })
				end,
				desc = "格式化当前文件",
			},
		},
		opts = {
			-- 保存时自动格式化已禁用，仅保留手动格式化（<Tab> / <leader>f）

			-- ========== 按文件类型配置格式化器 ==========
			formatters_by_ft = {
				---------- Python（isort 排序 → black 格式化，依次执行） ----------
				python = { "isort", "black" },

				---------- Lua ----------
				lua = { "stylua" },

				---------- C/C++ ----------
				c = { "clang-format" },
				cpp = { "clang-format" },
				proto = { "clang-format" },

				---------- Shell ----------
				sh = { "shfmt" },
				bash = { "shfmt" },
				zsh = { "shfmt" },

				---------- JS/TS（优先 prettierd，不存在则用 prettier） ----------
				javascript = { "prettierd", "prettier", stop_after_first = true },
				typescript = { "prettierd", "prettier", stop_after_first = true },
				javascriptreact = { "prettierd", "prettier", stop_after_first = true },
				typescriptreact = { "prettierd", "prettier", stop_after_first = true },

				---------- 前端标记语言（同上） ----------
				json = { "prettierd", "prettier", stop_after_first = true },
				jsonc = { "prettierd", "prettier", stop_after_first = true },
				html = { "prettierd", "prettier", stop_after_first = true },
				css = { "prettierd", "prettier", stop_after_first = true },
				scss = { "prettierd", "prettier", stop_after_first = true },
				less = { "prettierd", "prettier", stop_after_first = true },

				---------- 文档/配置 ----------
				markdown = { "prettierd", "prettier", stop_after_first = true },
				yaml = { "prettierd", "prettier", stop_after_first = true },
				toml = { "taplo" },

				---------- 构建系统 ----------
				cmake = { "cmake-format" },
			},

			-- ========== 格式化器详细选项 ==========
			formatters = {
				----- Python -----
				black = {
					prepend_args = { "--line-length", "100" },
				},
				isort = {
					prepend_args = {
						"--profile",
						"black",
						"--line-length",
						"100",
					},
				},

				----- C/C++（优先读取项目 .clang-format，找不到则回退到 ~/.clang-format） -----
				["clang-format"] = {
					prepend_args = function(_, ctx)
						local found = vim.fn.findfile(".clang-format", ctx.dirname .. ";")
						if found ~= "" then
							return {}
						end
						return { "--style=file:" .. vim.fn.expand("~/.clang-format") }
					end,
				},

				----- Prettier（优先使用 daemon 版本，性能更好） -----
				prettier = {
					prepend_args = function(_, ctx)
						local ft = vim.bo[ctx.buf].filetype
						-- Markdown/YAML 等文档语言不适用 JS 专用选项
						if ft == "markdown" or ft == "yaml" then
							return { "--stdin-filepath", ctx.filename, "--print-width", "100", "--tab-width", "4" }
						end
						return {
							"--stdin-filepath", ctx.filename,
							"--print-width", "100",
							"--tab-width", "4",
							"--single-quote",
							"--trailing-comma", "all",
						}
					end,
					stdin = true,
				},
				prettierd = {
					-- prettierd 参数解析要求 --key=value 格式（不能用 --key value 分开传）
					args = function(_, ctx)
						local ft = vim.bo[ctx.buf].filetype
						local base = { "--stdin-filepath", ctx.filename }
						if ft == "markdown" or ft == "yaml" then
							vim.list_extend(base, { "--print-width=100", "--tab-width=4" })
						else
							vim.list_extend(base, {
								"--print-width=100",
								"--tab-width=4",
								"--single-quote",
								"--trailing-comma=all",
							})
						end
						return base
					end,
					stdin = true,
				},

				----- Shell -----
				shfmt = {
					prepend_args = { "-i", "4", "-ci" }, -- 4空格缩进，switch case 缩进
				},

				----- CMake -----
				["cmake-format"] = {
					prepend_args = {
						"--tab-size",
						"4",
						"--line-width",
						"100",
					},
				},
			},
		},
	},
}
