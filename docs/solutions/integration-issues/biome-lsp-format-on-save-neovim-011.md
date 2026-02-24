---
title: "Biome LSP not attaching and format-on-save not working in Neovim 0.11"
date: 2026-02-24
category: integration-issues
tags: [biome, lsp, neovim, nvim-lspconfig, blink-cmp, format-on-save]
component: "LSP configuration (Biome, nvim-lspconfig, blink.cmp)"
severity: high
symptoms:
  - "Biome LSP silently failed to attach despite being installed and configured"
  - "No format-on-save for JavaScript/TypeScript files"
  - "No linting diagnostics in editor"
  - "Biome not in vim.lsp.get_clients() output"
root_cause: |
  Three compounding issues:
  1. nvim-lspconfig's biome.lua requires biome.json to exist (workspace_required=true),
     unlike ruff/rust_analyzer/sqruff which fall back to .git
  2. blink.cmp capabilities computed but never passed to servers (unused local variable)
  3. LspAttach callback checked supports_method('textDocument/formatting') before biome
     finished reporting capabilities — returned false at attach time, true later
---

# Biome LSP not attaching and format-on-save not working in Neovim 0.11

## Root Cause Analysis

Three interconnected issues prevented biome from formatting on save:

1. **Root directory detection failure**: nvim-lspconfig's `lsp/biome.lua` has `workspace_required = true` and a `root_dir` function that requires `biome.json` or `biome.jsonc` in the directory tree. Without it, `root_dir` returns `nil` and biome silently never attaches. This is unlike ruff, rust_analyzer, sqruff, and tinymist which all fall back to `.git`.

2. **Unused capabilities variable**: `local capabilities = require('blink.cmp').get_lsp_capabilities()` was computed but never passed to any LSP server via `vim.lsp.config()`.

3. **Capability timing race**: The `LspAttach` autocmd checked `client:supports_method('textDocument/formatting')` at attach time. Biome hadn't finished reporting capabilities yet, so it returned `false`. The same check returned `true` seconds later. This meant the `BufWritePre` handler was never registered.

## Investigation Steps

1. **Repo research** revealed nvim-lspconfig's biome config requires `biome.json` (`workspace_required = true`, `root_dir` returns nil without it).
2. Found `local capabilities = ...` on line 5 of `lsp.lua` was computed but never used.
3. Created `after/lsp/biome.lua` to override root detection — biome attached, but format-on-save still didn't work.
4. User confirmed `supports_method` returned correct values when checked manually (`willSave=false`, `formatting=true`).
5. Added debug print to `LspAttach` callback — revealed `willSave=false format=false` at attach time, proving the timing issue.
6. Moved `LspAttach` registration before `vim.lsp.enable()` calls — didn't help (the issue was server-side, not registration timing).
7. Replaced `LspAttach`-based approach with direct `BufWritePre` — works.

## Solution

### Fix 1: Override biome root detection

Created `after/lsp/biome.lua` to replace the strict upstream `root_dir`:

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

### Fix 2: Wire up blink.cmp capabilities globally

Replaced the unused local variable with `vim.lsp.config('*', ...)` and added an explicit dependency:

```lua
-- Plugin spec
"neovim/nvim-lspconfig",
dependencies = { 'saghen/blink.cmp' },
config = function()
  vim.lsp.config('*', {
    capabilities = require('blink.cmp').get_lsp_capabilities(),
  })
  -- ...
end
```

### Fix 3: Replace LspAttach format-on-save with direct BufWritePre

```lua
-- BEFORE (broken — supports_method returns false at attach time):
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client:supports_method('textDocument/formatting') then
      vim.api.nvim_create_autocmd('BufWritePre', { ... })
    end
  end,
})

-- AFTER (works — vim.lsp.buf.format() checks capabilities at save time):
vim.api.nvim_create_autocmd('BufWritePre', {
  group = vim.api.nvim_create_augroup('my.lsp', {}),
  callback = function(args)
    vim.lsp.buf.format({ bufnr = args.buf, timeout_ms = 1000 })
  end,
})
```

## Key Insight

**LSP capability checks must be deferred to use-time, not attach-time.** Servers don't always report all capabilities immediately when `LspAttach` fires. `vim.lsp.buf.format()` handles capability negotiation internally at invocation time, when the server is fully initialized. A single global `BufWritePre` autocmd is simpler and more robust than per-client `LspAttach` handlers.

## Prevention Strategies

- **Check `:LspInfo` after opening files** where you expect LSP — confirms which servers attached and which didn't.
- **Use `vim.lsp.config('*', ...)` for global settings** in Neovim 0.11+ — don't store capabilities in local variables.
- **Prefer `BufWritePre` over `LspAttach` for format-on-save** — avoids capability timing races.
- **Use `after/lsp/<server>.lua`** to override server-specific settings like `root_dir` without forking nvim-lspconfig.

## Debugging Checklist

- [ ] `:LspInfo` — is the server in the "attached" list?
- [ ] `:messages` — any silent errors?
- [ ] `:checkhealth lsp` — configuration health
- [ ] `:lua print(vim.inspect(vim.lsp.get_clients()))` — verify client details
- [ ] `:lua vim.lsp.buf.format()` — does manual formatting work?
- [ ] `:lua print(vim.inspect(vim.api.nvim_get_autocmds({group='my.lsp'})))` — is BufWritePre registered?
- [ ] Add `print()` inside callbacks to trace execution

## References

- [Neovim 0.11 LSP docs](https://neovim.io/doc/user/lsp.html)
- [nvim-lspconfig biome.lua source](https://github.com/neovim/nvim-lspconfig/blob/master/lsp/biome.lua)
- [Biome LSP capabilities](https://deepwiki.com/biomejs/biome/7.3-lsp-and-editor-integration)
- [blink.cmp capabilities in Neovim 0.11](https://github.com/Saghen/blink.cmp/discussions/1802)
- [What's New in Neovim 0.11](https://gpanders.com/blog/whats-new-in-neovim-0-11/)
