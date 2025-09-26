-- Copyright Elasticsearch B.V. and contributors
-- SPDX-License-Identifier: Apache-2.0

local request = require("elasticsearch_console.request")

local M = {}

---If url is a valid string, overrides URL config for this buffer. Otherwise prints configured URL for this buffer.
---@param url? string
local function _url(url)
  if url == nil or url == "" then
    if vim.b.elasticsearch ~= nil and vim.b.elasticsearch.url ~= nil then
      print(vim.b.elasticsearch_console.url)
    elseif vim.g.elasticsearch ~= nil and vim.g.elasticsearch.url ~= nil then
      print(vim.g.elasticsearch.url)
    else
      error("No URL configured")
    end
  else
    vim.b.elasticsearch = vim.b.elasticsearch or {}
    vim.b.elasticsearch.url = url
  end
end

---If auth is a valid string, overrides auth for this buffer. Otherwise prints configured auth for this buffer.
---@param auth? auth
local function _auth(auth)
  if auth == nil then
    if vim.b.elasticsearch ~= nil and vim.b.elasticsearch.auth ~= nil then
      print(vim.b.elasticsearch.auth)
    elseif vim.g.elasticsearch.config ~= nil and vim.g.elasticsearch.auth ~= nil then
      print(vim.g.elasticsearch.auth)
    else
      error("No auth configured")
    end
  else
    vim.b.elasticsearch = vim.b.elasticsearch or {}
    vim.b.elasticsearch.auth = auth
  end
end

---Creates a merged config of global and buffer configs, preferring buffer config values to global when they exist.
---@return config
local function merged_config()
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

---To be run when a new elasticsearch_console buffer has been created
M.setup_buffer = function()
  vim.api.nvim_buf_create_user_command(0, "Elastic", function(opts)
    local sub_command = opts.fargs[1]
    if sub_command == "run" then
      request.run(merged_config())
    elseif sub_command == "curl" then
      request.curl(merged_config())
    elseif sub_command == "url" then
      _url(opts.fargs[2])
    elseif sub_command == "auth" then
      _auth(opts.fargs[2])
    else
      error("Command does not exist: " .. sub_command)
    end
  end, { nargs = "+" })
end

return M
