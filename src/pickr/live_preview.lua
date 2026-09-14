-- One view owns captures independently of fzf's short-lived preview helpers.
-- Reloading an unchanged target must not repeatedly kill its unfinished read.
local M = {}
M.__index = M

function M.new(capture, notify)
  return setmetatable({ capture = capture, notify = notify, token = 0, waiters = {} }, M)
end

function M:cancel()
  self.token = self.token + 1
  local job = self.job
  self.job, self.content = nil, nil
  if job then job:cancel() end
  local waiters = self.waiters
  self.waiters = {}
  for reply in pairs(waiters) do reply("") end
end

function M:select(target, visible)
  if target == "" then target = nil end
  if target ~= self.target or visible ~= self.visible then
    self:cancel()
    self.target, self.visible = target, visible
  end
end

function M:start()
  if self.job or not self.visible or not self.target then return end
  self.token = self.token + 1
  local token = self.token
  self.job = self.capture(self.target, function(content)
    if token ~= self.token then return end
    self.job, self.content = nil, content
    local waiters = self.waiters
    self.waiters = {}
    if next(waiters) then
      for reply in pairs(waiters) do reply(content) end
    else
      self.notify()
    end
  end)
end

function M:request(target, visible, reply)
  self:select(target, visible)
  if not self.visible or not self.target then reply(""); return end
  if self.content then reply(self.content); return end
  self.waiters[reply] = true
  self:start()
  return function() self.waiters[reply] = nil end
end

function M:refresh(target, visible)
  self:select(target, visible)
  self:start()
end

function M:close()
  self:select(nil, false)
end

return M
