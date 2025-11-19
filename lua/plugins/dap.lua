-- ~/.config/nvim/lua/plugins/dap.lua

-- 快捷键配置函数
local function setup_keymaps()
	local dap = require("dap")
	local dapui = require("dapui")

	-- 调试相关快捷键
	vim.keymap.set("n", "<F4>", function()
		vim.cmd("!g++ -g -O0 % -o out")
		require("dap").continue()
	end, { desc = "DAP: 继续执行" })
	vim.keymap.set("n", "<F5>", dap.continue, { desc = "DAP: 继续执行" })
	vim.keymap.set("n", "<F10>", dap.step_over, { desc = "DAP: 单步跳过" })
	vim.keymap.set("n", "<F11>", dap.step_into, { desc = "DAP: 单步进入" })
	vim.keymap.set("n", "<S-F11>", dap.step_out, { desc = "DAP: 单步退出" })
	vim.keymap.set("n", "<F9>", dap.toggle_breakpoint, { desc = "DAP: 切换断点" })
	vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "DAP: 切换断点" })
	vim.keymap.set("n", "<leader>B", function()
		dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
	end, { desc = "DAP: 设置条件断点" })
	vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "DAP: 打开/关闭调试UI" })
	vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "DAP: 重新运行上次调试" })
	vim.keymap.set("n", "<C-A-b>", function()
		dapui.float_element("breakpoints", { enter = true })
	end, { desc = "DAP: 打开断点窗口" })
end

-- 主配置
return {
	"mfussenegger/nvim-dap",
	dependencies = {
		-- nvim-dap-ui 配置（手动指定布局，解决 nil 错误）
		{
			"rcarriga/nvim-dap-ui",
			config = function()
				local dapui = require("dapui")
				-- 显式配置 UI 布局，避免默认配置冲突
				dapui.setup({
					layouts = {
						{
							elements = {
								{ id = "scopes", size = 0.25 }, -- 变量作用域
								"breakpoints", -- 断点列表
								"stacks", -- 调用栈
								"watches", -- 监视列表
							},
							size = 40, -- 左侧面板宽度（列数）
							position = "left", -- 左侧显示
						},
						{
							elements = {
								"repl", -- 交互式终端
								"console", -- 调试控制台
							},
							size = 10, -- 底部面板高度（行数）
							position = "bottom", -- 底部显示
						},
					},
				})
			end,
			dependencies = { "nvim-neotest/nvim-nio" }, -- 必需依赖
		},
		-- 虚拟文本显示变量
		{ "theHamsta/nvim-dap-virtual-text", opts = {} },
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		-- 调试器启动/退出时自动打开/关闭 UI
		dap.listeners.after.event_initialized["dapui_config"] = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated["dapui_config"] = function()
			dapui.close()
		end
		dap.listeners.before.event_exited["dapui_config"] = function()
			dapui.close()
		end

		-- ===================== C/C++ 调试配置 =====================
		-- 1. 配置 lldb-dap 适配器（Arch Linux 新版 LLDB 使用 lldb-dap）
		dap.adapters.lldb = {
			type = "executable",
			command = "C:\\Users\\Administrator\\scoop\\apps\\llvm\\current\\bin\\lldb-dap.exe", -- 直接用你的路径
			name = "lldb",
		}

		-- 根据你的实际终端进行修改
		dap.defaults.fallback.external_terminal = {
			command = "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe", -- 你的终端程序路径
			args = { "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command" },
		}

		-- 2. 调试会话配置
		dap.configurations.cpp = {
			{
				name = "Launch", -- 配置名称（在调试菜单中显示）
				type = "lldb", -- 对应上面的适配器名称
				request = "launch", -- 启动类型（launch/attach）
				-- 程序路径：调试时提示输入（默认当前目录）
				program = function()
					return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
				end,
				cwd = "${workspaceFolder}", -- 工作目录（当前项目根目录）
				stopOnEntry = false, -- 是否在程序入口处暂停（false 不暂停）
				-- args = { "<", "${workspaceFolder}/data" }, -- 传递给程序的参数（空表示无参数）
				args = {}, -- 传递给程序的参数（空表示无参数）
				runInTerminal = false, -- 是否在终端中运行（false 则在 DAP UI 控制台输出）
				-- 额外配置：解决部分编译路径问题
				sourceFileMap = {
					["/proc/self/cwd"] = "${workspaceFolder}",
				},
			},
		}

		-- C 语言复用 C++ 的配置
		dap.configurations.c = dap.configurations.cpp

		-- ===================== 其他语言配置（可选） =====================
		-- 如果你需要调试 Rust，可以添加以下配置
		-- dap.configurations.rust = {
		--   {
		--     name = "Launch",
		--     type = "lldb",
		--     request = "launch",
		--     program = function()
		--       return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
		--     end,
		--     cwd = "${workspaceFolder}",
		--     stopOnEntry = false,
		--   },
		-- }

		-- 最后调用快捷键配置
		setup_keymaps()
	end,
}
