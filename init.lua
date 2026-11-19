-- Adapted from kickstart.nvim

-- ============================================================
-- SECTION 1: OPTIONS
-- Core Neovim settings, leaders, options
-- ============================================================
do
  vim.loader.enable()

  --  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
  vim.g.mapleader = ' '
  vim.g.maplocalleader = ' '

  vim.g.have_nerd_font = true

  -- [[ Setting options ]]
  vim.o.number = true
  vim.o.mouse = 'a'
  vim.o.showmode = false
  vim.o.breakindent = true
  vim.o.undofile = true
  vim.o.ignorecase = true
  vim.o.smartcase = true
  vim.o.signcolumn = 'yes'
  vim.o.updatetime = 250
  vim.o.timeoutlen = 300
  vim.o.splitright = true
  vim.o.splitbelow = true
  vim.o.list = true
  vim.opt.listchars = { tab = '» ', lead = '·', trail = '·', nbsp = '␣' }
  vim.o.inccommand = 'split'
  vim.o.cursorline = true
  vim.o.scrolloff = 10
  vim.o.confirm = true
  vim.o.expandtab = true
  vim.o.tabstop = 2
  vim.o.shiftwidth = 2
  vim.o.softtabstop = -1
end

-- ============================================================
-- SECTION 2: KEYMAPS & AUTOCMDS
-- basic keymaps, basic autocmds
-- ============================================================
do
  -- [[ Basic Keymaps ]]
  vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

  vim.diagnostic.config {
    update_in_insert = false,
    severity_sort = true,
    float = { border = 'rounded', source = 'if_many' },
    underline = { severity = { min = vim.diagnostic.severity.WARN } },

    virtual_text = true,
    virtual_lines = false,

    jump = {
      on_jump = function(_, bufnr)
        vim.diagnostic.open_float {
          bufnr = bufnr,
          scope = 'cursor',
          focus = false,
        }
      end,
    },
  }

  vim.keymap.set('n', '<leader>cd', vim.diagnostic.open_float, { desc = 'Line [D]iagnostics' })
  local function toggle_diagnostic_list(kind)
    return function()
      local winid = kind == 'loc' and vim.fn.getloclist(0, { winid = 0 }).winid or vim.fn.getqflist({ winid = 0 }).winid
      if winid ~= 0 then
        vim.cmd(kind == 'loc' and 'lclose' or 'cclose')
      elseif kind == 'loc' then
        vim.diagnostic.setloclist()
      else
        vim.diagnostic.setqflist()
      end
    end
  end

  vim.keymap.set('n', '<leader>xl', toggle_diagnostic_list 'loc', { desc = 'Location List (Diagnostics)' })
  vim.keymap.set('n', '<leader>xq', toggle_diagnostic_list 'qf', { desc = 'Quickfix List (Diagnostics)' })
  vim.keymap.set('n', ']q', vim.cmd.cnext, { desc = 'Next Quickfix' })
  vim.keymap.set('n', '[q', vim.cmd.cprev, { desc = 'Previous Quickfix' })

  vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

  vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
  vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
  vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
  vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

  -- Closing the gitsigns:// split is enough: gitsigns sets bufhidden=wipe on it,
  -- and the default diffopt 'closeoff' turns diff off in the source window.
  vim.keymap.set('n', '<leader>hx', function()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)):match '^gitsigns://' then vim.api.nvim_win_close(win, true) end
    end
  end, { desc = 'Git diff e[X]it' })

  vim.keymap.set('n', '<S-l>', '<cmd>bnext<CR>', { desc = 'Next buffer' })
  vim.keymap.set('n', '<S-h>', '<cmd>bprevious<CR>', { desc = 'Previous buffer' })
  vim.keymap.set('n', '<leader>d', '<cmd>bdelete<CR>', { desc = '[D]elete buffer' })
  vim.keymap.set('n', '<leader>D', function()
    local cur = vim.api.nvim_get_current_buf()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if buf ~= cur and vim.bo[buf].buflisted then vim.api.nvim_buf_delete(buf, {}) end
    end
  end, { desc = '[D]elete other buffers' })

  -- [[ Basic Autocommands ]]
  vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function() vim.hl.on_yank() end,
  })
