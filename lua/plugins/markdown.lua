return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  build = "cd app && yarn install",
  init = function()
    -- 设置支持的文件类型
    vim.g.mkdp_filetypes = { "markdown", "html" }
    
    -- 自动启动预览
    vim.g.mkdp_auto_start = 0  -- 1 为启用，0 为禁用
    
    -- 指定浏览器 (根据你的实际浏览器可执行文件路径修改)
    -- Windows 示例: vim.g.mkdp_browser = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
    -- Linux 示例: vim.g.mkdp_browser = "/usr/bin/google-chrome"
    -- Mac 示例: vim.g.mkdp_browser = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    vim.g.mkdp_browser = "/usr/bin/chromium"  -- 简单写法，前提是浏览器已添加到环境变量
    
    -- 设置快捷键 (在markdown文件中生效)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function()
        -- vim.keymap.set("n", "gmp", "<cmd>MarkdownPreview<CR>", {
        --   buffer = true,
        --   desc = "goto markdown preview"
        -- })
      end
    })
  end,
  ft = { "markdown" }
}
