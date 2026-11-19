--[[
	Floaty — makes every part tagged "Floaty" gently bob and spin.
	Runs on the client so it's perfectly smooth and costs no network traffic.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Floaty = {}

local BOB_HEIGHT = 0.6
local BOB_SPEED = 2
local SPIN_SPEED = 0.8

function Floaty.init()
	local tracked: { [BasePart]: { base: CFrame, phase: number } } = {}

	local function add(part: Instance)
		if part:IsA("BasePart") then
			tracked[part] = { base = part.CFrame, phase = math.random() * math.pi * 2 }
		end
	end

	for _, part in CollectionService:GetTagged("Floaty") do
		add(part)
	end
	CollectionService:GetInstanceAddedSignal("Floaty"):Connect(add)
	CollectionService:GetInstanceRemovedSignal("Floaty"):Connect(function(part)
		tracked[part :: BasePart] = nil
	end)

	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for part, info in tracked do
			local y = math.sin(t * BOB_SPEED + info.phase) * BOB_HEIGHT
			part.CFrame = info.base * CFrame.new(0, y, 0) * CFrame.Angles(0, t * SPIN_SPEED + info.phase, 0)
		end
	end)
end

return Floaty
