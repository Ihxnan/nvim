return {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "UIEnter",
    opts = {
        indent = {
            char = "│",
            -- 彩虹色循环，与 tokyonight 配色匹配
            highlight = {
                "IblIndent1",
                "IblIndent2",
                "IblIndent3",
                "IblIndent4",
                "IblIndent5",
                "IblIndent6",
            },
        },
        scope = { enabled = true, show_start = false, show_end = false },
    },
    config = function(_, opts)
        -- 高亮组必须在 setup 之前定义，否则 ibl 会报错
        local colors = {
            "#f7768e", -- red
            "#e0af68", -- yellow
            "#7aa2f7", -- blue
            "#ff9e64", -- orange
            "#9ece6a", -- green
            "#bb9af7", -- violet
        }
        for i, color in ipairs(colors) do
            vim.api.nvim_set_hl(0, "IblIndent" .. i, { fg = color, nocombine = true })
        end

        require("ibl").setup(opts)
    end,
}