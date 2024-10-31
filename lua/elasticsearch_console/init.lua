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

local M = {}

M.setup = function()
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
          "/home/joshmock/.asdf/shims/node",
          "/home/joshmock/Code/elastic-neovim/lsp-dev-console/out/server.js",
          "--stdio",
        },
      })
    end,
  })

  -- assign tree-sitter parser to filetype
  -- vim.treesitter.language.add("elasticsearch_console", {
  --   path = "/home/joshmock/Code/elastic-neovim/tree-sitter-elasticsearch-console/elasticsearch-console.so",
  -- })
  -- vim.treesitter.language.register("elasticsearch_console", "elasticsearch_console")
end

-- Returns the first parent of `node` with type `selector`
---@param node TSNode
---@param selector string
---@return TSNode?
local function closest_parent(node, selector)
  print(node)
  print(selector)
  if node == nil then
    return nil
  end

  local status, parent_node = pcall(node.parent, node)
  if not status then
    return
  end
  if parent_node == nil then
    return
  end

  while parent_node ~= nil do
    if parent_node:type() == selector then
      return parent_node
    end
    print("four")

    status, parent_node = pcall(node.parent, node)
    if not status then
      return
    end
  end
end

---@param node TSNode
---@return string?
local function node_text(node)
  return vim.treesitter.get_node_text(node, vim.api.nvim_get_current_buf())
end

---builds a curl command string for a given method, path and body
---@param method string?
---@param path string?
---@param body string?
---@return string[]?
local function build_curl_request(method, path, body)
  if method == nil or path == nil then
    return
  end

  local request = { "curl", "-u", "elastic:changeme", "-X" }

  if string.sub(path, 1, 1) ~= "/" then
    path = "/" .. path
  end

  table.insert(request, method)
  table.insert(request, "http://localhost:9200" .. path)

  if body ~= nil then
    table.insert(request, "-d'" .. body .. "'")
  end
  return request
end

---for the current cursor position, parse request syntax and return a curl command
---@return string[]?
local function request()
  -- get current location in file
  local status, node = pcall(vim.treesitter.get_node)
  if not status or node == nil then
    return
  end

  -- expand from current location to full request
  local parent_request = closest_parent(node, "request")
  if parent_request == nil then
    return
  end

  -- parse request parts
  local method, path, body
  for child in parent_request:iter_children() do
    if child:type() == "request_type" then
      method = node_text(child)
    end
    if child:type() == "request_path" then
      path = node_text(child)
    end
    if child:type() == "request_body" then
      body = node_text(child)
    end
  end

  return build_curl_request(method, path, body)
end

M.run_request = function()
  local status, request_cmd = pcall(request)
  if not status or request_cmd == nil then
    print("No request found at this cursor location")
    return
  end

  -- table.insert(request_cmd, "-s")

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
  local status, request_cmd = pcall(request)
  if not status or request_cmd == nil then
    print("No request found at this cursor location")
  else
    print(table.concat(request_cmd, " "))
  end
end

return M
