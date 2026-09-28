return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" }, -- 懒加载
    config = function()
        require("gitsigns").setup({
            signs = {
                -- add = { text = "▎" }, -- 新增行符号
                -- change = { text = "▎" }, -- 修改行符号
                -- delete = { text = "" }, -- 删除行符号

                add = { text = "" }, -- 经典新增行图标 (plus circle)
                change = { text = "" }, -- 经典修改行图标 (pencil)
                delete = { text = "" }, -- 经典删除行图标 (minus circle)
                topdelete = { text = "" },
                changedelete = { text = "" },
                untracked = { text = "" }, -- 未跟踪文件图标
            },
            -- 快捷键绑定（缓冲区局部）
            on_attach = function(bufnr)
                local gs = package.loaded.gitsigns
                local map = function(mode, l, r, desc)
                    vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
                end

                -- 跳转差异
                map("n", "]c", function()
                    gs.next_hunk()
                end, "Next Git hunk")
                map("n", "[c", function()
                    gs.prev_hunk()
                end, "Prev Git hunk")
                -- 暂存/撤销/查看差异
                map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
                map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
                map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
                map("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
                map("n", "<leader>hu", gs.undo_stage_hunk, "Undo stage hunk")
                -- 查看仓库状态
                map("n", "<leader>gb", function()
                    gs.blame_line({ full = true })
                end, "Blame line")
            end,
        })
    end,
}
