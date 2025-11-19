return {
	"numToStr/Comment.nvim",
	event = "VeryLazy",
	config = function()
		require("Comment").setup()
		-- 插件会自动设置 `gcc` 和 `gc` 等快捷键，你原来的映射依然可以使用
		-- 或者，你也可以使用它提供的 Lua API 来设置映射，这更稳定
		local api = require("Comment.api")
		vim.keymap.set("n", "<C-_>", api.toggle.linewise.current, { desc = "Comment current line" })
		vim.keymap.set("v", "<C-_>", function()
			api.toggle.linewise(vim.fn.visualmode())
		end, { desc = "Comment selected lines" })
	end,
}
