-- @ScriptType: LocalScript
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Paste your audio asset IDs here: "rbxassetid://" followed by the number.
-- looped = false makes a track play once and stop (default: loops forever).
local TRACKS = {
	Main = {id = "rbxassetid://94986330847008", volume = 0.4},
	Ending = {id = "rbxassetid://1842056877", volume = 0.5},
}
local DEFAULT_TRACK = "Main"
local CROSSFADE = 2 -- seconds for one song to fade out while the next fades in

local currentName = nil  -- which track is playing now
local currentSound = nil -- its Sound object

local function makeSound(track)
	local sound = Instance.new("Sound")
	sound.Name = "Music"
	sound.SoundId = track.id
	sound.Volume = 0 -- fades up to track.volume
	sound.Looped = track.looped ~= false
	sound.Parent = SoundService
	return sound
end

local function fade(sound, toVolume, onDone)
	local tween = TweenService:Create(sound, TweenInfo.new(CROSSFADE), {Volume = toVolume})
	if onDone then
		tween.Completed:Connect(onDone)
	end
	tween:Play()
end

local function setTrack(name)
	local track = TRACKS[name]
	if not track then
		warn("MusicPlayer: no track named " .. tostring(name))
		return
	end
	if name == currentName then
		return -- already playing this one
	end
	currentName = name

	local oldSound = currentSound
	local newSound = makeSound(track)
	currentSound = newSound
	newSound:Play()
	fade(newSound, track.volume)

	if oldSound then
		-- cleanup: the old song fades out, then its Sound is destroyed
		fade(oldSound, 0, function()
			oldSound:Destroy()
		end)
	end
end

-- The server decides which song plays through the "Music" attribute; we only play it
local function applyMusic()
	setTrack(player:GetAttribute("Music") or DEFAULT_TRACK)
end

applyMusic()
player:GetAttributeChangedSignal("Music"):Connect(applyMusic)