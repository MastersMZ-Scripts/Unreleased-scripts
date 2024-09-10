local ImGui = loadstring(game:HttpGet('https://github.com/depthso/Roblox-ImGUI/raw/main/ImGui.lua'))()

--// Services
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MaterialService = game:GetService("MaterialService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Rooms = workspace.Rooms

local GameInfo = MarketplaceService:GetProductInfo(game.PlaceId)

local Window = ImGui:CreateWindow({
	Title = `{GameInfo.Name} | Depso`,
	Size = UDim2.new(0, 350, 0, 370),
	Position = UDim2.new(0.5, 0, 0, 70),
	CloseCallback = CloseCallback
}):Center()

local function Alert(Text: string)
    local ModalWindow = ImGui:CreateModal({
        Title = "Attention",
        AutoSize = "Y"
    })

    ModalWindow:Label({
        Text = Text,
        TextWrapped = true
    })
    ModalWindow:Separator()

    ModalWindow:Button({
        Text = "Okay",
        Callback = function()
            ModalWindow:Close()
        end,
    })
end

local DiscoveredItems = {}
local ItemsWhitelist = {
    "Sandwich",
    "Cheese",
    "Closet key",
    "Flower",
    "Explodsive ball"
}

local Positions = {
	["Painting"] = CFrame.new(-397, 2, -11),
	["Lobby"] = CFrame.new(-277, 3, 0),
	["Office"] = CFrame.new(-484, 3, 11),
	["Basement"] = CFrame.new(-523, -17, -35),
	["Picnic"] = CFrame.new(-615, 3, 6),
	["Roof front"] = CFrame.new(-265, 29, 0),
	["Hallway end"] = CFrame.new(-486, 3, -1)
}

local Overwrites = { --// Name, Properities
	["Explodsive ball"] = {
		Color = Color3.fromRGB(0, 255, 0)
	},
	["Closet key"] = {
		Color = Color3.fromRGB(245, 205, 48)
	},
	["Sandwich"] = {
        Parent = workspace:FindFirstChild("Picnic Basket"),
		[{
            Child = "Mesh",
        }] = {
            MeshId = "http://www.roblox.com/asset/?id=12510164"
        }
	},
    ["Broom stick"] = {
		[{
            Child = "Mesh",
        }] = {
            MeshId = "http://www.roblox.com/asset/?id=99865889"
        }
	},
    ["Cheese"] = {
		[{
            Child = "Mesh",
        }] = {
            MeshId = "http://www.roblox.com/asset/?id=1090700"
        }
	},
}

local Spams = {
	["WeatherTv"] = "Weather Tv",
	["Radio"] = "Radio mute",
    ["AtticRadio"] = "Attic radio mute",
	["Curtain"] = "Curtains",
	["Warm"] = "Crouch",
}

local ServerTab = Window:CreateTab({
	Name = "Server",
	Visible = true
})

--// Viewport frame
local PreviewHeader = ServerTab:CollapsingHeader({
	Title = "Preview",
}):SetOpen(true)

local Viewport = PreviewHeader:Viewport({
	Size = UDim2.new(1, 0, 0, 120),
	Clone = true, --// Otherwise will parent
})

local ViewportConnection = RunService.RenderStepped:Connect(function(deltaTime)
	local ItemModel: Instance = Viewport.Model
	if not ItemModel then return end

	local YRotation = 30 * deltaTime
	local Rotation = CFrame.Angles(0,math.rad(YRotation),0)
	local cFrame = ItemModel:GetPivot() * Rotation
	ItemModel:PivotTo(cFrame)
end)

ServerTab:Separator()

local ItemsHeader = ServerTab:CollapsingHeader({
	Title = "Items give",
})

--// Specific matches
local Items = {
	["^CD%d$"] = ItemsHeader:CollapsingHeader({
		Title = "CDs",
	})
}

local function GetExtentsSize(Item)
	local Size
	if Item:IsA("Model") then
		Size = Item:GetExtentsSize()
	else
		Size = Item.Size
	end

	return Vector3.new(0, Size.Y, Size.Z)
end

local function GetItem(Match: string)
	for _, Item in next, DiscoveredItems do 
		local Name = Item.Name 
		if Name == Match then
			return Item
		end
	end

	return
end

local function FireItemClick(Item: Instance)
	local ClickDetector = Item:FindFirstChildOfClass("ClickDetector")
	if not ClickDetector then return end

	return fireclickdetector(ClickDetector)
end

local function CreateButtons(Item: Instance, Parent, Callback)
	if not Item then return end 

    Callback = Callback or function()
		return FireItemClick(Item)
	end

	local ButtonsRow = Parent:Row()
	ButtonsRow:Button({
		Text = `Collect {Item.Name}`,
		Callback = Callback,
	})
	ButtonsRow:Button({
		Text = "Preview",
		Callback = function(self)
			local Size = GetExtentsSize(Item)
			Viewport:SetModel(Item, CFrame.new(0, 0, -Size.Magnitude))
		end,
	})
end

local function CheckProps(Item, Properities)
    for Key, Match in next, Properities do

        --// Child check
        if type(Key) == "table" then
            local Name = Key.Child
            local Child = Item:FindFirstChild(Name)
            Properities = Match

            if not Child or not CheckProps(Child, Properities) then
                return
            end

            continue
        end

        local Success, Value = pcall(function()
            return Item[Key]
        end)

        if not Success then return end
        if Value ~= Match then return end
    end

    return true
end

local function CheckItem(Item, Parent, Depth)
	local ClickDetector = Item:FindFirstChildOfClass("ClickDetector")
	if not ClickDetector then return end

	--// Filter hidden/disabled
	if Item:IsA("BasePart") and Item.Transparency >= 1 then return end

	--// No players
	if Players:GetPlayerFromCharacter(Item) then return end
	if Players:GetPlayerFromCharacter(Parent) then return end

	--// Check properities
    for NewName, Properities in next, Overwrites do 
        if not CheckProps(Item, Properities) then
            continue
        end

        print("Discovered", NewName)
        Item.Name = NewName
    end

	table.insert(DiscoveredItems, Item)

	--// Create buttons
	local Matched = false
	for Match, Parent in next, Items do
		if Item.Name:match(Match) then
			CreateButtons(Item, Parent)
			Matched = true
		end
	end

    --// --Blacklist-- Whitelist check
	if not table.find(ItemsWhitelist, Item.Name) then return end

	if not Matched then
		CreateButtons(Item, ItemsHeader)
	end
end

local function RecursiveScan(Parent, CallBack, MaxDepth, CurrentDepth)
	CurrentDepth = CurrentDepth or 0
	if CurrentDepth > MaxDepth then return end

	for _, Child in next, Parent:GetChildren() do
		CallBack(Child, Parent, CurrentDepth)
		RecursiveScan(Child, CallBack, MaxDepth, CurrentDepth+1)
	end
end

--// Items give section, create buttons
RecursiveScan(workspace, CheckItem, 4)

local Broom = GetItem("Broom stick")
CreateButtons(Broom, ItemsHeader, function()
	--// Name of tools
	local KeyName = "Key"
	local BroomName = "Broom"

	local Backpack = LocalPlayer.Backpack
	local Character = LocalPlayer.Character
	local Humanoid = Character.Humanoid
	local OldPivot = Character:GetPivot()

	local ClosetDoor = workspace.Door

	--// Closed
	local ClosedDoor = ClosetDoor.Door1
	local MainDoor = ClosedDoor.Main
	local OpenPrompt = MainDoor:FindFirstChildOfClass("ProximityPrompt")

	--// Open
	local OpenDoor = ClosetDoor.Door1Open
	local RandomOpenPart = OpenDoor:GetChildren()[1]

	--// Get key
	local KeyTool = Backpack:FindFirstChild(KeyName)

    if Backpack:FindFirstChild(BroomName) then
        return Alert("You already own the broom 😱")
    end

	if not KeyTool then
		local Key = GetItem("Closet key")
		FireItemClick(Key)

		KeyTool = Backpack:WaitForChild(KeyName)
	end

	Humanoid:EquipTool(KeyTool)

	--// Open door
	local DoorPivot = MainDoor:GetPivot()
	Character:PivotTo(DoorPivot)

	repeat 
		fireproximityprompt(OpenPrompt)
		wait(.05)
	until RandomOpenPart.Transparency < 1

	--// Collect broom stick
	local BroomPivot = Broom:GetPivot()
	Character:PivotTo(BroomPivot)

	repeat
		FireItemClick(Broom)
		wait()
	until Backpack:FindFirstChild(BroomName)

	Character:PivotTo(OldPivot)
end)

local Toggles = ServerTab:CollapsingHeader({
	Title = "Toggles",
})

local function AddSpam(Title, Delay, Callback)
	local ButtonsRow = Toggles:Row()

	ButtonsRow:Button({
		Text = Title,
		Callback = Callback,
	})

	local SpamEnabled = false
	ButtonsRow:Button({
		Text = "Spam",
		Callback = function(self)
			SpamEnabled = not SpamEnabled
			self.Text = SpamEnabled and "Stop spam" or "Spam"

			while SpamEnabled and wait(Delay) do
				pcall(Callback)  --// Connections may cause an error
			end
		end,
	})
end

for Spam, Title in next, Spams do
	AddSpam(Title, .01, function()
		for _, Item in next, DiscoveredItems do
			local Name = Item.Name
			if Name ~= Spam then continue end

			FireItemClick(Item)
		end
	end)
end

AddSpam("Open Basement", 0.3, function()
	local Code = "9714"

	for i = 1,#Code do --// gsub is not yeildable
		local Button = GetItem(Code:sub(i,i))
		FireItemClick(Button)
		wait()
	end
end)

AddSpam("Spam Basement Codes", 0.4, function()
	local Length = 4

	for i = 1, Length do
		local Digit = math.random(1, 9)
		local Button = GetItem(Digit)
		FireItemClick(Button)
	end
end)

function CloseCallback()
	ViewportConnection:Disconnect()
end

local Destruction = ServerTab:CollapsingHeader({
	Title = "Destruction",
})

Destruction:Button({
	Text = "Bring chairs",
	Callback = function(self)
		local Character = LocalPlayer.Character
		local Humanoid = Character.Humanoid
		local Target = Character:GetPivot()

		for _, Room in next, Rooms:GetChildren() do
			local Chairs = Room.ChairZone:FindFirstChild("Chairs")
			if not Chairs then continue end --// Chairs respawning

			--// Chairs
			for _, Chair in next, Chairs:GetChildren() do
				local Seat = Chair:FindFirstChildOfClass("Seat")
				if Seat.Occupant then continue end

				--// Wait until claimed
				while wait() and Seat and not Seat.Occupant do
					Seat:Sit(Humanoid)
				end

				--// Teleport the chair
				Chair:PivotTo(Target)
				wait()
				Humanoid.Sit = false
			end
		end
	end,
})

Destruction:Button({
	Text = "Tool Reach",
	Callback = function(self)
		local Character = LocalPlayer.Character
		local Humanoid = Character.Humanoid
		local Size = 400

		for _, Tool in next, Character:GetChildren() do
			if not Tool:IsA("Tool") then continue end

			Tool.Handle.Massless = true
			Tool.Handle.Size = Vector3.new(Size,Size,Size)
			Humanoid:UnequipTools()
		end
	end,
})

--// Client Tab
local ClientTab = Window:CreateTab({
	Name = "Client"
})

--// Teleports
local Teleports = ClientTab:CollapsingHeader({
	Title = "Teleports",
})

for Name, Pivot in next, Positions do
	Teleports:Button({
		Text = Name,
		Callback = function(self)
			local Character = LocalPlayer.Character
			Character:PivotTo(Pivot)
		end,
	})
end

----// Doors
local Doors = {}
for _, Room: Model in next, Rooms:GetChildren() do
	local Door = Room:FindFirstChild("Door")
	if not Door then continue end
	Doors[Door] = Door.Parent
end

ClientTab:Checkbox({
	Label = "No doors",
	Callback = function(self, Value)
		for Door, Parent in next, Doors do
			Door.Parent = not Value and Parent or nil
		end
	end,
})

--// Weather
ClientTab:Separator({
	Text = "Weather"
})

ClientTab:Checkbox({
	Label = "No Rain",
	Callback = function(self, Value)
		LocalPlayer.PlayerScripts.Rai.RainyDay.Enabled = not Value

		local RainFolder: model = workspace:FindFirstChild("Rain Home")
		if Value then
			RainFolder:Remove()
		end
	end,
})
ClientTab:Button({
	Text = "Stop Rain",
	Callback = function(self)
		ReplicatedStorage.Season.Value = "Sunny"
		ReplicatedStorage.Sound.Rain:Stop()

		local RainySky = Lighting:FindFirstChild("RainySky")
		if RainySky then
			RainySky:Remove()
		end

		local SunnySky = MaterialService:FindFirstChild("Sky")
		SunnySky:Clone().Parent = Lighting
	end,
})

--// Player
ClientTab:Separator({
	Text = "Player"
})

ClientTab:Slider({
	Label = "Walkspeed",
	Value = 16,
	MinValue = 1,
	MaxValue = 100,

	Callback = function(self, Value)
		local Character = LocalPlayer.Character
		local Humanoid = Character.Humanoid
		Humanoid.WalkSpeed = Value
	end,
})
