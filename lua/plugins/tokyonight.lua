return {
    {
        "folke/tokyonight.nvim",
        lazy = true,  -- 主题通常不懒加载
        priority = 1000,  -- 确保优先加载
        config = function()
        require("tokyonight").setup({
            style = "night",  -- 可选: storm, night, day
            transparent = true,  -- 是否透明背景
            terminal_colors = true,
        })
        vim.cmd("colorscheme tokyonight")
        end
}
}
