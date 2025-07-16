local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

local Spawner
local success, result = pcall(function()
	if not workspace:FindFirstChild("PetsPhysical") then
		Instance.new("Folder", workspace).Name = "PetsPhysical"
	end
	Spawner = loadstring(game:HttpGet("https://codeberg.org/GrowAFilipino/GrowAGarden/raw/branch/main/Spawner.lua", true))()
end)

local THEME = {
	FlagBlue = Color3.fromHex("#0038A8"),
	FlagRed = Color3.fromHex("#CE1126"),
	FlagYellow = Color3.fromHex("#FCD116"),
	FlagWhite = Color3.fromHex("#FFFFFF"),
	Background = Color3.fromHex("#080D1A"),
	PrimaryText = Color3.fromRGB(255, 255, 255),
	SecondaryText = Color3.fromRGB(200, 200, 210),
	TertiaryText = Color3.fromRGB(130, 130, 140),
	Container = Color3.fromHex("#101625"),
	ContainerStroke = Color3.fromHex("#283040"),
	InputBackground = Color3.fromHex("#05080F"),
	Success = Color3.fromRGB(80, 255, 120),
	Failure = Color3.fromHex("#CE1126"),
	Font = Enum.Font.SourceSans,
	FontBold = Enum.Font.SourceSansBold,
}
local ASSETS = {
	MAIN_ICON = "rbxassetid://10817389095",
	SPLATTER_FLAG = "rbxassetid://9494348698",
	CLOSE_ICON = "rbxassetid://13516615284",
	MUSIC_1 = "rbxassetid://1840684529",
	MUSIC_2 = "rbxassetid://118939739460633",
	MUSIC_3 = "rbxassetid://79451196298919",
}

if _G.ProSpawnerCleanup then
	_G.ProSpawnerCleanup()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ProSpawnerUI_Hybrid"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

local ConnectionManager = {}
table.insert(ConnectionManager, screenGui.Destroying:Connect(function()
	if _G.ProSpawnerCleanup then
		_G.ProSpawnerCleanup = nil
	end
end))

function cleanup()
	for _, c in ipairs(ConnectionManager) do
		pcall(c.Disconnect, c)
	end
	table.clear(ConnectionManager)
	if screenGui and screenGui.Parent then
		screenGui:Destroy()
	end
	_G.ProSpawnerCleanup = nil
end
_G.ProSpawnerCleanup = cleanup

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 500, 0, 340)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = THEME.Background
mainFrame.BackgroundTransparency = 0.2
mainFrame.ClipsDescendants = true
mainFrame.Visible = false

local backgroundImage = Instance.new("ImageLabel", mainFrame)
backgroundImage.Name = "SplatterBackground"
backgroundImage.Size = UDim2.fromScale(1, 1)
backgroundImage.Image = ASSETS.SPLATTER_FLAG
backgroundImage.BackgroundTransparency = 1
backgroundImage.ZIndex = 0
backgroundImage.ImageTransparency = 0.5
backgroundImage.ScaleType = Enum.ScaleType.Crop

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 24)
Instance.new("UICorner", backgroundImage).CornerRadius = UDim.new(0, 24)

local mainFrameStroke = Instance.new("UIStroke", mainFrame)
mainFrameStroke.Name = "MainFrameStroke"
mainFrameStroke.Color = THEME.FlagBlue
mainFrameStroke.Thickness = 2.5

local frameGradient = Instance.new("UIGradient", mainFrameStroke)
frameGradient.Name = "FrameGradient"
frameGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, THEME.FlagBlue),
	ColorSequenceKeypoint.new(0.3, THEME.FlagRed),
	ColorSequenceKeypoint.new(0.5, THEME.FlagWhite),
	ColorSequenceKeypoint.new(0.7, THEME.FlagYellow),
	ColorSequenceKeypoint.new(1, THEME.FlagBlue),
})
frameGradient.Rotation = 90

