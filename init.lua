-- Adapted from kickstart.nvim

-- ============================================================
-- SECTION 1: OPTIONS
-- Core Neovim settings, leaders, options
-- ============================================================
do
  -- Enable faster startup by caching compiled Lua modules
  vim.loader.enable()

  -- Set <space> as the leader key
  -- See `:help mapleader`
  --  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
  vim.g.mapleader = ' '
  vim.g.maplocalleader = ' '

  -- Set to true if you have a Nerd Font installed and selected in the terminal
  vim.g.have_nerd_font = false

  -- [[ Setting options ]]
  --  See `:help vim.o`
  -- NOTE: You can change these options as you wish!
  --  For more options, you can see `:help option-list`

  -- Make line numbers default
  vim.o.number = true
  -- You can also add relative line numbers, to help with jumping.
  --  Experiment for yourself to see if you like it!
  -- vim.o.relativenumber = true

  -- Enable mouse mode, can be useful for resizing splits for example!
  vim.o.mouse = 'a'

  -- Don't show the mode, since it's already in the status line
  vim.o.showmode = false

  -- Sync clipboard between OS and Neovim.
  --  Schedule the setting after `UiEnter` because it can increase startup-time.
  --  Remove this option if you want your OS clipboard to remain independent.
  --  See `:help 'clipboard'`
  vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

  -- Enable break indent
  vim.o.breakindent = true

  -- Enable undo/redo changes even after closing and reopening a file
  vim.o.undofile = true

  -- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
  vim.o.ignorecase = true
  vim.o.smartcase = true

  -- Keep signcolumn on by default
  vim.o.signcolumn = 'yes'

  -- Decrease update time
  vim.o.updatetime = 250

  -- Decrease mapped sequence wait time
  vim.o.timeoutlen = 300

  -- Configure how new splits should be opened
  vim.o.splitright = true
  vim.o.splitbelow = true

  -- Sets how neovim will display certain whitespace characters in the editor.
  --  See `:help 'list'`
  --  and `:help 'listchars'`
  --
  --  Notice listchars is set using `vim.opt` instead of `vim.o`.
  --  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
  --   See `:help lua-options`
  --   and `:help lua-guide-options`
  vim.o.list = true
  vim.opt.listchars = { tab = '» ', lead = '·', trail = '·', nbsp = '␣' }

  -- Preview substitutions live, as you type!
  vim.o.inccommand = 'split'

  -- Show which line your cursor is on
  vim.o.cursorline = true

  -- Minimal number of screen lines to keep above and below the cursor.
  vim.o.scrolloff = 10

  -- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
  -- instead raise a dialog asking if you wish to save the current file(s)
  -- See `:help 'confirm'`
  vim.o.confirm = true

  -- Use spaces by default
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
  --  See `:help vim.keymap.set()`

  -- Clear highlights on search when pressing <Esc> in normal mode
  --  See `:help hlsearch`
  vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

  -- Make <C-c> behave like <Esc> in insert mode (triggers InsertLeave, e.g. diagnostics update)
  vim.keymap.set('i', '<C-c>', '<Esc>')

  -- Diagnostic Config & Keymaps
  --  See `:help vim.diagnostic.Opts`
  vim.diagnostic.config {
    update_in_insert = false,
    severity_sort = true,
    float = { border = 'rounded', source = 'if_many' },
    underline = { severity = { min = vim.diagnostic.severity.WARN } },

    -- Can switch between these as you prefer
    virtual_text = true, -- Text shows up at the end of the line
    virtual_lines = false, -- Text shows up underneath the line, with virtual lines

    -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
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
  -- Toggle: close the list if its window is open, otherwise populate it with
  -- diagnostics and open it (`setloclist`/`setqflist` open the window themselves).
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

  -- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
  -- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
  -- is not what someone will guess without a bit more experience.
  --
  -- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
  -- or just use <C-\><C-n> to exit terminal mode
  vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

  -- Keybinds to make split navigation easier.
  --  Use CTRL+<hjkl> to switch between windows
  --
  --  See `:help wincmd` for a list of all window commands
  vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
  vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
  vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
  vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

  -- Buffer management
  vim.keymap.set('n', '<S-l>', '<cmd>bnext<CR>', { desc = 'Next buffer' })
  vim.keymap.set('n', '<S-h>', '<cmd>bprevious<CR>', { desc = 'Previous buffer' })
  vim.keymap.set('n', '<leader>bd', '<cmd>bdelete<CR>', { desc = '[B]uffer [D]elete' })
  vim.keymap.set('n', '<leader>bo', function()
    local cur = vim.api.nvim_get_current_buf()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if buf ~= cur and vim.bo[buf].buflisted then vim.api.nvim_buf_delete(buf, {}) end
    end
  end, { desc = '[B]uffer close [O]thers' })

  -- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
  -- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
  -- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
  -- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
  -- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

  -- [[ Basic Autocommands ]]
  --  See `:help lua-guide-autocommands`

  -- Highlight when yanking (copying) text
  --  Try it with `yap` in normal mode
  --  See `:help vim.hl.on_yank()`
  vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function() vim.hl.on_yank() end,
  })
