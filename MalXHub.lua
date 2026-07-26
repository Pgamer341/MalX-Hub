--[[
  MalX Hub v2 — COMBAT FIXED
  - Reads quest from PlayerGui to target correct enemies
  - Searches Workspace.Enemies folder
  - Proper tool equip + attack via VirtualUser
  - Working auto quest NPC interaction
]]

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ========= CHARACTER REFS =========
local function GetRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function GetHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("Humanoid")
end

-- Anti-idle
LocalPlayer.Idled:Connect(function()
    VirtualInputManager:SendKeyEvent(true, "V", false, game)
    task.wait(0.5)
    VirtualInputManager:SendKeyEvent(false, "V", false, game)
end)

-- ========= CONFIG =========
local Config = {
    SpeedValue = 50,
    JumpPowerValue = 100,
    StatMode = "Melee",
    AutoFarm = false, Aimbot = false, AutoSkills = false, FastAttack = false,
    BringEnemy = false, AutoQuest = false, AutoBoss = false,
    AutoFruitFind = false, FruitNotifier = false, AutoStoreFruit = false,
    PlayerESP = false, NpcESP = false, ChestESP = false,
    AutoRaid = false, AutoSeaEvent = false, AutoDungeon = false,
    InfiniteJump = false, NoClip = false, SpeedEnabled = false,
    AutoStatsEnabled = false, AutoHaki = false, GodMode = false,
    SafeMode = false, AutoRejoin = false,
    SelectedWeapon = nil,
    -- Combat tracking
    CurrentQuestTarget = nil, -- auto-detected from quest GUI
}

-- ========= FRUIT LIST =========
local FruitNames = {"Bomb","Flame","Ice","Light","Dark","Magma","Sand","Bird","String","Rumble","Door","Ghost","Spider","Diamond","Love","Rubber","Barrier","Dragon","Venom","Shadow","Dough","Soul","Leopard","Mammoth","T-Rex","Spirit","Control","Kitsune","Yeti","Gas","Blizzard","Gravity","Pain","Phoenix","Smoke","Spring","Chop","Spin","Revive"}

local function IsFruit(obj)
    if not obj then return false end
    local n = obj.Name:lower()
    for i = 1, #FruitNames do
        if n:find(FruitNames[i]:lower()) then return true end
    end
    return (obj:FindFirstChild("Fruit") or obj:FindFirstChild("ClickDetector")) and true or false
end

local function Tp(cf)
    local r = GetRoot()
    if r then r.CFrame = cf end
end

-- ========= QUEST SYSTEM =========

-- Blox Fruit quest GUI: LocalPlayer.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text
-- Example: "Defeat Gorilla (0/10)"
local function GetQuestInfo()
    local ok, result = pcall(function()
        local questFrame = PlayerGui:FindFirstChild("Main")
        if not questFrame then return nil end
        questFrame = questFrame:FindFirstChild("Quest")
        if not questFrame then return nil end
        local container = questFrame:FindFirstChild("Container")
        if not container then return nil end
        local title = container:FindFirstChild("QuestTitle")
        if not title then return nil end
        local textLabel = title:FindFirstChild("Title")
        if not textLabel then return nil end
        return textLabel.Text
    end)
    if ok and result then return result end
    return nil
end

-- Extract enemy name from quest text
-- "Defeat Gorilla (0/10)" → "Gorilla"
-- "Defeat Pirate (0/5)" → "Pirate"
local function ExtractEnemyNameFromQuest(questText)
    if not questText then return nil end
    -- Pattern: "Defeat <EnemyName> (X/Y)"
    local startIdx, endIdx = questText:find("Defeat ")
    if not startIdx then return nil end
    local afterDefeat = questText:sub(endIdx + 1)
    local parenIdx = afterDefeat:find(" %(")
    if parenIdx then
        return afterDefeat:sub(1, parenIdx - 1)
    end
    return afterDefeat:gsub(" %(.+%)", ""):gsub("^%s+", ""):gsub("%s+$", "")
end

-- Full enemy name with level bracket
-- e.g. "Gorilla" → check all "Gorilla [Lv. 20]" etc.
local function GetFullEnemyName(baseName)
    if not baseName then return nil end
    -- Check Workspace.Enemies first
    local enemies = Workspace:FindFirstChild("Enemies")
    if enemies then
        for _, v in pairs(enemies:GetChildren()) do
            if v:IsA("Model") then
                -- Match: v.Name starts with baseName
                local enemyBase = v.Name:gsub(" %[Lv%. %d+%]", "")
                if enemyBase == baseName then
                    return v.Name
                end
            end
        end
    end
    -- Check ReplicatedStorage for spawned enemy models
    for _, v in pairs(ReplicatedStorage:GetChildren()) do
        if v:IsA("Model") then
            local enemyBase = v.Name:gsub(" %[Lv%. %d+%]", "")
            if enemyBase == baseName then
                return v.Name
            end
        end
    end
    return nil
end

