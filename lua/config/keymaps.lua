--
-- ██╗  ██╗███████╗██╗   ██╗███╗   ███╗ █████╗ ██████╗ ███████╗
-- ██║ ██╔╝██╔════╝╚██╗ ██╔╝████╗ ████║██╔══██╗██╔══██╗██╔════╝
-- █████╔╝ █████╗   ╚████╔╝ ██╔████╔██║███████║██████╔╝███████╗
-- ██╔═██╗ ██╔══╝    ╚██╔╝  ██║╚██╔╝██║██╔══██║██╔═══╝ ╚════██║
-- ██║  ██╗███████╗   ██║   ██║ ╚═╝ ██║██║  ██║██║     ███████║
-- ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝
--
--  功能：Neovim 自定义按键映射 + 多语言代码运行/预览 + 窗口/缓冲区高效管理

-- ======================== 1. 基础配置 ========================
vim.g.mapleader = " " -- 设置<leader>键为空格（自定义快捷键的前缀）
local keymap = vim.keymap -- 简化按键映射函数的调用（:help vim.keymap）
local clipboard = require("config.clipboard")
clipboard.setup_system_clipboard() -- 系统剪贴板快捷键
clipboard.setup_template_copy() -- <C-a><C-i>：内联模板并复制完整竞赛代码

-- 算法输入 data 文件：不再所有源文件共用一个，而是按当前编辑文件路径自动派生：
--   /home/ihxnan/WorkSpace/test.cpp → /home/ihxnan/Data/WorkSpace/test.txt
-- 即 <数据根目录>/<源文件父目录名>/<源文件名>.txt
local DATA_ROOT = vim.fn.expand("~") .. "/Data"

--- 依据当前缓冲区路径推导专属 data 文件；未命名缓冲区回退到 DATA_ROOT/unnamed.txt
local function get_data_file()
	local abs = vim.fn.expand("%:p")
	if abs == "" then
		return DATA_ROOT .. "/unnamed.txt"
	end
	local parent = vim.fn.fnamemodify(abs, ":h:t") -- 源文件父目录名
	local stem = vim.fn.fnamemodify(abs, ":t:r") -- 源文件名（去扩展名）
	if parent == "" or parent == "." then
		return DATA_ROOT .. "/" .. stem .. ".txt"
	end
	return DATA_ROOT .. "/" .. parent .. "/" .. stem .. ".txt"
end

--- 确保 data 文件的父目录存在（写入 / 打开前调用）
local function ensure_data_dir(path)
	vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
end

-- ======================== 2. 自定义函数 ========================

-- 2.1 ANSI 颜色常量 & 辅助函数（用于终端输出着色）
local C = {
	blue = "\\033[34m",
	cyan = "\\033[36m",
	yellow = "\\033[33m",
	green = "\\033[32m",
	red = "\\033[31m",
	reset = "\\033[0m",
}

--- 生成带颜色的 echo 命令片段
local function e(msg, color)
	return 'echo -e "' .. color .. msg .. C.reset .. '"'
end

--- 将命令列表拼接为 vsplit + terminal bash -c 的 Ex 命令
local function term_cmd(cmds)
	return "vsplit | terminal bash -c '" .. table.concat(cmds, "; ") .. "'"
end

