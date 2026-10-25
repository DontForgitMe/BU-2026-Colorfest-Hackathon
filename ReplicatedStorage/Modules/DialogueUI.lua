-- @ScriptType: ModuleScript
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local DialogueUI = {}

local TYPE_DELAY = 0.02 -- seconds per character

local token = 0 -- bumps whenever a new line starts or hide() is called

-- the text box is the TextLabel inside ChoiceGui: the one you and your friend made
local function getParts()
	local gui = player:WaitForChild("PlayerGui"):WaitForChild("ChoiceGui", 5)
	if not gui then
		error("DialogueUI: ChoiceGui not found in PlayerGui")
	end
	return gui, gui:WaitForChild("Frame"), gui:WaitForChild("TextLabel")
end

-- Types a line into the box, holds it for `seconds` once typed, then hides the box.
-- Returns at once; the caller keeps going.
function DialogueUI.say(text, seconds)
	token += 1
	local myToken = token
	local ok, gui, frame, label = pcall(getParts)
	if not ok then
		warn(gui) -- on failure, `gui` holds the error message
		return
	end

	frame.Visible = false -- no buttons for a plain line
	label.Visible = true
	label.Text = text
	label.MaxVisibleGraphemes = 0
	gui.Enabled = true

	task.spawn(function()
		local total = 0
		for _ in utf8.graphemes(label.ContentText) do
			total += 1
		end
		for i = 1, total do
			if token ~= myToken or frame.Visible then
				return -- a newer line took over, or a choice is on screen
			end
			label.MaxVisibleGraphemes = i
			task.wait(TYPE_DELAY)
		end
		label.MaxVisibleGraphemes = -1 -- show everything
		task.wait(seconds or 4)
		if token ~= myToken or frame.Visible then
			return
		end
		label.Text = ""
		gui.Enabled = false
	end)
end

-- Clears the box and stops any line still typing or waiting
function DialogueUI.hide()
	token += 1
	local gui, frame, label = getParts()
	if frame.Visible then
		return -- a choice is on screen: leave it alone
	end
	label.Text = ""
	label.MaxVisibleGraphemes = -1
	gui.Enabled = false
end

return DialogueUI