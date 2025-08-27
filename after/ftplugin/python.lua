-- Detect .venv in the project root and add it to PATH
local venv = vim.fn.getcwd() .. "/.venv"
local venv_python = venv .. "/bin/python"

if vim.fn.executable(venv_python) == 1 then
  -- Prepend venv/bin to PATH so nvim-lspconfig finds it first
  vim.env.PATH = venv .. "/bin:" .. vim.env.PATH
  -- Make sure Python plugins use the same Python
  vim.g.python3_host_prog = venv_python
end

-- General
  -- Add visual indicator of line limit
  vim.opt.colorcolumn = "80"

-- Indentation
vim.defer_fn(function()
  if pcall(vim.cmd, "TSBufEnable indent") then
  end
end, 0)
