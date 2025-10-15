local M = {}

-- Configuration
local config = {
  case_sensitive = false,
  regex_mode = false,
  exclude_patterns = { '*.git/*', '*.node_modules/*', '*.log' },
  max_preview_lines = 50,
}


-- Utility: validate search pattern
local function validate_pattern(pattern)
  if not pattern or pattern == '' then
    return false, 'Search pattern cannot be empty'
  end

  -- Test if pattern is valid regex when in regex mode
  if config.regex_mode then
    local ok, err = pcall(vim.regex, pattern)
    if not ok then
      return false, 'Invalid regex pattern: ' .. tostring(err)
    end
  end

  return true, nil
end

-- Utility: escape pattern for different contexts
local function escape_pattern(pattern, context)
  if context == 'grep' then
    -- Escape for shell command
    return vim.fn.shellescape(pattern)
  elseif context == 'vim_substitute' then
    -- Escape for vim substitute command
    if config.regex_mode then
      return pattern
    else
      -- Escape special vim regex characters for literal search
      local escaped = pattern:gsub('[.*^$\\[\\]~]', '\\%0')
      return escaped
    end
  end
  return pattern
end

-- Internal function to run grep/ripgrep search
local function run_grep(find)
  local valid, err = validate_pattern(find)
  if not valid then
    vim.notify('Error: ' .. err, vim.log.levels.ERROR)
    return {}
  end

  local results

  if vim.fn.executable('rg') == 1 then
    -- Use ripgrep with proper argument handling
    local rg_args = {
      'rg',
      '--no-heading',
      '--line-number',
      '--color=never'
    }

    if not config.case_sensitive then
      table.insert(rg_args, '--ignore-case')
    end

    if not config.regex_mode then
      table.insert(rg_args, '--fixed-strings')
    end

    -- Add exclude patterns for ripgrep
    for _, pattern in ipairs(config.exclude_patterns) do
      table.insert(rg_args, '--glob')
      table.insert(rg_args, '!' .. pattern)
    end

    -- Add the search pattern directly (no shell escaping needed for vim.system)
    table.insert(rg_args, find)
    table.insert(rg_args, '.')

    -- Use vim.system (Neovim 0.10+) or fallback to systemlist with proper escaping
    if vim.system then
      -- Debug: show the actual command being run
      vim.notify('Debug: Running rg with args: ' .. vim.inspect(rg_args), vim.log.levels.INFO)

      local result = vim.system(rg_args, { text = true }):wait()
      results = result.stdout and vim.split(result.stdout, '\n') or {}

      -- Remove empty lines
      local filtered_results = {}
      for _, line in ipairs(results) do
        if line ~= '' then
          table.insert(filtered_results, line)
        end
      end
      results = filtered_results
    else
      -- Fallback for older Neovim versions - need shell escaping here
      local escaped_find = escape_pattern(find, 'grep')
      local cmd = 'rg --no-heading --line-number --color=never'

      if not config.case_sensitive then
        cmd = cmd .. ' --ignore-case'
      end

      if not config.regex_mode then
        cmd = cmd .. ' --fixed-strings'
      end

      -- Skip glob patterns for now to avoid shell issues
      cmd = cmd .. ' ' .. escaped_find .. ' .'

      vim.notify('Debug: Running command: ' .. cmd, vim.log.levels.INFO)
      results = vim.fn.systemlist(cmd)
    end
  else
    -- Use regular grep - build command differently
    local escaped_find = escape_pattern(find, 'grep')
    local grep_cmd = 'grep -RIn'

    if not config.case_sensitive then
      grep_cmd = grep_cmd .. 'i'
    end

    if not config.regex_mode then
      grep_cmd = grep_cmd .. ' -F'
    end

    local cmd = string.format('%s %s . 2>/dev/null', grep_cmd, escaped_find)

    -- Debug: show the actual command being run
    vim.notify('Debug: Running command: ' .. cmd, vim.log.levels.INFO)

    results = vim.fn.systemlist(cmd)
  end

  -- Filter out excluded patterns for grep (rg handles this natively)
  if vim.fn.executable('rg') ~= 1 then
    local filtered = {}
    for _, line in ipairs(results) do
      local should_include = true
      local file_path = line:match('^([^:]+):')

      if file_path then
        for _, pattern in ipairs(config.exclude_patterns) do
          local glob_pattern = pattern:gsub('%*', '.*'):gsub('?', '.')
          if file_path:match(glob_pattern) then
            should_include = false
            break
          end
        end
      end

      if should_include then
        table.insert(filtered, line)
      end
    end
    results = filtered
  end

  return results
end

