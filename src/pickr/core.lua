local runtime = require("pickr.runtime")
local themes = require("pickr.themes")
local columns = require("pickr.columns")
local default_roles = themes.resolve()
local M = {}

-- Herdr 0.9.0 status priority and glyphs are independent of presentation.
local statuses = {
	blocked = { priority = 4, icon = "●" },
	done = { priority = 3, icon = "●" },
	working = { priority = 2, icon = "●" },
	idle = { priority = 1, icon = "○" },
	unknown = { priority = 0, icon = "·" },
}

local function status_style(item)
	return statuses[item.agent_status] or statuses.unknown
end

local function status_text(item)
	return statuses[item.agent_status] and item.agent_status ~= "unknown" and item.agent_status or "-"
end

local function indicator(item, roles)
	local style = status_style(item)
	local status = statuses[item.agent_status] and item.agent_status or "unknown"
	return themes.ansi(roles["status_" .. status]) .. style.icon .. "\27[0m"
end

local function value(text, fallback)
	if text == nil or text == false or text == "" then
		return fallback or ""
	end
	return text
end

local function clean(text)
	local chars = {}
	for _, code in utf8.codes(tostring(value(text))) do
		-- Keep metadata on one row and remove terminal control characters.
		local control = code < 32 or (code >= 127 and code <= 159) or code == 0x2028 or code == 0x2029
		chars[#chars + 1] = control and " " or utf8.char(code)
	end
	return table.concat(chars)
end

local DIRECTORY_LIMIT = 48

local function directory_label(path)
	path = clean(value(path, "—"))
	local home = os.getenv("HOME")
	if home and home ~= "" and (path == home or path:sub(1, #home + 1) == home .. "/") then
		path = "~" .. path:sub(#home + 1)
	end
	local length = utf8.len(path)
	if length > DIRECTORY_LIMIT then
		local start = utf8.offset(path, length - DIRECTORY_LIMIT + 2)
		path = "…" .. path:sub(start)
	end
	return path
end

local function tab_directories(snapshot)
	local panes, directories, targets = {}, {}, {}
	for _, pane in ipairs(snapshot.panes) do
		panes[pane.pane_id] = pane
	end
	for _, layout in ipairs(snapshot.layouts) do
		local pane = panes[layout.focused_pane_id]
		if pane then
			targets[layout.tab_id] = pane.pane_id
			directories[layout.tab_id] = value(pane.foreground_cwd, value(pane.cwd))
		end
	end
	return directories, targets
end

function M.aligned_rows(entries, header, roles)
	local annotation = themes.ansi((roles or default_roles).annotation)
	if header then
		local combined = { header }
		for _, entry in ipairs(entries) do
			combined[#combined + 1] = entry
		end
		entries = combined
	end
	local widths = {}
	for _, entry in ipairs(entries) do
		for i = 2, #entry do
			entry[i] = clean(entry[i])
			widths[i] = math.max(widths[i] or 0, utf8.len(entry[i]))
		end
	end
	local rows = {}
	for _, entry in ipairs(entries) do
		local fields = {}
		for i = 2, #entry do
			local text = entry[i]
			local suffix = entry.muted_suffixes and entry.muted_suffixes[i]
			if suffix then
				-- Style only after cleaning/measuring, preserving column alignment.
				text = text:sub(1, #text - #suffix)
					.. annotation
					.. suffix
					.. "\27[0m"
				if i == entry.parent_field and text:sub(1, #"└─ ") == "└─ " then
					text = annotation .. "└─ \27[0m" .. text:sub(#"└─ " + 1)
				end
			end
			-- The glyph occupies the same two cells in every row, including the header.
			if entry.indicator and i == (entry.indicator_field or 2) then
				text = entry.indicator .. " " .. text
			end
			fields[#fields + 1] = text .. (i < #entry and string.rep(" ", widths[i] - utf8.len(entry[i])) or "")
		end
		rows[#rows + 1] = entry[1]
			.. "\t"
			.. (entry.preview_pane or "-")
			.. "\t"
			.. table.concat(fields, "  ·  ")
	end
	if header then
		local heading = table.remove(rows, 1)
		return rows, heading
	end
	return rows
end

local function column_header(kind, scope)
	local header = { "@header", indicator = " ", muted_suffixes = {} }
	for _, name in ipairs(columns.layout(kind, scope)) do
		header[#header + 1] = name == "pane" and "pane [label]" or name
		if name == "pane" then header.muted_suffixes[#header] = "[label]" end
	end
	return header
end

-- Project the existing canonical entries before measuring or styling them.
-- IDs remain outside the projection; annotation indexes travel with values.
local function render_columns(entries, kind, scope, settings, roles)
	local indexes = {}
	for index, name in ipairs(columns.layout(kind, scope)) do indexes[name] = index + 1 end
	local layout = columns.layout(kind, scope, settings)
	local function project(entry)
		local result = { entry[1], preview_pane = entry.preview_pane, muted_suffixes = {} }
		for index, name in ipairs(layout) do
			local source, target = indexes[name], index + 1
			result[target] = entry[source]
			result.muted_suffixes[target] = entry.muted_suffixes and entry.muted_suffixes[source]
			if source == entry.parent_field then result.parent_field = target end
			if name == "status" then result.indicator, result.indicator_field = entry.indicator, target end
		end
		return result
	end
	local projected = {}
	for index, entry in ipairs(entries) do projected[index] = project(entry) end
	return M.aligned_rows(projected, project(column_header(kind, scope)), roles)
end

local function grouped_workspaces(workspaces)
	-- Match Herdr's expanded sidebar: emit a group at its first member's
	-- position, parent first, then children in their original relative order.
	local groups, ordered, emitted = {}, {}, {}
	for _, workspace in ipairs(workspaces) do
		local tree = workspace.worktree
		if tree and tree.repo_key then
			local group = groups[tree.repo_key] or { members = {} }
			groups[tree.repo_key] = group
			group.members[#group.members + 1] = workspace
			if tree.is_linked_worktree == false and not group.parent then
				group.parent = workspace
			end
		end
	end
	for _, workspace in ipairs(workspaces) do
		local tree = workspace.worktree
		local group = tree and groups[tree.repo_key]
		if not group or not group.parent or #group.members < 2 then
			ordered[#ordered + 1] = workspace
		elseif not emitted[tree.repo_key] then
			emitted[tree.repo_key] = true
			ordered[#ordered + 1] = group.parent
			for _, member in ipairs(group.members) do
				if member ~= group.parent then
					ordered[#ordered + 1] = member
				end
			end
		end
	end
	return ordered
end

function M.candidates(kind, scope, settings)
	-- One consistent snapshot includes server-aggregated statuses and remembered
	-- tab focus, including inactive tabs (PaneInfo.focused is only global focus).
	return M.snapshot_candidates(runtime.herdr("api", "snapshot").snapshot, kind, scope, runtime.current_workspace(), settings)
end

function M.snapshot_candidates(snapshot, kind, scope, current, settings)
	local roles = settings and settings.roles or default_roles
	local workspaces = grouped_workspaces(snapshot.workspaces)
	local directories, targets = tab_directories(snapshot)
	local names, entries, parent_suffixes = {}, {}, {}
	local parent_repos = {}
	for _, workspace in ipairs(workspaces) do
		local tree = workspace.worktree
		if tree and tree.repo_key and tree.is_linked_worktree == false and not parent_repos[tree.repo_key] then
			parent_repos[tree.repo_key] = workspace
		end
	end
	local group_widths = {}
	for _, workspace in ipairs(workspaces) do
		local tree = workspace.worktree
		local name = clean(value(workspace.label, workspace.workspace_id))
		names[workspace.workspace_id] = name
		if tree and tree.is_linked_worktree and parent_repos[tree.repo_key] then
			group_widths[tree.repo_key] = math.max(group_widths[tree.repo_key] or 0, utf8.len(name))
		end
	end
	for _, workspace in ipairs(workspaces) do
		local tree = workspace.worktree
		local parent = tree and tree.is_linked_worktree and parent_repos[tree.repo_key]
		local name = names[workspace.workspace_id]
		if parent then
			parent_suffixes[workspace.workspace_id] = "[" .. clean(value(parent.label, parent.workspace_id)) .. "]"
			name = (kind ~= "agents" and "└─ " or "")
				.. name
				.. string.rep(" ", group_widths[tree.repo_key] - utf8.len(name) + 1)
				.. parent_suffixes[workspace.workspace_id]
		end
		names[workspace.workspace_id] = name
	end
	local function add_space(entry, workspace_id)
		entry[#entry + 1] = names[workspace_id] or workspace_id
		entry.parent_field = #entry
		entry.muted_suffixes = { [#entry] = parent_suffixes[workspace_id] }
	end
	if scope == "current" and not current then
		error("Current-space pickers must be launched from a Herdr popup", 0)
	end
	if kind == "workspaces" then
		for _, workspace in ipairs(workspaces) do
			local entry = { workspace.workspace_id, status_text(workspace) }
			add_space(entry, workspace.workspace_id)
			entry[#entry + 1] = workspace.tab_count .. " tabs"
			entry[#entry + 1] = directory_label(directories[workspace.active_tab_id])
			entry.indicator = indicator(workspace, roles)
			entry.preview_pane = targets[workspace.active_tab_id]
			entries[#entries + 1] = entry
		end
		return render_columns(entries, kind, scope, settings, roles)
	end

	local tabs = {}
	for _, tab in ipairs(snapshot.tabs) do
		if scope == "all" or tab.workspace_id == current then
			tabs[#tabs + 1] = tab
		end
	end
	if kind == "tabs" then
		if scope == "all" then
			local workspace_order, tab_order = {}, {}
			for index, workspace in ipairs(workspaces) do
				workspace_order[workspace.workspace_id] = index
			end
			for index, tab in ipairs(tabs) do
				tab_order[tab] = index
			end
			table.sort(tabs, function(a, b)
				local ar, br =
					workspace_order[a.workspace_id] or math.huge, workspace_order[b.workspace_id] or math.huge
				if ar ~= br then
					return ar < br
				end
				return tab_order[a] < tab_order[b]
			end)
		end
		for _, tab in ipairs(tabs) do
			local entry = { tab.tab_id, status_text(tab) }
			entry.indicator = indicator(tab, roles)
			entry.preview_pane = targets[tab.tab_id]
			if scope == "all" then
				add_space(entry, tab.workspace_id)
			end
			entry[#entry + 1] = value(tab.label, tab.tab_id)
			entry[#entry + 1] = tab.pane_count .. " panes"
			entry[#entry + 1] = directory_label(directories[tab.tab_id])
			entries[#entries + 1] = entry
		end
		return render_columns(entries, kind, scope, settings, roles)
	end

	local pane_labels = {}
	for _, pane in ipairs(snapshot.panes) do
		local label = value(pane.label)
		if label ~= "" then
			pane_labels[pane.pane_id] = clean(label)
		end
	end
	local tab_names = {}
	for _, tab in ipairs(tabs) do
		tab_names[tab.tab_id] = value(tab.label, tab.tab_id)
	end
	local agents = {}
	for index, agent in ipairs(snapshot.agents) do
		if scope == "all" or agent.workspace_id == current then
			agents[#agents + 1] = { agent = agent, index = index }
		end
	end
	table.sort(agents, function(a, b)
		local ap, bp = status_style(a.agent).priority, status_style(b.agent).priority
		if ap ~= bp then
			return ap > bp
		end
		local as, bs = a.agent.state_change_seq or 0, b.agent.state_change_seq or 0
		if as ~= bs then
			return as > bs
		end
		-- Lua's sort is unstable; preserve the API's workspace/tab/layout order.
		return a.index < b.index
	end)
	for _, item in ipairs(agents) do
		local agent = item.agent
		local entry = { agent.pane_id, status_text(agent) }
		entry.indicator = indicator(agent, roles)
		entry.preview_pane = agent.pane_id
		if scope == "all" then
			add_space(entry, agent.workspace_id)
		end
		entry[#entry + 1] = tab_names[agent.tab_id] or agent.tab_id
		entry[#entry + 1] = value(agent.name, value(agent.agent))
		entry[#entry + 1] = value(agent.terminal_title_stripped, value(agent.terminal_title))
		entry[#entry + 1] = agent.pane_id
		local label = pane_labels[agent.pane_id]
		if label then
			local suffix = "[" .. label .. "]"
			entry[#entry] = entry[#entry] .. " " .. suffix
			entry.muted_suffixes = entry.muted_suffixes or {}
			entry.muted_suffixes[#entry] = suffix
		end
		entries[#entries + 1] = entry
	end
	return render_columns(entries, kind, scope, settings, roles)
end

function M.preview(pane_id)
	if not pane_id or pane_id == "-" then
		return "No pane available for preview.\n"
	end
	local ok, output = pcall(function()
		local pane = runtime.herdr("pane", "get", pane_id).pane
		local screen = runtime.read_visible(pane_id)
		local cwd = clean(value(pane.foreground_cwd, value(pane.cwd, "—")))
		return clean(pane_id) .. "\n" .. cwd .. "\n\n" .. (screen ~= "" and screen or "(Empty screen)") .. "\27[0m\n"
	end)
	if not ok then
		return "Preview unavailable: pane closed or could not be read.\n"
	end
	return output
end

local keymap = require("pickr.keymap")

local Session = {}
Session.__index = Session

local function candidate_id(row)
	if type(row) ~= "string" or row:find("[\r\n]") then return nil end
	local id = row:match("^([^%s]+)\t[^\t]+\t[^\t]*$")
	if id and id:sub(1, 1) ~= "@" then return id end
end

function M.new_session(rows, header)
	local session = setmetatable({ state = "loading", generation = 0, active = {} }, Session)
	assert(session:publish(0, rows, header))
	return session
end

function Session:begin_refresh(id)
	if self.state ~= "ready" and self.state ~= "error" then return nil end
	if self.state == "ready" then self.saved_id = self.active[id] and id or nil end
	self.generation = self.generation + 1
	self.state, self.active = "loading", {}
	return self.generation
end

function Session:is_current(generation)
	return self.state == "loading" and self.generation == generation
end

function Session:publish(generation, rows, header)
	if not self:is_current(generation) then return false end
	local active = {}
	for _, row in ipairs(rows) do
		local id = assert(candidate_id(row), "Malformed candidate")
		assert(not active[id], "Duplicate candidate ID")
		active[id] = true
	end
	self.rows, self.header, self.active, self.state = rows, header, active, "ready"
	return true
end

function Session:fail(generation)
	if not self:is_current(generation) then return false end
	self.state, self.active = "error", {}
	return true
end

function Session:accept(row)
	local id = candidate_id(row)
	if self.state == "ready" and self.active[id] then return id end
end

function Session:close()
	self.generation = self.generation + 1
	self.state, self.active = "closed", {}
end

local function pick_once(kind, scope, settings, popup)
	local rows, header = M.candidates(kind, scope, settings)
	local origin = runtime.current_workspace()
	local session = M.new_session(rows, header)
	session.settings = settings
	session.popup = popup
	local expect = keymap.expect(settings.keymap)
	session.has_expect = #expect > 0
	local footer
	if settings.popup.show_hints then
		footer = function(count) return keymap.footer(settings.keymap, count) end
	end
	local search_fields = {}
	for i = 1, #columns.layout(kind, scope, settings) do
		search_fields[#search_fields + 1] = tostring(i)
	end
	local title = kind == "workspaces" and "Spaces"
		or (kind:gsub("^%l", string.upper) .. " — " .. scope .. " space" .. (scope == "all" and "s" or ""))
	local prompt
	for variant, destination in pairs(keymap.variants) do
		if destination[1] == kind and destination[2] == scope then
			prompt = settings.prompt.variants[variant]
			break
		end
	end
	local args = {
		"--layout=reverse",
		"--border=rounded",
		"--no-multi",
		"--ansi",
		"--delimiter=\t|  ·  ",
		"--with-nth=3..",
		-- --nth indexes the displayed fields after --with-nth. Individual
		-- indices keep each query term within one column; a range joins them.
		"--nth=" .. table.concat(search_fields, ","),
		"--prompt=" .. prompt,
		"--header-lines=1",
		"--with-shell=/bin/sh -c",
		"--preview=" .. runtime.preview_command(),
		"--preview-window=right:50%:border-left:nowrap" .. (popup.preview_visible and "" or ":hidden"),
		themes.options(settings.roles),
		"--border-label=" .. title,
	}
	if footer then args[#args + 1] = "--footer=" .. footer(#rows) end
	if session.has_expect then args[#args + 1] = "--expect=" .. table.concat(expect, ",") end
	for _, key in ipairs({ "enter", "esc", "ctrl-c", "ctrl-g", "ctrl-q", "ctrl-z", "double-click" }) do
		args[#args + 1] = "--bind=" .. key .. ":ignore"
	end
	args[#args + 1] = "--bind=ctrl-d:delete-char"
	local inherited = {}
	for key in pairs(settings.fzf_bindings or {}) do inherited[#inherited + 1] = key end
	table.sort(inherited)
	for _, key in ipairs(inherited) do
		args[#args + 1] = "--bind=" .. key .. ":" .. settings.fzf_bindings[key]
	end
	for _, key in ipairs(settings.keymap.keys.accept) do args[#args + 1] = "--bind=" .. key .. ":accept" end
	for _, key in ipairs(settings.keymap.keys.close) do args[#args + 1] = "--bind=" .. key .. ":abort" end
	if kind ~= "tabs" or scope == "all" then
		args[#args + 1] = "--no-sort"
	end
	local code, output, errors, signal, target =
		runtime.run_picker("fzf", args, header .. "\n" .. table.concat(rows, "\n"), runtime.fzf_env(), session,
			function(snapshot)
				local fresh, heading = M.snapshot_candidates(snapshot, kind, scope, origin, settings)
				M.new_session(fresh, heading) -- Validate the whole generation before publishing any rows.
				return fresh, heading
			end, footer)
	-- --expect emits the pressed shortcut on the first line (blank for Enter).
	-- A shortcut can exit with code 1 when there are no matching rows.
	local key, selected = "", output
	if session.has_expect then key, selected = output:match("^([^\n]*)\n(.*)$") end
	local destination = keymap.variants[settings.keymap.reverse[key]]
	if (code == 0 or code == 1) and (not signal or signal == 0) and destination then
		return destination
	end
	if code == 1 or code == 130 or signal == 2 then
		return
	end
	if code ~= 0 or (signal and signal ~= 0) then
		error(errors ~= "" and errors or "fzf failed", 0)
	end
	if key ~= "" or selected == nil then
		error("Picker returned an unknown shortcut", 0)
	end
	if target then
		if kind == "agents" then
			runtime.focus_agent_pane(target)
		else
			runtime.herdr(kind == "tabs" and "tab" or "workspace", "focus", target)
		end
		return
	end
	error("Picker returned an unknown selection", 0)
end

function M.pick(kind, scope, settings)
	settings = settings or require("pickr.config").owner()
	local popup = { preview_visible = settings.preview.enabled_by_default }
	while true do
		local next_picker = pick_once(kind, scope, settings, popup)
		if not next_picker then
			return
		end
		kind, scope = table.unpack(next_picker)
	end
end

return M
