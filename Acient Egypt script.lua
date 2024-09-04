local library = loadstring(game:HttpGet('https://byfron.glitch.me/scripts/ui_library.lua'))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Remotes
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

library:Init({
	version = "3.2",
	title = "MastersMZ's Ancient Egypt Script",
	company = "Depso"
})

library:Watermark("Script made by Depso")

local function CreateOptions(Table, Tab)
	local types = {
		["boolean"] = "NewToggle",
		["function"] = "NewButton",
	}
	for index, value in next, Table do
		local Call = types[typeof(value)]
		if not Call then
			continue
		end

		local Element = Tab[Call]
		Table[index]=Element(Element,index, value)
	end
	return Table
end

local function RecursiveFindClass(Parent: Model, ClassName)
	for _, Instance in next, Parent:GetDescendants() do
		if Instance:IsA(ClassName) then
			return Instance
		end
	end
end

local Game = {}
Game.MainGUI = LocalPlayer.PlayerGui:FindFirstChild("PharaohIntro", true).Parent
Game.SellUI = Game.MainGUI:WaitForChild("SellOres")

--local Sell: ScrollingFrame = Game.SellUI.Sell
--Sell.Parent = Game.MainGUI
--Sell.Size = UDim2.new(1,0,1,0)
--Sell.Position = UDim2.new(0,0,0.1,0)
--Sell.CanvasSize = UDim2.new(0,0,0,0)
--Sell.Visible = false

--for _, SellOre: TextButton in next, Sell:GetChildren() do
--	if not SellOre:IsA("TextButton") then continue end
--	SellOre.ZIndex = 999
--end

--local VirtualUser = game:GetService("VirtualUser")
--Game.SellUI:GetPropertyChangedSignal("Visible"):Connect(function()
--	if not Game.SellUI.Visible then return end
--	Sell.Visible = true
--	wait(.1)

--	local Backpack = LocalPlayer.Backpack
--	for _, Ore in next, Backpack:GetChildren() do
--		local SellButton: TextButton = Sell:FindFirstChild(Ore.Name)
--		if not SellButton then continue end

--		local Position = SellButton.AbsolutePosition
--		local Size = SellButton.AbsoluteSize
--		Position = Vector2.new(Position.X+(Size.X/2), Position.Y+(Size.Y/2))

--		local Began = tick()
--		VirtualUser:CaptureController()

--		repeat 
--			VirtualUser:ClickButton1(Position, Camera.CFrame)
--			--mousemoveabs()
--			--mouse1click()
--			wait()
--		until not Ore or Ore.Parent ~= Backpack or tick()-Began > 1.5

--		wait()
--	end

--	Sell.Visible = false
--	Game.SellUI.Visible = false
--end)

function Game:UseFood(Item: Tool)
	return Item:WaitForChild("Fge"):FireServer()
end

local Char = {}
local RespawnData = {}
function Char:HasItem(Name)
	local Backpack = LocalPlayer.Backpack
	local Character = Char.Character
	return Backpack:FindFirstChild(Name) or Character:FindFirstChild(Name)
end
function Char:GetCharacterItems(Character)
	local Character = Character or LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local Humanoid = Character:WaitForChild("Humanoid")
	self.Character = Character
	self.Humanoid = Humanoid
	self.Root = Humanoid.RootPart

	if Char.SpawnAtDeath then
		task.wait(.05)
		for Prop, Value in next, RespawnData do
			self.Root[Prop] = Value
		end
	end

	Humanoid.Died:Connect(function()
		for _, Prop in next, {"CFrame", "Velocity"} do
			RespawnData[Prop] = self.Root[Prop]
		end
	end)

	return Char
end

local PlayerTab = library:NewTab("Player")
LocalPlayer.CharacterAdded:Connect(function(Character) -- I know this is bozo
	Char:GetCharacterItems(Character)
end)
Char:GetCharacterItems()

PlayerTab:NewSection("Hide Game UIs")
function Game:SetUIVisible(Name: string, State)
	for _, Frame in next, Game.MainGUI:GetChildren() do
		if not Frame.Name:find(Name) then continue end
		Frame.Visible = State
	end
end
PlayerTab:NewButton("Hide team selection UI", function()
	Game:SetUIVisible("Become", false)
end)
PlayerTab:NewButton("Hide jail time", function()
	local JailUI = LocalPlayer.PlayerGui["JailTimeScreen"]
	JailUI:FindFirstChildOfClass("TextLabel").Visible = false
end)

