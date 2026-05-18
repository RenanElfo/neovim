---@type vim.lsp.Config
return {
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' })
    if root then
      on_dir(root)
    end
  end,
  cmd = function(dispatchers, config)
    local root = config.root_dir or '.'
    local bin = root .. '/node_modules/.bin/vtsls'
    return vim.lsp.rpc.start(bin, { '--stdio' }, dispatchers, {
      cwd = root,
    })
  end,
  settings = {
    typescript = {
      format = { enable = false },
      preferences = {
        importModuleSpecifier = "non-relative",
      },
    },
    javascript = {
      format = { enable = false },
    },
    vtsls = {
      autoUseWorkspaceTsdk = true,
    },
  },
}
