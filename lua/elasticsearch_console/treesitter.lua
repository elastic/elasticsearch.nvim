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

return M
