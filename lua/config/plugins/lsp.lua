return {
  {
    "neovim/nvim-lspconfig",
    dependencies = { 'saghen/blink.cmp' },
    config = function()
      vim.lsp.config('*', {
        capabilities = require('blink.cmp').get_lsp_capabilities(),
      })

      vim.api.nvim_create_autocmd('BufWritePre', {
        group = vim.api.nvim_create_augroup('my.lsp', {}),
        callback = function(args)
          vim.lsp.buf.format({ bufnr = args.buf, timeout_ms = 1000 })
        end,
      })

      vim.lsp.enable('rust_analyzer') -- rust lsp
      vim.lsp.enable('ruff') -- python formatter/linter
      vim.lsp.enable('ty') -- python typechecker/lsp
      vim.lsp.enable('biome') -- js/ts batteries-included
      vim.lsp.enable('sqruff') -- sql lsp/linter/formatter
      vim.lsp.config('tinymist', {
        settings = {
          formatterMode = 'typstyle',
          formatterProseWrap = true,
          formatterPrintWidth = 80,
          formatterIndentSize = 2,
        }
      })
      vim.lsp.enable('tinymist') -- typst lsp
    end,
  }
}
