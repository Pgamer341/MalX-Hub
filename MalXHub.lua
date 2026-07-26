--[[
  MalX Hub - Blox Fruit Script
  Categories: COMBAT | FRUITS | VISUAL | WORLD | MOVEMENT | PLAYER | UTILITY
  Features: 25+ toggles and controls
]]

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")

-- Player
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- Anti-Idle
LocalPlayer.Idled:Connect(function()
    VirtualInputManager:SendKeyEvent(true, "V", false, game)
    task.wait(0.5)
    VirtualInputManager:SendKeyEvent(false, "V", false, game)
end)

-- Configuration
local Config = {
    -- Combat
    AutoFarm = false,
    Aimbot = false,
    AutoSkills = false,
    FastAttack = false,
    BringEnemy = false,
    AutoQuest = false,
    AutoBoss = false,
    
    -- Fruits
    AutoFruitFind = false,
    FruitNotifier = false,
    AutoStoreFruit = false,
    AutoEatFruit = false,
    FruitESP = false,
    
    -- Visual
    PlayerESP = false,
    NpcESP = false,
    ChestESP = false,
    
    -- World
    AutoRaid = false,
    AutoSeaEvent = false,
    AutoDungeon = false,
    
    -- Movement
    InfiniteJump = false,
    NoClip = false,
    SpeedEnabled = false,
    SpeedValue = 50,
    JumpPowerValue = 100,
    
    -- Player
    AutoStatsEnabled = false,
    StatMode = "Melee",
    AutoHaki = false,
    GodMode = false,
    
    -- Utility
    SafeMode = false,
    AutoRejoin = false,
    
    -- Internal
    AimbotRange = 2000,
    SelectedTool = nil,
}

-- Fruit Detection
local FruitNames = {
    "Fruit", "Fruit2", "Bomb", "Flame", "Ice", "Light", "Dark",
    "Magma", "Sand", "Bird", "String", "Rumble", "Door", "Ghost",
    "Spider", "Diamond", "Love", "Falcon", "Rubber", "Barrier",
    "Dragon", "Venom", "Shadow", "Dough", "Soul", "Leopard",
    "Mammoth", "T-Rex", "Spirit", "Control", "Kitsune", "Yeti",
    "Gas", "Blizzard", "Gravity", "Pain", "Phoenix", "Smoke",
    "Spring", "Chop", "Spin", "Kilogram", "Revive",
}

local IslandLocations = {
    {"Jungle", CFrame.new(-1180, 30, -580)},
    {"Pirate Village", CFrame.new(-1190, 30, 880)},
    {"Desert", CFrame.new(-950, 30, 2650)},
    {"Frozen Village", CFrame.new(750, 30, -1450)},
    {"Marine Fortress", CFrame.new(-4130, 30, 2610)},
    {"Underwater City", CFrame.new(3870, 30, -1920)},
    {"Sky Island 1", CFrame.new(-4890, 230, -1040)},
    {"Sky Island 2", CFrame.new(-7790, 430, -1790)},
    {"Prison", CFrame.new(4850, 30, 1010)},
    {"Colosseum", CFrame.new(-1840, 30, -2820)},
    {"Magma Village", CFrame.new(-5410, 30, 8490)},
    {"Hot & Cold", CFrame.new(-5950, 30, -1180)},
    {"Ice Castle", CFrame.new(4100, 30, -6550)},
    {"Forgotten Island", CFrame.new(-2940, 30, -7250)},
    {"Usopp Island", CFrame.new(2810, 30, 4750)},
    {"Mansion", CFrame.new(-12590, 480, -3630)},
    {"Kingdom of Rose", CFrame.new(-8520, 180, -1530)},
    {"Sea of Treats", CFrame.new(330, 30, -9240)},
    {"Hydra Island", CFrame.new(5210, 30, -5320)},
    {"Great Tree", CFrame.new(2540, 380, -4150)},
    {"Cake Island", CFrame.new(-1940, 30, -10940)},
    {"Tiki Outpost", CFrame.new(5730, 30, 7100)},
    {"Port Town", CFrame.new(-290, 30, -6030)},
    {"Haunted Castle", CFrame.new(-9510, 130, -5980)},
    {"Mirage Island", CFrame.new(-1480, 30, 4720)},
    {"Prehistoric Island", CFrame.new(-1230, 30, 10580)},
    {"Kitsune Island", CFrame.new(420, 30, 14000)},
}

local function IsFruit(obj)
    if not obj then return false end
    local name = obj.Name
    for _, fruit in ipairs(FruitNames) do
        if string.find(string.lower(name), string.lower(fruit)) then
            return true
        end
    end
    if obj:FindFirstChild("Fruit") or obj:FindFirstChild("FruitSet") or obj:FindFirstChild("ClickDetector") then
        return true
    end
    return false
end

local function GetClosestEnemy(range)
    local closest, dist = nil, math.huge
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            local humanoid = v:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 and humanoid.MaxHealth > 0 then
                if not Players:GetPlayerFromCharacter(v) then
                    local root = v:FindFirstChild("HumanoidRootPart")
                    local mag = (root.Position - HumanoidRootPart.Position).Magnitude
                    if mag < dist and mag <= range then
                        closest = v
                        dist = mag
                    end
                end
            end
        end
    end
    return closest
end

local function GetClosestBoss(range)
    local closest, dist = nil, math.huge
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            local humanoid = v:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local name = v.Name or ""
                if string.find(string.lower(name), "boss") or string.find(string.lower(name), "raid") or humanoid.MaxHealth > 5000 then
                    if not Players:GetPlayerFromCharacter(v) then
                        local root = v:FindFirstChild("HumanoidRootPart")
                        local mag = (root.Position - HumanoidRootPart.Position).Magnitude
                        if mag < dist and mag <= range then
                            closest = v
                            dist = mag
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- ESP System
local ESPObjects = {}
local function CreateESP(instance, color, labelText)
    if ESPObjects[instance] then return end
    if not instance or not instance.Parent then return end
    
    local billboard = Instance.new("BillboardGui")
    local textLabel = Instance.new("TextLabel")
    
    billboard.Name = "MalX_ESP"
    billboard.Adornee = instance
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextScaled = true
    textLabel.TextColor3 = color or Color3.fromRGB(255, 50, 50)
    textLabel.TextStrokeTransparency = 0.3
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Text = labelText or instance.Name
    textLabel.Parent = billboard
    
    local distanceLabel = textLabel:Clone()
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.Size = UDim2.new(1, 0, 0, 20)
    distanceLabel.Position = UDim2.new(0, 0, 0, 25)
    distanceLabel.TextScaled = false
    distanceLabel.TextSize = 14
    distanceLabel.Text = ""
    distanceLabel.Parent = billboard
    
    billboard.Parent = instance
    ESPObjects[instance] = billboard
    
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not instance or not instance.Parent then
            conn:Disconnect()
            if ESPObjects[instance] then
                ESPObjects[instance]:Destroy()
                ESPObjects[instance] = nil
            end
            return
        end
        if HumanoidRootPart and instance:FindFirstChild("HumanoidRootPart") then
            local dist = (instance.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
            distanceLabel.Text = string.format("%.0f studs", dist)
        end
    end)