-- 2.2 多语言代码通用运行
--- 运行代码（可选带输入数据重定向；with_macro 为 true 时编译加本地调试宏 -DIHXNAN）
local function run_code(with_data, with_macro)
	vim.cmd("w")
	local ft = vim.bo.filetype
	local data_label = with_data and "（带数据）" or ""
	local data_redirect = with_data and (' < "' .. get_data_file() .. '"') or ""

	print("🚀 正在运行 " .. ft .. data_label .. " ...")

	if ft == "cpp" or ft == "c" then
		-- with_macro 为 true 时（rl/rd/rp）编译加本地调试宏 -DIHXNAN；rc 不加
		local macro = with_macro and " -DIHXNAN" or ""
		local cmds = {
			e("[Compile] Starting C++ compilation...", C.blue),
			'g++ -O2 -fsanitize=address,undefined,leak "%" -o a.out' .. macro .. " 2>&1",
			"if [ $? -eq 0 ]; then " .. e("[Run] Program output:", C.cyan),
			"time ./a.out" .. data_redirect,
			e("[Clean] Removing temporary file a.out", C.yellow),
			"rm -f a.out",
			e("[Done] All operations completed", C.green),
			"else " .. e("[Error] Compilation failed! Please fix your code and try again", C.red),
			"fi",
		}
		vim.cmd(term_cmd(cmds))
	elseif ft == "python" then
		local cmds = {
			e("[Check] Syntax checking...", C.blue),
			'python3 -B -m py_compile "%" 2>&1',
			"if [ $? -eq 0 ]; then "
				.. e("[Run] Executing Python file" .. (with_data and " (with input data)" or "") .. "...", C.cyan),
			'time python3 -B "%"'
				.. data_redirect
				.. "| lolcat; find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null",
			e("[Done] Python finished", C.green),
			"else " .. e("[Error] Syntax error! Fix your code", C.red),
			"fi",
		}
		vim.cmd(term_cmd(cmds))
	elseif ft == "java" then
		if with_data then
			print("⚠️ Java 暂不支持带数据运行")
			return
		end
		local class_name = vim.fn.expand("%:t:r")
		vim.cmd("split | terminal javac % && java " .. class_name .. "; rm -f " .. class_name .. ".class")
	elseif ft == "cmake" then
		if with_data then
			print("⚠️ CMake 暂不支持带数据运行")
			return
		end
		print("🔧 正在构建 CMake 项目 ...")
		vim.cmd("split | terminal rm -rf build && mkdir build && cd build && cmake .. && make; $SHELL")
		vim.cmd("startinsert")
	elseif ft == "sh" then
		if with_data then
			print("⚠️ Shell 暂不支持带数据运行")
			return
		end
		vim.cmd("split | terminal sh %")
	elseif ft == "html" then
		if with_data then
			print("⚠️ HTML 暂不支持带数据运行")
			return
		end
		vim.cmd("split | terminal chromium %")
	else
		print("❌ 不支持的文件类型: " .. ft)
	end
end

-- 2.3 本地调试运行（C/C++ 带 -DIHXNAN 宏）
local run_local = function()
	vim.cmd("w")
	local ft = vim.bo.filetype

	-- 仅 C/C++ 使用带 -DIHXNAN 的编译方式（启用本地调试宏）
	if ft == "cpp" or ft == "c" then
		print("🚀 正在运行 " .. ft .. "（本地调试模式）...")
		local cmds = {
			e("[Compile] Starting C++ compilation (local debug)...", C.blue),
			'g++ -O2 -fsanitize=address,undefined,leak "%" -o a.out -DIHXNAN 2>&1',
			"if [ $? -eq 0 ]; then " .. e("[Run] Program output:", C.cyan),
			"time ./a.out",
			e("[Clean] Removing temporary file a.out", C.yellow),
			"rm -f a.out",
			e("[Done] All operations completed", C.green),
			"else " .. e("[Error] Compilation failed! Please fix your code and try again", C.red),
			"fi",
		}
		vim.cmd(term_cmd(cmds))
	else
		-- 其他文件类型回退到普通运行
		run_code(false)
	end
end

-- 2.4 CUDA/C/C++ 运行
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
		print("不支持的文件类型: " .. filetype)
	end
end

-- 2.5 HTML 实时预览 & 关闭
local preview_code = function()
	vim.cmd("w") -- 保存文件
	local filetype = vim.bo.filetype

	-- 仅支持HTML，调用LivePreview插件启动实时预览
	if filetype == "html" then
		vim.cmd("LivePreview start")
	else
		print("不支持的文件类型: " .. filetype)
	end
end

