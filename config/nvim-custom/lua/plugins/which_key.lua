local M = {}

function M.setup()
  local ok, wk = pcall(require, "which-key")
  if not ok then
    return
  end

  wk.setup({
    preset = "modern",
    triggers = {
      { "<auto>", mode = "nixsotc" },
      { "g", mode = { "n", "v", "o" } },
      { "z", mode = { "n", "v", "o" } },
      { "[", mode = { "n", "v", "o" } },
      { "]", mode = { "n", "v", "o" } },
      { "<c-w>", mode = { "n", "v", "o" } },
      { "\"", mode = { "n", "i" } },
      { "`", mode = { "n", "v" } },
    },
    plugins = {
      presets = {
        g = true,
        z = true,
        windows = true,
        nav = true,
      },
    },
    win = {
      border = "rounded",
      padding = { 1, 2 },
    },
    layout = {
      spacing = 3,
    },
    show_help = true,
    show_keys = true,
  })
end

return M