end

-- ============================================================
-- SECTION 3: PLUGIN MANAGER INTRO
-- vim.pack intro, build hooks
-- ============================================================
do
  -- [[ Intro to `vim.pack` ]]
  -- `vim.pack` is a new plugin manager built into Neovim,
  --  which provides a Lua interface for installing and managing plugins.
  --
  --  See `:help vim.pack`, `:help vim.pack-examples` or the
  --  excellent blog post from the creator of vim.pack and mini.nvim:
  --  https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack
  --
  --  To inspect plugin state and pending updates, run
  --    :lua vim.pack.update(nil, { offline = true })
  --
  --  To update plugins, run
  --    :lua vim.pack.update()
  --
  --
  --  Throughout the rest of the config there will be examples
  --  of how to install and configure plugins using `vim.pack`.
  --
  --  In this section we set up some autocommands to run build
  --  steps for certain plugins after they are installed or updated.

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

  -- This autocommand runs after a plugin is installed or updated and
  --  runs the appropriate build command for that plugin if necessary.
  --
  -- See `:help vim.pack-events`
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

---Because most plugins are hosted on GitHub, you can use the helper
---function to have less repetition in the following sections.
---@param repo string
---@return string
local function gh(repo) return 'https://github.com/' .. repo end

-- ============================================================
-- SECTION 4: UI / CORE UX PLUGINS
-- guess-indent, gitsigns, which-key, colorscheme, todo-comments, mini modules
-- ============================================================
do
  -- [[ Installing and Configuring Plugins ]]
  --
  -- To install a plugin simply call `vim.pack.add` with its git url.
  -- This will download the default branch of the plugin, which will usually be `main` or `master`
  -- You can also have more advanced specs, which we will talk about later.
  --
  -- For most plugins its not enough to install them, you also need to call their `.setup()` to start them.
  --
  -- For example, lets say we want to install `guess-indent.nvim` - a plugin for
  -- automatically detecting and setting the indentation.
  --
  -- We first install it from https://github.com/NMAC427/guess-indent.nvim
  -- and then call its `setup()` function to start it with default settings.
  vim.pack.add { gh 'NMAC427/guess-indent.nvim' }
  require('guess-indent').setup {}

  -- Here is a more advanced configuration example that passes options to `gitsigns.nvim`
  --
  -- See `:help gitsigns` to understand what each configuration key does.
  -- Adds git related signs to the gutter, as well as utilities for managing changes
  vim.pack.add { gh 'lewis6991/gitsigns.nvim' }
  require('gitsigns').setup {
    signs = {
      add = { text = '+' }, ---@diagnostic disable-line: missing-fields
      change = { text = '~' }, ---@diagnostic disable-line: missing-fields
      delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
      topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
      changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
    },
  }

  -- Useful plugin to show you pending keybinds.
  vim.pack.add { gh 'folke/which-key.nvim' }
  require('which-key').setup {
    -- Delay between pressing a key and opening which-key (milliseconds)
    delay = 0,
    icons = { mappings = vim.g.have_nerd_font },
    -- Document existing key chains
    spec = {
      { '<leader>f', group = '[F]ind', mode = { 'n', 'v' } },
      { '<leader>s', group = '[S]ession' },
      { '<leader>x', group = 'diagnostics/quickfix' },
      { '<leader>b', group = '[B]uffer' },
      { '<leader>c', group = '[C]ode' },
      { '<leader>t', group = '[T]oggle' },
      { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } }, -- Enable gitsigns recommended keymaps first
      { 'gr', group = 'LSP Actions', mode = { 'n' } },
    },
  }

  -- [[ Colorscheme ]]
  -- You can easily change to a different colorscheme.
  -- Change the name of the colorscheme plugin below, and then
  -- change the command under that to load whatever the name of that colorscheme is.
  --
  -- If you want to see what colorschemes are already installed, you can use `:Pick colorschemes`.
  vim.pack.add { { src = "https://github.com/catppuccin/nvim", name = "catppuccin" } }

  -- Load the colorscheme here.
  -- Like many other themes, this one has different styles, and you could load
  -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
  -- vim.cmd.colorscheme 'tokyonight-night'
  vim.cmd.colorscheme 'catppuccin-mocha'

  -- Highlight todo, notes, etc in comments
  vim.pack.add { gh 'folke/todo-comments.nvim' }
  require('todo-comments').setup { signs = false }

  -- [[ mini.nvim ]]
  --  A collection of various small independent plugins/modules
  vim.pack.add { gh 'nvim-mini/mini.nvim' }

  -- If a nerd font is available, load the icons module for pretty icons in various plugins.
  if vim.g.have_nerd_font then
    require('mini.icons').setup()
    -- Used for backwards compatibility with plugins that require `nvim-web-devicons`
    MiniIcons.mock_nvim_web_devicons()
  end

  -- Better Around/Inside textobjects
  --
  -- Examples:
  --  - va)  - [V]isually select [A]round [)]paren
  --  - yiiq - [Y]ank [I]nside [I]+1 [Q]uote
  --  - ci'  - [C]hange [I]nside [']quote
  require('mini.ai').setup {
    -- NOTE: Avoid conflicts with the built-in incremental selection mappings on Neovim>=0.12 (see `:help treesitter-incremental-selection`)
    mappings = {
      around_next = 'aa',
      inside_next = 'ii',
    },
    n_lines = 500,
  }

  -- Add/delete/replace surroundings (brackets, quotes, etc.)
  --
  -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
  -- - sd'   - [S]urround [D]elete [']quotes
  -- - sr)'  - [S]urround [R]eplace [)] [']
  require('mini.surround').setup()

  -- File explorer
  --
  -- - <leader>e - toggle file explorer (cwd)
  -- - -         - toggle file explorer at the current file
  require('mini.files').setup()
  -- Show a `g? help` hint on the focused explorer column
  vim.api.nvim_create_autocmd('User', {
    pattern = 'MiniFilesWindowUpdate',
    callback = function(args)
      local is_cur = args.data.win_id == vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_config(args.data.win_id, { footer = is_cur and ' g? help ' or '', footer_pos = 'right' })
    end,
  })
  vim.keymap.set('n', '<leader>e', function()
    if not MiniFiles.close() then MiniFiles.open() end
  end, { desc = 'File [E]xplorer (cwd)' })
  vim.keymap.set('n', '-', function()
    if not MiniFiles.close() then MiniFiles.open(vim.api.nvim_buf_get_name(0), true) end
  end, { desc = 'File explorer (current file)' })

  -- Yank a file's path to the clipboard: the entry under the cursor in
  -- mini.files (without opening it), or the current buffer's file otherwise.
  --  <leader>yn - filename only
  --  <leader>yr - path relative to nvim cwd
  --  <leader>ya - absolute path
  local function yank_path(modifier)
    return function()
      local path
      if vim.bo.filetype == 'minifiles' then
        local entry = MiniFiles.get_fs_entry()
        path = entry and vim.fn.fnamemodify(entry.path, modifier)
      else
        path = vim.fn.expand('%' .. modifier)
      end
      if not path or path == '' then return end
      vim.fn.setreg('+', path)
      vim.notify('Copied: ' .. path)
    end
  end

  vim.keymap.set('n', '<leader>yn', yank_path ':t', { desc = '[Y]ank file[N]ame' })
  vim.keymap.set('n', '<leader>yr', yank_path ':.', { desc = '[Y]ank [R]elative path' })
  vim.keymap.set('n', '<leader>ya', yank_path ':p', { desc = '[Y]ank [A]bsolute path' })

  -- Simple and easy statusline.
  --  You could remove this setup call if you don't like it,
  --  and try some other statusline plugin
  local statusline = require 'mini.statusline'
  -- Set `use_icons` to true if you have a Nerd Font
  statusline.setup { use_icons = vim.g.have_nerd_font }

  -- You can configure sections in the statusline by overriding their
  -- default behavior. For example, here we set the section for
  -- cursor location to LINE:COLUMN
  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_location = function() return '%2l:%-2v' end

  require('mini.tabline').setup()

  -- Per-folder sessions, stored in stdpath('data')/session.
  --  `nvim` with no args restores the session for cwd; `nvim file` or stdin skips it.
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
    -- write the active session, or this folder's if none is active yet
    sessions.write(vim.v.this_session == '' and session_name or nil)
  end, { desc = '[S]ession [W]rite' })
  vim.keymap.set('n', '<leader>sx', function()
    -- delete this folder's session and don't recreate it on quit
    session_enabled = false
    if sessions.detected[session_name] then
      sessions.delete(session_name, { force = true })
    else
      vim.notify 'No session for this folder'
    end
  end, { desc = '[S]ession clear (this folder)' })

  -- ... and there is more!
  --  Check out: https://github.com/nvim-mini/mini.nvim
