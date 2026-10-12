--
-- ██████╗  █████╗ ████████╗██╗  ██╗███████╗
-- ██╔══██╗██╔══██╗╚══██╔══╝██║  ██║██╔════╝
-- ██████╔╝███████║   ██║   ███████║███████╗
-- ██╔═══╝ ██╔══██║   ██║   ██╔══██║╚════██║
-- ██║     ██║  ██║   ██║   ██║  ██║███████║
-- ╚═╝     ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝
--
--  功能：统一推导「源文件专属数据文件」路径，供 keymaps.lua 与 companion.lua 共用
--        插件样例（rc/rd，多组，全部编号）：
--            /home/ihxnan/WorkSpace/test.cpp → /home/ihxnan/Data/WorkSpace/test.1.in
--                                            → /home/ihxnan/Data/WorkSpace/test.1.out
--                                            → …test.2.in / test.2.out …
--        手动数据（rp/rn/cp/cd，单文件）：
--            /home/ihxnan/WorkSpace/test.cpp → /home/ihxnan/Data/WorkSpace/test.txt
--        即 <数据根目录>/<源文件父目录名>/<源文件名>.<ext>

local M = {}

M.DATA_ROOT = vim.fn.expand("~") .. "/Data"

--- 取缓冲区的「父目录名 + 文件名（去扩展名）」
--- @param bufnr number|nil 缓冲区号，nil/0 表示当前缓冲区
--- @return string|nil parent 源文件父目录名（直接位于数据根目录时返回 nil）
--- @return string stem 文件名（去扩展名），未命名缓冲区回退 "unnamed"
function M.parts(bufnr)
	bufnr = bufnr or 0
	local abs = vim.api.nvim_buf_get_name(bufnr)
	if abs == "" then
		return nil, "unnamed"
	end
	abs = vim.fn.fnamemodify(abs, ":p") -- 强制绝对路径
	local parent = vim.fn.fnamemodify(abs, ":h:t")
	local stem = vim.fn.fnamemodify(abs, ":t:r")
	if parent == "" or parent == "." then
		return nil, stem
	end
	return parent, stem
end

--- 组装 <数据根目录>/<父目录名>/<名>
local function join(parent, name)
	if parent then
		return M.DATA_ROOT .. "/" .. parent .. "/" .. name
	end
	return M.DATA_ROOT .. "/" .. name
end

--- 第 n 组插件样例文件路径（<名>.n.<ext>，n 从 1 起）
--- @param bufnr number|nil 缓冲区号
--- @param n number|nil 组号（1 起，缺省 1）
--- @param ext string 扩展名（in / out）
--- @return string
function M.test_file(bufnr, n, ext)
	local parent, stem = M.parts(bufnr)
	return join(parent, stem .. "." .. (n or 1) .. "." .. ext)
end

--- 第 n 组输入文件（<名>.n.in）
function M.in_file(bufnr, n)
	return M.test_file(bufnr, n or 1, "in")
end

--- 第 n 组期望答案文件（<名>.n.out）
function M.out_file(bufnr, n)
	return M.test_file(bufnr, n or 1, "out")
end

--- 手动数据文件（rp/rn/cp/cd 用）：<名>.txt
function M.txt_file(bufnr)
	local parent, stem = M.parts(bufnr)
	return join(parent, stem .. ".txt")
end

--- 确保路径的父目录存在（写入 / 打开前调用）
function M.ensure_dir(path)
	vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
end

return M
