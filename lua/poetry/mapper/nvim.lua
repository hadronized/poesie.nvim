-- Vanilla Neovim configuration mapper.
--
-- This module is responsible for mapping the poetry configuration for Neovim to
-- its Lua / VimL representation.
--
-- # Configuration
--
-- Currently, similar to what you would do with the Lua vim.* configuration.
--
-- {
--   "o": {
--     "title": true,
--     "textwidth": 120,
--     "wrap": false,
--     "inccommand": 'nosplit',
--   },
--
--   "wo": {
--     "number": 2
--   }
-- }

local M = {}

local function interpret_options(c, meta)
  if c[meta] ~= nil then
    for key, value in pairs(c[meta]) do
      vim[meta][key] = value
    end
  end
end

function M.interpret(c)
  if c ~= nil then
    interpret_options(c, 'o')
    interpret_options(c, 'w')
    interpret_options(c, 'b')
    interpret_options(c, 'wo')
    interpret_options(c, 'bo')
  end
end

return M
