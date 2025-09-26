-- Copyright Elasticsearch B.V. and contributors
-- SPDX-License-Identifier: Apache-2.0

local M = {}

---@param filetype string
M.setup_buffer = function(filetype)
  vim.lsp.start({
    name = filetype,
    cmd = {
      "lsp-elasticsearch-console",
      "--stdio",
    },
  })
end

return M
