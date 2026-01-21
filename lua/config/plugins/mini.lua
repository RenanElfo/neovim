return {
  {
    'echasnovski/mini.nvim',
    -- enabled = false,
    config = function()
      local statusline = require('mini.statusline')
      statusline.setup { use_icons = true }
      -- Add time to the statusline
      vim.o.statusline = vim.o.statusline .. ' %{strftime("%H:%M")}'
    end
  }
}

