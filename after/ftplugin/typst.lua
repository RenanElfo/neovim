vim.bo.textwidth = 80
vim.keymap.set('n', '<leader>fmt', function() vim.lsp.buf.format() end, { desc = 'Format document' })
