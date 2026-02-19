-- Copyright Elasticsearch B.V. and contributors
-- SPDX-License-Identifier: Apache-2.0

local M = {}

---Creates a merged config of global and buffer configs, preferring buffer config values to global when they exist.
---@return config
M.buffer_config = function()
  local config = {}

  if vim.b.elasticsearch ~= nil then
    config.url = vim.b.elasticsearch.url or vim.g.elasticsearch.url
    config.auth = vim.b.elasticsearch.auth or vim.g.elasticsearch.auth
  else
    config.url = vim.g.elasticsearch.url
    config.auth = vim.g.elasticsearch.auth
  end
  return config
end

return M
