local palettes = require("pickr.palettes")
local M = {}

M.roles = {
  "background", "foreground", "selected_background", "selected_foreground",
  "match", "selected_match", "info", "marker", "prompt", "spinner", "pointer",
  "header", "footer", "border", "label", "preview_background", "preview_foreground",
  "preview_border", "annotation", "status_blocked", "status_done", "status_working",
  "status_idle", "status_unknown",
}
M.names = {}
for name in pairs(palettes) do M.names[#M.names + 1] = name end
table.sort(M.names)

-- Ratatui's Gray is ANSI 7, White is 15, and DarkGray is 8.
local ansi = { black = 0, red = 1, green = 2, yellow = 3, blue = 4,
  magenta = 5, purple = 5, cyan = 6, gray = 7, grey = 7, darkgray = 8,
  darkgrey = 8, lightred = 9, lightgreen = 10, lightyellow = 11,
  lightblue = 12, lightmagenta = 13, lightcyan = 14, white = 15 }

function M.color(value, field)
  if type(value) ~= "string" then error((field or "color") .. ": expected a color string", 0) end
  local text = value:match("^%s*(.-)%s*$"):lower()
  if text == "default" or text == "reset" or text == "none" or text == "transparent" then
    return { kind = "default" }
  end
  if ansi[text] then return { kind = "ansi", index = ansi[text] } end
  local hex = text:match("^#(%x%x%x)$")
  if hex then text = "#" .. hex:gsub(".", "%0%0") end
  hex = text:match("^#(%x%x%x%x%x%x)$")
  if hex then
    return { kind = "rgb", r = tonumber(hex:sub(1, 2), 16),
      g = tonumber(hex:sub(3, 4), 16), b = tonumber(hex:sub(5, 6), 16) }
  end
  local r, g, b = text:match("^rgb%(%s*(%+?%d+)%s*,%s*(%+?%d+)%s*,%s*(%+?%d+)%s*%)$")
  r, g, b = tonumber(r), tonumber(g), tonumber(b)
  if r and g and b and r <= 255 and g <= 255 and b <= 255 then
    return { kind = "rgb", r = r, g = g, b = b }
  end
  error((field or "color") .. ": invalid color " .. value, 0)
end

function M.fzf(color)
  if color.kind == "default" then return "-1" end
  if color.kind == "ansi" then return tostring(color.index) end
  return string.format("#%02x%02x%02x", color.r, color.g, color.b)
end

function M.ansi(color, background)
  if color.kind == "default" then return background and "\27[49m" or "\27[39m" end
  local prefix = background and "48" or "38"
  if color.kind == "ansi" then return "\27[" .. prefix .. ";5;" .. color.index .. "m" end
  return "\27[" .. prefix .. ";2;" .. color.r .. ";" .. color.g .. ";" .. color.b .. "m"
end

function M.resolve(name, custom)
  name = name or "catppuccin"
  local p = palettes[name]
  if not p then error("theme.name: unknown theme " .. tostring(name), 0) end
  local values = {
    background = p[1], foreground = p[3], selected_background = p[2], selected_foreground = p[3],
    match = p[7], selected_match = p[7], info = p[7], marker = p[8], prompt = p[7],
    spinner = p[10], pointer = p[8], header = p[4], footer = p[4], border = p[6], label = p[3],
    preview_background = p[1], preview_foreground = p[3], preview_border = p[6], annotation = p[5],
    status_blocked = p[8], status_done = p[11], status_working = p[10], status_idle = p[9], status_unknown = p[5],
  }
  if name == "rose-pine" then
    values.foreground, values.selected_background = "#908caa", "#26233a"
    values.match, values.selected_match = "#ebbcba", "#ebbcba"
    values.header, values.footer = "#6e6a86", "#6e6a86"
    values.border, values.preview_border, values.annotation = "#403d52", "#403d52", "#524f67"
  end
  local roles = {}
  for role, value in pairs(values) do roles[role] = M.color(value) end
  for role, value in pairs(custom or {}) do
    if not roles[role] then error("theme.custom." .. role .. ": unknown role", 0) end
    roles[role] = M.color(value, "theme.custom." .. role)
  end
  return roles
end

local fzf_roles = { background = "bg", foreground = "fg", selected_background = "bg+",
  selected_foreground = "fg+", match = "hl", selected_match = "hl+", info = "info", marker = "marker",
  prompt = "prompt", spinner = "spinner", pointer = "pointer", header = "header", footer = "footer",
  border = "border", label = "label", preview_background = "preview-bg",
  preview_foreground = "preview-fg", preview_border = "preview-border" }
function M.options(roles)
  local values = {}
  for _, role in ipairs(M.roles) do
    if fzf_roles[role] then values[#values + 1] = fzf_roles[role] .. ":" .. M.fzf(roles[role]) end
  end
  return "--color=" .. table.concat(values, ",")
end

return M