-- Internal function to execute find and replace directly
local function execute_replacement(results, find_text, replace_text)
  if #results == 0 then
    vim.notify('❌ No matches found for: ' .. find_text, vim.log.levels.WARN)
    return
  end

  -- Debug: show first few grep results
  vim.notify('Debug: First few grep results:', vim.log.levels.INFO)
  for i = 1, math.min(3, #results) do
    vim.notify('  ' .. results[i], vim.log.levels.INFO)
  end

  -- Parse results to get unique file list - be more careful with parsing
  local file_set = {}
  local match_count = 0

  for _, line in ipairs(results) do
    -- Handle both rg and grep output formats
    local file = line:match('^([^:]+):')
    if file and file ~= '' then
      -- Clean up the file path
      file = file:gsub('^%s+', ''):gsub('%s+$', '') -- trim whitspace

      -- Skip if it looks like a shell command or invalid path
      if not file:match('^[a-zA-Z]') and not file:match('^[/.~]') then
        vim.notify('Skipping invalid file path: ' .. file, vim.log.levels.WARN)
      else
        file_set[file] = true
        match_count = match_count + 1
      end
    end
  end

  local file_list = {}
  for file, _ in pairs(file_set) do
    -- Verify file exists before adding to list
    if vim.fn.filereadable(file) == 1 then
      table.insert(file_list, file)
    else
      vim.notify('File not readable: ' .. file, vim.log.levels.WARN)
    end
  end
  table.sort(file_list)

  local file_count = #file_list

  if file_count == 0 then
    vim.notify('❌ No readable files found with matches', vim.log.levels.ERROR)
    return
  end

  -- Show what we found
  vim.notify(string.format('🔍 Found %d matches in %d files - processing...', match_count, file_count), vim.log.levels.INFO)

  -- Perform the replacement
  local files_changed = 0
  local errors = {}

  for i, file in ipairs(file_list) do
    local success, err = pcall(function()
      if vim.fn.filereadable(file) ~= 1 then
        table.insert(errors, file .. ': File not readable')
        return
      end

      -- Read file content directly
      local lines = vim.fn.readfile(file)
      if not lines then
        table.insert(errors, file .. ': Could not read file')
        return
      end

      local modified = false
      local new_lines = {}

      -- Process each line
      for _, line in ipairs(lines) do
        local new_line = line
        local original_line = line

        if config.regex_mode then
          -- Use regex replacement
          if config.case_sensitive then
            new_line = line:gsub(find_text, replace_text)
          else
            -- For case-insensitive regex, we need a different approach
            -- Create a case-insensitive pattern manually
            local ci_pattern = ''
            for i = 1, #find_text do
              local char = find_text:sub(i, i)
              if char:match('%a') then
                ci_pattern = ci_pattern .. '[' .. char:lower() .. char:upper() .. ']'
              else
                ci_pattern = ci_pattern .. vim.pesc(char)
              end
            end
            new_line = line:gsub(ci_pattern, replace_text)
          end
        else
          -- Literal replacement
          if config.case_sensitive then
            new_line = line:gsub(vim.pesc(find_text), replace_text)
          else
            -- Case-insensitive literal replacement - simpler approach
            new_line = line
            local start_pos = 1

            while true do
              local lower_line = new_line:lower()
              local lower_find = find_text:lower()
              -- Use plain text search (no patterns) - don't need vim.pesc here
              local pos = lower_line:find(lower_find, start_pos, true)

              if not pos then break end

              local before = new_line:sub(1, pos - 1)
              local after = new_line:sub(pos + #find_text)
              new_line = before .. replace_text .. after
              start_pos = pos + #replace_text
            end
          end
        end

        if new_line ~= original_line then
          modified = true
        end
        table.insert(new_lines, new_line)
      end

      -- Write file if modified
      if modified then
        local write_success = vim.fn.writefile(new_lines, file)
        if write_success == 0 then
          files_changed = files_changed + 1
        else
          table.insert(errors, file .. ': Could not write file')
        end
      end
    end)

    if not success then
      table.insert(errors, file .. ': ' .. tostring(err))
    end
  end

  -- Report results
  if #errors > 0 then
    vim.notify('⚠️  Errors in some files:', vim.log.levels.WARN)
    for _, error_msg in ipairs(errors) do
      vim.notify('   ' .. error_msg, vim.log.levels.WARN)
    end
  end

  if files_changed > 0 then
    vim.notify(string.format('✅ Replaced "%s" → "%s" in %d files', find_text, replace_text, files_changed), vim.log.levels.INFO)

    -- Show file list if not too many
    if files_changed <= 8 then
      local changed_files = {}
      for _, file in ipairs(file_list) do
        table.insert(changed_files, vim.fn.fnamemodify(file, ':t'))
      end
      vim.notify('📝 ' .. table.concat(changed_files, ', '), vim.log.levels.INFO)
    end
  else
    vim.notify('⚠️  No files were modified', vim.log.levels.WARN)
  end
end

-- Main function using vim's command line for input
function M.open_find_replace_popup()
  -- Show current configuration
  local case_indicator = config.case_sensitive and '[Case-sensitive]' or '[Ignore-case]'
  local regex_indicator = config.regex_mode and '[Regex]' or '[Literal]'
  vim.notify(string.format('🔍 Find & Replace Mode: %s %s', case_indicator, regex_indicator), vim.log.levels.INFO)

  -- Use vim.ui.input for search term
  vim.ui.input({
    prompt = '🔍 Find: ',
    default = '',
  }, function(find_text)
    if not find_text or find_text == '' then
      vim.notify('❌ Search cancelled', vim.log.levels.WARN)
      return
    end

    -- Validate the search pattern
    local valid, err = validate_pattern(find_text)
    if not valid then
      vim.notify('❌ ' .. err, vim.log.levels.ERROR)
      return
    end

    -- Use vim.ui.input for replacement term
    vim.ui.input({
      prompt = '🔄 Replace with: ',
      default = '',
    }, function(replace_text)
      if replace_text == nil then -- User cancelled
        vim.notify('❌ Replace cancelled', vim.log.levels.WARN)
        return
      end

      -- replace_text can be empty string for deletion
      M.execute_find_replace(find_text, replace_text)
    end)
  end)
end

-- Separate function to execute the find and replace
function M.execute_find_replace(find_text, replace_text)
  vim.notify('🔍 Searching for matches...', vim.log.levels.INFO)

  -- Debug: Show search configuration
  vim.notify(string.format('Debug: Searching for "%s" (case: %s, regex: %s)',
    find_text,
    config.case_sensitive and 'sensitive' or 'ignore',
    config.regex_mode and 'on' or 'off'), vim.log.levels.INFO)

  local results = run_grep(find_text)

  -- Debug: Show total results count
  vim.notify(string.format('Debug: Grep returned %d lines', #results), vim.log.levels.INFO)

  execute_replacement(results, find_text, replace_text)
end

-- Toggle configuration options
function M.toggle_case_sensitive()
  config.case_sensitive = not config.case_sensitive
  vim.notify((config.case_sensitive and '🔤 Case sensitive ON' or '🔤 Case sensitive OFF'), vim.log.levels.INFO)
end

function M.toggle_regex_mode()
  config.regex_mode = not config.regex_mode
  vim.notify((config.regex_mode and '📝 Regex mode ON' or '📝 Literal mode ON'), vim.log.levels.INFO)
end

-- Configuration function
function M.setup(opts)
  opts = opts or {}
  config.case_sensitive = opts.case_sensitive or config.case_sensitive
  config.regex_mode = opts.regex_mode or config.regex_mode
  config.exclude_patterns = opts.exclude_patterns or config.exclude_patterns
  config.max_preview_lines = opts.max_preview_lines or config.max_preview_lines
end

-- Export config for external access
function M.get_config()
  return vim.deepcopy(config)
end

function M.set_config(new_config)
  config = vim.tbl_deep_extend('force', config, new_config)
end

-- Commands
vim.api.nvim_create_user_command('GlobalFindReplace', function(opts)
  -- Parse arguments for direct find/replace
  local args = vim.split(opts.args, '%s+')
  if #args >= 2 then
    local find_text = args[1]
    local replace_text = args[2]
    M.execute_find_replace(find_text, replace_text)
  else
    M.open_find_replace_popup()
  end
end, {
  desc = 'Global find and replace. Usage: :GlobalFindReplace [find_text] [replace_text]',
  nargs = '*',
})

vim.api.nvim_create_user_command('GFR', function(opts)
  local args = vim.split(opts.args, '%s+')
  if #args >= 2 then
    local find_text = args[1]
    local replace_text = args[2]
    M.execute_find_replace(find_text, replace_text)
  else
    M.open_find_replace_popup()
  end
end, {
  desc = 'Short alias for GlobalFindReplace',
  nargs = '*',
})

-- Configuration commands
vim.api.nvim_create_user_command('GFRToggleCase', M.toggle_case_sensitive, {
  desc = 'Toggle case sensitivity for global find and replace'
})

vim.api.nvim_create_user_command('GFRToggleRegex', M.toggle_regex_mode, {
  desc = 'Toggle regex mode for global find and replace'
})

vim.api.nvim_create_user_command('GFRStatus', function()
  local case_status = config.case_sensitive and 'Case-sensitive' or 'Ignore-case'
  local regex_status = config.regex_mode and 'Regex' or 'Literal'
  local excludes = table.concat(config.exclude_patterns, ', ')

  vim.notify(string.format([[
🔍 Global Find & Replace Status:
  Mode: %s, %s
  Max preview lines: %d
  Excluded patterns: %s
  ]], case_status, regex_status, config.max_preview_lines, excludes), vim.log.levels.INFO)
end, {
  desc = 'Show current global find and replace configuration'
})

return M
