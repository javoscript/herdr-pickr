-- Changing full Herdr snapshots shared by unit and real-fzf live fixtures.
return function(fresh)
  if not fresh then
    return {
      workspaces = {
        { workspace_id = "w1", label = "space one", active_tab_id = "t1", tab_count = 1, agent_status = "working" },
        { workspace_id = "w2", label = "removed space", active_tab_id = "t2", tab_count = 1 },
      },
      tabs = {
        { workspace_id = "w1", tab_id = "t1", label = "tab one", pane_count = 2, agent_status = "working" },
        { workspace_id = "w2", tab_id = "t2", label = "removed tab", pane_count = 1 },
      },
      panes = {
        { workspace_id = "w1", tab_id = "t1", pane_id = "pa", terminal_title = "old title", cwd = "/old/pa", agent_status = "working" },
        { workspace_id = "w1", tab_id = "t1", pane_id = "pb", terminal_title = "moving pane", cwd = "/old/pb", agent_status = "blocked" },
        { workspace_id = "w2", tab_id = "t2", pane_id = "pd", terminal_title = "removed pane", cwd = "/old/pd", agent_status = "done" },
      },
      layouts = {
        { workspace_id = "w1", tab_id = "t1", focused_pane_id = "pa", panes = { { pane_id = "pa" }, { pane_id = "pb" } } },
        { workspace_id = "w2", tab_id = "t2", focused_pane_id = "pd", panes = { { pane_id = "pd" } } },
      },
      agents = {
        { workspace_id = "w1", tab_id = "t1", pane_id = "pa", agent = "old-agent", agent_status = "working", state_change_seq = 1 },
        { workspace_id = "w1", tab_id = "t1", pane_id = "pb", agent = "moving-agent", agent_status = "blocked", state_change_seq = 2 },
        { workspace_id = "w2", tab_id = "t2", pane_id = "pd", agent = "removed-agent", agent_status = "done", state_change_seq = 3 },
      },
    }
  end
  return {
    workspaces = { { workspace_id = "w1", label = "space renamed", active_tab_id = "t3", tab_count = 2, agent_status = "blocked" } },
    tabs = {
      { workspace_id = "w1", tab_id = "t1", label = "tab renamed", pane_count = 2, agent_status = "blocked" },
      { workspace_id = "w1", tab_id = "t3", label = "added tab", pane_count = 1, agent_status = "blocked" },
    },
    panes = {
      { workspace_id = "w1", tab_id = "t1", pane_id = "pa", terminal_title = "updated title", cwd = "/new/pa", label = "updated label", agent_status = "blocked" },
      { workspace_id = "w1", tab_id = "t3", pane_id = "pb", terminal_title = "moved pane", cwd = "/new/pb", agent_status = "blocked" },
      { workspace_id = "w1", tab_id = "t1", pane_id = "pc", terminal_title = "added pane", cwd = "/new/pc", agent_status = "working" },
    },
    layouts = {
      { workspace_id = "w1", tab_id = "t1", focused_pane_id = "pc", panes = { { pane_id = "pa" }, { pane_id = "pc" } } },
      { workspace_id = "w1", tab_id = "t3", focused_pane_id = "pb", panes = { { pane_id = "pb" } } },
    },
    agents = {
      { workspace_id = "w1", tab_id = "t1", pane_id = "pa", agent = "new-agent", terminal_title = "updated title", agent_status = "blocked", state_change_seq = 6 },
      { workspace_id = "w1", tab_id = "t3", pane_id = "pb", agent = "moving-agent", agent_status = "blocked", state_change_seq = 5 },
      { workspace_id = "w1", tab_id = "t1", pane_id = "pc", agent = "added-agent", agent_status = "working", state_change_seq = 4 },
    },
  }
end