local function createDraggable(frame, handle)
	table.insert(ConnectionManager, handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local dragStart, startPos = input.Position, frame.Position
			local moveConnection, endConnection
			moveConnection = UserInputService.InputChanged:Connect(function(inputChanged)
				if inputChanged.UserInputType == Enum.UserInputType.MouseMovement or inputChanged.UserInputType == Enum.UserInputType.Touch then
					frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + (inputChanged.Position - dragStart).X, startPos.Y.Scale, startPos.Y.Offset + (inputChanged.Position - dragStart).Y)
				end
			end)
			endConnection = UserInputService.InputEnded:Connect(function(inputEnded)
				if inputEnded.UserInputType == Enum.UserInputType.MouseButton1 or inputEnded.UserInputType == Enum.UserInputType.Touch then
					if moveConnection then moveConnection:Disconnect() end
					if endConnection then endConnection:Disconnect() end
				end
			end)
			table.insert(ConnectionManager, moveConnection)
			table.insert(ConnectionManager, endConnection)
		end
	end))
end

local TabContainer, ContentArea
do
	local TitleBar = Instance.new("Frame", mainFrame)
	TitleBar.Name = "TitleBar"
	TitleBar.Size = UDim2.new(1, 0, 0, 40)
	TitleBar.BackgroundTransparency = 1
	TitleBar.Active = true

	local TitleLabel = Instance.new("TextLabel", TitleBar)
	TitleLabel.Size = UDim2.new(0, 200, 1, 0)
	TitleLabel.Position = UDim2.new(0, 15, 0, 0)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Font = THEME.FontBold
	TitleLabel.Text = "Grow A Garden Spawner"
	TitleLabel.TextColor3 = THEME.PrimaryText
	TitleLabel.TextSize = 16
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

	local AuthorLabel = Instance.new("TextLabel", TitleBar)
	AuthorLabel.Size = UDim2.new(0, 200, 1, 0)
	AuthorLabel.Position = UDim2.new(0, 205, 0, 0)
	AuthorLabel.BackgroundTransparency = 1
	AuthorLabel.Font = THEME.Font
	AuthorLabel.Text = "by proautixt from discord"
	AuthorLabel.TextColor3 = THEME.TertiaryText
	AuthorLabel.TextSize = 14
	AuthorLabel.TextXAlignment = Enum.TextXAlignment.Left

	local CloseButton = Instance.new("ImageButton", TitleBar)
	CloseButton.Name = "CloseButton"
	CloseButton.Size = UDim2.new(0, 32, 0, 32)
	CloseButton.Position = UDim2.new(1, -36, 0.5, 0)
	CloseButton.AnchorPoint = Vector2.new(0.5, 0.5)
	CloseButton.BackgroundTransparency = 1
	CloseButton.Image = ASSETS.CLOSE_ICON
	CloseButton.ImageColor3 = THEME.SecondaryText
	CloseButton.ZIndex = 3

	local TitleSeparator = Instance.new("Frame", mainFrame)
	TitleSeparator.Size = UDim2.new(1, 0, 0, 1)
	TitleSeparator.Position = UDim2.fromOffset(0, 40)
	TitleSeparator.BackgroundColor3 = THEME.ContainerStroke
	TitleSeparator.BorderSizePixel = 0

	local Sidebar = Instance.new("Frame", mainFrame)
	Sidebar.Name = "Sidebar"
	Sidebar.Size = UDim2.new(0, 150, 1, -41)
	Sidebar.Position = UDim2.new(0, 0, 0, 41)
	Sidebar.BackgroundColor3 = THEME.Container
	Sidebar.BackgroundTransparency = 0.5

	TabContainer = Instance.new("Frame", Sidebar)
	TabContainer.Name = "TabContainer"
	TabContainer.Size = UDim2.new(1, 0, 1, -90)
	TabContainer.BackgroundTransparency = 1
	local tabLayout = Instance.new("UIListLayout", TabContainer)
	tabLayout.Padding = UDim.new(0, 5)
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local ProfileContainer = Instance.new("Frame", Sidebar)
	ProfileContainer.Size = UDim2.new(1, 0, 0, 80)
	ProfileContainer.Position = UDim2.new(0.5, 0, 1, -10)
	ProfileContainer.AnchorPoint = Vector2.new(0.5, 1)
	ProfileContainer.BackgroundTransparency = 1
	ProfileContainer.ClipsDescendants = true

	local UserIcon = Instance.new("ImageLabel", ProfileContainer)
	UserIcon.Size = UDim2.new(0, 48, 0, 48)
	UserIcon.Position = UDim2.fromScale(0.5, 0)
	UserIcon.AnchorPoint = Vector2.new(0.5, 0)
	UserIcon.BackgroundTransparency = 1
	Instance.new("UIStroke", UserIcon).Color = THEME.FlagBlue
	Instance.new("UICorner", UserIcon).CornerRadius = UDim.new(1, 0)

	local UserNameLabel = Instance.new("TextLabel", ProfileContainer)
	UserNameLabel.Size = UDim2.new(1, -50, 0, 20)
	UserNameLabel.Position = UDim2.new(0, 5, 1, -5)
	UserNameLabel.AnchorPoint = Vector2.new(0, 1)
	UserNameLabel.BackgroundTransparency = 1
	UserNameLabel.Font = THEME.Font
	UserNameLabel.Text = Players.LocalPlayer.DisplayName
	UserNameLabel.TextColor3 = THEME.SecondaryText
	UserNameLabel.TextSize = 14
	UserNameLabel.TextXAlignment = Enum.TextXAlignment.Left

	local HideNameButton = Instance.new("TextButton", ProfileContainer)
	HideNameButton.Name = "HideNameButton"
	HideNameButton.Size = UDim2.new(0, 40, 0, 20)
	HideNameButton.Position = UDim2.new(1, -5, 1, -5)
	HideNameButton.AnchorPoint = Vector2.new(1, 1)
	HideNameButton.BackgroundTransparency = 1
	HideNameButton.Font = THEME.Font
	HideNameButton.Text = "[Hide]"
	HideNameButton.TextColor3 = THEME.TertiaryText
	HideNameButton.TextSize = 12

	local isNameHidden = false
	table.insert(ConnectionManager, HideNameButton.MouseButton1Click:Connect(function()
		isNameHidden = not isNameHidden
		UserNameLabel.Visible = not isNameHidden
		HideNameButton.Text = isNameHidden and "[Show]" or "[Hide]"
	end))

	ContentArea = Instance.new("Frame", mainFrame)
	ContentArea.Name = "ContentArea"
	ContentArea.Size = UDim2.new(1, -150, 1, -41)
	ContentArea.Position = UDim2.new(0, 150, 0, 41)
	ContentArea.BackgroundTransparency = 1
	ContentArea.ClipsDescendants = true

	pcall(function()
		local c, i = Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		if i then UserIcon.Image = c end
	end)

	createDraggable(mainFrame, TitleBar)
