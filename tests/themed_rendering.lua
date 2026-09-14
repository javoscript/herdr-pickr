local core, runtime = require("pickr.core"), require("pickr.runtime")
local config, themes = require("pickr.config"), require("pickr.themes")
local snapshot = {
  workspaces = {
    { workspace_id = "w1", label = "parent", tab_count = 1, active_tab_id = "t1", agent_status = "blocked",
      worktree = { repo_key = "repo", is_linked_worktree = false } },
    { workspace_id = "w2", label = "child", tab_count = 1, active_tab_id = "t2", agent_status = "done",
      worktree = { repo_key = "repo", is_linked_worktree = true } },
  },
  tabs = {
    { tab_id = "t1", workspace_id = "w1", label = "first", pane_count = 1, agent_status = "blocked" },
    { tab_id = "t2", workspace_id = "w2", label = "second", pane_count = 1, agent_status = "done" },
  },
  panes = { { pane_id = "p1", workspace_id = "w1", tab_id = "t1", agent_status = "blocked", label = "review", cwd = "/one" },
    { pane_id = "p2", workspace_id = "w2", tab_id = "t2", agent_status = "done", label = "done", cwd = "/two" } },
  layouts = { { workspace_id = "w1", tab_id = "t1", focused_pane_id = "p1", panes = { { pane_id = "p1" } } },
    { workspace_id = "w2", tab_id = "t2", focused_pane_id = "p2", panes = { { pane_id = "p2" } } } },
  agents = {
    { pane_id = "p1", tab_id = "t1", workspace_id = "w1", agent = "agent", agent_status = "blocked" },
    { pane_id = "p2", tab_id = "t2", workspace_id = "w2", agent = "agent", agent_status = "done" },
  },
}
local variants = { { "tabs", "space" }, { "tabs", "all" }, { "spaces", "all" },
  { "agents", "tab" }, { "agents", "space" }, { "agents", "all" },
  { "panes", "tab" }, { "panes", "space" }, { "panes", "all" } }
local function plain(text) return (text:gsub("\27%[[%d;]*m", "")) end
local saved_candidates, saved_picker, saved_current = core.candidates, runtime.run_picker, runtime.current_workspace
local saved_origin = runtime.origin
runtime.origin = function() return { workspace_id = "w1", tab_id = "t1" } end
runtime.current_workspace = function() return "w1" end
core.candidates = function(kind, scope, settings) return core.snapshot_candidates(snapshot, kind, scope, "w1", settings, "t1") end
for _, variant in ipairs(variants) do
  local baseline_rows, baseline_header = core.candidates(variant[1], variant[2], config.decode("{}"))
  local baseline = plain(baseline_header .. "\n" .. table.concat(baseline_rows, "\n"))
  for _, text in ipairs({ "{}", '{"theme":{"name":"catppuccin-latte"}}', '{"theme":{"name":"rose-pine"}}',
    '{"theme":{"name":"terminal"}}',
    '{"theme":{"custom":{"annotation":"red","status_blocked":"#abc","header":"green",'
      .. '"preview_background":"default","preview_foreground":"lightcyan","preview_border":"blue"}}}' }) do
    local settings = config.decode(text)
    local rows, header = core.candidates(variant[1], variant[2], settings)
    local contents = header .. "\n" .. table.concat(rows, "\n")
    assert(plain(contents) == baseline, "theme changed candidate text, IDs, order or alignment")
    assert(rows[1]:find(themes.ansi(settings.roles.status_blocked), 1, true))
    if variant[1] == "agents" or variant[1] == "panes" then assert(contents:find(themes.ansi(settings.roles.annotation) .. "[", 1, true)) end
    runtime.run_picker = function(_, args, input, _, session, render)
      assert(session.settings == settings and input == contents)
      local found = false
      for _, option in ipairs(args) do if option == themes.options(settings.roles) then found = true end end
      assert(found, "picker did not use the resolved chrome/preview roles")
      local refreshed, refreshed_header = render(snapshot)
      assert(table.concat(refreshed, "\n") == table.concat(rows, "\n") and refreshed_header == header)
      return 130, {}, "", 0
    end
    core.pick(variant[1], variant[2], settings)
    local code, filtered, err = require("pickr.process").run("fzf",
      { "--ansi", "--no-sort", "--delimiter=\t", "--with-nth=3..", "--filter=blocked", themes.options(settings.roles) },
      table.concat(rows, "\n"), runtime.fzf_env(), 5000)
    assert(code == 0, err)
    assert(plain(filtered):match("^[^\t]+") == plain(baseline_rows[1]):match("^[^\t]+"), "theme changed search target")
  end
end
core.candidates, runtime.run_picker, runtime.current_workspace = saved_candidates, saved_picker, saved_current
runtime.origin = saved_origin
print("Themed rendering: nine effective type/scopes, dark/light/terminal/custom roles, refresh stability, unchanged text/alignment/IDs/filter targets and preview chrome OK")
