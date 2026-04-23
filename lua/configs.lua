-- 其他全局配置与杂项 (configs.lua)

local M = {}

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
local function path_exists(path)
  return path ~= nil and vim.uv.fs_stat(path) ~= nil
end

local function resolve_python(root_dir)
  local candidates = {}
  local cwd = vim.uv.cwd() or vim.fn.getcwd()

  if root_dir and root_dir ~= "" then
    table.insert(candidates, root_dir .. "/.venv/bin/python")
  end

  if cwd and cwd ~= "" and cwd ~= root_dir then
    table.insert(candidates, cwd .. "/.venv/bin/python")
  end

  for _, candidate in ipairs(candidates) do
    if vim.fn.executable(candidate) == 1 then
      return candidate
    end
  end

  local system_python = vim.fn.exepath("python3")
  if system_python ~= "" then
    return system_python
  end

  return nil
end

local function python_root_dir()
  return vim.fs.root(0, {
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    ".venv",
    ".git",
  }) or vim.fn.getcwd()
end

local function python_has_module(python, module_name)
  if not python or python == "" or vim.fn.executable(python) ~= 1 then
    return false
  end

  vim.fn.system({ python, "-c", "import " .. module_name })
  return vim.v.shell_error == 0
end

local function mason_debugpy_python()
  local mason_python = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
  if vim.fn.executable(mason_python) == 1 then
    return mason_python
  end

  return nil
end

local function resolve_debugpy_python(root_dir)
  local mason_python = mason_debugpy_python()
  if mason_python then
    return mason_python
  end

  local project_python = resolve_python(root_dir)
  if python_has_module(project_python, "debugpy") then
    return project_python
  end

  local system_python = vim.fn.exepath("python3")
  if python_has_module(system_python, "debugpy") then
    return system_python
  end

  return nil
end

local function pyright_settings(root_dir)
  local settings = {
    python = {
      pythonPath = resolve_python(root_dir),
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "workspace",
      },
    },
  }

  if root_dir and path_exists(root_dir .. "/.venv") then
    settings.python.venvPath = root_dir
    settings.python.venv = ".venv"
  end

  if root_dir and path_exists(root_dir .. "/src") then
    settings.python.analysis.extraPaths = { root_dir .. "/src" }
  end

  return settings
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

function M.setup_cmp()
  local cmp_status, cmp = pcall(require, "cmp")
  local luasnip_status, luasnip = pcall(require, "luasnip")
  if not (cmp_status and luasnip_status) then
    return
  end

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

function M.lsp_capabilities()
  local capabilities_status, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  if capabilities_status then
    capabilities = cmp_nvim_lsp.default_capabilities()
  end

  return capabilities
end

