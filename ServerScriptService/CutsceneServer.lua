-- @ScriptType: Script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playCutscene = ReplicatedStorage:WaitForChild("PlayCutscene")
local cutsceneDone = ReplicatedStorage:WaitForChild("CutsceneDone")
local CutsceneData = require(ReplicatedStorage:WaitForChild("CutsceneData"))
local cutscenesFolder = workspace:WaitForChild("Cutscenes")

-- Plain server tables: clients never read these
local seen = {}   -- seen[player][id] = true
local active = {} -- active[player] = true while that player is in a cutscene

local function startCutscene(player, id, replayable)
	if active[player] then
		return
	end
	if not CutsceneData[id] then
		warn("No cutscene data for id: " .. tostring(id))
		return
	end
	seen[player] = seen[player] or {}
	if seen[player][id] then
		return
	end

	active[player] = true
	if not replayable then
		seen[player][id] = true
	end
	player:SetAttribute("InCutscene", true)
	playCutscene:FireClient(player, id) -- the id is all the client gets
end

local function onTriggerTouched(trigger, hit)
	-- TODO 1:
	--  a) find the Player who owns `hit` (hit is a character part; try
	--     Players:GetPlayerFromCharacter on hit.Parent)
	--  b) no player? return
	--  c) read the id and replayable flag from `trigger` with :GetAttribute(...)
	--  d) call startCutscene(player, id, replayable)
end

for _, folder in ipairs(cutscenesFolder:GetChildren()) do
	local trigger = folder:FindFirstChild("Trigger")
	if trigger then
		trigger.Touched:Connect(function(hit)
			onTriggerTouched(trigger, hit)
		end)
	end
end

-- The client only says "I'm done". We trust nothing else it could send.
cutsceneDone.OnServerEvent:Connect(function(player)
	if not active[player] then
		return
	end
	active[player] = nil
	player:SetAttribute("InCutscene", false)
end)

-- Cleanup: entries keyed by player would otherwise live forever
Players.PlayerRemoving:Connect(function(player)
	seen[player] = nil
	active[player] = nil
end)