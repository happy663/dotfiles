-- Markdown helpers extracted from ixru/nvim-markdown
-- Only includes: toggle_checkbox, new_line_above, new_line_below, create_link
-- Original: https://github.com/ixru/nvim-markdown

local M = {}

local regex = {
  setex_line_header = "^%-%-%-%-*",
  setex_equals_header = "^====*",
  atx_header = "^#",
  unordered_list = "^%s*[%*%-%+]",
  ordered_list = "^%s*%d+[%)%.]",
}

-- to make M.backspace only trigger after a new line has been created
local should_run_callback = false
local function key_callback(key)
  local backspace_term = vim.api.nvim_replace_termcodes("<BS>", true, true, true)

  -- It sends some key on o and O "<80><fd>h", which is some special key I didn't ask for.
  if should_run_callback and key ~= "\x80\xfdh" then
    if key == backspace_term then
      M.backspace()
    end
    should_run_callback = false
  end
end

vim.on_key(key_callback)

-- Iterates up or down to find the first occurence of a section marker.
-- line_num is included in the search
local function find_header_or_list(line_num)
  local line_count = vim.api.nvim_buf_line_count(0)

  if line_num < 1 or line_num > line_count then
    return nil
  end

  local line = vim.fn.getline(line_num)
  local setex_line = vim.fn.getline(line_num + 1)
  if setex_line:match(regex.setex_equals_header) and not line:match("^$") then
    return { line = line_num, type = "setex_equals_header" }
  elseif setex_line:match(regex.setex_line_header) and not line:match("^$") then
    return { line = line_num, type = "setex_line_header" }
  end

  while line_num > 0 and line_num <= line_count do
    line = vim.fn.getline(line_num)
    for name, pattern in pairs(regex) do
      if line:match(pattern) then
        if name == "setex_equals_header" or name == "setex_line_header" then
          if vim.fn.getline(line_num - 1):match("^$") then
            break
          end
          line_num = line_num - 1
        end
        return { line = line_num, type = name }
      end
    end
    line_num = line_num - 1
  end
end

local function find_link_under_cursor()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.fn.getline(cursor[1])
  local column = cursor[2] + 1
  local link_start, link_stop, text, url
  local start = 1
  repeat
    link_start, link_stop, text, url = line:find("%[(.-)%]%((.-)%)", start)
    if link_start then
      start = link_stop + 1
    end
  until not link_start or (link_start <= column and link_stop >= column)

  if link_start then
    return {
      link = "[" .. text .. "](" .. url .. ")",
      start = link_start,
      stop = link_stop,
      text = text,
      url = url,
    }
  else
    return nil
  end
end

local function find_word_under_cursor()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local mode = vim.fn.mode(".")
  if mode:find("n") then
    cursor[2] = cursor[2] + 1
  end

  local line = vim.fn.getline(cursor[1])
  local word_start, word_stop, word
  local start = 1
  repeat
    word_start, word_stop, word = line:find("([^%s]+)", start)
    if word_start then
      start = word_stop + 1
    end
  until not word_start or (word_start <= cursor[2] and word_stop >= cursor[2])

  if word_start then
    return {
      start = word_start,
      stop = word_stop,
      text = word,
    }
  else
    return nil
  end
end

