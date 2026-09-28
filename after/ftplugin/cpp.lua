vim.opt_local.indentexpr = nil  -- 禁用 Treesitter 缩进
vim.opt_local.cindent = true    -- 启用 C 风格缩进
vim.opt_local.cinoptions = "{1,N-s:0,}0,l1,:0,g0,t0,+s,c0,C1,(0,m1"  -- 对齐 Microsoft + Allman 风格
vim.opt_local.shiftwidth = 4    -- 缩进 4 空格
vim.opt_local.tabstop = 4       -- Tab 显示为 4 空格
vim.opt_local.expandtab = true  -- 用空格代替 Tab
