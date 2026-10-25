-- @ScriptType: LocalScript
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local CameraController = require(ReplicatedStorage:WaitForChild("CameraController"))
local player = Players.LocalPlayer

CameraController.start()

local function applyCameraMode()
	local mode = player:GetAttribute("CameraMode")
	if mode then
		CameraController.setMode(mode)
	end
end
applyCameraMode()
player:GetAttributeChangedSignal("CameraMode"):Connect(applyCameraMode)

-- TEMP debug: 1 = Centered, 2 = LeftFraming. Delete later: the server decides in the real game.
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.One then
		CameraController.setMode("Centered")
	elseif input.KeyCode == Enum.KeyCode.Two then
		CameraController.setMode("LeftFraming")
	end
end)