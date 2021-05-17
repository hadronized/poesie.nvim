-- Treesitter configuration mapper.

local M = {}

local plugin_exists = require'poesie.plugin'.plugin_exists

function M.interpret(c)
  if not plugin_exists('nvim-treesitter') then
    return
  end

  local ts_conf = {}

  if c.highlight ~= nil then
    ts_conf.highlight = { enable = c.highlight }
  end

  if c.indent ~= nil then
    ts_conf.indent = { enable = c.indent }
  end

  if c.text_objects ~= nil then
    ts_conf.textobjects = { enable = c.text_objects }
  end

  if c.incremental_selection ~= nil then
    local inc_conf = {}

    if c.incremental_selection_keybindings ~= nil then
      inc_conf.keymaps = c.incremental_selection_keybindings
    end

    inc_conf.enable = c.incremental_selection
    ts_conf.incremental_selection = inc_conf
  end

  require'nvim-treesitter.configs'.setup(ts_conf)
end

return M
