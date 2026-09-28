return {
	"3rd/image.nvim",
	ft = "markdown",
	-- 不构建 rocks，使用 magick_cli（shell 调用 ImageMagick）
	build = false,
	---@type image.config
	opts = {
		-- 后端：选你终端的协议
		--   "kitty"    — Kitty 终端（推荐，性能最好）
		--   "ueberzug" — Überzug++，任何终端可用
		--   "sixel"    — 支持 Sixel 的终端
		backend = "kitty",
		-- 图片处理方式
		--   "magick_cli" — shell 调用 convert/identify（需安装 ImageMagick）
		--   "magick_rock" — Lua FFI 绑定（需 luarocks install magick）
		processor = "magick_cli",
		-- 最大显示尺寸（像素）
		max_width = nil,
		max_height = nil,
		max_height_window_percentage = 50,
		max_width_window_percentage = 50,
		-- 集成：自动处理哪些文件类型中的图片
		integrations = {
			-- Markdown 图片：自动识别 ![]() 语法
			markdown = {
				enabled = true,
				-- 插入模式自动清除图片（避免干扰打字）
				clear_in_insert_mode = false,
				-- 仅光标所在行渲染图片
				only_render_image_at_cursor = false,
				-- 图片浮窗模式
				floating_images = false,
				-- 文件大小限制（字节）
				max_file_size = 10 * 1024 * 1024, -- 10MB
				-- 下载远程图片超时（秒）
				download_timeout = 10,
			},
			-- Neorg 支持
			neorg = {
				enabled = false,
			},
		},
		-- 窗口内窗口：图片放大查看
		window_overlay_clear = true,
	},
}
