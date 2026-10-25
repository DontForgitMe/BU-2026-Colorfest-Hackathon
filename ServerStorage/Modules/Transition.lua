-- @ScriptType: ModuleScript
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Transition = {}

local black = nil -- the full-screen Frame, created on first use

local function getBlack()
	if black and black.Parent then
		return black
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "FadeGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 100
	gui.Parent = player:WaitForChild("PlayerGui")

	black = Instance.new("Frame")
	black.Name = "Black"
	black.Size = UDim2.fromScale(1, 1)
	black.BackgroundColor3 = Color3.new(0, 0, 0)
	black.BorderSizePixel = 0
	black.BackgroundTransparency = 1
	black.Parent = gui
	return black
end

local function fadeTo(transparency, seconds)
	local frame = getBlack()
	if not seconds or seconds <= 0 then
		frame.BackgroundTransparency = transparency
		return
	end
	local tween = TweenService:Create(frame, TweenInfo.new(seconds), {BackgroundTransparency = transparency})
	tween:Play()
	tween.Completed:Wait() -- yields until the fade is finished
end

function Transition.setBlack()
	getBlack().BackgroundTransparency = 0
end

function Transition.fadeOut(seconds) -- to black
	fadeTo(0, seconds)
end

function Transition.fadeIn(seconds) -- from black
	fadeTo(1, seconds)
end

return Transition