end

local function ClearESP()
    for _, v in pairs(ESPObjects) do
        pcall(function() v:Destroy() end)
    end
    ESPObjects = {}
end

-- Teleport Function
local function TeleportTo(cframe)
    if Character and HumanoidRootPart then
        HumanoidRootPart.CFrame = cframe
    end
end

-- ========== LOOP FUNCTIONS ==========

-- Combat: Auto Farm
local function AutoFarmLoop()
    while Config.AutoFarm do
        task.wait(0.1)
        pcall(function()
            local target = GetClosestEnemy(Config.AimbotRange)
            if target and target:FindFirstChild("HumanoidRootPart") then
                local root = target:FindFirstChild("HumanoidRootPart")
                HumanoidRootPart.CFrame = CFrame.new(root.Position + Vector3.new(0, 5, 0))
                
                local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
                if tool then tool:Activate() end
                
                if Config.AutoSkills then
                    for i = 1, 6 do
                        VirtualInputManager:SendKeyEvent(true, tostring(i), false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, tostring(i), false, game)
                        task.wait(0.3)
                    end
                end
            end
        end)
    end
end

-- Combat: Aimbot
local function AimbotLoop()
    while Config.Aimbot do
        task.wait(0.05)
        pcall(function()
            local target = GetClosestEnemy(Config.AimbotRange)
            if target and target:FindFirstChild("HumanoidRootPart") then
                local root = target:FindFirstChild("HumanoidRootPart")
                HumanoidRootPart.CFrame = CFrame.lookAt(HumanoidRootPart.Position, root.Position) * CFrame.new(0, 0, 3)
            end
        end)
    end
end

-- Combat: Fast Attack
local function FastAttackLoop()
    while Config.FastAttack do
        task.wait()
        pcall(function()
            local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
            if tool then
                tool:Activate()
                task.wait(0.01)
                local remote = tool:FindFirstChild("RemoteFunction") or tool:FindFirstChild("RemoteEvent")
                if remote then pcall(function() remote:FireServer("Activate") end) end
                local clickDetector = tool:FindFirstChild("ClickDetector") or tool:FindFirstChildWhichIsA("ClickDetector")
                if clickDetector then pcall(function() clickDetector:FireServer() end) end
            end
        end)
    end
end

-- Combat: Bring Enemy
local function BringEnemyLoop()
    while Config.BringEnemy do
        task.wait(0.3)
        pcall(function()
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
                    local hum = v:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 and not Players:GetPlayerFromCharacter(v) then
                        local root = v:FindFirstChild("HumanoidRootPart")
                        local dist = (root.Position - HumanoidRootPart.Position).Magnitude
                        if dist > 15 and dist < 300 then
                            root.CFrame = HumanoidRootPart.CFrame * CFrame.new(0, 0, -10)
                        end
                    end
                end
            end
        end)
    end
end

-- Combat: Auto Quest
local function AutoQuestLoop()
    while Config.AutoQuest do
        task.wait(2)
        pcall(function()
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("Model") and v.Name == "Quest" then
                    local clickDetector = v:FindFirstChildWhichIsA("ClickDetector")
                    if clickDetector then
                        HumanoidRootPart.CFrame = v:GetPivot() * CFrame.new(0, 5, 0)
                        task.wait(0.5)
                        clickDetector:FireServer()
                        task.wait(1)
                    end
                end
            end
        end)
    end
end

-- Combat: Auto Boss
local function AutoBossLoop()
    while Config.AutoBoss do
        task.wait(0.3)
        pcall(function()
            local boss = GetClosestBoss(5000)
            if boss and boss:FindFirstChild("HumanoidRootPart") then
                local root = boss:FindFirstChild("HumanoidRootPart")
                HumanoidRootPart.CFrame = CFrame.new(root.Position + Vector3.new(0, 10, 0))
                local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
                if tool then
                    tool:Activate()
                    if Config.AutoSkills then
                        for i = 1, 6 do
                            VirtualInputManager:SendKeyEvent(true, tostring(i), false, game)
                            task.wait(0.1)
                            VirtualInputManager:SendKeyEvent(false, tostring(i), false, game)
                            task.wait(0.3)
                        end
                    end
                end
            end
        end)
    end
end

-- Fruits: Auto Fruit Find
local function AutoFruitFindLoop()
    while Config.AutoFruitFind do
        task.wait(1)
        pcall(function()
            for _, v in pairs(Workspace:GetDescendants()) do
                if IsFruit(v) and v:IsA("BasePart") and v.Parent and not v:FindFirstChild("MalX_ESP") then
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "MalX_ESP"
                    billboard.Adornee = v
                    billboard.Size = UDim2.new(0, 200, 0, 50)
                    billboard.StudsOffset = Vector3.new(0, 3, 0)
                    billboard.AlwaysOnTop = true
                    local text = Instance.new("TextLabel")
                    text.Size = UDim2.new(1, 0, 1, 0)
                    text.BackgroundTransparency = 1
                    text.TextScaled = true
                    text.TextColor3 = Color3.fromRGB(255, 215, 0)
                    text.TextStrokeTransparency = 0.3
                    text.Text = "🌟 " .. v.Name
                    text.Parent = billboard
                    billboard.Parent = v
                    
                    if (v.Position - HumanoidRootPart.Position).Magnitude > 50 then
                        HumanoidRootPart.CFrame = CFrame.new(v.Position + Vector3.new(0, 5, 0))
                        task.wait(0.5)
                    end
                end
            end
        end)
    end
end