end

-- ============================================================
-- SECTION 3: PLUGIN BUILD HOOKS
-- vim.pack build hooks (LuaSnip, nvim-treesitter), gh() repo helper
-- ============================================================
do
  local function run_build(name, cmd, cwd)
    local result = vim.system(cmd, { cwd = cwd }):wait()
    if result.code ~= 0 then
      local stderr = result.stderr or ''
      local stdout = result.stdout or ''
      local output = stderr ~= '' and stderr or stdout
      if output == '' then output = 'No output from build command.' end
      vim.notify(('Build failed for %s:\n%s'):format(name, output), vim.log.levels.ERROR)
    end
  end

  vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
      local name = ev.data.spec.name
      local kind = ev.data.kind
      if kind ~= 'install' and kind ~= 'update' then return end

      if name == 'LuaSnip' then
        if vim.fn.has 'win32' ~= 1 and vim.fn.executable 'make' == 1 then run_build(name, { 'make', 'install_jsregexp' }, ev.data.path) end
        return
      end

      if name == 'nvim-treesitter' then
        if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
        vim.cmd 'TSUpdate'
        return
      end
    end,
  })
end

---@param repo string
---@return string
local function gh(repo) return 'https://github.com/' .. repo end

-- ============================================================
-- SECTION 4: UI / CORE UX PLUGINS
-- Snacks, guess-indent, gitsigns, diffview, which-key, colorscheme, todo-comments, mini modules, render-markdown
-- ============================================================
do
  vim.pack.add { gh 'folke/snacks.nvim' }
  local Snacks = require 'snacks'

  Snacks.setup {
    explorer = {},
    indent = { animate = { enabled = false } },
    picker = {
      icons = { files = vim.g.have_nerd_font and {} or { dir = '▸ ', dir_open = '▾ ', file = '  ' } },
      sources = {
        explorer = { follow_file = false, hidden = true },
      },
    },
  }

  vim.keymap.set('n', '<leader>e', function() Snacks.explorer { cwd = vim.fn.getcwd() } end, { desc = 'File [E]xplorer (cwd)' })
  vim.keymap.set('n', '<leader>E', Snacks.explorer.reveal, { desc = 'File [E]xplorer (current file)', silent = true })

  vim.pack.add { gh 'NMAC427/guess-indent.nvim' }
  require('guess-indent').setup {}

  vim.pack.add { gh 'lewis6991/gitsigns.nvim' }
  require('gitsigns').setup {
    signs = {
      add = { text = '+' }, ---@diagnostic disable-line: missing-fields
      change = { text = '~' }, ---@diagnostic disable-line: missing-fields
      delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
      topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
      changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
    },
    on_attach = function(bufnr)
      local gitsigns = require 'gitsigns'

      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
      end

      map({ 'n', 'x' }, '<leader>hs', ':Gitsigns stage_hunk<CR>', 'Git hunk [S]tage')
      map({ 'n', 'x' }, '<leader>hr', ':Gitsigns reset_hunk<CR>', 'Git hunk [R]eset')
      map('n', '<leader>hS', gitsigns.stage_buffer, 'Git buffer [S]tage')
      map('n', '<leader>hR', gitsigns.reset_buffer, 'Git buffer [R]eset')
      map('n', '<leader>hp', function()
        gitsigns.preview_hunk()
        gitsigns.preview_hunk()
      end, 'Git hunk [P]review and focus')
      map('n', '<leader>hi', gitsigns.preview_hunk_inline, 'Git hunk preview [I]nline')
      map('n', '<leader>hb', function() gitsigns.blame_line { full = true } end, 'Git line [B]lame')
      map('n', '<leader>hB', gitsigns.blame, 'Git buffer [B]lame')
      map('n', '<leader>hd', gitsigns.diffthis, 'Git file [D]iff against index')
      map('n', '<leader>hD', function() gitsigns.diffthis '@' end, 'Git file [D]iff against HEAD')
      map('n', '<leader>tb', gitsigns.toggle_current_line_blame, '[T]oggle Git [B]lame')
      map('n', '<leader>tw', gitsigns.toggle_word_diff, '[T]oggle Git [W]ord diff')
      map({ 'o', 'x' }, 'ih', gitsigns.select_hunk, 'Inside Git hunk')
    end,
  }

  vim.pack.add { gh 'dlyongemallo/diffview-plus.nvim' }
  local diffview_actions = require 'diffview.actions'
  local git_review_hydra = { keys = '<leader>G', loop = true }
  local function diffview_hunk(direction)
    return function()
      if vim.wo.diff then
        vim.cmd.normal { direction == 'next' and ']c' or '[c', bang = true }
      elseif direction == 'next' then
        diffview_actions.next_inline_hunk()
      else
        diffview_actions.prev_inline_hunk()
      end
    end
  end
  require('diffview').setup {
    persist_selections = { enabled = true },
    view = {
      foldlevel = 99,
    },
    keymaps = {
      view = {
        { 'n', 'q', '<cmd>DiffviewClose<CR>', { desc = 'Close Diffview' } },
        {
          'n',
          '<leader>g',
          function()
            git_review_hydra.loop = true
            require('which-key').show(git_review_hydra)
          end,
          { desc = 'Git review navigation' },
        },
        { 'n', '<leader>Gj', 'j', { desc = 'Down' } },
        { 'n', '<leader>Gk', 'k', { desc = 'Up' } },
        { 'n', '<leader>Gn', diffview_hunk 'next', { desc = 'Next hunk' } },
        { 'n', '<leader>Gp', diffview_hunk 'prev', { desc = 'Previous hunk' } },
        { 'n', '<leader>GN', diffview_actions.select_next_entry, { desc = 'Next changed file' } },
        { 'n', '<leader>GP', diffview_actions.select_prev_entry, { desc = 'Previous changed file' } },
      },
      file_panel = {
        { 'n', 'q', '<cmd>DiffviewClose<CR>', { desc = 'Close Diffview' } },
      },
    },
  }

  vim.pack.add { gh 'folke/which-key.nvim' }
  require('which-key').setup {
    delay = 0,
    icons = { mappings = vim.g.have_nerd_font },
    spec = {
      { '<leader>f', group = '[F]ind', mode = { 'n', 'v' } },
      { '<leader>s', group = '[S]ession' },
      { '<leader>x', group = 'diagnostics/quickfix' },
      { '<leader>c', group = '[C]ode' },
      { '<leader>t', group = '[T]oggle' },
      { '<leader>y', group = '[Y]ank' },
      { '<leader>g', group = '[G]it' },
      {
        '<leader>G',
        group = 'Git review navigation',
        cond = function() return require('diffview.lib').get_current_view() ~= nil end,
        expand = function()
          return {
            { 'q', function() git_review_hydra.loop = false end, desc = 'Quit' },
          }
        end,
      },
      { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      { 'gF', desc = 'Go to file and line under cursor' },
    },
  }

  -- [[ Colorscheme ]]
  vim.pack.add { { src = "https://github.com/catppuccin/nvim", name = "catppuccin" } }
  vim.cmd.colorscheme 'catppuccin-mocha'

  vim.pack.add { gh 'folke/todo-comments.nvim' }
  require('todo-comments').setup { signs = false }

  -- [[ mini.nvim ]]
  vim.pack.add { gh 'nvim-mini/mini.nvim' }

  if vim.g.have_nerd_font then
    require('mini.icons').setup()
    MiniIcons.mock_nvim_web_devicons()
  end

  local function yank_path(modifier, include_lines)
    return function()
      local path = vim.fn.expand('%' .. modifier)
      if include_lines then
        local first, last = vim.fn.line '.', vim.fn.line '.'
        if vim.fn.mode():find '[vV\22]' then
          first, last = vim.fn.line 'v', vim.fn.line '.'
          if first > last then first, last = last, first end
        end
        path = path .. ':' .. first .. (first == last and '' or '-' .. last)
      end
      if not path or path == '' then return end
      vim.fn.setreg('+', path)
      vim.notify('Copied: ' .. path)
    end
  end

  vim.keymap.set('n', '<leader>yn', yank_path ':t', { desc = '[Y]ank file[N]ame' })
  vim.keymap.set('n', '<leader>yp', yank_path ':.', { desc = '[Y]ank relative [P]ath' })
  vim.keymap.set('n', '<leader>yP', yank_path ':p', { desc = '[Y]ank absolute [P]ath' })
  vim.keymap.set({ 'n', 'x' }, '<leader>yl', yank_path(':.', true), { desc = '[Y]ank relative [L]ocation' })
  vim.keymap.set({ 'n', 'x' }, '<leader>yL', yank_path(':p', true), { desc = '[Y]ank absolute [L]ocation' })

  local statusline = require 'mini.statusline'
  statusline.setup { use_icons = vim.g.have_nerd_font }

  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_location = function() return '%2l:%-2v' end

  require('mini.tabline').setup()

  local sessions = require 'mini.sessions'
  sessions.setup()
  local session_name = (vim.fn.getcwd():gsub('/', '%%'))
  local session_enabled = vim.fn.argc() == 0
  vim.api.nvim_create_autocmd('StdinReadPre', { callback = function() session_enabled = false end })
  vim.api.nvim_create_autocmd('VimEnter', {
    nested = true,
    callback = function()
      if session_enabled and sessions.detected[session_name] then sessions.read(session_name) end
    end,
  })
  vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function()
      -- only the first save, and only if a file is open; after that mini's autowrite saves the active session
      local has_file = vim.iter(vim.fn.getbufinfo { buflisted = 1 }):any(function(b) return b.name ~= '' end)
      if session_enabled and has_file and vim.v.this_session == '' then sessions.write(session_name, { verbose = false }) end
    end,
  })

  vim.keymap.set('n', '<leader>sr', function() sessions.select 'read' end, { desc = '[S]ession [R]ead' })
  vim.keymap.set('n', '<leader>sd', function() sessions.select 'delete' end, { desc = '[S]ession [D]elete' })
  vim.keymap.set('n', '<leader>sn', function()
    vim.ui.input({ prompt = 'Session name: ' }, function(name)
      if name and name ~= '' then sessions.write(name) end
    end)
  end, { desc = '[S]ession [N]ew' })
  vim.keymap.set('n', '<leader>sw', function()
    sessions.write(vim.v.this_session == '' and session_name or nil)
  end, { desc = '[S]ession [W]rite' })
  vim.keymap.set('n', '<leader>sx', function()
    session_enabled = false
    if sessions.detected[session_name] then
      sessions.delete(session_name, { force = true })
    else
      vim.notify 'No session for this folder'
    end
  end, { desc = '[S]ession clear (this folder)' })

  vim.pack.add { gh 'MeanderingProgrammer/render-markdown.nvim' }
