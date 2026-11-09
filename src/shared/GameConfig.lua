--[[
	GameConfig — EVERYTHING YOU'LL WANT TO PERSONALIZE LIVES HERE.

	Each entry in `Stages` is one checkpoint. Reaching that checkpoint unlocks
	its reward card (a note, and optionally a photo).

	Photos: upload an image in Studio (Asset Manager -> Images, or
	Creator Dashboard -> Development Items -> Decals), copy its *image* ID,
	and put it here as "rbxassetid://123456789". Leave it as "" for a
	note-only card.

	Stage 1 is the spawn, so its reward is the welcome card.
	The last stage is the finish line and shows the finale.
]]

local GameConfig = {}

GameConfig.Title = "Our Sky Path"
GameConfig.Subtitle = "every checkpoint has a little secret ✨"

-- Changing the seed reshuffles the obstacle course layout.
GameConfig.Seed = 1402

-- Height the course floats at (studs).
GameConfig.CourseHeight = 120

-- Optional sound IDs ("rbxassetid://..."). Pick them from the Toolbox
-- audio library in Studio. Leave "" to skip.
GameConfig.Sounds = {
	Unlock = "",
	Music = "",
}

-- Colors used for platforms, in order. Change to her favorites!
GameConfig.Palette = {
	Color3.fromRGB(255, 183, 197), -- pink
	Color3.fromRGB(186, 225, 255), -- baby blue
	Color3.fromRGB(205, 180, 255), -- lavender
	Color3.fromRGB(255, 223, 186), -- peach
	Color3.fromRGB(186, 255, 201), -- mint
}
GameConfig.AccentColor = Color3.fromRGB(255, 105, 180) -- neon hot pink

--[[
	difficulty: 1 (easy) to 5 (hard). Controls gap sizes and which
	obstacles can appear in the section *after* this checkpoint.
]]
GameConfig.Stages = {
	{
		name = "Welcome",
		difficulty = 1,
		reward = {
			title = "Hi you 💗",
			note = "I made this whole sky just for you. Every checkpoint has something hidden in it. Take your time!",
			image = "",
		},
	},
	{
		name = "First Steps",
		difficulty = 1,
		reward = {
			title = "Where it started",
			note = "[Write about the day you met here]",
			image = "",
		},
	},
	{
		name = "Cotton Candy",
		difficulty = 2,
		reward = {
			title = "Our first date",
			note = "[Write about your first date here]",
			image = "",
		},
	},
	{
		name = "Drift",
		difficulty = 2,
		reward = {
			title = "That one inside joke",
			note = "[Put an inside joke here]",
			image = "",
		},
	},
	{
		name = "Spin Cycle",
		difficulty = 3,
		reward = {
			title = "Favorite photo",
			note = "[Caption for a favorite photo]",
			image = "",
		},
	},
	{
		name = "Vanishing Clouds",
		difficulty = 3,
		reward = {
			title = "Things I love about you",
			note = "[List a few things here]",
			image = "",
		},
	},
	{
		name = "Starlight",
		difficulty = 4,
		reward = {
			title = "Our place",
			note = "[Write about a place that's yours]",
			image = "",
		},
	},
	{
		name = "Almost There",
		difficulty = 5,
		reward = {
			title = "Keep going…",
			note = "[A little encouragement before the end]",
			image = "",
		},
	},
	{
		name = "The Top",
		difficulty = 5,
		finale = true,
		reward = {
			title = "You made it 💖",
			note = "[Write your final letter here. This one types out slowly, so make it count.]",
			image = "",
		},
	},
}

return GameConfig
