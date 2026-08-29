-- ╔═════════════════════════════════════════════════════╗
-- ║          SHARD - EGG FARMING SCRIPT               ║
-- ║        Developed by: kabusxrd                     ║
-- ║     GitHub: https://github.com/kabusxd/egglua    ║
-- ╚═════════════════════════════════════════════════════╝

-- =====================================================
-- WINDUI LIBRARY LOADING WITH FALLBACK
-- =====================================================
local WindUI

-- Try loading WindUI
local function loadWindUI()
    local success, lib = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end)
    
    if success and lib then
        return lib
    end
    
    -- Fallback - Simple UI without WindUI
    return nil
end

WindUI = loadWindUI()

-- If WindUI failed, use simple print-based UI
if not WindUI then
    print("⚠️ WindUI not available, using fallback mode...")
    
    WindUI = {
        CreateWindow = function(self, config)
            print("📊 UI: " .. (config.Title or "Window"))
            return {
                Section = function(self, config) 
                    print("  📁 " .. (config.Title or "Section"))
                    return self 
                end,
                Tab = function(self, config) 
                    print("    📄 " .. (config.Title or "Tab"))
                    return self 
                end,
                Toggle = function(self, config)
                    print("    ☑️ " .. (config.Title or "Toggle"))
                    return self
                end,
                Slider = function(self, config)
                    print("    🎚️ " .. (config.Title or "Slider"))
                    return self
                end,
                Dropdown = function(self, config)
                    print("    📋 " .. (config.Title or "Dropdown"))
                    return self
                end,
                Button = function(self, config)
                    print("    🔘 " .. (config.Title or "Button"))
                    return self
                end,
                Notify = function(self, config) 
                    print("📢 " .. (config.Title or "") .. ": " .. (config.Content or ""))
                    return self
                end,
                Destroy = function(self) 
                    print("❌ UI Closed")
                end
            }
        end,
        Notify = function(self, config)
            print("📢 " .. (config.Title or "") .. ": " .. (config.Content or ""))
        end
    }
end

-- =====================================================
-- GAME SERVICES
-- =====================================================
local players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local RS              = game:GetService("ReplicatedStorage")
local player          = players.LocalPlayer

-- =====================================================
-- STATE CONFIGURATION
-- =====================================================
local State = {
    AutoSteal            = false,
    EggNameFilter        = "",
    SpeedBoost           = 50,
    GlideSpeed           = 20,
    RarityFilter         = "Any",
    RareHunter           = false,
    RareTier             = "Rare",
    StealOnce            = false,
    AutoHop              = false,
    MaxHops              = 10,
    HopDelay             = 30,
    HopCount             = 0,
    AutoHatch            = false,
    HatchOnce            = false,
    EggESP               = false,
    AutoEquipBest        = false,
    AutoSell             = false,
    SellRarities         = {},
    AutoSellEggs         = false,
    EggSellRarities      = {},
    AutoClaim            = false,
    ClaimInterval        = 5,
    AutoUpgrade          = false,
    UpgradeInterval      = 5,
    AutoTreadmill        = false,
    AutoUpgradeTreadmill = false,
}

local Rarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}
local Threads    = {}
local ESPObjects = {}

-- =====================================================
-- CORE HELPER FUNCTIONS
-- =====================================================

local function getHumanoid()
    local char = player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRootPart()
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function teleportTo(pos)
    local root = getRootPart()
    if root then root.CFrame = CFrame.new(pos) end
end

local function findRemote(...)
    local patterns = {...}
    for _, desc in ipairs(RS:GetDescendants()) do
        if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
            local n = desc.Name:lower()
            for _, pat in ipairs(patterns) do
                if n:find(pat:lower(), 1, true) then return desc end
            end
        end
    end
end

