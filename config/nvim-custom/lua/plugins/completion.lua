local M = {}

function M.setup()
  local cmp = require("blink.cmp")

  cmp.setup({
    keymap = {
      preset = "none",
      ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
      ["<C-e>"] = { "hide", "fallback" },
      ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
      ["<C-n>"] = { "select_next", "snippet_forward", "fallback" },
      ["<C-p>"] = { "select_prev", "snippet_backward", "fallback" },
      ["<CR>"] = { "accept", "fallback" },
    },
  })
end

return M
