return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.lsp.enable('rust_analyzer') -- rust lsp
      vim.lsp.enable('ruff') -- python formatter/linter
      vim.lsp.enable('ty') -- python typechecker/lsp
      vim.lsp.enable('biome') -- js/ts batteries-included
    end,
  }
}
