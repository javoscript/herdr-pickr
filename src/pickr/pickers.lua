local M = {}

M.order = { "spaces", "tabs", "panes", "agents" }
M.scopes = { "all", "space", "tab" }
M.types = {
  spaces = {}, tabs = { all = true, space = true },
  panes = { all = true, space = true, tab = true },
  agents = { all = true, space = true, tab = true },
}
M.presets = { spaces = { "spaces", "all" } }
for _, kind in ipairs(M.order) do
  if kind ~= "spaces" then
    M.presets[kind] = { kind, "all" }
    for _, scope in ipairs(M.scopes) do
      if M.types[kind][scope] then M.presets[kind .. "-" .. scope] = { kind, scope } end
    end
  end
end

-- Interactive fallback is based only on capabilities, never on candidate data.
function M.effective(kind, chosen)
  assert(M.types[kind], "Unknown picker type")
  assert(chosen == "all" or chosen == "space" or chosen == "tab", "Unknown chosen scope")
  if kind == "spaces" then return nil end
  return chosen == "tab" and not M.types[kind].tab and "space" or chosen
end

function M.launch(kind, scope)
  if scope == "current" then error("Scope 'current' was removed; use 'space' instead", 0) end
  if not M.types[kind] then error("Unknown picker type: " .. tostring(kind), 0) end
  if scope ~= nil and not M.types[kind][scope] then
    error("Unsupported picker/scope pair: " .. kind .. " " .. tostring(scope), 0)
  end
  return kind, scope or "all"
end

function M.preset(name)
  if type(name) == "string" and name:match("%-current$") then
    error("Entrypoint '" .. name .. "' was removed; use '" .. name:gsub("%-current$", "-space") .. "' instead", 0)
  end
  local preset = M.presets[name]
  if not preset then error("Invalid Pickr entrypoint: " .. tostring(name), 0) end
  return table.unpack(preset)
end

M.legacy = {
  tabs_current = "tabs", tabs_all = "tabs", agents_current = "agents", agents_all = "agents",
  panes_tab = "panes", panes_current = "panes", panes_all = "panes",
}
function M.check_leaf(container, leaf)
  local replacement = M.legacy[leaf]
  if replacement then
    error(container .. "." .. leaf .. " was removed; use " .. container .. "." .. replacement
      .. (container == "keys" and "; picker type and scope now have separate actions (scope_all, scope_space, scope_tab)"
        or "; consolidate scope-specific overrides manually into one type setting"), 0)
  end
end

return M
