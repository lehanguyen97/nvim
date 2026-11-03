-- Git changes view: `git diff HEAD` plus untracked files, folded per hunk.
-- Rebuilt on every open (hunks shift after edits/staging); the cursor position
-- when leaving the view is kept per repo so reopening lands back on that hunk.
local M = {}

local git_changes_last = {}

function M.open()
  local root = vim.fs.root(0, '.git')
  if not root then return vim.notify('Not in a Git repository', vim.log.levels.WARN) end
  local function git(args, env)
    local cmd = vim.list_extend({ 'git', '-C', root, '-c', 'core.quotePath=false' }, args)
    local out = vim.system(cmd, { text = true, env = env }):wait().stdout
    return vim.split(out or '', '\n', { trimempty = true })
  end

  -- Intent-to-add untracked files in a throwaway copy of the index, so a single
  -- `git diff` includes them without touching the real index.
  local index = vim.fn.tempname()
  vim.uv.fs_copyfile(git({ 'rev-parse', '--path-format=absolute', '--git-path', 'index' })[1], index)
  local env = { GIT_INDEX_FILE = index }
  git({ 'add', '--intent-to-add', '.' }, env)
  local lines = git({ 'diff', '--no-color', '--no-ext-diff', 'HEAD' }, env)
  os.remove(index)
  if #lines == 0 then return vim.notify 'No changes' end

  -- Header line and path of the file whose diff contains line i. Path comes from
  -- the ---/+++ lines (`diff --git a/x b/y` is ambiguous when a path contains " b/").
  local function file_at(i)
    local header = i
    while header > 0 and not vim.startswith(lines[header], 'diff --git ') do
      header = header - 1
    end
    if header == 0 then return end
    local path
    for j = header + 1, #lines do
      local l = lines[j]
      if vim.startswith(l, 'diff --git ') or vim.startswith(l, '@@') then break end
      -- b/ side wins; a/ side is kept for deleted files (+++ /dev/null).
      path = l:match '^%+%+%+ b/(.-)\t?$' or l:match '^rename to (.*)$' or path or l:match '^%-%-%- a/(.-)\t?$'
    end
    return header, path or lines[header]:match ' b/(.*)$' -- binary files have no ---/+++ lines
  end

  local restore_lnum = 1
  local last = git_changes_last[root]
  if last then
    for i, l in ipairs(lines) do
      if vim.startswith(l, 'diff --git ') and select(2, file_at(i)) == last.path then
        restore_lnum = i
        for j = i + 1, #lines do
          if vim.startswith(lines[j], 'diff --git ') then break end
          local s, c = lines[j]:match '^@@ %-%S+ %+(%d+),?(%d*)'
          s, c = tonumber(s), tonumber(c) or 1
          if s and last.lnum >= s and last.lnum < s + c then
            restore_lnum = j
            break
          end
        end
        break
      end
    end
  end

  local origin = vim.api.nvim_get_current_tabpage()
  vim.cmd 'tabnew'
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype, vim.bo[buf].bufhidden, vim.bo[buf].modifiable, vim.bo[buf].filetype = 'nofile', 'wipe', false, 'diff'
  -- One fold per file, nested fold per hunk; foldlevel 1 = files open, hunks closed.
  vim.wo.foldmethod, vim.wo.foldlevel = 'expr', 1
  vim.wo.foldexpr = [[getline(v:lnum) =~ '^diff --git' ? '>1' : getline(v:lnum) =~ '^@@' ? '>2' : '=']]
  vim.api.nvim_win_set_cursor(0, { restore_lnum, 0 })
  vim.wo.winbar = ' <CR>/gf open · <Tab> fold · q close'

  -- Path and line in the real file for the diff line under the cursor.
  local function cursor_source()
    local cur = vim.fn.line '.'
    local header, path = file_at(cur)
    if not path then return end
    local hunk = cur
    while hunk > header and not vim.startswith(lines[hunk], '@@') do
      hunk = hunk - 1
    end
    if hunk == header then -- on file header lines: first hunk of the file
      hunk = header + 1
      while lines[hunk] and not vim.startswith(lines[hunk], '@@') and not vim.startswith(lines[hunk], 'diff --git ') do
        hunk = hunk + 1
      end
      if not (lines[hunk] and vim.startswith(lines[hunk], '@@')) then return path, 1 end
      cur = hunk
    end
    local start = tonumber(lines[hunk]:match '^@@ %-%S+ %+(%d+)') or 1
    local target = start - 1
    for l = hunk + 1, cur do
      local c = lines[l]:sub(1, 1)
      if c == ' ' or c == '+' then target = target + 1 end -- skip '-' and '\ No newline'
    end
    return path, math.max(target, start, 1)
  end

  -- BufLeave also fires when the view's window closes, so q, <CR>, :q and gt all save.
  vim.api.nvim_create_autocmd('BufLeave', {
    buffer = buf,
    callback = function()
      local path, lnum = cursor_source()
      if path then git_changes_last[root] = { path = path, lnum = lnum } end
    end,
  })

  -- :tabclose focuses the tab to the right; return to the tab the view was opened from.
  local function close_view()
    vim.cmd 'tabclose'
    if vim.api.nvim_tabpage_is_valid(origin) then vim.api.nvim_set_current_tabpage(origin) end
  end

  local function open_change()
    local path, target = cursor_source()
    if not path or not vim.uv.fs_stat(root .. '/' .. path) then return vim.notify 'File was deleted' end
    close_view()
    vim.cmd.edit(vim.fn.fnameescape(root .. '/' .. path))
    vim.api.nvim_win_set_cursor(0, { math.min(target, vim.api.nvim_buf_line_count(0)), 0 })
  end
  for _, lhs in ipairs { '<CR>', 'gf', 'gF' } do
    vim.keymap.set('n', lhs, open_change, { buffer = buf, desc = 'Go to change' })
  end
  vim.keymap.set('n', '<Tab>', 'za', { buffer = buf, desc = 'Toggle fold' })
  vim.keymap.set('n', 'q', close_view, { buffer = buf, desc = 'Close changes' })
end

return M
