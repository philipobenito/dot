-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Strip trailing whitespace on save
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    callback = function()
        -- Save cursor position
        local save_cursor = vim.fn.getpos(".")
        -- Remove trailing whitespace
        vim.cmd([[%s/\s\+$//e]])
        -- Restore cursor position
        vim.fn.setpos(".", save_cursor)
    end,
})