end

local pages = {}

if not success or not Spawner then
	mainFrame.Visible = true
	local e = Instance.new("TextLabel", mainFrame)
	e.Size = UDim2.new(1, -40, 1, -40)
	e.Position = UDim2.fromScale(0.5, 0.5)
	e.AnchorPoint = Vector2.new(0.5, 0.5)
	e.BackgroundTransparency = 1
	e.Font = THEME.FontBold
	e.TextColor3 = THEME.Failure
	e.TextWrapped = true
	e.TextSize = 16
	e.Text = "LOADING FAILED:\nSpawner library unreachable.\n\nDetails: " .. tostring(result)
	return
end

local function GetSafeData(func)
	local d = {}
	local s, r = pcall(func)
	if s and type(r) == "table" then
		d = r
		table.sort(d)
	end
	return d
end

local pet_names = GetSafeData(function() return Spawner:GetPets() end)
local seed_names = GetSafeData(function() return Spawner:GetSeeds() end)
local egg_names = GetSafeData(function() return Spawner:GetEggs() end)
if #egg_names == 0 then
	egg_names = {
    "Night Egg",
    "Bug Egg",
    "Anti Bee Egg",
    "Bee Egg",
    "Legendary Egg",
    "Mythical Egg",
    "Rare Egg",
    "Uncommon Egg",
    "Exotic Bug Egg",
    "Premium Anti Bee Egg",
    "Premium Night Egg",
    "Common Summer Egg",
    "Rare Summer Egg",
    "Paradise Egg",
    "Oasis Egg",
    "Premium Oasis Egg",
    "Dinosaur Egg",
    "Fake Egg"
}
	table.sort(egg_names)
