-- Copyright Elasticsearch B.V. and contributors
-- SPDX-License-Identifier: Apache-2.0

local M = {}

-- Returns the first parent of `node` with type `selector`
---@param node TSNode
---@param selector string
---@return TSNode?
M.closest_parent = function(node, selector)
  if node == nil then
    return
  end

  local status, parent_node = pcall(node.parent, node)
  if not status or parent_node == nil then
    return
  end

  while parent_node ~= nil do
    if parent_node:type() == selector then
      return parent_node
    end

    status, parent_node = pcall(parent_node.parent, parent_node)
    if not status or parent_node == nil then
      return
    end
  end
end

---@param node TSNode
---@return string?
M.node_text = function(node)
  return vim.treesitter.get_node_text(node, vim.api.nvim_get_current_buf())
end

M.setup = function()
  -- install grammar from github
  local ts_path = vim.fn.stdpath("data") .. "/tree-sitter-elasticsearch-console"
  if not vim.uv.fs_stat(ts_path) then
    local repo = "git@github.com:elastic/tree-sitter-elasticsearch-console.git"
    local out = vim.fn.system({ "git", "clone", "--branch=main", repo, ts_path })
    if vim.v.shell_error ~= 0 then
      error("Error cloning tree-sitter-elasticsearch-console:\n" .. out)
    end
  end

  -- copy highlight queries
  local highlights_path = vim.fn.stdpath("config") .. "/queries"
  local out = vim.fn.system({ "mkdir", "-p", highlights_path })
  if vim.v.shell_error ~= 0 then
    error("Error:\n" .. out)
  end
  out = vim.fn.system({
    "cp",
    "-r",
    ts_path .. "/queries/elasticsearch_console",
    highlights_path,
  })
  if vim.v.shell_error ~= 0 then
    error("Error:\n" .. out)
  end

  -- set up parser
  local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
  parser_config.elasticsearch_console = {
    install_info = {
      url = ts_path,
      files = { "src/parser.c" },
      branch = "main",
      generate_requires_npm = false,
      requires_generate_from_grammar = false,
    },
    filetype = "esc",
  }
  vim.cmd("TSUpdate elasticsearch_console")
end

return M
