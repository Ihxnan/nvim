return {
	"stevearc/conform.nvim",
	dependencies = {
		"williamboman/mason.nvim",
	},
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "isort", "black" },
			rust = { "rustfmt", lsp_format = "fallback" },
			toml = { "taplo" },
			-- 这里将clang_format改为clang-format
			cpp = { "clang-format" },
			c = { "clang-format" },
		},
		formatters = {
			-- 这里也将clang_format改为clang-format
			["clang-format"] = {
				args = {
					"--style=Microsoft",
					"--fallback-style=Microsoft",
				},
			},
		},
	},
	config = function(_, opts)
		require("mason").setup()
		require("conform").setup(opts)

		local function get_ensure_installed_for_ft(ft, ft_table)
			local tools = {}
			local cfg = ft_table[ft]
			if type(cfg) == "table" then
				for _, item in ipairs(cfg) do
					if type(item) == "string" then
						tools[item] = true
					end
				end
			elseif type(cfg) == "string" then
				tools[cfg] = true
			end
			local list = {}
			for tool, _ in pairs(tools) do
				table.insert(list, tool)
			end
			return list
		end

		vim.keymap.set({ "n", "v" }, "<Tab>", function()
			local ft = vim.bo.filetype
			local tools = get_ensure_installed_for_ft(ft, opts.formatters_by_ft)
			local registry = require("mason-registry")
			for _, tool in ipairs(tools) do
				if not registry.is_installed(tool) then
					vim.notify("正在安装格式化工具: " .. tool, vim.log.levels.INFO)
					registry.get_package(tool):install()
				end
			end
			require("conform").format({
				async = true,
				lsp_fallback = true,
			})
		end, { desc = "代码格式化（自动安装缺失工具，C++默认微软风格）" })
	end,
}
