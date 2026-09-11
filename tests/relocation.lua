-- Run the README's distribution-only relocation regression, then clean up.
local uv = require("luv")
local script = assert(uv.fs_realpath(arg[0]))
local root = assert(script:match("^(.*)/tests/[^/]+$"))
package.path = root .. "/src/?.lua;" .. package.path
local temporary = assert(uv.fs_mkdtemp((arg[1] or uv.os_tmpdir()) .. "/pickr-relocation-XXXXXX"))
local checkout, caller = temporary .. "/Herdr Pickr", temporary .. "/caller"
local function copy(source, destination)
  local stat = assert(uv.fs_stat(source))
  if stat.type == "directory" then
    assert(uv.fs_mkdir(destination, 448))
    local scan = assert(uv.fs_scandir(source))
    while true do
      local name = uv.fs_scandir_next(scan)
      if not name then break end
      copy(source .. "/" .. name, destination .. "/" .. name)
    end
  else assert(uv.fs_copyfile(source, destination)) end
end
local function remove(path)
  if assert(uv.fs_stat(path)).type == "directory" then
    local scan = assert(uv.fs_scandir(path))
    while true do
      local name = uv.fs_scandir_next(scan)
      if not name then break end
      remove(path .. "/" .. name)
    end
    assert(uv.fs_rmdir(path))
  else assert(uv.fs_unlink(path)) end
end
local original = assert(uv.cwd())
local ok, err = pcall(function()
  assert(uv.fs_mkdir(checkout, 448)); assert(uv.fs_mkdir(caller, 448))
  for _, name in ipairs({ "src", "tests", "herdr-plugin.toml", "LICENSE", "README.md", "AGENTS.md" }) do
    copy(root .. "/" .. name, checkout .. "/" .. name)
  end
  assert(uv.chdir(caller))
  local code, output, errors = require("pickr.process").run("env", {
    "-i", "HOME=" .. assert(os.getenv("HOME")), "PATH=" .. assert(os.getenv("PATH")),
    "TMPDIR=/tmp", "TERM=xterm-256color", "lua", "../Herdr Pickr/tests/test.lua",
  }, nil, nil, 120000)
  io.write(output); io.stderr:write(errors)
  assert(code == 0, "isolated relocation regression failed")
end)
assert(uv.chdir(original))
remove(temporary)
if not ok then error(err, 0) end
print("Relocation: distributed files only, checkout path with spaces, unrelated caller and clean environment passed; temporary copy removed")