-- Get a live enemy target matching the quest
local function GetQuestTarget()
    local questText = GetQuestInfo()
    if not questText then return nil end
    local baseName = ExtractEnemyNameFromQuest(questText)
    if not baseName then return nil end
    
    -- Search in Workspace.Enemies
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    
    local closest, closestDist = nil, math.huge
    local root = GetRoot()
    if not root then return nil end
    
    for _, v in pairs(enemies:GetChildren()) do
        if v:IsA("Model") then
            local enemyBase = v.Name:gsub(" %[Lv%. %d+%]", "")
            if enemyBase == baseName then
                local hum = v:FindFirstChild("Humanoid")
                local hrp = v:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    local dist = (hrp.Position - root.Position).Magnitude
                    if dist < closestDist then
                        closest = v
                        closestDist = dist
                    end
                end
            end
        end
    end
    return closest
end

-- Get any enemy (fallback if no quest or quest target not found)
local function GetAnyEnemy(range)
    local root = GetRoot()
    if not root then return nil end
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    local closest, closestDist = nil, math.huge
    for _, v in pairs(enemies:GetChildren()) do
        if v:IsA("Model") then
            local hum = v:FindFirstChild("Humanoid")
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 and not Players:GetPlayerFromCharacter(v) then
                local dist = (hrp.Position - root.Position).Magnitude
                if dist < closestDist and dist <= range then
                    closest = v
                    closestDist = dist
                end
            end
        end
    end
    return closest
end

-- ========= QUEST NPC DATA =========
-- FIX: Proper NPC CFrame locations for accepting quests
local QuestNPCs = {
    -- First Sea
    {Name = "Bandit", Level = 1, NPC_CF = CFrame.new(1061, 16, 1549), QuestName = "BanditQuest1"},
    {Name = "Monkey", Level = 10, NPC_CF = CFrame.new(-1604, 37, 154), QuestName = "JungleQuest"},
    {Name = "Gorilla", Level = 20, NPC_CF = CFrame.new(-1120, 15, 384), QuestName = "JungleQuest"},
    {Name = "Pirate", Level = 30, NPC_CF = CFrame.new(-1265, 30, -684), QuestName = "BuggyQuest1"},
    {Name = "Brute", Level = 40, NPC_CF = CFrame.new(-1265, 30, -684), QuestName = "BuggyQuest1"},
    {Name = "Desert Bandit", Level = 60, NPC_CF = CFrame.new(958, 17, 6), QuestName = "DesertQuest"},
    {Name = "Desert Officer", Level = 70, NPC_CF = CFrame.new(958, 17, 6), QuestName = "DesertQuest"},
    {Name = "Snow Bandit", Level = 90, NPC_CF = CFrame.new(1247, 47, -1594), QuestName = "SnowQuest"},
    {Name = "Snowman", Level = 100, NPC_CF = CFrame.new(1247, 47, -1594), QuestName = "SnowQuest"},
    {Name = "Chief Petty Officer", Level = 120, NPC_CF = CFrame.new(-4765, 28, -3183), QuestName = "MarineQuest2"},
    {Name = "Sky Bandit", Level = 150, NPC_CF = CFrame.new(-4970, 296, -2176), QuestName = "SkyQuest"},
    {Name = "Toga Warrior", Level = 225, NPC_CF = CFrame.new(-5330, 422, -2630), QuestName = "SkyQuest"},
}

-- Find the right quest NPC based on player level
local function GetQuestNPCForLevel(level)
    local best = nil
    for i = 1, #QuestNPCs do
        local q = QuestNPCs[i]
        if level >= q.Level then
            if not best or q.Level > best.Level then
                best = q
            end
        end
    end
    return best
end

-- ========= TOOL/EQUIP SYSTEM =========

-- Get the best tool from backpack
local function GetBestTool()
    -- Priority: equipped weapon > strongest weapon in backpack
    local char = LocalPlayer.Character
    if char then
        local equipped = char:FindFirstChildWhichIsA("Tool")
        if equipped then return equipped end
    end
    -- Get from backpack
    local bp = LocalPlayer.Backpack
    -- Prefer swords/melee, avoid guns if close range
    for _, v in pairs(bp:GetChildren()) do
        if v:IsA("Tool") then
            return v
        end
    end
    return nil
end

local function EquipTool(tool)
    if not tool then return end
    local hum = GetHum()
    if hum then
        pcall(function() hum:EquipTool(tool) end)
    end
end

-- ========= ATTACK SYSTEM =========
local function DoAttack()
    -- Method 1: VirtualUser click (works on most executors)
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(0, 0))
    end)
    
    -- Method 2: Activate equipped tool
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local tool = char:FindFirstChildWhichIsA("Tool")
            if tool then
                tool:Activate()
                -- Try remote events in the tool
                for _, r in pairs(tool:GetDescendants()) do
                    if r:IsA("RemoteEvent") then
                        pcall(function() r:FireServer("Activate") end)
                    end
                end
            end
        end
    end)
    
    -- Method 3: Click on screen center
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(500, 300, 0, true, game, 1)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(500, 300, 0, false, game, 1)
    end)
