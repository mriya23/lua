-- ⚡ ULTRA PERFECT CAST AUTO FISHING v35.2 (Safe Config Loading)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
local Character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

if _G.FishingScript then
    _G.FishingScript.Stop()
    task.wait(0.1)
end

local netFolder = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

local RF_ChargeFishingRod = netFolder:WaitForChild("RF/ChargeFishingRod")
local RF_RequestMinigame = netFolder:WaitForChild("RF/RequestFishingMinigameStarted")
local RF_CancelFishingInputs = netFolder:WaitForChild("RF/CancelFishingInputs")
local RF_UpdateAutoFishingState = netFolder:WaitForChild("RF/UpdateAutoFishingState")
local RE_FishingCompleted = netFolder:WaitForChild("RE/FishingCompleted")
local RE_MinigameChanged = netFolder:WaitForChild("RE/FishingMinigameChanged")
local RE_FishCaught = netFolder:WaitForChild("RE/FishCaught")
local RE_FishingStopped = netFolder:WaitForChild("RE/FishingStopped")

-- ⭐ SAFE CONFIG LOADING - Check if function exists
local function safeGetConfig(key, default)
    -- Check if GetConfigValue exists in _G
    if _G.GetConfigValue and type(_G.GetConfigValue) == "function" then
        local success, value = pcall(function()
            return _G.GetConfigValue(key, default)
        end)
        if success and value ~= nil then
            return value
        end
    end
    -- Return default if function doesn't exist or fails
    return default
end

-- ⭐ SAFE: Load saved settings dari GUI config
local function loadSavedSettings()
    local maxWait = safeGetConfig("InstantFishing.FishingDelay", 1.5)
    local cancelDelay = safeGetConfig("InstantFishing.CancelDelay", 0.19)
    
    return {
        MaxWaitTime = maxWait,
        CancelDelay = cancelDelay
    }
end

local savedSettings = loadSavedSettings()

local fishing = {
    Running = false,
    WaitingHook = false,
    CurrentCycle = 0,
    TotalFish = 0,
    PerfectCasts = 0,
    AmazingCasts = 0,
    FailedCasts = 0,
    Connections = {},
    Settings = {
        FishingDelay = 0.07,
        CancelDelay = savedSettings.CancelDelay,  -- ⭐ Use saved value
        HookDetectionDelay = 0.03,
        RetryDelay = 0.04,
        MaxWaitTime = savedSettings.MaxWaitTime,  -- ⭐ Use saved value
        FailTimeout = 2.5,
        PerfectChargeTime = 0.34,
        PerfectReleaseDelay = 0.005,
        PerfectPower = 0.95,
        UseMultiDetection = true,
        UseVisualDetection = true,
        UseSoundDetection = false,
    }
}

_G.FishingScript = fishing

-- ⭐ Auto-refresh settings setiap kali akan Start (dengan safety check)
local function refreshSettings()
    local maxWait = safeGetConfig("InstantFishing.FishingDelay", fishing.Settings.MaxWaitTime)
    local cancelDelay = safeGetConfig("InstantFishing.CancelDelay", fishing.Settings.CancelDelay)
    
    fishing.Settings.MaxWaitTime = maxWait
    fishing.Settings.CancelDelay = cancelDelay
end

local function disableFishingAnim()
    pcall(function()
        for _, track in pairs(Humanoid:GetPlayingAnimationTracks()) do
            local name = track.Name:lower()
            if name:find("fish") or name:find("rod") or name:find("cast") or name:find("reel") then
                track:Stop(0)
                track.TimePosition = 0
            end
        end
    end)

    task.spawn(function()
        local rod = Character:FindFirstChild("Rod") or Character:FindFirstChildWhichIsA("Tool")
        if rod and rod:FindFirstChild("Handle") then
            local handle = rod.Handle
            local weld = handle:FindFirstChildOfClass("Weld") or handle:FindFirstChildOfClass("Motor6D")
            if weld then
                weld.C0 = CFrame.new(0, -1, -1.2) * CFrame.Angles(math.rad(-10), 0, 0)
            end
        end
    end)
end

local function handleFailedCast()
    fishing.WaitingHook = false
    fishing.FailedCasts += 1
    
    pcall(function()
        RF_CancelFishingInputs:InvokeServer()
    end)
    
    task.wait(fishing.Settings.RetryDelay)
    
    if fishing.Running then
        fishing.PerfectCast()
    end
end

