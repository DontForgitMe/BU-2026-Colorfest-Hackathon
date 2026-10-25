-- @ScriptType: LocalScript
-- LocalScript inside StarterPlayerScripts that controls player's 2D Camera
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer
local camera = game.Workspace.CurrentCamera

-- Camera settings & Easing
local easingSpeed = 0.5
local currentFOV = 40
local targetFOV = 30

-- Modes definition
local MODES = {
	Centered = {
		offset = Vector3.new(0, 15, 45, false),   -- Camera position relative to the character
		lookOffset = Vector3.new(0, 0, 0, false), -- Point the camera aims at
		defaultFOV = 40,
		zoomedFOV = 30,
		canZoom = true,
	},
	LeftFraming = {
		offset = Vector3.new(6, 10, 30, false),   -- Shifted right so player is on the left third
		lookOffset = Vector3.new(2, 0, 0, false), -- Offset look target to balance framing
		fov = 40,                          -- Fixed singular POV
		canZoom = false,                   -- Zoom disabled for this mode
	},
}

local currentMode = "Centered" -- Set your active mode here ("Centered" or "LeftFraming")
local zoomingIn = false
local zoomingOut = false

-- Apply initial mode FOV settings
local function applyModeSettings()
	local modeData = MODES[currentMode]
	if modeData.canZoom then
		targetFOV = modeData.defaultFOV
	else
		targetFOV = modeData.fov
	end
	currentFOV = targetFOV
	camera.FieldOfView = currentFOV
end

-- Set initial camera properties
camera.CameraType = Enum.CameraType.Scriptable
applyModeSettings()

-- Update camera position and look target based on the active mode
local function updateCameraPosition()
	local character = player.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local modeData = MODES[currentMode]
			local targetPos = humanoidRootPart.Position + modeData.lookOffset
			local camPos = humanoidRootPart.Position + modeData.offset

			camera.CFrame = CFrame.new(camPos, targetPos)
		end
	end
end

-- Smoothly adjust the FOV (used by Centered mode)
local function adjustFOV()
	while math.abs(camera.FieldOfView - targetFOV) > 0.1 do
		if targetFOV < currentFOV then
			currentFOV = math.max(currentFOV - (easingSpeed * (currentFOV - targetFOV)), targetFOV)
		elseif targetFOV > currentFOV then
			currentFOV = math.min(currentFOV + (easingSpeed * (targetFOV - currentFOV)), targetFOV)
		end
		camera.FieldOfView = currentFOV
		task.wait(0.05)
	end
	zoomingIn = false
	zoomingOut = false
end

-- Handle zoom input via MouseWheel (respects canZoom flag)
local function onInputChanged(input)
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		local modeData = MODES[currentMode]

		-- If this mode doesn't allow zooming, ignore input entirely
		if not modeData.canZoom then return end

		if input.Position.Z > 0 then
			-- Scroll up, zoom in
			if not zoomingIn then
				targetFOV = modeData.zoomedFOV
				zoomingIn = true
				zoomingOut = false
				task.spawn(adjustFOV)
			end
		else
			-- Scroll down, zoom out
			if not zoomingOut then
				targetFOV = modeData.defaultFOV
				zoomingOut = true
				zoomingIn = false
				task.spawn(adjustFOV)
			end
		end
	end
end

UserInputService.InputChanged:Connect(onInputChanged)

-- Maintain camera position each frame
RunService.RenderStepped:Connect(function()
	updateCameraPosition()
end)