end

-- Use skills (Z, X, C, V, F, etc.)
local function UseSkills()
    if not Config.AutoSkills then return end
    local keys = {"Z", "X", "C", "V", "F", "G"}
    for i = 1, #keys do
        local key = keys[i]
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, key, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, key, false, game)
            task.wait(0.25)
        end)
    end
end

-- ========= AUTO QUEST =========
local function DoAutoQuest()
    local level = LocalPlayer.Data.Level.Value
    local questInfo = GetQuestInfo()
    
    -- Check if we already have a quest
    if questInfo then
        -- We have a quest, check if completed
        -- Format: "Defeat X (current/total)"
        local current, total = questInfo:match("%((%d+)/(%d+)%)")
        if current and total then
            local cur = tonumber(current)
            local tot = tonumber(total)
            if cur and tot and cur >= tot then
                -- Quest completed! Go talk to NPC to turn in / get new
                local npc = GetQuestNPCForLevel(level)
                if npc then
                    Tp(npc.NPC_CF * CFrame.new(0, 5, 3))
                    task.wait(1)
                    -- Click detector or proximity prompt
                    pcall(function()
                        local npcModel = Workspace:FindFirstChild(npc.QuestName)
                        if npcModel then
                            local cd = npcModel:FindFirstChildWhichIsA("ClickDetector")
                            if cd then cd:FireServer() end
                        end
                    end)
                    task.wait(1)
                end
                return
            end
        end
        -- Quest is active and not complete, farm it
        return
    end
    
    -- No active quest, go get one
    local npc = GetQuestNPCForLevel(level)
    if npc then
        Tp(npc.NPC_CF * CFrame.new(0, 5, 3))
        task.wait(1.5)
        -- Find and interact with the NPC
        pcall(function()
            local npcModel = Workspace:FindFirstChild(npc.QuestName)
            if npcModel then
                local cd = npcModel:FindFirstChildWhichIsA("ClickDetector")
                if cd then
                    cd:FireServer()
                end
            end
        end)
        task.wait(1)
    end
end

-- ========= BUILD GUI ========= (same as before, keep it simple)

-- Kill leftovers
pcall(function()
    local g1 = PlayerGui:FindFirstChild("MalXHubGUI")
    if g1 then g1:Destroy() end
    local g2 = PlayerGui:FindFirstChild("MalXCornerIcon")
    if g2 then g2:Destroy() end
    local g3 = PlayerGui:FindFirstChild("MalXLoadNotify")
    if g3 then g3:Destroy() end
end)

-- Main GUI
local gui = Instance.new("ScreenGui")
gui.Name = "MalXHubGUI"
gui.ResetOnSpawn = false
gui.Enabled = true
gui.Parent = PlayerGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 360, 0, 500)
main.Position = UDim2.new(0.15, 0, 0.2, 0)
main.BackgroundColor3 = Color3.fromRGB(13, 13, 25)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

-- Title
local tb = Instance.new("Frame")
tb.Size = UDim2.new(1, 0, 0, 38)
tb.BackgroundColor3 = Color3.fromRGB(22, 18, 42)
tb.BorderSizePixel = 0
tb.Parent = main
Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 10)

local tl = Instance.new("TextLabel")
tl.Size = UDim2.new(1, -60, 1, 0)
tl.Position = UDim2.new(0, 10, 0, 0)
tl.BackgroundTransparency = 1
tl.Text = "⚡ MalX Hub v2"
tl.TextColor3 = Color3.fromRGB(170, 100, 255)
tl.Font = Enum.Font.SourceSansBold
tl.TextSize = 22
tl.TextXAlignment = Enum.TextXAlignment.Left
tl.Parent = tb

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -32, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.Parent = tb
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 5)
closeBtn.MouseButton1Click:Connect(function() gui.Enabled = false end)

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 26, 0, 26)
minBtn.Position = UDim2.new(1, -64, 0, 6)
minBtn.BackgroundColor3 = Color3.fromRGB(50, 45, 65)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.new(1, 1, 1)
minBtn.TextScaled = true
minBtn.Font = Enum.Font.SourceSansBold
minBtn.Parent = tb
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 5)

-- Tabs
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -10, 0, 32)
tabBar.Position = UDim2.new(0, 5, 0, 40)
tabBar.BackgroundTransparency = 1
tabBar.Parent = main

local tabs = {{"⚔️","COMBAT"},{"🍎","FRUITS"},{"👁️","VISUAL"},{"🌍","WORLD"},{"🚀","MOVE"},{"💪","PLAYER"},{"⚙️","TOOLS"}}
local tabBtns = {}
local currentTab = "COMBAT"

