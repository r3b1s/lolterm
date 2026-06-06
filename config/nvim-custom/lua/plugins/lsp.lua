local M = {}

local schema_dir = vim.fn.stdpath("config") .. "/schemas"

local function has_executable(cmd)
  return vim.fn.executable(cmd) == 1
end

local servers = {
  ansiblels = {
    settings = {
      ansible = {
        ansible = { path = "ansible" },
        executionEnvironment = { enabled = false },
        python = { interpreterPath = "python3" },
        validation = {
          enabled = true,
          lint = {
            enabled = true,
            path = "ansible-lint",
          },
        },
      },
    },
  },
  bashls = {
    settings = {
      bashIde = {
        globPattern = vim.env.GLOB_PATTERN or "*@(.sh|.inc|.bash|.command)",
      },
    },
  },
  powershell_es = {
    bundle_path = vim.fn.stdpath("data") .. "/mason/packages/powershell-editor-services",
  },
  systemd_lsp = {},
  markdown_oxide = {},
  yamlls = {
    on_init = function(client)
      client.server_capabilities.documentFormattingProvider = true
    end,
    settings = {
      redhat = { telemetry = { enabled = false } },
      yaml = {
        format = { enable = true },
        schemaStore = { enable = false },
        schemas = {
          [schema_dir .. "/kubernetes.json"] = "*.{k8s,kubernetes}.{yml,yaml}",
          [schema_dir .. "/github-workflow.json"] = ".github/workflows/*",
          [schema_dir .. "/github-action.json"] = ".github/action.{yml,yaml}",
          [schema_dir .. "/ansible.json#/$defs/tasks"] = "roles/tasks/*.{yml,yaml}",
          [schema_dir .. "/prettierrc.json"] = ".prettierrc.{yml,yaml}",
          [schema_dir .. "/kustomization.json"] = "kustomization.{yml,yaml}",
          [schema_dir .. "/chart.json"] = "Chart.{yml,yaml}",
          [schema_dir .. "/docker-compose.json"] = "docker-compose.{yml,yaml}",
        },
      },
    },
  },
  helm_ls = {
    capabilities = {
      workspace = {
        didChangeWatchedFiles = {
          dynamicRegistration = true,
        },
      },
    },
  },
  tofu_ls = {},
  gopls = {},
  golangci_lint_ls = {
    init_options = {
      command = {
        "golangci-lint",
        "run",
        "--output.text.path=",
        "--output.tab.path=",
        "--output.html.path=",
        "--output.checkstyle.path=",
        "--output.junit-xml.path=",
        "--output.teamcity.path=",
        "--output.sarif.path=",
        "--show-stats=false",
        "--output.json.path=stdout",
      },
    },
  },
  ruby_lsp = {
    init_options = {
      formatter = "auto",
    },
  },
  eslint = {
    settings = {
      validate = "on",
      packageManager = nil,
      useESLintClass = false,
      experimental = {},
      codeActionOnSave = {
        enable = false,
        mode = "all",
      },
      format = true,
      quiet = false,
      onIgnoredFiles = "off",
      rulesCustomizations = {},
      run = "onType",
      problems = {
        shortenToSingleLine = false,
      },
      nodePath = "",
      workingDirectory = { mode = "auto" },
      codeAction = {
        disableRuleComment = {
          enable = true,
          location = "separateLine",
        },
        showDocumentation = {
          enable = true,
        },
      },
    },
  },
  basedpyright = {
    settings = {
      basedpyright = {
        analysis = {
          autoSearchPaths = true,
          diagnosticMode = "openFilesOnly",
        },
      },
    },
  },
  phpactor = {},
  awk_ls = {},
  docker_language_server = {},
  graphql = {},
  html = {
    init_options = {
      provideFormatter = true,
      embeddedLanguages = { css = true, javascript = true },
      configurationSection = { "html", "css", "javascript" },
    },
  },
  java_language_server = {},
  jinja_lsp = {},
  lua_ls = {
    settings = {
      Lua = {
        workspace = {
          checkThirdParty = false,
        },
        completion = {
          callSnippet = "Replace",
        },
        codeLens = { enable = true },
        hint = { enable = true, semicolon = "Disable" },
      },
    },
  },
  postgres_lsp = {},
  puppet = {},
  sqlls = {},
  basics_ls = {
    settings = {
      buffer = {
        enable = true,
        minCompletionLength = 4,
      },
      path = {
        enable = true,
      },
      snippet = {
        enable = false,
        sources = {},
      },
    },
  },
}

function M.server_names()
  return vim.tbl_keys(servers)
end

function M.mason_server_names()
  local names = {}

  for _, name in ipairs(M.server_names()) do
    if name == "java_language_server" and not has_executable("jlink") then
      goto continue
    end

    names[#names + 1] = name
    ::continue::
  end

  return names
end

function M.setup()
  local ok, blink = pcall(require, "blink.cmp")
  if ok and blink.get_lsp_capabilities then
    vim.lsp.config("*", {
      capabilities = blink.get_lsp_capabilities(),
    })
  end

  for name, config in pairs(servers) do
    vim.lsp.config(name, config)
    vim.lsp.enable(name)
  end
end

return M
