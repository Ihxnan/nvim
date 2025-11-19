return {
	-- 禁用 snacks.nvim 的 dashboard 避免冲突
	{ "folke/snacks.nvim", opts = { dashboard = { enabled = false } } },

	-- Alpha-nvim 启动界面核心配置
	{
		"goolord/alpha-nvim",
		event = "VimEnter",
		enabled = true,
		init = false,
		opts = function()
			local dashboard = require("alpha.themes.dashboard")
			-- 自定义 Logo（保留你的 ASCII 艺术）
			local logo = [[
    ✰   ✰   ✰   ✰   ✰   ✰   ✰   ✰   ✰   ✰   ✰
★  ╔═════════════════════════════════════════════╗ ★
   ██╗ ██╗  ██╗██╗  ██╗███╗   ██╗ █████╗ ███╗   ██╗
✰  ██║ ██║  ██║╚██╗██╔╝████╗  ██║██╔══██╗████╗  ██║✧
   ██║ ███████║ ╚███╔╝ ██╔██╗ ██║███████║██╔██╗ ██║
★  ██║ ██╔══██║ ██╔██╗ ██║╚██╗██║██╔══██║██║╚██╗██║★
   ██║ ██║  ██║██╔╝ ██╗██║ ╚████║██║  ██║██║ ╚████║
✰  ╚═╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═══╝✧
 ★  ╚════════════════════════════════════════════╝ ★
    ✰   ✰   ✰   ✰   ✰   ✰   ✰   ✰   ✰   ✰   ✰
      ]]

			-- 设置头部 Logo
			dashboard.section.header.val = vim.split(logo, "\n")

			-- 基础功能按钮（保留核心操作入口）
			dashboard.section.buttons.val = {
				dashboard.button("f", "  Find file", [[<cmd>lua require('telescope.builtin').find_files()<cr>]]),
				dashboard.button("c", "  Config", "<cmd> e ~\\AppData\\Local\\nvim\\lua\\config<cr>"),
				dashboard.button("p", "  Plugins", "<cmd> e ~\\AppData\\Local\\nvim\\lua\\plugins/<cr>"),
				dashboard.button("tc", "  cpp", "<cmd> e E:\\UserData\\Desktop\\WorkSpace\\Algorithm\\test.cpp<cr>"),
				dashboard.button("tp", "  python", "<cmd> E:\\UserData\\Desktop\\WorkSpace\\Algorithm\\test.py<cr>"),
				dashboard.button("a", "  Algorithm", "<cmd> e E:\\UserData\\Desktop\\WorkSpace\\Algorithm<cr>"),
				dashboard.button("l", "󰒲  Lazy", "<cmd> Lazy <cr>"),
				dashboard.button("h", "  Helath check", "<cmd> checkhealth <cr>"),
				dashboard.button("q", "  Quit", "<cmd> qa <cr>"),
			}

			-- 高亮样式配置
			for _, button in ipairs(dashboard.section.buttons.val) do
				button.opts.hl = "AlphaButtons"
				button.opts.hl_shortcut = "AlphaShortcut"
			end
			dashboard.section.header.opts.hl = "AlphaHeader"
			dashboard.section.buttons.opts.hl = "AlphaButtons"
			dashboard.section.footer.opts.hl = "AlphaFooter"
			dashboard.opts.layout[1].val = 0 -- 头部间距调整

			return dashboard
		end,
		config = function(_, dashboard)
			vim.api.nvim_set_hl(0, "AlphaShortcut", {
				fg = "#a855f7", -- 更亮的紫色快捷键，强化操作指引
				bg = "none",
				bold = true,
			})

			-- 基础初始化配置
			require("alpha").setup(dashboard.opts)

			-- 启动完成后显示插件加载统计
			vim.api.nvim_create_autocmd("User", {
				once = true,
				pattern = "LazyVimStarted",
				callback = function()
					local stats = require("lazy").stats()
					local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
					dashboard.section.footer.val = "⚡ Neovim loaded "
						.. stats.loaded
						.. "/"
						.. stats.count
						.. " plugins in "
						.. ms
						.. "ms"
					pcall(vim.cmd.AlphaRedraw)
				end,
			})
		end,
	},
}
