-- General
  -- Add visual indicator of line limit
  vim.opt.colorcolumn = '81'

-- Add formatting function
vim.api.nvim_create_user_command('Prettier', function()
  local cmd

  if vim.fn.executable('npx') == 1 then
    cmd = 'npx prettier --write %'
  else
    cmd = 'prettier --write %'
  end

  vim.cmd('silent! !' .. cmd)
  vim.cmd('edit!')
end, {})

-- Format on save
vim.api.nvim_create_augroup("AutoFormat", {})

vim.api.nvim_create_autocmd(
    "BufWritePost",
    {
        pattern = "*.py",
        group = "AutoFormat",
        callback = function()
            vim.cmd("silent !pnpm biome check --fix")            
            -- vim.cmd("silent !uv run ruff format %")            
            vim.cmd("edit")
        end,
    }
)
