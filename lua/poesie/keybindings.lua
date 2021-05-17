-- Declarative keybindings.
--
-- This module exposes a declarative and rich interface to Neovim’s internal keybinding mechanism.
--
-- TODO
-- # Examples
--
--   "keybindings": [
--     {
--       "mode": "n",
--       "sequences": [
--         {
--           "key": "<leader>",
--           "sequences": [
--             {
--               "key": "c",
--               "desc": "code",
--               "sequences": [
--                 {
--                   "key": "d",
--                   "lua": "vim.lsp.buf.definition()"
--                   "desc": "go to definition"
--                 },
--                 {
--                   "key": "s",
--                   "cmd": "Telescope lsp_dynamic_workspace_symbols"
--                   "desc": "search workspace"
--                 }
--               ]
--             }
--           ]
--         }
--       ]
--     }
--   ]

local M = {}

-- Transform a keybinding action into a Vim command from a keybinding leaf.
--
-- For example, the following will be transformed into "<cmd>lua foo.bar.zoo()<cr>":
--
-- { "lua": "foo.bar.zoo()" }
--
-- The following is "<cmd>Foo<cr>":
--
-- { "cmd": "Foo" }
--
-- And the following is "<cmd>Bar<cr>":
--
-- { "raw": "<cmd>Bar<cr>" }
local function extract_action_from_leaf(leaf)
  if leaf.lua ~= nil then
    return string.format('<cmd>lua %s<cr>', leaf.lua)
  elseif leaf.cmd then
    return string.format('<cmd>%s<cr>', leaf.cmd)
  elseif leaf.raw then
    return leaf.raw
  end
end

-- Traverse keybinding leaves.
--
-- Keybinding leaves are at the tip of the keybinding tree and contain actual actions to do. They have several keys:
--
-- - "key": key to press to run the associated action.
-- - "desc": description string used to describe what this action is about. Can be used by plugins such as which-key.
-- - One of:
--   - "lua": run some Lua command, wrapped in a string. The string will be wrapped inside a '<cmd>lua HERE<cr>' string, so
--     you don’t have to specify the '<cmd>lua' prefix, nor the '<cr>' suffix.
--   - "cmd": run some Vim command, wrapped in a string. The string will be wrapped inside a '<cmd>HERE<cr>' string, so
--     you don’t have to specify the '<cmd>' prefix, nor the '<cr>' suffix.
--   - "raw": run a Vim command, wrapped in a string, that will not be wrapped at all.
--  - (optional) "silent": a boolean indicating whether the keybinding should be silent.
--  - (optional) "noremap": a boolean indicating whether the keybinding should be noremap.
--  - (optional) "expr": a boolean indicating whether the keybinding should be expr.
--
--  The "set_keymap" argument is a function taking four arguments:
--
--  - The "mode" Vim mode.
--  - The sequence the keybinding will be mapped to.
--  - The actual string Vim command.
--  - A table containing options for the keybinding, such as "silent", "noremap", "expr", etc.
local function traverse_leaf(set_keymap, mode, partial_seq, leaf)
  local full_seq = partial_seq .. leaf.key
  local cmd = extract_action_from_leaf(leaf)
  local opt_set = { 'silent', 'noremap', 'expr' }
  local options = {}

  for _, opt in pairs(opt_set) do
    options[opt] = leaf[opt]
  end

  set_keymap(mode, full_seq, cmd, options)
end

-- Traverse keybinding middle group.
--
-- Such a group doesn’t induce a command to be executed yet. It has a few keys available:
--
-- - "key": key to press to enter this group.
-- - "desc": description string used to describe what this group is about. Can be used by plugins such as which-key.
-- - "sequences": subsequent mapping sequences.
--
-- The "mode" argument is the mode is the group occurs in. "partial_seq" is the partial sequence being built (parent of
-- this group in the keybinding tree).
local function traverse_middle_level_group(set_keymap, mode, partial_seq, group)
  if group.sequences == nil then
    traverse_leaf(set_keymap, mode, partial_seq, group)
  else
    local current_seq = partial_seq .. group.key

    for _, subgroup in pairs(group.sequences) do
      traverse_middle_level_group(set_keymap, mode, current_seq, subgroup)
    end
  end
end

-- Traverse a top-level group of keybindings.
--
-- Such groups have a few keys available:
--
-- - "mode": the Vim mode the subsequent sequences will be active in.
-- - "sequences": subsequent mapping sequences.
--
-- This function will abort if "mode" is not provided.
local function traverse_top_level_group(set_keymap, group)
  if group.mode == nil then
    return false
  end

  for _, subgroup in pairs(group.sequences) do
    traverse_middle_level_group(set_keymap, group.mode, '', subgroup)
  end
end

-- Traverse and apply with "set_keymap" all the keybindings found in "keybindings".
function M.traverse_keybindings(keybindings, set_keymap)
  for _, group in pairs(keybindings) do
    traverse_top_level_group(set_keymap, group)
  end
end

return M