end

-- ============================================================
-- SECTION 5: SEARCH & NAVIGATION
-- Snacks picker keymaps and LSP picker mappings
-- ============================================================
do
  local Snacks = require 'snacks'

  vim.keymap.set('n', '<leader>ff', Snacks.picker.files, { desc = 'Find [F]iles' })
  vim.keymap.set('n', '<leader>fr', Snacks.picker.recent, { desc = 'Find [R]ecent Files' })

  vim.keymap.set('n', '<leader>fg', Snacks.picker.grep, { desc = '[F]ind by [G]rep' })
  vim.keymap.set('n', '<leader>fh', Snacks.picker.help, { desc = '[F]ind [H]elp' })
  vim.keymap.set('n', '<leader>fk', Snacks.picker.keymaps, { desc = '[F]ind [K]eymaps' })
  vim.keymap.set('n', '<leader>fd', Snacks.picker.diagnostics, { desc = '[F]ind [D]iagnostics' })
  vim.keymap.set('n', '<leader>fa', Snacks.picker.resume, { desc = '[F]ind [A]gain' })
  vim.keymap.set('n', '<leader>fc', Snacks.picker.commands, { desc = '[F]ind [C]ommands' })

  vim.keymap.set('n', '<leader>gg', '<cmd>DiffviewOpen<CR>', { desc = '[G]it chan[G]es' })

  vim.keymap.set('n', '<leader><leader>', Snacks.picker.files, { desc = '[ ] Find files' })
  vim.keymap.set('n', '<leader>,', Snacks.picker.buffers, { desc = 'Find open buffers' })
  vim.keymap.set('n', '<leader>cl', Snacks.picker.lsp_config, { desc = '[C]ode [L]SP info' })

  vim.keymap.set({ 'n', 'x' }, '<leader>fw', Snacks.picker.grep_word, { desc = '[F]ind current [W]ord' })

  vim.keymap.set('n', '<leader>fp', Snacks.picker.pickers, { desc = 'Find [P]icker' })

  vim.keymap.set('n', '<leader>/', Snacks.picker.lines, { desc = '[/] Fuzzily search in current buffer' })
  vim.keymap.set('n', '<leader>fb', Snacks.picker.lines, { desc = '[F]ind [B]uffer Lines' })

  vim.keymap.set('n', '<leader>fB', Snacks.picker.grep_buffers, { desc = '[F]ind in Open [B]uffers' })

  vim.keymap.set(
    'n',
    '<leader>fC',
    function() Snacks.picker.files { cwd = vim.fn.stdpath 'config' } end,
    { desc = 'Find Nvim [C]onfig files' }
  )

  -- LazyVim-style LSP keys instead of Nvim's global gr* defaults, so plain
  -- `gr` doesn't wait on grr/gra/... and `gr{char}` keeps its builtin meaning
  -- in non-LSP buffers.
  for _, lhs in ipairs { 'grn', 'grx', 'grr', 'gri', 'grt' } do
    vim.keymap.del('n', lhs)
  end
  vim.keymap.del({ 'n', 'x' }, 'gra')

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('snacks-picker-lsp-attach', { clear = true }),
    callback = function(event)
      local function map(lhs, rhs, desc, opts)
        vim.keymap.set(opts and opts.mode or 'n', lhs, rhs, { buffer = event.buf, desc = 'LSP: ' .. desc, nowait = opts and opts.nowait })
      end

      map('gd', Snacks.picker.lsp_definitions, 'Goto Definition')
      map('gr', Snacks.picker.lsp_references, 'References', { nowait = true })
      map('gI', Snacks.picker.lsp_implementations, 'Goto Implementation')
      map('gy', Snacks.picker.lsp_type_definitions, 'Goto T[y]pe Definition')
      map('gD', vim.lsp.buf.declaration, 'Goto Declaration')
      map('gO', Snacks.picker.lsp_symbols, 'Document symbols')
      map('<leader>fs', Snacks.picker.lsp_symbols, '[F]ind [S]ymbols')
      map('<leader>fS', Snacks.picker.lsp_workspace_symbols, '[F]ind Workspace [S]ymbols')
      map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { mode = { 'n', 'x' } })
      map('<leader>cc', vim.lsp.codelens.run, '[C]ode Lens Run')
      map('<leader>cr', vim.lsp.buf.rename, '[C]ode [R]ename')
    end,
  })
