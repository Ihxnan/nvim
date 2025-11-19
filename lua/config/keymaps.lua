vim.g.mapleader = " "

local keymap = vim.keymap

local run_code = function()
	-- 保存当前文件
	vim.cmd("w")

	-- 获取当前文件类型
	local filetype = vim.bo.filetype

	-- 根据文件类型执行不同命令
	if filetype == "cpp" or filetype == "c" then
		-- C/C++ 编译运行命令
		vim.cmd("split | terminal powershell g++ -O3 % && a.exe && del a.exe")
	elseif filetype == "python" then
		-- Python 运行命令
		vim.cmd("split | terminal powershell python3 %")
	elseif filetype == "html" then
		-- html
		vim.cmd("split | terminal powershell chromium %")
	else
		-- 其他文件类型提示
		print("不支持的文件类型: " .. filetype)
	end
end

local run_code_with_data = function()
	-- 保存当前文件
	vim.cmd("w")

	-- 获取当前文件类型
	local filetype = vim.bo.filetype

	-- 根据文件类型执行不同命令
	if filetype == "cpp" or filetype == "c" then
		-- C/C++ 编译运行命令
		vim.cmd("split | terminal powershell g++ -O3 % && a.exe < data && del a.exe")
	elseif filetype == "python" then
		vim.cmd("split | terminal powershell python3 % < data")
	else
		-- 其他文件类型提示
		print("不支持的文件类型: " .. filetype)
	end
end

local preview_code = function()
	vim.cmd("w")

	local filetype = vim.bo.filetype

	if filetype == "md" or filetype == "markdown" or filetype == "vimwiki" then
		vim.cmd("MarkdownPreview")
	elseif filetype == "html" then
		vim.cmd("LivePreview start")
	else
		print("不支持的文件类型: " .. filetype)
	end
end

local close_code = function()
	local filetype = vim.bo.filetype

	if filetype == "md" or filetype == "markdown" or filetype == "vimwiki" then
		vim.cmd("MarkdownPreviewStop")
	elseif filetype == "html" then
		vim.cmd("LivePreview close")
	else
		print("不支持的文件类型: " .. filetype)
	end
end

-- ---------- 插入模式 ---------- ---
keymap.set("i", "jk", "<ESC>")

keymap.set("i", "<C-s>", "<ESC>:w<CR>")

-- keymap.set("i", "<F5>", run_code, { desc = "run the code" })

-- ---------- 终端模式 ---------- ---
keymap.set("t", "jk", "<C-\\><C-n>")

-- ---------- 视觉模式 ---------- ---
-- 单行或多行移动
keymap.set("v", "J", ":m '>+1<CR>gv=gv")
keymap.set("v", "K", ":m '<-2<CR>gv=gv")
keymap.set("v", "ii", "<ESC>")

-- ---------- 正常模式 ---------- ---
-- <leader> a new window
keymap.set("n", "<leader>wv", "<C-w>s", { desc = "leader a window vertically" })
keymap.set("n", "<leader>wh", "<C-w>v", { desc = "leader a window horizontally " })
keymap.set("n", "<leader>t", ":w<CR><C-w>v:terminal powershell<CR>i", { desc = "leader a terminal with insert mode" })
keymap.set("n", "<leader>i", ":w<CR><C-w>v:terminal powershell<CR>iiflow<CR>", { desc = "open iflow" })
keymap.set("n", "rc", run_code, { desc = "run the code" })
keymap.set("n", "rd", run_code_with_data, { desc = "run the code with the data" })
keymap.set("n", "dp", "<C-w>s:terminal powershell<CR>idp", { desc = "run the code with the data" })
-- keymap.set("n", "<F5>", run_code, { desc = "run the code" })

-- go window focus {h, j, k, l}
keymap.set("n", "<C-h>", "<C-w>h", { desc = "go window left" })
keymap.set("n", "<C-j>", "<C-w>j", { desc = "go window down" })
keymap.set("n", "<C-k>", "<C-w>k", { desc = "go window up" })
keymap.set("n", "<C-l>", "<C-w>l", { desc = "go window right" })

-- goto window move {H, J, K, L}
keymap.set("n", "gwh", "<C-w>H", { desc = "goto window left" })
keymap.set("n", "gwj", "<C-w>J", { desc = "goto window down" })
keymap.set("n", "gwk", "<C-w>K", { desc = "goto window up" })
keymap.set("n", "gwl", "<C-w>L", { desc = "goto window right" })

-- g window quit {d, o}
keymap.set("n", "gwd", "<C-w>q", { desc = "g window delete" })
keymap.set("n", "gwo", "<C-w>o", { desc = "g window delete other" })

-- g window resize {=, -}
vim.keymap.set("n", "<M-=>", "<C-w>>", { desc = "g window enlarge" })
vim.keymap.set("n", "<M-->", "<C-w><", { desc = "g window shrink" })

-- 取消高亮
keymap.set("n", "<leader>nh", ":nohl<CR>")

-- goto buffer {h, l}
keymap.set("n", "gbh", ":bprevious<CR>", { desc = "goto buffer left" })
keymap.set("n", "gbl", ":bnext<CR>", { desc = "goto buffer right" })
keymap.set("n", "gbd", ":bdelete<CR>", { desc = "buffer delete" })
keymap.set("n", "gbo", ":BufferLineCloseOthers<CR>", { desc = "buffer delete other" })

-- bufferline
keymap.set("n", "H", ":w<CR>:BufferLineCyclePre<CR>")
keymap.set("n", "L", ":w<CR>:BufferLineCycleNext<CR>")

-- 浏览器预览
keymap.set("n", "gmp", preview_code)
keymap.set("n", "gmc", close_code)

-- 快速保存
keymap.set("n", "<C-S>", ":w<CR>")

keymap.set("n", "j", "gj")
keymap.set("n", "k", "gk")

-- 快速移动
keymap.set("n", "J", "5j")
keymap.set("n", "K", "5k")

-- 查询跳转
keymap.set("n", "n", "nzz")
keymap.set("n", "N", "Nzz")

-- 剪切一行
keymap.set("n", "<C-x>", "dd")
-- 复制一行
keymap.set("n", "<C-c>", "yy")
-- 复制全部内容
keymap.set("n", "<C-a><C-c>", "ggyG``")
-- 剪切全部内容
keymap.set("n", "<C-a><C-x>", "ggdG")
-- 粘贴
keymap.set("n", "<C-v>", "p")
-- 全部替换
keymap.set("n", "<C-a><C-v>", "gg0vG$p")
