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

local lsp = require("elasticsearch_console.lsp")
local user_commands = require("elasticsearch_console.user_commands")

local M = {}

---@alias apiAuth { api_key: string }
---@alias userPassAuth { username: string, password: string }
---@alias auth apiAuth | userPassAuth
---@alias config { url: string, auth: auth }

---sets up plugin
---@param config? config
M.setup = function(config)
  local filetype = "elasticsearch_console"

  -- add Elasticsearch console filetype
  vim.filetype.add({
    extension = {
      esc = filetype,
    },
  })

  -- autocommand to run for each new elasticsearch_console buffer
  vim.api.nvim_create_autocmd("FileType", {
    pattern = filetype,
    callback = function()
      -- start LSP server
      lsp.setup_buffer(filetype)

      -- add `Elastic` user command to buffer
      user_commands.setup_buffer()
    end,
  })

  -- set global Elasticsearch config
  local g_config = {}
  if config ~= nil then
    if config.url ~= nil then
      local url = config.url
      if string.sub(url, string.len(url), string.len(url)) == "/" then
        url = string.sub(url, 0, string.len(url) - 1)
      end
      g_config.url = url
    end

    if config.auth ~= nil then
      g_config.auth = config.auth
    end
  end
  vim.g.elasticsearch = g_config
end

return M
