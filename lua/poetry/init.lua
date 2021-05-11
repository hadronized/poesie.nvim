local json = require'poetry.json'
local fs = require'plenary.path'

local LOG_DEBUG = false
local function log(msg, ...)
  if LOG_DEBUG then
    if arg ~= nil then
      print(msg, unpack(arg))
    else
      print(msg)
    end
  end
end

local config_dir = fs.new(vim.fn.stdpath('config'))

-- Vanilla Neovim configuration.
local nvim_config_path = config_dir / 'nvim.json'
if nvim_config_path:exists() then
  log('reading Vanilla Neovim configuration')
  local config = json.decode(nvim_config_path:read())
  require'poetry.mapper.nvim'.interpret(config)
end

-- LSP configuration.
local lsp_config_path = config_dir / 'lsp.json'
if lsp_config_path:exists() then
  log('reading LSP configuration')
  local config = json.decode(lsp_config_path:read())
  require'poetry.mapper.lsp'.interpret(config)
end
