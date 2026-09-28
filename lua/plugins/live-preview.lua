return {
    "brianhuster/live-preview.nvim",
    ft = "markdown",
    dependencies = {
        "nvim-telescope/telescope.nvim",
    },
    config = function()
        require("live-preview").setup({
            browser = "chromium",
        })
    end,
}