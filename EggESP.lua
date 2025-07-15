local function ManifestEggPredictorV2()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local CollectionService = game:GetService("CollectionService")
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")

	local _getUpvalue = debug.getupvalue
	local _getConnections = debug.getconnections
	local _hookFunction = hookfunction or getgenv().hookfunction
	local _newCClosure = newcclosure or getgenv().newcclosure

	local LocalPlayer = Players.LocalPlayer
	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
	local CurrentCamera = workspace.CurrentCamera

	local UI_FONT_PRIMARY = Enum.Font.GothamSemibold
	local UI_FONT_SECONDARY = Enum.Font.Gotham
	local REROLL_COOLDOWN_SECONDS = 3

	local PALETTE = {
		PRIMARY = Color3.fromRGB(80, 170, 255),
		PRIMARY_GLOW = Color3.fromRGB(120, 200, 255),
		BACKGROUND = Color3.fromRGB(20, 22, 28),
		SURFACE = Color3.fromRGB(35, 38, 46),
		SURFACE_LIGHT = Color3.fromRGB(45, 48, 58),
		TEXT_PRIMARY = Color3.fromRGB(235, 235, 245),
		TEXT_SECONDARY = Color3.fromRGB(180, 180, 190),
		SUCCESS = Color3.fromRGB(0, 255, 150),
		FAILURE = Color3.fromRGB(255, 80, 100),
		CONFIRMED_HATCH = Color3.fromRGB(255, 220, 90),
		LOCKED_SIMULATION = Color3.fromRGB(0, 255, 255),
	}

	local RARITY_COLORS = {
		["Common"] = Color3.fromRGB(190, 190, 190),
		["Uncommon"] = Color3.fromRGB(80, 200, 80),
		["Rare"] = Color3.fromRGB(80, 150, 255),
		["Legendary"] = Color3.fromRGB(200, 100, 255),
		["Mythical"] = Color3.fromRGB(255, 180, 80),
		["Divine"] = Color3.fromRGB(255, 255, 150),
		["Default"] = Color3.fromRGB(255, 255, 255)
	}

	local MasterPetList = {}
	local SimulatedLootTables = {}
	local ActiveTags = {}
	local PriorityPets = {}
	local Gui = {}
	local IsEnabled = true
	local IsRerolling = false
	local InternalPetState = nil

	local function ProcessMasterPetList(petData)
		for name, data in pairs(petData) do
			MasterPetList[name] = data.Rarity or "Common"
		end
	end

	local function ProcessEggLootTables(eggLootData)
		for eggName, eggData in pairs(eggLootData) do
			local lootPool = { Pets = {}, TotalWeight = 0 }
			if eggData.RarityData and eggData.RarityData.Items then
				for petName, petOdds in pairs(eggData.RarityData.Items) do
					local weight = petOdds.ItemOdd
					table.insert(lootPool.Pets, {
						Name = petName,
						Rarity = MasterPetList[petName] or "Common",
						Weight = weight
					})
					lootPool.TotalWeight = lootPool.TotalWeight + weight
				end
			end
			SimulatedLootTables[eggName] = lootPool
		end
		SimulatedLootTables["Default"] = SimulatedLootTables["Common Egg"]
	end

	local function SelectPetFromPool(lootPool)
		if not lootPool or #lootPool.Pets == 0 or lootPool.TotalWeight <= 0 then return nil end
		local roll = math.random() * lootPool.TotalWeight
		for _, petInfo in ipairs(lootPool.Pets) do
			roll = roll - petInfo.Weight
			if roll <= 0 then
				return petInfo
			end
		end
		return lootPool.Pets[#lootPool.Pets]
	end

	local function CreateTag()
		local tagFrame = Instance.new("Frame")
		tagFrame.Size = UDim2.fromOffset(200, 42)
		tagFrame.AnchorPoint = Vector2.new(0.5, 1)
		tagFrame.BackgroundTransparency = 1
		tagFrame.Visible = false

		local background = Instance.new("Frame")
		background.Name = "Background"
		background.Size = UDim2.new(1, 0, 1, 0)
		background.BackgroundColor3 = PALETTE.BACKGROUND
		background.Parent = tagFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = background

		local stroke = Instance.new("UIStroke")
		stroke.Color = PALETTE.PRIMARY
		stroke.Thickness = 1
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = background

		local rarityBar = Instance.new("Frame")
		rarityBar.Name = "RarityBar"
		rarityBar.Size = UDim2.new(1, 0, 0, 4)
		rarityBar.Position = UDim2.new(0, 0, 1, -4)
		rarityBar.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		rarityBar.BorderSizePixel = 0
		rarityBar.Parent = background

		local rarityBarCorner = Instance.new("UICorner")
		rarityBarCorner.CornerRadius = UDim.new(0, 2)
		rarityBarCorner.Parent = rarityBar

		local eggNameLabel = Instance.new("TextLabel")
		eggNameLabel.Size = UDim2.new(1, -10, 0.5, 0)
		eggNameLabel.Position = UDim2.fromOffset(5, 2)
		eggNameLabel.Font = UI_FONT_PRIMARY
		eggNameLabel.TextSize = 14
		eggNameLabel.TextColor3 = PALETTE.TEXT_SECONDARY
		eggNameLabel.TextXAlignment = Enum.TextXAlignment.Left
		eggNameLabel.BackgroundTransparency = 1
		eggNameLabel.Parent = background

		local petInfoLabel = Instance.new("TextLabel")
		petInfoLabel.Size = UDim2.new(1, -10, 0.5, 0)
		petInfoLabel.Position = UDim2.new(0, 5, 0.5, -2)
		petInfoLabel.Font = UI_FONT_SECONDARY
		petInfoLabel.TextSize = 15
		petInfoLabel.TextColor3 = PALETTE.TEXT_PRIMARY
		petInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
		petInfoLabel.BackgroundTransparency = 1
		petInfoLabel.Parent = background

		return tagFrame, { EggName = eggNameLabel, PetInfo = petInfoLabel, RarityBar = rarityBar, Stroke = stroke }
	end

	local function UpdateTagToState(data, petName, state)
		data.State = state
		local rarity = MasterPetList[petName] or "Common"
		local rarityColor = RARITY_COLORS[rarity] or RARITY_COLORS.Default
		local labels = data.Labels
		local stateText, strokeColor, textColor

		if state == "Revealed" then
			stateText = "[CONFIRMED] "
			strokeColor = PALETTE.CONFIRMED_HATCH
			textColor = PALETTE.CONFIRMED_HATCH
		elseif state == "Locked" then
			stateText = "[LOCKED] "
			strokeColor = PALETTE.LOCKED_SIMULATION
			textColor = PALETTE.LOCKED_SIMULATION
		end

		labels.PetInfo.Text = `{stateText}{petName}`
		
		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(labels.PetInfo, tweenInfo, { TextColor3 = textColor }):Play()
		TweenService:Create(labels.RarityBar, tweenInfo, { BackgroundColor3 = rarityColor }):Play()
		TweenService:Create(labels.Stroke, tweenInfo, { Color = strokeColor }):Play()
	end

	local function RerollPet(objectId)
		local data = ActiveTags[objectId]
		if not data or not data.LootPool or data.State ~= "Simulating" then return end

		local labels = data.Labels
		local selectedPet = SelectPetFromPool(data.LootPool)
		if not selectedPet then
			labels.PetInfo.Text = "Prediction Error"
			return
		end

		if PriorityPets[selectedPet.Name] then
			UpdateTagToState(data, selectedPet.Name, "Locked")
			return
		end

		local rarityColor = RARITY_COLORS[selectedPet.Rarity] or RARITY_COLORS.Default
		TweenService:Create(labels.RarityBar, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundColor3 = rarityColor }):Play()
		labels.PetInfo.Text = selectedPet.Name
		labels.PetInfo.TextColor3 = rarityColor
	end

	local function StartRerollCooldown()
		local button = Gui.RerollButton
		local overlay = button:FindFirstChild("CooldownOverlay")
		if not overlay then return end

		overlay.Visible = true
		overlay.Size = UDim2.new(1, 0, 1, 0)
		local tween = TweenService:Create(overlay, TweenInfo.new(REROLL_COOLDOWN_SECONDS, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 1, 0) })
		tween:Play()

		task.delay(REROLL_COOLDOWN_SECONDS, function()
			IsRerolling = false
			if overlay and overlay.Parent then
				overlay.Visible = false
			end
		end)
	end

	local function RerollAll()
		if IsRerolling then return end
		IsRerolling = true
		for objectId, data in pairs(ActiveTags) do
			if data.State == "Simulating" then
				RerollPet(objectId)
			end
		end
		StartRerollCooldown()
	end

	local function ToggleESP()
		IsEnabled = not IsEnabled
		for _, data in pairs(ActiveTags) do
			data.Tag.Visible = IsEnabled
		end

		local button = Gui.ToggleButton
		local stroke = Gui.ToggleStroke
		local icon = button:FindFirstChild("Icon")
		local targetText, targetColor, targetIcon

		if IsEnabled then
			targetText = "ESP: ENABLED"
			targetColor = PALETTE.SUCCESS
			targetIcon = "rbxassetid://6034841695"
		else
			targetText = "ESP: DISABLED"
			targetColor = PALETTE.FAILURE
			targetIcon = "rbxassetid://6034841580"
		end
		button.Text = targetText
		icon.Image = targetIcon
		TweenService:Create(stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Color = targetColor }):Play()
		TweenService:Create(icon, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { ImageColor3 = targetColor }):Play()
	end

	local function CreateControlPanel()
		local controlPanel = Instance.new("Frame")
		controlPanel.Name = "ControlPanel"
		controlPanel.Size = UDim2.fromOffset(240, 200)
		controlPanel.Position = UDim2.new(0.5, -120, 0.5, -100)
		controlPanel.BackgroundColor3 = PALETTE.BACKGROUND
		controlPanel.BorderSizePixel = 0
		Gui.ControlPanel = controlPanel

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = controlPanel

		local stroke = Instance.new("UIStroke")
		stroke.Color = PALETTE.PRIMARY
		stroke.Thickness = 1.5
		stroke.Parent = controlPanel

		local glow = Instance.new("UIStroke")
		glow.Color = PALETTE.PRIMARY_GLOW
		glow.Thickness = 5
		glow.Transparency = 0.85
		glow.Parent = controlPanel

		local titleBar = Instance.new("Frame")
		titleBar.Name = "TitleBar"
		titleBar.Size = UDim2.new(1, 0, 0, 36)
		titleBar.BackgroundColor3 = PALETTE.SURFACE
		titleBar.BorderSizePixel = 0
		titleBar.Parent = controlPanel

		local titleCorner = Instance.new("UICorner")
		titleCorner.CornerRadius = UDim.new(0, 8)
		titleCorner.Parent = titleBar

		local titleGradient = Instance.new("UIGradient")
		titleGradient.Color = ColorSequence.new(PALETTE.SURFACE_LIGHT, PALETTE.SURFACE)
		titleGradient.Rotation = 90
		titleGradient.Parent = titleBar

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "TitleLabel"
		titleLabel.Size = UDim2.new(1, -40, 1, 0)
		titleLabel.Position = UDim2.fromOffset(35, 0)
		titleLabel.Font = UI_FONT_PRIMARY
		titleLabel.Text = "EGG PREDICTOR V2"
		titleLabel.TextColor3 = PALETTE.TEXT_PRIMARY
		titleLabel.TextSize = 14
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.BackgroundTransparency = 1
		titleLabel.Parent = titleBar

		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.Size = UDim2.fromOffset(20, 20)
		icon.Position = UDim2.new(0, 10, 0.5, -10)
		icon.Image = "rbxassetid://2150201627"
		icon.ImageColor3 = PALETTE.PRIMARY_GLOW
		icon.BackgroundTransparency = 1
		icon.Parent = titleBar

		titleBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local dragInput, dragEnd
				local frameInitialPosition = controlPanel.Position
				local mouseInitialPosition = UserInputService:GetMouseLocation()

				dragInput = UserInputService.InputChanged:Connect(function(changedInput)
					if changedInput.UserInputType == Enum.UserInputType.MouseMovement or changedInput.UserInputType == Enum.UserInputType.Touch then
						local mouseCurrentPosition = UserInputService:GetMouseLocation()
						local mouseDelta = mouseCurrentPosition - mouseInitialPosition
						
						controlPanel.Position = UDim2.new(
							frameInitialPosition.X.Scale, frameInitialPosition.X.Offset + mouseDelta.X,
							frameInitialPosition.Y.Scale, frameInitialPosition.Y.Offset + mouseDelta.Y
						)
					end
				end)

				dragEnd = UserInputService.InputEnded:Connect(function(endedInput)
					if endedInput.UserInputType == input.UserInputType then
						dragInput:Disconnect()
						dragEnd:Disconnect()
					end
				end)
			end
		end)

		local contentFrame = Instance.new("Frame")
		contentFrame.Name = "ContentFrame"
		contentFrame.Size = UDim2.new(1, 0, 1, -36)
		contentFrame.Position = UDim2.fromOffset(0, 36)
		contentFrame.BackgroundTransparency = 1
		contentFrame.Parent = controlPanel

		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, 10)
		padding.PaddingBottom = UDim.new(0, 10)
		padding.PaddingLeft = UDim.new(0, 10)
		padding.PaddingRight = UDim.new(0, 10)
		padding.Parent = contentFrame

		local listLayout = Instance.new("UIListLayout")
		listLayout.Padding = UDim.new(0, 8)
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.FillDirection = Enum.FillDirection.Vertical
		listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		listLayout.Parent = contentFrame

		local function CreateInteractiveButton(properties)
			local button = Instance.new("TextButton")
			button.Name = properties.Name
			button.Size = UDim2.new(1, 0, 0, 30)
			button.Font = UI_FONT_PRIMARY
			button.Text = properties.Text
			button.TextSize = 14
			button.TextColor3 = PALETTE.TEXT_PRIMARY
			button.BackgroundColor3 = PALETTE.SURFACE
			button.LayoutOrder = properties.LayoutOrder
			button.ClipsDescendants = properties.ClipsDescendants or false
			button.AutoButtonColor = false
			button.Parent = contentFrame

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = button

			local stroke = Instance.new("UIStroke")
			stroke.Color = properties.StrokeColor
			stroke.Thickness = 1
			stroke.Parent = button

			button.MouseEnter:Connect(function()
				TweenService:Create(button, TweenInfo.new(0.15), { BackgroundColor3 = PALETTE.SURFACE_LIGHT }):Play()
			end)
			button.MouseLeave:Connect(function()
				TweenService:Create(button, TweenInfo.new(0.15), { BackgroundColor3 = PALETTE.SURFACE }):Play()
			end)
			button.MouseButton1Click:Connect(function()
				local pos = button.Position
				local size = button.Size
				local tween = TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = pos + UDim2.fromOffset(0, 2),
					Size = size - UDim2.fromOffset(0, 4)
				})
				tween:Play()
				tween.Completed:Wait()
				TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = pos,
					Size = size
				}):Play()
			end)

			return button, stroke
		end

		local toggleButton, toggleStroke = CreateInteractiveButton({
			Name = "ToggleButton", Text = "ESP: ENABLED", LayoutOrder = 1, StrokeColor = PALETTE.SUCCESS
		})
		Gui.ToggleButton = toggleButton
		Gui.ToggleStroke = toggleStroke

		local toggleIcon = Instance.new("ImageLabel")
		toggleIcon.Name = "Icon"
		toggleIcon.Size = UDim2.fromOffset(16, 16)
		toggleIcon.Position = UDim2.new(0, 10, 0.5, -8)
		toggleIcon.Image = "rbxassetid://6034841695"
		toggleIcon.ImageColor3 = PALETTE.SUCCESS
		toggleIcon.BackgroundTransparency = 1
		toggleIcon.Parent = toggleButton

		local rerollButton, rerollStroke = CreateInteractiveButton({
			Name = "RerollButton", Text = "MANUAL PREDICTION", LayoutOrder = 2, StrokeColor = PALETTE.PRIMARY, ClipsDescendants = true
		})
		Gui.RerollButton = rerollButton

		local cooldownOverlay = Instance.new("Frame")
		cooldownOverlay.Name = "CooldownOverlay"
		cooldownOverlay.Size = UDim2.new(0, 0, 1, 0)
		cooldownOverlay.Position = UDim2.new(1, 0, 0, 0)
		cooldownOverlay.AnchorPoint = Vector2.new(1, 0)
		cooldownOverlay.BackgroundColor3 = PALETTE.PRIMARY_GLOW
		cooldownOverlay.BackgroundTransparency = 0.6
		cooldownOverlay.BorderSizePixel = 0
		cooldownOverlay.Visible = false
		cooldownOverlay.ZIndex = 2
		cooldownOverlay.Parent = rerollButton

		local priorityLabel = Instance.new("TextLabel")
		priorityLabel.Name = "PriorityLabel"
		priorityLabel.Size = UDim2.new(1, 0, 0, 18)
		priorityLabel.Font = UI_FONT_PRIMARY
		priorityLabel.Text = "Priority Pets (comma-separated)"
		priorityLabel.TextColor3 = PALETTE.TEXT_SECONDARY
		priorityLabel.TextSize = 12
		priorityLabel.TextXAlignment = Enum.TextXAlignment.Left
		priorityLabel.BackgroundTransparency = 1
		priorityLabel.LayoutOrder = 3
		priorityLabel.Parent = contentFrame

		local priorityInput = Instance.new("TextBox")
		priorityInput.Name = "PriorityInput"
		priorityInput.Size = UDim2.new(1, 0, 0, 40)
		priorityInput.Font = UI_FONT_SECONDARY
		priorityInput.PlaceholderText = "Bunny, Dog, Cat..."
		priorityInput.PlaceholderColor3 = Color3.fromRGB(100, 105, 115)
		priorityInput.Text = ""
		priorityInput.TextSize = 14
		priorityInput.TextColor3 = PALETTE.TEXT_PRIMARY
		priorityInput.BackgroundColor3 = PALETTE.SURFACE
		priorityInput.ClearTextOnFocus = false
		priorityInput.LayoutOrder = 4
		priorityInput.Parent = contentFrame
		Gui.PriorityInput = priorityInput

		local piCorner = Instance.new("UICorner")
		piCorner.CornerRadius = UDim.new(0, 6)
		piCorner.Parent = priorityInput

		local piStroke = Instance.new("UIStroke")
		piStroke.Color = PALETTE.PRIMARY
		piStroke.Thickness = 1
		piStroke.Parent = priorityInput

		priorityInput.FocusLost:Connect(function(enterPressed)
			if not enterPressed then return end
			PriorityPets = {}
			local text = priorityInput.Text
			local petNames = string.split(text, ",")
			for _, petName in ipairs(petNames) do
				local trimmedName = string.gsub(petName, "^%s*(.-)%s*$", "%1")
				if #trimmedName > 0 then
					PriorityPets[trimmedName] = true
				end
			end
			
			TweenService:Create(piStroke, TweenInfo.new(0.1), { Color = PALETTE.SUCCESS }):Play()
			task.delay(0.5, function()
				if piStroke and piStroke.Parent then
					TweenService:Create(piStroke, TweenInfo.new(0.5), { Color = PALETTE.PRIMARY }):Play()
				end
			end)
		end)

		toggleButton.MouseButton1Click:Connect(ToggleESP)
		rerollButton.MouseButton1Click:Connect(RerollAll)

		controlPanel.Parent = Gui.ESPContainer
	end

	local function OnRender()
		if not IsEnabled then return end
		for objectId, data in pairs(ActiveTags) do
			local object = data.Instance
			local tagFrame = data.Tag
			if not object or not object.Parent or not object:IsDescendantOf(workspace) then
				Untrack(object)
				continue
			end
			local objectPosition = object:GetPivot().Position
			local position, onScreen = CurrentCamera:WorldToViewportPoint(objectPosition)
			if onScreen then
				tagFrame.Position = UDim2.fromOffset(position.X, position.Y - 50)
				tagFrame.Visible = true
			else
				tagFrame.Visible = false
			end

			if data.State ~= "Revealed" and InternalPetState then
				local realPetName = InternalPetState[objectId]
				if realPetName then
					UpdateTagToState(data, realPetName, "Revealed")
				end
			end
		end
	end

	function Track(object)
		if object:GetAttribute("OWNER") ~= LocalPlayer.Name then return end
		local objectId = object:GetAttribute("OBJECT_UUID")
		if not objectId or ActiveTags[objectId] then return end

		local eggName = object:GetAttribute("EggName") or "Unknown Egg"
		local lootPool = SimulatedLootTables[eggName] or SimulatedLootTables["Default"]

		local tagFrame, labels = CreateTag()
		labels.EggName.Text = eggName

		local data = {
			Tag = tagFrame, Labels = labels, Instance = object, LootPool = lootPool,
			State = "Simulating"
		}
		ActiveTags[objectId] = data
		tagFrame.Parent = Gui.ESPContainer

		local realPetName = InternalPetState and InternalPetState[objectId]
		if realPetName then
			UpdateTagToState(data, realPetName, "Revealed")
		else
			RerollPet(objectId)
		end
	end

	function Untrack(object)
		local objectId = typeof(object) == "Instance" and object:GetAttribute("OBJECT_UUID") or object
		if not objectId or not ActiveTags[objectId] then return end
		local data = ActiveTags[objectId]
		if data.Tag then data.Tag:Destroy() end
		ActiveTags[objectId] = nil
	end

	local function OnRealHatchRevealed(objectId, petName)
		local data = ActiveTags[objectId]
		if not data or data.State == "Revealed" then return end
		UpdateTagToState(data, petName, "Revealed")
	end

	local function ObserveSystemEvents()
		pcall(function()
			local petEggService = ReplicatedStorage:WaitForChild("GameEvents", 5):WaitForChild("PetEggService", 5)
			local connections = _getConnections(petEggService.OnClientEvent)
			if #connections > 0 then
				local hatchFunction = _getUpvalue(_getUpvalue(connections[1].Function, 1), 2)
				InternalPetState = _getUpvalue(hatchFunction, 2)
			end
		end)

		pcall(function()
			local readyRemote = ReplicatedStorage:WaitForChild("GameEvents", 5):WaitForChild("EggReadyToHatch_RE", 5)
			local connections = _getConnections(readyRemote.OnClientEvent)
			if #connections > 0 and _hookFunction and _newCClosure then
				local originalFunction = connections[1].Function
				local old; old = _hookFunction(originalFunction, _newCClosure(function(...)
					local args = {...}
					pcall(function()
						local objectId, petName = args[1], args[2]
						if typeof(objectId) == "string" and typeof(petName) == "string" then
							OnRealHatchRevealed(objectId, petName)
						end
					end)
					return old(...)
				end))
			end
		end)
	end

	local function Initialize()
		local MASTER_PET_DATA = { ["Dog"] = { Rarity = "Common" }, ["Golden Lab"] = { Rarity = "Common" }, ["Bunny"] = { Rarity = "Common" }, ["Black Bunny"] = { Rarity = "Uncommon" }, ["Cat"] = { Rarity = "Uncommon" }, ["Deer"] = { Rarity = "Uncommon" }, ["Chicken"] = { Rarity = "Uncommon" }, ["Orange Tabby"] = { Rarity = "Rare" }, ["Spotted Deer"] = { Rarity = "Rare" }, ["Rooster"] = { Rarity = "Rare" }, ["Monkey"] = { Rarity = "Rare" }, ["Pig"] = { Rarity = "Rare" }, ["Silver Monkey"] = { Rarity = "Legendary" }, ["Turtle"] = { Rarity = "Legendary" }, ["Cow"] = { Rarity = "Legendary" }, ["Sea Otter"] = { Rarity = "Legendary" }, ["Polar Bear"] = { Rarity = "Legendary" }, ["Caterpillar"] = { Rarity = "Legendary" }, ["Snail"] = { Rarity = "Legendary" }, ["Giant Ant"] = { Rarity = "Mythical" }, ["Praying Mantis"] = { Rarity = "Mythical" }, ["Dragonfly"] = { Rarity = "Divine" }, ["Panda"] = { Rarity = "Legendary" }, ["Hedgehog"] = { Rarity = "Rare" }, ["Kiwi"] = { Rarity = "Rare" }, ["Mole"] = { Rarity = "Legendary" }, ["Frog"] = { Rarity = "Legendary" }, ["Echo Frog"] = { Rarity = "Mythical" }, ["Raccoon"] = { Rarity = "Divine" }, ["Night Owl"] = { Rarity = "Mythical" }, ["Owl"] = { Rarity = "Mythical" }, ["Grey Mouse"] = { Rarity = "Legendary" }, ["Squirrel"] = { Rarity = "Legendary" }, ["Brown Mouse"] = { Rarity = "Legendary" }, ["Red Giant Ant"] = { Rarity = "Mythical" }, ["Red Fox"] = { Rarity = "Divine" }, ["Chicken Zombie"] = { Rarity = "Mythical" }, ["Blood Hedgehog"] = { Rarity = "Legendary" }, ["Blood Kiwi"] = { Rarity = "Legendary" }, ["Blood Owl"] = { Rarity = "Divine" }, ["Moon Cat"] = { Rarity = "Legendary" }, ["Bee"] = { Rarity = "Uncommon" }, ["Honey Bee"] = { Rarity = "Rare" }, ["Petal Bee"] = { Rarity = "Legendary" }, ["Bear Bee"] = { Rarity = "Mythical" }, ["Queen Bee"] = { Rarity = "Divine" }, ["Wasp"] = { Rarity = "Uncommon" }, ["Tarantula Hawk"] = { Rarity = "Rare" }, ["Moth"] = { Rarity = "Legendary" }, ["Butterfly"] = { Rarity = "Mythical" }, ["Disco Bee"] = { Rarity = "Divine" }, ["Cooked Owl"] = { Rarity = "Mythical" }, ["Pack Bee"] = { Rarity = "Mythical" }, ["Starfish"] = { Rarity = "Common" }, ["Crab"] = { Rarity = "Common" }, ["Seagull"] = { Rarity = "Common" }, ["Toucan"] = { Rarity = "Rare" }, ["Flamingo"] = { Rarity = "Rare" }, ["Sea Turtle"] = { Rarity = "Rare" }, ["Seal"] = { Rarity = "Rare" }, ["Orangutan"] = { Rarity = "Rare" }, ["Peacock"] = { Rarity = "Legendary" }, ["Capybara"] = { Rarity = "Legendary" }, ["Scarlet Macaw"] = { Rarity = "Legendary" }, ["Ostrich"] = { Rarity = "Legendary" }, ["Mimic Octopus"] = { Rarity = "Mythical" }, ["Meerkat"] = { Rarity = "Legendary" }, ["Sand Snake"] = { Rarity = "Legendary" }, ["Axolotl"] = { Rarity = "Mythical" }, ["Hyacinth Macaw"] = { Rarity = "Mythical" }, ["Fennec Fox"] = { Rarity = "Divine" }, ["Hamster"] = { Rarity = "Mythical" }, ["Bald Eagle"] = { Rarity = "Legendary" }, ["Raptor"] = { Rarity = "Legendary" }, ["Stegosaurus"] = { Rarity = "Legendary" }, ["Triceratops"] = { Rarity = "Legendary" }, ["Pterodactyl"] = { Rarity = "Mythical" }, ["Brontosaurus"] = { Rarity = "Mythical" }, ["Radioactive Stegosaurus"] = { Rarity = "Legendary" }, ["T-Rex"] = { Rarity = "Divine" }, ["Parasaurolophus"] = { Rarity = "Legendary" }, ["Iguanodon"] = { Rarity = "Legendary" }, ["Pachycephalosaurus"] = { Rarity = "Legendary" }, ["Dilophosaurus"] = { Rarity = "Mythical" }, ["Ankylosaurus"] = { Rarity = "Mythical" }, ["Spinosaurus"] = { Rarity = "Divine" }, ["Rainbow Parasaurolophus"] = { Rarity = "Legendary" }, ["Rainbow Iguanodon"] = { Rarity = "Legendary" }, ["Rainbow Pachycephalosaurus"] = { Rarity = "Legendary" }, ["Rainbow Dilophosaurus"] = { Rarity = "Mythical" }, ["Rainbow Ankylosaurus"] = { Rarity = "Mythical" }, ["Rainbow Spinosaurus"] = { Rarity = "Divine" }, ["Firefly"] = { Rarity = "Mythical" }, ["Red Dragon"] = { Rarity = "Common" }, ["Golden Bee"] = { Rarity = "Mythical" } }
		local EGG_LOOT_DATA = {["Legendary Egg"] = {RarityData = {Items = {["Silver Monkey"] = {ItemOdd = 20}, Cow = {ItemOdd = 20}, ["Sea Otter"] = {ItemOdd = 5}, Turtle = {ItemOdd = 1}, ["Polar Bear"] = {ItemOdd = 1}}}}, ["Rare Egg"] = {RarityData = {Items = {["Orange Tabby"] = {ItemOdd = 20}, Monkey = {ItemOdd = 5}, ["Spotted Deer"] = {ItemOdd = 15}, Rooster = {ItemOdd = 10}, Pig = {ItemOdd = 10}}}}, ["Uncommon Egg"] = {RarityData = {Items = {["Black Bunny"] = {ItemOdd = 5}, Cat = {ItemOdd = 5}, Deer = {ItemOdd = 5}, Chicken = {ItemOdd = 5}}}}, ["Common Egg"] = {RarityData = {Items = {Dog = {ItemOdd = 10}, ["Golden Lab"] = {ItemOdd = 10}, Bunny = {ItemOdd = 10}}}}, ["Mythical Egg"] = {RarityData = {Items = {["Grey Mouse"] = {ItemOdd = 36}, Squirrel = {ItemOdd = 27}, ["Brown Mouse"] = {ItemOdd = 27}, ["Red Giant Ant"] = {ItemOdd = 8.5}, ["Red Fox"] = {ItemOdd = 1.5}}}}, ["Bug Egg"] = {RarityData = {Items = {Dragonfly = {ItemOdd = 1}, ["Praying Mantis"] = {ItemOdd = 4}, ["Giant Ant"] = {ItemOdd = 25}, Snail = {ItemOdd = 30}, Caterpillar = {ItemOdd = 40}}}}, ["Exotic Bug Egg"] = {RarityData = {Items = {Dragonfly = {ItemOdd = 1}, ["Praying Mantis"] = {ItemOdd = 4}, Caterpillar = {ItemOdd = 25}, ["Giant Ant"] = {ItemOdd = 30}, Snail = {ItemOdd = 40}}}}, ["Night Egg"] = {RarityData = {Items = {Raccoon = {ItemOdd = 0.1}, ["Night Owl"] = {ItemOdd = 3}, ["Echo Frog"] = {ItemOdd = 7}, Frog = {ItemOdd = 15}, Mole = {ItemOdd = 20}, Hedgehog = {ItemOdd = 40}}}}, ["Bee Egg"] = {RarityData = {Items = {["Queen Bee"] = {ItemOdd = 1}, ["Petal Bee"] = {ItemOdd = 4}, ["Bear Bee"] = {ItemOdd = 5}, ["Honey Bee"] = {ItemOdd = 25}, Bee = {ItemOdd = 65}}}}, ["Anti Bee Egg"] = {RarityData = {Items = {["Disco Bee"] = {ItemOdd = 0.25}, Butterfly = {ItemOdd = 1}, Moth = {ItemOdd = 13.75}, ["Tarantula Hawk"] = {ItemOdd = 30}, Wasp = {ItemOdd = 55}}}}, ["Premium Anti Bee Egg"] = {RarityData = {Items = {["Disco Bee"] = {ItemOdd = 0.25}, Butterfly = {ItemOdd = 1}, Moth = {ItemOdd = 13.75}, ["Tarantula Hawk"] = {ItemOdd = 30}, Wasp = {ItemOdd = 55}}}}, ["Premium Night Egg"] = {RarityData = {Items = {Raccoon = {ItemOdd = 1}, ["Night Owl"] = {ItemOdd = 3}, ["Echo Frog"] = {ItemOdd = 7}, Frog = {ItemOdd = 10}, Mole = {ItemOdd = 16}, Hedgehog = {ItemOdd = 35}}}}, ["Common Summer Egg"] = {RarityData = {Items = {Starfish = {ItemOdd = 50}, Crab = {ItemOdd = 25}, Seagull = {ItemOdd = 25}}}}, ["Rare Summer Egg"] = {RarityData = {Items = {Flamingo = {ItemOdd = 30}, Toucan = {ItemOdd = 25}, ["Sea Turtle"] = {ItemOdd = 20}, Orangutan = {ItemOdd = 15}, Seal = {ItemOdd = 10}}}}, ["Paradise Egg"] = {RarityData = {Items = {Ostrich = {ItemOdd = 40}, Peacock = {ItemOdd = 30}, Capybara = {ItemOdd = 21}, ["Scarlet Macaw"] = {ItemOdd = 8}, ["Mimic Octopus"] = {ItemOdd = 1}}}}, ["Oasis Egg"] = {RarityData = {Items = {Meerkat = {ItemOdd = 45}, ["Sand Snake"] = {ItemOdd = 34.5}, Axolotl = {ItemOdd = 15}, ["Hyacinth Macaw"] = {ItemOdd = 5}, ["Fennec Fox"] = {ItemOdd = 0.5}}}}, ["Premium Oasis Egg"] = {RarityData = {Items = {Meerkat = {ItemOdd = 45}, ["Sand Snake"] = {ItemOdd = 34.5}, Axolotl = {ItemOdd = 15}, ["Hyacinth Macaw"] = {ItemOdd = 5}, ["Fennec Fox"] = {ItemOdd = 0.5}}}}, ["Dinosaur Egg"] = {RarityData = {Items = {Raptor = {ItemOdd = 35}, Triceratops = {ItemOdd = 32.5}, Stegosaurus = {ItemOdd = 28}, Pterodactyl = {ItemOdd = 3}, Brontosaurus = {ItemOdd = 1}, ["T-Rex"] = {ItemOdd = 0.5}}}}, ["Primal Egg"] = {RarityData = {Items = {Parasaurolophus = {ItemOdd = 35}, Iguanodon = {ItemOdd = 32.5}, Pachycephalosaurus = {ItemOdd = 28}, Dilophosaurus = {ItemOdd = 3}, Ankylosaurus = {ItemOdd = 1}, Spinosaurus = {ItemOdd = 0.5}}}}, ["Premium Primal Egg"] = {RarityData = {Items = {Parasaurolophus = {ItemOdd = 34}, Iguanodon = {ItemOdd = 32.5}, Pachycephalosaurus = {ItemOdd = 28}, Dilophosaurus = {ItemOdd = 3}, Ankylosaurus = {ItemOdd = 1}, Spinosaurus = {ItemOdd = 0.5}, ["Egg/Rainbow Premium Primal Egg"] = {ItemOdd = 1}}}}, ["Rainbow Premium Primal Egg"] = {RarityData = {Items = {["Rainbow Parasaurolophus"] = {ItemOdd = 30}, ["Rainbow Iguanodon"] = {ItemOdd = 25}, ["Rainbow Pachycephalosaurus"] = {ItemOdd = 20}, ["Rainbow Dilophosaurus"] = {ItemOdd = 10}, ["Rainbow Ankylosaurus"] = {ItemOdd = 8}, ["Rainbow Spinosaurus"] = {ItemOdd = 7}}}}, ["Fake Egg"] = {RarityData = {Items = {["Silver Monkey"] = {ItemOdd = 1}, Kiwi = {ItemOdd = 1}, Cow = {ItemOdd = 1}, ["Sea Otter"] = {ItemOdd = 1}, Turtle = {ItemOdd = 1}, ["Polar Bear"] = {ItemOdd = 1}, ["Orange Tabby"] = {ItemOdd = 1}, ["Moon Cat"] = {ItemOdd = 1}, Monkey = {ItemOdd = 1}, ["Spotted Deer"] = {ItemOdd = 1}, Rooster = {ItemOdd = 1}, Pig = {ItemOdd = 1}, ["Black Bunny"] = {ItemOdd = 1}, Cat = {ItemOdd = 1}, Deer = {ItemOdd = 1}, Chicken = {ItemOdd = 1}, Dog = {ItemOdd = 1}, ["Golden Lab"] = {ItemOdd = 1}, Bunny = {ItemOdd = 1}, Dragonfly = {ItemOdd = 1}, ["Praying Mantis"] = {ItemOdd = 1}, Caterpillar = {ItemOdd = 1}, ["Giant Ant"] = {ItemOdd = 1}, Snail = {ItemOdd = 1}, Raccoon = {ItemOdd = 1}, Owl = {ItemOdd = 1}, ["Night Owl"] = {ItemOdd = 1}, ["Echo Frog"] = {ItemOdd = 1}, Frog = {ItemOdd = 1}, Mole = {ItemOdd = 1}, Hedgehog = {ItemOdd = 1}, ["Blood Hedgehog"] = {ItemOdd = 1}, ["Blood Kiwi"] = {ItemOdd = 1}, ["Blood Owl"] = {ItemOdd = 1}, ["Chicken Zombie"] = {ItemOdd = 1}, ["Grey Mouse"] = {ItemOdd = 1}, Squirrel = {ItemOdd = 1}, ["Brown Mouse"] = {ItemOdd = 1}, ["Red Giant Ant"] = {ItemOdd = 1}, ["Red Fox"] = {ItemOdd = 1}, ["Queen Bee"] = {ItemOdd = 1}, ["Bear Bee"] = {ItemOdd = 1}, ["Petal Bee"] = {ItemOdd = 1}, Bee = {ItemOdd = 1}, ["Disco Bee"] = {ItemOdd = 1}, Butterfly = {ItemOdd = 1}, ["Tarantula Hawk"] = {ItemOdd = 1}, Moth = {ItemOdd = 1}, Wasp = {ItemOdd = 1}, ["Cooked Owl"] = {ItemOdd = 1}, ["Pack Bee"] = {ItemOdd = 1}, Starfish = {ItemOdd = 1}, Crab = {ItemOdd = 1}, Seagull = {ItemOdd = 1}, Flamingo = {ItemOdd = 1}, Toucan = {ItemOdd = 1}, ["Sea Turtle"] = {ItemOdd = 1}, Orangutan = {ItemOdd = 1}, Seal = {ItemOdd = 1}, Ostrich = {ItemOdd = 1}, Peacock = {ItemOdd = 1}, Capybara = {ItemOdd = 1}, ["Scarlet Macaw"] = {ItemOdd = 1}, ["Mimic Octopus"] = {ItemOdd = 1}, Meerkat = {ItemOdd = 1}, ["Sand Snake"] = {ItemOdd = 1}, Axolotl = {ItemOdd = 1}, ["Hyacinth Macaw"] = {ItemOdd = 1}, ["Fennec Fox"] = {ItemOdd = 1}, Hamster = {ItemOdd = 1}, Raptor = {ItemOdd = 1}, Triceratops = {ItemOdd = 1}, Stegosaurus = {ItemOdd = 1}, Pterodactyl = {ItemOdd = 1}, Brontosaurus = {ItemOdd = 1}, ["T-Rex"] = {ItemOdd = 1}, Iguanodon = {ItemOdd = 1}, ["Parasaurolophus "] = {ItemOdd = 1}, Pachycephalosaurus = {ItemOdd = 1}, Ankylosaurus = {ItemOdd = 1}, Dilophosaurus = {ItemOdd = 1}, Spinosaurus = {ItemOdd = 1}, ["Rainbow Parasaurolophus"] = {ItemOdd = 1}, ["Rainbow Iguanodon"] = {ItemOdd = 1}, ["Rainbow Pachycephalosaurus"] = {ItemOdd = 1}, ["Rainbow Dilophosaurus"] = {ItemOdd = 1}, ["Rainbow Ankylosaurus"] = {ItemOdd = 1}, ["Rainbow Spinosaurus"] = {ItemOdd = 1}, ["Golden Bee"] = {ItemOdd = 1}, ["Red Dragon"] = {ItemOdd = 1}, Firefly = {ItemOdd = 1}}}}}

		ProcessMasterPetList(MASTER_PET_DATA)
		ProcessEggLootTables(EGG_LOOT_DATA)
		ObserveSystemEvents()

		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "EggPredictorV2_Container"
		screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screenGui.ResetOnSpawn = false
		Gui.ESPContainer = screenGui

		CreateControlPanel()
		screenGui.Parent = PlayerGui

		CollectionService:GetInstanceAddedSignal("PetEggServer"):Connect(Track)
		CollectionService:GetInstanceRemovedSignal("PetEggServer"):Connect(Untrack)

		for _, instance in pairs(CollectionService:GetTagged("PetEggServer")) do
			Track(instance)
		end

		RunService.PreRender:Connect(OnRender)
	end

	pcall(function()
		if not LocalPlayer or not LocalPlayer.Character then
			LocalPlayer.CharacterAdded:Wait()
		end
		Initialize()
	end)
end

coroutine.wrap(ManifestEggPredictorV2)()