-- Fruits: Fruit Notifier
local fruitCache = {}
local function FruitNotifierLoop()
    while Config.FruitNotifier do
        task.wait(0.5)
        pcall(function()
            for _, v in pairs(Workspace:GetDescendants()) do
                if IsFruit(v) and v:IsA("BasePart") and v.Parent then
                    local key = v:GetFullName()
                    if not fruitCache[key] then
                        fruitCache[key] = true
                        local dist = (v.Position - HumanoidRootPart.Position).Magnitude
                        local msg = string.format("[🍎 MalX] %s spotted! Distance: %.0f studs", v.Name, dist)
                        pcall(function()
                            local notifyGui = Instance.new("ScreenGui")
                            local notifyFrame = Instance.new("TextLabel")
                            notifyGui.Name = "MalXNotify"
                            notifyGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
                            notifyFrame.Size = UDim2.new(0, 450, 0, 40)
                            notifyFrame.Position = UDim2.new(0.5, -225, 0.8, 0)
                            notifyFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                            notifyFrame.BackgroundTransparency = 0.3
                            notifyFrame.TextColor3 = Color3.fromRGB(255, 215, 0)
                            notifyFrame.TextStrokeTransparency = 0
                            notifyFrame.Font = Enum.Font.SourceSansBold
                            notifyFrame.TextSize = 20
                            notifyFrame.Text = msg
                            notifyFrame.Parent = notifyGui
                            task.delay(5, function()
                                pcall(function() notifyGui:Destroy() end)
                            end)
                        end)
                    end
                end
            end
        end)
    end
    fruitCache = {}
end

-- Fruits: Auto Store Fruit
local function AutoStoreFruitLoop()
    while Config.AutoStoreFruit do
        task.wait(2)
        pcall(function()
            for _, v in pairs(Workspace:GetDescendants()) do
                if IsFruit(v) and v:IsA("BasePart") and v.Parent and (v.Position - HumanoidRootPart.Position).Magnitude < 25 then
                    local args = {["Key"] = "FruitSupply", ["Item"] = v.Name}
                    local remote = ReplicatedStorage:FindFirstChild("RemoteEvent") or ReplicatedStorage:FindFirstChild("RemoteFunction")
                    if remote then
                        pcall(function() remote:FireServer("StoreFruit", args) end)
                    end
                    task.wait(0.5)
                end
            end
        end)
    end
end

-- Visual: ESP Loops
local function PlayerESPLoop()
    while Config.PlayerESP do
        task.wait(0.5)
        pcall(function()
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local root = player.Character:FindFirstChild("HumanoidRootPart")
                    if not root:FindFirstChild("MalX_ESP") then
                        CreateESP(root, Color3.fromRGB(255, 50, 50), "[P] " .. player.Name)
                    end
                end
            end
        end)
    end
    -- Cleanup
    for _, v in pairs(ESPObjects) do
        if v.Adornee and v.Adornee.Parent then
            local parentModel = v.Adornee.Parent
            if parentModel:IsA("Model") and Players:GetPlayerFromCharacter(parentModel) then
                pcall(function() v:Destroy() end)
            end
        end
    end
end

local function NpcESPLoop()
    while Config.NpcESP do
        task.wait(0.5)
        pcall(function()
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
                    local hum = v:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 and not Players:GetPlayerFromCharacter(v) then
                        local root = v:FindFirstChild("HumanoidRootPart")
                        if not root:FindFirstChild("MalX_ESP") then
                            local label = "[NPC] " .. v.Name
                            CreateESP(root, Color3.fromRGB(255, 200, 50), label)
                        end
                    end
                end
            end
        end)
    end
    -- Cleanup NPC ESPs
    for _, v in pairs(ESPObjects) do
        if v.Adornee and v.Adornee.Parent then
            local parentModel = v.Adornee.Parent
            if parentModel:IsA("Model") and not Players:GetPlayerFromCharacter(parentModel) then
                if not parentModel:FindFirstChild("Humanoid") then
                    pcall(function() v:Destroy() end)
                end
            end
        end
    end
end

local function ChestESPLoop()
    while Config.ChestESP do
        task.wait(1)
        pcall(function()
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("BasePart") and (string.find(string.lower(v.Name), "chest") or string.find(string.lower(v.Name), "box")) then
                    if not v:FindFirstChild("MalX_ESP") then
                        local billboard = Instance.new("BillboardGui")
                        billboard.Name = "MalX_ESP"
                        billboard.Adornee = v
                        billboard.Size = UDim2.new(0, 150, 0, 40)
                        billboard.StudsOffset = Vector3.new(0, 3, 0)
                        billboard.AlwaysOnTop = true
                        local text = Instance.new("TextLabel")
                        text.Size = UDim2.new(1, 0, 1, 0)
                        text.BackgroundTransparency = 1
                        text.TextScaled = true
                        text.TextColor3 = Color3.fromRGB(0, 255, 0)
                        text.TextStrokeTransparency = 0.3
                        text.Text = "📦 " .. v.Name
                        text.Parent = billboard
                        billboard.Parent = v
                        
                        local conn
                        conn = RunService.RenderStepped:Connect(function()
                            if not v or not v.Parent then
                                conn:Disconnect()
                                pcall(function() billboard:Destroy() end)
                            end
                        end)
                    end
                end
            end
        end)
    end
end

-- World: Auto Raid
local function AutoRaidLoop()
    while Config.AutoRaid do
        task.wait(3)
        pcall(function()
            -- Find raid NPC / enter raid
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("Model") and (string.find(string.lower(v.Name), "raid") or string.find(string.lower(v.Name), "dungeon")) then
                    local click = v:FindFirstChildWhichIsA("ClickDetector")
                    if click then
                        HumanoidRootPart.CFrame = v:GetPivot() * CFrame.new(0, 5, 0)
                        task.wait(0.5)
                        click:FireServer()
                        task.wait(2)
                    end
                end
            end
            -- Kill enemies inside raid
            local target = GetClosestEnemy(500)
            if target and target:FindFirstChild("HumanoidRootPart") then
                local root = target:FindFirstChild("HumanoidRootPart")
                HumanoidRootPart.CFrame = CFrame.new(root.Position + Vector3.new(0, 5, 0))
                local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
                if tool then tool:Activate() end
            end
        end)
    end
end

-- World: Auto Sea Event
local function AutoSeaEventLoop()
    while Config.AutoSeaEvent do
        task.wait(2)
        pcall(function()
            -- Look for sea events (sharks, terror sharks, etc.)
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
                    local name = string.lower(v.Name)
                    if string.find(name, "shark") or string.find(name, "fish") or string.find(name, "sea") or string.find(name, "beast") then
                        local hum = v:FindFirstChild("Humanoid")
                        if hum and hum.Health > 0 then
                            local root = v:FindFirstChild("HumanoidRootPart")
                            HumanoidRootPart.CFrame = CFrame.new(root.Position + Vector3.new(0, 10, 0))
                            local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
                            if tool then tool:Activate() end
                            break
                        end
                    end
                end
            end
        end)
    end
end

