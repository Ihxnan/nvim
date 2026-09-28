return {
    "dhruvasagar/vim-table-mode",
    ft = { "markdown", "text" },
    config = function()
        vim.g.table_mode_corner = "|"
        -- 进入 markdown 时自动打开表格模式（输入 | 自动扩展列宽、对齐）
        vim.schedule(function()
            vim.cmd("TableModeToggle")
        end)
    end,
}