local WeatherValues = ReplicatedStorage.Values
local Raining: BoolValue = WeatherValues.Raining
local Storming: BoolValue = WeatherValues.Storming

local DisableWeather = PlayerTab:NewToggle("Disable weather", false, function()
	Raining.Value = false
	Storming.Value = false
end)

Raining:GetPropertyChangedSignal("Value"):Connect(function()
	if DisableWeather:GetValue() then
		Raining.Value = false
	end
end)
Storming:GetPropertyChangedSignal("Value"):Connect(function()
	if DisableWeather:GetValue() then
		Storming.Value = false
	end
end)

PlayerTab:NewToggle("Respawn at death location", false, function(value)
	Char.SpawnAtDeath = value
end)
local NoClip = PlayerTab:NewToggle("No Collision", false):AddKeybind(Enum.KeyCode.C)
local InfiniteJump = PlayerTab:NewToggle("Air Jump", false):AddKeybind(Enum.KeyCode.V)

PlayerTab:NewSection("Flight")
local FlightEnabled = PlayerTab:NewToggle("Fight (WASD Shift, Space)", false):AddKeybind(Enum.KeyCode.G)
local FlySpeed = PlayerTab:NewSlider("Flight Speed", "", true, "/", {min=0.3,max=50,default=1})

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
RunService.Stepped:Connect(function()
	if not Char.Character then return end

	if FlightEnabled:GetValue() and Char.Root then
		local Speed = FlySpeed:GetValue() + (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and 3 or 0)
		local v = Char.Root.Velocity
		Char.Root.Velocity = Vector3.new(0,v.Y < 0 and math.abs(v.Y) or 0.5,0)

		pcall(function()
			local Rotation = CFrame.new(Char.Root.Position)*CFrame.Angles(0,select(2,Camera.CFrame.Rotation:ToOrientation()),0)
			Char.Root.CFrame = Rotation * CFrame.new(
				UserInputService:IsKeyDown(Enum.KeyCode.A) and -Speed or
					UserInputService:IsKeyDown(Enum.KeyCode.D) and Speed or 0
				, 
				UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and- Speed or
					UserInputService:IsKeyDown(Enum.KeyCode.Q) and -Speed or
					UserInputService:IsKeyDown(Enum.KeyCode.Space) and Speed or
					UserInputService:IsKeyDown(Enum.KeyCode.E) and Speed or 0
				, 
				UserInputService:IsKeyDown(Enum.KeyCode.W) and -Speed or
					UserInputService:IsKeyDown(Enum.KeyCode.S) and Speed or 0
			)
		end)
	end

	if NoClip:GetValue() then 
		for _, Part in next, Char.Character:GetDescendants() do
			if Part:IsA("BasePart") then
				Part.CanCollide = false
			end
		end
	end
end)

local HumanoidEntries = {
	["WalkSpeed"] = true, 
	["JumpPower"] = true, 
}

PlayerTab:NewSection("Humanoid")
for Entry, _ in next, HumanoidEntries do
	local Default = Char.Humanoid[Entry]
	local Slider = PlayerTab:NewSlider(Entry,"",true,"/",{min=Default,max=420,default=Default},function(Value)
		Char.Humanoid[Entry] = Value
	end)

	HumanoidEntries[Entry] = Slider
end

coroutine.wrap(function()
	while task.wait(.5) do
		local Humanoid = Char.Humanoid
		if not Humanoid then continue end

		for Entry, Value in next, HumanoidEntries do
			Humanoid[Entry] = Value:GetValue()
		end
	end
end)()

PlayerTab:NewSection("Drop deben")
local DropSpeed = PlayerTab:NewSlider("Drops every second","",true,"/",{min=1,max=500,default=1}, function(Amount)
	Remotes.TextToNumber:FireServer(Amount)
end)
local SpamDrops;SpamDrops=PlayerTab:NewToggle("Spam drop deben", false, function(Value)
	if not Value then return end
	local Remote = Game.MainGUI:FindFirstChild("Adfrs", true)

	while SpamDrops:GetValue() do
		Remote:FireServer()
		task.wait(1/DropSpeed:GetValue())
	end
end):AddKeybind(Enum.KeyCode.H)

local TeleportsTab = library:NewTab("Teleports")
local StoreBillboards = {}

