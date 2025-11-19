return {
    'brianhuster/live-preview.nvim',
    dependencies = {
        -- You can choose one of the following pickers
        'nvim-telescope/telescope.nvim',
    },
    config = function ()
        require('live-preview').setup({
            browser = 'chromium'
        })
    end
}
