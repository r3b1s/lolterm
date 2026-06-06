local M = {}

local function read_spec(module_name)
  local ok, spec = pcall(require, module_name)
  if not ok or type(spec) ~= "table" then
    return {}
  end

  return spec
end

local function theme_plugin_specs(specs)
  local plugins = {}

  for _, spec in ipairs(specs) do
    if type(spec) == "table" and spec[1] ~= "LazyVim/LazyVim" then
      plugins[#plugins + 1] = spec
    end
  end

  return plugins
end

function M.current_theme_spec()
  return read_spec("plugins.theme")
end

function M.current_theme_plugins()
  return theme_plugin_specs(M.current_theme_spec())
end

function M.current_theme_plugin_name()
  local plugins = M.current_theme_plugins()
  local first = plugins[1]
  if not first then
    return nil
  end

  return first.name or first[1]
end

function M.current_colorscheme()
  for _, spec in ipairs(M.current_theme_spec()) do
    if type(spec) == "table" and spec[1] == "LazyVim/LazyVim" and spec.opts and spec.opts.colorscheme then
      return spec.opts.colorscheme
    end
  end

  return nil
end

function M.all_theme_plugins()
  return theme_plugin_specs(read_spec("plugins.all-themes"))
end

function M.lazy_specs()
  local specs = {}
  local seen = {}

  local function add_spec(spec)
    local key = spec.name or spec[1]
    if not key then
      return
    end

    local index = seen[key]
    if index then
      specs[index] = spec
      return
    end

    specs[#specs + 1] = spec
    seen[key] = #specs
  end

  for _, spec in ipairs(M.all_theme_plugins()) do
    add_spec(spec)
  end

  for _, spec in ipairs(M.current_theme_plugins()) do
    local current = vim.deepcopy(spec)
    current.lazy = false
    current.priority = current.priority or 1000
    add_spec(current)
  end

  local colorscheme = M.current_colorscheme()
  if colorscheme then
    specs[#specs + 1] = {
      name = "omarchy-theme-loader",
      dir = vim.fn.stdpath("config"),
      lazy = false,
      priority = 1000,
      config = function()
        local theme_plugin_name = M.current_theme_plugin_name()
        local transparency_file = vim.fn.stdpath("config") .. "/plugin/after/transparency.lua"

        if theme_plugin_name then
          require("lazy").load({ plugins = { theme_plugin_name } })
        end

        if pcall(vim.cmd.colorscheme, colorscheme) and vim.fn.filereadable(transparency_file) == 1 then
          vim.cmd.source(transparency_file)
        end
      end,
    }

    specs[#specs + 1] = {
      name = "omarchy-theme-hotreload",
      dir = vim.fn.stdpath("config"),
      lazy = false,
      priority = 1000,
      config = function()
        local transparency_file = vim.fn.stdpath("config") .. "/plugin/after/transparency.lua"

        vim.api.nvim_create_autocmd("User", {
          pattern = "LazyReload",
          callback = function()
            package.loaded["plugins.theme"] = nil
            package.loaded["plugins.omarchy_theme"] = nil

            vim.schedule(function()
              local ok, theme = pcall(require, "plugins.omarchy_theme")
              if not ok then
                return
              end

              local theme_plugin_name = theme.current_theme_plugin_name()
              local next_colorscheme = theme.current_colorscheme()
              if not next_colorscheme then
                return
              end

              vim.cmd("highlight clear")
              if vim.fn.exists("syntax_on") == 1 then
                vim.cmd("syntax reset")
              end
              vim.o.background = "dark"

              if theme_plugin_name then
                require("lazy").load({ plugins = { theme_plugin_name } })
              end

              vim.defer_fn(function()
                pcall(vim.cmd.colorscheme, next_colorscheme)
                vim.cmd("redraw!")

                if vim.fn.filereadable(transparency_file) == 1 then
                  vim.defer_fn(function()
                    vim.cmd.source(transparency_file)
                    vim.api.nvim_exec_autocmds("ColorScheme", { modeline = false })
                    vim.api.nvim_exec_autocmds("VimEnter", { modeline = false })
                    vim.cmd("redraw!")
                  end, 5)
                end
              end, 5)
            end)
          end,
        })
      end,
    }
  end

  return specs
end

return M
