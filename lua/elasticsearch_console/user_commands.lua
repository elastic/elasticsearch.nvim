-- Copyright Elasticsearch B.V. and contributors
-- SPDX-License-Identifier: Apache-2.0

local request = require("elasticsearch_console.request")
local config = require("elasticsearch_console.config")

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

---If username and password are passed, username/password auth is configured for this buffer.
---If pass is nil, username is assumed to be an API key which is used for auth.
---Otherwise prints configured auth for this buffer.
---@param username? string
---@param password? string
local function _auth(username, password)
  if username == nil then
    if vim.b.elasticsearch ~= nil and vim.b.elasticsearch.auth ~= nil then
      print(table.concat(vim.b.elasticsearch.auth, ":"))
    elseif vim.g.elasticsearch.config ~= nil and vim.g.elasticsearch.auth ~= nil then
      print(table.concat(vim.g.elasticsearch.auth, ":"))
    else
      error("No auth configured")
    end
  else
    vim.b.elasticsearch = vim.b.elasticsearch or {}
    local auth = {}
    if password ~= nil then
      auth.username = username
      auth.password = password
    else
      auth.api_key = username
    end
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
      request.run(config.buffer_config())
    elseif sub_command == "curl" then
      request.curl(config.buffer_config())
    elseif sub_command == "url" then
      _url(opts.fargs[2])
    elseif sub_command == "auth" then
      _auth(opts.fargs[2], opts.fargs[3] or nil)
    else
      error("Command does not exist: " .. sub_command)
    end
  end, { nargs = "+" })
end

return M
