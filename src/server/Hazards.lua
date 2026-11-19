--[[
	Hazards — behavior for tagged parts.

	"Kill": sends you back to your checkpoint (no dying, just a gentle reset).
	"Fade": starts fading when stepped on, disappears, then comes back.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Hazards = {}

local FADE_DELAY = 0.4 -- seconds after touching before it starts to fade
local FADE_TIME = 0.5
local GONE_TIME = 1.8 -- how long it stays gone

local function playerFromHit(hit: BasePart): Player?
	local character = hit.Parent
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return Players:GetPlayerFromCharacter(character)
end

function Hazards.init(progress)
	local lastReset: { [Player]: number } = {}

	local function setupKill(part: BasePart)
		part.Touched:Connect(function(hit)
			local player = playerFromHit(hit)
			if not player then
				return
			end
			local now = os.clock()
			if lastReset[player] and now - lastReset[player] < 1 then
				return
			end
			lastReset[player] = now
			progress.sendToCheckpoint(player)
		end)
	end

	local function setupFade(part: BasePart)
		local busy = false
		local originalTransparency = part.Transparency
		part.Touched:Connect(function(hit)
			if busy or not playerFromHit(hit) then
				return
			end
			busy = true
			task.wait(FADE_DELAY)
			local fadeOut = TweenService:Create(part, TweenInfo.new(FADE_TIME), { Transparency = 0.9 })
			fadeOut:Play()
			fadeOut.Completed:Wait()
			part.CanCollide = false
			task.wait(GONE_TIME)
			part.CanCollide = true
			TweenService:Create(part, TweenInfo.new(0.3), { Transparency = originalTransparency }):Play()
			task.wait(0.3)
			busy = false
		end)
	end

	for _, part in CollectionService:GetTagged("Kill") do
		setupKill(part)
	end
	CollectionService:GetInstanceAddedSignal("Kill"):Connect(setupKill)

	for _, part in CollectionService:GetTagged("Fade") do
		setupFade(part)
	end
	CollectionService:GetInstanceAddedSignal("Fade"):Connect(setupFade)

	Players.PlayerRemoving:Connect(function(player)
		lastReset[player] = nil
	end)
end

return Hazards
