--[[
	Client entry point.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Floaty = require(script.Parent.Floaty)
local RewardUI = require(script.Parent.RewardUI)

Floaty.init()
RewardUI.init()

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local rewardUnlocked = remotes:WaitForChild("RewardUnlocked") :: RemoteEvent
rewardUnlocked.OnClientEvent:Connect(function(stage: number)
	RewardUI.showCard(stage, true)
end)

if GameConfig.Sounds.Music ~= "" then
	local music = Instance.new("Sound")
	music.Name = "BackgroundMusic"
	music.SoundId = GameConfig.Sounds.Music
	music.Looped = true
	music.Volume = 0.35
	music.Parent = SoundService
	music:Play()
end