end

local function CreateTab(name, icon, order)
	local b = Instance.new("TextButton", TabContainer)
	b.Name = name
	b.Size = UDim2.new(1, -20, 0, 30)
	b.BackgroundColor3 = THEME.Container
	b.Font = THEME.FontBold
	b.Text = " " .. (icon or "") .. " " .. name
	b.TextColor3 = THEME.SecondaryText
	b.TextSize = 16
	b.LayoutOrder = order
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	local s = Instance.new("UIStroke", b)
	s.Color = THEME.ContainerStroke
	local p = Instance.new("Frame", ContentArea)
	p.Name = name
	p.Size = UDim2.fromScale(1, 1)
	p.BackgroundTransparency = 1
	p.Visible = false
	pages[name] = p
	return p
end

local function CreateQualityInput(parent, title, placeholder)
	local container = Instance.new("Frame", parent)
	container.Name = title .. "_InputContainer"
	container.Size = UDim2.new(1, 0, 0, 40)
	container.BackgroundColor3 = THEME.InputBackground
	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)
	Instance.new("UIStroke", container).Color = THEME.ContainerStroke
	local titleLabel = Instance.new("TextLabel", container)
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -10, 0, 14)
	titleLabel.Position = UDim2.new(0, 10, 0, 2)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = THEME.Font
	titleLabel.Text = title
	titleLabel.TextColor3 = THEME.TertiaryText
	titleLabel.TextSize = 11
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	local textBox = Instance.new("TextBox", container)
	textBox.Name = "InputBox"
	textBox.Size = UDim2.new(1, -10, 1, -18)
	textBox.Position = UDim2.new(0, 10, 0, 16)
	textBox.BackgroundTransparency = 1
	textBox.Font = THEME.Font
	textBox.TextColor3 = THEME.PrimaryText
	textBox.TextSize = 14
	textBox.Text = ""
	textBox.PlaceholderText = placeholder or ""
	textBox.PlaceholderColor3 = THEME.TertiaryText
	textBox.ClearTextOnFocus = false
	textBox.TextXAlignment = Enum.TextXAlignment.Left
	return textBox
end

local function CreateActionButton(parent, t, onClick, isPrimary)
	isPrimary = (isPrimary == nil) and true or isPrimary
	local b = Instance.new("TextButton", parent)
	b.Name = t .. "_Button"
	b.Size = UDim2.new(1, 0, 0, 40)
	b.BackgroundColor3 = isPrimary and THEME.FlagBlue or THEME.Container
	b.Font = THEME.FontBold
	b.Text = t
	b.TextColor3 = THEME.PrimaryText
	b.TextSize = 16
	b.AutoButtonColor = false
	if onClick and typeof(onClick) == "function" then
		table.insert(ConnectionManager, b.MouseButton1Click:Connect(onClick))
	end
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	local s = Instance.new("UIStroke", b)
	s.Color = isPrimary and THEME.FlagYellow or THEME.ContainerStroke
	s.Thickness = 1
	return b
end