local function findEggs()
    local eggs   = {}
    local filter = State.EggNameFilter:lower()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find("egg", 1, true) then
            if filter == "" or obj.Name:lower():find(filter, 1, true) then
                eggs[#eggs + 1] = obj
            end
        end
    end
    return eggs
end

local function rarityMatches(name, rarity)
    if rarity == "Any" then return true end
    return name:lower():find(rarity:lower(), 1, true) ~= nil
end

local function tryInteractEgg(egg)
    for _, pp in ipairs(egg:GetDescendants()) do
        if pp:IsA("ProximityPrompt") then
            pcall(function() if fireproximityprompt then fireproximityprompt(pp) end end)
        end
    end
    for _, cd in ipairs(egg:GetDescendants()) do
        if cd:IsA("ClickDetector") then
            pcall(function() if fireclickdetector then fireclickdetector(cd) end end)
        end
    end
    for _, re in ipairs(egg:GetDescendants()) do
        if re:IsA("RemoteEvent") then
            pcall(function() re:FireServer(egg) end)
        end
    end
    local remote = findRemote("steal","grab","collect","pick","take","snatch","egg")
    if remote then
        pcall(function() remote:FireServer(egg) end)
        pcall(function() remote:FireServer(egg.Name) end)
        pcall(function() remote:FireServer() end)
    end
end

local function killThread(name)
    if Threads[name] then
        pcall(task.cancel, Threads[name])
        Threads[name] = nil
    end
end

-- =====================================================
-- FEATURE LOOPS
-- =====================================================

local function startStealLoop()
    killThread("steal")
    Threads["steal"] = task.spawn(function()
        while State.AutoSteal do
            for _, egg in ipairs(findEggs()) do
                if not State.AutoSteal then break end
                if rarityMatches(egg.Name, State.RarityFilter) then
                    local part = egg.PrimaryPart or egg:FindFirstChildOfClass("BasePart")
                    if part then
                        teleportTo(part.Position + Vector3.new(0, 3, 0))
                        local hum = getHumanoid()
                        if hum then hum.WalkSpeed = State.SpeedBoost end
                        task.wait(0.3)
                        tryInteractEgg(egg)
                        if State.StealOnce then
                            State.AutoSteal = false
                            break
                        end
                    end
                end
                task.wait(0.1)
            end
            if State.AutoSteal then
                task.wait(0.8)
            end
        end
    end)
end

local function startHatchLoop()
    killThread("hatch")
    Threads["hatch"] = task.spawn(function()
        local hatched = false
        while State.AutoHatch do
            if not (State.HatchOnce and hatched) then
                local remote = findRemote("hatch","open","crack","incubat")
                if remote then
                    pcall(function() remote:FireServer() end)
                    hatched = true
                end
            end
            task.wait(1.5)
        end
    end)
end

local function startClaimLoop()
    killThread("claim")
    Threads["claim"] = task.spawn(function()
        while State.AutoClaim do
            local remote = findRemote("claim","reward","daily","bonus","chest")
            if remote then pcall(function() remote:FireServer() end) end
            task.wait(State.ClaimInterval)
        end
    end)
end

local function startUpgradeLoop()
    killThread("upgrade")
    Threads["upgrade"] = task.spawn(function()
        while State.AutoUpgrade do
            local remote = findRemote("upgrade","levelup","stat","improve","boost")
            if remote then
                pcall(function() remote:FireServer() end)
                pcall(function() remote:FireServer(1) end)
            end
            task.wait(State.UpgradeInterval)
        end
    end)
end

local function startEquipLoop()
    killThread("equip")
    Threads["equip"] = task.spawn(function()
        while State.AutoEquipBest do
            local remote = findRemote("equipbest","equip","bestpet")
            if remote then
                pcall(function() remote:FireServer() end)
                pcall(function() remote:FireServer("best") end)
            end
            task.wait(3)
        end
    end)
end

local function startSellLoop()
    killThread("sell")
    Threads["sell"] = task.spawn(function()
        while State.AutoSell do
            local remote = findRemote("sellpet","sell","sellall")
            if remote then
                pcall(function() remote:FireServer(State.SellRarities) end)
                pcall(function() remote:FireServer() end)
            end
            task.wait(2.5)
        end
    end)
end

local function startSellEggLoop()
    killThread("sellegg")
    Threads["sellegg"] = task.spawn(function()
        while State.AutoSellEggs do
            local remote = findRemote("sellegg","sell","sellall")
            if remote then
                pcall(function() remote:FireServer(State.EggSellRarities) end)
                pcall(function() remote:FireServer() end)
            end
            task.wait(2.5)
        end
    end)
end

-- =====================================================
-- COMMAND INTERFACE (Print-based)
-- =====================================================
print("\n╔════════════════════════════════════════════╗")
print("║     🥚 SHARD - Egg Farming Script        ║")
print("║     Developed by: kabusxrd               ║")
print("║     GitHub: github.com/kabusxd/egglua    ║")
print("╚════════════════════════════════════════════╝\n")

print("📋 KOMUTLAR:")
print("  State.AutoSteal = true/false          → Auto Steal Aç/Kapat")
print("  State.AutoHatch = true/false          → Auto Hatch Aç/Kapat")
print("  State.AutoClaim = true/false          → Auto Claim Aç/Kapat")
print("  State.AutoUpgrade = true/false        → Auto Upgrade Aç/Kapat")
print("  State.AutoEquipBest = true/false      → Auto Equip Aç/Kapat")
print("  State.AutoSell = true/false           → Auto Sell Aç/Kapat")
print("  State.AutoSellEggs = true/false       → Auto Sell Eggs Aç/Kapat")
print("  State.SpeedBoost = 50-500             → Hız Ayarla")
print("  State.RarityFilter = 'Any' vb         → Rarity Filtresi")
print("\n")

-- =====================================================
-- STARTUP NOTIFICATION
-- =====================================================
WindUI:Notify({
    Title    = "✅ SHARD Loaded",
    Content  = "Developed by: kabusxrd",
    Duration = 5,
})

print("╔════════════════════════════════════╗")
print("║   ✅ SHARD Script Yüklendi!      ║")
print("║   Developed by: kabusxrd          ║")
print("║   GitHub: kabusxd/egglua          ║")
print("╚════════════════════════════════════╝")
