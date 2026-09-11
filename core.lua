local runtime = require("runtime")
local M = {}

-- Herdr 0.9.0 status priority, dot glyphs, and Rosé Pine palette colors.
local statuses = {
	blocked = { priority = 4, icon = "●", color = "235;111;146" },
	done = { priority = 3, icon = "●", color = "156;207;216" },
	working = { priority = 2, icon = "●", color = "246;193;119" },
	idle = { priority = 1, icon = "○", color = "49;116;143" },
	unknown = { priority = 0, icon = "·", color = "110;106;134" },
}

local function status_style(item)
	return statuses[item.agent_status] or statuses.unknown
end

local function status_text(item)
	return statuses[item.agent_status] and item.agent_status ~= "unknown" and item.agent_status or "-"
end

local function indicator(item)
	local style = status_style(item)
	return "\27[38;2;" .. style.color .. "m" .. style.icon .. "\27[0m"
end

local function plain(text)
	return (text:gsub("\27%[[%d;]*m", ""))
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

function M.aligned_rows(entries, header)
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
			if i == entry.parent_field and entry.parent_suffix then
				-- Style only after cleaning/measuring, preserving column alignment.
				text = text:sub(1, #text - #entry.parent_suffix)
					.. "\27[38;2;82;79;103m"
					.. entry.parent_suffix
					.. "\27[0m"
				if text:sub(1, #"└─ ") == "└─ " then
					text = "\27[38;2;82;79;103m└─ \27[0m" .. text:sub(#"└─ " + 1)
				end
			end
			fields[#fields + 1] = text .. (i < #entry and string.rep(" ", widths[i] - utf8.len(entry[i])) or "")
		end
		-- Add trusted styling after cleaning and measuring metadata columns.
		local prefix = entry.indicator and entry.indicator .. " " or ""
		rows[#rows + 1] = entry[1]
			.. "\t"
			.. (entry.preview_pane or "-")
			.. "\t"
			.. prefix
			.. table.concat(fields, "  ·  ")
	end
	if header then
		local heading = table.remove(rows, 1)
		return rows, heading
	end
	return rows
end

local function column_header(kind, scope)
	local header = { "@header", "status", indicator = " " }
	if kind == "workspaces" then
		header[#header + 1] = "space"
		header[#header + 1] = "tabs"
		header[#header + 1] = "directory"
	elseif kind == "tabs" then
		header[#header + 1] = "tab"
		if scope == "all" then
			header[#header + 1] = "space"
		end
		header[#header + 1] = "panes"
		header[#header + 1] = "directory"
	else
		if scope == "all" then
			header[#header + 1] = "space"
		end
		header[#header + 1] = "tab"
		header[#header + 1] = "agent"
		header[#header + 1] = "title"
		header[#header + 1] = "pane"
	end
	return header
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

function M.candidates(kind, scope)
	-- One consistent snapshot includes server-aggregated statuses and remembered
	-- tab focus, including inactive tabs (PaneInfo.focused is only global focus).
	local snapshot = runtime.herdr("api", "snapshot").snapshot
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
		entry.parent_suffix = parent_suffixes[workspace_id]
	end
	local current = runtime.current_workspace()
	if scope == "current" and not current then
		error("Current-space pickers must be launched from a Herdr popup", 0)
	end
	if kind == "workspaces" then
		for _, workspace in ipairs(workspaces) do
			local entry = { workspace.workspace_id, status_text(workspace) }
			add_space(entry, workspace.workspace_id)
			entry[#entry + 1] = workspace.tab_count .. " tabs"
			entry[#entry + 1] = directory_label(directories[workspace.active_tab_id])
			entry.indicator = indicator(workspace)
			entry.preview_pane = targets[workspace.active_tab_id]
			entries[#entries + 1] = entry
		end
		return M.aligned_rows(entries, column_header(kind, scope))
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
			local entry = { tab.tab_id, status_text(tab), value(tab.label, tab.tab_id) }
			entry.indicator = indicator(tab)
			entry.preview_pane = targets[tab.tab_id]
			if scope == "all" then
				add_space(entry, tab.workspace_id)
			end
			entry[#entry + 1] = tab.pane_count .. " panes"
			entry[#entry + 1] = directory_label(directories[tab.tab_id])
			entries[#entries + 1] = entry
		end
		return M.aligned_rows(entries, column_header(kind, scope))
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
		entry.indicator = indicator(agent)
		entry.preview_pane = agent.pane_id
		if scope == "all" then
			add_space(entry, agent.workspace_id)
		end
		entry[#entry + 1] = tab_names[agent.tab_id] or agent.tab_id
		entry[#entry + 1] = value(agent.name, value(agent.agent))
		entry[#entry + 1] = value(agent.terminal_title_stripped, value(agent.terminal_title))
		entry[#entry + 1] = agent.pane_id
		entries[#entries + 1] = entry
	end
	return M.aligned_rows(entries, column_header(kind, scope))
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

local picker_shortcuts = {
	["ctrl-r"] = { "tabs", "current" },
	["ctrl-t"] = { "tabs", "all" },
	["ctrl-s"] = { "workspaces", "all" },
	["ctrl-a"] = { "agents", "current" },
	["ctrl-g"] = { "agents", "all" },
}

local function pick_once(kind, scope)
	local rows, header = M.candidates(kind, scope)
	local search_fields = {}
	for i = 2, #column_header(kind, scope) do
		search_fields[#search_fields + 1] = tostring(i - 1)
	end
	local title = kind == "workspaces" and "Spaces"
		or (kind:gsub("^%l", string.upper) .. " — " .. scope .. " space" .. (scope == "all" and "s" or ""))
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
		"--prompt=◉/> ",
		"--header-lines=1",
		"--with-shell=/bin/sh -c",
		"--preview=" .. runtime.preview_command(),
		"--preview-window=right:50%:border-left:nowrap",
		"--expect=ctrl-r,ctrl-t,ctrl-s,ctrl-a,ctrl-g",
		-- Rosé Pine (original dark palette).
		"--color=bg:#191724,bg+:#26233a,fg:#908caa,fg+:#e0def4",
		"--color=hl:#ebbcba,hl+:#ebbcba,info:#c4a7e7,marker:#eb6f92",
		"--color=prompt:#c4a7e7,spinner:#f6c177,pointer:#eb6f92",
		"--color=header:#6e6a86,footer:#6e6a86,border:#403d52,label:#e0def4",
		"--border-label=" .. title,
		"--footer="
			.. (#rows > 0 and "enter: switch · ctrl+p: preview · esc: cancel" or "no entries · ctrl+p: preview · esc: close")
			.. "\nctrl+r: tabs here · ctrl+t: all tabs · ctrl+s: spaces · ctrl+a: agents here · ctrl+g: all agents",
		"--bind=esc:abort,ctrl-c:abort,enter:accept,ctrl-p:toggle-preview",
	}
	if kind ~= "tabs" or scope == "all" then
		args[#args + 1] = "--no-sort"
	end
	local code, output, errors, signal =
		runtime.run("fzf", args, header .. "\n" .. table.concat(rows, "\n"), runtime.fzf_env())
	-- --expect emits the pressed shortcut on the first line (blank for Enter).
	-- A shortcut can exit with code 1 when there are no matching rows.
	local key, selected = output:match("^([^\n]*)\n(.*)$")
	if (code == 0 or code == 1) and (not signal or signal == 0) and picker_shortcuts[key] then
		return picker_shortcuts[key]
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
	selected = selected:gsub("\n+$", "")
	for _, row in ipairs(rows) do
		-- fzf --ansi removes styling from accepted output.
		if plain(row) == selected then
			local target = assert(selected:match("^(.-)\t"))
			if kind == "agents" then
				runtime.focus_agent_pane(target)
			else
				runtime.herdr(kind == "tabs" and "tab" or "workspace", "focus", target)
			end
			return
		end
	end
	error("Picker returned an unknown selection", 0)
end

function M.pick(kind, scope)
	while true do
		local next_picker = pick_once(kind, scope)
		if not next_picker then
			return
		end
		kind, scope = table.unpack(next_picker)
	end
end

return M
