-- ╔═════════════════════════════════════════════════════╗
-- ║          SHARD - EGG FARMING SCRIPT               ║
-- ║        Developed by: kabusxrd                     ║
-- ║     GitHub: https://github.com/kabusxd/egglua    ║
-- ╚═════════════════════════════════════════════════════╝

-- =====================================================
-- GAME SERVICES
-- =====================================================
local players    = game:GetService("Players")
local RS         = game:GetService("ReplicatedStorage")
local player     = players.LocalPlayer

-- =====================================================
-- STATE CONFIGURATION
-- =====================================================
local State = {
    AutoSteal       = false,
    SpeedBoost      = 50,
    RarityFilter    = "Any",
    StealOnce       = false,
    AutoHatch       = false,
    AutoClaim       = false,
    AutoUpgrade     = false,
    AutoEquipBest   = false,
    AutoSell        = false,
    AutoSellEggs    = false,
    ClaimInterval   = 5,
    UpgradeInterval = 5,
}

local Threads = {}

print("\n╔════════════════════════════════════════════╗")
print("║     🥚 SHARD - Egg Farming Script        ║")
print("║     Developed by: kabusxrd               ║")
print("║     GitHub: github.com/kabusxd/egglua    ║")
print("╚════════════════════════════════════════════╝\n")

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
                if n:find(pat:lower(), 1, true) then 
                    return desc 
                end
            end
        end
    end
    return nil
end

local function findEggs()
    local eggs = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find("egg", 1, true) then
            table.insert(eggs, obj)
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
            pcall(function() 
                if fireproximityprompt then fireproximityprompt(pp) end 
            end)
        end
    end
    for _, cd in ipairs(egg:GetDescendants()) do
        if cd:IsA("ClickDetector") then
            pcall(function() 
                if fireclickdetector then fireclickdetector(cd) end 
            end)
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
                            print("✅ Steal tamamlandı")
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
    print("✅ Auto Steal başladı")
end

local function startHatchLoop()
    killThread("hatch")
    Threads["hatch"] = task.spawn(function()
        while State.AutoHatch do
            local remote = findRemote("hatch","open","crack","incubat")
            if remote then
                pcall(function() remote:FireServer() end)
            end
            task.wait(1.5)
        end
    end)
    print("✅ Auto Hatch başladı")
end

local function startClaimLoop()
    killThread("claim")
    Threads["claim"] = task.spawn(function()
        while State.AutoClaim do
            local remote = findRemote("claim","reward","daily","bonus","chest")
            if remote then 
                pcall(function() remote:FireServer() end) 
            end
            task.wait(State.ClaimInterval)
        end
    end)
    print("✅ Auto Claim başladı")
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
    print("✅ Auto Upgrade başladı")
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
    print("✅ Auto Equip başladı")
end

local function startSellLoop()
    killThread("sell")
    Threads["sell"] = task.spawn(function()
        while State.AutoSell do
            local remote = findRemote("sellpet","sell","sellall")
            if remote then
                pcall(function() remote:FireServer() end)
            end
            task.wait(2.5)
        end
    end)
    print("✅ Auto Sell başladı")
end

local function startSellEggLoop()
    killThread("sellegg")
    Threads["sellegg"] = task.spawn(function()
        while State.AutoSellEggs do
            local remote = findRemote("sellegg","sell","sellall")
            if remote then
                pcall(function() remote:FireServer() end)
            end
            task.wait(2.5)
        end
    end)
    print("✅ Auto Sell Eggs başladı")
end

-- =====================================================
-- COMMAND INTERFACE
-- =====================================================
print("📋 KOMUTLAR:\n")
print("State.AutoSteal = true/false")
print("State.AutoHatch = true/false")
print("State.AutoClaim = true/false")
print("State.AutoUpgrade = true/false")
print("State.AutoEquipBest = true/false")
print("State.AutoSell = true/false")
print("State.AutoSellEggs = true/false")
print("State.SpeedBoost = 50 (sayı)")
print("State.RarityFilter = 'Any' (Any/Rare/Epic vb)")
print("\n✅ Script Hazır!\n")

return State