end

-- ============================================================
-- SECTION 5: SEARCH & NAVIGATION
-- mini.pick setup, keymaps, LSP picker mappings
-- ============================================================
do
  -- [[ Fuzzy Finder (files, lsp, etc) ]]
  --
  -- mini.pick is the picker; mini.extra supplies the extra pickers
  -- (diagnostics, keymaps, oldfiles, lsp, buffer lines, ...).
  -- Both ship inside mini.nvim, already added in Section 4.
  --
  -- Try it with `:Pick files` or `:Pick help`. In the picker:
  --  - <Tab>      toggle preview
  --  - <C-Space>  refine the current matches
  --  - <C-s>/<C-v>/<C-t>  open in split / vsplit / tab
  --  - <C-x>      mark item, <C-a> mark all, <M-CR> send marked to quickfix
  --
  -- See `:help mini.pick`, `:help mini.extra` and `:help MiniPick-actions`
  local pick = require 'mini.pick'
  local extra = require 'mini.extra'

  pick.setup { window = { prompt_prefix = '(S-Tab help) > ' } }
  extra.setup() -- also registers its pickers into MiniPick.registry

  -- Use mini.pick for `vim.ui.select`
  vim.ui.select = pick.ui_select

  -- file/find: opening things
  vim.keymap.set('n', '<leader>ff', pick.builtin.files, { desc = 'Find [F]iles' })
  vim.keymap.set('n', '<leader>fr', extra.pickers.oldfiles, { desc = 'Find [R]ecent Files' })

  -- search: looking things up
  vim.keymap.set('n', '<leader>fg', pick.builtin.grep_live, { desc = '[F]ind by [G]rep' })
  vim.keymap.set('n', '<leader>fh', pick.builtin.help, { desc = '[F]ind [H]elp' })
  vim.keymap.set('n', '<leader>fk', extra.pickers.keymaps, { desc = '[F]ind [K]eymaps' })
  vim.keymap.set('n', '<leader>fd', extra.pickers.diagnostic, { desc = '[F]ind [D]iagnostics' })
  vim.keymap.set('n', '<leader>fR', pick.builtin.resume, { desc = '[F]ind [R]esume' })
  vim.keymap.set('n', '<leader>fc', extra.pickers.commands, { desc = '[F]ind [C]ommands' })
  -- Buffers picker with <C-d> to wipe out (delete) marked buffers (mark with
  -- <C-x>/<C-a>), or just the buffer under the cursor if none are marked.
  -- See `:help MiniPick.builtin.buffers()` and `:help MiniPick-actions-mark`.
  vim.keymap.set('n', '<leader><leader>', function()
    local wipeout = function()
      local matches = MiniPick.get_picker_matches() or {}
      local items = (matches.marked and #matches.marked > 0) and matches.marked or { matches.current }
      for _, item in ipairs(items) do vim.api.nvim_buf_delete(item.bufnr, {}) end
    end
    pick.builtin.buffers({}, { mappings = { wipeout = { char = '<C-d>', func = wipeout } } })
  end, { desc = '[ ] Find existing buffers' })

  -- Grep the word (or visual selection) under the cursor.
  vim.keymap.set({ 'n', 'x' }, '<leader>fw', function()
    local pattern
    if vim.fn.mode():find '[vV]' then
      vim.cmd 'normal! "vy'
      pattern = vim.fn.getreg 'v'
    else
      pattern = vim.fn.expand '<cword>'
    end
    pick.builtin.grep { pattern = vim.fn.escape(pattern, '\\.*$^[]') }
  end, { desc = '[F]ind current [W]ord' })

  -- Pick a picker: lists everything registered in `MiniPick.registry`.
  vim.keymap.set('n', '<leader>fp', function()
    local names = vim.tbl_keys(MiniPick.registry)
    table.sort(names)
    MiniPick.start {
      source = {
        name = 'Pickers',
        items = names,
        choose = function(item) vim.schedule(function() MiniPick.registry[item]() end) end,
      },
    }
  end, { desc = 'Find [P]icker' })

  -- Fuzzily search in the current buffer.
  vim.keymap.set('n', '<leader>/', function() extra.pickers.buf_lines { scope = 'current' } end, { desc = '[/] Fuzzily search in current buffer' })
  vim.keymap.set('n', '<leader>fb', function() extra.pickers.buf_lines { scope = 'current' } end, { desc = '[F]ind [B]uffer Lines' })
  vim.keymap.set('n', '<leader>l', '<cmd>nohlsearch<CR>', { desc = 'No Hi[l]ight' } )

  -- Search lines across all open buffers.
  vim.keymap.set('n', '<leader>fB', function() extra.pickers.buf_lines { scope = 'all' } end, { desc = '[F]ind in Open [B]uffers' })

  -- Shortcut for searching your Neovim configuration files
  vim.keymap.set(
    'n',
    '<leader>fC',
    function() pick.builtin.files(nil, { source = { cwd = vim.fn.stdpath 'config' } }) end,
    { desc = 'Find Nvim [C]onfig files' }
  )

  -- LSP jump pickers start hidden. Once items are in: choose a lone result,
  -- otherwise show the picker. See mini.nvim #978 and `:h nvim_open_win()` (hide).
  local hidden = { window = { config = { hide = true } } }
  vim.api.nvim_create_autocmd('User', {
    pattern = 'MiniPickStart',
    group = vim.api.nvim_create_augroup('minipick-lsp-jump', { clear = true }),
    callback = function()
      local opts, items = MiniPick.get_picker_opts() or {}, MiniPick.get_picker_items() or {}
      if not vim.tbl_get(opts, 'window', 'config', 'hide') then return end
      if #items > 1 then return MiniPick.set_picker_opts { window = { config = { hide = false } } } end
      local choose = opts.source.choose or MiniPick.default_choose
      MiniPick.stop()
      choose(items[1])
    end,
  })
  local function lsp(scope)
    return function() extra.pickers.lsp({ scope = scope }, hidden) end
  end

  -- LSP pickers, attached per-buffer when a server attaches.
  -- If you later switch picker plugins, this is where to update these mappings.
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('minipick-lsp-attach', { clear = true }),
    callback = function(event)
      local function map(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { buffer = event.buf, desc = 'LSP: ' .. desc }) end

      map('grr', lsp 'references', 'References')
      map('gri', lsp 'implementation', 'Implementation')
      map('grd', lsp 'definition', 'Definition')
      map('grt', lsp 'type_definition', 'Type definition')
      map('grD', vim.lsp.buf.declaration, 'Declaration')
      map('gO', function() extra.pickers.lsp { scope = 'document_symbol' } end, 'Document symbols')
      map('grw', function() extra.pickers.lsp { scope = 'workspace_symbol' } end, 'Workspace symbols')
      -- gra (code action) and grn (rename) stay as the 0.11 defaults
    end,
  })
