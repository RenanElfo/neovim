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
  -- Add visual indicator of 80 characters
  vim.opt.colorcolumn = "81"
  -- No wrap
  vim.opt.wrap = false

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
  -- Return statement
  vim.keymap.set('n', 'R', 'ireturn ')
  -- Telescope
  local builtin = require('telescope.builtin')
  vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
  vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
  vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
  vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
  vim.keymap.set("n", "<leader>fr", "<cmd>Telescope lsp_references<CR>", { desc = "Telescope LSP References" })
  -- LSP
  vim.keymap.set('n', '<F2>', vim.lsp.buf.rename, { desc = 'Semantic search and replace' })
  vim.keymap.set('n', '<F3>', vim.lsp.buf.references, { desc = 'Find references' })
  -- Linter
  vim.keymap.set('n', '<leader>ll', vim.diagnostic.open_float, { desc = 'Open linter message' })

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

-- Linter
  -- Set line numbers on start
  vim.api.nvim_create_autocmd('VimEnter', {
    desc = 'Set line numbers',
    callback = function()
      vim.cmd('set number')
    end,
  })

