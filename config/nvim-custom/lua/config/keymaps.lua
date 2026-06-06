local map = vim.keymap.set

-- Safe require wrappers keep these keymaps from erroring if a plugin isn't loaded yet.
local function harpoon()
	local ok, module = pcall(require, "harpoon")
	if not ok then
		return nil
	end

	return module
end

local function fzf(action, opts)
	return function()
		local ok, module = pcall(require, "fzf-lua")
		if not ok then
			return
		end

		module[action](opts or {})
	end
end

local function project_root()
	return vim.fs.root(0, { ".git" }) or vim.uv.cwd()
end

-- Movement / viewport tweaks
map("n", "j", "gjzz", { noremap = true })
map("n", "k", "gkzz", { noremap = true })
map("n", "G", "Gzz", { noremap = true })
map("n", "gg", "ggzz", { noremap = true })
map("n", "<C-d>", "<C-d>zz", { noremap = true })
map("n", "<C-u>", "<C-u>zz", { noremap = true })
map("n", "n", "nzz", { noremap = true })
map("n", "N", "Nzz", { noremap = true })

-- Tmux Sessionizer
map("n", "<C-t>", "<cmd>silent !tmux neww ~/.local/bin/tmux-sessionizer<CR>", { desc = "tmux sessionizer" })

-- Harpoon: quick file marks and list navigation
map("n", "<leader>a", function()
	local hp = harpoon()
	if not hp then
		return
	end

	hp:list():add()
end, { desc = "Harpoon add file" })

map("n", "<C-e>", function()
	local hp = harpoon()
	if not hp then
		return
	end

	hp.ui:toggle_quick_menu(hp:list())
end, { desc = "Harpoon menu" })

map("n", "<C-S-h>", function()
	local hp = harpoon()
	if not hp then
		return
	end

	hp:list():select(1)
end, { desc = "Harpoon file 1" })

map("n", "<C-S-t>", function()
	local hp = harpoon()
	if not hp then
		return
	end

	hp:list():select(2)
end, { desc = "Harpoon file 2" })

map("n", "<C-n>", function()
	local hp = harpoon()
	if not hp then
		return
	end

	hp:list():select(3)
end, { desc = "Harpoon file 3" })

map("n", "<C-S-s>", function()
	local hp = harpoon()
	if not hp then
		return
	end

	hp:list():select(4)
end, { desc = "Harpoon file 4" })

map("n", "<C-S-p>", function()
	local hp = harpoon()
	if not hp then
		return
	end

	hp:list():prev()
end, { desc = "Harpoon prev" })

map("n", "<C-S-n>", function()
	local hp = harpoon()
	if not hp then
		return
	end

	hp:list():next()
end, { desc = "Harpoon next" })

-- fzf-lua: conventional picker shortcuts
map("n", "<leader>,", fzf("buffers", { sort_mru = true, sort_lastused = true }), { desc = "Buffers" })
map("n", "<leader>/", fzf("live_grep", { cwd = project_root() }), { desc = "Live grep" })
map("n", "<leader><space>", fzf("files", { cwd = project_root() }), { desc = "Find files" })
map("n", "<leader>:", fzf("command_history"), { desc = "Command history" })
map("n", "<leader>fb", fzf("buffers", { sort_mru = true, sort_lastused = true }), { desc = "Buffers" })
map("n", "<leader>fB", fzf("buffers"), { desc = "Buffers (all)" })
map("n", "<leader>ff", fzf("files", { cwd = project_root() }), { desc = "Find files" })
map("n", "<leader>fF", fzf("files", { cwd = vim.uv.cwd() }), { desc = "Find files (cwd)" })
map("n", "<leader>fg", fzf("git_files"), { desc = "Git files" })
map("n", "<leader>fr", fzf("oldfiles"), { desc = "Recent files" })
map("n", "<leader>fR", fzf("oldfiles", { cwd = vim.uv.cwd() }), { desc = "Recent files (cwd)" })
map("n", "<leader>sb", fzf("lines"), { desc = "Buffer lines" })
map("n", "<leader>sc", fzf("command_history"), { desc = "Command history" })
map("n", "<leader>sC", fzf("commands"), { desc = "Commands" })
map("n", "<leader>sd", fzf("diagnostics_workspace"), { desc = "Workspace diagnostics" })
map("n", "<leader>sD", fzf("diagnostics_document"), { desc = "Buffer diagnostics" })
map("n", "<leader>sg", fzf("live_grep", { cwd = project_root() }), { desc = "Live grep" })
map("n", "<leader>sG", fzf("live_grep", { cwd = vim.uv.cwd() }), { desc = "Live grep (cwd)" })
map("n", "<leader>sh", fzf("help_tags"), { desc = "Help tags" })
map("n", "<leader>sj", fzf("jumps"), { desc = "Jumps" })
map("n", "<leader>sk", fzf("keymaps"), { desc = "Keymaps" })
map("n", "<leader>sl", fzf("loclist"), { desc = "Location list" })
map("n", "<leader>sq", fzf("quickfix"), { desc = "Quickfix list" })
map("n", "<leader>sw", fzf("grep_cword", { cwd = project_root() }), { desc = "Word" })
map("n", "<leader>sW", fzf("grep_cword", { cwd = vim.uv.cwd() }), { desc = "Word (cwd)" })
map("x", "<leader>sw", fzf("grep_visual", { cwd = project_root() }), { desc = "Selection" })
map("x", "<leader>sW", fzf("grep_visual", { cwd = vim.uv.cwd() }), { desc = "Selection (cwd)" })
map("n", "<leader>ss", fzf("lsp_document_symbols"), { desc = "Document symbols" })
map("n", "<leader>sS", fzf("lsp_live_workspace_symbols"), { desc = "Workspace symbols" })
