-- Copyright Elasticsearch B.V. and contributors
-- SPDX-License-Identifier: Apache-2.0

local treesitter = require("elasticsearch_console.treesitter")

local M = {}

---@alias request { method: string, path: string, body?: string }

local response_buf_nr = nil

-- check if jq is installed
local has_jq = false
local jq_on_exit = function(obj)
  if obj.code ~= 0 then
    has_jq = false
  else
    has_jq = true
  end
end
vim.system({ "which", "jq" }, { text = true }, jq_on_exit)

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
      table.insert(cmd, "'Authorization: " .. config.auth.api_key .. "'")
    elseif config.auth.username ~= nil and config.auth.password ~= nil then
      -- do user/pass auth
      table.insert(cmd, "-u")
      table.insert(cmd, config.auth.username .. ":" .. config.auth.password)
    end
  end

  -- timeout
  table.insert(cmd, "--connect-timeout")
  table.insert(cmd, "5")

  -- content-type header
  table.insert(cmd, "-H")
  if request.path:find("_bulk") then
    table.insert(cmd, "'Content-Type: application/x-ndjson'")
  else
    table.insert(cmd, "'Content-Type: application/json'")
  end

  -- HTTP method
  table.insert(cmd, "-X")
  table.insert(cmd, request.method)

  -- output headers to stdout so we can check content-type
  table.insert(cmd, "-D")
  table.insert(cmd, "-")

  -- URL
  if string.sub(request.path, 1, 1) ~= "/" then
    request.path = "/" .. request.path
  end
  table.insert(cmd, config.url .. request.path)

  if request.body ~= nil then
    table.insert(cmd, "-d")
    table.insert(cmd, "'" .. request.body .. "'")
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

---display a request's response in a read-only JSON buffer
local function display_response(response, filetype)
  vim.schedule(function()
    -- reuse existing buffer if it exists and is valid
    if response_buf_nr == nil or not vim.api.nvim_buf_is_valid(response_buf_nr) then
      response_buf_nr = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_command("botright split")
      vim.api.nvim_command("buffer " .. response_buf_nr)
      vim.opt_local.buftype = "nofile"
      vim.opt_local.bufhidden = "wipe"

      vim.api.nvim_buf_set_name(response_buf_nr, "[Elasticsearch response]")
    end

    -- set the filetype (update it each time content is replaced)
    vim.api.nvim_buf_set_option(response_buf_nr, "filetype", filetype)

    -- temporarily disable readonly to allow writing
    vim.api.nvim_buf_set_option(response_buf_nr, "readonly", false)

    -- add content to the buffer
    local lines = vim.split(response, "\n")
    vim.api.nvim_buf_set_lines(response_buf_nr, 0, -1, true, lines)

    -- re-enable readonly
    vim.api.nvim_buf_set_option(response_buf_nr, "readonly", true)
  end)
end

---parse curl response with headers and extract the content-type
---@param response string
---@return string? content_type the content-type header value
---@return string body the response body (without headers)
local function parse_response(response)
  local lines = vim.split(response, "\n")
  local content_type = nil
  local body_start = 1

  -- parse headers until we hit an empty line
  for i, line in ipairs(lines) do
    if line == "" then
      -- empty line marks end of headers
      body_start = i + 1
      break
    end
    -- check for content-type header (case-insensitive)
    local ct = line:match("^[Cc]ontent%-[Tt]ype:%s*(.+)$")
    if ct then
      content_type = ct:gsub(";.*", ""):match("^%s*(.-)%s*$") -- remove charset etc and trim
    end
  end

  -- reconstruct body (everything after headers)
  local body = table.concat(vim.list_slice(lines, body_start), "\n")

  return content_type, body
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

    local content_type, body = parse_response(obj.stdout)

    -- only apply jq to JSON and ndjson responses
    local should_format = has_jq and content_type and
      (content_type == "application/json" or content_type == "application/x-ndjson")

    if should_format then
      -- apply jq formatting to the body
      local jq_on_exit = function(jq_obj)
        if jq_obj.code == 0 then
          display_response(jq_obj.stdout, "json")
        else
          -- fall back to unformatted body if jq fails
          display_response(body, "json")
        end
      end
      vim.system({ "jq" }, { stdin = body, text = true }, jq_on_exit)
    else
      display_response(body, "json")
    end
  end

  vim.system(request_cmd, { text = true }, on_exit)
end

---Returns a list of one or more strings, each being a runnable cURL command
---@param config config
M.curl = function(config)
  local curl_cmd = request_from_position(config)
  if curl_cmd ~= nil then
    display_response(table.concat(curl_cmd, " "), "bash")
  else
    print("No request found under cursor")
  end
end

return M
