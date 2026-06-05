return {
  -- Better syntax highlighting + filetype detection
  {
    "pearofducks/ansible-vim",
    init = function()
      -- File patterns that should trigger yaml.ansible filetype
      vim.g.ansible_ftdetect_filename_regex = [[\v(playbook|site|main|local|requirements)\.ya?ml$]]
    end,
  },

  -- Explicit filetype rules for common Ansible file patterns
  {
    "neovim/nvim-lspconfig",
    init = function()
      vim.filetype.add({
        pattern = {
          [".*playbook.*%.ya?ml"] = "yaml.ansible",
          [".*roles/.*/tasks/.*%.ya?ml"] = "yaml.ansible",
          [".*roles/.*/handlers/.*%.ya?ml"] = "yaml.ansible",
          [".*roles/.*/defaults/.*%.ya?ml"] = "yaml.ansible",
          [".*roles/.*/vars/.*%.ya?ml"] = "yaml.ansible",
          [".*playbooks/.*%.ya?ml"] = "yaml.ansible",
          [".*inventory/.*%.ya?ml"] = "yaml.ansible",
          [".*requirements.ya?ml"] = "yaml.ansible",
        },
      })
    end,
  },
}
