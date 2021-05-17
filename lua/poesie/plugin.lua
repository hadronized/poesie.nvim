-- Plugin manipulation layer.

local M = {}

local existing_plugins_cache = {}
function M.plugin_exists(name)
  local cached = existing_plugins_cache[name]
  if cached ~= nil then
    return cached
  end

  local exists = pcall(require, name)
  existing_plugins_cache[name] = exists

  return exists
end

return M
