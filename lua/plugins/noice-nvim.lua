-- 插件配置以 Lua 模块形式返回，这是 Neovim 插件管理器（如 Lazy.nvim）的标准配置格式
return {
    -- 配置 folke/noice.nvim 插件
    {
        "folke/noice.nvim",  -- 插件名称（GitHub 仓库路径）
        
        -- opts 是插件的默认配置选项，会传递给 setup 函数
        opts = {
            lsp = {  -- LSP 相关配置
                -- 签名帮助（函数参数提示）配置
                signature = {
                    auto_open = {
                        enabled = false,  -- 关闭自动弹出签名帮助
                        trigger = false,  -- 不自动触发
                        luasnip = false,  -- 不与 luasnip 联动触发
                        throttle = 50,    -- 触发节流时间（毫秒），这里关闭后无效
                    },
                    enabled = true,  -- 保留签名帮助功能，允许手动触发（如通过快捷键）
                    view = "virtualtext",  -- 签名帮助显示方式：虚拟文本（行内显示）
                },
                
                -- LSP 覆盖配置：让 noice 接管一些 LSP 相关的默认行为
                override = {
                    -- 让 noice 处理 LSP 信息转 markdown 的过程
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    -- 让 noice 处理 markdown 内容的样式渲染
                    ["vim.lsp.util.stylize_markdown"] = true,
                    -- 让 noice 处理 cmp 补全项的文档显示
                    ["cmp.entry.get_documentation"] = true,
                },
            },
            -- 其他全局选项保持默认（会被下面 config 中的配置合并）
        },
        
        -- 插件加载时机：VeryLazy 事件触发时（基本是 Neovim 启动完成后）
        event = "VeryLazy",
        
        -- 依赖插件：noice 正常工作需要这些插件
        dependencies = {
            "rcarriga/nvim-notify",  -- 用于显示通知的插件
            "MunifTanjim/nui.nvim",  -- UI 组件库，noice 的基础
            "nvim-treesitter/nvim-treesitter",  -- 语法高亮支持，用于渲染 markdown 等
        },
        
        -- 配置函数：插件加载后执行的初始化逻辑
        config = function(_, opts)
            -- 合并默认配置和用户配置（opts），"force" 表示用户配置优先级更高
            require("noice").setup(vim.tbl_deep_extend("force", {
                cmdline = {  -- 命令行相关配置
                    enabled = true,  -- 启用 noice 的命令行替代
                    view = "cmdline_popup",  -- 命令行显示方式：弹窗
                    opts = {},  -- 额外选项（留空使用默认）
                    
                    -- 命令行格式配置：不同命令有不同的样式
                    format = {
                        cmdline = { pattern = "^:", icon = "", lang = "vim" },  -- 普通命令行（:开头）
                        search_down = { kind = "search", pattern = "^/", icon = " ", lang = "regex" },  -- 向下搜索（/开头）
                        search_up = { kind = "search", pattern = "^%?", icon = " ", lang = "regex" },  -- 向上搜索（?开头）
                        filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },  -- 终端命令（:!开头）
                        lua = { pattern = "^:%s*lua%s+", icon = "", lang = "lua" },  -- Lua 命令（:lua开头）
                        help = { pattern = "^:%s*h%s+", icon = "" },  -- 帮助命令（:h开头）
                    },
                },
                
                completions = {  -- 补全相关配置
                    enabled = true,  -- 启用补全功能
                    sources = {  -- 补全数据源
                        { name = "nvim_lua" },  -- Neovim Lua API 补全
                        { name = "cmdline" },   -- 命令行补全
                        { name = "luasnip" },   -- LuaSnip 代码片段补全
                    },
                    autocomplete = {  -- 自动补全设置
                        enabled = true,    -- 启用自动补全
                        trigger = true,    -- 允许触发自动补全
                        debounce = 50,     -- 输入防抖时间（毫秒）
                    },
                },
                
                views = {  -- 视图配置：定义各种弹窗/界面的样式和位置
                    cmdline_popup = {  -- 命令行弹窗样式
                        position = {
                            row = 5,       -- 距离顶部5行
                            col = "50%",   -- 水平居中
                        },
                        size = {
                            width = 80,    -- 宽度80列
                            height = "auto",  -- 高度自适应内容
                        },
                    },
                    
                    popupmenu = {  -- 补全菜单弹窗样式
                        relative = "editor",  -- 相对编辑器定位
                        position = {
                            row = 8,       -- 距离顶部8行（在命令行下方）
                            col = "50%",   -- 水平居中
                        },
                        size = {
                            width = 80,    -- 宽度80列
                            height = 10,   -- 高度10行
                        },
                        border = {
                            style = "rounded",  -- 圆角边框
                            padding = { 0, 1 }, -- 内边距
                        },
                        win_options = {
                            -- 窗口高亮设置：正常文本用 Normal 高亮，边框用 DiagnosticInfo 高亮
                            winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
                        },
                    },
                    
                    -- 消息通知视图配置（用于 messages 和 notify）
                    notify = {
                        size = {
                            width = "80%",   -- 宽度为编辑器的80%
                            height = "auto", -- 高度自适应内容
                        },
                        position = {
                            col = "50%",    -- 水平居中
                            row = "90%",    -- 垂直位置：靠近底部（90%高度处）
                        },
                    },
                    
                    -- 备用消息视图配置（如果 messages.view 设置为 "messages" 则启用）
                    messages = {
                        size = {
                            width = "70%",  -- 宽度为编辑器的70%
                            height = 20,    -- 固定高度20行
                        },
                    },
                },
                
                messages = {  -- 消息系统配置
                    enabled = true,  -- 启用消息功能
                    view = "notify",  -- 消息使用 "notify" 视图（对应上面 views.notify 配置）
                    view_error = "notify",  -- 错误消息也使用 "notify" 视图
                },
                
                history = {  -- 历史记录配置
                    view = "split",  -- 历史记录显示方式：水平分屏
                    view_search = "virtualtext",  -- 搜索历史显示方式：虚拟文本
                },
            }, opts))  -- 结束配置合并
            
            -- 配置 nvim-notify 插件（noice 依赖它显示通知）
            require("notify").setup({
                background_colour = "#000000",  -- 通知背景色（黑色）
                max_width = 100,  -- 通知最大宽度
                max_height = 20,  -- 通知最大高度
            })
            
            -- 增强命令行补全体验的 Vim 选项设置
            vim.opt.wildmenu = true  -- 启用增强型命令行菜单
            -- 补全模式：先匹配最长公共部分，再显示所有选项
            vim.opt.wildmode = "longest:full,full"
            vim.opt.wildignorecase = true  -- 补全时忽略大小写
        end,
    },
}