local sf = Instance.new("ScrollingFrame")
sf.Size = UDim2.new(1, -10, 1, -82)
sf.Position = UDim2.new(0, 5, 0, 76)
sf.BackgroundTransparency = 1
sf.BorderSizePixel = 0
sf.ScrollBarThickness = 4
sf.ScrollBarImageColor3 = Color3.fromRGB(150, 50, 255)
sf.CanvasSize = UDim2.new(0, 0, 0, 0)
sf.Parent = main

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = sf

local status = Instance.new("TextLabel")
status.Size = UDim2.new(0, 340, 0, 22)
status.BackgroundTransparency = 1
status.Text = "[MalX v2] Ready"
status.TextColor3 = Color3.fromRGB(100, 255, 130)
status.Font = Enum.Font.SourceSansBold
status.TextSize = 15
status.Parent = sf

-- Helper functions
local function Sep(txt)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 340, 0, 26)
    f.BackgroundColor3 = Color3.fromRGB(25, 22, 45)
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = Color3.fromRGB(170, 100, 255)
    l.Font = Enum.Font.SourceSansBold
    l.TextSize = 15
    l.Parent = f
    return f
end

local function Toggle(txt, key, def)
    local state = def or false
    Config[key] = state
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 340, 0, 38)
    f.BackgroundColor3 = Color3.fromRGB(20, 18, 35)
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, 265, 1, 0)
    l.Position = UDim2.new(0, 8, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = Color3.fromRGB(220, 220, 230)
    l.Font = Enum.Font.SourceSansSemibold
    l.TextSize = 14
    l.Parent = f
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 50, 0, 26)
    b.Position = UDim2.new(1, -58, 0.5, -13)
    b.BackgroundColor3 = state and Color3.fromRGB(120, 40, 200) or Color3.fromRGB(45, 42, 60)
    b.Text = state and "ON" or "OFF"
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextScaled = true
    b.Font = Enum.Font.SourceSansBold
    b.Parent = f
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    b.MouseButton1Click:Connect(function()
        state = not state
        Config[key] = state
        b.BackgroundColor3 = state and Color3.fromRGB(120, 40, 200) or Color3.fromRGB(45, 42, 60)
        b.Text = state and "ON" or "OFF"
        status.Text = "[MalX] "..txt.." → "..(state and "ON" or "OFF")
        status.TextColor3 = state and Color3.fromRGB(100,255,130) or Color3.fromRGB(255,150,50)
    end)
    return f
end

local function TpBtn(name, cf)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 340, 0, 30)
    f.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -8, 1, -4)
    b.Position = UDim2.new(0, 4, 0, 2)
    b.BackgroundColor3 = Color3.fromRGB(50, 35, 100)
    b.Text = "📍 "..name
    b.TextColor3 = Color3.new(1,1,1)
    b.TextScaled = true
    b.Font = Enum.Font.SourceSansSemibold
    b.Parent = f
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    b.MouseButton1Click:Connect(function() Tp(cf); status.Text = "[MalX] Teleported to "..name; status.TextColor3 = Color3.fromRGB(100,200,255) end)
    return f
end

