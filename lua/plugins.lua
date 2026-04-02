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
    cmd = {
      "NvimTreeToggle",
      "NvimTreeFindFile",
      "NvimTreeFocus",
    },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Toggle NvimTree" },
      { "<leader>o", "<cmd>NvimTreeFindFile<CR>", desc = "Reveal current file in NvimTree" },
    },
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
          adaptive_size = true,
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
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("configs").setup_lsp()
    end,
  },

  {
    "williamboman/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "williamboman/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = {
        "pyright",
        "gopls",
        "ts_ls",
      },
    },
  },

  -- 自动代码补全：nvim-cmp 及其生态
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",     -- LSP 补全源
      "hrsh7th/cmp-buffer",       -- 缓冲区文本补全源
      "hrsh7th/cmp-path",         -- 文件路径补全源
      "hrsh7th/cmp-cmdline",      -- 命令行补全源
      "L3MON4D3/LuaSnip",         -- 代码片段引擎 (Snippet Engine)
      "saadparwaiz1/cmp_luasnip", -- 代码片段补全源
      "rafamadriz/friendly-snippets", -- 预置的各种语言代码片段集合
    },
    config = function()
      require("configs").setup_cmp()
    end,
  },

  -- 语法高亮：nvim-treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    build = ":TSUpdate",
    config = function()
      local status, treesitter = pcall(require, "nvim-treesitter")
      if not status then return end

      local languages = {
        "c",
        "lua",
        "vim",
        "vimdoc",
        "query",
        "python",
        "go",
        "gomod",
        "gowork",
        "gosum",
        "bash",
        "javascript",
        "typescript",
        "tsx",
        "json",
        "yaml",
        "markdown",
      }
      treesitter.setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
      })

      -- New nvim-treesitter enables features via Neovim APIs rather than old module toggles.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = languages,
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },

  -- 全局搜索：telescope.nvim
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    cmd = "Telescope",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live grep (keywords)" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Find buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Find help tags" },
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", desc = "Find document symbols" },
      { "<leader>fS", "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", desc = "Find workspace symbols" },
    },
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
          preview = {
            -- Keep Telescope preview stable across Neovim/Treesitter mismatches.
            treesitter = false,
          },
        },
      })
    end,
  },

  -- Git signs / blame
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local status, gitsigns = pcall(require, "gitsigns")
      if not status then return end

      gitsigns.setup({
        current_line_blame = false,
      })
    end,
  },
}

-- 3. 配置 lazy.nvim
local opts = {
  -- 可以在这里添加 lazy.nvim 的特定配置，例如 UI 颜色等
  defaults = {
    lazy = true,
  },
}

require("lazy").setup(plugins, opts)