local close_code = function()
	local filetype = vim.bo.filetype

	if filetype == "html" then
		vim.cmd("LivePreview close") -- 关闭LivePreview预览窗口
	else
		print("不支持的文件类型: " .. filetype)
	end
end

-- 2.6 剪贴板工具
--- 粘贴剪贴板内容到 data 文件
local paste_to_data = function()
	local content = vim.fn.getreg("+")
	if not content or content == "" then
		print("⚠️ 剪贴板为空，跳过写入")
		return
	end
	local data_file = get_data_file()
	ensure_data_dir(data_file)
	local file = io.open(data_file, "w")
	if file then
		-- 确保末尾有换行符，避免 C++ 的 gc() 读到 EOF 后死循环
		local to_write = content
		if not to_write:match("\n$") then
			to_write = to_write .. "\n"
		end
		file:write(to_write)
		file:close()
		local lines = vim.fn.substitute(content, "[^\\n]", "", "g")
		local line_count = #lines + 1
		print("✅ 已写入 " .. line_count .. " 行到 " .. data_file .. " (" .. content:len() .. " 字节)")
	else
		print("❌ 错误：无法打开 data 文件写入：" .. data_file)
	end
end

--- 粘贴剪贴板内容 + 延迟运行代码（带数据）
local run_code_with_paste = function()
	vim.cmd("w")
	paste_to_data()
	vim.defer_fn(function()
		run_code(true, true)
	end, 50)
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

-- ======================== 6. 代码运行快捷键 ========================
keymap.set("n", "rc", function()
	-- 1. 剪贴板内容写入 data；2. 复制完整代码到剪贴板；3. 带数据运行（不加 -DIHXNAN）
	paste_to_data()
	clipboard.copy_all_with_info()
	run_code(true, false)
end, { desc = "rc：剪贴板→data，复制完整代码，带数据运行（无宏）" })
keymap.set("n", "rl", run_local, { desc = "rl：本地调试运行C/C++代码（带 -DIHXNAN 宏）" })
keymap.set("n", "ru", run_cuda, { desc = "ru：运行CUDA/C/C++代码" })
keymap.set("n", "rd", function()
	run_code(true, true)
end, { desc = "rd：带数据运行代码（读取本文件专属 data，带 -DIHXNAN）" })
keymap.set(
	"n",
	"rp",
	run_code_with_paste,
	{ desc = "rp：粘贴剪贴板到本文件专属 data 后带数据运行（带 -DIHXNAN）" }
)
keymap.set(
	"n",
	"dp",
	":w<CR><C-w>v:terminal fish -l<CR>idp",
	{ desc = "dp：保存并运行dp工具（-k参数）" }
)
-- cd 打开的是当前文件专属 data 文件（路径可能含空格），故打开前先建目录并 fnameescape
local open_data_file = function()
	local f = get_data_file()
	ensure_data_dir(f)
	vim.cmd("edit " .. vim.fn.fnameescape(f))
end
keymap.set("n", "cd", open_data_file, { desc = "cd：快速打开当前文件的算法输入数据文件" })
keymap.set("n", "cp", paste_to_data, { desc = "cp：覆盖写入剪贴板内容到 data 文件" })
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
	"<F5>",
	":w<CR>:silent !code . &<CR>",
	{ desc = "F5：保存并在VSCode中打开当前目录" }
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
	print("正在提交：" .. name)

	vim.system({
		"/home/ihxnan/.local/bin/server",
		"push",
		name,
	}, { text = true }, function(res)
		-- 回调函数不在 nvim 主线程，必须套 vim.schedule
		vim.schedule(function()
			if res.code == 0 then
				vim.notify("✅ 提交成功\n" .. res.stdout, vim.log.levels.INFO)
			else
				vim.notify("❌ 提交失败\n" .. res.stderr, vim.log.levels.ERROR)
			end
		end)
	end)
end

keymap.set("n", "<leader>p", submit, { desc = "Leader+p: 把当前文件提交到服务器" })

keymap.set("n", "<leader>q", ":q<CR>")
