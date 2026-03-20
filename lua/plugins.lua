-- Neovim 插件管理配置 (plugins.lua)
-- 使用 lazy.nvim 作为插件管理器

-- 1. 自动安装 lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 2. 插件列表
local plugins = {
  -- 文件浏览器：nvim-tree
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons", -- 文件图标支持
    },
    config = function()
      -- 禁用默认的 netrw（vim 自带的文件浏览器）
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
      -- nvim-tree 的基础配置
      local status, nvim_tree = pcall(require, "nvim-tree")
      if not status then return end
      
      nvim_tree.setup({
        sort_by = "case_sensitive",
        view = {
          width = 30,
        },
        renderer = {
          group_empty = true,
        },
        filters = {
          dotfiles = false, -- 显示隐藏文件（根据需要可设为 true）
        },
      })
    end,
  },

  -- LSP / Linter / Formatter 管理器：mason.nvim 及配套插件
  {
    "williamboman/mason.nvim",
    dependencies = {
      "williamboman/mason-lspconfig.nvim", -- 连接 mason 和 lspconfig
      "neovim/nvim-lspconfig",             -- Neovim 官方 LSP 配置集合
    },
    config = function()
      local mason_status, mason = pcall(require, "mason")
      if not mason_status then return end
      -- 初始化 mason
      mason.setup()

      local mason_lspconfig_status, mason_lspconfig = pcall(require, "mason-lspconfig")
      if not mason_lspconfig_status then return end
      -- 配置 mason-lspconfig，指定我们需要自动安装的语言服务器
      -- 我们主要针对 Python (pyright/ruff) 和 Golang (gopls)
      mason_lspconfig.setup({
        ensure_installed = {
          "pyright", -- Python 静态类型检查及补全
          "gopls",   -- Golang 官方 LSP
          -- "ruff_lsp", -- Python linter & formatter (可选，速度极快)
        },
      })
    end,
  },

  -- 自动代码补全：nvim-cmp 及其生态
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",     -- LSP 补全源
      "hrsh7th/cmp-buffer",       -- 缓冲区文本补全源
      "hrsh7th/cmp-path",         -- 文件路径补全源
      "hrsh7th/cmp-cmdline",      -- 命令行补全源
      "L3MON4D3/LuaSnip",         -- 代码片段引擎 (Snippet Engine)
      "saadparwaiz1/cmp_luasnip", -- 代码片段补全源
      "rafamadriz/friendly-snippets", -- 预置的各种语言代码片段集合
    },
  },

  -- 语法高亮：nvim-treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local status, configs = pcall(require, "nvim-treesitter.configs")
      if not status then return end

      configs.setup({
        -- 添加你需要高亮的语言
        ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "python", "go", "gomod", "gowork", "gosum", "bash", "json", "yaml", "markdown" },
        -- 自动安装缺失的解析器
        auto_install = true,
        highlight = {
          enable = true,
          -- 禁用 Vim 原生的高亮，使用 Treesitter 的高亮
          additional_vim_regex_highlighting = false,
        },
        indent = { enable = true }, -- 启用基于 Treesitter 的智能缩进
      })
    end,
  },

  -- 全局搜索：telescope.nvim
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = { 
      "nvim-lua/plenary.nvim",
      -- 可选：如果你本地有 C 编译器 (gcc/clang) 和 make，可以加上下面这个提升搜索性能
      -- { "nvim-telescope/telescope-fzf-native.nvim", build = "make" }
    },
    config = function()
      local status, telescope = pcall(require, "telescope")
      if not status then return end

      telescope.setup({
        defaults = {
          -- 这里可以添加 telescope 的全局配置
          file_ignore_patterns = { "node_modules", ".git/", ".cache" },
        },
      })
    end,
  },
}

-- 3. 配置 lazy.nvim
local opts = {
  -- 可以在这里添加 lazy.nvim 的特定配置，例如 UI 颜色等
}

require("lazy").setup(plugins, opts)
