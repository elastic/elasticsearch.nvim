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
