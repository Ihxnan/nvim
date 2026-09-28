return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = "markdown",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-mini/mini.nvim", -- for mini.icons
	},
	---@module 'render-markdown'
	---@type render.md.UserConfig
	opts = {
		-- 文件类型：仅对 Markdown 及相关文件启用
		file_types = { "markdown", "norg", "rmd", "org", "vimwiki", "pandoc" },
		-- ============ 渲染模块 ============

		-- 标题：用彩色高亮代替 #
		heading = {
			enabled = true,
			-- 使用背景色块加图标
			icons = { "󰎤 ", "󰎧 ", "󰎪 ", "󰎭 ", "󰎱 ", "󰎳 " },
			position = "inline",
			sign = true,
			width = "block",
			left_pad = 1,
			right_pad = 2,
		},

		-- 代码块：带背景底色 + 语言标签
		code = {
			enabled = true,
			style = "full_width",           -- 块状填充
			position = "left",
			language_pad = 1,
			language_icon = true,
			border = "thin",
			above = "▔",
			below = "▁",
		},

		-- 分隔线：将 --- 渲染为一条线
		dash = {
			enabled = true,
			width = "full",
		},

		-- 无序列表：自定义圆点
		bullet = {
			enabled = true,
			icons = { "●", "○", "◆", "◇" },
		},

		-- 复选框：渲染为真实复选框外观
		checkbox = {
			enabled = true,
			position = "inline",
			unchecked = {
				icon = " ",
				highlight = "RenderMarkdownUnchecked",
			},
			checked = {
				icon = " ",
				highlight = "RenderMarkdownChecked",
			},
			-- custom = {},  -- 默认已有 [-] → 󰥔 ，有需要再扩展
		},

		-- 表格：对齐列宽
		table = {
			enabled = true,
			style = "full_width",
		},

		-- 链接：显示图标，可自定义域名图标
		link = {
			enabled = true,
			-- 超链接图标
			hyperlink = "󰌹 ",
			-- 图片链接图标
			image = "󰥶 ",
			-- 邮件链接图标
			email = "󰀓 ",
			-- 脚注
			footnote = {
				enabled = true,
				icon = "󰯔 ",
				superscript = true,
			},
			-- WikiLink（[[]]）
			wiki = {
				enabled = true,
				icon = "󱗖 ",
			},
			-- 自定义域名图标
			custom = {
				github = { pattern = "github%.com", icon = "󰊤 " },
				youtube = { pattern = "youtube%.com", icon = "󰗃 " },
			},
		},

		-- 引用块 / Callout（使用默认配置，已涵盖 GitHub + Obsidian 类型）
		-- callout = {},

		-- 图片预览（需 image.nvim 配合）
		image = {
			enabled = true,
		},

		-- LaTeX 数学公式渲染
		latex = {
			enabled = true,
		},

		-- 行内格式：加粗 / 斜体 / 行内代码
		markdown_highlight = {
			enabled = true,
		},

		-- ============ 行为配置 ============

		-- 渲染完成后自动隐藏渲染标记
		anti_conceal = {
			enabled = true,
			ignore = { "markdown" },
		},

		-- 进入插入模式时暂时隐藏渲染
		clear_after_insert = {
			enabled = false,         -- 设 true 则在插入模式下隐藏渲染效果
		},

		-- 排除列表：不对某些缓冲区渲染
		excluded_buftypes = { "nofile", "prompt", "popup" },
	},
}
