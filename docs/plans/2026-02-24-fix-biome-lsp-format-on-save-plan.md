---
title: "Fix biome LSP format-on-save and linting"
type: fix
date: 2026-02-24
---

# Fix biome LSP format-on-save and linting

## Overview

Biome is installed via Homebrew (`biome 2.4.4` at `/home/linuxbrew/.linuxbrew/bin/biome`) and `vim.lsp.enable('biome')` is called in the LSP config, but biome never attaches to any buffer. This means format-on-save and linting silently do nothing for JS/TS files.

## Problem Statement

Two issues were identified:

### Primary: biome LSP silently never starts

The nvim-lspconfig default `lsp/biome.lua` has `workspace_required = true` and a `root_dir` function that **requires** finding `biome.json` or `biome.jsonc` (or a `biomejs` key in `package.json`) in the directory tree. If none is found, `root_dir` returns `nil` and biome never starts. There is zero user feedback when this happens.

This is unlike every other LSP in the config (ruff, ty, rust_analyzer, sqruff, tinymist), all of which fall back to `.git` or other common root markers.

See upstream logic at `~/.local/share/nvim/lazy/nvim-lspconfig/lsp/biome.lua:40-77` — `workspace_required = true` and `root_dir` returns nil when no config file is found.

### Secondary: blink.cmp capabilities are never passed to LSP servers

In `lua/config/plugins/lsp.lua:5`, capabilities are computed but the variable is never used:

```lua
local capabilities = require('blink.cmp').get_lsp_capabilities()
-- ^ This is NEVER passed to any LSP server
```

This means no LSP server receives blink.cmp's enhanced completion capabilities (snippet support, additional text edits, etc.).

## Proposed Solution

### Fix 1: Override biome's root detection via `after/lsp/biome.lua`

Create `~/.config/nvim/after/lsp/biome.lua` to override the upstream `root_dir` function. In Neovim 0.11, files in `after/lsp/` have higher priority than nvim-lspconfig's defaults. The upstream config uses a custom `root_dir` function (not `root_markers`), so the override must replace it with a simpler function that falls back to `package.json` or `.git`:

```lua
---@type vim.lsp.Config
return {
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { 'biome.json', 'biome.jsonc', 'package.json', '.git' })
    if root then
      on_dir(root)
    end
  end,
}
```

This makes biome's root detection consistent with ruff and sqruff. Biome works fine without a config file (uses sensible defaults: formatter enabled, recommended lint rules).

**Alternative**: Create a `biome.json` with `{}` in each JS/TS project root instead. More explicit but easy to forget.

### Fix 2: Wire up blink.cmp capabilities correctly

Two changes in `lua/config/plugins/lsp.lua`:

1. **Add `dependencies = { 'saghen/blink.cmp' }`** to the nvim-lspconfig plugin spec. Currently the load order works by coincidence; an explicit dependency guarantees blink.cmp loads first.

2. **Replace the unused local variable** on line 5 with a wildcard config:

```lua
-- Before:
local capabilities = require('blink.cmp').get_lsp_capabilities()

-- After:
vim.lsp.config('*', {
  capabilities = require('blink.cmp').get_lsp_capabilities(),
})
```

In Neovim 0.11, `vim.lsp.config('*', ...)` sets a base config that is deep-merged into every server's config at lowest priority. Server-specific capabilities (e.g., rust_analyzer's experimental fields) are preserved.

## Technical Considerations

### Format-on-save logic is already correct

The existing `LspAttach` -> `BufWritePre` -> `vim.lsp.buf.format()` pattern works for biome because:
- Biome **supports** `textDocument/formatting`
- Biome does **NOT** support `textDocument/willSaveWaitUntil`
- Both conditions in the guard clause (lines 28-29) are satisfied

Once biome actually attaches, format-on-save will work with no changes to the autocmd logic.

### Multiple formatters on the same buffer

No conflict exists today — each filetype has exactly one formatter-capable LSP. If `ts_ls` is added later, a `filter` function would be needed on `vim.lsp.buf.format()` to avoid double-formatting.

