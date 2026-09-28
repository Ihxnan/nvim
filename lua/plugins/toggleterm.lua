return {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = { "<A-t>" },
    config = true,
    opts = {
        open_mapping = [[<A-t>]],
        direction = "float",
        shell = vim.o.shell,
    },
}
