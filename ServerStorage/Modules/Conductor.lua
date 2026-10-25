-- @ScriptType: ModuleScript
--coordinates and starts everything


local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local events = ReplicatedStorage:WaitForChild("Events")
local doEvent = events:WaitForChild("Do")
local doneEvent = events:WaitForChild("Done")

local STEP_TIMEOUT = 180 -- seconds; a client that never answers can't hold the story forever

local Conductor = {}

local pending = {} -- pending[player] = {token, signal, answered, cancelled}
local nextToken = 0

function Conductor.run(player, kind, data)
	if not player:IsDescendantOf(Players) then
		error("player left", 0)
	end
	if pending[player] then
		error("Conductor: " .. player.Name .. " already has a pending step", 0)
	end

	nextToken += 1
	local entry = {token = nextToken, signal = Instance.new("BindableEvent")}
	pending[player] = entry

	doEvent:FireClient(player, entry.token, kind, data)

	task.delay(STEP_TIMEOUT, function()
		if pending[player] == entry then
			entry.signal:Fire(nil) -- gave up waiting
		end
	end)

	local result = entry.signal.Event:Wait()

	-- cleanup: runs on every path (answer, timeout, player left)
	pending[player] = nil
	entry.signal:Destroy()
	if entry.cancelled then
		error("player left", 0)
	end
	return result
end

doneEvent.OnServerEvent:Connect(function(player, token, result)
	local entry = pending[player]
	if not entry or entry.token ~= token or entry.answered then
		return -- stale, duplicate or forged: ignore
	end
	entry.answered = true
	entry.signal:Fire(result)
end)

Players.PlayerRemoving:Connect(function(player)
	local entry = pending[player]
	if entry then
		entry.cancelled = true
		entry.signal:Fire(nil) -- wake the story thread so it can end
	end
end)

return Conductor