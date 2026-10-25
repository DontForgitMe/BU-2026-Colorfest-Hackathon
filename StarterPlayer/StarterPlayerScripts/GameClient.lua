-- @ScriptType: LocalScript
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

---------------------------------------------------------------- 1. Fade overlay
local black = nil -- full-screen Frame, created on first use (lives all session)

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

-- transparency 0 = fully black, 1 = clear. Yields until the fade is done.
local function fadeTo(transparency, seconds)
	local frame = getBlack()
	if not seconds or seconds <= 0 then
		frame.BackgroundTransparency = transparency
		return
	end
	local tween = TweenService:Create(frame, TweenInfo.new(seconds), {BackgroundTransparency = transparency})
	tween:Play()
	tween.Completed:Wait()
end

fadeTo(0, 0) -- cover the screen right away, before anything else loads

-- Moves the black overlay above (true) or below (false) every other GUI.
-- Below = text boxes show ON TOP of the black, which the ending needs.
local function setFadeOnTop(onTop)
	getBlack().Parent.DisplayOrder = onTop and 100 or -1
end

---------------------------------------------------------------- 2. Modules and camera
local events = ReplicatedStorage:WaitForChild("Events")
local doEvent = events:WaitForChild("Do")
local doneEvent = events:WaitForChild("Done")
local clientReady = events:WaitForChild("ClientReady")

local modules = ReplicatedStorage:WaitForChild("Modules")
local CameraController = require(modules:WaitForChild("CameraController"))
local CutsceneData = require(modules:WaitForChild("CutsceneData"))
local ChoiceUI = require(modules:WaitForChild("ChoiceUI"))
local DialogueUI = require(modules:WaitForChild("DialogueUI"))

CameraController.start()

-- The server decides the framing through an Attribute; we only display it
local function applyCameraMode()
	local mode = player:GetAttribute("CameraMode")
	if mode then
		CameraController.setMode(mode)
	end
end
applyCameraMode()
player:GetAttributeChangedSignal("CameraMode"):Connect(applyCameraMode)

-- TEMP debug: 1 = Centered, 2 = LeftFraming. Delete later.
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

---------------------------------------------------------------- 3. Disable the reset button
-- SetCore throws until the CoreGui has loaded, so retry in the background
task.spawn(function()
	for _ = 1, 20 do
		local ok = pcall(function()
			StarterGui:SetCore("ResetButtonCallback", false)
		end)
		if ok then
			return
		end
		task.wait(0.5)
	end
	warn("Could not disable the reset button")
end)

---------------------------------------------------------------- 4. Cutscene steps
-- Every handler gets (step, folder, context). context carries the choice and the subtitle timers.
local stepHandlers = {}

function stepHandlers.shot(step, folder)
	local cam = folder and folder:FindFirstChild(step.part)
	if not cam then
		error("shot part '" .. tostring(step.part) .. "' not found")
	end
	CameraController.moveTo(cam:GetPivot(), step.fov, step.duration)
end

function stepHandlers.wait(step)
	task.wait(step.seconds)
end

function stepHandlers.fade(step)
	if step.direction == "out" then
		fadeTo(0, step.seconds)
	else
		fadeTo(1, step.seconds)
	end
end

-- the scenario text and buttons appear now, WHILE the cutscene keeps playing
function stepHandlers.choice(step, folder, context)
	context.startChoice()
end

-- A line of text in the blue box. `at` = seconds from now before it appears (default 0).
-- It returns at once, so the shots keep playing. The timer is remembered so the cutscene
-- can cancel it if it ends first.
function stepHandlers.subtitle(step, folder, context)
	local timer = task.delay(step.at or 0, DialogueUI.say, step.text, step.seconds)
	table.insert(context.timers, timer)
end

local playing = false

