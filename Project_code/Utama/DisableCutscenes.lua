--=====================================================
-- DisableCutscenes.lua (FINAL MODULE VERSION)
-- Memiliki: Start(), Stop()
--=====================================================

local DisableCutscenes = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Index = Packages:WaitForChild("_Index")
local NetFolder = Index:WaitForChild("sleitnick_net@0.2.0")
local net = NetFolder:WaitForChild("net")

local ReplicateCutscene = net:FindFirstChild("ReplicateCutscene")
local StopCutscene = net:FindFirstChild("StopCutscene")
local BlackoutScreen = net:FindFirstChild("BlackoutScreen")

local running = false
local _connections = {}
local _loopThread = nil

local function connect(event, fn)
    if event then
        local c = event.OnClientEvent:Connect(fn)
        table.insert(_connections, c)
    end
end

-----------------------------------------------------
-- START
-----------------------------------------------------
function DisableCutscenes.Start()
    if running then return end
    running = true

    -- Block ReplicateCutscene
    connect(ReplicateCutscene, function(...)
        if running and StopCutscene then
            StopCutscene:FireServer()
        end
    end)

    -- Block BlackoutScreen
    connect(BlackoutScreen, function(...)
        -- just ignore
    end)

    -- Loop paksa StopCutscene tiap 1 detik
    _loopThread = task.spawn(function()
        while running do
            if StopCutscene then
                StopCutscene:FireServer()
            end
            task.wait(1)
        end
    end)
end

-----------------------------------------------------
-- STOP
-----------------------------------------------------
function DisableCutscenes.Stop()
    if not running then return end
    running = false

    -- Hapus semua koneksi listener
    for _, c in ipairs(_connections) do
        c:Disconnect()
    end

    _connections = {}

    -- Stop loop
    if _loopThread then
        task.cancel(_loopThread)
        _loopThread = nil
    end
end

-----------------------------------------------------
return DisableCutscenes
