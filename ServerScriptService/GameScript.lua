-- @ScriptType: Script
local players = game:GetService("Players")

players.PlayerAdded:Connect(function(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local HumanoidRootPart = character:WaitForChild("HumanoidRootPart")
	
	task.wait(7)
	game.Lighting.ClockTime=2
	local teleportPart = game.Workspace:WaitForChild("ChapterStart")
	HumanoidRootPart.Position = teleportPart.Position
end)