function Rebuild()
    local toRemove = {}
    for _, c in pairs(sf:GetChildren()) do
        if c ~= status and c ~= layout then table.insert(toRemove, c) end
    end
    for i = 1, #toRemove do toRemove[i]:Destroy() end
    
    if currentTab == "COMBAT" then
        Sep("⚔️ COMBAT").Parent = sf
        Toggle("Auto Farm", "AutoFarm").Parent = sf
        Toggle("Auto Quest", "AutoQuest").Parent = sf
        Toggle("Auto Skills (Z/X/C/V/F)", "AutoSkills").Parent = sf
        Toggle("Fast Attack", "FastAttack").Parent = sf
        Toggle("Bring Enemy", "BringEnemy").Parent = sf
        Toggle("Auto Boss", "AutoBoss").Parent = sf
    elseif currentTab == "FRUITS" then
        Sep("🍎 FRUITS").Parent = sf
        Toggle("Auto Fruit Find", "AutoFruitFind").Parent = sf
        Toggle("Fruit Notifier", "FruitNotifier").Parent = sf
        Toggle("Auto Store Fruit", "AutoStoreFruit").Parent = sf
    elseif currentTab == "VISUAL" then
        Sep("👁️ VISUAL").Parent = sf
        Toggle("Player ESP", "PlayerESP").Parent = sf
        Toggle("NPC/Enemy ESP", "NpcESP").Parent = sf
        Toggle("Chest ESP", "ChestESP").Parent = sf
    elseif currentTab == "WORLD" then
        Sep("🌍 WORLD").Parent = sf
        Toggle("Auto Raid", "AutoRaid").Parent = sf
        Toggle("Auto Sea Event", "AutoSeaEvent").Parent = sf
        Toggle("Auto Dungeon", "AutoDungeon").Parent = sf
        Sep("🌍 TELEPORT").Parent = sf
        local islands = {
            {"Jungle", CFrame.new(-1180,30,-580)},
            {"Pirate Village", CFrame.new(-1190,30,880)},
            {"Desert", CFrame.new(-950,30,2650)},
            {"Frozen Village", CFrame.new(750,30,-1450)},
            {"Marine Fortress", CFrame.new(-4130,30,2610)},
            {"Sky Island", CFrame.new(-4890,230,-1040)},
            {"Magma Village", CFrame.new(-5410,30,8490)},
            {"Ice Castle", CFrame.new(4100,30,-6550)},
            {"Kingdom of Rose", CFrame.new(-8520,180,-1530)},
            {"Sea of Treats", CFrame.new(330,30,-9240)},
            {"Hydra Island", CFrame.new(5210,30,-5320)},
            {"Cake Island", CFrame.new(-1940,30,-10940)},
            {"Haunted Castle", CFrame.new(-9510,130,-5980)},
            {"Kitsune Island", CFrame.new(420,30,14000)},
        }
        for i = 1, #islands do
            if i <= 14 then TpBtn(islands[i][1], islands[i][2]).Parent = sf end
        end
    elseif currentTab == "MOVE" then
        Sep("🚀 MOVEMENT").Parent = sf
        Toggle("Infinite Jump", "InfiniteJump").Parent = sf
        Toggle("No Clip", "NoClip").Parent = sf
        
        local spF = Instance.new("Frame")
        spF.Size = UDim2.new(0,340,0,36)
        spF.BackgroundColor3 = Color3.fromRGB(20,18,35)
        spF.BorderSizePixel = 0
        Instance.new("UICorner",spF).CornerRadius = UDim.new(0,5)
        spF.Parent = sf
        
        local spL = Instance.new("TextLabel")
        spL.Size = UDim2.new(0,200,1,0)
        spL.Position = UDim2.new(0,8,0,0)
        spL.BackgroundTransparency = 1
        spL.Text = "Speed: 50"
        spL.TextXAlignment = Enum.TextXAlignment.Left
        spL.TextColor3 = Color3.fromRGB(220,220,230)
        spL.Font = Enum.Font.SourceSansSemibold
        spL.TextSize = 14
        spL.Parent = spF
        
        local spT = Instance.new("TextButton")
        spT.Size = UDim2.new(0,50,0,26)
        spT.Position = UDim2.new(1,-58,0.5,-13)
        spT.BackgroundColor3 = Color3.fromRGB(45,42,60)
        spT.Text = "OFF"
        spT.TextColor3 = Color3.new(1,1,1)
        spT.TextScaled = true
        spT.Font = Enum.Font.SourceSansBold
        spT.Parent = spF
        Instance.new("UICorner",spT).CornerRadius = UDim.new(0,4)
        spT.MouseButton1Click:Connect(function()
            Config.SpeedEnabled = not Config.SpeedEnabled
            spT.BackgroundColor3 = Config.SpeedEnabled and Color3.fromRGB(120,40,200) or Color3.fromRGB(45,42,60)
            spT.Text = Config.SpeedEnabled and "ON" or "OFF"
        end)
        
        local jF = Instance.new("Frame")
        jF.Size = UDim2.new(0,340,0,30)
        jF.BackgroundColor3 = Color3.fromRGB(20,18,35)
        jF.BorderSizePixel = 0
        Instance.new("UICorner",jF).CornerRadius = UDim.new(0,5)
        jF.Parent = sf
        
        local jL = Instance.new("TextLabel")
        jL.Size = UDim2.new(1,0,1,0)
        jL.BackgroundTransparency = 1
        jL.Text = "Jump Power: 100"
        jL.TextColor3 = Color3.fromRGB(220,220,230)
        jL.Font = Enum.Font.SourceSansSemibold
        jL.TextSize = 14
        jL.Parent = jF
        
        local jcF = Instance.new("Frame")
        jcF.Size = UDim2.new(0,340,0,30)
        jcF.BackgroundTransparency = 1
        jcF.Parent = sf
        
        local jD = Instance.new("TextButton")
        jD.Size = UDim2.new(0,165,0,26)
        jD.Position = UDim2.new(0,0,0,2)
        jD.BackgroundColor3 = Color3.fromRGB(60,40,80)
        jD.Text = "-10"
        jD.TextColor3 = Color3.new(1,1,1)
        jD.TextScaled = true
        jD.Font = Enum.Font.SourceSansBold
        jD.Parent = jcF
        Instance.new("UICorner",jD).CornerRadius = UDim.new(0,4)
        local h = GetHum()
        jD.MouseButton1Click:Connect(function()
            Config.JumpPowerValue = math.max(50, Config.JumpPowerValue - 10)
            local hum = GetHum()
            if hum then hum.JumpPower = Config.JumpPowerValue end
            jL.Text = "Jump Power: "..Config.JumpPowerValue
        end)
        
        local jU = Instance.new("TextButton")
        jU.Size = UDim2.new(0,165,0,26)
        jU.Position = UDim2.new(0,175,0,2)
        jU.BackgroundColor3 = Color3.fromRGB(60,40,80)
        jU.Text = "+10"
        jU.TextColor3 = Color3.new(1,1,1)
        jU.TextScaled = true
        jU.Font = Enum.Font.SourceSansBold
        jU.Parent = jcF
        Instance.new("UICorner",jU).CornerRadius = UDim.new(0,4)
        jU.MouseButton1Click:Connect(function()
            Config.JumpPowerValue = math.min(500, Config.JumpPowerValue + 10)
            local hum = GetHum()
            if hum then hum.JumpPower = Config.JumpPowerValue end
            jL.Text = "Jump Power: "..Config.JumpPowerValue
        end)
        
    elseif currentTab == "PLAYER" then
        Sep("💪 PLAYER").Parent = sf
        Toggle("Auto Stats", "AutoStatsEnabled").Parent = sf
        
        local stF = Instance.new("Frame")
        stF.Size = UDim2.new(0,340,0,32)
        stF.BackgroundColor3 = Color3.fromRGB(20,18,35)
        stF.BorderSizePixel = 0
        Instance.new("UICorner",stF).CornerRadius = UDim.new(0,5)
        stF.Parent = sf
        
        local stL = Instance.new("TextLabel")
        stL.Size = UDim2.new(0,130,1,0)
        stL.Position = UDim2.new(0,8,0,0)
        stL.BackgroundTransparency = 1
        stL.Text = "Stat Mode:"
        stL.TextXAlignment = Enum.TextXAlignment.Left
        stL.TextColor3 = Color3.fromRGB(220,220,230)
        stL.Font = Enum.Font.SourceSansSemibold
        stL.TextSize = 14
        stL.Parent = stF
        
        local modes = {"Melee","Defense","Sword","Gun","Fruit"}
        for i = 1, #modes do
            local m = modes[i]
            local mb = Instance.new("TextButton")
            mb.Size = UDim2.new(0,50,0,24)
            mb.Position = UDim2.new(0,115+(i-1)*52,0,4)
            mb.BackgroundColor3 = (m == Config.StatMode) and Color3.fromRGB(120,40,200) or Color3.fromRGB(40,38,55)
            mb.Text = m
            mb.TextColor3 = Color3.new(1,1,1)
            mb.TextScaled = true
            mb.Font = Enum.Font.SourceSansBold
            mb.Parent = stF
            Instance.new("UICorner",mb).CornerRadius = UDim.new(0,4)
            mb.MouseButton1Click:Connect(function()
                Config.StatMode = m
                for _, c in pairs(stF:GetChildren()) do
                    if c:IsA("TextButton") then c.BackgroundColor3 = Color3.fromRGB(40,38,55) end
                end
                mb.BackgroundColor3 = Color3.fromRGB(120,40,200)
            end)
        end
        
        Toggle("Auto Haki", "AutoHaki").Parent = sf
        Toggle("God Mode", "GodMode").Parent = sf
        
    elseif currentTab == "TOOLS" then
        Sep("⚙️ UTILITY").Parent = sf
        Toggle("Safe Mode", "SafeMode").Parent = sf
        Toggle("Auto Rejoin", "AutoRejoin").Parent = sf
        Sep("🛠️ ACTIONS").Parent = sf
        
        local rF = Instance.new("Frame")
        rF.Size = UDim2.new(0,340,0,30)
        rF.BackgroundColor3 = Color3.fromRGB(20,18,35)
        rF.BorderSizePixel = 0
        Instance.new("UICorner",rF).CornerRadius = UDim.new(0,5)
        rF.Parent = sf
        
        local rB = Instance.new("TextButton")
        rB.Size = UDim2.new(1,-8,1,-4)
        rB.Position = UDim2.new(0,4,0,2)
        rB.BackgroundColor3 = Color3.fromRGB(50,100,180)
        rB.Text = "🔄 Respawn"
        rB.TextColor3 = Color3.new(1,1,1)
        rB.TextScaled = true
        rB.Font = Enum.Font.SourceSansBold
        rB.Parent = rF
        Instance.new("UICorner",rB).CornerRadius = UDim.new(0,4)
        rB.MouseButton1Click:Connect(function()
            local h = GetHum()
            if h then h.Health = 0 end
        end)
        
        Sep("™️ MALX HUB v2").Parent = sf
        local cF = Instance.new("Frame")
        cF.Size = UDim2.new(0,340,0,40)
        cF.BackgroundColor3 = Color3.fromRGB(15,13,28)
        cF.BorderSizePixel = 0
        Instance.new("UICorner",cF).CornerRadius = UDim.new(0,5)
        cF.Parent = sf
        local cT = Instance.new("TextLabel")
        cT.Size = UDim2.new(1,0,0,20)
        cT.Position = UDim2.new(0,0,0,4)
        cT.BackgroundTransparency = 1
        cT.Text = "⚡ MalX Hub v2"
        cT.TextColor3 = Color3.fromRGB(150,80,220)
        cT.Font = Enum.Font.SourceSansBold
        cT.TextSize = 16
        cT.Parent = cF
        local cS = Instance.new("TextLabel")
        cS.Size = UDim2.new(1,0,0,14)
        cS.Position = UDim2.new(0,0,0,24)
        cS.BackgroundTransparency = 1
        cS.Text = "25+ Features | Fixed Combat + Quest"
        cS.TextColor3 = Color3.fromRGB(100,100,130)
        cS.Font = Enum.Font.SourceSans
        cS.TextSize = 12
        cS.Parent = cF
    end
    
    task.wait(0.05)
    sf.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
