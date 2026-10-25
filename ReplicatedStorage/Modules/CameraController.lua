-- @ScriptType: ModuleScript
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- CurrentCamera can be nil for a moment right at startup
local camera = workspace.CurrentCamera
while not camera do
	workspace:GetPropertyChangedSignal("CurrentCamera"):Wait()
	camera = workspace.CurrentCamera
end

local CameraController = {}

-- SETTINGS
local EASING_SPEED = 0.5 -- 0 to 1: how fast FOV eases (zoom and mode changes). 1 = instant
local ZOOM_FACTOR = 0.7  -- zoomed-in FOV = the mode's FOV * this (your old 35/50)

local MODES = {
	Centered = {
		offset = Vector3.new(0, 10, 30),   -- camera position relative to the character
		lookOffset = Vector3.new(0, 0, 0), -- aim point relative to the character
		screenX = 0,                       -- -1 = left edge, 0 = center, 1 = right edge
		fov = 50,
	},
	LeftFraming = {
		offset = Vector3.new(0, 10, 30),
		lookOffset = Vector3.new(0, 0, 0),
		screenX = -1 / 3,                  -- left-third line
		fov = 35,
	},
}

-- STATE
local currentMode = "Centered"
local currentFOV = MODES[currentMode].fov
local zoomedIn = false
local canZoom = true
local inCutscene = false
local started = false

local function getTargetFOV()
	local mode = MODES[currentMode]
	if zoomedIn then
		return mode.fov * ZOOM_FACTOR
	end
	return mode.fov
end

-- Studs to aim off the character (world X) so it lands at mode.screenX.
-- Aiming right pushes the character left, hence the minus sign.
local function getFramingShift(mode)
	local distance = mode.offset.Magnitude
	local aspect = camera.ViewportSize.X / camera.ViewportSize.Y
	local halfWidth = distance * math.tan(math.rad(camera.FieldOfView / 2)) * aspect
	return -mode.screenX * halfWidth
end

local function updateFOV(dt)
	local target = getTargetFOV()
	local alpha = 1 - (1 - EASING_SPEED) ^ (dt * 20) -- dt * 20 matches your old 20 steps/second
	currentFOV = currentFOV + (target - currentFOV) * alpha
	if math.abs(target - currentFOV) < 0.05 then
		currentFOV = target
	end
	camera.FieldOfView = currentFOV
end

local function updateCameraPosition()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local mode = MODES[currentMode]
	local rootPos = root.Position
	local aimPoint = rootPos + mode.lookOffset + Vector3.new(getFramingShift(mode), 0, 0)
	camera.CFrame = CFrame.new(rootPos + mode.offset, aimPoint)
end

local function onInputChanged(input, gameProcessed)
	if gameProcessed or not canZoom then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseWheel then
		return
	end
	zoomedIn = input.Position.Z > 0 -- scroll up = zoom in, down = zoom out
end

-- PUBLIC API
function CameraController.setMode(name)
	if not MODES[name] then
		warn("Unknown camera mode: " .. tostring(name))
		return
	end
	currentMode = name
end

function CameraController.setZoomEnabled(enabled)
	canZoom = enabled
	if not enabled then
		zoomedIn = false
	end
end

-- Cutscene API: the follow loop pauses so cutscene code is the only writer
function CameraController.beginCutscene()
	inCutscene = true
	zoomedIn = false
end

-- Yields until the camera arrives. fov is optional; duration 0 = instant cut
function CameraController.moveTo(cf, fov, duration)
	if not inCutscene then
		warn("CameraController.moveTo called before beginCutscene()")
		return
	end
	local goal = {CFrame = cf}
	if fov then
		goal.FieldOfView = fov
	end
	if duration and duration > 0 then
		local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
		local tween = TweenService:Create(camera, info, goal)
		tween:Play()
		tween.Completed:Wait()
	else
		camera.CFrame = cf
		if fov then
			camera.FieldOfView = fov
		end
	end
end

function CameraController.endCutscene()
	currentFOV = camera.FieldOfView -- ease back from wherever the cutscene left it
	inCutscene = false
end

function CameraController.start()
	if started then
		return
	end
	started = true
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfViewMode = Enum.FieldOfViewMode.Vertical
	camera.FieldOfView = currentFOV
	UserInputService.InputChanged:Connect(onInputChanged)
	RunService.RenderStepped:Connect(function(dt)
		-- safety: if anything switched the camera back to a default type, take it back
		if camera.CameraType ~= Enum.CameraType.Scriptable then
			camera.CameraType = Enum.CameraType.Scriptable
		end
		if inCutscene then
			return
		end
		updateFOV(dt)
		updateCameraPosition()
	end)
end

return CameraController