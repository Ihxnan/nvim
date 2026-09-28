return {
    "numToStr/Comment.nvim",
    keys = {
        { "gc", mode = { "n", "v" }, desc = "Comment" },
    },
    opts = {
        mappings = {
            basic = true,
            extra = true,
        },
    },
    config = function(_, opts)
        require("Comment").setup(opts)
        local ft = require("Comment.ft")
        local fn_calc = ft.calculate
        ft.calculate = function(ctx)
            local ok, parser = pcall(vim.treesitter.get_parser, vim.api.nvim_get_current_buf())
            if not ok or not parser then
                return require("Comment.ft").get(vim.bo.filetype, ctx.ctype)
            end
            return fn_calc(ctx)
        end
    end,
}
