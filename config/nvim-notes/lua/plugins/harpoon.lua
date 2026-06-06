return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  opts = {
    menu = {
      width = vim.api.nvim_win_get_width(0) - 4,
    },
    settings = {
      save_on_toggle = true,
    },
  },
  keys = {
    {
      "<leader>a",
      function()
        require("harpoon"):list():add()
      end,
      desc = "Harpoon add file",
    },
    {
      "<C-e>",
      function()
        local harpoon = require("harpoon")
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end,
      desc = "Harpoon menu",
    },
    {
      "<C-S-h>",
      function()
        require("harpoon"):list():select(1)
      end,
      desc = "Harpoon file 1",
    },
    {
      "<C-S-t>",
      function()
        require("harpoon"):list():select(2)
      end,
      desc = "Harpoon file 2",
    },
    {
      "<C-n>",
      function()
        require("harpoon"):list():select(3)
      end,
      desc = "Harpoon file 3",
    },
    {
      "<C-S-s>",
      function()
        require("harpoon"):list():select(4)
      end,
      desc = "Harpoon file 4",
    },
    {
      "<C-S-p>",
      function()
        require("harpoon"):list():prev()
      end,
      desc = "Harpoon prev",
    },
    {
      "<C-S-n>",
      function()
        require("harpoon"):list():next()
      end,
      desc = "Harpoon next",
    },
  },
}