local function PopulatePage(page, itemData, controlPanelBuilder)
	local listContainer = Instance.new("Frame", page)
	listContainer.Name = "ListContainer"
	listContainer.Size = UDim2.new(0.6, -30, 1, -25)
	listContainer.Position = UDim2.new(0, 20, 0, 15)
	listContainer.BackgroundColor3 = THEME.Container
	listContainer.BackgroundTransparency = 0.5
	listContainer.BorderSizePixel = 0

	local controlsFrame = Instance.new("Frame", page)
	controlsFrame.Name = "ControlsContainer"
	controlsFrame.Size = UDim2.new(0.4, -20, 1, -25)
	controlsFrame.Position = UDim2.new(0.6, 0, 0, 15)
	controlsFrame.BackgroundTransparency = 1
	local controlsLayout = Instance.new("UIListLayout", controlsFrame)
	controlsLayout.Padding = UDim.new(0, 10)
	controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local searchBar = Instance.new("TextBox", listContainer)
	searchBar.Name = "SearchBar"
	searchBar.Size = UDim2.new(1, -10, 0, 30)
	searchBar.Position = UDim2.new(0.5, 0, 0, 5)
	searchBar.AnchorPoint = Vector2.new(0.5, 0)
	searchBar.BackgroundColor3 = THEME.InputBackground
	searchBar.Font = THEME.Font
	searchBar.TextColor3 = THEME.PrimaryText
	searchBar.Text = ""
	searchBar.PlaceholderText = "Search..."
	searchBar.PlaceholderColor3 = THEME.TertiaryText
	searchBar.TextSize = 14
	searchBar.ClearTextOnFocus = false
	Instance.new("UICorner", searchBar).CornerRadius = UDim.new(0, 6)
	Instance.new("UIStroke", searchBar).Color = THEME.ContainerStroke

	local listFrame = Instance.new("ScrollingFrame", listContainer)
	listFrame.Name = "Itemlist"
	listFrame.Size = UDim2.new(1, 0, 1, -40)
	listFrame.Position = UDim2.new(0, 0, 0, 40)
	listFrame.BackgroundTransparency = 1
	listFrame.BorderSizePixel = 0
	listFrame.ScrollBarImageColor3 = THEME.FlagYellow
	listFrame.ScrollBarThickness = 5
	listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	local listLayout = Instance.new("UIListLayout", listFrame)
	listLayout.Padding = UDim.new(0, 5)
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local selectedItem = "None"
	local updateControls = controlPanelBuilder(controlsFrame, function() return selectedItem end)
	for _, name in ipairs(itemData) do
		local b = Instance.new("TextButton", listFrame)
		b.Name = name
		b.Size = UDim2.new(1, -10, 0, 25)
		b.BackgroundColor3 = THEME.InputBackground
		b.Font = THEME.Font
		b.Text = name
		b.TextColor3 = THEME.SecondaryText
		b.TextSize = 14
		b.AutoButtonColor = false
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
		local st = Instance.new("UIStroke", b)
		st.Name = "Stroke"
		st.Color = THEME.ContainerStroke
		table.insert(ConnectionManager, b.MouseButton1Click:Connect(function()
			selectedItem = name
			updateControls(name)
			for _, v in ipairs(listFrame:GetChildren()) do
				if v:IsA("TextButton") then v.Stroke.Color = THEME.ContainerStroke end
			end
			st.Color = THEME.FlagYellow
		end))
	end
	table.insert(ConnectionManager, searchBar:GetPropertyChangedSignal("Text"):Connect(function()
		local query = string.lower(searchBar.Text)
		for _, btn in ipairs(listFrame:GetChildren()) do
			if btn:IsA("TextButton") then
				btn.Visible = (query == "") or string.find(string.lower(btn.Name), query, 1, true)
			end
		end
	end))
end

