-- 必须在 lazy.nvim 之前禁用内置 netrw：
-- lazy 启动时会 source runtime 里的 netrw 加载桩（packadd netrw），
-- 若这之后再设 g:loaded_netrw=1，netrw 的 autoload/netrw.vim 会提前 finish，
-- 导致 VimEnter 触发 netrw#LocalBrowseCheck 时报 E117。放在最前面可彻底禁用。
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("config.lazy")
require("config.options")
require("config.keymaps")
require("config.companion").setup() -- 启动 Competitive Companion 监听器（写 .in/.out）
