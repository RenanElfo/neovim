-- General
  -- Add visual indicator of line limit
  vim.opt.colorcolumn = "101"

-- Format on save
  -- Set line numbers on start
  vim.api.nvim_create_autocmd('BufWritePost', {
    desc = 'Format code',
    callback = function()
      vim.cmd('RustFmt')
    end,
  })