local function BuildPetControls(parent, getSelection)
	local selectedLabel = Instance.new("TextLabel", parent)
	selectedLabel.Name = "SelectedLabel"
	selectedLabel.Size = UDim2.new(1, 0, 0, 20)
	selectedLabel.BackgroundTransparency = 1
	selectedLabel.Font = THEME.FontBold
	selectedLabel.Text = "Selected: None"
	selectedLabel.TextColor3 = THEME.PrimaryText
	selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
	local ageInput = CreateQualityInput(parent, "PET AGE", "1")
	local kgInput = CreateQualityInput(parent, "PET SIZE (KG)", "1")
	local amountInput = CreateQualityInput(parent, "AMOUNT", "1")
	CreateActionButton(parent, "Spawn Pet", function()
		if getSelection() ~= "None" then
			local age = tonumber(ageInput.Text) or 1
			local kg = tonumber(kgInput.Text) or 1
			local amount = math.min(18272737447372881919, math.max(1, tonumber(amountInput.Text) or 1))
			for i = 1, amount do
				Spawner.SpawnPet(getSelection(), kg, age)
			end
		end
	end, true)
	return function(name)
		selectedLabel.Text = "Selected: " .. name
	end
end

local function BuildSeedControls(parent, getSelection)
	local selectedLabel = Instance.new("TextLabel", parent)
	selectedLabel.Name = "SelectedLabel"
	selectedLabel.Size = UDim2.new(1, 0, 0, 20)
	selectedLabel.BackgroundTransparency = 1
	selectedLabel.Font = THEME.FontBold
	selectedLabel.Text = "Selected: None"
	selectedLabel.TextColor3 = THEME.PrimaryText
	selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
	local amountInput = CreateQualityInput(parent, "AMOUNT", "1")
	CreateActionButton(parent, "Spawn Seed", function()
		if getSelection() ~= "None" then
			local amount = math.min(4848474747474848, math.max(1, tonumber(amountInput.Text) or 1))
			for i = 1, amount do
				Spawner.SpawnSeed(getSelection())
			end
		end
	end, true)
	if Spawner.PlaceSeed then
		CreateActionButton(parent, "Place Seed", function()
			if getSelection() ~= "None" then Spawner.PlaceSeed(getSelection()) end
		end, false)
	end
	return function(name)
		selectedLabel.Text = "Selected: " .. name
	end
end

local function BuildEggControls(parent, getSelection)
	local selectedLabel = Instance.new("TextLabel", parent)
	selectedLabel.Name = "SelectedLabel"
	selectedLabel.Size = UDim2.new(1, 0, 0, 20)
	selectedLabel.BackgroundTransparency = 1
	selectedLabel.Font = THEME.FontBold
	selectedLabel.Text = "Selected: None"
	selectedLabel.TextColor3 = THEME.PrimaryText
	selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
	local amountInput = CreateQualityInput(parent, "AMOUNT", "1")
	CreateActionButton(parent, "Spawn Egg", function()
		if getSelection() ~= "None" then
			local amount = math.min(1037743636360, math.max(1, tonumber(amountInput.Text) or 1))
			for i = 1, amount do
				Spawner.SpawnEgg(getSelection())
			end
		end
	end, true)
	return function(name)
		selectedLabel.Text = "Selected: " .. name
	end
end

local function BuildFlowerControls(parent, getSelection)
	local selectedLabel = Instance.new("TextLabel", parent)
	selectedLabel.Name = "SelectedLabel"
	selectedLabel.Size = UDim2.new(1, 0, 0, 20)
	selectedLabel.BackgroundTransparency = 1
	selectedLabel.Font = THEME.FontBold
	selectedLabel.Text = "Selected: None"
	selectedLabel.TextColor3 = THEME.PrimaryText
	selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
	if Spawner.Spin then
		CreateActionButton(parent, "Spin for Item", function()
			if getSelection() ~= "None" then Spawner.Spin(getSelection()) end
		end, true)
	end
	return function(name)
		selectedLabel.Text = "Selected: " .. name
	end
end

