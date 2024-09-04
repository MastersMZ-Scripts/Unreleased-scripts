local library = loadstring(game:HttpGet(('https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wall%20v3')))()

local LocalPlayer = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera 

local Player = {}
Player.NextSpawnPosition = nil
Player.SpawnAtDeathPosition = false
Player.DeathPosition = CFrame.new()

local WeebTycoon = {}
WeebTycoon.Crates = {"UwU Crate", "MoneyBag"}
WeebTycoon.NPCS = workspace.npc
WeebTycoon.Remotes = ReplicatedStorage.RemoteEvents

function CreateWindow(Name)
	return library:CreateWindow(Name):CreateFolder("Why do you play this game")
end

-- Player library
function CharacterAdded(Character)
	Player.Character = Character
	Player.Root = Character:WaitForChild("HumanoidRootPart")
	Player.Humanoid = Player.Character:WaitForChild("Humanoid")
	
	Player.Humanoid.Died:Connect(function()
		Player.DeathPosition = Player.Root.CFrame
	end)
	
	if Player.SpawnAtDeathPosition then
		Player:Goto(Player.DeathPosition)
	end
	if Player.NextSpawnPosition then
		Player:Goto(Player.NextSpawnPosition)
		Player.NextSpawnPosition = nil
	end
end

function Player:Goto(CFrame)
	Player.Humanoid.Sit = false
	Player.Root.Velocity = Vector3.new(0,0,0)
	Player.Root.CFrame = CFrame
end

function Player:HasItem(ItemName)
	if typeof(ItemName) == "Instance" then
		ItemName = ItemName.Name
	end
	return LocalPlayer.Backpack:FindFirstChild(ItemName) or Player.Character:FindFirstChild(ItemName)
end

CharacterAdded(LocalPlayer.Character)
LocalPlayer.CharacterAdded:Connect(CharacterAdded)

--- Game wrapper

function WeebTycoon:BuyGirl(Type)
	WeebTycoon.Remotes.HatchPet:FireServer(Type)
end
function WeebTycoon:EquipGirl(AnimeGirl)
	WeebTycoon.Remotes.EquipPet:FireServer(AnimeGirl)
end
function WeebTycoon:DeleteGirl(AnimeGirl)
	WeebTycoon.Remotes.DeletePet:FireServer(AnimeGirl)
end
function WeebTycoon:UnEquip(SlotNumber)
	WeebTycoon.Remotes.UnequipPet:FireServer(SlotNumber)
end

function WeebTycoon:GetOwned()
	local Owned = {}
	for _, Cute in next, LocalPlayer.PetInventory:GetChildren() do
		table.insert(Cute.Value)
	end
	return Owned
end
---


------------
local Menu_LocalPlayer = CreateWindow("Local Player") 

Menu_LocalPlayer:Slider("Walkspeed",{
	min = 16,
	max = 100,
	precise = false 
},function(value)
	Player.Humanoid.WalkSpeed = value
end)

Menu_LocalPlayer:Slider("JumpPower",{
	min = 40,
	max = 300,
	precise = false 
},function(value)
	Player.Humanoid.UseJumpPower = true
	Player.Humanoid.JumpPower = value
end)

Menu_LocalPlayer:Toggle("Spawn at death point",function(bool)
	Player.SpawnAtDeathPosition = bool
end)
------------
local Menu_AnimeGirls = CreateWindow("Egirls") 

Menu_AnimeGirls:Label("Get therapy",{
	TextSize = 25,
	TextColor = Color3.fromRGB(255,255,255),
	BgColor = Color3.fromRGB(69,69,69)
}) 

for _, GirlType in next, workspace.Incubators:GetChildren() do
	Menu_AnimeGirls:Button(("Buy %s girl"):format(GirlType.Name:split(" ")[1]) ,function()
		WeebTycoon:BuyGirl(GirlType)
	end)
end
Menu_AnimeGirls:Button("Equip all egirls",function()
	for _, Babe in next, WeebTycoon:GetOwned() do
		WeebTycoon:EquipGirl(Babe)
	end
end)
Menu_AnimeGirls:Button("Unequip all girls",function()
	for _, goodbye in LocalPlayer.PetsEquipped:GetChildren() do
		WeebTycoon:UnEquip(goodbye.Name)
	end
end)
Menu_AnimeGirls:Button("Make girls single (sigma)",function()
	for _, IMissYou in next, WeebTycoon:GetOwned() do
		WeebTycoon:DeleteGirl(IMissYou)
	end
end)
------------
local Menu_Crates = CreateWindow("UWU Crates") 

Menu_Crates:Button("Claim sussy collectables",function()
	local Saved = Player.Root.CFrame
	
	for _, Box in next, workspace:GetChildren() do
		if not table.find(WeebTycoon.Crates, Box.Name) then
			continue
		end
		
		local ProximityPrompt=Box:FindFirstChildOfClass("ProximityPrompt")
		local Start = tick()

		ProximityPrompt.HoldDuration = 0
		Box.CanCollide = false

		repeat 
			Box.Velocity = Vector3.new(0,0,0)
			Player:Goto(Box.CFrame*CFrame.new(0,0,3))

			ProximityPrompt:InputHoldBegin()
			task.wait()
			ProximityPrompt:InputHoldEnd()
		until (not Box or Box.Parent == nil) or (tick()-Start>3)
	end

	Player:Goto(Saved)
end)
