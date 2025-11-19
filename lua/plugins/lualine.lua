return {
	"nvim-lualine/lualine.nvim",
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
