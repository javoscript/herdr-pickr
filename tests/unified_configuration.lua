local config, json = require("pickr.config"), require("pickr.vendor.json")
local pickers, columns = require("pickr.pickers"), require("pickr.columns")
local keymap = require("pickr.keymap")
local function fails(text, field, replacement)
  local ok, err = pcall(config.decode, text)
  assert(not ok and err:find(field, 1, true), tostring(err))
  if replacement then assert(err:find(replacement, 1, true), err) end
end
for old, replacement in pairs(pickers.legacy) do
  for _, container in ipairs({ "keys", "columns", "prompt.variants" }) do
    for _, value in ipairs({ "null", "[]", '"old"' }) do
      for _, mixed in ipairs({ false, true }) do
        local leaves = '"' .. old .. '":' .. value .. (mixed and ',"' .. replacement .. '":null' or "")
        local text = container == "prompt.variants" and '{"prompt":{"variants":{' .. leaves .. '}}}'
          or '{"' .. container .. '":{' .. leaves .. '}}'
        fails(text, container .. "." .. old, container .. "." .. replacement)
      end
    end
  end
end
local defaults = {
  spaces = "status,space,tabs,directory", tabs = "status,space,tab,panes,directory",
  panes = "status,space,tab,title,pane,directory", agents = "status,space,tab,agent,title,pane",
}
for kind, layout in pairs(defaults) do
  local settings = config.decode('{"prompt":{"variants":{"' .. kind .. '":"Type: "}}}')
  for _, scope in ipairs(pickers.scopes) do
    assert(table.concat(columns.layout(kind, scope, settings), ",") == layout)
    assert(settings.prompt.variants[kind] == "Type: ")
    local custom = config.decode('{"columns":{"' .. kind .. '":["status"]}}')
    assert(table.concat(columns.layout(kind, scope, custom), ",") == "status")
  end
  for _, value in ipairs({ "[]", "{}", "false", '["status","status"]', '[null]', '["nope"]' }) do
    fails('{"columns":{"' .. kind .. '":' .. value .. '}}', "columns." .. kind)
  end
end
local handoff = json.decode(config.snapshot(config.decode("{}")))
assert(handoff.version == 3)
handoff.version = 2
local ok, err = pcall(config.owner, { getenv = function() return json.encode(handoff) end,
  read_file = function() error("Must not reread incompatible handoff") end })
assert(not ok and err:find("incompatible settings handoff", 1, true))
assert(table.concat(keymap.expect(config.decode("{}").keymap), ",") == "ctrl-s,ctrl-t,ctrl-r,ctrl-a")
print("Unified configuration: all legacy/null/mixed migrations, stable type layouts, invalid inactive overrides and versioned handoff OK")