-- World: Auto Dungeon
local function AutoDungeonLoop()
    while Config.AutoDungeon do
        task.wait(1)
        pcall(function()
            -- Find dungeon entrance
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("Model") and string.find(string.lower(v.Name), "dungeon") then
                    local click = v:FindFirstChildWhichIsA("ClickDetector")
                    if click then
                        HumanoidRootPart.CFrame = v:GetPivot() * CFrame.new(0, 5, 0)
                        task.wait(0.5)
                        click:FireServer()
                        task.wait(2)
                    end
                end
            end
            -- Kill mobs inside
            local target = GetClosestEnemy(500)
            if target and target:FindFirstChild("HumanoidRootPart") then
                local root = target:FindFirstChild("HumanoidRootPart")
                HumanoidRootPart.CFrame = CFrame.new(root.Position + Vector3.new(0, 5, 0))
                local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
                if tool then tool:Activate() end
            end
        end)
    end
end

-- Movement: Infinite Jump
local function OnJump()
    if Config.InfiniteJump then
        HumanoidRootPart.Velocity = Vector3.new(HumanoidRootPart.Velocity.X, 50, HumanoidRootPart.Velocity.Z)
    end
end

-- Movement: No Clip
local function NoClipLoop()
    while Config.NoClip do
        task.wait(0.1)
        pcall(function()
            if Character then
                for _, part in pairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
    -- Restore collision
    pcall(function()
        if Character then
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end)
end

-- Movement: Speed
local function SpeedLoop()
    while Config.SpeedEnabled do
        task.wait(0.5)
        pcall(function()
            if Humanoid then
                Humanoid.WalkSpeed = Config.SpeedValue
            end
        end)
    end
    pcall(function() if Humanoid then Humanoid.WalkSpeed = 16 end end)
end

-- Movement: Jump Power
local function JumpPowerLoop()
    while Config.JumpPowerValue > 0 do
        task.wait(1)
        pcall(function()
            if Humanoid then
                Humanoid.JumpPower = Config.JumpPowerValue
                Humanoid.JumpHeight = Config.JumpPowerValue / 5
            end
        end)
        if not Config.AutoFarm and not Config.Aimbot and not Config.FastAttack and not Config.AutoFruitFind then
            break
        end
        task.wait(5)
    end
end

-- Player: Auto Stats
local function AutoStatsLoop()
    while Config.AutoStatsEnabled do
        task.wait(3)
        pcall(function()
            local statRemote = ReplicatedStorage:FindFirstChild("RemoteEvent") or ReplicatedStorage:FindFirstChild("RemoteFunction")
            if statRemote then
                local statType = Config.StatMode
                pcall(function() statRemote:FireServer("AddStats", statType, 1) end)
            end
        end)
    end
end

-- Player: Auto Haki
local function AutoHakiLoop()
    while Config.AutoHaki do
        task.wait(5)
        pcall(function()
            LocalPlayer.Character:FindFirstChild("Humanoid"):EquipTool(LocalPlayer.Backpack:FindFirstChild("ObservationHaki") or LocalPlayer.Character:FindFirstChild("ObservationHaki"))
            task.wait(0.5)
            -- Activate observation haki
            local args = {["Key"] = "ObservationHaki", ["Active"] = true}
            local remote = ReplicatedStorage:FindFirstChild("RemoteEvent") or ReplicatedStorage:FindFirstChild("RemoteFunction")
            if remote then pcall(function() remote:FireServer("Haki", args) end) end
        end)
    end
end

-- Player: God Mode
local function GodModeLoop()
    while Config.GodMode do
        task.wait(1)
        pcall(function()
            if Humanoid then
                Humanoid.MaxHealth = 999999
                Humanoid.Health = 999999
            end
        end)
    end
end

-- Utility: Safe Mode
local function SafeModeLoop()
    while Config.SafeMode do
        task.wait(2)
        pcall(function()
            if Humanoid and Humanoid.Health < (Humanoid.MaxHealth * 0.3) then
                -- Teleport to safe zone
                HumanoidRootPart.CFrame = CFrame.new(-1180, 30, -580) -- Jungle spawn
                -- Turn off auto farms temporarily
                Config.AutoFarm = false
                task.wait(5)
                Config.AutoFarm = true
            end
        end)
    end
end

-- Utility: Auto Rejoin
local function AutoRejoinLoop()
    while Config.AutoRejoin do
        task.wait(60)
        pcall(function()
            if Humanoid and Humanoid.Health <= 0 then
                task.wait(3)
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            end
        end)
    end
end

-- Feature Starter
local function StartFeature(name, func)
    coroutine.wrap(func)()
end

-- ========== GUI BUILDER ==========

local function CreateGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MalXHubGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = (CoreGui:FindFirstChild("RobloxGui") or CoreGui)
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 380, 0, 560)
    MainFrame.Position = UDim2.new(0.1, 0, 0.15, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 25)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Parent = MainFrame
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(150, 50, 255)
    Stroke.Thickness = 2
    Stroke.Parent = MainFrame
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 42)
    TitleBar.BackgroundColor3 = Color3.fromRGB(22, 18, 42)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 12)
    TitleCorner.Parent = TitleBar
    
    local TitleFix = Instance.new("Frame")
    TitleFix.Size = UDim2.new(1, 0, 0, 6)
    TitleFix.Position = UDim2.new(0, 0, 0, 36)
    TitleFix.BackgroundColor3 = Color3.fromRGB(22, 18, 42)
    TitleFix.BorderSizePixel = 0
    TitleFix.Parent = MainFrame
    
    local TitleText = Instance.new("TextLabel")
    TitleText.Size = UDim2.new(1, 0, 1, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = "⚡ MalX Hub"
    TitleText.TextColor3 = Color3.fromRGB(170, 100, 255)
    TitleText.Font = Enum.Font.SourceSansBold
    TitleText.TextSize = 24
    TitleText.Parent = TitleBar
    
    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -38, 0, 6)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextScaled = true
    CloseBtn.Font = Enum.Font.SourceSansBold
    CloseBtn.Parent = TitleBar
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseBtn
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
    
    -- Minimize Button
    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 30, 0, 30)
    MinBtn.Position = UDim2.new(1, -74, 0, 6)
    MinBtn.BackgroundColor3 = Color3.fromRGB(50, 45, 65)
    MinBtn.Text = "-"
    MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinBtn.TextScaled = true
    MinBtn.Font = Enum.Font.SourceSansBold
    MinBtn.Parent = TitleBar
    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(0, 6)
    MinCorner.Parent = MinBtn
    
    -- Category Tab Bar
    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(1, -10, 0, 35)
    TabBar.Position = UDim2.new(0, 5, 0, 44)
    TabBar.BackgroundColor3 = Color3.fromRGB(18, 16, 35)
    TabBar.BorderSizePixel = 0
    TabBar.Parent = MainFrame
    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 6)
    TabCorner.Parent = TabBar
    
    -- Scrolling Frame (content area)
    local ScrollingFrame = Instance.new("ScrollingFrame")
    ScrollingFrame.Size = UDim2.new(1, -10, 1, -96)
    ScrollingFrame.Position = UDim2.new(0, 5, 0, 82)
    ScrollingFrame.BackgroundTransparency = 1
    ScrollingFrame.BorderSizePixel = 0
    ScrollingFrame.ScrollBarThickness = 4
    ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(150, 50, 255)
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollingFrame.Parent = MainFrame
    
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0, 5)
    UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIListLayout.Parent = ScrollingFrame
    
    -- Status Label
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(0, 360, 0, 25)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "[MalX v2] Script Loaded ✓"
    StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 130)
    StatusLabel.Font = Enum.Font.SourceSansBold
    StatusLabel.TextSize = 16
    StatusLabel.Parent = ScrollingFrame
    
    -- Category system
    local categories = {}
    local currentCategory = "COMBAT"
    
    -- Tab buttons
    local tabData = {
        {"⚔️", "COMBAT"},
        {"🍎", "FRUITS"},
        {"👁️", "VISUAL"},
        {"🌍", "WORLD"},
        {"🚀", "MOVE"},
        {"💪", "PLAYER"},
        {"⚙️", "TOOLS"},
    }
    
    local tabButtons = {}
    local tabStartX = 5
    
    for i, data in ipairs(tabData) do
        local btn = Instance.new("TextButton")
        local btnW = 52
        btn.Size = UDim2.new(0, btnW, 0, 28)
        btn.Position = UDim2.new(0, tabStartX + (i-1) * (btnW + 3), 0, 3.5)
        btn.BackgroundColor3 = (data[2] == currentCategory) and Color3.fromRGB(120, 40, 200) or Color3.fromRGB(30, 28, 50)
        btn.Text = data[1]
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextScaled = true
        btn.Font = Enum.Font.SourceSansBold
        btn.Parent = TabBar
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 5)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            currentCategory = data[2]
            -- Update tab colors
            for _, tb in pairs(tabButtons) do
                tb.BackgroundColor3 = Color3.fromRGB(30, 28, 50)
            end
            btn.BackgroundColor3 = Color3.fromRGB(120, 40, 200)
            -- Rebuild visible content
            RebuildContent()
        end)
        
        table.insert(tabButtons, btn)
    end
    
    -- Local function to create a separator
    local function CreateSeparator(text)
        local sep = Instance.new("Frame")
        sep.Size = UDim2.new(0, 360, 0, 28)
        sep.BackgroundColor3 = Color3.fromRGB(25, 22, 45)
        sep.BorderSizePixel = 0
        local sepCorner = Instance.new("UICorner")
        sepCorner.CornerRadius = UDim.new(0, 5)
        sepCorner.Parent = sep
        local sepText = Instance.new("TextLabel")
        sepText.Size = UDim2.new(1, 0, 1, 0)
        sepText.BackgroundTransparency = 1
        sepText.Text = text
        sepText.TextColor3 = Color3.fromRGB(170, 100, 255)
        sepText.Font = Enum.Font.SourceSansBold
        sepText.TextSize = 16
        sepText.Parent = sep
        return sep
    end
    
    -- Local function to create a toggle
    local function CreateToggle(text, configKey, defaultState)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 360, 0, 42)
        frame.BackgroundColor3 = Color3.fromRGB(20, 18, 35)
        frame.BorderSizePixel = 0
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 6)
        frameCorner.Parent = frame
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 55, 0, 28)
        btn.Position = UDim2.new(1, -63, 0, 7)
        btn.BackgroundColor3 = defaultState and Color3.fromRGB(120, 40, 200) or Color3.fromRGB(45, 42, 60)
        btn.Text = defaultState and "ON" or "OFF"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextScaled = true
        btn.Font = Enum.Font.SourceSansBold
        btn.Parent = frame
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 5)
        btnCorner.Parent = btn
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 280, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextColor3 = Color3.fromRGB(220, 220, 230)
        label.Font = Enum.Font.SourceSansSemibold
        label.TextSize = 15
        label.Parent = frame
        
        local state = defaultState or false
        Config[configKey] = state
        
        btn.MouseButton1Click:Connect(function()
            state = not state
            Config[configKey] = state
            btn.BackgroundColor3 = state and Color3.fromRGB(120, 40, 200) or Color3.fromRGB(45, 42, 60)
            btn.Text = state and "ON" or "OFF"
            StatusLabel.Text = string.format("[MalX] %s → %s", text, state and "ENABLED" or "DISABLED")
            StatusLabel.TextColor3 = state and Color3.fromRGB(100, 255, 130) or Color3.fromRGB(255, 150, 50)
            
            -- Start/stop feature loops
            if configKey == "AutoFarm" and state then StartFeature("AutoFarm", AutoFarmLoop)
            elseif configKey == "Aimbot" and state then StartFeature("Aimbot", AimbotLoop)
            elseif configKey == "FastAttack" and state then StartFeature("FastAttack", FastAttackLoop)
            elseif configKey == "BringEnemy" and state then StartFeature("BringEnemy", BringEnemyLoop)
            elseif configKey == "AutoQuest" and state then StartFeature("AutoQuest", AutoQuestLoop)
            elseif configKey == "AutoBoss" and state then StartFeature("AutoBoss", AutoBossLoop)
            elseif configKey == "AutoFruitFind" and state then StartFeature("AutoFruitFind", AutoFruitFindLoop)
            elseif configKey == "FruitNotifier" and state then StartFeature("FruitNotifier", FruitNotifierLoop)
            elseif configKey == "AutoStoreFruit" and state then StartFeature("AutoStoreFruit", AutoStoreFruitLoop)
            elseif configKey == "PlayerESP" and state then StartFeature("PlayerESP", PlayerESPLoop)
            elseif configKey == "NpcESP" and state then StartFeature("NpcESP", NpcESPLoop)
            elseif configKey == "ChestESP" and state then StartFeature("ChestESP", ChestESPLoop)
            elseif configKey == "AutoRaid" and state then StartFeature("AutoRaid", AutoRaidLoop)
            elseif configKey == "AutoSeaEvent" and state then StartFeature("AutoSeaEvent", AutoSeaEventLoop)
            elseif configKey == "AutoDungeon" and state then StartFeature("AutoDungeon", AutoDungeonLoop)
            elseif configKey == "NoClip" and state then StartFeature("NoClip", NoClipLoop)
            elseif configKey == "SpeedEnabled" and state then StartFeature("Speed", SpeedLoop)
            elseif configKey == "AutoStatsEnabled" and state then StartFeature("AutoStats", AutoStatsLoop)
            elseif configKey == "AutoHaki" and state then StartFeature("AutoHaki", AutoHakiLoop)
            elseif configKey == "GodMode" and state then StartFeature("GodMode", GodModeLoop)
            elseif configKey == "SafeMode" and state then StartFeature("SafeMode", SafeModeLoop)
            elseif configKey == "AutoRejoin" and state then StartFeature("AutoRejoin", AutoRejoinLoop)
            end
        end)
        
        return frame, btn
    end
    
    -- Local function to create a dropdown-style button list
    local function CreateTeleportButton(name, cframe)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 360, 0, 34)
        frame.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
        frame.BorderSizePixel = 0
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 5)
        frameCorner.Parent = frame
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 1, -4)
        btn.Position = UDim2.new(0, 5, 0, 2)
        btn.BackgroundColor3 = Color3.fromRGB(50, 35, 100)
        btn.Text = "📍 " .. name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextScaled = true
        btn.Font = Enum.Font.SourceSansSemibold
        btn.Parent = frame
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            TeleportTo(cframe)
            StatusLabel.Text = string.format("[MalX] Teleported to %s", name)
            StatusLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
        end)
        
        return frame
    end
    
    -- Content builder per category
    function RebuildContent()
        -- Clear scrolling frame children except status label
        for _, child in pairs(ScrollingFrame:GetChildren()) do
            if child ~= StatusLabel and child ~= UIListLayout then
                child:Destroy()
            end
        end
        
        if currentCategory == "COMBAT" then
            CreateSeparator("⚔️ COMBAT FEATURES").Parent = ScrollingFrame
            CreateToggle("Auto Farm", "AutoFarm", false).Parent = ScrollingFrame
            CreateToggle("Aimbot", "Aimbot", false).Parent = ScrollingFrame
            CreateToggle("Auto Skills (1-6)", "AutoSkills", false).Parent = ScrollingFrame
            CreateToggle("Fast Attack", "FastAttack", false).Parent = ScrollingFrame
            CreateToggle("Bring Enemy", "BringEnemy", false).Parent = ScrollingFrame
            CreateToggle("Auto Quest", "AutoQuest", false).Parent = ScrollingFrame
            CreateToggle("Auto Boss", "AutoBoss", false).Parent = ScrollingFrame
            
        elseif currentCategory == "FRUITS" then
            CreateSeparator("🍎 FRUIT FEATURES").Parent = ScrollingFrame
            CreateToggle("Auto Fruit Find", "AutoFruitFind", false).Parent = ScrollingFrame
            CreateToggle("Fruit Notifier", "FruitNotifier", false).Parent = ScrollingFrame
            CreateToggle("Auto Store Fruit", "AutoStoreFruit", false).Parent = ScrollingFrame
            
        elseif currentCategory == "VISUAL" then
            CreateSeparator("👁️ VISUAL FEATURES").Parent = ScrollingFrame
            CreateToggle("Player ESP", "PlayerESP", false).Parent = ScrollingFrame
            CreateToggle("NPC/Enemy ESP", "NpcESP", false).Parent = ScrollingFrame
            CreateToggle("Chest ESP", "ChestESP", false).Parent = ScrollingFrame
            
        elseif currentCategory == "WORLD" then
            CreateSeparator("🌍 WORLD FEATURES").Parent = ScrollingFrame
            CreateToggle("Auto Raid", "AutoRaid", false).Parent = ScrollingFrame
            CreateToggle("Auto Sea Event", "AutoSeaEvent", false).Parent = ScrollingFrame
            CreateToggle("Auto Dungeon", "AutoDungeon", false).Parent = ScrollingFrame
            
            CreateSeparator("🌍 ISLAND TELEPORT").Parent = ScrollingFrame
            -- Show teleport buttons (first 15 to avoid overflow)
            local count = 0
            for _, loc in ipairs(IslandLocations) do
                if count >= 15 then break end
                CreateTeleportButton(loc[1], loc[2]).Parent = ScrollingFrame
                count = count + 1
            end
            
        elseif currentCategory == "MOVE" then
            CreateSeparator("🚀 MOVEMENT FEATURES").Parent = ScrollingFrame
            CreateToggle("Infinite Jump", "InfiniteJump", false).Parent = ScrollingFrame
            -- Jump binding
            if Config.InfiniteJump then
                UserInputService.JumpRequest:Connect(OnJump)
            end
            
            CreateToggle("No Clip", "NoClip", false).Parent = ScrollingFrame
            
            local speedFrame = Instance.new("Frame")
            speedFrame.Size = UDim2.new(0, 360, 0, 42)
            speedFrame.BackgroundColor3 = Color3.fromRGB(20, 18, 35)
            speedFrame.BorderSizePixel = 0
            local speedCorner = Instance.new("UICorner")
            speedCorner.CornerRadius = UDim.new(0, 6)
            speedCorner.Parent = speedFrame
            
            local speedLabel = Instance.new("TextLabel")
            speedLabel.Size = UDim2.new(0, 280, 1, 0)
            speedLabel.Position = UDim2.new(0, 10, 0, 0)
            speedLabel.BackgroundTransparency = 1
            speedLabel.Text = "Speed: " .. Config.SpeedValue
            speedLabel.TextXAlignment = Enum.TextXAlignment.Left
            speedLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
            speedLabel.Font = Enum.Font.SourceSansSemibold
            speedLabel.TextSize = 15
            speedLabel.Parent = speedFrame
            
            local speedBtn = Instance.new("TextButton")
            speedBtn.Size = UDim2.new(0, 55, 0, 28)
            speedBtn.Position = UDim2.new(1, -63, 0, 7)
            speedBtn.BackgroundColor3 = Config.SpeedEnabled and Color3.fromRGB(120, 40, 200) or Color3.fromRGB(45, 42, 60)
            speedBtn.Text = Config.SpeedEnabled and "ON" or "OFF"
            speedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            speedBtn.TextScaled = true
            speedBtn.Font = Enum.Font.SourceSansBold
            speedBtn.Parent = speedFrame
            local speedBtnCorner = Instance.new("UICorner")
            speedBtnCorner.CornerRadius = UDim.new(0, 5)
            speedBtnCorner.Parent = speedBtn
            
            speedBtn.MouseButton1Click:Connect(function()
                Config.SpeedEnabled = not Config.SpeedEnabled
                speedBtn.BackgroundColor3 = Config.SpeedEnabled and Color3.fromRGB(120, 40, 200) or Color3.fromRGB(45, 42, 60)
                speedBtn.Text = Config.SpeedEnabled and "ON" or "OFF"
                if Config.SpeedEnabled then StartFeature("Speed", SpeedLoop) end
            end)
            speedFrame.Parent = ScrollingFrame
            
            -- Jump Power slider-like (simple up/down)
            local jumpFrame = Instance.new("Frame")
            jumpFrame.Size = UDim2.new(0, 360, 0, 34)
            jumpFrame.BackgroundColor3 = Color3.fromRGB(20, 18, 35)
            jumpFrame.BorderSizePixel = 0
            local jumpCorner = Instance.new("UICorner")
            jumpCorner.CornerRadius = UDim.new(0, 6)
            jumpCorner.Parent = jumpFrame
            
            local jumpLabel = Instance.new("TextLabel")
            jumpLabel.Size = UDim2.new(0, 360, 1, 0)
            jumpLabel.BackgroundTransparency = 1
            jumpLabel.Text = "Jump Power: " .. Config.JumpPowerValue
            jumpLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
            jumpLabel.Font = Enum.Font.SourceSansSemibold
            jumpLabel.TextSize = 15
            jumpLabel.Parent = jumpFrame
            
            jumpFrame.Parent = ScrollingFrame
            
            -- Jump controls
            local jumpCtrlFrame = Instance.new("Frame")
            jumpCtrlFrame.Size = UDim2.new(0, 360, 0, 34)
            jumpCtrlFrame.BackgroundTransparency = 1
            jumpCtrlFrame.Parent = ScrollingFrame
            
            local jDown = Instance.new("TextButton")
            jDown.Size = UDim2.new(0, 175, 0, 30)
            jDown.Position = UDim2.new(0, 0, 0, 2)
            jDown.BackgroundColor3 = Color3.fromRGB(60, 40, 80)
            jDown.Text = "-10"
            jDown.TextColor3 = Color3.fromRGB(255, 255, 255)
            jDown.TextScaled = true
            jDown.Font = Enum.Font.SourceSansBold
            jDown.Parent = jumpCtrlFrame
            local jDownCorner = Instance.new("UICorner")
            jDownCorner.CornerRadius = UDim.new(0, 5)
            jDownCorner.Parent = jDown
            jDown.MouseButton1Click:Connect(function()
                Config.JumpPowerValue = math.max(50, Config.JumpPowerValue - 10)
                Humanoid.JumpPower = Config.JumpPowerValue
                jumpLabel.Text = "Jump Power: " .. Config.JumpPowerValue
            end)
            
            local jUp = Instance.new("TextButton")
            jUp.Size = UDim2.new(0, 175, 0, 30)
            jUp.Position = UDim2.new(0, 185, 0, 2)
            jUp.BackgroundColor3 = Color3.fromRGB(60, 40, 80)
            jUp.Text = "+10"
            jUp.TextColor3 = Color3.fromRGB(255, 255, 255)
            jUp.TextScaled = true
            jUp.Font = Enum.Font.SourceSansBold
            jUp.Parent = jumpCtrlFrame
            local jUpCorner = Instance.new("UICorner")
            jUpCorner.CornerRadius = UDim.new(0, 5)
            jUpCorner.Parent = jUp
            jUp.MouseButton1Click:Connect(function()
                Config.JumpPowerValue = math.min(500, Config.JumpPowerValue + 10)
                Humanoid.JumpPower = Config.JumpPowerValue
                jumpLabel.Text = "Jump Power: " .. Config.JumpPowerValue
            end)
            
        elseif currentCategory == "PLAYER" then
            CreateSeparator("💪 PLAYER FEATURES").Parent = ScrollingFrame
            CreateToggle("Auto Stats", "AutoStatsEnabled", false).Parent = ScrollingFrame
            
            -- Stat mode selector
            local statFrame = Instance.new("Frame")
            statFrame.Size = UDim2.new(0, 360, 0, 34)
            statFrame.BackgroundColor3 = Color3.fromRGB(20, 18, 35)
            statFrame.BorderSizePixel = 0
            local statCorner = Instance.new("UICorner")
            statCorner.CornerRadius = UDim.new(0, 6)
            statCorner.Parent = statFrame
            
            local statLabel = Instance.new("TextLabel")
            statLabel.Size = UDim2.new(0, 160, 1, 0)
            statLabel.Position = UDim2.new(0, 10, 0, 0)
            statLabel.BackgroundTransparency = 1
            statLabel.Text = "Stat Mode:"
            statLabel.TextXAlignment = Enum.TextXAlignment.Left
            statLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
            statLabel.Font = Enum.Font.SourceSansSemibold
            statLabel.TextSize = 15
            statLabel.Parent = statFrame
            
            local modes = {"Melee", "Defense", "Sword", "Gun", "Fruit"}
            local modeBtnWidth = 60
            for i, mode in ipairs(modes) do
                local mBtn = Instance.new("TextButton")
                mBtn.Size = UDim2.new(0, modeBtnWidth, 0, 26)
                mBtn.Position = UDim2.new(0, 165 + (i-1) * (modeBtnWidth + 3), 0, 4)
                mBtn.BackgroundColor3 = (mode == Config.StatMode) and Color3.fromRGB(120, 40, 200) or Color3.fromRGB(40, 38, 55)
                mBtn.Text = mode
                mBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                mBtn.TextScaled = true
                mBtn.Font = Enum.Font.SourceSansBold
                mBtn.Parent = statFrame
                local mBtnCorner = Instance.new("UICorner")
                mBtnCorner.CornerRadius = UDim.new(0, 4)
                mBtnCorner.Parent = mBtn
                mBtn.MouseButton1Click:Connect(function()
                    Config.StatMode = mode
                    for _, child in pairs(statFrame:GetChildren()) do
                        if child:IsA("TextButton") then
                            child.BackgroundColor3 = Color3.fromRGB(40, 38, 55)
                        end
                    end
                    mBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 200)
                end)
            end
            statFrame.Parent = ScrollingFrame
            
            CreateToggle("Auto Haki", "AutoHaki", false).Parent = ScrollingFrame
            CreateToggle("God Mode", "GodMode", false).Parent = ScrollingFrame
            
        elseif currentCategory == "TOOLS" then
            CreateSeparator("⚙️ UTILITY TOOLS").Parent = ScrollingFrame
            CreateToggle("Safe Mode", "SafeMode", false).Parent = ScrollingFrame
            CreateToggle("Auto Rejoin on Death", "AutoRejoin", false).Parent = ScrollingFrame
            
            CreateSeparator("🛠️ QUICK ACTIONS").Parent = ScrollingFrame
            
            -- Refresh Character
            local refreshFrame = Instance.new("Frame")
            refreshFrame.Size = UDim2.new(0, 360, 0, 34)
            refreshFrame.BackgroundColor3 = Color3.fromRGB(20, 18, 35)
            refreshFrame.BorderSizePixel = 0
            local refreshCorner = Instance.new("UICorner")
            refreshCorner.CornerRadius = UDim.new(0, 6)
            refreshCorner.Parent = refreshFrame
            
            local refreshBtn = Instance.new("TextButton")
            refreshBtn.Size = UDim2.new(1, -10, 1, -4)
            refreshBtn.Position = UDim2.new(0, 5, 0, 2)
            refreshBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 180)
            refreshBtn.Text = "🔄 Respawn / Refresh Character"
            refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            refreshBtn.TextScaled = true
            refreshBtn.Font = Enum.Font.SourceSansBold
            refreshBtn.Parent = refreshFrame
            local refreshBtnCorner = Instance.new("UICorner")
            refreshBtnCorner.CornerRadius = UDim.new(0, 5)
            refreshBtnCorner.Parent = refreshBtn
            refreshBtn.MouseButton1Click:Connect(function()
                Humanoid.Health = 0
                task.wait(2)
                StatusLabel.Text = "[MalX] Character respawned"
                StatusLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
            end)
            refreshFrame.Parent = ScrollingFrame
            
            -- Clear ESP
            local clearFrame = Instance.new("Frame")
            clearFrame.Size = UDim2.new(0, 360, 0, 34)
            clearFrame.BackgroundColor3 = Color3.fromRGB(20, 18, 35)
            clearFrame.BorderSizePixel = 0
            local clearCorner = Instance.new("UICorner")
            clearCorner.CornerRadius = UDim.new(0, 6)
            clearCorner.Parent = clearFrame
            
            local clearBtn = Instance.new("TextButton")
            clearBtn.Size = UDim2.new(1, -10, 1, -4)
            clearBtn.Position = UDim2.new(0, 5, 0, 2)
            clearBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
            clearBtn.Text = "🗑️ Clear All ESP"
            clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            clearBtn.TextScaled = true
            clearBtn.Font = Enum.Font.SourceSansBold
            clearBtn.Parent = clearFrame
            local clearBtnCorner = Instance.new("UICorner")
            clearBtnCorner.CornerRadius = UDim.new(0, 5)
            clearBtnCorner.Parent = clearBtn
            clearBtn.MouseButton1Click:Connect(function()
                ClearESP()
                StatusLabel.Text = "[MalX] All ESP cleared"
                StatusLabel.TextColor3 = Color3.fromRGB(255, 150, 50)
            end)
            clearFrame.Parent = ScrollingFrame
            
            -- Credits
            CreateSeparator("™️ MALX HUB").Parent = ScrollingFrame
            local creditFrame = Instance.new("Frame")
            creditFrame.Size = UDim2.new(0, 360, 0, 50)
            creditFrame.BackgroundColor3 = Color3.fromRGB(15, 13, 28)
            creditFrame.BorderSizePixel = 0
            local creditCorner = Instance.new("UICorner")
            creditCorner.CornerRadius = UDim.new(0, 6)
            creditCorner.Parent = creditFrame
            
            local creditText = Instance.new("TextLabel")
            creditText.Size = UDim2.new(1, 0, 0, 20)
            creditText.Position = UDim2.new(0, 0, 0, 5)
            creditText.BackgroundTransparency = 1
            creditText.Text = "⚡ MalX Hub "
            creditText.TextColor3 = Color3.fromRGB(150, 80, 220)
            creditText.Font = Enum.Font.SourceSansBold
            creditText.TextSize = 16
            creditText.Parent = creditFrame
            
            local creditSub = Instance.new("TextLabel")
            creditSub.Size = UDim2.new(1, 0, 0, 18)
            creditSub.Position = UDim2.new(0, 0, 0, 28)
            creditSub.BackgroundTransparency = 1
            creditSub.Text = "25+ Features | Keyless | 2026"
            creditSub.TextColor3 = Color3.fromRGB(100, 100, 130)
            creditSub.Font = Enum.Font.SourceSans
            creditSub.TextSize = 13
            creditSub.Parent = creditFrame
            
            creditFrame.Parent = ScrollingFrame
        end
        
        -- Resize canvas
        task.wait(0.05)
        ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 20)
    end
    
    -- Minimize
    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        ScrollingFrame.Visible = not minimized
        TabBar.Visible = not minimized
        MainFrame.Size = minimized and UDim2.new(0, 380, 0, 42) or UDim2.new(0, 380, 0, 560)
        MinBtn.Text = minimized and "+" or "-"
    end)
    
    -- Destroy old instance
    pcall(function()
        if CoreGui:FindFirstChild("MalXHubGUI") then
            CoreGui:FindFirstChild("MalXHubGUI"):Destroy()
        end
    end)
    
    -- Build initial content
    RebuildContent()
    
    return ScreenGui
