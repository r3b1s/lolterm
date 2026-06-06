local M = {}

function M.setup()
  local ok, harpoon = pcall(require, "harpoon")
  if not ok then
    return
  end

  harpoon:setup()
end

return M
