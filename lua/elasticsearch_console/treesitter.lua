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
  local install_dir = vim.fn.stdpath("data") .. "/site"
  local ts_repo = vim.fn.stdpath("data") .. "/tree-sitter-elasticsearch-console"

  local parser_dir = install_dir .. "/parser"
  vim.fn.mkdir(parser_dir, "p")
  local queries_dir = install_dir .. "/queries/elasticsearch_console"
  vim.fn.mkdir(queries_dir, "p")

  -- copy parser
  local parser_lib = parser_dir .. "/elasticsearch_console.so"
  local src_lib = ts_repo .. "/elasticsearch-console.so"
  local copy_out = vim.fn.system({ "cp", src_lib, parser_lib })
  if vim.v.shell_error ~= 0 then
    error("Error copying parser binary: " .. copy_out)
  end

  -- copy queries
  local src_queries = ts_repo .. "/queries/elasticsearch_console"
  if vim.uv.fs_stat(src_queries) then
    local copy_queries = vim.fn.system({ "cp", "-r", src_queries .. "/.", queries_dir })
    if vim.v.shell_error ~= 0 then
      vim.notify("Warning: Could not copy queries: " .. copy_queries, vim.log.levels.WARN)
    end
  end

  -- register the language with neovim
  vim.treesitter.language.register("elasticsearch_console", { "esc" })

  -- register parser with nvim-treesitter
  vim.api.nvim_create_autocmd("User", {
    pattern = "TSUpdate",
    callback = function()
      require("nvim-treesitter.parsers").elasticsearch_console = {
        install_info = {
          path = ts_repo,
        },
      }
    end,
  })
end

return M
