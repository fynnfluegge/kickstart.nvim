local M = {}

-- Utility: simple centered floating window
local function open_centered_window(lines, title, height)
  local buf = vim.api.nvim_create_buf(false, true)
  local width = 60
  height = height or (#lines + 2)
  local ui = vim.api.nvim_list_uis()[1]

  local opts = {
    relative = 'editor',
    width = width,
    height = math.min(height, ui.height - 4),
    col = (ui.width - width) / 2,
    row = (ui.height - height) / 2,
    border = 'rounded',
    style = 'minimal',
    title = title or 'Popup',
  }

  local win = vim.api.nvim_open_win(buf, true, opts)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  return buf, win
end

-- Main function
function M.open_find_replace_popup()
  local buf = vim.api.nvim_create_buf(false, true)
  local width, height = 40, 5
  local ui = vim.api.nvim_list_uis()[1]
  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = (ui.width - width) / 2,
    row = (ui.height - height) / 2,
    border = 'rounded',
    style = 'minimal',
    title = ' Global Find & Replace ',
  }

  vim.api.nvim_open_win(buf, true, opts)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    'Find: ',
    'Replace: ',
    '',
    '(Press <Enter> to search, <Esc> to cancel)',
  })

  local data = { find = '', replace = '', step = 1 }
  vim.api.nvim_win_set_cursor(0, { 1, 7 }) -- Start after "Find: "

  local function close_popup()
    vim.api.nvim_win_close(0, true)
  end

  local function run_grep(find)
    local cmd = vim.fn.executable('rg') == 1
      and string.format('rg --no-heading --line-number "%s"', find)
      or string.format('grep -RIn "%s" .', find)
    return vim.fn.systemlist(cmd)
  end

  local function show_grep_results(results)
    if #results == 0 then
      open_centered_window({ 'No matches found.' }, 'Results', 3)
      return
    end

    local preview_buf, preview_win = open_centered_window(results, 'Affected Files', 20)
    vim.api.nvim_buf_set_option(preview_buf, 'modifiable', false)

    vim.keymap.set('n', '<Esc>', function()
      vim.api.nvim_win_close(preview_win, true)
    end, { buffer = preview_buf })

    vim.keymap.set('n', '<CR>', function()
      vim.api.nvim_win_close(preview_win, true)
      vim.cmd('args **/*')
      vim.cmd('argdo %s/' .. vim.fn.escape(data.find, '/') .. '/' .. vim.fn.escape(data.replace, '/') .. '/g | update')
      print("Replaced all occurrences of '" .. data.find .. "' with '" .. data.replace .. "'.")
    end, { buffer = preview_buf })
  end

  vim.keymap.set('i', '<CR>', function()
    if data.step == 1 then
      data.find = vim.api.nvim_get_current_line():sub(7)
      data.step = 2
      vim.api.nvim_win_set_cursor(0, { 2, 10 }) -- move to Replace line
    else
      data.replace = vim.api.nvim_get_current_line():sub(10)
      close_popup()
      local results = run_grep(data.find)
      show_grep_results(results)
    end
  end, { buffer = buf })

  vim.keymap.set('i', '<Esc>', close_popup, { buffer = buf })
end

vim.api.nvim_create_user_command('GlobalFindReplace', M.open_find_replace_popup, {})
return M
