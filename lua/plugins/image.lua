return {
	-- snacks.nvim 的 image 模块：用 Kitty 图形协议内联显示 图片 / PDF / 视频
	-- 直接 `nvim foo.png`、`nvim foo.pdf`、`nvim foo.mp4` 即可查看
	-- 依赖：ImageMagick（magick/convert）用于转码，PDF 逐页转图
	{
		"folke/snacks.nvim",
		priority = 1000,
		opts = {
			-- 禁用 snacks 的 dashboard（与 alpha-nvim 冲突）与 notifier
			dashboard = { enabled = false },
			notifier = { enabled = false },

			image = {
				enabled = true,
				-- 支持的格式默认已含 pdf/png/jpg/gif/webp/mp4 等
				doc = {
					enabled = true, -- markdown/html/norg 等文档内联渲染图片
					inline = true, -- 优先在缓冲区中内联显示
					float = true, -- 终端不支持 unicode placeholders 时退回浮窗
					max_width = 80,
					max_height = 40,
				},
				convert = {
					notify = false, -- 转码失败时不弹通知
				},
			},
		},
	},
}
