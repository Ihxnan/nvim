-- lua/plugins/editor.lua
return {
    {
        "windwp/nvim-ts-autotag",
        -- 依赖 Tree-sitter，确保先加载
        dependencies = "nvim-treesitter/nvim-treesitter",
        -- 只在特定文件类型下激活（可选，默认全支持）
        ft = {
            "html", "xml", "vue", "javascript", "typescript", "tsx", "jsx", "markdown"
        },
        config = function()
            -- 配置插件
            require("nvim-ts-autotag").setup({
                -- 启用自动重命名闭合标签（核心功能）
                auto_rename = true,
                -- 启用自动删除闭合标签（删除开始标签时）
                auto_close = true,
                -- 启用自动闭合标签（输入开始标签时生成闭合标签）
                auto_open = true,
            })
        end,
    }
}
