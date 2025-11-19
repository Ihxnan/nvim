return {
    -- 安装 mini.icons 插件
    {
        'echasnovski/mini.icons',
        version = false, -- 不指定版本，使用最新版
        -- 配置在加载时自动生效
        config = function()
            require('mini.icons').setup({
                style = 'glyph', -- 图标风格：'glyph' 或 'ascii'

                -- 按类别自定义图标（留空则使用默认值）
                default   = {},
                directory = {},
                extension = {},
                file      = {},
                filetype  = {},
                lsp       = {},
                os        = {},

                -- 控制文件扩展名解析逻辑
                use_file_extension = function(ext, file)
                    return true -- 始终使用文件扩展名来匹配图标
                end,
            })
        end,
    },

    -- 可添加其他 mini.nvim 系列插件
    {
        'echasnovski/mini.comment', -- 代码注释插件
        version = false,
        config = function()
            require('mini.comment').setup()
        end,
    },

    {
        'echasnovski/mini.cursorword', -- 高亮当前光标所在单词
        version = false,
        config = function()
            require('mini.cursorword').setup()
        end,
    },
}

