--[[
  MalX Hub v2 — ULTIMATE FIX
  - Auto-opens with 4 fallback parenting methods
  - Clickable corner icon (⚡ MalX) to toggle main GUI
  - NO 'continue' keyword (executor-safe)
  - All loops are simple while-true with config checks
]]

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ========= SAFE CHARACTER REFS =========
local function GetRoot()
    local c = LocalPlayer.Character
    if c then return c:FindFirstChild("HumanoidRootPart") end
    return nil
end
local function GetHum()
    local c = LocalPlayer.Character
    if c then return c:FindFirstChild("Humanoid") end
    return nil
end

-- ========= ANTI-IDLE =========
LocalPlayer.Idled:Connect(function()
    VirtualInputManager:SendKeyEvent(true, "V", false, game)
    task.wait(0.5)
    VirtualInputManager:SendKeyEvent(false, "V", false, game)
end)

-- ========= CONFIG =========
local Config = {
    AimbotRange = 2000,
    SpeedValue = 50,
    JumpPowerValue = 100,
    StatMode = "Melee",
    -- toggles
    AutoFarm = false, Aimbot = false, AutoSkills = false, FastAttack = false,
    BringEnemy = false, AutoQuest = false, AutoBoss = false,
    AutoFruitFind = false, FruitNotifier = false, AutoStoreFruit = false,
    PlayerESP = false, NpcESP = false, ChestESP = false,
    AutoRaid = false, AutoSeaEvent = false, AutoDungeon = false,
    InfiniteJump = false, NoClip = false, SpeedEnabled = false,
    AutoStatsEnabled = false, AutoHaki = false, GodMode = false,
    SafeMode = false, AutoRejoin = false,
}

-- ========= FRUIT LIST =========
local FruitNames = {"Bomb","Flame","Ice","Light","Dark","Magma","Sand","Bird","String","Rumble","Door","Ghost","Spider","Diamond","Love","Rubber","Barrier","Dragon","Venom","Shadow","Dough","Soul","Leopard","Mammoth","T-Rex","Spirit","Control","Kitsune","Yeti","Gas","Blizzard","Gravity","Pain","Phoenix","Smoke","Spring","Chop","Spin","Revive"}

local function IsFruit(obj)
    if not obj then return false end
    local n = obj.Name:lower()
    for i = 1, #FruitNames do
        if n:find(FruitNames[i]:lower()) then
            return true
        end
    end
    if obj:FindFirstChild("Fruit") or obj:FindFirstChild("ClickDetector") then
        return true
    end
    return false
end

-- ========= TELEPORT =========
local function Tp(cf)
    local r = GetRoot()
    if r then r.CFrame = cf end
end

-- ========= BUILD GUI =========

-- Kill any leftover GUIs first
pcall(function()
    local g1 = PlayerGui:FindFirstChild("MalXHubGUI")
    if g1 then g1:Destroy() end
    local g2 = PlayerGui:FindFirstChild("MalXCornerIcon")
    if g2 then g2:Destroy() end
    local g3 = CoreGui:FindFirstChild("MalXHubGUI")
    if g3 then g3:Destroy() end
    local g4 = CoreGui:FindFirstChild("MalXCornerIcon")
    if g4 then g4:Destroy() end
end)

-- CLIENT SCREEN
local cl = Instance.new("ScreenGui")
cl.Name = "MalXLoadNotify"
cl.ResetOnSpawn = false
cl.Parent = PlayerGui

local clT = Instance.new("TextLabel")
clT.Size = UDim2.new(0, 400, 0, 40)
clT.Position = UDim2.new(0.5, -200, 0.2, 0)
clT.BackgroundColor3 = Color3.fromRGB(0,0,0)
clT.BackgroundTransparency = 0.2
clT.TextColor3 = Color3.fromRGB(170,100,255)
clT.Text = "⚡ Loading MalX Hub v2..."
clT.Font = Enum.Font.SourceSansBold
clT.TextSize = 18
clT.TextStrokeTransparency = 0
clT.Parent = cl
Instance.new("UICorner", clT).CornerRadius = UDim.new(0,8)

-- ===== TRY 4 PARENTING LOCATIONS =====
local gui = nil
local parentingAttempts = {
    PlayerGui,
    CoreGui,
    CoreGui:FindFirstChild("RobloxGui"),
    CoreGui:FindFirstChild("RobloxGui") or CoreGui
}

for i = 1, #parentingAttempts do
    local parent = parentingAttempts[i]
    if parent then
        local success = pcall(function()
            local test = Instance.new("ScreenGui")
            test.Name = "MalXHubGUI"
            test.ResetOnSpawn = false
            test.Enabled = true
            local f = Instance.new("Frame")
            f.Size = UDim2.new(0, 10, 0, 10)
            f.Parent = test
            test.Parent = parent
            task.wait(0.05)
            if test.Parent ~= nil then
                gui = test
                f:Destroy()
                error("FOUND") -- break out of pcall via error
            else
                test:Destroy()
            end
        end)
        if success == false and gui ~= nil then
            -- Found working parent
            break
        end
    end
