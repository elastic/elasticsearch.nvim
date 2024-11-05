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

local treesitter = require("elasticsearch_console.treesitter")

local M = {}

---builds a curl command string for a given method, path and body
---@param config config
---@param method string?
---@param path string?
---@param body string?
---@return string[]?
local function build_curl_request(config, method, path, body)
  if method == nil or path == nil then
    return
  end

  local request = { "curl" }
  if config.auth.api_key ~= nil then
    -- do API auth
    table.insert(request, "-H")
    table.insert(request, '"Authorization: ' .. config.auth.api_key .. '"')
  else
    -- do user/pass auth
    table.insert(request, "-u")
    table.insert(request, config.auth.username .. ":" .. config.auth.password)
  end

  if string.sub(path, 1, 1) ~= "/" then
    path = "/" .. path
  end

  table.insert(request, "-X")
  table.insert(request, method)
  table.insert(request, config.url .. path)

  if body ~= nil then
    table.insert(request, "-d'" .. body .. "'")
  end
  return request
end

---for the current cursor position, parse request syntax and return a curl command
---@param config config
---@return string[]?
M.request_from_position = function(config)
  -- get current location in file
  local status, node = pcall(vim.treesitter.get_node)
  if not status or node == nil then
    return
  end

  -- expand from current location to full request
  local parent_request = treesitter.closest_parent(node, "request")
  if parent_request == nil then
    return
  end

  -- parse request parts
  local method, path, body
  for child in parent_request:iter_children() do
    if child:type() == "request_type" then
      method = treesitter.node_text(child)
    end
    if child:type() == "request_path" then
      path = treesitter.node_text(child)
    end
    if child:type() == "request_body" then
      body = treesitter.node_text(child)
    end
  end

  return build_curl_request(config, method, path, body)
end

return M