end

-- ============================================================
-- SECTION 6: LSP
-- LSP keymaps and server configuration
-- ============================================================
do
  vim.pack.add { gh 'j-hui/fidget.nvim' }
  require('fidget').setup {}

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
    callback = function(event)
      local map = function(keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
      end

      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client:supports_method('textDocument/documentHighlight', event.buf) then
        local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })

        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })

        vim.api.nvim_create_autocmd('LspDetach', {
          group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
          callback = function(event2)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
          end,
        })
      end

      if client and client:supports_method('textDocument/inlayHint', event.buf) then
        map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
      end
    end,
  })

  ---@type table<string, vim.lsp.Config>
  local servers = {
    gopls = {},

    -- --query-driver lets clangd ask emscripten's em++/emcc for its target + sysroot.
    clangd = { cmd = { 'clangd', '--query-driver=**/em++,**/emcc' } },

    lua_ls = {
      on_init = function(client)
        client.server_capabilities.documentFormattingProvider = false

        if client.workspace_folders then
          local path = client.workspace_folders[1].name
          if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
        end

        local current_settings = client.config.settings --[[@as lspconfig.settings.lua_ls]]
        client.config.settings.Lua = vim.tbl_deep_extend('force', current_settings.Lua, {
          runtime = {
            version = 'LuaJIT',
            path = { 'lua/?.lua', 'lua/?/init.lua' },
          },
          workspace = {
            checkThirdParty = false,
            library = vim.api.nvim_get_runtime_file('', true),
          },
        })
      end,
      ---@type lspconfig.settings.lua_ls
      settings = {
        Lua = {
          format = { enable = false },
        },
      },
    },
  }

  vim.pack.add { gh 'neovim/nvim-lspconfig' }

  for name, server in pairs(servers) do
    vim.lsp.config(name, server)
    vim.lsp.enable(name)
  end
