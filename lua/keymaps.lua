-- Neovim 按键映射配置 (keymaps.lua)

-- 设置 leader 键为空格 (通常放在所有 map 前面)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- === 基础操作 ===
-- 保存与退出
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit neovim" })
-- 取消搜索高亮
map("n", "<ESC>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- === 窗口操作 ===
-- 窗口切换
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })
-- 分割窗口
map("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "Split window vertically" })
map("n", "<leader>sh", "<cmd>split<CR>", { desc = "Split window horizontally" })

-- === 文本编辑 ===
-- 视觉模式下连续缩进
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

-- === 缓冲/Buffer 操作 ===
-- 左右切换 tab / buffer (根据使用习惯)
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Close buffer" })

-- === 插件特定按键映射 ===
-- nvim-tree
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle NvimTree" })      -- 开启/关闭文件树
map("n", "<leader>o", "<cmd>NvimTreeFindFile<CR>", { desc = "Reveal current file in NvimTree" }) -- 在文件树中定位当前文件

-- telescope (全局搜索)
-- 这里不再使用 pcall，改为通过 :Telescope 命令的方式来映射，这样就不会在启动时要求模块已加载，完全依赖 lazy.nvim 的延迟加载机制
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "Find files" })             -- 全局搜索文件
map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", { desc = "Live grep (keywords)" })    -- 全局搜索关键字
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "Find buffers" })              -- 搜索已打开的缓冲区
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "Find help tags" })          -- 搜索帮助文档
map("n", "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", { desc = "Find document symbols" }) -- 当前文件 symbol
map("n", "<leader>fS", "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", { desc = "Find workspace symbols" }) -- 全局 symbol（输入关键词筛选）
map("n", "<leader>cq", function()
  pcall(vim.cmd, "cclose")
  pcall(vim.cmd, "lclose")
end, { desc = "Close quickfix/location list" })
map("n", "<leader>gb", "<cmd>Gitsigns blame_line<CR>", { desc = "Git blame current line" })
map("n", "<leader>gB", "<cmd>Gitsigns toggle_current_line_blame<CR>", { desc = "Toggle inline git blame" })
map("n", "<leader>gp", "<cmd>Gitsigns preview_hunk<CR>", { desc = "Preview git hunk" })
map("n", "]c", "<cmd>Gitsigns next_hunk<CR>", { desc = "Next git hunk" })
map("n", "[c", "<cmd>Gitsigns prev_hunk<CR>", { desc = "Prev git hunk" })