-- Given a the line of a bullet, returns a table of properties of the bullet.
local function parse_bullet(bullet_line)
  local line = vim.fn.getline(bullet_line)
  local bullet = {}

  bullet.indent, bullet.marker, bullet.trailing_indent, bullet.text = line:match("^(%s*)([%*%-%+])(%s+)(.*)")
  if not bullet.marker then
    bullet.indent, bullet.marker, bullet.delimiter, bullet.trailing_indent, bullet.text =
      line:match("^(%s*)(%d+)([%)%.])(%s+)(.*)")
    bullet.type = "ordered_list"
  else
    bullet.delimiter = ""
    bullet.type = "unordered_list"
  end

  if not bullet.marker then
    return nil
  end

  local checkbox = bullet.text:match("^%[([%sx])%]")
  if checkbox then
    bullet.checkbox = {}
    bullet.checkbox.checked = checkbox == "x" and true or false
    bullet.text = bullet.text:sub(5)
  end

  bullet.indent = #bullet.indent
  bullet.trailing_indent = #bullet.trailing_indent
  bullet.start = bullet_line

  local line_count = vim.api.nvim_buf_line_count(0)
  local iter = bullet.start + 1
  while true do
    local indent = vim.fn.indent(iter)

    if not bullet.has_children and indent >= bullet.indent + vim.o.shiftwidth then
      local child = vim.fn.getline(iter)
      if child:match(regex.unordered_list) or child:match(regex.ordered_list) then
        bullet.has_children = true
      end
    end

    if indent <= bullet.indent then
      bullet.stop = iter - 1
      break
    end

    if iter >= line_count then
      bullet.stop = line_count
      break
    end

    iter = iter + 1
  end

  if bullet.indent > 0 then
    local section = find_header_or_list(bullet.start - 1)
    while true do
      if not section or not section.type or not section.type:match("list") then
        break
      elseif vim.fn.indent(section.line) < bullet.indent then
        bullet.parent = parse_bullet(section.line)
        break
      else
        section = find_header_or_list(section.line - 1)
      end
    end
  end
  return bullet
end

-- Pressing backspace in insert mode calls this function.
function M.backspace()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local folded, line
  if vim.fn.foldclosed(cursor[1] - 1) ~= -1 then
    folded = true
    line = vim.fn.foldclosed(cursor[1] - 1)
  else
    line = cursor[1] - 1
  end

  local bullet = parse_bullet(line)
  if not bullet then
    return
  end

  local indent_length = bullet.indent + #bullet.marker + bullet.trailing_indent + #bullet.delimiter
  if bullet.checkbox then
    indent_length = indent_length + 4
  end

  local newline
  if folded then
    newline = string.rep(" ", indent_length - 2) .. "a"
  else
    newline = string.rep(" ", indent_length) .. "a"
  end

  vim.fn.setline(".", newline)
  vim.api.nvim_win_set_cursor(0, { cursor[1], 10000 })
end

-- Responsible for auto-inserting new bullet points
local function newline(insert_line, folded)
  local bullet_above, bullet_below

  if folded then
    bullet_above = parse_bullet(vim.fn.foldclosed(insert_line))
    bullet_below = parse_bullet(insert_line + 1)
  else
    bullet_above = parse_bullet(insert_line)
    bullet_below = parse_bullet(insert_line + 1)
  end

  if bullet_above then
    if #bullet_above.text == 0 then
      vim.cmd("startinsert")
      vim.api.nvim_buf_set_lines(0, insert_line - 1, insert_line, true, { "", "" })
      vim.api.nvim_win_set_cursor(0, { insert_line + 1, 0 })
      return
    end

    local bullet
    if bullet_below and bullet_below.indent > bullet_above.indent then
      bullet = bullet_below
    else
      bullet = bullet_above
    end

    local indent = string.rep(" ", bullet.indent)
    local marker = bullet.marker
    local delimiter = bullet.delimiter
    local trailing_indent = string.rep(" ", bullet.trailing_indent)

    local checkbox
    if bullet_above and bullet_below and bullet_above.indent == bullet_below.indent then
      checkbox = bullet_above.checkbox and "[ ] " or ""
    else
      checkbox = bullet.checkbox and "[ ] " or ""
    end

    if tonumber(marker) then
      marker = marker + 1
    end

    local new_line = indent .. marker .. delimiter .. trailing_indent .. checkbox
    vim.cmd("startinsert")
    vim.fn.append(insert_line, new_line)
    vim.api.nvim_win_set_cursor(0, { insert_line + 1, 1000000 })
    should_run_callback = true
  elseif folded then
    vim.cmd("startinsert")
    vim.fn.append(insert_line, "")
    vim.api.nvim_win_set_cursor(0, { insert_line + 1, 0 })
  else
    vim.cmd("startinsert")
    vim.fn.append(insert_line, "")
    vim.api.nvim_win_set_cursor(0, { insert_line + 1, 1000000 })
  end
