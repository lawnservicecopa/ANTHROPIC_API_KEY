--[[
	Progress — checkpoints, respawning, rewards and saving.

	- The player's furthest checkpoint is stored in a DataStore, a "Stage"
	  leaderstat, and a "Stage" attribute on the Player (the client UI reads it).
	- Touching a new checkpoint fires the "RewardUnlocked" RemoteEvent so the
	  client pops up that stage's card.
	- Falling off the course (or touching a "Kill" part) teleports you back to
	  your checkpoint instead of killing you.

	DataStores only work in a published place. In Studio, turn on
	Game Settings -> Security -> "Enable Studio Access to API Services",
	otherwise progress just won't save between test sessions.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Progress = {}

local FALL_DISTANCE = 45 -- studs below your checkpoint before you get sent back
local SAVE_KEY_PREFIX = "player_"

local store: DataStore? = nil
local checkpoints: { BasePart } = {}
local rewardUnlocked: RemoteEvent
local stageOf: { [Player]: number } = {}

do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("SkyObbyProgress_v1")
	end)
	if ok then
		store = result
	else
		warn("[Progress] DataStore unavailable, progress won't save:", result)
	end
end

local function spawnCFrameFor(stage: number): CFrame
	local pad = checkpoints[stage] or checkpoints[1]
	-- Stand on top of the pad, facing +Z (the direction the course runs).
	return pad.CFrame * CFrame.new(0, pad.Size.Y / 2 + 3, 0) * CFrame.Angles(0, math.pi, 0)
end

local function save(player: Player)
	local stage = stageOf[player]
	if not store or not stage then
		return
	end
	local ok, err = pcall(function()
		store:SetAsync(SAVE_KEY_PREFIX .. player.UserId, { stage = stage }, { player.UserId })
	end)
	if not ok then
		warn("[Progress] Save failed for", player.Name, err)
	end
end

local function load(player: Player): number
	if not store then
		return 1
	end
	local ok, data = pcall(function()
		return store:GetAsync(SAVE_KEY_PREFIX .. player.UserId)
	end)
	if ok and type(data) == "table" and type(data.stage) == "number" then
		return math.clamp(math.floor(data.stage), 1, #checkpoints)
	end
	if not ok then
		warn("[Progress] Load failed for", player.Name, data)
	end
	return 1
end

local function setStage(player: Player, stage: number)
	stageOf[player] = stage
	player:SetAttribute("Stage", stage)
	local leaderstats = player:FindFirstChild("leaderstats")
	local value = leaderstats and leaderstats:FindFirstChild("Stage")
	if value then
		(value :: IntValue).Value = stage
	end
end

function Progress.getStage(player: Player): number
	return stageOf[player] or 1
end

-- Puts the player's character back on their latest checkpoint.
function Progress.sendToCheckpoint(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not character or not root then
		return
	end
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	character:PivotTo(spawnCFrameFor(Progress.getStage(player)))
end

local function onCheckpointTouched(pad: BasePart, hit: BasePart)
	local character = hit.Parent
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player or stageOf[player] == nil then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local stage = pad:GetAttribute("Stage") :: number
	if stage > stageOf[player] then
		setStage(player, stage)
		rewardUnlocked:FireClient(player, stage)
		task.spawn(save, player)
	end
end

local function onCharacterAdded(player: Player, character: Model)
	character:WaitForChild("HumanoidRootPart")
	task.wait() -- let the default spawn finish before moving the character
	if character.Parent then
		Progress.sendToCheckpoint(player)
	end
end

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local stageValue = Instance.new("IntValue")
	stageValue.Name = "Stage"
	stageValue.Value = 1
	stageValue.Parent = leaderstats
	leaderstats.Parent = player

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)

	local stage = load(player)
	if not player.Parent then
		return -- left while loading
	end
	setStage(player, stage)
	player:SetAttribute("Loaded", true)

	if player.Character then
		Progress.sendToCheckpoint(player)
	end
end

-- Teleports anyone who has fallen well below their checkpoint.
local function watchFalls()
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.2 then
			return
		end
		elapsed = 0
		for player, stage in stageOf do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local pad = checkpoints[stage]
			if root and pad and root.Position.Y < pad.Position.Y - FALL_DISTANCE then
				Progress.sendToCheckpoint(player)
			end
		end
	end)
end

function Progress.init(checkpointParts: { BasePart }, remotes: Folder)
	checkpoints = checkpointParts
	rewardUnlocked = remotes:WaitForChild("RewardUnlocked") :: RemoteEvent

	for _, pad in checkpoints do
		pad.Touched:Connect(function(hit)
			onCheckpointTouched(pad, hit)
		end)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		save(player)
		stageOf[player] = nil
	end)

	game:BindToClose(function()
		for player in stageOf do
			task.spawn(save, player)
		end
		task.wait(2)
	end)

	watchFalls()
end

return Progress
