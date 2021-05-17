-- Internal LSP configuration mapper.
--
-- This module handles configuring LSP the easy way.
--
-- # Configuration
--
-- {
--   "diagnostics": {
--     "underline": <true>,
--     "virtual_text": <true>,
--     "signs": <true>,
--     "update_in_insert": <false>,
--     "severity_sort": <false>
--   },
--
--   "capabilities": {
--     "snippet": <true>,
--     "resolve": {
--       "documentation": <true>,
--       "detail": <true>,
--       "additional-text-edits": <true>
--     },
--     "lsp_status": <true>
--   },
--
--   "symbol-kind-labels": {
--     "text": " ",
--     "method": " ",
--     "function": " ",
--     "ctor": " ",
--     "field": " ",
--     "variable": " ",
--     "class": " ",
--     "interface": " ",
--     "module": " ",
--     "property": " ",
--     "unit": " ",
--     "value": " ",
--     "enum": "螺",
--     "keyword": " ",
--     "snippet": " ",
--     "color": " ",
--     "file": " ",
--     "reference": " ",
--     "folder": " ",
--     "member": " ",
--     "constant": " ",
--     "struct": " ",
--     "event": " ",
--     "operator": "璉",
--     "parameter": " "
--   }
--
--   "keybindings": …,
--
--   "servers": {
--     "rust_analyzer": {
--       "setup": …,
--       "lsp-status": <true>,
--       "highlight": <true>,
--       "format": <true>,
--       "keybindings": …
--     }
--   }
-- }

local M = {}

local plugin_exists = require'poesie.plugin'.plugin_exists

local function configure_diagnostics(c)
  vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
    underline = c.underline or true,
    virtual_text = c.virtual_text or true,
    signs = c.signs or true,
    update_in_insert = c.update_in_insert or false,
    severity_sort = c.severity_sort or false
  })
end

local function configure_lsp_status()
  local lsp_status = require('lsp-status')
  lsp_status.register_progress()
  lsp_status.config {
    current_function = true,
    status_symbol = '%#StatusLineLinNbr#LSP',
    indicator_errors = '%#StatusLineLSPErrors#',
    indicator_warnings = '%#StatusLineLSPWarnings#',
    indicator_info = '%#StatusLineLSPInfo#',
    indicator_hints = '%#StatusLineLSPHints#',
    indicator_ok = '%#StatusLineLSPOk#',
  }

  vim.cmd [[
    hi StatusLineLinNbr guibg=#23272e guifg=#51afef
    hi StatusLineLSPOk guibg=#23272e guifg=#98be65
    hi StatusLineLSPErrors guibg=#23272e guifg=#ff6c6b
    hi StatusLineLSPWarnings guibg=#23272e guifg=#ECBE7B
    hi StatusLineLSPInfo guibg=#23272e guifg=#51afef
    hi StatusLineLSPHints guibg=#23272e guifg=#c678dd
  ]]
end

local function extract_capabilities(c)
  local capabilities = vim.lsp.protocol.make_client_capabilities()

  capabilities.textDocument.completion.completionItem.snippetSupport = c.snippet or true

  if c.resolve then
    local props = {}
    local props_map = {
      documentation = 'documentation',
      detail = 'detail',
      ['additional-text-edits'] = 'additionalTextEdits'
    }

    for key, value in pairs(props_map) do
      if c[key] then
        props[#props + 1] = value
      end
    end

    capabilities.textDocument.completion.completionItem.resolveSupport = { properties = props }
  end

  if c.lsp_status and plugin_exists('lsp-status') then
    vim.tbl_extend('keep', capabilities, require'lsp-status'.capabilities)
  end

  return capabilities
end

local function extract_symbol_kind_labels(c)
  local ordered_labels = {
    'text',
    'method',
    'function',
    'ctor',
    'field',
    'variable',
    'class',
    'interface',
    'module',
    'property',
    'unit',
    'value',
    'enum',
    'keyword',
    'snippet',
    'color',
    'file',
    'reference',
    'folder',
    'member',
    'constant',
    'struct',
    'event',
    'operator',
    'parameter',
  }

  local symbols = {}

  for i, label in ipairs(ordered_labels) do
    symbols[i] = c[label]
  end

  return symbols
end

local function configure_local_keybindings(bufnr, keybindings)
  require'poesie.keybindings'.traverse_keybindings(keybindings, function(mode, seq, cmd, opts)
    vim.api.nvim_buf_set_keymap(bufnr, mode, seq, cmd, opts)
  end)
end

local function extract_attach(c)
  return function(client)
    if c.highlight and client.resolved_capabilities.document_highlight then
      vim.api.nvim_exec([[
        augroup lsp_document_highlight
          autocmd! * <buffer>
          autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
          autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
        augroup END
      ]], false)
    end

    if c.format then
      vim.api.nvim_exec([[
        augroup lsp_formatting_sync
          autocmd! * <buffer>
          autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()
        augroup END
      ]], false)
    end

    if c.lsp_status and plugin_exists('lsp-status') then
      require'lsp_status'.on_attach(client)
    end

    local symbol_kind_labels = c['symbol-kind-labels']
    if symbol_kind_labels ~= nil then
      vim.lsp.protocol.CompletionItemKind = extract_symbol_kind_labels(symbol_kind_labels)
    end
  end
end

local function get_sumneko_lua_override(c)
  local sumneko_path = c.sumneko_path

  return {
    cmd = {
      string.format('%s/bin/platform/lua-language-server', sumneko_path),
      '-E',
      string.format('%s/main.lua', sumneko_path)
    },
    settings = {
      Lua = {
        runtime = {
          version = 'LuaJIT',
          path = vim.split(package.path, ';'),
        },

        diagnostics = {
          enable = true,
          globals = { "vim" },
        },

        workspace = {
          -- Make the server aware of Neovim runtime files
          library = {
            [vim.fn.expand('$VIMRUNTIME/lua')] = true,
            [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true,
          },
        },
      },
    },
  }
end

local function get_rust_analyzer_override(c)
  local ra_path = c.rust_analyzer_path

  return {
    cmd = { ra_path },
  }
end

local function get_language_overrides(c, lang)
  local overrides = {
    sumneko_lua = get_sumneko_lua_override,
    rust_analyzer = get_rust_analyzer_override
  }

  local override = overrides[lang]
  return override and override(c) or {}
end

local function configure_language_servers(capabilities, c)
  for lang, lang_config in pairs(c.servers) do
    local attach = extract_attach(lang_config)
    local setup = get_language_overrides(lang_config, lang)
    setup.capabilities = capabilities
    setup.on_attach = function(client, bufnr)
      if c.keybindings ~= nil then
        configure_local_keybindings(bufnr, c.keybindings)
      end

      if lang_config.keybindings ~= nil then
        configure_local_keybindings(bufnr, lang_config.keybindings)
      end

      attach(client)
    end

    if lang_config.setup ~= nil then
      vim.tbl_extend('keep', setup, lang_config.setup)
    end

    local lang_entry = require'lspconfig'[lang]
    if lang_entry ~= nil then
      lang_entry.setup(setup)
    end
  end
end

function M.interpret(c)
  if not plugin_exists('lspconfig') then
    return
  end

  if c.diagnostics ~= nil then
    configure_diagnostics(c.diagnostics)
  end

  local capabilities
  if c.capabilities ~= nil then
    capabilities = extract_capabilities(c.capabilities)
  end

  if plugin_exists('lsp-status') then
    configure_lsp_status()
  end

  if c.servers ~= nil then
    configure_language_servers(capabilities, c)
  end
end

return M
