vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.loader.enable()

require("config.options")
require("config.keymaps")
require("config.lazy")
