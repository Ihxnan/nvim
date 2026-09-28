return {
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"folke/tokyonight.nvim",
	},
	config = function()
		require("lualine").setup({
			options = {
				theme = "tokyonight",
			},
			sections = {
				lualine_c = {
					"filename",
					-- musicode 播放状态（仅在播放时显示）
					{
						function()
							return require("musicode").statusline()
						end,
						cond = function()
							local ok, status = pcall(function()
								return require("musicode").statusline()
							end)
							return ok and status ~= "" and status ~= "musicode: stopped"
						end,
						color = { fg = "#a8e6cf", gui = "italic" },
					},
					{
						"macro-recording",
						fmt = function()
							local reg = vim.fn.reg_recording()
							return reg ~= "" and string.format("[REC] @%s", reg) or ""
						end,
						-- 使用鲜明的蓝紫色 (#7d5bbe)
						color = { fg = "#7d5bbe", gui = "bold" },
						cond = function()
							return vim.fn.reg_recording() ~= ""
						end,
					},
				},
			},
		})
	end,
}
