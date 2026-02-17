-- Copyright Elasticsearch B.V. and contributors
-- SPDX-License-Identifier: Apache-2.0

local lsp = require("elasticsearch_console.lsp")
local user_commands = require("elasticsearch_console.user_commands")
local treesitter = require("elasticsearch_console.treesitter")

local M = {}

---@alias apiAuth { api_key: string }
---@alias userPassAuth { username: string, password: string }
---@alias auth apiAuth | userPassAuth
---@alias config { url: string, auth: auth }

---sets up plugin
---@param config? config
M.setup = function(config)
  -- installs any missing dependencies
  treesitter.setup()
  -- lsp.setup()

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
      -- start treesitter
      vim.treesitter.start()

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