end

-- ========== LAUNCH ==========

-- Infinite Jump handler
UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        HumanoidRootPart.Velocity = Vector3.new(HumanoidRootPart.Velocity.X, 60, HumanoidRootPart.Velocity.Z)
    end
end)

CreateGUI()

-- Load notification
LocalPlayer:WaitForChild("PlayerGui")
local notify = Instance.new("ScreenGui")
local notifyText = Instance.new("TextLabel")
notify.Name = "MalXLoadNotify"
notify.Parent = LocalPlayer.PlayerGui

notifyText.Size = UDim2.new(0, 420, 0, 45)
notifyText.Position = UDim2.new(0.5, -210, 0.25, 0)
notifyText.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
notifyText.BackgroundTransparency = 0.25
notifyText.TextColor3 = Color3.fromRGB(170, 100, 255)
notifyText.Text = "⚡ MalX Hub Loaded! Press Insert to toggle GUI"
notifyText.Font = Enum.Font.SourceSansBold
notifyText.TextSize = 20
notifyText.TextStrokeTransparency = 0
notifyText.Parent = notify

task.delay(5, function()
    pcall(function() notify:Destroy() end)
end)

-- Insert key to toggle GUI
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        local gui = CoreGui:FindFirstChild("MalXHubGUI")
        if gui then
            gui.Enabled = not gui.Enabled
        end
    end
end)
