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
local paths = require("config.paths") -- 统一推导 .in/.out 数据文件路径（与 companion.lua 共用）
clipboard.setup_system_clipboard() -- 系统剪贴板快捷键
clipboard.setup_template_copy() -- <C-a><C-i>：内联模板并复制完整竞赛代码

-- 算法输入/答案文件：按当前编辑文件路径自动派生（规则见 config/paths.lua）：
--   /home/ihxnan/WorkSpace/test.cpp → /home/ihxnan/Data/WorkSpace/test.in   （输入 / rd）
--                                     /home/ihxnan/Data/WorkSpace/test.out  （期望答案 / rc 判题）
-- 即 <数据根目录>/<源文件父目录名>/<源文件名>.in / .out

-- ======================== 2. 自定义函数 ========================

-- 2.1 ANSI 颜色常量 & 辅助函数（用于终端输出着色）
local C = {
	blue = "\\033[34m",
	cyan = "\\033[36m",
	yellow = "\\033[33m",
	green = "\\033[32m",
	red = "\\033[31m",
	magenta = "\\033[35m",
	green_bold = "\\033[1;32m",
	red_bold = "\\033[1;31m",
	reset = "\\033[0m",
}

-- 各运行命令「头部标注」的专属强调色（加粗、彼此可区分；正文仍用上面的语义色）
local CMD_COLOR = {
	rc = "\\033[1;36m", -- 亮青
	rd = "\\033[1;34m", -- 亮蓝
	rp = "\\033[1;35m", -- 亮紫
	rn = "\\033[1;32m", -- 亮绿
	rl = "\\033[1;33m", -- 亮黄
}

--- 生成带颜色的 echo 命令片段
local function e(msg, color)
	return 'echo -e "' .. color .. msg .. C.reset .. '"'
end

--- 将命令列表写成临时脚本再执行。
--- 不直接拼成一条 :terminal 命令：那样有长度上限（约 900 字符即触发 E114/E499），
--- 且 `%`、`<...>`、`<(...)` 会被 Ex 层展开/误解析。落成脚本文件后，:terminal 只跑一句
--- 短命令，脚本可任意长、由 bash 自己解析，无 Vim 层转义问题。
local RUN_SCRIPT_PATH = "/tmp/ihxnan_run.sh"
local function run_script(cmds)
	vim.fn.writefile({ table.concat(cmds, "; ") }, RUN_SCRIPT_PATH)
	vim.cmd("vsplit | terminal bash " .. RUN_SCRIPT_PATH)
end

--- 归一化命令：先剥掉 ANSI 颜色码（调试模式下程序输出被 dbg_putchar 包成紫色），再去行尾空白
local function norm_of(path)
	return '<(sed -e "s/\\x1b\\[[0-9;]*m//g" -e "s/[[:space:]]*$//" "' .. path .. '")'
end

--- 判题结果行标签：多组时带 [Test k] 前缀，单组时沿用 [Check]
local function label_of(k, total, text)
	return (total > 1) and ("[Test " .. k .. "] " .. text) or ("[Check] " .. text)
end

--- 追加「多组遍历判题」的命令块（C/C++、python 共用）。
--- run_of(k) 返回该组「把程序结果打到 stdout」的命令（不含 tee/对比）。
local function append_multi_tests(cmds, groups, any_out, run_of)
	local total = #groups
	table.insert(cmds, "_ac=0; _wa=0")
	for _, k in ipairs(groups) do
		local out_k = paths.out_file(nil, k)
		if total > 1 then
			table.insert(cmds, e("── Test " .. k .. "/" .. total .. " ──", C.cyan))
		end
		if vim.fn.filereadable(out_k) == 1 then
			table.insert(cmds, run_of(k) .. " | tee /tmp/ihxnan_run.out")
			table.insert(
				cmds,
				"if diff -q -B "
					.. norm_of(out_k)
					.. " "
					.. norm_of("/tmp/ihxnan_run.out")
					.. " >/dev/null 2>&1; then "
					.. e(label_of(k, total, "Accepted"), C.green)
					.. "; _ac=$(( _ac + 1 )); else "
					.. e(label_of(k, total, "Wrong Answer"), C.red)
					.. "; _wa=$(( _wa + 1 )); "
					.. e("--- expected ---", C.yellow)
					.. '; cat "'
					.. out_k
					.. '"; '
					.. e("--- diff (expected vs yours) ---", C.magenta)
					.. "; diff -B "
					.. norm_of(out_k)
					.. " "
					.. norm_of("/tmp/ihxnan_run.out")
					.. "; fi"
			)
		else
			table.insert(cmds, run_of(k))
			if any_out and total > 1 then
				table.insert(cmds, e(label_of(k, total, "no .out, skip"), C.yellow))
			end
		end
	end
	if any_out and total > 1 then
		table.insert(
			cmds,
			'if [ "$_wa" -eq 0 ]; then '
				.. e("=== All tests passed ($_ac) ===", C.green_bold)
				.. "; else "
				.. e("=== Tests failed ($_ac passed / $_wa failed) ===", C.red_bold)
				.. "; fi"
		)
	end
