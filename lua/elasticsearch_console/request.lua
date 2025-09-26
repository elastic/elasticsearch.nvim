-- Copyright Elasticsearch B.V. and contributors
-- SPDX-License-Identifier: Apache-2.0

local treesitter = require("elasticsearch_console.treesitter")

local M = {}

---@alias request { method: string, path: string, body?: string }

---builds a curl command string for a given method, path and body
---@param config config
---@param request request
---@return string[]?
local function build_curl_request(config, request)
  if request.method == nil then
    error("Missing: method")
  end
  if request.path == nil then
    error("Missing: path")
  end

  local cmd = { "curl" }
  if config.auth ~= nil then
    if config.auth.api_key ~= nil then
      -- do API auth
      table.insert(cmd, "-H")
      table.insert(cmd, '"Authorization: ' .. config.auth.api_key .. '"')
    elseif config.auth.username ~= nil and config.auth.password ~= nil then
      -- do user/pass auth
      table.insert(cmd, "-u")
      table.insert(cmd, config.auth.username .. ":" .. config.auth.password)
    end
  end

  -- timeout
  table.insert(cmd, "--connect-timeout")
  table.insert(cmd, "5")

  -- HTTP method
  table.insert(cmd, "-X")
  table.insert(cmd, request.method)

  -- URL
  if string.sub(request.path, 1, 1) ~= "/" then
    request.path = "/" .. request.path
  end
  table.insert(cmd, config.url .. request.path)

  if request.body ~= nil then
    -- TODO: escape quotes in strings, support triple quotes
    table.insert(cmd, "-d'" .. request.body .. "'")
  end
  return cmd
end

---for the current cursor position, parse request syntax and return a curl command
---@param config config
---@return string[]?
local function request_from_position(config)
  -- get current location in file
  local status, node = pcall(vim.treesitter.get_node)
  if not status or node == nil then
    return
  end

  -- expand from current location to full request
  local request_node = treesitter.closest_parent(node, "request")
  if request_node == nil then
    error("No request found at cursor location")
  end

  -- parse request parts
  local request = {}

  -- request line
  local request_line_node = request_node:child(0)
  if request_line_node == nil or request_line_node:type() ~= "request_line" then
    error("No request line found")
  end

  -- HTTP method
  local method_nodes = request_line_node:field("method")
  if #method_nodes == 0 then
    error("No request method found")
  end
  request.method = treesitter.node_text(method_nodes[1])

  -- HTTP path
  local path_nodes = request_line_node:field("path")
  if #path_nodes == 0 then
    error("No request path found")
  end
  request.path = treesitter.node_text(path_nodes[1])

  -- JSON/NDJSON body
  local body_nodes = request_node:field("body")
  if #body_nodes > 0 then
    request.body = treesitter.node_text(body_nodes[1])
  end

  return build_curl_request(config, request)
end

---runs Elasticsearch request under the current cursor location
---@param config config
M.run = function(config)
  local status, request_cmd = pcall(request_from_position, config)
  if not status or request_cmd == nil then
    error("No request found at this cursor location")
  end

  -- execute command and print JSON result
  local on_exit = function(obj)
    if obj.code ~= 0 then
      if obj.stderr ~= "" then
        error("Request failed. Exit code: " .. obj.stderr)
      else
        error("Request failed. Error message: " .. obj.code)
      end
    end

    print(obj.stdout)
  end

  vim.system(request_cmd, { text = true }, on_exit)
end

---Returns a list of one or more strings, each being a runnable cURL command
---@param config config
M.curl = function(config)
  local curl_cmd = request_from_position(config)
  if curl_cmd ~= nil then
    print(table.concat(curl_cmd, " "))
  else
    print("No request found under cursor")
  end
end

return M
