require('config.lazy')
require('gruvbox').setup({
  italic = { strings = false }
})

-- General
  -- Change tabs to spaces; 2 space indentation
  vim.opt.tabstop = 2
  vim.opt.expandtab = true
  vim.opt.softtabstop = 2
  vim.opt.shiftwidth = 2

-- Key maps
  -- Resource lua script
  vim.keymap.set('n', '<space><space>x', '<cmd>source %<CR>')
  vim.keymap.set('n', '<space>x', ':.lua<CR>')
  vim.keymap.set('v', '<space>x', ':lua<CR>')
  -- Quick save/quit neovim
  vim.keymap.set('n', '<M-S-S>', ':w<CR>')
  vim.keymap.set('n', '<M-S-Q>', ':wq<CR>')
  -- Switch buffers
  vim.keymap.set('n', '<TAB>', '<C-W><C-W>')
  -- Indent and unindent blocks of code
  vim.keymap.set('v', '<TAB>', '>gv')
  vim.keymap.set('v', '<S-TAB>', '<gv')
  -- Big jumps
  vim.keymap.set({'n', 'v'}, '<C-j>', '10j')
  vim.keymap.set({'n', 'v'}, '<C-k>', '10k')

-- Visuals
  -- Set theme to dark themed gruvbox
  vim.o.background = 'dark'
  vim.cmd([[colorscheme gruvbox]])

  -- Set line numbers on start
  vim.api.nvim_create_autocmd('VimEnter', {
    desc = 'Set line numbers',
    callback = function()
      vim.cmd('set number')
    end,
  })

  -- Highlight when yanking text
  --   Try it with `yap` in normal mode
  --   See `:help vim.highlight.on_yank()`
  vim.api.nvim_create_autocmd(
    'TextYankPost',
    {
      desc = 'Highlight when yanking text',
      group = vim.api.nvim_create_augroup(
        'kickstart-highlight-yank',
        { clear = true }
      ),
      callback = function()
        vim.highlight.on_yank()
      end,
    }
  )

