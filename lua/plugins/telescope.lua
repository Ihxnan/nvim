return {
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    dependencies = { 'nvim-lua/plenary.nvim' },
    -- 配置函数，在插件加载后执行
    config = function()
      -- 引入 telescope 内置功能
      local builtin = require('telescope.builtin')
      
      -- 设置快捷键
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
    end
  }
}

