--
--  ██████╗ ██████╗ ███╗   ███╗██████╗  █████╗ ███╗   ██╗██╗   ██╗
-- ██╔════╝██╔═══██╗████╗ ████║██╔══██╗██╔══██╗████╗  ██║╚██╗ ██╔╝
-- ██║     ██║   ██║██╔████╔██║██████╔╝███████║██╔██╗ ██║ ╚████╔╝
-- ██║     ██║   ██║██║╚██╔╝██║██╔═══╝ ██╔══██║██║╚██╗██║  ╚██╔╝
-- ╚██████╗╚██████╔╝██║ ╚═╝ ██║██║     ██║  ██║██║ ╚████║   ██║
--  ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝
--
--  功能：Competitive Companion 本地监听器（替代现成插件）
--        浏览器扩展「Competitive Companion」点绿色 + 后，会把题目解析成 JSON
--        POST 到 http://127.0.0.1:27121/ ；本模块接住它并落盘：
--          第 1 组样例 input → <源文件>.in        output → <源文件>.out
--          第 n 组样例(>=2) input → <源文件>.n.in  output → <源文件>.n.out
--        路径规则与 keymaps.lua 的 rd/rc 完全一致（见 config.paths）。
--        注意：目标按「当前 nvim 缓冲区」推导，收题前请把对应源文件切到前台。

local paths = require("config.paths")

local M = {}

-- 监听端口：Competitive Companion 默认会往这组端口 POST，27121 是其中之一，无需改扩展。
M.PORT = 27121

-- vim.uv 句柄（防止重复启动）
M._server = nil

-- 空响应：告诉扩展收到了（任意 2xx 即可），随后关闭连接
local OK_RESPONSE = "HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"

--- 若字符串末尾无换行则补一个（空串保持为空）
local function with_newline(s)
	s = s or ""
	if s == "" or s:sub(-1) == "\n" then
		return s
	end
	return s .. "\n"
end

--- 写文件（自动建父目录），返回是否成功
local function write_file(path, content)
	paths.ensure_dir(path)
	local f = io.open(path, "w")
	if not f then
		return false
	end
	f:write(content)
	f:close()
	return true
end

--- 从累积的原始请求中尝试取出完整 body；未收全返回 nil
local function extract_body(chunks)
	local raw = table.concat(chunks)
	local header_end = raw:find("\r\n\r\n", 1, true)
	if not header_end then
		return nil
	end
	local content_length = tonumber(raw:sub(1, header_end - 1):match("[Cc]ontent%-[Ll]ength:%s*(%d+)")) or 0
	local body = raw:sub(header_end + 4)
	if #body < content_length then
		return nil
	end
	return body:sub(1, content_length)
end

--- 处理一份题目 JSON：把各组样例写入当前缓冲区对应的 .in / .out
--- @param body string 请求体（题目 JSON）
function M.handle(body)
	local ok, prob = pcall(vim.json.decode, body)
	if not ok or type(prob) ~= "table" then
		vim.notify("Competitive Companion: failed to parse JSON", vim.log.levels.ERROR)
		return
	end

	local tests = prob.tests
	if type(tests) ~= "table" or #tests == 0 then
		vim.notify("Competitive Companion: this problem has no sample tests", vim.log.levels.WARN)
		return
	end

	local written = 0
	for i, t in ipairs(tests) do
		if type(t) == "table" then
			local in_ok = write_file(paths.in_file(0, i), with_newline(t.input))
			-- 有期望输出才写 .out（否则 rc 的 [ -f ] 检查会因空文件误判 WA）
			local out_ok = true
			if t.output ~= nil then
				out_ok = write_file(paths.out_file(0, i), with_newline(t.output))
			end
			if in_ok and out_ok then
				written = written + 1
			end
		end
	end

	vim.notify(
		string.format("Received \"%s\": wrote %d sample group(s)\n%s", prob.name or "unnamed", written, paths.in_file(0, 1)),
		vim.log.levels.INFO
	)
end

--- 处理单个客户端连接：收完 HTTP 请求后交给 handle
local function on_client(client)
	local chunks = {}
	client:read_start(function(err, data)
		if err then
			client:close()
			return
		end
		if data then
			chunks[#chunks + 1] = data
		end

		local body = extract_body(chunks)
		if body then
			client:read_stop()
			client:write(OK_RESPONSE, function()
				client:close()
			end)
			-- uv 回调不是 vim 主循环安全上下文，必须 schedule 后再调 vim API
			vim.schedule(function()
				M.handle(body)
			end)
		elseif not data then
			-- 对端关闭但请求不完整，直接丢弃
			client:close()
		end
	end)
end

--- 启动监听（重复调用无副作用）
function M.setup()
	if M._server then
		return
	end

	local uv = vim.uv or vim.loop
	local server = uv.new_tcp()

	local ok, ret, err = pcall(server.bind, server, "127.0.0.1", M.PORT)
	if not ok or not ret then
		vim.notify(
			string.format("Competitive Companion: listen failed (port %d maybe in use): %s", M.PORT, tostring(err or ret)),
			vim.log.levels.WARN
		)
		server:close()
		return
	end

	server:listen(128, function(listen_err)
		if listen_err then
			return
		end
		local client = uv.new_tcp()
		server:accept(client)
		on_client(client)
	end)

	M._server = server
	vim.notify(string.format("Competitive Companion listening on http://127.0.0.1:%d/", M.PORT), vim.log.levels.INFO)
end

return M
