--
-- ███████╗██╗   ██╗██████╗  █████╗
-- ██╔════╝██║   ██║██╔══██╗██╔══██╗
-- ███████╗██║   ██║██║  ██║███████║
-- ╚════██║██║   ██║██║  ██║██╔══██║
-- ███████║╚██████╔╝██████╔╝██║  ██║
-- ╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝
--
--  功能：用 sudo 权限保存文件（自动检测权限不足）
--        开启 smart_edit 后，检测到文件不可写时自动切换为 suda:// 前缀
--        - :w 自动走 sudo，无需手动 :SudaWrite
--        - :SudaWrite / :SudaRead 仍可手动强制使用

return {
    "lambdalisue/suda.vim",
    lazy = false, -- 需要在启动时注册 BufEnter 自动命令，不能用 cmd 懒加载
    init = function()
        -- smart_edit：打开不可读/不可写的文件时，自动切换到 suda:// 前缀
        -- 这样 :w 就直接通过 sudo 写入，无需手动 :SudaWrite
        vim.g.suda_smart_edit = true
        -- 可选：不交互（无密码 sudo 时启用）
        -- vim.g["suda#noninteractive"] = true
        -- 可选：自定义 sudo 密码提示文字（默认英文 "Password: "）
        -- vim.g["suda#prompt"] = "密码: " 
    end,
}