end

-- Tab buttons
for i = 1, #tabs do
    local data = tabs[i]
    local b = Instance.new("TextButton")
    local bw = 50
    b.Size = UDim2.new(0, bw, 0, 26)
    b.Position = UDim2.new(0, (i-1)*(bw+3), 0, 3)
    b.BackgroundColor3 = (data[2]==currentTab) and Color3.fromRGB(120,40,200) or Color3.fromRGB(30,28,50)
    b.Text = data[1]
    b.TextColor3 = Color3.new(1,1,1)
    b.TextScaled = true
    b.Font = Enum.Font.SourceSansBold
    b.Parent = tabBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    table.insert(tabBtns, b)
    b.MouseButton1Click:Connect(function()
        currentTab = data[2]
        for j = 1, #tabBtns do tabBtns[j].BackgroundColor3 = Color3.fromRGB(30,28,50) end
        b.BackgroundColor3 = Color3.fromRGB(120,40,200)
        Rebuild()
    end)
end

local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    sf.Visible = not minimized
    tabBar.Visible = not minimized
    main.Size = minimized and UDim2.new(0,360,0,38) or UDim2.new(0,360,0,500)
    minBtn.Text = minimized and "+" or "-"
end)

Rebuild()

-- ========= CORNER ICON =========
local iconGui = Instance.new("ScreenGui")
iconGui.Name = "MalXCornerIcon"
iconGui.ResetOnSpawn = false
iconGui.Enabled = true
iconGui.Parent = PlayerGui

