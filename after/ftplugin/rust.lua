-- General
  -- Add visual indicator of line limit
  vim.opt.colorcolumn = '101'

-- -- Format on save
--   vim.api.nvim_create_autocmd('BufWritePre', {
--     desc = 'Format code',
--     callback = function()
--       local diagnostics = vim.diagnostic.get(
--         0,
--         { severity = vim.diagnostic.severity.ERROR }
--       )
--       if #diagnostics == 0 then
--         vim.cmd('silent! RustFmt')
--       end
--     end,
--   })
