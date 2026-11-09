--
-- ██╗  ██╗███████╗██╗   ██╗███╗   ███╗ █████╗ ██████╗ ███████╗
-- ██║ ██╔╝██╔════╝╚██╗ ██╔╝████╗ ████║██╔══██╗██╔══██╗██╔════╝
-- █████╔╝ █████╗   ╚████╔╝ ██╔████╔██║███████║██████╔╝███████╗
-- ██╔═██╗ ██╔══╝    ╚██╔╝  ██║╚██╔╝██║██╔══██║██╔═══╝ ╚════██║
-- ██║  ██╗███████╗   ██║   ██║ ╚═╝ ██║██║  ██║██║     ███████║
-- ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝
--
--  功能：Neovim 自定义按键映射 + 窗口/缓冲区管理（代码运行/判题快捷键见 config/run.lua）

-- ======================== 1. 基础配置 ========================
vim.g.mapleader = " " -- 设置<leader>键为空格（自定义快捷键的前缀）
local keymap = vim.keymap -- 简化按键映射函数的调用（:help vim.keymap）
local clipboard = require("config.clipboard")
local paths = require("config.paths") -- 统一推导 .in/.out 数据文件路径（与 companion.lua 共用）
local run = require("config.run") -- rc/rd/rp/rn/rl 运行/判题引擎与快捷键（见 config/run.lua）
clipboard.setup_system_clipboard() -- 系统剪贴板快捷键
clipboard.setup_template_copy() -- <C-a><C-i>：内联模板并复制完整竞赛代码

-- 算法输入/答案文件路径推导见 config/paths.lua；rc/rd/rp/rn/rl 的实现见 config/run.lua

-- ======================== 2. 自定义函数 ========================

-- 2.1 CUDA/C/C++ 运行
local run_cuda = function()
	vim.cmd("w") -- 执行前先保存当前文件，避免运行旧代码

	-- 获取当前缓冲区的文件类型（如cuda/c/cpp）
	local filetype = vim.bo.filetype

	-- 根据文件类型执行对应编译运行命令
	if filetype == "cuda" or filetype == "c" or filetype == "cpp" then
		-- 分割窗口并打开终端，执行：
		-- 1. nvcc编译（指定架构sm_89，适配RTX 30/40系显卡）
		-- 2. 运行生成的a.out
		-- 3. 运行后删除a.out临时文件
		vim.cmd("split | terminal nvcc -arch=sm_89 % && ./a.out && rm -f a.out")
	else
		-- 非支持类型给出提示
		print("Unsupported filetype: " .. filetype)
	end
end

-- 2.2 HTML 实时预览 & 关闭
local preview_code = function()
	vim.cmd("w") -- 保存文件
	local filetype = vim.bo.filetype

	-- 仅支持HTML，调用LivePreview插件启动实时预览
	if filetype == "html" then
		vim.cmd("LivePreview start")
	else
		print("Unsupported filetype: " .. filetype)
	end
end

local close_code = function()
	local filetype = vim.bo.filetype

	if filetype == "html" then
		vim.cmd("LivePreview close") -- 关闭LivePreview预览窗口
	else
		print("Unsupported filetype: " .. filetype)
	end
end

-- ======================== 3. 通用模式快捷键 ========================

-- 3.1 插入模式
keymap.set("i", "jk", "<ESC>") -- 快速退出插入模式（替代ESC键，减少抬手）
keymap.set("i", "<C-s>", "<ESC>:w<CR>") -- 插入模式下Ctrl+s快速保存

-- 3.2 终端模式
keymap.set("t", "jk", "<C-\\><C-n>") -- 终端模式下jk退出到普通模式

-- 3.3 视觉模式
keymap.set("v", "J", ":m '>+1<CR>gv=gv") -- 选中行向下移动
keymap.set("v", "K", ":m '<-2<CR>gv=gv") -- 选中行向上移动
keymap.set("v", "ii", "<ESC>") -- 视觉模式下ii退出到普通模式
keymap.set("v", "<C-c>", '"+y') -- 视觉模式下Ctrl+c复制选中内容到系统剪贴板

-- ======================== 4. 窗口管理 ========================

-- 4.1 窗口导航 - 插入模式
keymap.set("i", "<C-h>", "<ESC><C-w>h", { desc = "插入模式：切换到左侧窗口" })
keymap.set("i", "<C-j>", "<ESC><C-w>j", { desc = "插入模式：切换到下方窗口" })
keymap.set("i", "<C-k>", "<ESC><C-w>k", { desc = "插入模式：切换到上方窗口" })
keymap.set("i", "<C-l>", "<ESC><C-w>l", { desc = "插入模式：切换到右侧窗口" })