end

-- ============================================================
-- SECTION 6: LSP
-- LSP keymaps and server configuration
-- ============================================================
do
  -- [[ LSP Configuration ]]
  -- Brief aside: **What is LSP?**
  --
  -- LSP is an initialism you've probably heard, but might not understand what it is.
  --
  -- LSP stands for Language Server Protocol. It's a protocol that helps editors
  -- and language tooling communicate in a standardized fashion.
  --
  -- In general, you have a "server" which is some tool built to understand a particular
  -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
  -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
  -- processes that communicate with some "client" - in this case, Neovim!
  --
  -- LSP provides Neovim with features like:
  --  - Go to definition
  --  - Find references
  --  - Autocompletion
  --  - Symbol Search
  --  - and more!
  --
  -- Thus, Language Servers are external tools that must be installed separately from
  -- Neovim. This config expects them to come from the system (Homebrew, your
  -- package manager, or the language's own toolchain) and be on `$PATH`.
  --
  -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
  -- and elegantly composed help section, `:help lsp-vs-treesitter`

  -- Useful status updates for LSP.
  vim.pack.add { gh 'j-hui/fidget.nvim' }
  require('fidget').setup {}

  --  This function gets run when an LSP attaches to a particular buffer.
  --    That is to say, every time a new file is opened that is associated with
  --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
  --    function will be executed to configure the current buffer
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
    callback = function(event)
      -- NOTE: Remember that Lua is a real programming language, and as such it is possible
      -- to define small helper and utility functions so you don't have to repeat yourself.
      --
      -- In this case, we create a function that lets us more easily define mappings specific
      -- for LSP related items. It sets the mode, buffer and description for us each time.
      local map = function(keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
      end

      -- Rename the variable under your cursor.
      --  Most Language Servers support renaming across files, etc.
      map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')

      -- The following two autocommands are used to highlight references of the
      -- word under your cursor when your cursor rests there for a little while.
      --    See `:help CursorHold` for information about when this is executed
      --
      -- When you move your cursor, the highlights will be cleared (the second autocommand).
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

      -- The following code creates a keymap to toggle inlay hints in your
      -- code, if the language server you are using supports them
      --
      -- This may be unwanted, since they displace some of your code
      if client and client:supports_method('textDocument/inlayHint', event.buf) then
        map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
      end
    end,
  })

  -- Enable the following language servers
  --  Feel free to add/remove any LSPs that you want here. Install the matching
  --  server binary yourself and make sure it is on `$PATH`.
  --  See `:help lsp-config` for information about keys and how to configure
  ---@type table<string, vim.lsp.Config>
  local servers = {
    -- gopls = {},
    -- pyright = {},
    -- rust_analyzer = {},
    --
    -- Some languages (like typescript) have entire language plugins that can be useful:
    --    https://github.com/pmizio/typescript-tools.nvim
    --
    -- But for many setups, the LSP (`ts_ls`) will work just fine
    -- ts_ls = {},

    -- --query-driver lets clangd ask emscripten's em++/emcc for its target + sysroot.
    clangd = { cmd = { 'clangd', '--query-driver=**/em++,**/emcc' } },

    -- Special Lua Config, as recommended by neovim help docs
    lua_ls = {
      on_init = function(client)
        client.server_capabilities.documentFormattingProvider = false -- Disable formatting (formatting is done by stylua)

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
            -- NOTE: this is a lot slower and will cause issues when working on your own configuration.
            --  See https://github.com/neovim/nvim-lspconfig/issues/3189
            library = vim.api.nvim_get_runtime_file('', true),
          },
        })
      end,
      ---@type lspconfig.settings.lua_ls
      settings = {
        Lua = {
          format = { enable = false }, -- Disable formatting (formatting is done by stylua)
        },
      },
    },
  }

  vim.pack.add { gh 'neovim/nvim-lspconfig' }

  -- Enable each configured server. `nvim-lspconfig` supplies the default
  -- `cmd`/`filetypes`/`root_markers`; a server is only started if its
  -- executable is found on `$PATH`.
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
  -- [[ Formatting ]]
  vim.pack.add { gh 'stevearc/conform.nvim' }
  require('conform').setup {
    notify_on_error = false,
    format_on_save = function(bufnr)
      -- You can specify filetypes to autoformat on save here:
      local enabled_filetypes = {
        -- lua = true,
        -- python = true,
      }
      if enabled_filetypes[vim.bo[bufnr].filetype] then
        return { timeout_ms = 500 }
      else
        return nil
      end
    end,
    default_format_opts = {
      lsp_format = 'fallback', -- Use external formatters if configured below, otherwise use LSP formatting. Set to `false` to disable LSP formatting entirely.
    },
    -- You can also specify external formatters in here.
    formatters_by_ft = {
      -- rust = { 'rustfmt' },
      -- Conform can also run multiple formatters sequentially
      -- python = { "isort", "black" },
      --
      -- You can use 'stop_after_first' to run the first available formatter from the list
      -- javascript = { "prettierd", "prettier", stop_after_first = true },
    },
  }

  vim.keymap.set({ 'n', 'v' }, '<leader>cf', function() require('conform').format { async = true } end, { desc = '[C]ode [F]ormat buffer' })
