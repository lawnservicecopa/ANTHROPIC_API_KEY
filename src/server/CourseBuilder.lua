--[[
	CourseBuilder — generates the whole sky obby from GameConfig.

	The course runs along +Z. A "cursor" tracks the far edge (top-center) of the
	last thing placed, and each new piece is placed a gap ahead of it.

	Tags used (CollectionService):
	  "Kill"    touching it sends you back to your checkpoint (Hazards.lua)
	  "Fade"    platform that vanishes shortly after you step on it (Hazards.lua)
	  "Floaty"  decoration that bobs and spins on the client (client/Floaty.lua)
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local CourseBuilder = {}

local MAX_SIDEWAYS = 24 -- keep the course inside a band this wide on X

local rng: Random
local folder: Folder
local cursor: Vector3
local paletteIndex = 0

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function nextColor(): Color3
	paletteIndex = paletteIndex % #GameConfig.Palette + 1
	return GameConfig.Palette[paletteIndex]
end

local function newPart(className: string?, parent: Instance?): BasePart
	local part = Instance.new(className or "Part") :: BasePart
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = parent or folder
	return part
end

-- Places a box `gap` studs ahead of the cursor. `rise` raises/lowers its top
-- surface and `sideways` shifts it on X. Moves the cursor to its far edge.
local function place(size: Vector3, gap: number, rise: number, sideways: number): BasePart
	local x = math.clamp(cursor.X + sideways, -MAX_SIDEWAYS, MAX_SIDEWAYS)
	local top = cursor.Y + rise
	local part = newPart()
	part.Size = size
	part.Position = Vector3.new(x, top - size.Y / 2, cursor.Z + gap + size.Z / 2)
	part.Color = nextColor()
	cursor = Vector3.new(x, top, cursor.Z + gap + size.Z)
	return part
end

-- Gap/size tuning per difficulty (1..5). A default character (JumpPower 50,
-- WalkSpeed 16, gravity 196.2) is airborne ~0.5s, about 8 studs of travel on
-- flat ground and less when jumping upward, so gaps top out around 6.7 studs.
local function gapFor(difficulty: number): number
	return 2.5 + difficulty * 0.6 + rng:NextNumber(0, 1.2)
end

local function widthFor(difficulty: number): number
	return math.max(3.5, 8 - difficulty * 0.8)
end

local function riseFor(): number
	return rng:NextNumber(-1, 1.5)
end

local function sidewaysFor(difficulty: number): number
	local s = 2 + difficulty
	return rng:NextNumber(-s, s)
end

local function addFloatyOrb(position: Vector3, size: number)
	local orb = newPart()
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.one * size
	orb.Position = position
	orb.Material = Enum.Material.Neon
	orb.Color = GameConfig.AccentColor
	orb.CanCollide = false
	orb.CanTouch = false
	orb.CanQuery = false
	orb.CastShadow = false

	local light = Instance.new("PointLight")
	light.Color = GameConfig.AccentColor
	light.Range = 14
	light.Brightness = 1.5
	light.Parent = orb

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Color = ColorSequence.new(Color3.new(1, 1, 1), GameConfig.AccentColor)
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new(0.4, 0)
	sparkles.Lifetime = NumberRange.new(1, 2)
	sparkles.Rate = 6
	sparkles.Speed = NumberRange.new(1, 2)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Parent = orb

	CollectionService:AddTag(orb, "Floaty")
	return orb
end

local function addLabel(parent: BasePart, text: string, offsetY: number)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(200, 50)
	gui.StudsOffset = Vector3.new(0, offsetY, 0)
	gui.MaxDistance = 120
	gui.AlwaysOnTop = false
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.TextStrokeColor3 = GameConfig.AccentColor
	label.Parent = gui
end

--------------------------------------------------------------------------------
-- Obstacle sections (each starts at the cursor and leaves it at its end)
--------------------------------------------------------------------------------

local Sections = {}

-- Plain jumps between floating platforms.
function Sections.jumps(difficulty: number)
	for _ = 1, 4 + difficulty do
		local w = widthFor(difficulty)
		place(Vector3.new(w, 1.5, w), gapFor(difficulty), riseFor(), sidewaysFor(difficulty))
	end
end

-- Platforms that slide side to side. Built with physics constraints (not
-- tweens) so players standing on them get carried along.
function Sections.moving(difficulty: number)
	for _ = 1, 2 + math.floor(difficulty / 2) do
		local w = widthFor(difficulty) + 1
		local range = 6 + difficulty
		local speed = 5 + difficulty

		-- Anchored, invisible rail the platform slides along.
		local rail = place(Vector3.new(w, 1.5, w), gapFor(difficulty) - 1, rng:NextNumber(-0.5, 1), 0)
		rail.Transparency = 1
		rail.CanCollide = false
		rail.CanTouch = false
		rail.CanQuery = false

		local platform = newPart()
		platform.Size = rail.Size
		platform.CFrame = rail.CFrame
		platform.Color = rail.Color
		platform.Material = Enum.Material.Glass
		platform.Transparency = 0.15
		platform.Anchored = false

		local a0 = Instance.new("Attachment")
		a0.Parent = rail
		local a1 = Instance.new("Attachment")
		a1.Parent = platform

		local slider = Instance.new("PrismaticConstraint") -- slides along attachment X axis
		slider.Attachment0 = a0
		slider.Attachment1 = a1
		slider.ActuatorType = Enum.ActuatorType.Servo
		slider.ServoMaxForce = 1e7
		slider.Speed = speed
		slider.LimitsEnabled = true
		slider.LowerLimit = -range
		slider.UpperLimit = range
		slider.Parent = platform

		platform:SetNetworkOwner(nil) -- server simulates it so everyone sees the same thing

		local startSide = if rng:NextNumber() < 0.5 then -1 else 1
		task.spawn(function()
			local target = range * startSide
			while platform.Parent do
				slider.TargetPosition = target
				task.wait(2 * range / speed + 0.8)
				target = -target
			end
		end)
	end
end

-- A wide platform with a spinning sweeper bar to jump over.
function Sections.spinner(difficulty: number)
	local size = 22
	local floor = place(Vector3.new(size, 1.5, size), gapFor(difficulty), riseFor(), 0)
	local center = floor.Position + Vector3.new(0, floor.Size.Y / 2 + 2.5, 0)

	local pivot = newPart()
	pivot.Size = Vector3.one
	pivot.Position = center
	pivot.Transparency = 1
	pivot.CanCollide = false
	pivot.CanTouch = false
	pivot.CanQuery = false

	local bar = newPart()
	bar.Size = Vector3.new(size - 2, 1.2, 1.2)
	bar.Position = center
	bar.Material = Enum.Material.Neon
	bar.Color = GameConfig.AccentColor
	bar.Anchored = false

	local a0 = Instance.new("Attachment")
	a0.Axis = Vector3.yAxis
	a0.SecondaryAxis = Vector3.xAxis
	a0.Parent = pivot
	local a1 = Instance.new("Attachment")
	a1.Axis = Vector3.yAxis
	a1.SecondaryAxis = Vector3.xAxis
	a1.Parent = bar

	local hinge = Instance.new("HingeConstraint")
	hinge.Attachment0 = a0
	hinge.Attachment1 = a1
	hinge.ActuatorType = Enum.ActuatorType.Motor
	hinge.AngularVelocity = 1.2 + difficulty * 0.3
	hinge.MotorMaxTorque = 1e9
	hinge.MotorMaxAcceleration = math.huge
	hinge.Parent = bar

	bar:SetNetworkOwner(nil)
end

-- Cloud platforms that vanish a moment after you land on them.
function Sections.fade(difficulty: number)
	for _ = 1, 4 + math.floor(difficulty / 2) do
		local w = widthFor(difficulty) + 1
		local p =
			place(Vector3.new(w, 1.2, w), gapFor(difficulty) - 1, rng:NextNumber(-0.5, 1.5), sidewaysFor(1))
		p.Color = Color3.fromRGB(255, 255, 255)
		p.Material = Enum.Material.SmoothPlastic
		CollectionService:AddTag(p, "Fade")
	end
end

-- A walkway crossed by glowing "laser" strips you have to hop over.
function Sections.lasers(difficulty: number)
	local strips = 3 + difficulty
	local spacing = 7
	local walk = place(Vector3.new(10, 1.5, strips * spacing + 6), gapFor(difficulty), riseFor(), 0)
	local startZ = walk.Position.Z - walk.Size.Z / 2 + 6
	local topY = walk.Position.Y + walk.Size.Y / 2

	for i = 0, strips - 1 do
		local laser = newPart()
		laser.Size = Vector3.new(walk.Size.X, 1.2, 1.2)
		laser.Position = Vector3.new(walk.Position.X, topY + 0.6, startZ + i * spacing)
		laser.Material = Enum.Material.Neon
		laser.Color = GameConfig.AccentColor
		laser.CanCollide = false
		laser.CastShadow = false
		CollectionService:AddTag(laser, "Kill")
	end
end

local SECTIONS_BY_DIFFICULTY = {
	[1] = { "jumps" },
	[2] = { "jumps", "moving", "lasers" },
	[3] = { "jumps", "moving", "lasers", "spinner", "fade" },
	[4] = { "jumps", "moving", "lasers", "spinner", "fade" },
	[5] = { "jumps", "moving", "lasers", "spinner", "fade" },
}

--------------------------------------------------------------------------------
-- Checkpoints and scenery
--------------------------------------------------------------------------------

local function buildCheckpoint(index: number, stage, isFirst: boolean, isLast: boolean): BasePart
	local size = if isLast then 30 else 16
	local pad: BasePart
	if isFirst then
		local spawn = newPart("SpawnLocation") :: SpawnLocation
		spawn.Neutral = true
		spawn.Duration = 0 -- no forcefield bubble
		pad = spawn
		pad.Size = Vector3.new(size, 1.5, size)
		pad.Position = cursor + Vector3.new(0, -0.75, size / 2)
		cursor = Vector3.new(cursor.X, cursor.Y, cursor.Z + size)
	else
		pad = place(Vector3.new(size, 1.5, size), gapFor(1), riseFor(), 0)
	end

	pad.Name = string.format("Checkpoint%02d", index)
	pad.Color = Color3.fromRGB(255, 248, 252)
	pad:SetAttribute("Stage", index)

	-- Glowing trim so checkpoints are easy to spot from far away.
	local trim = newPart()
	trim.Size = Vector3.new(size + 0.6, 0.4, size + 0.6)
	trim.CFrame = pad.CFrame * CFrame.new(0, -pad.Size.Y / 2, 0)
	trim.Material = Enum.Material.Neon
	trim.Color = GameConfig.AccentColor
	trim.CanCollide = false
	trim.CanTouch = false
	trim.CastShadow = false

	local orbSize = if isLast then 6 else 3
	local orb = addFloatyOrb(pad.Position + Vector3.new(0, 6, 0), orbSize)
	local label = if isLast then "💖 " .. stage.name else string.format("✨ %d · %s", index, stage.name)
	addLabel(orb, label, orbSize / 2 + 2)

	return pad
end

local function scatterClouds(fromZ: number, toZ: number)
	local cloudFolder = Instance.new("Folder")
	cloudFolder.Name = "Scenery"
	cloudFolder.Parent = folder

	for z = fromZ - 100, toZ + 100, 45 do
		for _, side in { -1, 1 } do
			local origin = Vector3.new(
				side * rng:NextNumber(60, 130),
				GameConfig.CourseHeight - rng:NextNumber(25, 70),
				z + rng:NextNumber(-15, 15)
			)
			for _ = 1, rng:NextInteger(3, 5) do
				local puff = newPart(nil, cloudFolder)
				puff.Shape = Enum.PartType.Ball
				puff.Size = Vector3.one * rng:NextNumber(12, 26)
				puff.Position = origin
					+ Vector3.new(rng:NextNumber(-14, 14), rng:NextNumber(-4, 4), rng:NextNumber(-14, 14))
				puff.Color = Color3.fromRGB(255, 250, 252)
				puff.Transparency = 0.1
				puff.CanCollide = false
				puff.CanTouch = false
				puff.CanQuery = false
				puff.CastShadow = false
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Public
--------------------------------------------------------------------------------

-- Builds the course and returns the checkpoint parts, indexed by stage.
function CourseBuilder.build(): { BasePart }
	rng = Random.new(GameConfig.Seed)
	paletteIndex = 0
	cursor = Vector3.new(0, GameConfig.CourseHeight, 0)

	local old = workspace:FindFirstChild("SkyCourse")
	if old then
		old:Destroy()
	end
	-- Remove the default baseplate/spawn if the place still has them.
	for _, name in { "Baseplate", "SpawnLocation" } do
		local inst = workspace:FindFirstChild(name)
		if inst then
			inst:Destroy()
		end
	end

	folder = Instance.new("Folder")
	folder.Name = "SkyCourse"
	folder.Parent = workspace

	local checkpoints = {}
	local stages = GameConfig.Stages

	for index, stage in stages do
		local isFirst = index == 1
		local isLast = index == #stages
		checkpoints[index] = buildCheckpoint(index, stage, isFirst, isLast)

		if not isLast then
			local difficulty = math.clamp(stage.difficulty or 1, 1, 5)
			local options = SECTIONS_BY_DIFFICULTY[difficulty]
			local count = if difficulty >= 4 then 2 else 1
			for _ = 1, count do
				local kind = options[rng:NextInteger(1, #options)]
				Sections[kind](difficulty)
			end
		end
	end

	scatterClouds(0, cursor.Z)
	return checkpoints
end

return CourseBuilder
