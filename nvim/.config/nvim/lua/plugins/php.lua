-- Global PHP defaults: intelephense, phpcs, phpstan
-- Override per-project via .nvim.lua (exrc) or .neoconf.json

return {
  -- Use intelephense as default PHP LSP
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        phpactor = { enabled = false },
        intelephense = { enabled = true },
      },
    },
  },

  -- Prevent mason-lspconfig from auto-installing phpactor
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      automatic_installation = {
        exclude = { "phpactor" },
      },
    },
  },

  -- Install all PHP tools (available for per-project use)
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "intelephense",
        -- Linters
        "phpcs",
        "phpstan",
        -- Formatters
        "php-cs-fixer",
        "pint",
      },
    },
  },

  -- Default linters: phpcs, phpstan
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.php = vim.g.php_linters or { "phpcs", "phpstan" }

      -- Configure phpstan: level 9 if no config file exists
      opts.linters = opts.linters or {}
      opts.linters.phpstan = {
        args = function()
          local config_files = { "phpstan.neon", "phpstan.neon.dist", "phpstan.dist.neon" }
          local has_config = false

          for _, file in ipairs(config_files) do
            if vim.fn.filereadable(vim.fn.getcwd() .. "/" .. file) == 1 then
              has_config = true
              break
            end
          end

          if has_config then
            return { "analyze", "--error-format=json", "--no-progress" }
          else
            return { "analyze", "--error-format=json", "--no-progress", "--level=9" }
          end
        end,
      }
    end,
  },

  -- Default formatter: phpcbf (pairs with phpcs)
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        php = vim.g.php_formatters or { "phpcbf" },
      },
    },
  },
}
