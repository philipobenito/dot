-- Subtle diagnostic virtual text styling
return {
  -- Override LazyVim's diagnostic config (removes ● prefix)
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = {
          prefix = "",
          spacing = 4,
          source = "if_many",
        },
      },
    },
    init = function()
      -- Dim virtual text colors
      local function set_dim_diagnostics()
        vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { fg = "#45475a", italic = true })
        vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { fg = "#45475a", italic = true })
        vim.api.nvim_set_hl(0, "DiagnosticVirtualTextInfo", { fg = "#45475a", italic = true })
        vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", { fg = "#45475a", italic = true })
      end

      set_dim_diagnostics()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_dim_diagnostics })
    end,
  },
}
