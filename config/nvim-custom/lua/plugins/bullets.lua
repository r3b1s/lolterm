local M = {}

function M.setup()
  vim.g.bullets_enabled_file_types = { "markdown", "text", "gitcommit" }
end

return M