-- Plays a cutscene. If dilemmaId is given, the choice is shown DURING the cutscene and the
-- player's pick (an option id) is returned. The camera holds on the last shot until they pick.
local function playCutscene(id, dilemmaId)
	if playing then
		return nil
	end
	local steps = CutsceneData[id]
	if not steps then
		warn("No cutscene data for id: " .. tostring(id))
		return nil
	end
	playing = true

	local cutscenes = workspace:FindFirstChild("Cutscenes")
	local folder = cutscenes and cutscenes:FindFirstChild(id)

	-- the choice that runs alongside the cutscene, plus the timers for delayed subtitles
	local context = {
		started = false,
		finished = false,
		result = nil,
		signal = Instance.new("BindableEvent"),
		timers = {},
	}
	function context.startChoice()
		if not dilemmaId or context.started then
			return -- no choice for this cutscene, or already showing
		end
		context.started = true
		task.spawn(function()
			local ok, picked = pcall(ChoiceUI.ask, dilemmaId) -- yields until a button is pressed
			if ok then
				context.result = picked
			else
				warn("Choice failed: " .. tostring(picked))
			end
			context.finished = true
			context.signal:Fire()
		end)
	end

	-- no explicit {type = "choice"} step: show the choice as the cutscene starts
	local hasChoiceStep = false
	for _, step in ipairs(steps) do
		if step.type == "choice" then
			hasChoiceStep = true
			break
		end
	end
	if not hasChoiceStep then
		context.startChoice()
	end

	CameraController.beginCutscene()
	local ok, err = pcall(function()
		for _, step in ipairs(steps) do
			local handler = stepHandlers[step.type]
			if not handler then
				error("unknown step type: " .. tostring(step.type))
			end
			handler(step, folder, context)
		end
	end)
	if not ok then
		warn("Cutscene '" .. id .. "' failed: " .. tostring(err))
	end

	-- the camera holds on the last shot until the player has picked
	if dilemmaId then
		context.startChoice() -- no-op if it already started
		if not context.finished then
			context.signal.Event:Wait()
		end
	end

	-- cleanup lives after the pcall, not inside the steps
	for _, timer in ipairs(context.timers) do
		pcall(task.cancel, timer) -- a delayed subtitle that hasn't fired yet must not fire later
	end
	CameraController.endCutscene()
	context.signal:Destroy()
	playing = false
	local hideOk, hideErr = pcall(DialogueUI.hide) -- last, so a DialogueUI problem can't skip the rest
	if not hideOk then
		warn("DialogueUI.hide failed: " .. tostring(hideErr))
	end
	return context.result
end

---------------------------------------------------------------- 5. The glowing line to the End (client-only decoration)
local guideLine = nil  -- the neon Part on the floor
local guideTween = nil -- its slow pulse

-- removes the line and stops its pulse; safe to call any time
local function clearGuide()
	if guideTween then
		guideTween:Cancel()
		guideTween = nil
	end
	if guideLine then
		guideLine:Destroy()
		guideLine = nil
	end
end

-- Draws a pulsing neon line on the floor from the player to the End zone
local function showGuideToEnd()
	clearGuide()
	local scenarios = workspace:FindFirstChild("Scenarios")
	local endPart = scenarios and scenarios:FindFirstChild("End")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not endPart or not root then
		warn("showGuideToEnd: no End zone in Workspace/Scenarios, or no character")
		return
	end

	-- find the floor under the player
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -20, 0), params)
	local floorY = hit and hit.Position.Y or (root.Position.Y - 3)

	local startX = root.Position.X
	local endX = endPart:GetPivot().Position.X
	local length = math.max(math.abs(endX - startX), 1)

	local line = Instance.new("Part")
	line.Name = "GuideToEnd"
	line.Anchored = true
	line.CanCollide = false
	line.CanQuery = false
	line.CanTouch = false
	line.CastShadow = false
	line.Material = Enum.Material.Neon
	line.Color = Color3.fromRGB(0, 200, 255)
	line.Size = Vector3.new(length, 0.15, 1)
	line.Position = Vector3.new((startX + endX) / 2, floorY + 0.1, root.Position.Z)
	line.Parent = workspace
	guideLine = line

	-- a slow pulse so it reads as a guide (repeat -1 = forever, true = reverse each time)
	guideTween = TweenService:Create(
		line,
		TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{Transparency = 0.6}
	)
	guideTween:Play()
end

---------------------------------------------------------------- 6. Steps the server asks for
local handlers = {}

-- data is either a cutscene id ("Intro") or {id = "Cart1", dilemma = "Ch1_1"}
function handlers.cutscene(data)
	if type(data) == "table" then
		return playCutscene(data.id, data.dilemma)
	end
	return playCutscene(data)
end

function handlers.fadeOut()
	fadeTo(0, 1)
end

function handlers.fadeIn()
	fadeTo(1, 1)
end

-- a choice with no cutscene behind it (what every cart uses for now)
function handlers.choice(dilemmaId)
	return ChoiceUI.ask(dilemmaId)
end

-- Option 4 was picked: draw the glowing line to the End and show a short hint
function handlers.guide()
	showGuideToEnd()
	DialogueUI.say("Your objective is waiting at the end of the train.", 4)
end

-- data = {lines = {...}, title = "..."}: fade to black, show the lines one by one,
-- then leave the final card on screen
function handlers.ending(data)
	clearGuide() -- the line has done its job
	fadeTo(0, 2) -- to black
	setFadeOnTop(false) -- the blue box now shows above the black
	task.wait(1)
	for _, line in ipairs(data.lines) do
		DialogueUI.say(line, 30) -- the next line replaces it
		local length = utf8.len(line) or #line
		task.wait(length * 0.02 + length / 20 + 1) -- typing time plus reading time
	end
	DialogueUI.say("You are: " .. data.title, 9999) -- the final card stays up
	task.wait(3)
end

doEvent.OnClientEvent:Connect(function(token, kind, data)
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
	doneEvent:FireServer(token, result) -- always answer, so the server never hangs
end)

clientReady:FireServer() -- listeners are connected, safe to start