for _, BillBoard in next, workspace:GetDescendants() do
	if BillBoard.Name ~= "StoreBillboard" or not BillBoard:IsA("BillboardGui") then
		continue
	end
	local Part: Part = BillBoard.Parent
	local PlaceName = BillBoard:FindFirstChildOfClass("TextLabel")
	table.insert(StoreBillboards, BillBoard)

	local IsLocation = PlaceName.Text == PlaceName.Text:upper()
	if not IsLocation then
		continue
	end

	TeleportsTab:NewButton(PlaceName.Text, function()
		local Offset = BillBoard.StudsOffset
		local Cframe = CFrame.new(Part.Position-Offset) * CFrame.new(0,2,0)
		Char.Character:PivotTo(Cframe)
	end)
	task.wait()
end

local AutoFarmTab = library:NewTab("AutoFarm")
local Farm = {}
local FarmCFG = CreateOptions({
	["Instant Prompts"] = true,
}, AutoFarmTab)

local OreSpawns: Folder = workspace.OreSpawns

local OreTypes = {} -- Extract ore types
for _, Type in next, OreSpawns:GetChildren()[1]:GetChildren() do
	if Type:IsA("Model") and Type.Name:find("Ore") then
		table.insert(OreTypes, Type.Name)
	end
end

function Farm:GenerateOreData(Ore: Model)
	local Mined = Ore:FindFirstChild("Mined")
	local OreType = Ore:FindFirstChild("OreType")
	if not Mined or not OreType then return print(Ore, "No an ore") end

	local ActualOre: Model = Ore[OreType.Value]
	return {
		Model = Ore,
		Type = OreType,
		Ore = ActualOre,
		Part = ActualOre:FindFirstChildOfClass("MeshPart"), -- BasePart returns nil
		Mined = Mined,
		Prompt = RecursiveFindClass(Ore, "ProximityPrompt")
	}
end 

function Farm:FindOre(FindOreType)
	local Distance, FoundOre=nil,nil

	for _, Ore in next, OreSpawns:GetChildren() do
		local OreData = Farm:GenerateOreData(Ore)

		if not OreData or OreData.Mined.Value then continue end
		if OreData.Type.Value ~= FindOreType then continue end

		local PrimaryPart = OreData.Part
		if not PrimaryPart then continue end

		local OreDistance = (PrimaryPart.Position - Char.Root.Position).Magnitude
		if not Distance or OreDistance < Distance then
			Distance = OreDistance
			FoundOre = OreData
		end
	end
	return FoundOre
end

AutoFarmTab:NewSection("Ore Types:") 
FarmCFG.CollectOres = {}

for _, OreType in next, OreTypes do
	FarmCFG.CollectOres[OreType] = AutoFarmTab:NewToggle(OreType, false)
end
function Farm:CheckInventory(Max: number, Include: string, SearchCharacter: boolean)
	local Backpack = LocalPlayer.Backpack
	local Children = Backpack:GetChildren()
	local Count = 0

	if SearchCharacter then
		local Character = Char.Character
		table.foreach(Character:GetChildren(), function(_, Tool)
			table.insert(Children, Tool)
		end)
	end

	for _, Tool in next, Children do
		if Include and not Tool.Name:find(Include) then
			continue
		end
		Count += 1
		if Count >= Max then
			return true
		end
	end
end

FarmCFG.SkipOre = false 
function Farm:Farm(Toggle)
	local function Check()
		if Toggle and not Toggle:GetValue() then
			return true
		end
		return FarmCFG.SkipOre 
	end

	for OreType, FindOre in next, FarmCFG.CollectOres do
		task.wait()

		if not FindOre:GetValue() then continue end
		if Check() then break end

		local Ore: SharedTable = Farm:FindOre(OreType)
		if not Ore then continue end

		local ProxPrompt = Ore.Prompt
		if not ProxPrompt then continue end

		local Began = tick()
		local MaxTime = 3

		repeat 
			Char.Character:PivotTo(Ore.Part.CFrame)
			fireproximityprompt(ProxPrompt, math.huge)
			task.wait(.05)
		until Ore.Mined.Value or tick()-Began > MaxTime or Check()
		FarmCFG.SkipOre = false 
	end
	FarmCFG.SkipOre = false 
end

