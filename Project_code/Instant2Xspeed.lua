-- Instant2Xspeed.lua (no toggle key) - ULTRA SPEED AUTO FISHING
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local netFolder = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")

local RF_ChargeFishingRod = netFolder:WaitForChild("RF/ChargeFishingRod")
local RF_RequestMinigame = netFolder:WaitForChild("RF/RequestFishingMinigameStarted")
local RF_CancelFishingInputs = netFolder:WaitForChild("RF/CancelFishingInputs")
local RE_FishingCompleted = netFolder:WaitForChild("RE/FishingCompleted")
local RE_MinigameChanged = netFolder:WaitForChild("RE/FishingMinigameChanged")
local RE_FishCaught = netFolder:WaitForChild("RE/FishCaught")

local fishing = {
    Running = false,
    WaitingHook = false,
    CurrentCycle = 0,
    TotalFish = 0,
    Settings = {
        FishingDelay = 0.3,
        CancelDelay = 0.05,
    },
}

_G.FishingScript = fishing

RE_MinigameChanged.OnClientEvent:Connect(function(state)
    if fishing.WaitingHook and typeof(state) == "string" and string.find(string.lower(state), "hook") then
        fishing.WaitingHook = false
        task.wait(0.30)
        RE_FishingCompleted:FireServer()
        
        task.wait(fishing.Settings.CancelDelay)
        pcall(function() RF_CancelFishingInputs:InvokeServer() end)
        
        task.wait(fishing.Settings.FishingDelay)
        if fishing.Running then fishing.Cast() end
    end
end)

RE_FishCaught.OnClientEvent:Connect(function(name, data)
    if fishing.Running then
        fishing.WaitingHook = false
        fishing.TotalFish = fishing.TotalFish + 1
        
        task.wait(fishing.Settings.CancelDelay)
        pcall(function() RF_CancelFishingInputs:InvokeServer() end)
        
        task.wait(fishing.Settings.FishingDelay)
        if fishing.Running then fishing.Cast() end
    end
end)

function fishing.Cast()
    if not fishing.Running or fishing.WaitingHook then return end
    fishing.CurrentCycle = fishing.CurrentCycle + 1
    
    pcall(function()
        RF_ChargeFishingRod:InvokeServer({[10] = tick()})
        task.wait(0.07)
        RF_RequestMinigame:InvokeServer(10, 0, tick())
        fishing.WaitingHook = true
        
        task.delay(1.1, function()
            if fishing.WaitingHook and fishing.Running then
                fishing.WaitingHook = false
                RE_FishingCompleted:FireServer()
                
                task.wait(fishing.Settings.CancelDelay)
                pcall(function() RF_CancelFishingInputs:InvokeServer() end)
                
                task.wait(fishing.Settings.FishingDelay)
                if fishing.Running then fishing.Cast() end
            end
        end)
    end)
end

function fishing.Start()
    if fishing.Running then return end
    fishing.Running = true
    fishing.CurrentCycle = 0
    fishing.TotalFish = 0
    fishing.Cast()
end

function fishing.Stop()
    fishing.Running = false
    fishing.WaitingHook = false
end

return fishing
