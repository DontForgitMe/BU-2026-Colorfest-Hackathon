-- @ScriptType: ModuleScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CameraController = require(ReplicatedStorage:WaitForChild("CameraController"))
local CutsceneData = require(ReplicatedStorage:WaitForChild("CutsceneData"))
local Transition = require(ReplicatedStorage:WaitForChild("Transition"))

local CutscenePlayer = {}
local playing = false

local stepHandlers = {}

function stepHandlers.shot(step, folder)
	local part = folder and folder:FindFirstChild(step.part)
	if not part then
		error("shot part '" .. tostring(step.part) .. "' not found")
	end
	CameraController.moveTo(part.CFrame, step.fov, step.duration)
end

function stepHandlers.wait(step, folder)
	task.wait(step.seconds)
end

function stepHandlers.fade(step, folder)
	if step.direction == "out" then
		Transition.fadeOut(step.seconds)
	else
		Transition.fadeIn(step.seconds)
	end
end

function CutscenePlayer.play(id)
	if playing then
		return
	end
	local steps = CutsceneData[id]
	if not steps then
		warn("No cutscene data for id: " .. tostring(id))
		return
	end
	playing = true

	local cutscenes = workspace:FindFirstChild("Cutscenes")
	local folder = cutscenes and cutscenes:FindFirstChild(id)

	CameraController.beginCutscene()
	local ok, err = pcall(function()
		for _, step in ipairs(steps) do
			local handler = stepHandlers[step.type]
			if not handler then
				error("unknown step type: " .. tostring(step.type))
			end
			handler(step, folder)
		end
	end)

	-- cleanup lives after the pcall, not inside the steps
	CameraController.endCutscene()
	playing = false
	if not ok then
		warn("Cutscene '" .. id .. "' failed: " .. tostring(err))
	end
end

return CutscenePlayer