return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	config = function()
		local configs = require("nvim-treesitter.configs")
		configs.setup({
			ensure_installed = {
				"c",
				"cpp",
				"lua",
				"vim",
				"python",
				"html",
				"xml",
				"vue",
				"javascript",
				"typescript",
				"tsx",
				"markdown",
			},
			sync_install = true,
			auto_install = true,
			highlight = { enable = true },
			indent = { enable = false }, -- 关键：禁用 Treesitter 缩进
		})

		-- 针对 C/C++ 设置 cindent 和 cinoptions
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "c", "cpp" },
			callback = function()
				vim.opt_local.cindent = true
				vim.opt_local.cinoptions = "{0,m1,s1,C1,g0,w1,}0,:0,l1,N-s,t0,(0"
				vim.opt_local.shiftwidth = 4
				vim.opt_local.tabstop = 4
				vim.opt_local.expandtab = true
			end,
		})
	end,
}
