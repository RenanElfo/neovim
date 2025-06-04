return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("lspconfig").rust_analyzer.setup {}
    end,
  }
}
