-- @ScriptType: ModuleScript
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DilemmaData = require(script.Parent:WaitForChild("DilemmaData"))

-- Tells the server to explode an Android model (handled in TouchFreezeScript)
local unanchorAndroidEvent = ReplicatedStorage:FindFirstChild("UnanchorAndroidEvent")

local player = Players.LocalPlayer
local ChoiceUI = {}

local BUTTON_NAMES = {"Option 1", "Option 2", "Option 3", "Option 4"}
local OPTION_IDS = {"a", "b", "programming", "objective"} -- same order as the buttons

-- Shows the dilemma and YIELDS until a button is pressed. Returns the option id.
function ChoiceUI.ask(dilemmaId)
	local record = DilemmaData.byId[dilemmaId]
	if not record then
		error("ChoiceUI: unknown dilemma " .. tostring(dilemmaId))
	end
	local gui = player:WaitForChild("PlayerGui"):WaitForChild("ChoiceGui", 5)
	if not gui then
		error("ChoiceUI: ChoiceGui not found in PlayerGui (rename your ScreenGui)")
	end
	local frame = gui:WaitForChild("Frame")
	local textLabel = gui:WaitForChild("TextLabel")

	local buttons = {}
	for i, name in ipairs(BUTTON_NAMES) do
		buttons[i] = frame:WaitForChild(name)
	end

	-- the old scripts hid these, and a typed line can leave the text partly hidden: reset them
	textLabel.MaxVisibleGraphemes = -1
	textLabel.Text = record.prompt
	textLabel.Visible = true
	buttons[1].Text = record.a
	buttons[2].Text = record.b
	for _, button in ipairs(buttons) do
		button.Visible = true
	end
	frame.Visible = true

	local answer = Instance.new("BindableEvent")
	local connections = {}
	local pickedIndex = 0
	for i, button in ipairs(buttons) do
		connections[i] = button.MouseButton1Click:Connect(function()
			pickedIndex = i
			answer:Fire(OPTION_IDS[i])
		end)
	end

	gui.Enabled = true
	local picked = answer.Event:Wait()

	-- If the player picked "Forcefully terminate the android", tell the server
	-- to explode the Android model for this scenario. Only buttons 1 and 2 are
	-- checked because their text is freshly set for this dilemma; buttons 3 and
	-- 4 may still carry text from an earlier dilemma.
	if unanchorAndroidEvent and pickedIndex <= 2 then
		local text = string.lower(buttons[pickedIndex].Text)
		if string.find(text, "forcefully terminate the android") then
			-- Chapter 1 dilemma Ch1_N happens at zone ScenarioN, which sits next
			-- to Android model N in Workspace.Android.
			if record.chapter == 1 then
				unanchorAndroidEvent:FireServer(record.number)
			end
		end
	end

	-- cleanup: disconnect, destroy, hide
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	answer:Destroy()
	frame.Visible = false
	textLabel.Text = ""
	gui.Enabled = false
	return picked
end

return ChoiceUI