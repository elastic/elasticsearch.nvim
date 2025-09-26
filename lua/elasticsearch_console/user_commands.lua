-- Licensed to Elasticsearch B.V. under one or more contributor
-- license agreements. See the NOTICE file distributed with
-- this work for additional information regarding copyright
-- ownership. Elasticsearch B.V. licenses this file to you under
-- the Apache License, Version 2.0 (the "License"); you may
-- not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing,
-- software distributed under the License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
-- KIND, either express or implied.  See the License for the
-- specific language governing permissions and limitations
-- under the License.

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
