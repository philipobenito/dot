return {
  "nvim-telescope/telescope.nvim",
  opts = function(_, opts)
    opts.pickers = opts.pickers or {}
    opts.pickers.find_files = {
      hidden = true,
      find_command = { "fd", "--type", "f", "--hidden", "--exclude", ".git" },
    }
    return opts
  end,
}