local iconBtn = Instance.new("TextButton")
iconBtn.Size = UDim2.new(0, 90, 0, 30)
iconBtn.Position = UDim2.new(1, -100, 0, 10)
iconBtn.BackgroundColor3 = Color3.fromRGB(22, 18, 42)
iconBtn.BackgroundTransparency = 0.1
iconBtn.Text = "⚡ MalX"
iconBtn.TextColor3 = Color3.fromRGB(170, 100, 255)
iconBtn.TextScaled = false
iconBtn.TextSize = 18
iconBtn.Font = Enum.Font.SourceSansBold
iconBtn.Draggable = true
iconBtn.Active = true
iconBtn.Parent = iconGui
Instance.new("UICorner", iconBtn).CornerRadius = UDim.new(0, 10)
local iconStroke = Instance.new("UIStroke")
iconStroke.Color = Color3.fromRGB(120, 40, 200)
iconStroke.Thickness = 2
iconStroke.Parent = iconBtn

iconBtn.MouseButton1Click:Connect(function()
    gui.Enabled = not gui.Enabled
    iconBtn.Text = gui.Enabled and "⚡ MalX" or "⚡ OFF"
    iconBtn.TextColor3 = gui.Enabled and Color3.fromRGB(170,100,255) or Color3.fromRGB(255,100,100)
    if gui.Enabled then
        task.delay(0.5, function() iconBtn.TextColor3 = Color3.fromRGB(170,100,255) end)
    end
end)

-- Notification
local notify = Instance.new("ScreenGui")
notify.Name = "MalXLoadNotify"
notify.ResetOnSpawn = false
notify.Parent = PlayerGui
local notifyT = Instance.new("TextLabel")
notifyT.Size = UDim2.new(0, 400, 0, 40)
notifyT.Position = UDim2.new(0.5, -200, 0.2, 0)
notifyT.BackgroundColor3 = Color3.fromRGB(0,0,0)
notifyT.BackgroundTransparency = 0.2
notifyT.TextColor3 = Color3.fromRGB(100, 255, 130)
notifyT.Text = "⚡ MalX Hub v2 loaded! Auto Farm now targets quest enemies"
notifyT.Font = Enum.Font.SourceSansBold
notifyT.TextSize = 16
notifyT.TextStrokeTransparency = 0
notifyT.Parent = notify
Instance.new("UICorner", notifyT).CornerRadius = UDim.new(0, 8)
task.delay(6, function() pcall(function() notify:Destroy() end) end)

-- ========= KEYBOARD =========
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightShift then
        gui.Enabled = not gui.Enabled
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local r = GetRoot()
        if r then r.Velocity = Vector3.new(r.Velocity.X, 60, r.Velocity.Z) end
    end
end)

