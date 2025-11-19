return
{
    "akinsho/bufferline.nvim",
    version = "*", -- 使用最新稳定版，也可指定具体版本如 "v3.6.0"
    dependencies = {
        "nvim-tree/nvim-web-devicons", -- bufferline 依赖图标，可选
        "nvim-lspconfig", -- 若用 diagnostics = "nvim_lsp" ，依赖 lspconfig
    },
    event = "VeryLazy", -- 懒加载时机，VeryLazy 表示 Neovim 启动完成后加载
    config = function()
        require("bufferline").setup({
            options = {
                always_show_bufferline = false,
                diagnostics = "nvim_lsp",
                offsets = {
                    {
                        filetype = "neo-tree",
                        text = "File Explorer",
                        highlight = "Directory",
                        text_align = "left",
                    },
                },
            },
        })
    end
}
