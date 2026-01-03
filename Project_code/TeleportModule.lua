-- 🌍 TeleportModule.lua
-- Modul fungsi teleport + daftar lokasi

local TeleportModule = {}

TeleportModule.Locations = {
    ["Ancient Jungle"] = Vector3.new(1467.8480224609375, 7.447117328643799, -327.5971984863281),
    ["Ancient Ruin"] = Vector3.new(6045.40234375, -588.600830078125, 4608.9375),
    ["Coral Reefs"] = Vector3.new(-2921.858154296875, 3.249999761581421, 2083.2978515625),
    ["Crater Island"] = Vector3.new(1078.454345703125, 5.0720038414001465, 5099.396484375),
    ["Classic Island"] = Vector3.new(1253.974853515625, 9.999999046325684, 2816.7646484375),
    ["Christmas Island"] = Vector3.new(1130.576904, 23.854950, 1554.231567),
    ["Christmas Cave"] = Vector3.new(535.279724121093750, -580.581359863281250, 8900.060546875000000),
    ["Iron Cavern"] = Vector3.new(-8881.52734375, -581.7500610351562, 156.1653289794922),
    ["The Iron Cafe"] = Vector3.new(-8642.7265625, -547.5001831054688, 159.8160400390625),
    ["Esoteric Depths"] = Vector3.new(3224.075927734375, -1302.85498046875, 1404.9346923828125),
    ["Fisherman Island"] = Vector3.new(92.80695343017578, 9.531265258789062, 2762.082275390625),
    ["Kohana"] = Vector3.new(-643.3051147460938, 16.03544807434082, 622.3605346679688),
    ["Kohana Volcano"] = Vector3.new(-572.0244750976562, 39.4923210144043, 112.49259185791016),
    ["Lost Isle"] = Vector3.new(-3701.1513671875, 5.425841808319092, -1058.9107666015625),
    ["Sysiphus Statue"] = Vector3.new(-3656.56201171875, -134.5314178466797, -964.3167724609375),
    ["Sacred Temple"] = Vector3.new(1476.30810546875, -21.8499755859375, -630.8220825195312),
    ["Treasure Room"] = Vector3.new(-3601.568359375, -266.57373046875, -1578.998779296875),
    ["Tropical Grove"] = Vector3.new(-2104.467041015625, 6.268016815185547, 3718.2548828125),
    ["Underground Cellar"] = Vector3.new(2162.577392578125, -91.1981430053711, -725.591552734375),
    ["Weather Machine"] = Vector3.new(-1513.9249267578125, 6.499999523162842, 1892.10693359375)
}

function TeleportModule.TeleportTo(name)
    local player = game.Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")

    local target = TeleportModule.Locations[name]
    if not target then
        warn("⚠️ Lokasi '" .. tostring(name) .. "' tidak ditemukan!")
        return
    end

    root.CFrame = CFrame.new(target)
    print("✅ Teleported to:", name)
end

return TeleportModule


