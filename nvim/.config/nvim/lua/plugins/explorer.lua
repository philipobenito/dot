return {
  -- Disable neo-tree (using snacks explorer instead)
  { "nvim-neo-tree/neo-tree.nvim", enabled = false },

  -- Configure snacks explorer to show hidden files
  {
    "folke/snacks.nvim",
    opts = {
      explorer = {
        replace_netrw = true,
      },
      picker = {
        sources = {
          explorer = {
            hidden = true,
            ignored = true,
            jump = { close = true },
          },
        },
      },
    },
  },
}
