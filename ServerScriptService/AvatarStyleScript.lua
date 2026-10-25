-- @ScriptType: Script
--[[
	AvatarStyleScript
	When players join (and every time their character spawns/respawns),
	their avatar is set to 0.5 transparency and colored [15, 184, 255].
]]

local Players = game:GetService("Players")

local TRANSPARENCY = 0.75
local AVATAR_COLOR = Color3.fromRGB(15, 184, 255)

-- Applies the style to the character's visible parts.
-- Parts that were originally invisible (like accessory handles) are left
-- alone so they don't appear as blue boxes. The HumanoidRootPart is fully hidden.
local function stylePart(part)
	if not part:IsA("BasePart") then return end
	if part.Name == "HumanoidRootPart" then
		part.Transparency = 1
	elseif part.Transparency < 1 then
		-- Only style parts the avatar is meant to show
		part.Transparency = TRANSPARENCY
		part.Color = AVATAR_COLOR
	end
end

local function styleCharacter(character)
	for _, descendant in character:GetDescendants() do
		stylePart(descendant)
	end

	-- Also style any parts added later (e.g. accessories that finish loading)
	character.DescendantAdded:Connect(stylePart)
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		-- Wait a moment so the character and its accessories finish loading
			task.wait(1)
			if character.Parent then
				styleCharacter(character)
			end
	end)

	-- Handle a character that already exists (e.g. player joined before this script ran)
	if player.Character then
		styleCharacter(player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end