-- 4.2 窗口导航 - 终端模式
keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "终端模式：切换到左侧窗口" })
keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "终端模式：切换到下方窗口" })
keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "终端模式：切换到上方窗口" })
keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "终端模式：切换到右侧窗口" })

-- 4.3 窗口导航 - 普通模式
keymap.set("n", "<C-h>", "<C-w>h", { desc = "切换到左侧窗口" })
keymap.set("n", "<C-j>", "<C-w>j", { desc = "切换到下方窗口" })
keymap.set("n", "<C-k>", "<C-w>k", { desc = "切换到上方窗口" })
keymap.set("n", "<C-l>", "<C-w>l", { desc = "切换到右侧窗口" })

-- 4.4 窗口创建
keymap.set("n", "<leader>wv", "<C-w>s", { desc = "Leader+wv：水平分割窗口（上下）" })
keymap.set("n", "<leader>wh", "<C-w>v", { desc = "Leader+wh：垂直分割窗口（左右）" })

-- 4.5 窗口位置移动
keymap.set("n", "gwh", "<C-w>H", { desc = "gwh：将当前窗口移到最左侧" })
keymap.set("n", "gwj", "<C-w>J", { desc = "gwj：将当前窗口移到最下方" })
keymap.set("n", "gwk", "<C-w>K", { desc = "gwk：将当前窗口移到最上方" })
keymap.set("n", "gwl", "<C-w>L", { desc = "gwl：将当前窗口移到最右侧" })

-- 4.6 窗口关闭
keymap.set("n", "gwd", "<C-w>q", { desc = "gwd：关闭当前窗口" })
keymap.set("n", "gwo", "<C-w>o", { desc = "gwo：关闭其他所有窗口" })

-- 4.7 窗口大小调整
keymap.set("n", "<M-=>", "<C-w>>", { desc = "Alt+=：扩大当前窗口宽度" })
keymap.set("n", "<M-->", "<C-w><", { desc = "Alt+-：缩小当前窗口宽度" })

-- ======================== 5. 缓冲区管理 ========================

-- 5.1 缓冲区切换（基于 BufferLine 插件）
keymap.set("n", "H", ":w<CR>:BufferLineCyclePre<CR>", { desc = "Shift+H：保存并切换到上一个缓冲区" })
keymap.set("n", "L", ":w<CR>:BufferLineCycleNext<CR>", { desc = "Shift+L：保存并切换到下一个缓冲区" })

-- 5.2 缓冲区基本操作
keymap.set("n", "gbh", ":bprevious<CR>", { desc = "gbh：切换到上一个缓冲区" })
keymap.set("n", "gbl", ":bnext<CR>", { desc = "gbl：切换到下一个缓冲区" })
keymap.set("n", "gbd", ":bdelete<CR>", { desc = "gbd：关闭当前缓冲区" })
keymap.set("n", "gbo", ":BufferLineCloseOthers<CR>", { desc = "gbo：关闭其他所有缓冲区" })

-- ======================== 6. 其他运行/调试快捷键 ========================
keymap.set("n", "ru", run_cuda, { desc = "ru：运行CUDA/C/C++代码" })
keymap.set("n", "rk", function()
	-- 编译当前文件（-g -O0 -DIHXNAN），然后在终端里用 gdb 打开调试界面
	local ft = vim.bo.filetype
	if ft ~= "c" and ft ~= "cpp" then
		print("rk 只支持 C/C++")
		return
	end
	vim.cmd("w")
	local cc = (ft == "c") and "gcc" or "g++"
	local src = vim.fn.expand("%:p")
	-- main 定义在 <ihxnan> 头文件里，gdb 默认把「含有 main 的文件」当作当前源文件，
	-- 直接 b 行号会落到头文件上。先 list 本文件，把 gdb 的当前源文件切过来。
	local gdb_args = " -ex " .. vim.fn.shellescape("set listsize 1")
		.. " -ex " .. vim.fn.shellescape("list " .. src .. ":1")
		.. " -ex " .. vim.fn.shellescape("set listsize 10")
	run.run_script({
		run.e("[gdb] Compiling with -g -O0 -DIHXNAN ...", run.C.blue),
		cc .. ' -g -O0 -DIHXNAN "' .. src .. '" -o a.out 2>&1',
		"if [ $? -eq 0 ]; then " .. run.e("[gdb] Starting gdb (quit with q)", run.C.cyan),
		"gdb ./a.out" .. gdb_args,
		"fi",
		"rm -f a.out",
	})
end, { desc = "rk：编译（-DIHXNAN）并用 gdb 调试当前文件" })
keymap.set(
	"n",
	"dp",
	":w<CR><C-w>v:terminal fish -l<CR>idp",
	{ desc = "dp：保存并运行dp工具（-k参数）" }
)
-- cd 打开的是当前文件专属手动数据文件 <名>.txt（路径可能含空格），故打开前先建目录并 fnameescape
local open_data_file = function()
	local f = paths.txt_file()
	paths.ensure_dir(f)
	vim.cmd("edit " .. vim.fn.fnameescape(f))