end

-- If all failed, force into PlayerGui
if gui == nil then
    gui = Instance.new("ScreenGui")
    gui.Name = "MalXHubGUI"
    gui.ResetOnSpawn = false
    gui.Enabled = true
    gui.Parent = PlayerGui
end

-- ===== CORNER ICON GUI =====
local iconGui = nil
for i = 1, #parentingAttempts do
    local parent = parentingAttempts[i]
    if parent then
        local ok = pcall(function()
            local t = Instance.new("ScreenGui")
            t.Name = "MalXCornerIcon"
            t.ResetOnSpawn = false
            t.Enabled = true
            local f = Instance.new("Frame")
            f.Size = UDim2.new(0, 10, 0, 10)
            f.Parent = t
            t.Parent = parent
            task.wait(0.05)
            if t.Parent ~= nil then
                iconGui = t
                f:Destroy()
                error("FOUND")
            else
                t:Destroy()
            end
        end)
        if ok == false and iconGui ~= nil then break end
    end
end
if iconGui == nil then
    iconGui = Instance.new("ScreenGui")
    iconGui.Name = "MalXCornerIcon"
    iconGui.ResetOnSpawn = false
    iconGui.Enabled = true
    iconGui.Parent = PlayerGui
end

-- ===== BUILD MAIN GUI =====
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

-- Scroll frame
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

-- Helper: separator
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

-- Helper: toggle
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

-- Helper: teleport button
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

-- Rebuild content
local function Rebuild()
    -- Clear children except status and layout
    local toRemove = {}
    for _, c in pairs(sf:GetChildren()) do
        if c ~= status and c ~= layout then
            table.insert(toRemove, c)
        end
    end
    for i = 1, #toRemove do
        toRemove[i]:Destroy()
    end
    
    if currentTab == "COMBAT" then
        Sep("⚔️ COMBAT").Parent = sf
        Toggle("Auto Farm", "AutoFarm").Parent = sf
        Toggle("Aimbot", "Aimbot").Parent = sf
        Toggle("Auto Skills (1-6)", "AutoSkills").Parent = sf
        Toggle("Fast Attack", "FastAttack").Parent = sf
        Toggle("Bring Enemy", "BringEnemy").Parent = sf
        Toggle("Auto Quest", "AutoQuest").Parent = sf
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
            if i <= 14 then
                TpBtn(islands[i][1], islands[i][2]).Parent = sf
            end
        end
    elseif currentTab == "MOVE" then
        Sep("🚀 MOVEMENT").Parent = sf
        Toggle("Infinite Jump", "InfiniteJump").Parent = sf
        Toggle("No Clip", "NoClip").Parent = sf
        
        -- Speed
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
        
        -- Jump power display
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
        
        -- Jump controls
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
        
        jD.MouseButton1Click:Connect(function()
            Config.JumpPowerValue = math.max(50, Config.JumpPowerValue - 10)
            local h = GetHum()
            if h then h.JumpPower = Config.JumpPowerValue end
            jL.Text = "Jump Power: "..Config.JumpPowerValue
        end)
        jU.MouseButton1Click:Connect(function()
            Config.JumpPowerValue = math.min(500, Config.JumpPowerValue + 10)
            local h = GetHum()
            if h then h.JumpPower = Config.JumpPowerValue end
            jL.Text = "Jump Power: "..Config.JumpPowerValue
        end)
        
    elseif currentTab == "PLAYER" then
        Sep("💪 PLAYER").Parent = sf
        Toggle("Auto Stats", "AutoStatsEnabled").Parent = sf
        
        -- Stat mode selector
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
                    if c:IsA("TextButton") then
                        c.BackgroundColor3 = Color3.fromRGB(40,38,55)
                    end
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
        
        -- Respawn
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
        
        -- Credits
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
        cS.Text = "25+ Features | Auto-open | Corner Icon"
        cS.TextColor3 = Color3.fromRGB(100,100,130)
        cS.Font = Enum.Font.SourceSans
        cS.TextSize = 12
        cS.Parent = cF
    end
    
    task.wait(0.05)
    local contentSize = layout.AbsoluteContentSize.Y
    sf.CanvasSize = UDim2.new(0, 0, 0, contentSize + 20)
end