AutoFarmTab:NewSection("Auto Farm:")
FarmCFG.AutoFarm = AutoFarmTab:NewToggle("Farm Ores", false, function(value)
	if not value then
		return 
	end

	local self = FarmCFG.AutoFarm
	local Saved = Char.Character:GetPivot()
	FarmCFG.SkipOre = false 

	if not Farm:CheckInventory(1, "Pickaxe", true) then
		self:Set(false)
		library:Notify("You do not own a pickaxe!", 8, "alert")
		return 
	end

	repeat
		Farm:Farm(self)
	until not self:GetValue()

	Char.Character:PivotTo(Saved)
end):AddKeybind(Enum.KeyCode.F)

local WheatPlots = {}
local SellPoints = {}
for _, Part in next, workspace:GetDescendants() do
	if Part.Name == "WheatPlot" then
		table.insert(WheatPlots, Part)
		continue
	end
	if Part.Name == "Sell" then
		table.insert(SellPoints, Part)
		continue
	end
end

FarmCFG.AutoFarmWheet = AutoFarmTab:NewToggle("Farm Wheet", false, function(value)
	if not value then
		return
	end

	local self = FarmCFG.AutoFarmWheet
	local Saved = Char.Character:GetPivot()

	repeat
		for _, Plot in next, WheatPlots do
			for _, Node in next, Plot:GetChildren() do
				if Node.Name ~= "WheatNode" then
					continue
				end
				local Prompt = RecursiveFindClass(Node, "ProximityPrompt")
				if not Prompt then
					continue
				end

				local Part: Part = Prompt.Parent.Parent
				Char.Character:PivotTo(Part:GetPivot())

				wait(.1)
				fireproximityprompt(Prompt)
				wait(.1)
				Char.Character:PivotTo(SellPoints[1]:GetPivot())
			end
		end
	until not self:GetValue()

	Char.Character:PivotTo(Saved)
end)



local BlackmarketTab = library:NewTab("Blackmarket")
local BlackmarketModel: Model = workspace:WaitForChild("BlackmarketModel")

for _, Dealer: Model in next, BlackmarketModel:GetChildren() do
	local HumanoidRootPart = Dealer:FindFirstChild("HumanoidRootPart")
	local Prompt = RecursiveFindClass(HumanoidRootPart, "ProximityPrompt")

	BlackmarketTab:NewButton(Dealer.Name, function()
		Char.Character:PivotTo(Dealer:GetPivot())
		task.wait(1)
		fireproximityprompt(Prompt)
	end)
end

local TeamsTab = library:NewTab("Teams")
local Stands: Model = workspace:WaitForChild("Stands")
for _, Team: Model in next, Stands:GetChildren() do
	if not Team.Name:find("Stand") then continue end
	local Prompt = RecursiveFindClass(Team, "ProximityPrompt")

	TeamsTab:NewButton(Team.Name, function()
		Char.Character:PivotTo(Team:GetPivot())
		task.wait(0.5)
		fireproximityprompt(Prompt)
	end)
end

local PlayersTab = library:NewTab("Players")
local Teams = game:GetService("Teams")

PlayersTab:NewButton("Teleport to Pharaoh", function()
	local Pharaoh: Player = Teams.Pharaoh:GetPlayers()[1]
	local Character = Pharaoh.Character
	if not Character then 
		library:Notify("There is no Pharaoh", 8, "alert")
		return 
	end
	Char.Character:PivotTo(Character:GetPivot())
end)

local ProximityService = game:GetService("ProximityPromptService")
ProximityService.PromptButtonHoldBegan:Connect(function(prompt)
	if FarmCFG["Instant Prompts"]:GetValue() then
		fireproximityprompt(prompt, math.huge)
	end
end)

local Alerts = {Hooks={}}
function Alerts:Hook(Includes, Callback)
	self.Hooks[Includes] = Callback
	return self
end

Alerts:Hook("too many of this ore", function(_, Child)
	local AutoFarm = FarmCFG.AutoFarm
	if not AutoFarm:GetValue() then return end

	Child.Size = UDim2.new(0,0,0,0) -- Replace notification
	library:Notify("Inventory full!", 6, "alert")
	AutoFarm:Set(false) 
end)
Alerts:Hook("Being mined by ", function(_, Child)
	Child.Size = UDim2.new(0,0,0,0)
	FarmCFG.SkipOre = true
end)

LocalPlayer.PlayerGui.DescendantAdded:Connect(function(Child)
	local AlertName = "CoolDownPopup"
	if Child.Name ~= AlertName then return end
	local Msg: string = Child.Text

	for Hook, Callback in next, Alerts.Hooks do
		if Msg:find(Hook) then
			Callback(Msg, Child)
		end
	end
end)
