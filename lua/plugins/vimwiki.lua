-- Vimwiki插件配置
return {
  'vimwiki/vimwiki',
  init = function()
    -- Vimwiki的基本设置
    vim.g.vimwiki_list = {
      {
        path = '~/vimwiki/',  -- Wiki文件存放路径
        syntax = 'markdown',  -- 使用markdown语法
        ext = '.md',          -- 文件扩展名
      }
    }
    
    vim.g.vimwiki_auto_ext = 0
    
    -- 快捷键映射设置
    vim.g.vimwiki_key_mappings = {
      all_maps = 1,          -- 启用所有默认映射
      global = 1,            -- 启用全局映射
      headers = 1,           -- 启用标题映射
      text_objs = 1,         -- 启用文本对象
      table_format = 1,      -- 启用表格格式化
      table_mappings = 1,    -- 启用表格映射
      lists = 1,             -- 启用列表映射
      links = 1,             -- 启用链接映射
      html = 1,              -- 启用HTML映射
      mouse = 1,             -- 启用鼠标映射
    }

    -- goto wiki index
    vim.keymap.set('n', 'gwi', '<cmd>VimwikiIndex<CR>', { desc = 'goto wiki index' })
    -- g wiki creat diary 
    vim.keymap.set('n', 'gwc', '<cmd>VimwikiMakeDiaryNote<CR>', { desc = 'Open diary wiki-file' })

    vim.keymap.set('n', 'gws', '<cmd>VimwikiSplitLink<CR>', 
      { desc = 'Split follow/create wiki link' })
    vim.keymap.set('v', 'gws', '<cmd>VimwikiSplitLink<CR>', 
      { desc = 'Split follow/create wiki link' })

    vim.keymap.set('n', 'gwv', '<cmd>VimwikiVSplitLink<CR>', 
      { desc = 'VSplit follow/create wiki link ' })
    vim.keymap.set('v', 'gwv', '<cmd>VimwikiVSplitLink<CR>', 
      { desc = 'VSplit follow/create wiki link ' })
  end
}
    
