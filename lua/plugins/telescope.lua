return {
    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        -- 配置函数，在插件加载后执行
        config = function()
            local builtin = require("telescope.builtin")

            vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })

            -- 搜索界面透明背景
            vim.api.nvim_set_hl(0, "TelescopeNormal",       { bg = "none" })
            vim.api.nvim_set_hl(0, "TelescopeBorder",       { bg = "none" })
            vim.api.nvim_set_hl(0, "TelescopePromptNormal", { bg = "none" })
            vim.api.nvim_set_hl(0, "TelescopePromptBorder", { bg = "none" })
            vim.api.nvim_set_hl(0, "TelescopeResultsNormal", { bg = "none" })
            vim.api.nvim_set_hl(0, "TelescopeResultsBorder", { bg = "none" })
            vim.api.nvim_set_hl(0, "TelescopePreviewNormal", { bg = "none" })
            vim.api.nvim_set_hl(0, "TelescopePreviewBorder", { bg = "none" })
        end,
    },
}