end
keymap.set("n", "cd", open_data_file, { desc = "cd：快速打开当前文件的 <名>.txt 数据文件" })
keymap.set("n", "cp", run.paste_to_data, { desc = "cp：覆盖写入剪贴板内容到 <名>.txt" })
keymap.set("n", "ct", ":e ~/Github/Template<CR>", { desc = "ct：快速打开算法模板文件" })

-- ======================== 7. HTML 预览快捷键 ========================
keymap.set("n", "gmp", preview_code, { desc = "gmp：启动HTML实时预览" })
keymap.set("n", "gmc", close_code, { desc = "gmc：关闭HTML实时预览" })

-- ======================== 8. 搜索与导航 ========================
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Leader+nh：取消搜索高亮" })
keymap.set("n", "n", "nzz", { desc = "n：搜索下一个并居中显示" })
keymap.set("n", "N", "Nzz", { desc = "N：搜索上一个并居中显示" })

-- ======================== 9. 编辑效率 ========================

-- 9.1 常用工具启动
keymap.set(
	"n",
	"<C-g>",
	":tabe<CR>:term fish -l -c lazygit<CR>i",
	{ desc = "Ctrl+g：新建标签页并打开lazygit" }
)
keymap.set(
	"n",
	"<leader>t",
	":w<CR><C-w>v:terminal fish -l<CR>i",
	{ desc = "Leader+t：保存并新建垂直终端窗口（fish 登录模式）" }
)
keymap.set(
	"n",
	"<leader>s",
	":w<CR><C-w>s:terminal fish -l<CR>i",
	{ desc = "Leader+t：保存并新建水平终端窗口（fish 登录模式）" }
)
keymap.set(
	"n",
	"<leader>i",
	":w<CR><C-w>v:terminal fish -l<CR>ireasonix<CR>",
	{ desc = "Leader+i：保存并打开reasonix工具" }
)
keymap.set({ "n", "t" }, "<A-t>", "<Cmd>ToggleTerm<CR>", { desc = "Alt+t：切换 toggleterm 悬浮终端" })
keymap.set(
	"n",
	"<F6>",
	":w<CR>:silent !code . &<CR>",
	{ desc = "F6：保存并在VSCode中打开当前目录" }
)

-- 9.2 快速保存
keymap.set("n", "<C-S>", ":w<CR>", { desc = "Ctrl+S：快速保存" })

-- 9.3 光标快速移动（兼容折行）
keymap.set("n", "j", "gj", { desc = "j：按视觉行向下移动" })
keymap.set("n", "k", "gk", { desc = "k：按视觉行向上移动" })
keymap.set("n", "J", "5j", { desc = "J：快速向下移动5行" })
keymap.set("n", "K", "5k", { desc = "K：快速向上移动5行" })

local submit = function()
	vim.cmd("w")
	local name = vim.fn.expand("%:p")
	print("Submitting: " .. name)

	vim.system({
		"/home/ihxnan/.local/bin/server",
		"push",
		name,
	}, { text = true }, function(res)
		-- 回调函数不在 nvim 主线程，必须套 vim.schedule
		vim.schedule(function()
			if res.code == 0 then
				vim.notify("✅ Submit succeeded\n" .. res.stdout, vim.log.levels.INFO)
			else
				vim.notify("❌ Submit failed\n" .. res.stderr, vim.log.levels.ERROR)
			end
		end)
	end)
end

keymap.set("n", "<leader>p", submit, { desc = "Leader+p: 把当前文件提交到服务器" })

keymap.set("n", "<leader>q", ":q<CR>")
