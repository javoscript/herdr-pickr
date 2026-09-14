local M = {}
local pickers = require("pickr.pickers")
M.order = { "accept", "close", "toggle_preview", "refresh", "spaces", "tabs", "panes", "agents",
  "scope_all", "scope_space", "scope_tab" }
M.defaults = { accept = { "enter" }, close = { "esc" }, toggle_preview = { "ctrl-p" },
  refresh = { "ctrl-l" }, spaces = { "ctrl-s" }, tabs = { "ctrl-t" }, panes = { "ctrl-r" },
  agents = { "ctrl-a" }, scope_all = { "ctrl-z" }, scope_space = { "ctrl-x" }, scope_tab = { "ctrl-c" } }
M.variants = pickers.types

-- fzf 0.74.3 parseKeyChords and Unix tui event aliases.
local aliases = { ["return"] = "enter", ["ctrl-m"] = "enter", ["ctrl-i"] = "tab",
  ["ctrl-h"] = "ctrl-backspace", bs = "backspace", bspace = "backspace",
  ["ctrl-bs"] = "ctrl-backspace", ["ctrl-bspace"] = "ctrl-backspace",
  ["alt-bs"] = "alt-backspace", ["alt-bspace"] = "alt-backspace",
  ["ctrl-alt-bs"] = "ctrl-alt-backspace", ["ctrl-alt-bspace"] = "ctrl-alt-backspace",
  ["ctrl-alt-h"] = "ctrl-alt-backspace", ["alt-return"] = "alt-enter", ["ctrl-alt-m"] = "alt-enter",
  btab = "shift-tab", del = "delete", pgup = "page-up", pgdn = "page-down",
  ["ctrl-6"] = "ctrl-^", ["ctrl-_"] = "ctrl-/", [" "] = "space" }
local named = {}
for word in ("up down left right enter space backspace ctrl-space ctrl-^ ctrl-/ ctrl-\\ ctrl-] tab shift-tab esc delete home end insert page-up page-down alt-enter alt-space alt-backspace ctrl-backspace ctrl-alt-backspace left-click right-click shift-left-click shift-right-click double-click scroll-up scroll-down shift-scroll-up shift-scroll-down preview-scroll-up preview-scroll-down"):gmatch("%S+") do named[word] = true end
for _, modifier in ipairs({ "alt", "ctrl", "shift", "alt-shift", "ctrl-alt", "ctrl-shift", "ctrl-alt-shift" }) do
  for _, key in ipairs({ "up", "down", "left", "right", "home", "end", "delete", "page-up", "page-down" }) do
    named[modifier .. "-" .. key] = true
    if modifier == "alt-shift" then aliases["shift-alt-" .. key] = modifier .. "-" .. key end
    if modifier == "ctrl-alt" then aliases["alt-ctrl-" .. key] = modifier .. "-" .. key end
    if modifier == "ctrl-shift" then aliases["shift-ctrl-" .. key] = modifier .. "-" .. key end
  end
end
for i = 1, 12 do named["f" .. i] = true end

function M.normalize(key)
  if type(key) ~= "string" or key == "" or key:find("[%z\1-\31\127]") then return nil end
  local length = utf8.len(key)
  if not length then return nil end
  if length == 1 then return aliases[key] or key end -- printable keys are case-sensitive
  local lower = key:lower()
  lower = aliases[lower] or lower
  if named[lower] or lower:match("^ctrl%-%l$") or lower:match("^ctrl%-alt%-%l$") then return lower end
  if lower:sub(1, 4) == "alt-" and length == 5 then return "alt-" .. key:sub(5) end
end

function M.resolve(overrides)
  overrides = overrides or {}
  for action in pairs(overrides) do
    pickers.check_leaf("keys", action)
    if not M.defaults[action] then error("keys." .. tostring(action) .. ": unknown action", 0) end
  end
  local result = { keys = {}, reverse = {} }
  for _, action in ipairs(M.order) do
    local keys = overrides[action] or M.defaults[action]
    if type(keys) ~= "table" then error("keys." .. action .. ": expected an array", 0) end
    if (action == "accept" or action == "close") and #keys == 0 then
      error("keys." .. action .. ": requires at least one key", 0)
    end
    result.keys[action] = {}
    for index, key in ipairs(keys) do
      local normalized = M.normalize(key)
      if not normalized then error("keys." .. action .. "[" .. index .. "]: unsupported key " .. tostring(key), 0) end
      if result.reverse[normalized] then
        error("keys." .. action .. ": key " .. key .. " conflicts with keys." .. result.reverse[normalized], 0)
      end
      result.reverse[normalized] = action
      result.keys[action][#result.keys[action] + 1] = normalized
    end
  end
  return result
end

function M.display(keys)
  local labels = {}
  for _, key in ipairs(keys) do labels[#labels + 1] = key:gsub("%-", "+") end
  return table.concat(labels, "/")
end

function M.expect(map, kind, chosen)
  local keys = {}
  for _, action in ipairs(M.order) do
    local scope = action:match("^scope_(.+)$")
    if M.variants[action] or (scope and kind and pickers.types[kind][scope]
      and scope ~= pickers.effective(kind, chosen)) then
      for _, key in ipairs(map.keys[action]) do keys[#keys + 1] = key end
    end
  end
  return keys
end

function M.gate(map, operation, actions)
  local bindings = {}
  for _, action in ipairs(actions) do
    for _, key in ipairs(map.keys[action]) do bindings[#bindings + 1] = operation .. "(" .. key .. ")" end
  end
  return table.concat(bindings, "+")
end

function M.header(settings, kind, chosen, status)
  local themes = require("pickr.themes")
  local labels = { all = "All spaces", space = "This space", tab = "This tab" }
  local effective, parts = pickers.effective(kind, chosen), {}
  for _, scope in ipairs(pickers.scopes) do
    local text, keys = labels[scope], settings.keymap.keys["scope_" .. scope]
    if settings.popup.show_hints and #keys > 0 then text = text .. " (" .. M.display(keys) .. ")" end
    local style = themes.ansi(settings.roles.header)
    if not pickers.types[kind][scope] then style = themes.ansi(settings.roles.annotation) .. "\27[2m"
    elseif effective == scope then style = themes.ansi(settings.roles.prompt) .. "\27[1m" end
    parts[#parts + 1] = style .. text .. "\27[0m"
  end
  local lines = { table.concat(parts, " · ") }
  if chosen ~= effective then
    lines[#lines + 1] = themes.ansi(settings.roles.annotation) .. labels[chosen] .. " remembered\27[0m"
  end
  if status then lines[#lines + 1] = status end
  return table.concat(lines, "\n")
end

function M.footer(map, count)
  local labels = { accept = "switch", close = "close", toggle_preview = "preview", refresh = "refresh",
    spaces = "spaces", tabs = "tabs", panes = "panes", agents = "agents" }
  local groups = {
    { "accept", "close", "toggle_preview", "refresh" },
    pickers.order,
  }
  local lines = {}
  for index, actions in ipairs(groups) do
    local hints = index == 1 and count == 0 and { "no entries" } or {}
    for _, action in ipairs(actions) do
      local keys = map.keys[action]
      if #keys > 0 then hints[#hints + 1] = M.display(keys) .. ": " .. labels[action] end
    end
    if #hints > 0 then lines[#lines + 1] = table.concat(hints, " · ") end
  end
  return table.concat(lines, "\n")
end

return M
