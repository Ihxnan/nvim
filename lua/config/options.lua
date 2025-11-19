local opt = vim.opt
local g = vim.g

-- 行号
opt.relativenumber = true
opt.number = true

-- 缩进
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

-- 光标行
opt.cursorline = true

-- 启用鼠标
opt.mouse:append("a")

-- 等待时间
vim.o.timeoutlen = 500

-- 系统剪贴板
opt.clipboard:append("unnamedplus")

-- 默认新窗口右和下
opt.splitright = true
opt.splitbelow = true

-- 搜索
opt.ignorecase = true
opt.smartcase = true

-- 外观
opt.termguicolors = true
opt.signcolumn = "yes"

-- 插件设置
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- vimwiki设置
opt.compatible = false
vim.cmd("filetype plugin on")
vim.cmd("syntax on")

-- 自动跳转到上次编辑的位置
vim.api.nvim_create_autocmd("BufReadPost", {
	pattern = "*",
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	callback = function()
		-- 已有的其他配置...
		vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "NONE" })
		vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "NONE" })
		vim.api.nvim_set_hl(0, "NeoTreeFloatBackground", { bg = "#1e1e1e" })

		vim.api.nvim_set_hl(0, "LeetCodeInfo", { bg = "NONE" })
		vim.api.nvim_set_hl(0, "LeetCodeQuestion", { bg = "NONE" })
		vim.api.nvim_set_hl(0, "LeetCodePopup", { bg = "#1e1e1e" })

		-- Bufferline 透明背景设置
		vim.api.nvim_set_hl(0, "BufferLineBackground", { bg = "NONE" }) -- 未激活缓冲区背景
		vim.api.nvim_set_hl(0, "BufferLineBufferVisible", { bg = "NONE" }) -- 可见但未激活缓冲区背景
		vim.api.nvim_set_hl(0, "BufferLineBufferSelected", { bg = "NONE" }) -- 选中缓冲区背景（通常会保留前景色突出显示）
		vim.api.nvim_set_hl(0, "BufferLineFill", { bg = "NONE" }) -- Bufferline 填充区域
		vim.api.nvim_set_hl(0, "BufferLineTabPageFill", { bg = "NONE" }) -- 标签页填充区域
	end,
})

-- 立即应用所有设置
vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "NONE" })
vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "NONE" })
vim.api.nvim_set_hl(0, "BufferLineBackground", { bg = "NONE" })
vim.api.nvim_set_hl(0, "BufferLineBufferVisible", { bg = "NONE" })
vim.api.nvim_set_hl(0, "BufferLineBufferSelected", { bg = "NONE" })
vim.api.nvim_set_hl(0, "BufferLineFill", { bg = "NONE" })
vim.api.nvim_set_hl(0, "BufferLineTabPageFill", { bg = "NONE" })

-- 工作目录自动切换
vim.o.autochdir = true

-- 折叠
opt.foldmethod = 'indent'
opt.foldexpr = 'nvim_treesitter#foldexpr()'
