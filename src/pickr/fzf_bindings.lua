-- Bounded fzf 0.74.3 compatibility. See tests/FZF_COMPATIBILITY.md for
-- source references, grammar decisions, and the supported action inventory.
local keymap = require("pickr.keymap")
local M = {}
M.actions = {}
for name in ([[ignore up down up-match down-match first top last best page-up page-down
half-page-up half-page-down offset-up offset-down offset-middle beginning-of-line
end-of-line backward-char forward-char backward-word forward-word backward-subword
forward-subword backward-delete-char delete-char clear-query kill-line kill-word
kill-subword backward-kill-word backward-kill-subword unix-line-discard line-discard
unix-word-rubout word-rubout yank preview-top preview-bottom preview-up preview-down
preview-page-up preview-page-down preview-half-page-up preview-half-page-down]]):gmatch("%S+") do
  M.actions[name] = true
end

-- go-shellwords with ParseComment=true, ParseEnv/ParseBacktick=false. This is
-- tokenization only: neither a shell nor environment expansion is involved.
function M.words(text)
  assert(not text:find("%z"), "NUL in fzf options")
  local words, buffer = {}, ""
  local single, double, backtick, dollar, escaped, comment, got = false, false, false, false, false, false, false
  local function flush()
    if got then words[#words + 1] = buffer end
    buffer, got = "", false
  end
  for i = 1, #text do
    local c = text:sub(i, i)
    if comment then
      if c == "\n" then comment = false end
    elseif escaped then
      buffer, escaped, got = buffer .. (c == "n" and "\n" or c == "t" and "\t" or c), false, true
    elseif c == "\\" then
      if single then buffer = buffer .. c else escaped = true end
    elseif c:find("[ \t\r\n]") then
      if single or double or backtick or dollar then buffer = buffer .. c else flush() end
    elseif c == "#" and buffer == "" and not single and not double then
      comment = true
    elseif c == '"' and not single and not dollar then
      if double then got = true end
      double = not double
    elseif c == "'" and not double and not dollar then
      if single then got = true end
      single = not single
    else
      if c == "`" and not single and not double and not dollar then backtick = not backtick end
      if not single and not double and not backtick then
        if c == "(" then
          assert(not dollar and buffer:sub(-1) == "$", "invalid unquoted parenthesis in fzf options")
          dollar = true
        elseif c == ")" then dollar = not dollar end
      end
      if c:find("[;&|<>]") and not single and not double and not backtick and not dollar then
        if c == ">" and buffer:match("^%d") then got = false end
        break
      end
      buffer, got = buffer .. c, true
    end
  end
  assert(not (single or double or backtick or dollar or escaped), "unterminated quoting or escape in fzf options")
  flush()
  return words
end

local argument_actions = {}
for name in ([[become execute execute-multi execute-silent reload reload-sync preview
bg-transform transform change-preview-window change-preview change-multi rebind unbind
toggle-bind pos put print search trigger]]):gmatch("%S+") do argument_actions[name] = true end
for _, prefix in ipairs({ "change", "bg-transform", "transform" }) do
  for suffix in ([[query prompt border-label list-label preview-label input-label header-label
footer-label header-lines header footer search with-nth nth pointer ghost]]):gmatch("%S+") do
    argument_actions[prefix .. "-" .. suffix] = true
  end
end
local closers = { ["("] = ")", ["{"] = "}", ["["] = "]", ["<"] = ">" }
for c in ("~!@#$%%^&*;/|"):gmatch(".") do closers[c] = c end

-- Preserve byte offsets while hiding argument contents. The fzf grammar ends
-- arguments at a delimiter followed by +, comma, or EOF (not balanced nesting).
local function mask(text)
  local parts, start, i = {}, 1, 1
  while i <= #text do
    local c = text:sub(i, i)
    if c == ":" or c == "+" then
      local name = text:sub(i + 1):match("^([%a-]+)")
      if name and argument_actions[name:lower()] then
        local first = i + 1 + #name
        local delimiter = text:sub(first, first)
        local last
        if delimiter == ":" then last = #text
        elseif closers[delimiter] then
          local pos = first + 1
          while pos <= #text do
            local found = text:find(closers[delimiter], pos, true)
            if not found then break end
            local next_char = text:sub(found + 1, found + 1)
            if next_char == "" or next_char == "+" or next_char == "," then last = found; break end
            pos = found + 1
          end
          assert(last, "unterminated action argument for " .. name)
        end
        if last then
          parts[#parts + 1] = text:sub(start, first - 1) .. string.rep(" ", last - first + 1)
          start, i = last + 1, last
        end
      end
    end
    i = i + 1
  end
  parts[#parts + 1] = text:sub(start)
  return table.concat(parts):gsub(",,,", ",\1,"):gsub(",:,", ",\0,")
    :gsub("::", "\0:"):gsub(",:", "\1:"):gsub("%+:", "\2:")
end

local function split(text, separator)
  local fields, start = {}, 1
  while true do
    local pos = text:find(separator, start, true)
    if not pos then fields[#fields + 1] = text:sub(start); return fields end
    fields[#fields + 1], start = text:sub(start, pos - 1), pos + 1
  end
end

function M.bind(state, text, source)
  local masked, pending, offset, result = mask(text), {}, 1, {}
  for key, value in pairs(state) do result[key] = value end
  for _, pair in ipairs(split(masked, ",")) do
    local original = text:sub(offset, offset + #pair - 1)
    offset = offset + #pair + 1
    local colon = pair:find(":", 1, true)
    local key = colon and pair:sub(1, colon - 1) or pair
    assert(key ~= "", "key name required")
    key = key:gsub("%z", ":"):gsub("\1", ","):gsub("\2", "+")
    pending[#pending + 1] = keymap.normalize(key) or key
    if colon then
      local actions, index = {}, colon + 1
      local append = pair:sub(colon + 1, colon + 1) == "+"
      for n, action in ipairs(split(pair:sub(colon + 1), "+")) do
        local raw = original:sub(index, index + #action - 1)
        index = index + #action + 1
        if not (append and n == 1) then
          assert(raw ~= "", "empty action in binding for " .. key)
          actions[#actions + 1] = raw:lower()
        end
      end
      for _, target in ipairs(pending) do
        local chain = {}
        if append and result[target] then
          for _, action in ipairs(result[target].actions) do chain[#chain + 1] = action end
        end
        for _, action in ipairs(actions) do chain[#chain + 1] = action end
        result[target] = { actions = chain, source = source }
      end
      pending = {}
    end
  end
  assert(#pending == 0, "bind action not specified: " .. table.concat(pending, ", "))
  return result
end

-- These unrelated options consume their next token even when it resembles a
-- --bind option. Do not accidentally import a preview/query/header argument.
local takes_value = {}
for name in ([[--query -q --filter -f --nth -n --with-nth --accept-nth --delimiter -d --scheme
--tiebreak --algo --border-label --border-label-pos --list-label --list-label-pos
--input-label --input-label-pos --header-label --header-label-pos --footer-label
--footer-label-pos --preview-label --preview-label-pos --prompt --info --info-command
--ghost --preview --preview-window --with-shell --header --header-lines --footer
--expect --history --history-size --margin --padding --height --min-height --tail
--freeze-left --freeze-right --scroll-off --hscroll-off --jump-labels --ellipsis
--tabstop --walker --walker-skip --tty-default --preview-wrap-sign --wrap-sign]]):gmatch("%S+") do takes_value[name] = true end

function M.parse(state, text, source, warn)
  local ok, words = pcall(M.words, text)
  if not ok then warn(source .. ": " .. tostring(words)); return state end
  local i = 1
  while i <= #words do
    local word, value = words[i], words[i]:match("^%-%-bind=(.*)$")
    if word == "--bind" then i = i + 1; value = words[i] end
    if word == "--bind" or value ~= nil then
      local parsed, updated = pcall(M.bind, state, value or "", source)
      if parsed then state = updated else warn(source .. ": " .. tostring(updated)) end
    elseif takes_value[word] then i = i + 1 end
    i = i + 1
  end
  return state
end

function M.load(deps)
  deps = deps or {}
  local getenv = deps.getenv or os.getenv
  local warn = deps.warn or function(message) io.stderr:write("Pickr fzf: " .. message .. "\n") end
  local read = deps.read_file or function(filename)
    local file, err = io.open(filename, "r")
    if not file then return nil, err end
    local text, read_error = file:read("*a")
    file:close()
    return text, read_error
  end
  local state, path = {}, getenv("FZF_DEFAULT_OPTS_FILE")
  if path and path ~= "" then
    local text, err = read(path)
    if text and not err then state = M.parse(state, text, path, warn)
    else warn(path .. ": " .. tostring(err or "cannot read fzf options file")) end
  end
  state = M.parse(state, getenv("FZF_DEFAULT_OPTS") or "", "FZF_DEFAULT_OPTS", warn)
  local keys, bindings = {}, {}
  for key in pairs(state) do keys[#keys + 1] = key end
  table.sort(keys)
  for _, key in ipairs(keys) do
    local binding, unsupported = state[key], nil
    for _, action in ipairs(binding.actions) do
      if not M.actions[action] then unsupported = action:match("^[%a/-]+") or action; break end
    end
    if not keymap.normalize(key) then unsupported = unsupported or table.concat(binding.actions, "+") end
    if unsupported then
      warn(binding.source .. ": excluded " .. key .. ": unsupported key/event or action " .. unsupported)
    else bindings[key] = table.concat(binding.actions, "+") end
  end
  return bindings
end

return M
