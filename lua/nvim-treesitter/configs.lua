local M = {}

local state = {
  auto_install = false,
  ensure_installed = {},
  modules = {
    highlight = {
      enable = false,
      additional_vim_regex_highlighting = false,
    },
    indent = {
      enable = false,
    },
  },
}

local function list_contains(list, value)
  return type(list) == "table" and vim.tbl_contains(list, value)
end

local function ensure_parsers_compat()
  local ok, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok or type(parsers) ~= "table" then
    return
  end

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

local function module_enabled(module, lang, bufnr)
  if type(module) ~= "table" then
    return false
  end

  local enabled = module.enable
  if enabled == nil or enabled == false then
    return false
  end

  if type(enabled) == "table" and not list_contains(enabled, lang) then
    return false
  end

  local disabled = module.disable
  if type(disabled) == "function" and disabled(lang, bufnr) then
    return false
  end
  if list_contains(disabled, lang) then
    return false
  end

  local ok = pcall(vim.treesitter.language.inspect, lang)
  if not ok then
    ok = pcall(vim.treesitter.language.add, lang)
  end
  return ok
end

function M.setup(opts)
  ensure_parsers_compat()

  opts = opts or {}

  if opts.ensure_installed ~= nil then
    state.ensure_installed = opts.ensure_installed
  end

  if opts.auto_install ~= nil then
    state.auto_install = opts.auto_install
  end

  for name, value in pairs(opts) do
    if name ~= "ensure_installed" and name ~= "auto_install" then
      if type(value) == "table" then
        state.modules[name] = vim.tbl_deep_extend("force", state.modules[name] or {}, value)
      else
        state.modules[name] = value
      end
    end
  end
end

function M.get_module(name)
  return state.modules[name] or {}
end

function M.is_enabled(name, lang, bufnr)
  ensure_parsers_compat()
  return module_enabled(state.modules[name], lang, bufnr)
end

return M