end

-- ============================================================
-- SECTION 8: AUTOCOMPLETE & SNIPPETS
-- blink.cmp and luasnip setup
-- ============================================================
do
  -- [[ Snippet Engine ]]

  -- NOTE: You can also specify plugin using a version range for its git tag.
  --  See `:help vim.version.range()` for more info
  vim.pack.add { { src = gh 'L3MON4D3/LuaSnip', version = vim.version.range '2.*' } }
  require('luasnip').setup {}

  -- `friendly-snippets` contains a variety of premade snippets.
  --    See the README about individual language/framework/plugin snippets:
  --    https://github.com/rafamadriz/friendly-snippets
  --
  -- vim.pack.add { gh 'rafamadriz/friendly-snippets' }
  -- require('luasnip.loaders.from_vscode').lazy_load()

  -- [[ Autocomplete Engine ]]
  vim.pack.add { { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' } }
  require('blink.cmp').setup {
    keymap = {
      -- 'default' (recommended) for mappings similar to built-in completions
      --   <c-y> to accept ([y]es) the completion.
      --    This will auto-import if your LSP supports it.
      --    This will expand snippets if the LSP sent a snippet.
      -- 'super-tab' for tab to accept
      -- 'enter' for enter to accept
      -- 'none' for no mappings
      --
      -- For an understanding of why the 'default' preset is recommended,
      -- you will need to read `:help ins-completion`
      --
      -- No, but seriously. Please read `:help ins-completion`, it is really good!
      --
      -- All presets have the following mappings:
      -- <tab>/<s-tab>: move to right/left of your snippet expansion
      -- <c-space>: Open menu or open docs if already open
      -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
      -- <c-e>: Hide menu
      -- <c-k>: Toggle signature help
      --
      -- See `:help blink-cmp-config-keymap` for defining your own keymap
      preset = 'enter',

      -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
      --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
    },

    appearance = {
      -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = 'mono',
    },

    completion = {
      -- By default, you may press `<c-space>` to show the documentation.
      -- Optionally, set `auto_show = true` to show the documentation after a delay.
      documentation = { auto_show = false, auto_show_delay_ms = 500 },
    },

    sources = {
      default = { 'lsp', 'path', 'snippets' },
    },

    snippets = { preset = 'luasnip' },

    -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
    -- which automatically downloads a prebuilt binary when enabled.
    --
    -- By default, we use the Lua implementation instead, but you may enable
    -- the rust implementation via `'prefer_rust_with_warning'`
    --
    -- See `:help blink-cmp-config-fuzzy` for more information
    fuzzy = { implementation = 'lua' },

    -- Shows a signature help window while you type arguments for a function
    signature = { enabled = true },
  }
end

-- ============================================================
-- SECTION 9: TREESITTER
-- Parser installation, syntax highlighting, folds, indentation
-- ============================================================
do
  -- [[ Configure Treesitter ]]
  --  Used to highlight, edit, and navigate code
  --
  --  See `:help nvim-treesitter-intro`

  -- NOTE: You can also specify a branch or a specific commit
  vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' } }

  -- Ensure basic parsers are installed
  local parsers = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' }
  require('nvim-treesitter').install(parsers)

  ---@param buf integer
  ---@param language string
  local function treesitter_try_attach(buf, language)
    -- Check if a parser exists and load it
    if not vim.treesitter.language.add(language) then return end
    -- Enable syntax highlighting and other treesitter features
    vim.treesitter.start(buf, language)

    -- Enable treesitter based folds
    -- For more info on folds see `:help folds`
    -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    -- vim.wo.foldmethod = 'expr'

    -- Check if treesitter indentation is available for this language, and if so enable it
    -- in case there is no indent query, the indentexpr will fallback to the vim's built in one
    local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil

    -- Enable treesitter based indentation
    if has_indent_query then vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
  end

  local available_parsers = require('nvim-treesitter').get_available()
  vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
      local buf, filetype = args.buf, args.match

      local language = vim.treesitter.language.get_lang(filetype)
      if not language then return end

      local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

      if vim.tbl_contains(installed_parsers, language) then
        -- Enable the parser if it is already installed
        treesitter_try_attach(buf, language)
      elseif vim.tbl_contains(available_parsers, language) then
        -- If a parser is available in `nvim-treesitter`, auto-install it and enable it after the installation is done
        require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
      else
        -- Try to enable treesitter features in case the parser exists but is not available from `nvim-treesitter`
        treesitter_try_attach(buf, language)
      end
    end,
  })
end

-- ============================================================
-- SECTION 10: OPTIONAL EXAMPLES / NEXT STEPS
-- kickstart.plugins.* examples
-- ============================================================
do
  -- The following comments only work if you have downloaded the kickstart repo, not just copy pasted the
  -- init.lua. If you want these files, they are in the repository, so you can just download them and
  -- place them in the correct locations.

  -- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
  --
  --  Here are some example plugins that I've included in the Kickstart repository.
  --  Uncomment any of the lines below to enable them (you will need to restart nvim).
  --
  -- require 'kickstart.plugins.debug'
  -- require 'kickstart.plugins.indent_line'
  -- require 'kickstart.plugins.lint'
  -- require 'kickstart.plugins.autopairs'
  -- require 'kickstart.plugins.neo-tree'
  -- require 'kickstart.plugins.gitsigns' -- adds gitsigns recommended keymaps

  -- NOTE: You can add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --
  --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  -- require 'custom.plugins'
end

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