### Restart required

After applying changes to `lsp.lua`, a full Neovim restart is required. Lazy.nvim caches plugin `config` execution, so re-sourcing will not work. For the `after/lsp/biome.lua` file, existing buffers need to be reopened or `:LspStart biome` must be run.

## Acceptance Criteria

- [ ] Biome LSP attaches when opening JS/TS files in projects with `.git` or `package.json` (even without `biome.json`)
- [ ] Format-on-save works: saving a JS/TS file applies biome formatting
- [ ] Linting works: biome diagnostics appear in the buffer (`:lua print(vim.inspect(vim.diagnostic.get(0)))`)
- [ ] blink.cmp capabilities are propagated to all LSP servers (`:lua print(vim.inspect(vim.lsp.get_clients()[1].capabilities.textDocument.completion))` shows snippet support)
- [ ] Other LSPs (ruff, ty, rust_analyzer, tinymist) continue to work as before

## Verification Steps

After applying the fix, restart Neovim and open a JS/TS file in a project:

```vim
:lua print(vim.inspect(vim.lsp.get_clients()))
```

Biome should appear in the client list. Then verify format-on-save by intentionally misformatting a line and saving with `:w`.

## Files to Modify

| File | Action | Change |
|---|---|---|
| `lua/config/plugins/lsp.lua` | Edit | Add `dependencies`, replace unused `local capabilities` with `vim.lsp.config('*', ...)` |
| `after/lsp/biome.lua` | Create | Override `root_dir` to fall back to `package.json` / `.git` |

## MVP

### `after/lsp/biome.lua` (new file)

```lua
---@type vim.lsp.Config
return {
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { 'biome.json', 'biome.jsonc', 'package.json', '.git' })
    if root then
      on_dir(root)
    end
  end,
}
```

### `lua/config/plugins/lsp.lua` (edited)

```lua
return {
  {
    "neovim/nvim-lspconfig",
    dependencies = { 'saghen/blink.cmp' },
    config = function()
      vim.lsp.config('*', {
        capabilities = require('blink.cmp').get_lsp_capabilities(),
      })

      vim.lsp.enable('rust_analyzer') -- rust lsp
      vim.lsp.enable('ruff') -- python formatter/linter
      vim.lsp.enable('ty') -- python typechecker/lsp
      vim.lsp.enable('biome') -- js/ts batteries-included
      vim.lsp.config('tinymist', {
        settings = {
          formatterMode = 'typstyle',
          formatterProseWrap = true,
          formatterPrintWidth = 80,
          formatterIndentSize = 2,
        }
      })
      vim.lsp.enable('tinymist') -- typst lsp

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('my.lsp', {}),
        callback = function(args)
          local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
          if not client then return end
          if not client:supports_method('textDocument/willSaveWaitUntil')
              and client:supports_method('textDocument/formatting') then
            vim.api.nvim_create_autocmd('BufWritePre', {
              group = vim.api.nvim_create_augroup('my.lsp', {
                 clear=false
               }),
              buffer = args.buf,
              callback = function()
                vim.lsp.buf.format({
                  bufnr = args.buf, id = client.id, timeout_ms = 1000
                })
              end,
            })
          end
        end,
      })
    end,
  }
}
```

## References

- [Neovim 0.11 LSP docs](https://neovim.io/doc/user/lsp.html) -- `vim.lsp.config('*')` and `after/lsp/` override behavior
- [nvim-lspconfig biome.lua source](https://github.com/neovim/nvim-lspconfig/blob/master/lsp/biome.lua) -- `workspace_required` and `root_dir` logic
- [Biome LSP capabilities](https://deepwiki.com/biomejs/biome/7.3-lsp-and-editor-integration) -- supports formatting, NOT willSaveWaitUntil
- [blink.cmp capabilities discussion](https://github.com/Saghen/blink.cmp/discussions/1802) -- how to pass capabilities in nvim 0.11
- [What's New in Neovim 0.11](https://gpanders.com/blog/whats-new-in-neovim-0-11/) -- config resolution order
