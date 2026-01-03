--========================================================--
--       AutoTempleModule (NO YIELD, SAFE FIND VERSION)
--========================================================--

local AutoTemple = {}
local Run = false

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------
-- SAFE FIND SYSTEM (Anti Infinite Yield)
------------------------------------------------------------
local function SafeFind(parent, name)
    if not parent then return nil end
    return parent:FindFirstChild(name)
end

-- MAIN FOLDERS
local Shared = SafeFind(ReplicatedStorage, "Shared")
local Types = SafeFind(Shared, "Types")
local TempleStateFolder = SafeFind(Types, "TempleState")
local TempleLeverFolder = SafeFind(TempleStateFolder, "TempleLevers")

-- MAP FOLDER
local JungleFolder = SafeFind(Workspace, "JUNGLE INTERACTIONS")

-- Jika folder wajib tidak ada, AutoTemple tetap aman dipanggil (tidak error)
local LeverTypes = {
    "Crescent Artifact",
    "Arrow Artifact",
    "Diamond Artifact",
    "Hourglass Diamond Artifact"
}

------------------------------------------------------------
-- AMBIL STATUS LEVER DARI ATTRIBUTE ASLI GAME
------------------------------------------------------------
local function GetTempleProgress()
    local result = {}

    if not TempleLeverFolder then
        -- Kalau tidak ada folder, anggap semua FALSE (biar aman)
        for _, typeName in ipairs(LeverTypes) do
            result[typeName] = false
        end
        return result
    end

    for _, typeName in ipairs(LeverTypes) do
        local lever = SafeFind(TempleLeverFolder, typeName)
        result[typeName] = lever and lever:GetAttribute("Completed") == true
    end

    return result
end

------------------------------------------------------------
-- CARI LEVER FISIK DI MAP
------------------------------------------------------------
local function FindLeverByType(typeName)
    if not JungleFolder then return nil end

    for _, obj in ipairs(JungleFolder:GetChildren()) do
        if obj.Name == "TempleLever" then
            local Type = obj:GetAttribute("Type")
            if Type == typeName then
                local part = SafeFind(obj, "MovePiece") or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    return obj, part.Position
                end
            end
        end
    end

    return nil
end

------------------------------------------------------------
-- PROGRESS TEXT UNTUK GUI
------------------------------------------------------------
function AutoTemple.GetTempleInfoText()
    local prog = GetTempleProgress()
    local lines = {}

    for _, typeName in ipairs(LeverTypes) do
        table.insert(lines, typeName .. " : " .. (prog[typeName] and "✅" or "❌"))
    end

    return table.concat(lines, "\n")
end

------------------------------------------------------------
-- TELEPORT DIRECT CFRAME
------------------------------------------------------------
local function TeleportTo(pos)
    local char = LocalPlayer.Character
    if not char then return end

    local hrp = SafeFind(char, "HumanoidRootPart")
    if not hrp then return end

    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
end

------------------------------------------------------------
-- AMBIL LEVER YANG BELUM SELESAI
------------------------------------------------------------
local function GetNextLever()
    local prog = GetTempleProgress()

    for _, typeName in ipairs(LeverTypes) do
        if not prog[typeName] then
            local model, pos = FindLeverByType(typeName)
            if pos then return typeName, pos end
        end
    end

    return nil
end

------------------------------------------------------------
-- START AUTO TEMPLE
------------------------------------------------------------
function AutoTemple.Start()
    if Run then return end
    Run = true

    task.spawn(function()
        while Run do
            local typeName, pos = GetNextLever()

            if not typeName then
                Run = false
                break
            end

            TeleportTo(pos)
            task.wait(1.2)
        end
    end)
end

------------------------------------------------------------
-- STOP AUTO TEMPLE
------------------------------------------------------------
function AutoTemple.Stop()
    Run = false
end

return AutoTemple