end

-- ============================================================
-- SECTION 7: FORMATTING
-- conform.nvim setup and keymap
-- ============================================================
do
  vim.pack.add { gh 'stevearc/conform.nvim' }
  require('conform').setup {
    notify_on_error = false,
    format_on_save = function(bufnr)
      local enabled_filetypes = {}
      if enabled_filetypes[vim.bo[bufnr].filetype] then
        return { timeout_ms = 500 }
      else
        return nil
      end
    end,
    default_format_opts = {
      lsp_format = 'fallback',
    },
    formatters_by_ft = {},
  }

  vim.keymap.set({ 'n', 'v' }, '<leader>cf', function() require('conform').format { async = true } end, { desc = '[C]ode [F]ormat buffer' })
end

-- ============================================================
-- SECTION 8: AUTOCOMPLETE & SNIPPETS
-- blink.cmp and luasnip setup
-- ============================================================
do
  -- [[ Snippet Engine ]]
  vim.pack.add { { src = gh 'L3MON4D3/LuaSnip', version = vim.version.range '2.*' } }
  require('luasnip').setup {}

  -- [[ Autocomplete Engine ]]
  vim.pack.add { { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' } }
  require('blink.cmp').setup {
    keymap = {
      preset = 'enter',
    },

    appearance = {
      nerd_font_variant = 'mono',
    },

    completion = {
      documentation = { auto_show = false, auto_show_delay_ms = 500 },
    },

    sources = {
      default = { 'lsp', 'path', 'snippets' },
    },

    snippets = { preset = 'luasnip' },

    fuzzy = { implementation = 'lua' },

    signature = { enabled = true },
  }
end

-- ============================================================
-- SECTION 9: TREESITTER
-- Parser installation, syntax highlighting, indentation
-- ============================================================
do
  vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' } }

  local parsers = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' }
  require('nvim-treesitter').install(parsers)

  ---@param buf integer
  ---@param language string
  local function treesitter_try_attach(buf, language)
    if not vim.treesitter.language.add(language) then return end
    vim.treesitter.start(buf, language)

    local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil

    if has_indent_query then vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
  end

  local available_parsers = require('nvim-treesitter').get_available()
  vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
      local buf, filetype = args.buf, args.match

      local language = vim.treesitter.language.get_lang(filetype)
      if not language then return end

      local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

      if vim.tbl_contains(installed_parsers, language) then
        treesitter_try_attach(buf, language)
      elseif vim.tbl_contains(available_parsers, language) then
        require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
      else
        treesitter_try_attach(buf, language)
      end
    end,
  })
end

-- ============================================================
-- SECTION 10: CUSTOM PLUGINS
-- Loads lua/custom/plugins/*.lua
-- ============================================================
do
  require 'custom.plugins'
end

-- vim: ts=2 sts=2 sw=2 et
