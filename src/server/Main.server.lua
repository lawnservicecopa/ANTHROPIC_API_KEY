--[[
	Server entry point. Builds the world, then starts the game systems.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CourseBuilder = require(script.Parent.CourseBuilder)
local Hazards = require(script.Parent.Hazards)
local LightingSetup = require(script.Parent.LightingSetup)
local Progress = require(script.Parent.Progress)

Players.RespawnTime = 1.5

-- Remotes the client listens to.
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local rewardUnlocked = Instance.new("RemoteEvent")
rewardUnlocked.Name = "RewardUnlocked"
rewardUnlocked.Parent = remotes
remotes.Parent = ReplicatedStorage

LightingSetup.apply()
local checkpoints = CourseBuilder.build()
Hazards.init(Progress)
Progress.init(checkpoints, remotes)

print(string.format("[SkyObby] Course built with %d checkpoints", #checkpoints))
