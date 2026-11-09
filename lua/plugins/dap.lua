return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio",
			"theHamsta/nvim-dap-virtual-text",
		},
		keys = {
			-- VSCode 风格
			{
				"<F5>",
				function()
					require("dap").continue()
				end,
				desc = "DAP：启动/继续",
			},
			{
				"<F9>",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "DAP：切换断点",
			},
			{
				"<F10>",
				function()
					require("dap").step_over()
				end,
				mode = { "n", "i" },
				desc = "DAP：步过",
			},
			{
				"<F11>",
				function()
					require("dap").step_into()
				end,
				mode = { "n", "i" },
				desc = "DAP：步入",
			},
			{
				"<S-F11>",
				function()
					require("dap").step_out()
				end,
				desc = "DAP：步出",
			},
			{
				"<S-F5>",
				function()
					require("dap").terminate()
				end,
				desc = "DAP：结束调试",
			},
			{
				"<leader>dB",
				function()
					require("dap").set_breakpoint(vim.fn.input("条件: "))
				end,
				desc = "DAP：条件断点",
			},
			{
				"<leader>du",
				function()
					require("dapui").toggle()
				end,
				desc = "DAP：开关调试面板",
			},
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			dapui.setup()
			require("nvim-dap-virtual-text").setup()

			-- codelldb 由 Mason 安装（见 lua/plugins/mason.lua 的 ensure_installed）
			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = {
					command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
					args = { "--port", "${port}" },
				},
			}

			-- 启动前编译当前文件：gcc/g++ -g -O0 -DIHXNAN，编译不过就不进入调试
			local function build()
				vim.cmd("write")
				local src = vim.fn.expand("%:p")
				local out = vim.fn.fnamemodify(src, ":r")
				local cc = (vim.bo.filetype == "c") and "gcc" or "g++"
				local msg = vim.fn.system({ cc, "-g", "-O0", "-DIHXNAN", src, "-o", out })
				if vim.v.shell_error ~= 0 then
					vim.fn.setqflist({}, " ", {
						title = "编译失败",
						lines = vim.split(msg, "\n", { trimempty = true }),
					})
					vim.cmd("copen")
					print("❌ [dap] 编译失败，已取消调试")
					return nil
				end
				return out
			end

			local cpp = {
				{
					name = "Launch (g++ -g -O0 -DIHXNAN)",
					type = "codelldb",
					request = "launch",
					program = build,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
					args = {},
				},
			}
			dap.configurations.cpp = cpp
			dap.configurations.c = cpp

			-- 开始调试时自动打开面板，结束时自动关闭
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end
		end,
	},
}
