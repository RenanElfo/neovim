return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = require('blink.cmp').get_lsp_capabilities()
      
      vim.lsp.enable('rust_analyzer') -- rust lsp
      vim.lsp.enable('ruff') -- python formatter/linter
      vim.lsp.enable('ty') -- python typechecker/lsp
      vim.lsp.enable('biome') -- js/ts batteries-included
      vim.lsp.config('tinymist', {
        settings = {
          formatterMode = 'typstyle',
          formatterProseWrap = true,
          formatterPrintWidth = 80,
          formatterIndentSize = 2,
        }
      })
      vim.lsp.enable('tinymist') -- typst lsp

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('my.lsp', {}),
        callback = function(args)
          local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
          if not client then return end
          -- Auto-format ("lint") on save.
          -- Usually not needed if server supports "textDocument/willSaveWaitUntil".
          if not client:supports_method('textDocument/willSaveWaitUntil')
              and client:supports_method('textDocument/formatting') then
            vim.api.nvim_create_autocmd('BufWritePre', {
              group = vim.api.nvim_create_augroup('my.lsp', {
                 clear=false
               }),
              buffer = args.buf,
              callback = function()
                vim.lsp.buf.format({
                  bufnr = args.buf, id = client.id, timeout_ms = 1000
                })
              end,
            })
          end
        end,
      })
    end,
  }
}