local function dupeHeldItem()
	local character = player.Character
	if not character then return end
	local heldTool = character:FindFirstChildOfClass("Tool")
	if heldTool then
		local dupe = heldTool:Clone()
		dupe.Name = heldTool.Name .. ""
		local backpack = player:FindFirstChildOfClass("Backpack")
		if backpack then
			dupe.Parent = backpack
			local sound = Instance.new("Sound")
			sound.SoundId = "rbxassetid://6701126635"
			sound.PlayOnRemove = true
			sound.Parent = workspace
			sound:Destroy()
		else
			dupe:Destroy()
		end
	else
		StarterGui:SetCore("SendNotification", {
			Title = "WARNING!!!",
			Text = "No item equipped to DUPE.",
			Duration = 3
		})
	end
end

local function BuildSpecialFeatures(page)
	local layout = Instance.new("UIListLayout", page)
	layout.Padding = UDim.new(0, 20)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	local pagePadding = Instance.new("UIPadding", page)
	pagePadding.PaddingTop = UDim.new(0, 20)
	pagePadding.PaddingLeft = UDim.new(0, 20)
	pagePadding.PaddingRight = UDim.new(0, 20)
	local musicContainer = Instance.new("Frame", page)
	musicContainer.Name = "MusicContainer"
	musicContainer.Size = UDim2.new(1, 0, 0, 150)
	musicContainer.BackgroundTransparency = 1
	local musicLayout = Instance.new("UIListLayout", musicContainer)
	musicLayout.Padding = UDim.new(0, 10)
	local musicTitle = Instance.new("TextLabel", musicContainer)
	musicTitle.Name = "MusicTitle"
	musicTitle.Size = UDim2.new(1, 0, 0, 20)
	musicTitle.BackgroundTransparency = 1
	musicTitle.Font = THEME.FontBold
	musicTitle.Text = "Soundtrack"
	musicTitle.TextColor3 = THEME.PrimaryText
	musicTitle.TextSize = 16
	musicTitle.TextXAlignment = Enum.TextXAlignment.Left
	local musicPlayer = Instance.new("Sound", mainFrame)
	musicPlayer.Name = "MusicPlayer"
	local currentTrackButton = nil
	local function createMusicButton(name, soundId)
		local btn = CreateActionButton(musicContainer, name, nil, false)
		btn.Size = UDim2.new(1, 0, 0, 35)
		table.insert(ConnectionManager, btn.MouseButton1Click:Connect(function()
			if currentTrackButton == btn then
				musicPlayer:Stop()
				btn.BackgroundColor3 = THEME.Container
				btn.UIStroke.Color = THEME.ContainerStroke
				currentTrackButton = nil
			else
				if currentTrackButton then
					currentTrackButton.BackgroundColor3 = THEME.Container
					currentTrackButton.UIStroke.Color = THEME.ContainerStroke
				end
				musicPlayer.SoundId = soundId
				musicPlayer:Play()
				btn.BackgroundColor3 = THEME.FlagBlue
				btn.UIStroke.Color = THEME.FlagYellow
				currentTrackButton = btn
			end
		end))
		return btn
	end
	createMusicButton("Cool Vibes", ASSETS.MUSIC_1)
	createMusicButton("CandyLand", ASSETS.MUSIC_2)
	createMusicButton("infectious", ASSETS.MUSIC_3)
	local dupeContainer = Instance.new("Frame", page)
	dupeContainer.Name = "DupeContainer"
	dupeContainer.Size = UDim2.new(1, 0, 0, 80)
	dupeContainer.BackgroundTransparency = 1
	local dupeLayout = Instance.new("UIListLayout", dupeContainer)
	dupeLayout.Padding = UDim.new(0, 10)
	local dupeTitle = Instance.new("TextLabel", dupeContainer)
	dupeTitle.Name = "DupeTitle"
	dupeTitle.Size = UDim2.new(1, 0, 0, 20)
	dupeTitle.BackgroundTransparency = 1
	dupeTitle.Font = THEME.FontBold
	dupeTitle.Text = "Utilities"
	dupeTitle.TextColor3 = THEME.PrimaryText
	dupeTitle.TextSize = 16
	dupeTitle.TextXAlignment = Enum.TextXAlignment.Left
	CreateActionButton(dupeContainer, "Dupe Held Item", dupeHeldItem, true)