end

-- 2.2 多语言代码通用运行
--- 运行代码。opts：
---   files: "plugin" | "manual" | "none"
---          plugin — 插件生成的样例 <名>.1.in/.2.in…（rc/rd，可多组判题）
---          manual — 手动数据文件 <名>.txt（rp/rn）
---          none   — 不重定向 stdin（rl 非 C/C++ 回退）
---   macro: boolean  编译加本地调试宏 -DIHXNAN
---   check: boolean  与 <名>.N.out 判题（仅 plugin 模式有效）
---   cmd:   string   头部标签（rc/rd/rp/rn/rl）
local function run_code(opts)
	opts = opts or {}
	local files = opts.files or "none"
	local with_data = files ~= "none"
	local with_macro = opts.macro
	local with_check = opts.check
	local cmd = opts.cmd
	vim.cmd("w")
	local ft = vim.bo.filetype

	local src = vim.fn.expand("%:p") -- 当前源文件绝对路径（写进脚本用，不依赖 Ex 层 `%`）
	local macro_label = with_macro and "-DIHXNAN" or "no macro"
	local manual_file = paths.txt_file() -- 手动数据文件 <名>.txt

	-- 插件样例组：<名>.1.in / <名>.2.in …（连续，遇缺即止）
	local groups = {}
	if files == "plugin" then
		local k = 1
		while vim.fn.filereadable(paths.in_file(nil, k)) == 1 do
			groups[#groups + 1] = k
			k = k + 1
		end
	end
	local any_out = false
	for _, k in ipairs(groups) do
		if vim.fn.filereadable(paths.out_file(nil, k)) == 1 then
			any_out = true
			break
		end
	end
	-- 多组判题：仅 plugin + check + 有样例
	local multi = (files == "plugin") and with_check and #groups > 0
	local judging = multi and any_out

	local data_redirect = ""
	if files == "manual" then
		data_redirect = ' < "' .. manual_file .. '"'
	elseif files == "plugin" then
		data_redirect = ' < "' .. paths.in_file(nil, 1) .. '"' -- 单组兜底
	end

	local data_label = ({ plugin = "plugin data", manual = "manual .txt", none = "no data" })[files]
	local check_label = judging and ", judging" or ""

	-- 头部标注：命令名 + 专属色（正文仍用语义色）
	local tag = cmd or "run"
	local header = e("[" .. tag .. "] " .. data_label .. ", " .. macro_label .. check_label, CMD_COLOR[cmd] or C.cyan)
	print("🚀 [" .. tag .. "] Running " .. ft .. " (" .. data_label .. ", " .. macro_label .. check_label .. ") ...")

	if ft == "cpp" or ft == "c" then
		local macro = with_macro and " -DIHXNAN" or ""
		local cmds = {
			header,
			e("[Compile] Starting C++ compilation...", C.blue),
			'g++ -O2 -fsanitize=address,undefined,leak "' .. src .. '" -o a.out' .. macro .. " 2>&1",
			"if [ $? -eq 0 ]; then " .. e("[Run] Program output:", C.cyan),
		}
		if multi then
			-- 遍历所有样例组：有 .out 的组对比，无 .out 的组只运行
			append_multi_tests(cmds, groups, any_out, function(k)
				return './a.out < "' .. paths.in_file(nil, k) .. '"'
			end)
		else
			table.insert(cmds, "./a.out" .. data_redirect)
		end
		vim.list_extend(cmds, {
			e("[Clean] Removing temporary file a.out", C.yellow),
			"rm -f a.out",
			e("[Done] All operations completed", C.green),
			"else " .. e("[Error] Compilation failed! Please fix your code and try again", C.red),
			"fi",
		})
		run_script(cmds)
	elseif ft == "python" then
		local cmds = {
			header,
			e("[Check] Syntax checking...", C.blue),
			'python3 -B -m py_compile "' .. src .. '" 2>&1',
			"if [ $? -eq 0 ]; then "
				.. e("[Run] Executing Python file" .. (with_data and " (with input data)" or "") .. "...", C.cyan),
		}
		local pycache_clean = "find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null"
		if multi then
			append_multi_tests(cmds, groups, any_out, function(k)
				return 'python3 -B "' .. src .. '" < "' .. paths.in_file(nil, k) .. '" | lolcat'
			end)
			table.insert(cmds, pycache_clean)
		else
			table.insert(cmds, 'python3 -B "' .. src .. '"' .. data_redirect .. " | lolcat; " .. pycache_clean)
		end
		vim.list_extend(cmds, {
			e("[Done] Python finished", C.green),
			"else " .. e("[Error] Syntax error! Fix your code", C.red),
			"fi",
		})
		run_script(cmds)
	elseif ft == "java" then
		if with_data then
			print("⚠️ Java: running with data is not supported")
			return
		end
		local class_name = vim.fn.expand("%:t:r")
		vim.cmd("split | terminal javac % && java " .. class_name .. "; rm -f " .. class_name .. ".class")
	elseif ft == "cmake" then
		if with_data then
			print("⚠️ CMake: running with data is not supported")
			return
		end
		print("🔧 Building CMake project ...")
		vim.cmd("split | terminal rm -rf build && mkdir build && cd build && cmake .. && make; $SHELL")
		vim.cmd("startinsert")
	elseif ft == "sh" then
		if with_data then
			print("⚠️ Shell: running with data is not supported")
			return
		end
		vim.cmd("split | terminal sh %")
	elseif ft == "html" then
		if with_data then
			print("⚠️ HTML: running with data is not supported")
			return
		end
		vim.cmd("split | terminal chromium %")
	else
		print("❌ Unsupported filetype: " .. ft)
	end
end

-- 2.3 本地调试运行（C/C++ 带 -DIHXNAN 宏）
local run_local = function()
	vim.cmd("w")
	local ft = vim.bo.filetype

	-- 仅 C/C++ 使用带 -DIHXNAN 的编译方式（启用本地调试宏）
	if ft == "cpp" or ft == "c" then
		print("🚀 [rl] Running " .. ft .. " (no data, -DIHXNAN, local debug) ...")
		local src = vim.fn.expand("%:p")
		local cmds = {
			e("[rl] no data, -DIHXNAN, local debug", CMD_COLOR.rl),
			e("[Compile] Starting C++ compilation (local debug)...", C.blue),
			'g++ -O2 -fsanitize=address,undefined,leak "' .. src .. '" -o a.out -DIHXNAN 2>&1',
			"if [ $? -eq 0 ]; then " .. e("[Run] Program output:", C.cyan),
			"./a.out",
			e("[Clean] Removing temporary file a.out", C.yellow),
			"rm -f a.out",
			e("[Done] All operations completed", C.green),
			"else " .. e("[Error] Compilation failed! Please fix your code and try again", C.red),
			"fi",
		}
		run_script(cmds)
	else
		-- 其他文件类型回退到普通运行（仍标注 rl）
		run_code({ files = "none", cmd = "rl" })
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
		print("Unsupported filetype: " .. filetype)
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

-- 2.6 剪贴板工具
--- 粘贴剪贴板内容到 data 文件
local paste_to_data = function()
	local content = vim.fn.getreg("+")
	if not content or content == "" then
		print("⚠️ Clipboard empty, skipped")
		return
	end
	local data_file = paths.txt_file() -- 手动数据文件 <名>.txt
	paths.ensure_dir(data_file)
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
		print("✅ Wrote " .. line_count .. " lines to " .. data_file .. " (" .. content:len() .. " bytes)")
	else
		print("❌ Error: cannot open data file for writing: " .. data_file)
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

-- ======================== 6. 代码运行快捷键 ========================
keymap.set("n", "rc", function()
	-- 配合插件：遍历 <名>.1.in / <名>.2.in…，逐组与 <名>.N.out 判题；不加 -DIHXNAN
	run_code({ files = "plugin", macro = false, check = true, cmd = "rc" })
end, { desc = "rc：插件样例全部判题（不加 -DIHXNAN，对比 .N.out）" })
keymap.set("n", "rl", run_local, { desc = "rl：本地调试运行C/C++代码（带 -DIHXNAN 宏）" })
keymap.set("n", "ru", run_cuda, { desc = "ru：运行CUDA/C/C++代码" })
keymap.set("n", "rd", function()
	-- 同 rc；加 -DIHXNAN（gdb 走 stderr，stdout 只留程序结果）
	run_code({ files = "plugin", macro = true, check = true, cmd = "rd" })
end, { desc = "rd：插件样例全部判题（带 -DIHXNAN，对比 .N.out）" })
keymap.set("n", "rp", function()
	-- 粘贴剪贴板到 <名>.txt，再带数据运行（带 -DIHXNAN，不判题）
	vim.cmd("w")
	paste_to_data()
	vim.defer_fn(function()
		run_code({ files = "manual", macro = true, cmd = "rp" })
	end, 50)
end, { desc = "rp：粘贴剪贴板到 <名>.txt 后带数据运行（带 -DIHXNAN）" })
keymap.set("n", "rn", function()
	-- 读 <名>.txt 带数据运行（带 -DIHXNAN，不判题）——即加插件前的 rd
	run_code({ files = "manual", macro = true, cmd = "rn" })
end, { desc = "rn：读 <名>.txt 带数据运行（带 -DIHXNAN，不判题）" })
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
keymap.set("n", "cp", paste_to_data, { desc = "cp：覆盖写入剪贴板内容到 <名>.txt" })
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
