return {
	{
		"folke/tokyonight.nvim",
		lazy = false, -- 启动时立即加载 colorscheme
		priority = 1000, -- 确保优先加载
		config = function()
			require("tokyonight").setup({
				style = "night", -- 可选: storm, night, day
				transparent = true, -- 是否透明背景
				terminal_colors = true,
			})
			vim.cmd("colorscheme tokyonight")
		end,
	},
}