end

function M.new_line_above()
  local insert_line = vim.fn.line(".")
  local folded

  if vim.fn.foldclosed(insert_line - 1) > 0 then
    insert_line = vim.fn.foldclosedend(insert_line - 1)
    folded = true
  else
    insert_line = insert_line - 1
  end

  newline(insert_line, folded)
end

function M.new_line_below()
  local insert_line = vim.fn.line(".")
  local folded

  local bullet = parse_bullet(insert_line)

  if vim.fn.mode() == "i" then
    local column = vim.api.nvim_win_get_cursor(0)[2] + 1
    local line = vim.api.nvim_get_current_line()

    if column < #line or not bullet then
      local key = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
      vim.api.nvim_feedkeys(key, "n", true)
      return
    end
  else
    if vim.fn.foldclosed(".") > 0 then
      insert_line = vim.fn.foldclosedend(".")
      folded = true
    elseif not bullet then
      vim.api.nvim_feedkeys("o", "n", true)
      return
    end
  end

  newline(insert_line, folded)
end

-- Takes the word under the cursor and puts it in the appropriate spot in a link.
function M.create_link()
  local line = vim.fn.getline(".")
  local cursor = vim.api.nvim_win_get_cursor(0)
  local mode = vim.fn.mode(".")

  local new_line, new_cursor_pos
  if mode == "i" or mode == "ic" or mode == "n" then
    local word = find_word_under_cursor()
    if word and (word.text:match("/") or vim.fn.filereadable(word.text) == 1) then
      new_line = line:sub(1, word.start - 1) .. "[]"
      new_cursor_pos = #new_line
      new_line = new_line .. "(" .. word.text .. ")" .. line:sub(word.stop + 1)
    elseif word then
      new_line = line:sub(1, word.start - 1) .. "[" .. word.text .. "]()"
      new_cursor_pos = #new_line
      new_line = new_line .. line:sub(word.stop + 1)
    else
      new_line = line:sub(1, cursor[2]) .. "[]"
      new_cursor_pos = #new_line
      new_line = new_line .. "()" .. line:sub(cursor[2] + 1)
    end
  elseif mode == "v" or mode == "\22" then
    vim.cmd(":normal! ")
    local start = vim.fn.getpos("'<")
    local stop = vim.fn.getpos("'>")

    if start[2] ~= stop[2] then
      return
    else
      start = start[3]
      stop = stop[3]
    end

    local selection = line:sub(start, stop)
    if selection:match("/") or vim.fn.filereadable(selection) == 1 then
      new_line = line:sub(1, start - 1) .. "[]"
      new_cursor_pos = #new_line
      new_line = new_line .. "(" .. selection .. ")" .. line:sub(stop + 1)
    else
      new_line = line:sub(1, start - 1) .. "[" .. selection .. "]()"
      new_cursor_pos = #new_line
      new_line = new_line .. line:sub(stop + 1)
    end
  else
    return
  end

  vim.fn.setline(".", new_line)
  vim.fn.setpos(".", { 0, cursor[1], new_cursor_pos, 0 })
  vim.cmd("startinsert")
end

