-- Neovim 基础选项配置 (options.lua)

local opt = vim.opt

-- 外观与显示
opt.number = true           -- 显示绝对行号
opt.relativenumber = true   -- 显示相对行号
opt.cursorline = true       -- 高亮当前行
opt.termguicolors = true    -- 开启 True Color (24-bit 颜色) 支持
opt.signcolumn = "yes"      -- 始终显示标志列（防止左侧抖动）
opt.wrap = false            -- 禁止代码自动折行

-- 缩进与制表符
opt.tabstop = 4             -- 1 个 tab 对应的空格数
opt.shiftwidth = 4          -- 缩进时使用的空格数
opt.expandtab = true        -- 将 tab 转换为空格
opt.smartindent = true      -- 智能缩进
opt.autoindent = true       -- 自动缩进

-- 搜索行为
opt.ignorecase = true       -- 搜索时忽略大小写
opt.smartcase = true        -- 如果包含大写字母，则不忽略大小写
opt.hlsearch = false        -- 不高亮所有匹配项 (可以根据需要开启)
opt.incsearch = true        -- 输入搜索模式时即时高亮匹配项

-- 其他系统设置
opt.mouse = "a"             -- 允许使用鼠标 (全模式)
opt.clipboard = "unnamedplus" -- 使用系统剪贴板 (需要本地支持，如 xclip/wl-clipboard/pbcopy)
opt.updatetime = 250        -- 降低刷新时间 (默认 4000 毫秒)，有助于提供更好的 UI 响应体验
opt.swapfile = false        -- 禁用 swap 文件
opt.undofile = true         -- 开启持久化撤销历史
opt.splitright = true       -- 垂直分割窗口时，向右侧分割
opt.splitbelow = true       -- 水平分割窗口时，向下侧分割

-- 确保文件类型与语法高亮开启，并使用对比更明显的内置主题
vim.cmd("filetype plugin indent on")
vim.cmd("syntax on")
pcall(vim.cmd.colorscheme, "habamax")
