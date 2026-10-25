-- @ScriptType: Script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local events = ReplicatedStorage:WaitForChild("Events")
local clientReady = events:WaitForChild("ClientReady")
local Conductor = require(ServerScriptService:WaitForChild("Conductor"))
local StoryFlow = require(ServerScriptService:WaitForChild("StoryFlow"))

local INTRO_DELAY = 2 -- the "wait a little bit" before the intro starts

local busy = {}         -- busy[player] = true while locked into the story
local introStarted = {} -- introStarted[player] = true once their intro has begun

local function setBusy(player, value)
	busy[player] = value or nil
	player:SetAttribute("InCutscene", value)
end

local function runScene(player, id)
	local scene = StoryFlow[id]
	if not scene then
		warn("No story scene named: " .. tostring(id))
		return
	end
	setBusy(player, true)
	local ok, err = pcall(scene, player)
	if not ok and err ~= "player left" then
		warn("Scene '" .. id .. "' failed: " .. tostring(err))
		pcall(Conductor.run, player, "fadeIn") -- never leave a player on a black screen
	end
	-- cleanup lives after the pcall, not inside the scene
	if player:IsDescendantOf(Players) then
		setBusy(player, false)
	end
end

local function onPlayerAdded(player)
	setBusy(player, true) -- locked from the moment they join; their screen is black too
end

clientReady.OnServerEvent:Connect(function(player)
	if introStarted[player] then
		return
	end
	introStarted[player] = true
	task.wait(INTRO_DELAY)
	if player:IsDescendantOf(Players) then
		runScene(player, "Intro")
	end
end)

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
	busy[player] = nil
	introStarted[player] = nil
end)