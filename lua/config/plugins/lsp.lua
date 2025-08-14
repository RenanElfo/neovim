return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("lspconfig").rust_analyzer.setup {}
      require("lspconfig").basedpyright.setup {}
    end,
  }
}
