-- 其他全局配置与杂项 (configs.lua)

-- 这部分可以用来放置不属于 options, keymaps 或 plugins 的代码。
-- 例如：自动命令 (autocmd) 的定义，界面特定重置等。

-- 示例：高亮被复制(Yank)的文本
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.highlight.on_yank()
    end,
    group = highlight_group,
    pattern = "*",
})

--------------------------------------------------------------------------------
-- Python provider / 项目 venv 解析
--------------------------------------------------------------------------------
local function resolve_python()
  local cwd = vim.uv.cwd() or vim.fn.getcwd()
  local project_python = cwd .. "/.venv/bin/python"

  if vim.fn.executable(project_python) == 1 then
    return project_python
  end

  local system_python = vim.fn.exepath("python3")
  if system_python ~= "" then
    return system_python
  end

  return nil
end

local python_host = resolve_python()
if python_host then
  vim.g.python3_host_prog = python_host
end

if vim.fn.exists(":LspInfo") == 0 then
  vim.api.nvim_create_user_command("LspInfo", function()
    vim.cmd("checkhealth vim.lsp")
  end, { desc = "Alias to :checkhealth vim.lsp" })
end

--------------------------------------------------------------------------------
-- Treesitter 兼容补丁
--------------------------------------------------------------------------------
do
  local ok, parsers = pcall(require, "nvim-treesitter.parsers")
  if ok and type(parsers) == "table" then
    if type(parsers.ft_to_lang) ~= "function" then
      parsers.ft_to_lang = function(ft)
        return vim.treesitter.language.get_lang(ft) or ft
      end
    end
    if type(parsers.get_parser) ~= "function" then
      parsers.get_parser = function(bufnr, lang)
        return vim.treesitter.get_parser(bufnr, lang)
      end
    end
  end
end

do
  local ok, ts_configs = pcall(require, "nvim-treesitter.configs")
  if ok and type(ts_configs) == "table" and type(ts_configs.is_enabled) ~= "function" then
    ts_configs.is_enabled = function(_, lang, _)
      return pcall(vim.treesitter.language.add, lang)
    end
  end
end

--------------------------------------------------------------------------------
-- 自动补全配置 (nvim-cmp)
--------------------------------------------------------------------------------
-- 使用 pcall 保护调用，防止在插件未完全加载时引发报错
local cmp_status, cmp = pcall(require, "cmp")
local luasnip_status, luasnip = pcall(require, "luasnip")

if cmp_status and luasnip_status then
  -- 加载 vscode 风格的代码片段库 (friendly-snippets)
  require("luasnip.loaders.from_vscode").lazy_load()

  cmp.setup({
    snippet = {
      -- 指定使用的 snippet 引擎
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    mapping = cmp.mapping.preset.insert({
      ["<C-k>"] = cmp.mapping.select_prev_item(), -- 上一个建议
      ["<C-j>"] = cmp.mapping.select_next_item(), -- 下一个建议
      ["<C-b>"] = cmp.mapping.scroll_docs(-4),    -- 向上滚动文档
      ["<C-f>"] = cmp.mapping.scroll_docs(4),     -- 向下滚动文档
      ["<C-Space>"] = cmp.mapping.complete(),     -- 手动触发补全
      ["<C-e>"] = cmp.mapping.abort(),            -- 取消补全
      ["<CR>"] = cmp.mapping.confirm({ select = true }), -- 回车确认补全
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          fallback()
        end
      end, { "i", "s" }),
      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { "i", "s" }),
    }),
    -- 补全来源，优先级按顺序递减
    sources = cmp.config.sources({
      { name = "nvim_lsp" }, -- LSP 补全
      { name = "luasnip" },  -- 代码片段补全
    }, {
      { name = "buffer" },   -- 当前文件内容补全
      { name = "path" },     -- 路径补全
    }),
  })

  -- 为搜索模式 (`/` 和 `?`) 配置命令行补全
  cmp.setup.cmdline({ "/", "?" }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = "buffer" }
    }
  })

  -- 为命令行模式 (`:`) 配置命令行补全
  cmp.setup.cmdline(":", {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = "path" }
    }, {
      { name = "cmdline" }
    })
  })
end

--------------------------------------------------------------------------------
-- LSP 配置 (针对 Python 和 Golang)
--------------------------------------------------------------------------------
if vim.lsp and vim.lsp.config and vim.lsp.enable then
  -- 获取 nvim-cmp 提供的 LSP capabilities，让 LSP 服务器知道我们支持高级补全
  local capabilities_status, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  if capabilities_status then
    capabilities = cmp_nvim_lsp.default_capabilities()
  end

  -- 定义 LSP attach 时的快捷键（只有当 LSP 成功挂载到当前文件时才会生效）
  local on_attach = function(_, bufnr)
    local bufopts = { noremap = true, silent = true, buffer = bufnr }
    local keymap = vim.keymap.set

    keymap("n", "gd", vim.lsp.buf.definition, bufopts)         -- 跳转到定义
    keymap("n", "K", vim.lsp.buf.hover, bufopts)               -- 悬浮显示文档
    keymap("n", "gi", vim.lsp.buf.implementation, bufopts)     -- 跳转到实现
    keymap("n", "gr", vim.lsp.buf.references, bufopts)         -- 查找引用
    keymap("n", "<leader>rn", vim.lsp.buf.rename, bufopts)     -- 重命名变量
    keymap("n", "<leader>ca", vim.lsp.buf.code_action, bufopts) -- 代码操作/快速修复
    keymap("n", "<leader>f", function()                        -- 格式化当前文件
      vim.lsp.buf.format { async = true }
    end, bufopts)
  end

  vim.lsp.config("gopls", {
    capabilities = capabilities,
    on_attach = on_attach,
    settings = {
      gopls = {
        analyses = {
          unusedparams = true,
        },
        staticcheck = true,
        gofumpt = true,
      },
    },
  })
  vim.lsp.enable("gopls")

  local pyright_python = resolve_python()
  local cwd = vim.uv.cwd() or vim.fn.getcwd()

  vim.lsp.config("pyright", {
    capabilities = capabilities,
    on_attach = on_attach,
    settings = {
      python = {
        pythonPath = pyright_python,
        venvPath = cwd,
        venv = ".venv",
        analysis = {
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
          diagnosticMode = "workspace",
        },
      },
    },
  })
  vim.lsp.enable("pyright")
end
