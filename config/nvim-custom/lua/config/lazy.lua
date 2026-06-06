local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

local specs = {
  {
    "pearofducks/ansible-vim",
    init = function()
      require("plugins.ansible").pre_setup()
      require("plugins.ansible").setup()
    end,
  },
  {
    "bullets-vim/bullets.vim",
    ft = { "markdown", "text", "gitcommit" },
    init = function()
      require("plugins.bullets").setup()
    end,
  },
  {
    "nvim-lua/plenary.nvim",
    lazy = false,
  },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("plugins.harpoon").setup()
    end,
  },
  {
    "ibhagwan/fzf-lua",
    lazy = false,
  },
  {
    "mikavilpas/yazi.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = {
      { "nvim-lua/plenary.nvim", lazy = true },
    },
    keys = {
      {
        "<leader>-",
        mode = { "n", "v" },
        "<cmd>Yazi<cr>",
        desc = "Open Yazi",
      },
      {
        "<leader>.",
        "<cmd>Yazi cwd<cr>",
        desc = "Yazi cwd",
      },
    },
    opts = {
      open_for_directories = false,
      keymaps = {
        show_help = "<f1>",
      },
    },
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("plugins.which_key").setup()
    end,
  },
  {
    "saghen/blink.lib",
    lazy = false,
  },
  {
    "saghen/blink.cmp",
    version = "*",
    lazy = false,
    dependencies = { "saghen/blink.lib" },
    build = function()
      require("blink.cmp.fuzzy.build").build():pwait()
    end,
    config = function()
      require("plugins.completion").setup()
    end,
  },
  {
    "mason-org/mason.nvim",
    lazy = false,
  },
  {
    "mason-org/mason-lspconfig.nvim",
    lazy = false,
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    config = function()
      require("plugins.mason").setup()
    end,
  },
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = {
      "saghen/blink.cmp",
      "mason-org/mason-lspconfig.nvim",
    },
    config = function()
      require("plugins.lsp").setup()
    end,
  },
}

for _, spec in ipairs(require("plugins.omarchy_theme").lazy_specs()) do
  specs[#specs + 1] = spec
end

require("lazy").setup(specs, {
  install = {
    colorscheme = { "habamax" },
  },
  checker = {
    enabled = false,
  },
  change_detection = {
    notify = false,
  },
})
