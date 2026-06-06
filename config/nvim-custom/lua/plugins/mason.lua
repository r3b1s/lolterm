local M = {}

local extra_packages = {
  "ansible-lint",
  "docker-compose-language-service",
}

local function ensure_installed(package_names)
  local registry = require("mason-registry")

  registry.refresh(function(success)
    if not success then
      vim.schedule(function()
        vim.notify("Mason registry refresh failed", vim.log.levels.ERROR)
      end)
      return
    end

    for _, package_name in ipairs(package_names) do
      local ok, pkg = pcall(registry.get_package, package_name)
      if ok and not pkg:is_installed() and not pkg:is_installing() then
        pkg:install()
      end
    end
  end)
end

function M.setup()
  require("mason").setup()

  local lsp = require("plugins.lsp")
  local server_names = lsp.server_names()
  local mason_server_names = lsp.mason_server_names()

  if #mason_server_names ~= #server_names then
    vim.schedule(function()
      vim.notify(
        "Skipping Mason auto-install for java_language_server (missing jlink)",
        vim.log.levels.WARN
      )
    end)
  end

  require("mason-lspconfig").setup({
    automatic_enable = false,
  })

  local mappings = require("mason-lspconfig").get_mappings().lspconfig_to_package
  local package_names = {}
  local seen = {}

  for _, package_name in ipairs(extra_packages) do
    if not seen[package_name] then
      seen[package_name] = true
      package_names[#package_names + 1] = package_name
    end
  end

  for _, server_name in ipairs(mason_server_names) do
    local package_name = mappings[server_name]
    if package_name and not seen[package_name] then
      seen[package_name] = true
      package_names[#package_names + 1] = package_name
    end
  end

  ensure_installed(package_names)
end

return M
