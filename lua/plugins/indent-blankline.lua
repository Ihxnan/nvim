return {
	"lukas-reineke/indent-blankline.nvim",
	main = "ibl",
	opts = {
		-- 配置线条样式
		indent = { char = "│" },
		-- 结合treesitter优化层级识别
		scope = { enabled = true, show_start = false, show_end = false },
	},
}
