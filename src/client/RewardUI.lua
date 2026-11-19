--[[
	RewardUI — all on-screen UI, built in code:
	  - intro title on join
	  - checkpoint counter (top)
	  - "Memories" button + gallery of unlocked cards
	  - the reward card (note + optional photo), typed out
	  - finale confetti
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local RewardUI = {}

local player = Players.LocalPlayer
local stages = GameConfig.Stages
local ACCENT = GameConfig.AccentColor
local CARD_BG = Color3.fromRGB(255, 248, 251)
local TEXT = Color3.fromRGB(80, 50, 70)

local gui: ScreenGui
local counter: TextLabel
local card: Frame
local cardTitle: TextLabel
local cardImage: ImageLabel
local cardNote: TextLabel
local cardScale: UIScale
local gallery: Frame
local galleryList: ScrollingFrame
local unlockSound: Sound?
local typingToken = 0

--------------------------------------------------------------------------------
-- Small UI helpers
--------------------------------------------------------------------------------

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function stroke(parent: Instance, thickness: number)
	local s = Instance.new("UIStroke")
	s.Color = ACCENT
	s.Thickness = thickness
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
end

local function padding(parent: Instance, px: number)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, px)
	p.PaddingBottom = UDim.new(0, px)
	p.PaddingLeft = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	p.Parent = parent
end

local function label(parent: Instance, text: string, size: number, font: Enum.Font?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size
	l.Font = font or Enum.Font.Gotham
	l.TextColor3 = TEXT
	l.TextWrapped = true
	l.Size = UDim2.new(1, 0, 0, 0)
	l.AutomaticSize = Enum.AutomaticSize.Y
	l.Parent = parent
	return l
end

local function button(parent: Instance, text: string): TextButton
	local b = Instance.new("TextButton")
	b.Text = text
	b.Font = Enum.Font.FredokaOne
	b.TextSize = 20
	b.TextColor3 = Color3.new(1, 1, 1)
	b.BackgroundColor3 = ACCENT
	b.AutoButtonColor = true
	b.Size = UDim2.fromOffset(150, 44)
	corner(b, 22)
	b.Parent = parent
	return b
end

local function unlockedStage(): number
	return player:GetAttribute("Stage") or 1
end

--------------------------------------------------------------------------------
-- Card
--------------------------------------------------------------------------------

local function buildCard()
	card = Instance.new("Frame")
	card.Name = "Card"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.new(0.9, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = CARD_BG
	card.Visible = false
	card.ZIndex = 10
	corner(card, 18)
	stroke(card, 3)
	padding(card, 20)
	card.Parent = gui

	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(460, math.huge)
	limit.Parent = card

	cardScale = Instance.new("UIScale")
	cardScale.Parent = card

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 12)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = card

	cardTitle = label(card, "", 28, Enum.Font.FredokaOne)
	cardTitle.TextColor3 = ACCENT
	cardTitle.LayoutOrder = 1

	cardImage = Instance.new("ImageLabel")
	cardImage.BackgroundTransparency = 1
	cardImage.Size = UDim2.new(1, 0, 0, 220)
	cardImage.ScaleType = Enum.ScaleType.Fit
	cardImage.LayoutOrder = 2
	cardImage.Parent = card

	cardNote = label(card, "", 20)
	cardNote.LayoutOrder = 3
	cardNote.LineHeight = 1.15

	local close = button(card, "💗 Close")
	close.LayoutOrder = 4
	close.Activated:Connect(function()
		typingToken += 1
		card.Visible = false
	end)
end

local function typeOut(text: string, perChar: number)
	typingToken += 1
	local token = typingToken
	cardNote.Text = text
	local total = utf8.len(text) or #text
	cardNote.MaxVisibleGraphemes = 0
	task.spawn(function()
		for i = 1, total do
			if token ~= typingToken then
				return
			end
			cardNote.MaxVisibleGraphemes = i
			task.wait(perChar)
		end
		cardNote.MaxVisibleGraphemes = -1
	end)
end

local function confetti()
	local colors = GameConfig.Palette
	for i = 1, 70 do
		local bit = Instance.new("Frame")
		bit.BorderSizePixel = 0
		bit.BackgroundColor3 = if i % 3 == 0 then ACCENT else colors[(i % #colors) + 1]
		bit.Size = UDim2.fromOffset(math.random(6, 12), math.random(10, 18))
		bit.Position = UDim2.new(math.random(), 0, -0.05, 0)
		bit.Rotation = math.random(0, 360)
		bit.ZIndex = 20
		bit.Parent = gui
		local tween = TweenService:Create(
			bit,
			TweenInfo.new(
				math.random(25, 45) / 10,
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.In,
				0,
				false,
				math.random() * 1.5
			),
			{
				Position = UDim2.new(bit.Position.X.Scale + (math.random() - 0.5) * 0.3, 0, 1.05, 0),
				Rotation = bit.Rotation + math.random(-360, 360),
			}
		)
		tween.Completed:Once(function()
			bit:Destroy()
		end)
		tween:Play()
	end
end

-- Shows a stage's reward card. `fresh` = just unlocked (plays sound/effects).
function RewardUI.showCard(stageIndex: number, fresh: boolean)
	local stage = stages[stageIndex]
	if not stage then
		return
	end
	local reward = stage.reward
	gallery.Visible = false

	cardTitle.Text = reward.title
	cardImage.Image = reward.image or ""
	cardImage.Visible = reward.image ~= nil and reward.image ~= ""

	if stage.finale and fresh then
		typeOut(reward.note, 0.06)
		confetti()
	else
		typeOut(reward.note, 0.015)
	end

	card.Visible = true
	cardScale.Scale = 0.8
	TweenService:Create(cardScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()

	if fresh and unlockSound then
		unlockSound:Play()
	end
end

--------------------------------------------------------------------------------
-- Gallery
--------------------------------------------------------------------------------

local function refreshGallery()
	for _, child in galleryList:GetChildren() do
		if child:IsA("GuiButton") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local unlocked = unlockedStage()
	for i, stage in stages do
		local entry = Instance.new("TextButton")
		entry.Size = UDim2.new(1, 0, 0, 44)
		entry.Font = Enum.Font.GothamMedium
		entry.TextSize = 18
		entry.LayoutOrder = i
		corner(entry, 12)
		if i <= unlocked then
			entry.Text = string.format("%d · %s", i, stage.reward.title)
			entry.BackgroundColor3 = Color3.fromRGB(255, 225, 236)
			entry.TextColor3 = TEXT
			entry.Activated:Connect(function()
				RewardUI.showCard(i, false)
			end)
		else
			entry.Text = string.format("🔒 Reach checkpoint %d", i)
			entry.BackgroundColor3 = Color3.fromRGB(235, 230, 235)
			entry.TextColor3 = Color3.fromRGB(150, 140, 150)
			entry.AutoButtonColor = false
		end
		entry.Parent = galleryList
	end
end

local function buildGallery()
	gallery = Instance.new("Frame")
	gallery.Name = "Gallery"
	gallery.AnchorPoint = Vector2.new(0.5, 0.5)
	gallery.Position = UDim2.fromScale(0.5, 0.5)
	gallery.Size = UDim2.fromScale(0.9, 0.7)
	gallery.BackgroundColor3 = CARD_BG
	gallery.Visible = false
	gallery.ZIndex = 5
	corner(gallery, 18)
	stroke(gallery, 3)
	padding(gallery, 16)
	gallery.Parent = gui

	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(420, 520)
	limit.Parent = gallery

	local title = label(gallery, "💌 Memories", 26, Enum.Font.FredokaOne)
	title.TextColor3 = ACCENT
	title.AutomaticSize = Enum.AutomaticSize.None
	title.Size = UDim2.new(1, 0, 0, 36)

	galleryList = Instance.new("ScrollingFrame")
	galleryList.BackgroundTransparency = 1
	galleryList.BorderSizePixel = 0
	galleryList.Position = UDim2.fromOffset(0, 46)
	galleryList.Size = UDim2.new(1, 0, 1, -100)
	galleryList.CanvasSize = UDim2.new()
	galleryList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	galleryList.ScrollBarThickness = 6
	galleryList.ScrollBarImageColor3 = ACCENT
	galleryList.Parent = gallery

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = galleryList

	local close = button(gallery, "Close")
	close.AnchorPoint = Vector2.new(0.5, 1)
	close.Position = UDim2.fromScale(0.5, 1)
	close.Activated:Connect(function()
		gallery.Visible = false
	end)
end

--------------------------------------------------------------------------------
-- HUD + intro
--------------------------------------------------------------------------------

local function buildHud()
	counter = Instance.new("TextLabel")
	counter.AnchorPoint = Vector2.new(0.5, 0)
	counter.Position = UDim2.new(0.5, 0, 0, 8)
	counter.Size = UDim2.fromOffset(220, 36)
	counter.BackgroundColor3 = CARD_BG
	counter.BackgroundTransparency = 0.15
	counter.Font = Enum.Font.FredokaOne
	counter.TextSize = 20
	counter.TextColor3 = ACCENT
	corner(counter, 18)
	counter.Parent = gui

	local memories = button(gui, "💌 Memories")
	memories.AnchorPoint = Vector2.new(0, 0.5)
	memories.Position = UDim2.new(0, 16, 0.5, 0)
	memories.Activated:Connect(function()
		card.Visible = false
		refreshGallery()
		gallery.Visible = not gallery.Visible
	end)
end

local function updateCounter()
	counter.Text = string.format("✨ Checkpoint %d / %d", unlockedStage(), #stages)
end

local function playIntro()
	local title = Instance.new("TextLabel")
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.35)
	title.Size = UDim2.new(0.9, 0, 0, 120)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextSize = 54
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextStrokeColor3 = ACCENT
	title.TextStrokeTransparency = 0
	title.TextWrapped = true
	title.RichText = true
	title.Text = string.format('%s\n<font size="24">%s</font>', GameConfig.Title, GameConfig.Subtitle)
	title.TextTransparency = 1
	title.TextStrokeTransparency = 1
	title.Parent = gui

	local fade = TweenInfo.new(1.2)
	TweenService:Create(title, fade, { TextTransparency = 0, TextStrokeTransparency = 0 }):Play()
	task.delay(4, function()
		local out = TweenService:Create(title, fade, { TextTransparency = 1, TextStrokeTransparency = 1 })
		out.Completed:Once(function()
			title:Destroy()
		end)
		out:Play()
	end)
end

--------------------------------------------------------------------------------
-- Public
--------------------------------------------------------------------------------

function RewardUI.init()
	gui = Instance.new("ScreenGui")
	gui.Name = "SkyObbyUI"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")

	if GameConfig.Sounds.Unlock ~= "" then
		local sound = Instance.new("Sound")
		sound.SoundId = GameConfig.Sounds.Unlock
		sound.Volume = 0.6
		sound.Parent = SoundService
		unlockSound = sound
	end

	buildHud()
	buildGallery()
	buildCard()
	updateCounter()
	playIntro()

	player:GetAttributeChangedSignal("Stage"):Connect(function()
		updateCounter()
		if gallery.Visible then
			refreshGallery()
		end
	end)

	-- Show the welcome card the first time she joins.
	task.delay(5, function()
		if unlockedStage() == 1 and not card.Visible then
			RewardUI.showCard(1, true)
		end
	end)
end

return RewardUI
