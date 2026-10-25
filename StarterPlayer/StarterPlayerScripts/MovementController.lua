-- @ScriptType: LocalScript
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer

-- SETTINGS
local LOCKED_Z = 3.43 -- locking the Z position of the player's HumanoidRootPart
local Z_TOLERANCE = 0.01

-- mobile buttons
local LEFT_IMAGE = "rbxassetid://9637079210"
local RIGHT_IMAGE = "rbxassetid://9637131321"
local JUMP_IMAGE = "rbxassetid://9637136409"

local jumpingon = false -- want the player to jump or not? (change at runtime with setJumpEnabled)

-- STATE
local leftValue, rightValue = 0, 0
local jumping = false


-- Turn off Roblox's default controls so only our bindings work
local function disableDefaultControls()
	local playerScripts = player:WaitForChild("PlayerScripts")
	local playerModule = playerScripts:WaitForChild("PlayerModule", 5) -- 5s timeout, no infinite yield
	if not playerModule then
		return -- default controls aren't running, nothing to disable
	end
	require(playerModule):GetControls():Disable()
end


local function getCharacterParts()
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		return nil
	end
	return humanoid, root
end


-- The Humanoid itself decides whether a jump is possible, whatever asked for it
local function applyJumpState(humanoid)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, jumpingon)
end

-- Runs for the current character and for every respawn
local function setupCharacter(character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid then
		applyJumpState(humanoid)
	end
end


-- Input handlers (Sink stops the key from reaching other bindings)
local function onLeft(actionName, inputState)
	if inputState == Enum.UserInputState.Begin then
		leftValue = 1
	elseif inputState == Enum.UserInputState.End then
		leftValue = 0
	end
	return Enum.ContextActionResult.Sink
end

local function onRight(actionName, inputState)
	if inputState == Enum.UserInputState.Begin then
		rightValue = 1
	elseif inputState == Enum.UserInputState.End then
		rightValue = 0
	end
	return Enum.ContextActionResult.Sink
end

local function onJump(actionName, inputState)
	if not jumpingon then
		return Enum.ContextActionResult.Sink
	end
	if inputState == Enum.UserInputState.Begin then
		jumping = true
	elseif inputState == Enum.UserInputState.End then
		jumping = false
	end
	return Enum.ContextActionResult.Sink
end


-- Per-frame actions
local function applyMovement(humanoid)
	local direction = rightValue - leftValue
	-- X only, false = world space (not relative to the camera)
	humanoid:Move(Vector3.new(direction, 0, 0), false)
end

local function applyJump(humanoid)
	if jumpingon and jumping then
		humanoid.Jump = true
	end
end

local function lockZ(root)
	local offset = LOCKED_Z - root.Position.Z
	if math.abs(offset) > Z_TOLERANCE then
		root.CFrame = root.CFrame + Vector3.new(0, 0, offset)
	end
	-- also kill Z velocity, or physics pushes the character off again next frame
	local velocity = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(velocity.X, velocity.Y, 0)
end

local function onUpdate()
	local humanoid, root = getCharacterParts()
	if not humanoid then
		return
	end
	-- the server sets InCutscene while the story has control of the player
	if player:GetAttribute("InCutscene") then
		humanoid:Move(Vector3.zero, false) -- explicitly stop
		lockZ(root)
		return
	end
	applyMovement(humanoid)
	applyJump(humanoid)
	lockZ(root)
end


-- Jump toggle: the key binding, the mobile button AND the Humanoid's Jumping state
local function setJumpEnabled(enabled)
	jumpingon = enabled
	jumping = false
	if enabled then
		ContextActionService:BindAction("Jump", onJump, true, Enum.KeyCode.Space)
		ContextActionService:SetImage("Jump", JUMP_IMAGE)
		ContextActionService:SetPosition("Jump", UDim2.new(0, 120, 0, 100))
	else
		ContextActionService:UnbindAction("Jump")
	end
	local humanoid = getCharacterParts()
	if humanoid then
		applyJumpState(humanoid)
	end
end


local function bindControls()
	-- true = create an on-screen touch button
	ContextActionService:BindAction("Left", onLeft, true, Enum.KeyCode.A, Enum.KeyCode.Left)
	ContextActionService:BindAction("Right", onRight, true, Enum.KeyCode.D, Enum.KeyCode.Right)

	ContextActionService:SetImage("Left", LEFT_IMAGE)
	ContextActionService:SetImage("Right", RIGHT_IMAGE)

	ContextActionService:SetPosition("Left", UDim2.new(0, 0, 0, 100))
	ContextActionService:SetPosition("Right", UDim2.new(0, 50, 0, 100))

	setJumpEnabled(jumpingon)

	RunService:BindToRenderStep("Control", Enum.RenderPriority.Input.Value, onUpdate)
end


-- START
disableDefaultControls()
bindControls()
if player.Character then
	task.spawn(setupCharacter, player.Character)
end
player.CharacterAdded:Connect(setupCharacter) -- covers every respawn