function fishing.PerfectCast()
    if not fishing.Running or fishing.WaitingHook then 
        return 
    end

    disableFishingAnim()
    fishing.CurrentCycle += 1

    local castSuccess = pcall(function()
        local startTime = tick()
        local chargeData = {[1] = startTime}
        
        local chargeResult = RF_ChargeFishingRod:InvokeServer(chargeData)
        if not chargeResult then 
            error("Charge fishing rod failed") 
        end

        local waitTime = fishing.Settings.PerfectChargeTime
        local endTime = tick() + waitTime
        while tick() < endTime and fishing.Running do
            task.wait(0.01)
        end

        task.wait(fishing.Settings.PerfectReleaseDelay)

        local releaseTime = tick()
        local perfectPower = fishing.Settings.PerfectPower

        local minigameResult = RF_RequestMinigame:InvokeServer(
            perfectPower,
            0,
            releaseTime
        )
        
        if not minigameResult then 
            handleFailedCast()
            return
        end

        fishing.WaitingHook = true
        local hookDetected = false
        local castStartTime = tick()
        local eventDetection

        eventDetection = RE_MinigameChanged.OnClientEvent:Connect(function(state)
            if fishing.WaitingHook and typeof(state) == "string" then
                local s = state:lower()
                if s:find("hook") or s:find("bite") or s:find("catch") or s == "!" then
                    hookDetected = true
                    eventDetection:Disconnect()
                    
                    fishing.WaitingHook = false

                    task.wait(fishing.Settings.HookDetectionDelay)
                    pcall(function()
                        RE_FishingCompleted:FireServer()
                    end)

                    task.wait(fishing.Settings.CancelDelay)
                    pcall(function()
                        RF_CancelFishingInputs:InvokeServer()
                    end)

                    task.wait(fishing.Settings.FishingDelay)
                    if fishing.Running then
                        fishing.PerfectCast()
                    end
                end
            end
        end)

        task.delay(fishing.Settings.MaxWaitTime, function()
            if fishing.WaitingHook and fishing.Running then
                if not hookDetected then
                    fishing.WaitingHook = false
                    eventDetection:Disconnect()

                    pcall(function()
                        RE_FishingCompleted:FireServer()
                    end)

                    task.wait(fishing.Settings.RetryDelay)
                    pcall(function()
                        RF_CancelFishingInputs:InvokeServer()
                    end)

                    task.wait(fishing.Settings.FishingDelay)
                    if fishing.Running then
                        fishing.PerfectCast()
                    end
                end
            end
        end)
        
        task.delay(fishing.Settings.FailTimeout, function()
            if fishing.WaitingHook and fishing.Running then
                local elapsedTime = tick() - castStartTime
                
                if elapsedTime >= fishing.Settings.FailTimeout then
                    if eventDetection then
                        eventDetection:Disconnect()
                    end
                    
                    handleFailedCast()
                end
            end
        end)
    end)

    if not castSuccess then
        task.wait(fishing.Settings.RetryDelay)
        if fishing.Running then
            fishing.PerfectCast()
        end
    end
end

function fishing.Start()
    if fishing.Running then return end
    
    -- ⭐ Refresh settings dari config sebelum start
    refreshSettings()
    
    fishing.Running = true
    fishing.CurrentCycle = 0
    fishing.TotalFish = 0
    fishing.PerfectCasts = 0
    fishing.AmazingCasts = 0
    fishing.FailedCasts = 0

    disableFishingAnim()

    fishing.Connections.FishingStopped = RE_FishingStopped.OnClientEvent:Connect(function()
        if fishing.Running and fishing.WaitingHook then
            handleFailedCast()
        end
    end)

    fishing.Connections.Caught = RE_FishCaught.OnClientEvent:Connect(function(name, data)
        if fishing.Running then
            fishing.WaitingHook = false
            fishing.TotalFish += 1

            local castResult = data and data.CastResult or "Unknown"
            if castResult == "Perfect" then
                fishing.PerfectCasts += 1
            elseif castResult == "Amazing" then
                fishing.AmazingCasts += 1
            end

            task.wait(fishing.Settings.CancelDelay)
            pcall(function()
                RF_CancelFishingInputs:InvokeServer()
            end)

            task.wait(fishing.Settings.FishingDelay)
            if fishing.Running then
                fishing.PerfectCast()
            end
        end
    end)

    fishing.Connections.AnimDisabler = task.spawn(function()
        while fishing.Running do
            disableFishingAnim()
            task.wait(0.1)
        end
    end)

    fishing.Connections.StatsReporter = task.spawn(function()
        while fishing.Running do
            task.wait(30)
        end
    end)

    task.wait(0.3)
    fishing.PerfectCast()
end

function fishing.Stop()
    if not fishing.Running then return end
    fishing.Running = false
    fishing.WaitingHook = false

    for _, conn in pairs(fishing.Connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        elseif typeof(conn) == "thread" then
            task.cancel(conn)
        end
    end

    fishing.Connections = {}
    
    pcall(function()
        RF_UpdateAutoFishingState:InvokeServer(true)
    end)
    
    task.wait(0.2)
    
    pcall(function()
        RF_CancelFishingInputs:InvokeServer()
    end)
end

-- ⭐ Function untuk update settings dari GUI (tetap ada untuk backward compatibility)
function fishing.UpdateSettings(maxWaitTime, cancelDelay)
    if maxWaitTime then
        fishing.Settings.MaxWaitTime = maxWaitTime
    end
    if cancelDelay then
        fishing.Settings.CancelDelay = cancelDelay
    end
end

return fishing
