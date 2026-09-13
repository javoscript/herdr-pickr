local runtime = require("pickr.runtime")
local env = { HERDR_PLUGIN_ID = "javoscript.herdr-pickr",
  HERDR_PLUGIN_CONTEXT_JSON = '{"workspace_id":"w1","tab_id":"t1"}',
  HERDR_ACTIVE_WORKSPACE_ID = "w2" }
local function getenv(key) return env[key] end
local snapshot = { workspaces = {
  { workspace_id = "w1", active_tab_id = "later" },
  { workspace_id = "w2", active_tab_id = "unrelated" },
} }
local origin = runtime.origin(getenv, snapshot)
assert(origin.workspace_id == "w1" and origin.tab_id == "t1")
env.PICKR_ORIGIN_WORKSPACE_ID, env.PICKR_ORIGIN_TAB_ID = "w1", "t1"
env.HERDR_PLUGIN_CONTEXT_JSON = '{"workspace_id":"w2","tab_id":"unrelated"}'
assert(runtime.origin(getenv, snapshot).tab_id == "t1")
env.PICKR_ORIGIN_TAB_ID = ""
assert(runtime.origin(getenv, snapshot).tab_id == nil)
env.PICKR_ORIGIN_TAB_ID = nil
assert(runtime.origin(getenv, snapshot).tab_id == "later")
env.HERDR_PLUGIN_ID = "other.plugin"
assert(runtime.origin(getenv, snapshot).tab_id == "later")
snapshot.workspaces[1].active_tab_id = nil
assert(runtime.origin(getenv, snapshot).tab_id == nil)
snapshot.workspaces = {}
assert(runtime.origin(getenv, snapshot).tab_id == nil)
assert(origin.tab_id == "t1")
env.PICKR_ORIGIN_WORKSPACE_ID = nil
snapshot.workspaces = { { workspace_id = "w2", active_tab_id = "direct" } }
assert(runtime.origin(getenv, snapshot).tab_id == "direct")
print("Origin: action/handoff precedence, explicit absence, direct fallback and missing/deleted workspace OK")
