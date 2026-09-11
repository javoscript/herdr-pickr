-- Characterize the pinned fzf grammar independently of the binding importer.
local uv = require("luv")
local directory = assert(uv.fs_realpath(arg[0])):match("^(.*)/[^/]+$")
local pty = dofile(directory .. "/pty_runner.lua")
local process = require("pickr.process")
local valid = {
  "--bind 'alt-j:down+up'", "--bind=alt-j:down --bind=alt-j:up",
  "--bind 'alt-j,alt-k:down'", "--bind ',:down,::up,+:first'",
  "--bind 'alt-,:down,alt-::up,alt-+:first'",
  "--bind 'alt-j:execute(echo a,b+c)+up,alt-k:down'",
  "--bind 'alt-j:execute@echo a,b+c@+up,alt-k:down'",
  "--bind 'alt-j:execute:echo a,b+c'", "--bind 'ALT-J:DOWN+UP'",
  "# comment\n--bind alt-j:down # trailing comment\n",
  "--bind alt-j:do'wn'", "--bind=alt-j:down ; ignored --bind invalid",
  "--bind 'alt-j:down' --bind 'alt-j:+up'",
}
local invalid = { "--bind 'unterminated", "--bind", "--bind 'alt-j:down+'",
  "--bind 'alt-j'", "--bind 'unknown:down'", "--bind alt-j:put(x)" }
local file = assert(io.open(directory .. "/FZF_COMPATIBILITY.md", "r"))
local document = file:read("*a"); file:close()
local inventory = assert(document:match("## Supported action inventory(.-)Lifecycle actions"))
local actions = {}
for action in inventory:gmatch("`([a-z-]+)`") do actions[#actions + 1] = action end
valid[#valid + 1] = "--bind 'f1:" .. table.concat(actions, "+") .. "'"
for index, cases in ipairs({ valid, invalid }) do
  for _, text in ipairs(cases) do
    local code, _, errors = process.run("fzf", { "--filter=alpha" }, "alpha\n",
      pty.environment_list(pty.environment({ FZF_DEFAULT_OPTS = text })), 5000)
    assert((code == 0) == (index == 1), text .. ": " .. errors)
  end
end

local root = assert(uv.fs_mkdtemp("/tmp/pickr fzf compatibility XXXXXX"))
local path = root .. "/options with spaces"
local ok, err = pcall(function()
  local options = assert(io.open(path, "w"))
  assert(options:write("--bind 'alt-j:down'\n")); assert(options:close())
  for _, case in ipairs({ { "", {}, "beta\n" }, { "--bind 'alt-j:ignore'", {}, "alpha\n" },
    { "--bind 'alt-j:ignore'", { "--bind=alt-j:down" }, "beta\n" },
    { "--bind 'alt-j:+up'", {}, "alpha\n" } }) do
    local argv = { "fzf", "--layout=reverse", "--no-sort" }
    for _, option in ipairs(case[2]) do argv[#argv + 1] = option end
    local code, output, screen = pty.run(argv,
      pty.environment({ FZF_DEFAULT_OPTS_FILE = path, FZF_DEFAULT_OPTS = case[1] }),
      { "\27j", "\r" }, "alpha\nbeta\n")
    assert(code == 0 and output == case[3], case[1] .. ": " .. output .. screen:sub(-1000))
  end
end)
uv.fs_unlink(path); assert(uv.fs_rmdir(root))
if not ok then error(err, 0) end
print("fzf compatibility: source precedence, replacement/append bindings, tokenization, aliases, separators and chains pass")
