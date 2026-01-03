-- ULTRA SPEED AUTO FISHING V2 - OPTIMIZED FOR MAXIMUM SPEED
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
        FishingDelay = 0.05,
        CancelDelay = 0.01,
        HookWaitTime = 0.01,
        CastDelay = 0.25,
        TimeoutDelay = 0.8,
    },
}

_G.FishingScript = fishing

-- Event handler optimized dengan spawn untuk non-blocking
RE_MinigameChanged.OnClientEvent:Connect(function(state)
    if fishing.WaitingHook and typeof(state) == "string" and string.find(string.lower(state), "hook") then
        fishing.WaitingHook = false
        
        task.spawn(function()
            task.wait(fishing.Settings.HookWaitTime)
            RE_FishingCompleted:FireServer()
            
            task.wait(fishing.Settings.CancelDelay)
            pcall(function() RF_CancelFishingInputs:InvokeServer() end)
            
            task.wait(fishing.Settings.FishingDelay)
            if fishing.Running then fishing.Cast() end
        end)
    end
end)

RE_FishCaught.OnClientEvent:Connect(function(name, data)
    if fishing.Running then
        fishing.WaitingHook = false
        fishing.TotalFish = fishing.TotalFish + 1
        
        task.spawn(function()
            task.wait(fishing.Settings.CancelDelay)
            pcall(function() RF_CancelFishingInputs:InvokeServer() end)
            
            task.wait(fishing.Settings.FishingDelay)
            if fishing.Running then fishing.Cast() end
        end)
    end
end)

function fishing.Cast()
    if not fishing.Running or fishing.WaitingHook then return end
    
    fishing.CurrentCycle = fishing.CurrentCycle + 1
    
    task.spawn(function()
        pcall(function()
            -- Charge dan request dalam satu batch untuk kecepatan maksimal
            RF_ChargeFishingRod:InvokeServer({[10] = tick()})
            task.wait(fishing.Settings.CastDelay)
            RF_RequestMinigame:InvokeServer(10, 0, tick())
            
            fishing.WaitingHook = true
            
            -- Timeout handler yang lebih cepat
            task.delay(fishing.Settings.TimeoutDelay, function()
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
