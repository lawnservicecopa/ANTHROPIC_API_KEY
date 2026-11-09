--[[
	LightingSetup — dreamy sunset sky.

	NOTE: Lighting.Technology can't be changed from a script. In Studio, select
	Lighting in the Explorer and set Technology = Future by hand (once).
]]

local Lighting = game:GetService("Lighting")

local LightingSetup = {}

local function replace(className: string, name: string, parent: Instance): Instance
	local existing = parent:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	local inst = Instance.new(className)
	inst.Name = name
	return inst
end

function LightingSetup.apply()
	Lighting.ClockTime = 17.4
	Lighting.GeographicLatitude = 20
	Lighting.Brightness = 2.5
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.OutdoorAmbient = Color3.fromRGB(200, 170, 190)
	Lighting.Ambient = Color3.fromRGB(90, 70, 90)

	local atmosphere = replace("Atmosphere", "SkyAtmosphere", Lighting) :: Atmosphere
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(255, 200, 215)
	atmosphere.Decay = Color3.fromRGB(255, 150, 180)
	atmosphere.Glare = 0.4
	atmosphere.Haze = 1.5
	atmosphere.Parent = Lighting

	local bloom = replace("BloomEffect", "SkyBloom", Lighting) :: BloomEffect
	bloom.Intensity = 0.6
	bloom.Size = 30
	bloom.Threshold = 1.2
	bloom.Parent = Lighting

	local sunRays = replace("SunRaysEffect", "SkySunRays", Lighting) :: SunRaysEffect
	sunRays.Intensity = 0.12
	sunRays.Spread = 0.8
	sunRays.Parent = Lighting

	local color = replace("ColorCorrectionEffect", "SkyColor", Lighting) :: ColorCorrectionEffect
	color.Saturation = 0.15
	color.Contrast = 0.05
	color.TintColor = Color3.fromRGB(255, 240, 245)
	color.Parent = Lighting

	-- Volumetric cloud layer around the course.
	local clouds = replace("Clouds", "SkyClouds", workspace.Terrain) :: Clouds
	clouds.Cover = 0.55
	clouds.Density = 0.6
	clouds.Color = Color3.fromRGB(255, 245, 250)
	clouds.Parent = workspace.Terrain
end

return LightingSetup
