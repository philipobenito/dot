-- Get diagnostic under cursor for statusline
local function cursor_diagnostic()
  local bufnr = vim.api.nvim_get_current_buf()
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  local diagnostics = vim.diagnostic.get(bufnr, { lnum = line })

  if #diagnostics == 0 then
    return ""
  end

  local diag = diagnostics[1]
  local severity_icon = ({
    [vim.diagnostic.severity.ERROR] = " ",
    [vim.diagnostic.severity.WARN] = " ",
    [vim.diagnostic.severity.INFO] = " ",
    [vim.diagnostic.severity.HINT] = " ",
  })[diag.severity] or ""

  local source = diag.source and (diag.source .. ": ") or ""
  local msg = diag.message:gsub("\n", " ")
  if #msg > 80 then
    msg = msg:sub(1, 77) .. "..."
  end

  return severity_icon .. source .. msg
end

return {
  "nvim-lualine/lualine.nvim",
  opts = {
    options = {
      section_separators = { left = " ", right = " " },
      component_separators = "",
    },
    sections = {
      lualine_b = {
        { "branch", icon = " " },
        "diff",
        "diagnostics",
      },
      lualine_c = {
        { cursor_diagnostic, color = { fg = "#6c7086" } },
      },
      lualine_z = {
        function()
          return "󱑌  " .. os.date("%R")
        end,
      },
    },
  },
}
