return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        -- 配置项留空则使用默认设置
        -- 可在此处添加自定义配置
        -- 例如：
        -- window = {
        --   border = "single", -- 边框样式
        --   position = "bottom", -- 位置
        -- },
        -- triggers_blacklist = {
        --   i = { "j", "k" },
        --   v = { "j", "k" },
        -- },
    },
    keys = {
        {
            "<leader>?",
            function()
                require("which-key").show({ global = false })
            end,
            desc = "Buffer Local Keymaps (which-key)",
        },
    },
}