-- Pressing C-c calls this function
-- Iterates through todo list for all list types
function M.toggle_checkbox()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()
  local bullet = parse_bullet(cursor[1])

  if not bullet then
    return
  end

  -- Fill checkbox
  if bullet.checkbox and not bullet.checkbox.checked then
    if #bullet.text == 0 then
      line = line:gsub("%[%s%]", "[x]")
      bullet.checkbox.checked = true
    else
      line = line:gsub("%[%s]", "[x]")
      vim.api.nvim_buf_set_lines(0, cursor[1] - 1, cursor[1], 1, { line })
      return
    end
  end

  -- Return to normal list item
  if bullet.checkbox and bullet.checkbox.checked then
    line = line:gsub("%s%[x%]", "")
    vim.api.nvim_buf_set_lines(0, cursor[1] - 1, cursor[1], 1, { line })

    local checkbox = bullet.checkbox and 4 or 0
    local text_start = bullet.indent + #bullet.marker + #bullet.delimiter + checkbox
    if cursor[2] + 1 > text_start then
      vim.api.nvim_win_set_cursor(0, { cursor[1], cursor[2] - 4 })
    end
    return
  end

  -- Convert list item to checkbox
  if not bullet.checkbox then
    local trailing_indent = string.rep(" ", bullet.trailing_indent)
    if #bullet.text == 0 and bullet.trailing_indent == 0 then
      trailing_indent = " "
    end

    line = string.rep(" ", bullet.indent)
      .. bullet.marker
      .. bullet.delimiter
      .. " [ ]"
      .. trailing_indent
      .. bullet.text
    vim.api.nvim_buf_set_lines(0, cursor[1] - 1, cursor[1], 1, { line })

    local text_start = bullet.indent + #bullet.marker + #bullet.delimiter
    if cursor[2] + 1 == text_start + 1 then
      vim.api.nvim_win_set_cursor(0, { cursor[1], cursor[2] + 5 })
    elseif cursor[2] + 1 > text_start then
      vim.api.nvim_win_set_cursor(0, { cursor[1], cursor[2] + 4 })
    end
    return
  end
end

local function get_clipboard_lines()
  local clipboard_content = vim.fn.getreg("+")
  local code_lines = vim.split(clipboard_content, "\n", { plain = true })

  if code_lines[#code_lines] == "" then
    table.remove(code_lines, #code_lines)
  end

  return code_lines
end

function M.paste_as_code_block()
  local code_lines = get_clipboard_lines()

  if code_lines[#code_lines] == "" then
    table.remove(code_lines, #code_lines)
  end

  table.insert(code_lines, 1, "```")
  table.insert(code_lines, "```")

  vim.api.nvim_put(code_lines, "l", true, false)
  vim.cmd("normal! k")
end

function M.paste_as_details()
  local code_lines = get_clipboard_lines()
  local summary = vim.fn.input("Summary: ") or "詳細"
  if summary == nil or summary == "" then
    summary = "詳細"
  end

  local result = {
    "<details>",
    "<summary>" .. summary .. "</summary>",
    "",
  }
  vim.list_extend(result, code_lines)
  table.insert(result, "</details>")

  vim.api.nvim_put(result, "l", true, false)
  vim.cmd("normal! k")
end

function M.paste_as_details_with_code_block()
  local code_lines = get_clipboard_lines()
  local summary = vim.fn.input("Summary: ") or "詳細"
  if summary == nil or summary == "" then
    summary = "詳細"
  end

  local result = {
    "<details>",
    "<summary>" .. summary .. "</summary>",
    "", -- 空行
    "```",
  }

  vim.list_extend(result, code_lines)
  table.insert(result, "```")
  table.insert(result, "</details>")

  vim.api.nvim_put(result, "l", true, false)
end

-- Setup keymaps for markdown/octo buffers
function M.setup_keymaps()
  vim.keymap.set("n", "<C-c>", M.toggle_checkbox, {
    buffer = true,
    silent = true,
    desc = "Markdown: Toggle checkbox",
  })

  vim.keymap.set("n", "O", M.new_line_above, {
    buffer = true,
    silent = true,
    desc = "Markdown: New line above",
  })

  vim.keymap.set("n", "o", M.new_line_below, {
    buffer = true,
    silent = true,
    desc = "Markdown: New line below",
  })

  vim.keymap.set("i", "<C-k>", M.create_link, {
    buffer = true,
    silent = true,
    desc = "Markdown: Create link",
  })

  vim.keymap.set("n", "<leader>py", M.paste_as_code_block, {
    buffer = true,
    silent = true,
    desc = "Markdown: Paste as code block",
  })
  vim.keymap.set("n", "<leader>pd", M.paste_as_details, {
    buffer = true,
    silent = true,
    desc = "Markdown: Paste as details",
  })
  vim.keymap.set("n", "<leader>ps", M.paste_as_details, {
    buffer = true,
    silent = true,
    desc = "Markdown: Paste as details with code block",
  })
end

return M
