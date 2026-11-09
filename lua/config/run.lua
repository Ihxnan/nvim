--
--  ██████╗ ██╗   ██╗███╗   ██╗
--  ██╔══██╗██║   ██║████╗  ██║
--  ██████╔╝██║   ██║██╔██╗ ██║
--  ██╔══██╗██║   ██║██║╚██╗██║
--  ██║  ██║╚██████╔╝██║ ╚████║
--  ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
--
--  功能：rc/rd/rp/rn/rl 运行与判题快捷键，以及其背后的「编译 → 运行 → 对比」引擎
--        数据文件路径统一由 config.paths 推导（<数据根>/<父目录名>/<名>.N.in|out|txt）
--        引擎里的 e / C / run_script / paste_to_data 也被 keymaps.lua 复用（rk、cp）

local paths = require("config.paths")
local keymap = vim.keymap

-- ======================== 1. 工具函数 ========================

--- ANSI 颜色常量 & 辅助函数（用于终端输出着色）
local C = {
	blue = "\\033[34m",
	cyan = "\\033[36m",
	yellow = "\\033[33m",
	green = "\\033[32m",
	red = "\\033[31m",
	magenta = "\\033[35m",
	gray = "\\033[90m",
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
	return 'echo -e "' .. (color or "") .. msg .. C.reset .. '"'
end

--- 将命令列表写成临时脚本再执行。
--- 不直接拼成一条 :terminal 命令：那样有长度上限（约 900 字符即触发 E114/E499），
--- 且 %、<...>、<(...) 会被 Ex 层展开/误解析。落成脚本文件后，:terminal 只跑一句
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

--- 判题产物：
---   RUN_OUT  只含程序 stdout（供 diff 与实时显示）
---   RUN_RAW  收程序 stderr（dbg 输出；sanitizer 报告已用 log_path 改写到独立日志）
---   RUN_HINT 是「sanitizer 日志 + stderr」的合并文件，仅用于提炼 RE 提示
local RUN_OUT = "/tmp/ihxnan_run.out"
local RUN_RAW = "/tmp/ihxnan_run.raw"
local RUN_HINT = "/tmp/ihxnan_hint"
local ASAN_LOG = "/tmp/ihxnan_asan"
local UBSAN_LOG = "/tmp/ihxnan_ubsan"

--- 判题单组时限（秒）：rc/rd 用 timeout 包住程序，超时即判 TLE（退出码 124）。
local TIME_LIMIT = 2

--- 输出美化：统一分隔线 + 彩色 unified diff（rc/rd/rn/rp/rl 共用）
local SEP = "──────────────────────────────────────────────────────────"
local function sep(color)
	return e(SEP, color or C.gray)
end

--- 彩色 unified diff：+ 绿 / - 红；去掉两行文件头，最多 40 行
local function colored_diff(expected)
	return "diff -u -B --label expected --label received "
		.. norm_of(expected)
		.. " "
		.. norm_of(RUN_OUT)
		.. " 2>/dev/null | tail -n +3 | head -n 40 | sed -e $'s/^\\+/\\033[32m+/' -e $'s/^-/\\033[31m-/' -e $'s/$/\\033[0m/'"
end

--- 从 RUN_RAW 提炼 RE 原因，并翻译成通俗中文提示
local function re_hint()
	return "_rh=$(grep -m1 'runtime error:' "
		.. RUN_HINT
		.. " 2>/dev/null | sed -e 's|^.*/||'); "
		.. "[ -n \"$_rh\" ] || _rh=$(grep -m1 '^SUMMARY: AddressSanitizer:' "
		.. RUN_HINT
		.. " 2>/dev/null | sed -e 's/ ([^)]*)//g' -e 's/^SUMMARY: AddressSanitizer: //'); "
		.. "[ -n \"$_rh\" ] || _rh=$(grep -m1 'ERROR: AddressSanitizer:' "
		.. RUN_HINT
		.. " 2>/dev/null | sed -e 's/^.*ERROR: //'); "
		.. "[ -n \"$_rh\" ] || _rh=$(grep -E '^[A-Za-z_.]+(Error|Exception|Interrupt)' "
		.. RUN_HINT
		.. " 2>/dev/null | tail -n1); "
		.. "_ra=$(grep -m1 -E '(READ|WRITE) of size' "
		.. RUN_HINT
		.. " 2>/dev/null | sed -e 's/^ *//' -e 's/ at 0x.*//'); "
		.. "[ -n \"$_ra\" ] || _ra=$(grep -m1 'The signal is caused by' "
		.. RUN_HINT
		.. " 2>/dev/null | sed -e 's/^==[0-9]*==//' -e 's/^The signal is caused by //' -e 's/\\.$//'); "
		.. "if [ -n \"$_rh\" ]; then "
		.. "[ -z \"$_ra\" ] || _rh=\"$_rh ($_ra)\"; "
		.. "printf '  \\033[90m↳ %s\\033[0m\\n' \"$_rh\"; fi; "
		.. "_tip=''; "
		.. "case \"$_rh\" in "
		.. "*buffer-overflow*|*out*of*bounds*) _tip='数组越界：检查下标是否越界（a[n]、<= n、数组开小）' ;; "
		.. "*double-free*) _tip='重复释放：同一块内存 delete/free 了两次' ;; "
		.. "*use-after-free*|*use-after-poison*) _tip='释放后使用：内存已释放但仍在访问' ;; "
		.. "*stack-overflow*) _tip='栈溢出：递归太深或局部数组太大' ;; "
		.. "*SEGV*|*segmentation*) _tip='段错误：多为空指针/野指针，或数组越界' ;; "
		.. "*division*by*zero*|*divide*by*zero*|*FPE*) _tip='除以 0：检查除数和取模是否为 0' ;; "
		.. "*integer*overflow*) _tip='整数溢出：int 不够用，改用 long long' ;; "
		.. "*null*pointer*|*nullptr*) _tip='空指针：指针未初始化或已释放' ;; "
		.. "*misaligned*) _tip='未对齐访问：指针强转或越界读写' ;; "
		.. "*alloc-dealloc-mismatch*) _tip='分配/释放不匹配：new 配 delete，malloc 配 free' ;; "
		.. "*leak*) _tip='内存泄漏：申请的内存未释放（本地调试可忽略）' ;; "
		.. "*IndexError*|*KeyError*) _tip='下标/键访问越界：检查数组或字典的索引' ;; "
		.. "*ZeroDivisionError*) _tip='除以 0：检查除数是否为 0' ;; "
		.. "*RecursionError*) _tip='递归太深：检查递归边界或改用迭代' ;; "
		.. "*MemoryError*) _tip='内存不足：数组开太大' ;; "
		.. "*AssertionError*) _tip='断言失败：检查 assert 条件' ;; "
		.. "esac; "
		.. "[ -n \"$_tip\" ] || _tip=\"程序异常退出（exit $_st）：可能是越界/空指针/除零，检查对应代码逻辑\"; "
		.. "printf '  \\033[33m↳ %s\\033[0m\\n' \"$_tip\""
end

--- 追加「多组遍历判题」的命令块（C/C++、python 共用）。
--- run_of(k) 返回该组「把程序结果打到 stdout」的命令（不含 tee/对比）。
--- tle: 单组时限（秒），nil 表示不限时；超时（timeout 退出码 124）判 TLE，其余非 0 退出码判 RE
--- RE 时只保留程序 stdout（崩溃前已输出的部分），stderr 的 ASan/gdb 报告不打印，仅用于提炼提示
local function append_multi_tests(cmds, groups, any_out, run_of, tle)
	local total = #groups
	local lim = tle and ("timeout " .. tle .. " ") or ""
	table.insert(cmds, "_ac=0; _wa=0; _tle=0; _re=0; _t_all0=$(date +%s%N)")
	for _, k in ipairs(groups) do
		local out_k = paths.out_file(nil, k)
		if total > 1 then
			table.insert(cmds, e("── Test " .. k .. "/" .. total .. " ──", C.cyan))
		end
		if vim.fn.filereadable(out_k) == 1 then
			table.insert(cmds, "_t0=$(date +%s%N)")
			-- sanitizer 报告用 log_path 写到独立文件，stderr 只留 dbg 输出
			table.insert(cmds, "rm -f " .. ASAN_LOG .. ".* " .. UBSAN_LOG .. ".*")
			-- PIPESTATUS[0] 才是 timeout/程序本身的退出码（tee 恒为 0），必须紧跟管道取
			table.insert(
				cmds,
				"ASAN_OPTIONS=log_path="
					.. ASAN_LOG
					.. " UBSAN_OPTIONS=log_path="
					.. UBSAN_LOG
					.. " "
					.. run_of(k, lim)
					.. " | tee "
					.. RUN_OUT
			)
			table.insert(cmds, "_st=${PIPESTATUS[0]}")
			table.insert(cmds, "_t1=$(date +%s%N); _ms=$(( (_t1 - _t0) / 1000000 ))")
			-- 合并 sanitizer 日志与 stderr 供 re_hint 提炼；stderr 显示时过滤掉残留的 sanitizer 行
			table.insert(cmds, "cat " .. ASAN_LOG .. ".* " .. UBSAN_LOG .. ".* " .. RUN_RAW .. " 2>/dev/null > " .. RUN_HINT)
			table.insert(
				cmds,
				"[ -s "
					.. RUN_RAW
					.. " ] && grep -vE 'runtime error:|DEADLYSIGNAL|^==[0-9]+==|^=+$' "
					.. RUN_RAW
			)
			table.insert(
				cmds,
				'if [ "$_st" -eq 124 ]; then '
					.. e(label_of(k, total, "✗ Time Limit Exceeded (TLE)") .. " (${_ms} ms)", C.red_bold)
					.. "; _tle=$(( _tle + 1 )); _wa=$(( _wa + 1 )); elif [ \"$_st\" -ne 0 ]; then "
					.. e(label_of(k, total, "✗ Runtime Error (exit $_st)") .. " (${_ms} ms)", C.red_bold)
					.. "; " .. re_hint()
					.. "; _re=$(( _re + 1 )); _wa=$(( _wa + 1 )); elif diff -q -B "
					.. norm_of(out_k)
					.. " "
					.. norm_of(RUN_OUT)
					.. " >/dev/null 2>&1; then "
					.. e(label_of(k, total, "✓ Accepted") .. " (${_ms} ms)", C.green)
					.. "; _ac=$(( _ac + 1 )); else "
					.. e(label_of(k, total, "✗ Wrong Answer") .. " (${_ms} ms)", C.red)
					.. "; _wa=$(( _wa + 1 )); "
					.. colored_diff(out_k)
					.. "; fi"
			)
		else
			table.insert(cmds, "_t0=$(date +%s%N)")
			table.insert(cmds, "rm -f " .. ASAN_LOG .. ".* " .. UBSAN_LOG .. ".*")
			table.insert(
				cmds,
				"ASAN_OPTIONS=log_path="
					.. ASAN_LOG
					.. " UBSAN_OPTIONS=log_path="
					.. UBSAN_LOG
					.. " "
					.. run_of(k, lim)
			)
			table.insert(cmds, "_st=${PIPESTATUS[0]}")
			table.insert(cmds, "_t1=$(date +%s%N); _ms=$(( (_t1 - _t0) / 1000000 ))")
			table.insert(cmds, "cat " .. ASAN_LOG .. ".* " .. UBSAN_LOG .. ".* " .. RUN_RAW .. " 2>/dev/null > " .. RUN_HINT)
			table.insert(
				cmds,
				"[ -s "
					.. RUN_RAW
					.. " ] && grep -vE 'runtime error:|DEADLYSIGNAL|^==[0-9]+==|^=+$' "
					.. RUN_RAW
			)
			if any_out and total > 1 then
				table.insert(cmds, e(label_of(k, total, "- no .out, run only") .. " (${_ms} ms)", C.yellow))
			end
		end
	end
	if any_out and total > 1 then
		table.insert(
			cmds,
			'_t_all1=$(date +%s%N); _mall=$(( (_t_all1 - _t_all0) / 1000000 )); if [ "$_wa" -eq 0 ]; then '
				.. e("═══ All tests passed ($_ac) ═══ (${_mall} ms)", C.green_bold)
				.. "; else "
				.. e("═══ $_ac passed / $_wa failed / $_tle TLE / $_re RE ═══ (${_mall} ms)", C.red_bold)
				.. "; fi"
		)
	end
end

-- ======================== 2. 运行/判题引擎 ========================

--- 多语言代码通用运行
--- 运行代码。opts：
---   files: "plugin" | "manual" | "none"
---          plugin — 插件生成的样例 <名>.1.in/.2.in…（rc/rd，可多组判题）
---          manual — 手动数据文件 <名>.txt（rp/rn）
---          none   — 不重定向 stdin（rl 非 C/C++ 回退）
---   macro: boolean  编译加本地调试宏 -DIHXNAN
---   check: boolean  与 <名>.N.out 判题（仅 plugin 模式有效）
---   cmd:   string   头部标签（rc/rd/rp/rn/rl）
---   timeout: number 单组时限（秒），仅 rc/rd 传；nil = 不限时
local function run_code(opts)
	opts = opts or {}
	local files = opts.files or "none"
	local with_data = files ~= "none"
	local with_macro = opts.macro
	local with_check = opts.check
	local tle = opts.timeout -- 单组时限（秒），nil = 不限；目前只有 rc/rd 传
	local cmd = opts.cmd
	vim.cmd("w")
	local ft = vim.bo.filetype

	local src = vim.fn.expand("%:p") -- 当前源文件绝对路径（写进脚本用，不依赖 Ex 层 %）
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
	elseif files == "plugin" and #groups > 0 then
		data_redirect = ' < "' .. paths.in_file(nil, 1) .. '"' -- 单组兜底；rd 清空样例后无重定向
	end

	local data_label = ({ plugin = "plugin data", manual = "manual .txt", none = "no data" })[files]
	local check_label = judging and ", judging" or ""
	local tle_label = (judging and tle) and (", TLE " .. tle .. "s") or ""
	local test_label = (#groups > 1) and (", " .. #groups .. " tests") or ""

	-- 头部标注：命令名 + 专属色（正文仍用语义色）
	local tag = cmd or "run"
	local file_label = vim.fn.expand("%:t")
	local header = e(
		"━━━ ["
			.. tag
			.. "] "
			.. file_label
			.. "  ·  "
			.. data_label
			.. "  ·  "
			.. macro_label
			.. check_label
			.. tle_label
			.. test_label
			.. " ━━━",
		CMD_COLOR[cmd] or C.cyan
	)
	print(
		"🚀 ["
			.. tag
			.. "] "
			.. file_label
			.. " ("
			.. data_label
			.. ", "
			.. macro_label
			.. check_label
			.. tle_label
			.. test_label
			.. ") ..."
	)

	if ft == "cpp" or ft == "c" then
		local macro = with_macro and " -DIHXNAN" or ""
		local cmds = {
			header,
			sep(C.gray),
			e("[Compile] g++ -O2 + ASan/UBSan" .. macro .. " ...", C.blue),
			"_tc0=$(date +%s%N)",
			'g++ -O2 -fsanitize=address,undefined,leak "' .. src .. '" -o a.out' .. macro .. " 2>&1; _cst=$?",
			"_tc1=$(date +%s%N); _cms=$(( (_tc1 - _tc0) / 1000000 ))",
			'if [ "$_cst" -eq 0 ]; then '
				.. e("[Compile] OK (${_cms} ms)", C.green)
				.. "; "
				.. e("[Run] Program output:", C.cyan),
		}
		if multi then
			-- 遍历所有样例组：有 .out 的组对比，无 .out 的组只运行
			append_multi_tests(cmds, groups, any_out, function(k, lim)
				-- 用 pty 跑，stdout 变成行缓冲：崩溃前已输出的内容不会丢（stdbuf 与 ASan 冲突）
				return 'script -qec "'
					.. lim
					.. "'./a.out' < '"
					.. paths.in_file(nil, k)
					.. "' 2> "
					.. RUN_RAW
					.. '" /dev/null'
			end, tle)
		else
			table.insert(cmds, "_t0=$(date +%s%N)")
			table.insert(cmds, "./a.out" .. data_redirect)
			table.insert(cmds, "_t1=$(date +%s%N); _ms=$(( (_t1 - _t0) / 1000000 ))")
			table.insert(cmds, e("[Run] finished in ${_ms} ms", C.cyan))
		end
		vim.list_extend(cmds, {
			sep(C.gray),
			e("[Clean] Removing temporary file a.out", C.yellow),
			"rm -f a.out",
			e("[Done] All operations completed", C.green_bold),
			sep(C.gray),
			"else " .. e("[Error] Compilation failed — fix the code above", C.red_bold),
			"fi",
		})
		run_script(cmds)
	elseif ft == "python" then
		local cmds = {
			header,
			sep(C.gray),
			e("[Check] Syntax checking ...", C.blue),
			'python3 -B -m py_compile "' .. src .. '" 2>&1',
			"if [ $? -eq 0 ]; then "
				.. e("[Run] Executing Python" .. (with_data and " (with input data)" or "") .. " ...", C.cyan),
		}
		local pycache_clean = "find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null"
		if multi then
			append_multi_tests(cmds, groups, any_out, function(k, lim)
				return lim
					.. 'python3 -u -B "'
					.. src
					.. '" < "'
					.. paths.in_file(nil, k)
					.. '" 2> '
					.. RUN_RAW
					.. " | lolcat"
			end, tle)
			table.insert(cmds, pycache_clean)
		else
			table.insert(cmds, "_t0=$(date +%s%N)")
			table.insert(cmds, 'python3 -B "' .. src .. '"' .. data_redirect .. " | lolcat")
			table.insert(cmds, "_t1=$(date +%s%N); _ms=$(( (_t1 - _t0) / 1000000 ))")
			table.insert(cmds, pycache_clean)
			table.insert(cmds, e("[Run] finished in ${_ms} ms", C.cyan))
		end
		vim.list_extend(cmds, {
			sep(C.gray),
			e("[Done] Python finished", C.green_bold),
			sep(C.gray),
			"else " .. e("[Error] Syntax error — fix the code above", C.red_bold),
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

--- 本地调试运行（C/C++ 带 -DIHXNAN 宏；其他语言自动回退为普通运行）
local run_local = function()
	-- 复用 run_code：files = "none" 即无样例数据、加 -DIHXNAN、不判题
	run_code({ files = "none", macro = true, cmd = "rl" })
end

-- ======================== 3. 剪贴板 → 数据文件 ========================

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

-- ======================== 4. 运行/判题快捷键 ========================
keymap.set("n", "rc", function()
	-- 配合插件：遍历 <名>.1.in / <名>.2.in…，逐组与 <名>.N.out 判题；不加 -DIHXNAN
	run_code({ files = "plugin", macro = false, check = true, cmd = "rc", timeout = TIME_LIMIT })
end, { desc = "rc：插件样例全部判题（不加 -DIHXNAN，对比 .N.out）" })
keymap.set("n", "rl", run_local, { desc = "rl：本地调试运行C/C++代码（带 -DIHXNAN 宏）" })
keymap.set("n", "rd", function()
	-- 没有样例就别起终端：程序会卡在等 stdin
	if vim.fn.filereadable(paths.in_file(nil, 1)) == 0 then
		print("⚠️ [rd] 没有样例文件，先收题，或改用 rn 读 <名>.txt")
		return
	end
	-- 同 rc；加 -DIHXNAN（gdb 走 stderr，stdout 只留程序结果）
	run_code({ files = "plugin", macro = true, check = true, cmd = "rd", timeout = TIME_LIMIT })
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

return { e = e, C = C, run_script = run_script, paste_to_data = paste_to_data }
