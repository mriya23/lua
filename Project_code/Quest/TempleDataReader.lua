--========================================================--
--        TempleDataReader V3 (AutoScan + UltraFast)
--========================================================--

local TempleDataReader = {}

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Ready = false
local Listeners = {}
local Cached = {}

local KEYS = {
    ["Crescent Artifact"] = {"CrescentArtifact", "Crescent", "Artifact1"},
    ["Arrow Artifact"] = {"ArrowArtifact", "Arrow", "Artifact2"},
    ["Diamond Artifact"] = {"DiamondArtifact", "Diamond", "Artifact3"},
    ["Hourglass Diamond Artifact"] = {"HourglassArtifact", "Hourglass", "Artifact4"},
}

------------------------------------------------------------
-- Safe Get Attribute in many possible locations
------------------------------------------------------------
local function ReadArtifact(mainName, aliases)
    -- Player attribute
    for _, k in ipairs(aliases) do
        local v = Player:GetAttribute(k)
        if v ~= nil then return v == true or v == 1 end
    end

    -- Character attributes
    if Player.Character then
        for _, k in ipairs(aliases) do
            local v = Player.Character:GetAttribute(k)
            if v ~= nil then return v == true or v == 1 end
        end
    end

    -- Folder under Player
    local folder = Player:FindFirstChild("TempleLevers")
    if folder then
        for _, k in ipairs(aliases) do
            local obj = folder:FindFirstChild(k)
            if obj and obj.Value ~= nil then return obj.Value == true end
        end
    end

    -- ReplicatedStorage fallback
    local rs = game:GetService("ReplicatedStorage")
    local gameData = rs:FindFirstChild("GameData")
    if gameData and gameData:FindFirstChild("Temple") then
        local t = gameData.Temple
        for _, k in ipairs(aliases) do
            local obj = t:FindFirstChild(k)
            if obj and obj.Value ~= nil then return obj.Value == true end
        end
    end

    return false
end

------------------------------------------------------------
-- Build readable status table
------------------------------------------------------------
local function BuildStatus()
    local data = {}
    for displayName, aliases in pairs(KEYS) do
        data[displayName] = ReadArtifact(displayName, aliases)
    end
    return data
end

------------------------------------------------------------
-- Fire callbacks
------------------------------------------------------------
local function FireUpdate()
    local status = BuildStatus()
    Cached = status
    for _, fn in ipairs(Listeners) do
        task.spawn(fn, status)
    end
end

------------------------------------------------------------
-- API
------------------------------------------------------------
function TempleDataReader.GetTempleStatus()
    if not Ready then
        return {}
    end
    return Cached
end

function TempleDataReader.OnTempleUpdate(cb)
    table.insert(Listeners, cb)
    if Ready then
        cb(Cached)
    end
end

------------------------------------------------------------
-- Start Scanner
------------------------------------------------------------
task.spawn(function()
    -- Wait until character loaded
    repeat task.wait() until Player.Character

    Ready = true
    Cached = BuildStatus()
    FireUpdate()

    -- Auto monitor attribute changes
    Player.AttributeChanged:Connect(FireUpdate)
    Player.CharacterAdded:Connect(function()
        task.wait(0.5)
        FireUpdate()
    end)
end)

return TempleDataReader