end

PopulatePage(CreateTab("Pets", "🐾", 1), pet_names, BuildPetControls)
PopulatePage(CreateTab("Seeds", "🌱", 2), seed_names, BuildSeedControls)
PopulatePage(CreateTab("Eggs", "🥚", 3), egg_names, BuildEggControls)
PopulatePage(CreateTab("Spin pack", "🌸", 4), seed_names, BuildFlowerControls)
BuildSpecialFeatures(CreateTab("Special", "⭐", 5))

local activeTab, isAnimating = nil, false
local function SwitchTab(button)
	if isAnimating or activeTab == button then return end
	isAnimating = true
	if activeTab then
		local s = activeTab:FindFirstChildOfClass("UIStroke")
		if s then s.Color = THEME.ContainerStroke end
		TweenService:Create(activeTab, TweenInfo.new(0.2), { TextColor3 = THEME.SecondaryText }):Play()
		if pages[activeTab.Name] then pages[activeTab.Name].Visible = false end
	end
	activeTab = button
	local p = pages[button.Name]
	local s = button:FindFirstChildOfClass("UIStroke")
	if s then s.Color = THEME.FlagYellow end
	TweenService:Create(button, TweenInfo.new(0.2), { TextColor3 = THEME.PrimaryText }):Play()
	if p then p.Visible = true end
	task.wait(0.2)
	isAnimating = false
end

local initialTab = TabContainer:FindFirstChild("Pets")
if initialTab then
	SwitchTab(initialTab)
end
for _, b in ipairs(TabContainer:GetChildren()) do
	if b:IsA("TextButton") then
		table.insert(ConnectionManager, b.MouseButton1Click:Connect(function() SwitchTab(b) end))
	end
end

local isVisible = false
local function toggleVisibility()
	if isAnimating then return end
	isAnimating = true
	isVisible = not isVisible
	mainFrame.Visible = true
	local props
	local info = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	if isVisible then
		mainFrame.Position = UDim2.fromScale(0.5, 0.45)
		mainFrame.Transparency = 1
		props = { Position = UDim2.fromScale(0.5, 0.5), Transparency = 0 }
	else
		props = { Position = UDim2.fromScale(0.5, 0.55), Transparency = 1 }
	end
	local t = TweenService:Create(mainFrame, info, props)
	t:Play()
	t.Completed:Once(function()
		isAnimating = false
		if not isVisible then mainFrame.Visible = false end
	end)
end

local toggleButton = Instance.new("ImageButton", screenGui)
toggleButton.Name = "ToggleUI"
toggleButton.Size = UDim2.new(0, 48, 0, 48)
toggleButton.Position = UDim2.new(0, 20, 0, 20)
toggleButton.BackgroundColor3 = THEME.Background
toggleButton.BackgroundTransparency = 0.2
toggleButton.ClipsDescendants = true
toggleButton.Image = ASSETS.SPLATTER_FLAG
toggleButton.ImageColor3 = Color3.new(1, 1, 1)
toggleButton.ScaleType = Enum.ScaleType.Crop
Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 8)

local toggleStroke = Instance.new("UIStroke", toggleButton)
toggleStroke.Thickness = 1.5
local toggleGradient = Instance.new("UIGradient", toggleStroke)
toggleGradient.Color = frameGradient.Color
toggleGradient.Rotation = 90

table.insert(ConnectionManager, toggleButton.MouseButton1Click:Connect(toggleVisibility))
createDraggable(toggleButton, toggleButton)

toggleVisibility()