-- Create tab buttons
for i = 1, #tabs do
    local data = tabs[i]
    local b = Instance.new("TextButton")
    local bw = 50
    b.Size = UDim2.new(0, bw, 0, 26)
    b.Position = UDim2.new(0, (i-1)*(bw+3), 0, 3)
    if data[2] == currentTab then
        b.BackgroundColor3 = Color3.fromRGB(120,40,200)
    else
        b.BackgroundColor3 = Color3.fromRGB(30,28,50)
    end
    b.Text = data[1]
    b.TextColor3 = Color3.new(1,1,1)
    b.TextScaled = true
    b.Font = Enum.Font.SourceSansBold
    b.Parent = tabBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    table.insert(tabBtns, b)
    b.MouseButton1Click:Connect(function()
        currentTab = data[2]
        for j = 1, #tabBtns do
            tabBtns[j].BackgroundColor3 = Color3.fromRGB(30,28,50)
        end
        b.BackgroundColor3 = Color3.fromRGB(120,40,200)
        Rebuild()
    end)
end

-- Minimize
local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    sf.Visible = not minimized
    tabBar.Visible = not minimized
    if minimized then
        main.Size = UDim2.new(0,360,0,38)
        minBtn.Text = "+"
    else
        main.Size = UDim2.new(0,360,0,500)
        minBtn.Text = "-"
    end
end)

-- Build initial
Rebuild()

-- ===== CORNER ICON =====
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

-- Click icon to toggle main GUI
iconBtn.MouseButton1Click:Connect(function()
    gui.Enabled = not gui.Enabled
    if gui.Enabled then
        iconBtn.TextColor3 = Color3.fromRGB(100, 255, 130)
        iconBtn.Text = "⚡ ON"
    else
        iconBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        iconBtn.Text = "⚡ OFF"
    end
    task.delay(0.5, function()
        iconBtn.Text = "⚡ MalX"
        iconBtn.TextColor3 = Color3.fromRGB(170, 100, 255)
    end)
end)

-- ===== NOTIFICATION =====
task.wait(0.3)
clT.Text = "⚡ MalX Hub v2 loaded! Click [⚡ MalX] at top-right"
clT.TextColor3 = Color3.fromRGB(100, 255, 130)

task.delay(5, function()
    pcall(function() cl:Destroy() end)
end)

-- ===== KEYBOARD TOGGLES =====
-- Insert key
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        gui.Enabled = not gui.Enabled
    end
end)

-- Right Shift
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        gui.Enabled = not gui.Enabled
    end
end)

-- ===== INFINITE JUMP =====
UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local r = GetRoot()
        if r then
            r.Velocity = Vector3.new(r.Velocity.X, 60, r.Velocity.Z)
        end
    end
end)

-- ===== BACKGROUND LOOPS (no 'continue' used anywhere) =====

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

-- No Clip
coroutine.wrap(function()
    while true do
        task.wait(0.1)
        if Config.NoClip then
            local c = LocalPlayer.Character
            if c then
                for _, p in pairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.CanCollide = false
                    end
                end
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
                    local ok = pcall(function()
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
            local haki = LocalPlayer.Backpack:FindFirstChild("ObservationHaki")
            if not haki then
                local c = LocalPlayer.Character
                if c then haki = c:FindFirstChild("ObservationHaki") end
            end
            if haki then
                local h = GetHum()
                if h then pcall(function() h:EquipTool(haki) end) end
            end
            task.wait(0.3)
            for _, v in pairs(ReplicatedStorage:GetDescendants()) do
                if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                    pcall(function()
                        v:FireServer("Haki", {["Key"]="ObservationHaki", ["Active"]=true})
                    end)
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
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end)
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

-- Auto Farm
coroutine.wrap(function()
    while true do
        task.wait(0.15)
        if Config.AutoFarm then
            local root = GetRoot()
            if root then
                local target = nil
                local tdist = math.huge
                for _, v in pairs(Workspace:GetDescendants()) do
                    if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
                        local hum = v:FindFirstChild("Humanoid")
                        if hum and hum.Health > 0 and hum.MaxHealth > 0 then
                            local isPlayer = Players:GetPlayerFromCharacter(v)
                            if not isPlayer then
                                local tr = v:FindFirstChild("HumanoidRootPart")
                                local mag = (tr.Position - root.Position).Magnitude
                                if mag < tdist and mag <= Config.AimbotRange then
                                    target = v
                                    tdist = mag
                                end
                            end
                        end
                    end
                end
                if target then
                    local tr = target:FindFirstChild("HumanoidRootPart")
                    root.CFrame = CFrame.new(tr.Position + Vector3.new(0,5,0))
                    local char = LocalPlayer.Character
                    local tool = nil
                    if char then tool = char:FindFirstChildWhichIsA("Tool") end
                    if tool then tool:Activate() end
                    if Config.AutoSkills then
                        for i = 1, 6 do
                            VirtualInputManager:SendKeyEvent(true, tostring(i), false, game)
                            task.wait(0.08)
                            VirtualInputManager:SendKeyEvent(false, tostring(i), false, game)
                            task.wait(0.3)
                        end
                    end
                end
            end
        end
    end
end)()

print("✅ MalX Hub v2 loaded successfully")