function M.lsp_on_attach(_, bufnr)
  local bufopts = { noremap = true, silent = true, buffer = bufnr }
  local keymap = vim.keymap.set

  keymap("n", "gd", vim.lsp.buf.definition, bufopts)
  keymap("n", "K", vim.lsp.buf.hover, bufopts)
  keymap("n", "gi", vim.lsp.buf.implementation, bufopts)
  keymap("n", "gr", vim.lsp.buf.references, bufopts)
  keymap("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
  keymap("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
  keymap("n", "<leader>f", function()
    vim.lsp.buf.format({ async = true })
  end, bufopts)
end

function M.setup_toggleterm()
  local status, toggleterm = pcall(require, "toggleterm")
  if not status then
    return
  end

  toggleterm.setup({
    open_mapping = nil,
    start_in_insert = true,
    insert_mappings = false,
    terminal_mappings = false,
    persist_size = false,
    shade_terminals = true,
    direction = "float",
    float_opts = {
      border = "curved",
      width = function()
        return math.floor(vim.o.columns * 0.9)
      end,
      height = function()
        return math.floor(vim.o.lines * 0.85)
      end,
    },
  })
end

--------------------------------------------------------------------------------
-- DAP 配置
--------------------------------------------------------------------------------
function M.setup_dap()
  local dap_status, dap = pcall(require, "dap")
  local dapui_status, dapui = pcall(require, "dapui")
  local dap_python_status, dap_python = pcall(require, "dap-python")
  if not (dap_status and dapui_status and dap_python_status) then
    return
  end

  dapui.setup({
    controls = {
      enabled = false,
    },
    layouts = {
      {
        elements = {
          { id = "scopes", size = 0.50 },
          { id = "breakpoints", size = 0.17 },
          { id = "stacks", size = 0.17 },
          { id = "watches", size = 0.16 },
        },
        position = "left",
        size = 40,
      },
      {
        elements = {
          { id = "repl", size = 0.5 },
          { id = "console", size = 0.5 },
        },
        position = "bottom",
        size = 12,
      },
    },
  })

  vim.fn.sign_define("DapBreakpoint", {
    text = "B",
    texthl = "DiagnosticSignError",
    linehl = "",
    numhl = "",
  })
  vim.fn.sign_define("DapBreakpointCondition", {
    text = "C",
    texthl = "DiagnosticSignWarn",
    linehl = "",
    numhl = "",
  })
  vim.fn.sign_define("DapStopped", {
    text = ">",
    texthl = "DiagnosticSignInfo",
    linehl = "Visual",
    numhl = "",
  })

  dap.listeners.before.attach.dapui_config = function()
    dapui.open()
  end
  dap.listeners.before.launch.dapui_config = function()
    dapui.open()
  end
  dap.listeners.before.event_terminated.dapui_config = function()
    dapui.close()
  end
  dap.listeners.before.event_exited.dapui_config = function()
    dapui.close()
  end

  local registry_ok, mason_registry = pcall(require, "mason-registry")
  if registry_ok then
    local package_ok, debugpy_package = pcall(mason_registry.get_package, "debugpy")
    if package_ok and debugpy_package and not debugpy_package:is_installed() then
      debugpy_package:install()
    end
  end

  local function project_python_path()
    return resolve_python(python_root_dir())
  end

  local debugpy_python = resolve_debugpy_python(python_root_dir())
  if debugpy_python then
    dap_python.setup(debugpy_python)
  else
    vim.schedule(function()
      vim.notify(
        "Python 调试适配器未就绪。请等待 Mason 安装 debugpy，或手动执行 `python3 -m pip install debugpy`。",
        vim.log.levels.WARN
      )
    end)
  end

  dap.configurations.python = {
    {
      type = "python",
      request = "launch",
      name = "Launch current file",
      program = "${file}",
      cwd = "${workspaceFolder}",
      console = "integratedTerminal",
      justMyCode = true,
      pythonPath = project_python_path,
    },
    {
      type = "python",
      request = "launch",
      name = "Launch current file with args",
      program = "${file}",
      cwd = "${workspaceFolder}",
      console = "integratedTerminal",
      justMyCode = true,
      args = function()
        local input = vim.trim(vim.fn.input("Args: "))
        if input == "" then
          return {}
        end
        return vim.split(input, "%s+", { trimempty = true })
      end,
      pythonPath = project_python_path,
    },
  }

  vim.api.nvim_create_user_command("DapInstallPython", function()
    local ok, registry = pcall(require, "mason-registry")
    if not ok then
      vim.notify("mason-registry 不可用，无法自动安装 debugpy。", vim.log.levels.ERROR)
      return
    end

    local package_ok, debugpy_package = pcall(registry.get_package, "debugpy")
    if not package_ok or not debugpy_package then
      vim.notify("Mason registry 中未找到 debugpy 包。", vim.log.levels.ERROR)
      return
    end

    if debugpy_package:is_installed() then
      vim.notify("debugpy 已安装。", vim.log.levels.INFO)
      return
    end

    debugpy_package:install()
    vim.notify("已触发 Mason 安装 debugpy。", vim.log.levels.INFO)
  end, { desc = "Install debugpy with Mason" })
end

--------------------------------------------------------------------------------
-- LSP 配置
--------------------------------------------------------------------------------
function M.setup_lsp()
  if not (vim.lsp and vim.lsp.config and vim.lsp.enable) then
    return
  end

  local capabilities = M.lsp_capabilities()
  vim.lsp.config("gopls", {
    capabilities = capabilities,
    on_attach = M.lsp_on_attach,
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

  vim.lsp.config("pyright", {
    capabilities = capabilities,
    on_attach = M.lsp_on_attach,
    before_init = function(_, config)
      config.settings = pyright_settings(config.root_dir)
    end,
    on_new_config = function(config, root_dir)
      config.settings = pyright_settings(root_dir)
    end,
    settings = pyright_settings(vim.uv.cwd() or vim.fn.getcwd()),
  })
  vim.lsp.enable("pyright")

  vim.lsp.config("ts_ls", {
    capabilities = capabilities,
    on_attach = function(client, bufnr)
      M.lsp_on_attach(client, bufnr)

      vim.keymap.set("n", "<leader>co", "<cmd>LspTypescriptSourceAction<CR>", {
        noremap = true,
        silent = true,
        buffer = bufnr,
        desc = "TypeScript source actions",
      })
    end,
    settings = {
      typescript = {
        inlayHints = {
          includeInlayParameterNameHints = "literals",
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints = false,
          includeInlayVariableTypeHintsWhenTypeMatchesName = false,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
        },
      },
      javascript = {
        inlayHints = {
          includeInlayParameterNameHints = "all",
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints = false,
          includeInlayVariableTypeHintsWhenTypeMatchesName = false,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
        },
      },
    },
  })
  vim.lsp.enable("ts_ls")
end

return M
