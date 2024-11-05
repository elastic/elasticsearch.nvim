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

---@alias apiAuth { api_key: string }
---@alias userPassAuth { username: string, password: string }
---@alias auth apiAuth | userPassAuth
---@alias config { url: string, auth: auth }

---@type config
local config = {
  url = "http://localhost:9200",
  auth = {
    username = "elastic",
    password = "changeme",
  },
}

---sets up plugin
---@param setup_config? config
M.setup = function(setup_config)
  -- add Elasticsearch console filetype
  vim.filetype.add({
    extension = {
      esc = "elasticsearch_console",
    },
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "elasticsearch_console",
    callback = function()
      -- start language server
      vim.lsp.start({
        name = "elasticsearch_console",
        cmd = {
          "elasticsearch-language-server",
          "--stdio",
        },
      })
    end,
  })

  -- set Elasticsearch config
  if setup_config ~= nil then
    if setup_config.url ~= nil then
      local url = setup_config.url
      if string.sub(url, string.len(url), string.len(url)) == "/" then
        url = string.sub(url, 0, string.len(url) - 1)
      end
      config.url = url
    end

    if setup_config.auth ~= nil then
      config.auth = setup_config.auth
    end
  end
end

---parses the request the cursor is currently on, runs it, and prints the response
M.run_request = function()
  local status, request_cmd = pcall(request.request_from_position, config)
  if not status or request_cmd == nil then
    print("No request found at this cursor location")
    return
  end

  -- execute command and print JSON result
  local on_exit = function(obj)
    if obj.code ~= 0 then
      if obj.stderr ~= "" then
        print("Request failed. Exit code: " .. obj.stderr)
        return
      else
        print("Request failed. Error message: " .. obj.code)
        return
      end
    end

    print(obj.stdout)
  end

  vim.system(request_cmd, { text = true }, on_exit)
end

---prints a curl command for the request the cursor is currently on
M.get_curl = function()
  local status, request_cmd = pcall(request.request_from_position, config)
  if not status or request_cmd == nil then
    print("No request found at this cursor location")
  else
    print(table.concat(request_cmd, " "))
  end
end

---updates local Elasticsearch configuration values
---@param changes { url?: string, auth?: auth }
M.config = function(changes)
  if changes.url ~= nil then
    config.url = changes.url
  end

  if changes.auth ~= nil then
    config.auth = changes.auth
  end
end

return M