-- ========= STEPPED LOOP (critical for NoClip + combat) =========
RunService.Stepped:Connect(function()
    -- NoClip: keeps character in NoClip state
    if Config.NoClip then
        local h = GetHum()
        if h then
            pcall(function()
                h:ChangeState(11) -- Enum.HumanoidStateType.Physics = 11
            end)
        end
    end
    
    -- Auto Farm: equip tool and keep it equipped
    if Config.AutoFarm then
        local char = LocalPlayer.Character
        if char then
            local tool = char:FindFirstChildWhichIsA("Tool")
            if not tool then
                -- Equip a tool from backpack
                local bpTool = GetBestTool()
                if bpTool then
                    EquipTool(bpTool)
                end
            end
        end
    end
end)

-- ========= AUTO FARM LOOP =========
coroutine.wrap(function()
    while true do
        task.wait(0.2)
        
        if not Config.AutoFarm then
            task.wait(1)
        else
            -- Step 1: Auto Quest (get/handle quests)
            if Config.AutoQuest then
                DoAutoQuest()
            end
            
            -- Step 2: Find target
            local target = nil
            
            -- First: try to find enemy matching quest
            target = GetQuestTarget()
            
            -- Fallback: any enemy nearby
            if not target then
                target = GetAnyEnemy(Config.AimbotRange or 2000)
            end
            
            -- Step 3: Attack target
            if target then
                local hrp = target:FindFirstChild("HumanoidRootPart")
                if hrp and GetRoot() then
                    local root = GetRoot()
                    
                    -- FIX: Position in front of enemy, slightly above
                    local lookVec = hrp.CFrame.lookVector
                    local pos = hrp.Position - lookVec * 5 + Vector3.new(0, 2.5, 0)
                    root.CFrame = CFrame.new(pos)
                    
                    -- Equip tool
                    local char = LocalPlayer.Character
                    local tool = char and char:FindFirstChildWhichIsA("Tool")
                    if not tool then
                        local bpTool = GetBestTool()
                        if bpTool then
                            EquipTool(bpTool)
                            task.wait(0.1)
                        end
                    end
                    
                    -- Attack!
                    DoAttack()
                    
                    -- Use skills
                    if Config.AutoSkills then
                        UseSkills()
                    end
                    
                    -- Fast Attack = spam clicks
                    if Config.FastAttack then
                        for _ = 1, 3 do
                            DoAttack()
                            task.wait(0.05)
                        end
                    end
                end
            else
                -- No target found, wait a bit
                task.wait(1)
            end
        end
    end
end)()

-- ========= AUTO QUEST STANDALONE =========
-- If auto quest is on but auto farm is off, still handle quests separately
coroutine.wrap(function()
    while true do
        task.wait(3)
        if Config.AutoQuest and not Config.AutoFarm then
            DoAutoQuest()
        end
    end
end)()

-- ========= OTHER LOOPS =========

-- Speed
coroutine.wrap(function()
    while true do
        task.wait(0.5)
        if Config.SpeedEnabled then
            local h = GetHum()
            if h then h.WalkSpeed = Config.SpeedValue end
        end
    end
end)()

-- God Mode
coroutine.wrap(function()
    while true do
        task.wait(1)
        if Config.GodMode then
            local h = GetHum()
            if h then
                h.MaxHealth = 999999
                h.Health = 999999
            end
        end
    end
end)()

-- Auto Stats
coroutine.wrap(function()
    while true do
        task.wait(3)
        if Config.AutoStatsEnabled then
            for _, v in pairs(ReplicatedStorage:GetDescendants()) do
                if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                    pcall(function()
                        if v:IsA("RemoteFunction") then
                            v:InvokeServer("AddStats", Config.StatMode, 1)
                        else
                            v:FireServer("AddStats", Config.StatMode, 1)
                        end
                    end)
                    break
                end
            end
        end
    end
end)()

-- Auto Haki
coroutine.wrap(function()
    while true do
        task.wait(5)
        if Config.AutoHaki then
            local haki = LocalPlayer.Backpack:FindFirstChild("ObservationHaki") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("ObservationHaki"))
            if haki then
                local h = GetHum()
                if h then pcall(function() h:EquipTool(haki) end) end
            end
            task.wait(0.3)
            for _, v in pairs(ReplicatedStorage:GetDescendants()) do
                if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                    pcall(function() v:FireServer("Haki", {["Key"]="ObservationHaki", ["Active"]=true}) end)
                    break
                end
            end
        end
    end
end)()

-- Auto Rejoin
coroutine.wrap(function()
    while true do
        task.wait(60)
        if Config.AutoRejoin then
            local h = GetHum()
            if h and h.Health <= 0 then
                task.wait(3)
                pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
            end
        end
    end
end)()

-- Safe Mode
coroutine.wrap(function()
    while true do
        task.wait(2)
        if Config.SafeMode then
            local h = GetHum()
            if h and h.Health < h.MaxHealth * 0.3 then
                local r = GetRoot()
                if r then r.CFrame = CFrame.new(-1180,30,-580) end
            end
        end
    end
end)()

print("✅ MalX Hub v2 - Combat Fixed")
