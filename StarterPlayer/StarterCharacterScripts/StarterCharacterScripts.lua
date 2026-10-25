-- @ScriptType: LocalScript
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:FindFirstChildOfClass("Humanoid")

humanoid.JumpPower = 0
humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

--if they somehow do sit then get their ahh up
humanoid:GetPropertyChangedSignal("Sit"):Connect(function()
	if humanoid.Sit then
		humanoid.Sit = false
	end
end)