return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = require('blink.cmp').get_lsp_capabilities()
      
      vim.lsp.enable('rust_analyzer') -- rust lsp
      vim.lsp.enable('ruff') -- python formatter/linter
      vim.lsp.enable('ty') -- python typechecker/lsp
      vim.lsp.enable('biome') -- js/ts batteries-included
      vim.lsp.config('tinymist', { settings = { formatterMode = 'typstyle' } })
      vim.lsp.enable('tinymist') -- typst lsp
    end,
  }
}
