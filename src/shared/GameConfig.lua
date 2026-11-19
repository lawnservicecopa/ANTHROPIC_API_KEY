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
		name = "FOMO",
		difficulty = 1,
		reward = {
			title = "Where it started",
			note = "We met at a club in downtown Houston called FOMO, where we were with a bunch of our friends and just started talking.",
			image = "", -- photo idea: IMG_1582 (selfie under the vines)
		},
	},
	{
		name = "Galveston",
		difficulty = 2,
		reward = {
			title = "Our first date",
			note = "Our first date was with my family at Galveston beach, where we played in the water, went to eat and saw her people.",
			image = "", -- photo idea: IMG_1125 (beach)
		},
	},
	{
		name = "On Wallahi",
		difficulty = 2,
		reward = {
			title = "That one inside joke",
			note = "On wallahi",
			image = "",
		},
	},
	{
		name = "Cozy",
		difficulty = 3,
		reward = {
			title = "Favorite photo",
			note = "Laying in John’s bed",
			image = "", -- photo idea: the purple-lights photo
		},
	},
	{
		name = "Her Smile",
		difficulty = 3,
		reward = {
			title = "Things I love about you",
			note = "Her energy, her love, her smile, her laugh, her drive towards God",
			image = "", -- photo idea: IMG_8332 (holding hands downtown)
		},
	},
	{
		name = "The Gym",
		difficulty = 4,
		reward = {
			title = "Our place",
			note = "The gym",
			image = "", -- photo idea: IMG_0799 (gym mirror)
		},
	},
	{
		name = "Never Back Down",
		difficulty = 5,
		reward = {
			title = "Keep going…",
			note = "Never back down never what?",
			image = "",
		},
	},
	{
		name = "The Top",
		difficulty = 5,
		finale = true,
		reward = {
			title = "You made it 💖",
			note = "To the stinkiest loving girl I know, thank you for playing my game. I’ll always love you to every angle and back. You are what keeps me going and what motivates me to be a better version of myself. Keep going and driving for what you want I promise the world is going to be ours.",
			image = "",
		},
	},
}

return GameConfig
