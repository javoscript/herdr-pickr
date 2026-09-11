local importer = require("pickr.fzf_bindings")
local function equal(a, b) assert(a == b, tostring(a) .. " ~= " .. tostring(b)) end
local function load(text, contents, path_error)
  local diagnostics = {}
  local map = importer.load({
    getenv = function(key)
      if key == "FZF_DEFAULT_OPTS" then return text end
      if key == "FZF_DEFAULT_OPTS_FILE" and (contents or path_error) then return "/fixture options/file with spaces" end
    end,
    read_file = function(path)
      equal(path, "/fixture options/file with spaces")
      return contents, path_error
    end,
    warn = function(message) diagnostics[#diagnostics + 1] = message end,
  })
  return map, table.concat(diagnostics, "\n")
end

local map, warnings = load([[--bind 'alt-j:down+up' --bind=ctrl-m:backward-char]])
equal(map["alt-j"], "down+up"); equal(map.enter, "backward-char"); equal(warnings, "")
map = load([[--bind 'alt-j:+up' --bind 'alt-k:ignore']], [[--bind 'alt-j:down,alt-k:last']])
equal(map["alt-j"], "down+up"); equal(map["alt-k"], "ignore")
map = load([[--bind 'alt-j:up']], [[--bind 'alt-j:down']])
equal(map["alt-j"], "up")
map = load([[--bind ',:down,::up,+:first,alt-,:last,alt-::best,alt-+:ignore']])
for key, action in pairs({ [","] = "down", [":"] = "up", ["+"] = "first",
  ["alt-,"] = "last", ["alt-:"] = "best", ["alt-+"] = "ignore" }) do equal(map[key], action) end
map = load([[--bind 'alt-j,alt-k:down+first']])
equal(map["alt-j"], "down+first"); equal(map["alt-k"], "down+first")
map = load("# comment\n--bind alt-j:do'wn' # ignored --bind=alt-j:up\n--bind \"alt-k:up\"")
equal(map["alt-j"], "down"); equal(map["alt-k"], "up")
equal(table.concat(importer.words([[one\ two "three\tfour" 'five\nsix' '' $HOME]]), "|"),
  "one two|three\tfour|five\\nsix||$HOME")
equal(table.concat(importer.words([[--bind alt-j:down ; --bind alt-j:up]]), "|"), "--bind|alt-j:down")

for _, delimiters in ipairs({ { "(", ")" }, { "{", "}" }, { "[", "]" }, { "<", ">" },
  { "@", "@" }, { "|", "|" }, { "/", "/" } }) do
  map, warnings = load("--bind 'alt-j:down+execute" .. delimiters[1] .. "printf x,y+z"
    .. delimiters[2] .. "+up,alt-k:down'")
  equal(map["alt-j"], nil); equal(map["alt-k"], "down")
  assert(warnings:find("alt-j", 1, true) and warnings:find("execute", 1, true))
end
map, warnings = load([[--bind 'alt-j:execute:printf x,alt-k:up']])
equal(next(map), nil); assert(warnings:find("execute", 1, true))
map, warnings = load([[--bind 'alt-j:+up']], [[--bind 'alt-j:down+accept']])
equal(map["alt-j"], nil); assert(warnings:find("accept", 1, true))
map, warnings = load([[--bind 'start:up,load:reload(echo x),alt-j:toggle-preview,alt-k:preview-down']])
equal(map.start, nil); equal(map.load, nil); equal(map["alt-j"], nil); equal(map["alt-k"], "preview-down")
assert(warnings:find("start", 1, true) and warnings:find("reload", 1, true) and warnings:find("toggle-preview", 1, true))
map = load([[--preview '--bind=alt-j:down' --query '--bind=alt-k:up' --bind 'alt-v:forward-char']])
equal(map["alt-j"], nil); equal(map["alt-k"], nil); equal(map["alt-v"], "forward-char")
map, warnings = load([[--bind 'alt-j:down']], nil, "permission denied")
equal(map["alt-j"], "down"); assert(warnings:find("permission denied", 1, true))
for _, text in ipairs({ [[--bind 'unterminated]], [[--bind]], [[--bind 'alt-j:down+']],
  [[--bind 'alt-j']], [[--bind 'alt-j:execute(oops,alt-k:up']] }) do
  map, warnings = load(text)
  equal(next(map), nil); assert(warnings ~= "", text)
end
for action in pairs(importer.actions) do
  map, warnings = load("--bind 'f1:" .. action:upper() .. "'")
  equal(map.f1, action); equal(warnings, "")
end
print("fzf import: source precedence, tokenization, separator keys, chains, exclusions, diagnostics and option isolation OK")

do
  local config = require("pickr.config")
  local env = { HERDR_PLUGIN_ID = "javoscript.herdr-pickr", HERDR_PLUGIN_CONFIG_DIR = "/fixture",
    FZF_DEFAULT_OPTS = "--bind alt-j:up", FZF_DEFAULT_OPTS_FILE = "/fzf options" }
  local reads = 0
  local deps = { getenv = function(key) return env[key] end,
    read_file = function() return "{}" end,
    read_fzf_file = function() reads = reads + 1; return "--bind alt-k:down" end }
  local launch = config.load(deps)
  equal(launch.fzf_bindings["alt-j"], "up"); equal(reads, 1)
  env.PICKR_SETTINGS_SNAPSHOT = config.snapshot(launch)
  env.FZF_DEFAULT_OPTS = "--bind alt-j:down"
  local owner = config.owner(deps)
  equal(owner.fzf_bindings["alt-j"], "up"); equal(reads, 1)
  env.PICKR_SETTINGS_SNAPSHOT = nil
  equal(config.owner(deps).fzf_bindings["alt-j"], "down"); equal(reads, 2)
end
print("fzf import: launcher snapshot and direct reopen-to-adopt isolation OK")
