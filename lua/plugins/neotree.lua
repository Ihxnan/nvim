return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons", -- 可选，用于显示图标
    },
    lazy = false,
    config = function()
      -- 配置 Neo-tree
      require('neo-tree').setup({
        -- 窗口位置，可选: left, right, top, bottom
        window = {
          position = "left",
          width = 25, -- 窗口宽度
        },
        -- 文件系统配置
        filesystem = {
          -- 重点修改：将follow_current_file从布尔值改为表格配置
          follow_current_file = {
            enabled = true, -- 启用跟随当前文件功能
            leave_dirs_open = false -- 可选：是否保持目录展开状态
          },
          hijack_netrw_behavior = "open_current", -- 替代netrw
        },
      })

      -- 设置快捷键: Ctrl+n 打开/关闭文件树
      vim.keymap.set('n', '<leader>e', '<Cmd>Neotree toggle<CR>', { 
        desc = 'Toggle Neo-tree file explorer',
        noremap = true, 
        silent = true 
      })

    end
  }
}
