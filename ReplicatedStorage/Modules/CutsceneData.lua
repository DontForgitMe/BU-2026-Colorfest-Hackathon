-- @ScriptType: ModuleScript
return {
	-- duration: 0 = hard cut, otherwise the camera glides to that part over that many seconds
	-- subtitle `at` = seconds from the START of the cutscene (the subtitle steps all sit at the top)
	-- `seconds` = how long a line is held after it finishes typing (long, so the next line replaces it)
	Intro = {
		{type = "shot", part = "Cam1", fov = 40, duration = 0}, -- instant cut, screen still black

		{type = "subtitle", text = "You are the state-of-the-art prototype Android created by Cyberthon.", at = 0.8, seconds = 10},
		{type = "subtitle", text = "You are the first Android capable of independent thought.", at = 4.0, seconds = 10},
		{type = "subtitle", text = "However, we don’t have time to teach you our moral code.", at = 6.7, seconds = 10},
		{type = "subtitle", text = "An important shipment of goods has been compromised by a terrorist organization with incredible hackers.", at = 9.4, seconds = 10},
		{type = "subtitle", text = "You’re the only one who can save those who are on that train and secure our goods.", at = 14.4, seconds = 10},

		{type = "fade", direction = "in", seconds = 1.5}, -- t = 1.5
		{type = "shot", part = "Cam2", fov = 40, duration = 3}, -- glide, t = 4.5
		{type = "shot", part = "Cam3", fov = 75, duration = 0}, -- cut
		{type = "wait", seconds = 3}, -- t = 7.5
		{type = "shot", part = "Cam4", fov = 50, duration = 0}, -- cut
		{type = "wait", seconds = 2}, -- t = 9.5
		{type = "shot", part = "Cam5", fov = 40, duration = 0}, -- cut
		{type = "shot", part = "Cam6", fov = 40, duration = 4}, -- pan, t = 13.5
		{type = "shot", part = "Cam7", fov = 60, duration = 0}, -- cut
		{type = "shot", part = "Cam8", fov = 60, duration = 4}, -- pan, t = 17.5
		{type = "fade", direction = "out", seconds = 1}, -- ends on black at t = 19; the server teleports next
	},
}