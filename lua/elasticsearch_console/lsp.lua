-- Copyright Elasticsearch B.V. and contributors
-- SPDX-License-Identifier: Apache-2.0
local config = require("elasticsearch_console.config")

local M = {}

local lsp_path = vim.fn.stdpath("data") .. "/lsp-elasticsearch-console"

---@param filetype string
M.setup_buffer = function(filetype)
  vim.lsp.start({
    name = filetype,
    cmd = {
      "lsp-elasticsearch-console",
      "--stdio",
    },
    init_options = config.buffer_config(),
  })
end

M.setup = function()
  -- install lsp from github
  if not vim.uv.fs_stat(lsp_path) then
    -- clone repo
    local repo = "git@github.com:elastic/lsp-elasticsearch-console.git"
    local out = vim.fn.system({ "git", "clone", "--branch=main", repo, lsp_path })
    if vim.v.shell_error ~= 0 then
      error("Error cloning lsp-elasticsearch-console:\n" .. out)
    end

    -- install npm dependencies
    out = vim.fn.system({ "npm", "install" }, { cwd = lsp_path })
    if vim.v.shell_error ~= 0 then
      error("Error installing lsp-elasticsearch-console:\n" .. out)
    end

    -- build code
    out = vim.fn.system({ "npm", "run", "compile" }, { cwd = lsp_path })
    if vim.v.shell_error ~= 0 then
      error("Error building lsp-elasticsearch-console:\n" .. out)
    end
  end
end

return M
