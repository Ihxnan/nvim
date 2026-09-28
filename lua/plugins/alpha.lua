return {
	-- 禁用 snacks.nvim 的 dashboard 避免冲突
	{
		"folke/snacks.nvim",
		priority = 1000,
		opts = { dashboard = { enabled = false }, notifier = { enabled = false } },
	},

	-- Alpha-nvim 启动界面
	{
		"goolord/alpha-nvim",
		event = "VimEnter",
		opts = function()
			local dashboard = require("alpha.themes.dashboard")
			local config_dir = vim.fn.stdpath("config")
			local snippet_dir = config_dir .. "/snippets"

			local logo = [[




    ✰   ✰   ✰   ✰   ✰   ✰   ✰   ✰   ✰   ✰   ✰   ✰
★  ╔═════════════════════════════════════════════╗ ★
   ██╗ ██╗  ██╗██╗  ██╗███╗   ██╗ █████╗ ███╗   ██╗
✰  ██║ ██║  ██║╚██╗██╔╝████╗  ██║██╔══██╗████╗  ██║✧
   ██║ ███████║ ╚███╔╝ ██╔██╗ ██║███████║██╔██╗ ██║
★  ██║ ██╔══██║ ██╔██╗ ██║╚██╗██║██╔══██║██║╚██╗██║★
   ██║ ██║  ██║██╔╝ ██╗██║ ╚████║██║  ██║██║ ╚████║
✰  ╚═╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═══╝✧
 ★  ╚════════════════════════════════════════════╝ ★
    ✰   ✰   ✰   ✰   ✰   ✰   ✰   ✰   ✰   ✰   ✰   ✰
      ]]

			dashboard.section.header.val = vim.split(logo, "\n")

			-- 常用操作按钮
			dashboard.section.buttons.val = {
				dashboard.button("f", "  Find file", "<cmd>Telescope find_files<cr>"),
				dashboard.button("r", "  Recent files", "<cmd>Telescope oldfiles<cr>"),
				dashboard.button("n", "  New file", function()
					local name = vim.fn.input("File: ")
					if name and name ~= "" then
						vim.cmd("e " .. name)
					end
				end),
				dashboard.button(
					"c",
					"  Config",
					"<cmd>Telescope find_files search_dirs=" .. config_dir .. "/lua/config<cr>"
				),
				dashboard.button(
					"p",
					"  Plugins",
					"<cmd>Telescope find_files search_dirs=" .. config_dir .. "/lua/plugins<cr>"
				),
				dashboard.button(
					"s",
					"  Snippets",
					"<cmd>Telescope find_files search_dirs=" .. snippet_dir .. "<cr>"
				),
				dashboard.button("tc", "  C++", "<cmd>e ~/WorkSpace/CPP/test.cpp<cr>"),
				dashboard.button("tp", "  Python", "<cmd>e ~/WorkSpace/Python/test.py<cr>"),
				dashboard.button("td", "  MarkDown", "<cmd>e ~/WorkSpace/MD/tmp.md<cr>"),
				dashboard.button("l", "󰒲  Lazy", "<cmd>Lazy<cr>"),
				dashboard.button("q", "  Quit", "<cmd>qa<cr>"),
			}

			-- 统一高亮
			for _, button in ipairs(dashboard.section.buttons.val) do
				button.opts.hl = "AlphaButtons"
				button.opts.hl_shortcut = "AlphaShortcut"
			end
			dashboard.section.header.opts.hl = "AlphaHeader"
			dashboard.section.buttons.opts.hl = "AlphaButtons"
			dashboard.section.footer.opts.hl = "AlphaFooter"
			dashboard.opts.layout[1].val = 0

			return dashboard
		end,
		config = function(_, dashboard)
			vim.api.nvim_set_hl(0, "AlphaShortcut", {
				fg = "#a855f7",
				bg = "none",
				bold = true,
			})

			require("alpha").setup(dashboard.opts)

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
