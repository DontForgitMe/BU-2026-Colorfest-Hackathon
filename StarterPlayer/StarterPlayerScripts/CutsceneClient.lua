-- @ScriptType: LocalScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local events = ReplicatedStorage:WaitForChild("Events")
local CutscenePlayer = require(ReplicatedStorage:WaitForChild("CutscenePlayer"))
local Transition = require(ReplicatedStorage:WaitForChild("Transition"))

-- One handler per step kind the server can ask for. Each YIELDS until its step is done.
local handlers = {}

function handlers.cutscene(id)
	CutscenePlayer.play(id)
end

function handlers.fadeOut()
	Transition.fadeOut(1)
end

function handlers.fadeIn()
	Transition.fadeIn(1)
end

events:WaitForChild("Do").OnClientEvent:Connect(function(token, kind, data)
	local result = nil
	local handler = handlers[kind]
	if handler then
		local ok, value = pcall(handler, data)
		if ok then
			result = value
		else
			warn("Step '" .. tostring(kind) .. "' failed: " .. tostring(value))
		end
	else
		warn("Unknown step kind from server: " .. tostring(kind))
	end
	events.Done:FireServer(token, result) -- always answer, so the server never hangs
end)

Transition.setBlack() -- cover the screen right away
events.ClientReady:FireServer() -- listeners are connected, safe to start