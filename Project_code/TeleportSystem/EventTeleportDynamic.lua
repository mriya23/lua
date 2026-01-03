-- EventTeleportDynamic.lua
-- Optimized version: no lag + proper height offset + smart event detection
-- Put this file on your raw hosting and call it from GUI via loadstring or require

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local module = {}

-- =======================
-- Event coordinate database (copy from game's module)
-- =======================
module.Events = {
    ["Shark Hunt"] = {
        Vector3.new(1.64999, -1.3500, 2095.72),
        Vector3.new(1369.94, -1.3500, 930.125),
        Vector3.new(-1585.5, -1.3500, 1242.87),
        Vector3.new(-1896.8, -1.3500, 2634.37),
    },

    ["Worm Hunt"] = {
        Vector3.new(2190.85, -1.3999, 97.5749),
        Vector3.new(-2450.6, -1.3999, 139.731),
        Vector3.new(-267.47, -1.3999, 5188.53),
    },

    ["Megalodon Hunt"] = {
        Vector3.new(-1076.3, -1.3999, 1676.19),
        Vector3.new(-1191.8, -1.3999, 3597.30),
        Vector3.new(412.700, -1.3999, 4134.39),
    },

    ["Ghost Shark Hunt"] = {
        Vector3.new(489.558, -1.3500, 25.4060),
        Vector3.new(-1358.2, -1.3500, 4100.55),
        Vector3.new(627.859, -1.3500, 3798.08),
    },

    ["Treasure Hunt"] = nil, -- no static coords
}

-- =======================
-- Config
-- =======================
module.SearchRadius = 25            -- radius (studs) to consider "spawned object at coord"
module.ScanInterval = 2.0           -- seconds between scans (increased to reduce lag)
module.HeightOffset = 15            -- studs above detected position to teleport (avoid drowning)
module.MaxPartsToCheck = 500        -- limit parts checked per scan (anti-lag)
module.RequireEventSpawned = true   -- only teleport if event object actually detected
module.CacheValidPosition = true    -- use cached position when available
module.CacheDuration = 5            -- seconds to trust cached position
module.TeleportRadius = 50          -- if player within this radius of target, skip teleport (anti-spam)

-- =======================
-- Internal state
-- =======================
local running = false
local currentEventName = nil
local scanCoroutine = nil
local lastValidPosition = nil       -- cache last known good position
local lastValidTime = 0             -- when was last valid position found
local eventDetectedOnce = false     -- track if we ever detected the event spawning
local cachedParts = {}              -- cache workspace parts to reduce GetDescendants calls
local lastCacheUpdate = 0
local cacheUpdateInterval = 5       -- update part cache every 5 seconds

-- ================
-- Utilities
-- ================
local function safeCharacter()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char
end

local function getHRP()
    local char = LocalPlayer.Character
    return char and (char:FindFirstChild("HumanoidRootPart"))
end

-- Update cached parts list (happens infrequently to reduce lag)
local function updatePartCache()
    local now = tick()
    if now - lastCacheUpdate < cacheUpdateInterval then
        return -- use existing cache
    end
    
    lastCacheUpdate = now
    cachedParts = {}
    
    -- Only cache parts that could be event objects (filter out terrain, player characters, etc)
    local count = 0
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:IsA("BasePart") and inst.Parent and inst.Parent.Name ~= "Terrain" then
            -- Skip player characters
            local isPlayerPart = false
            local ancestor = inst.Parent
            for i = 1, 3 do -- check up to 3 levels up
                if ancestor and Players:GetPlayerFromCharacter(ancestor) then
                    isPlayerPart = true
                    break
                end
                ancestor = ancestor.Parent
                if not ancestor then break end
            end
            
            if not isPlayerPart then
                table.insert(cachedParts, inst)
                count = count + 1
                if count >= module.MaxPartsToCheck * 2 then
                    break -- limit initial cache size
                end
            end
        end
    end
end

-- Optimized: find parts near position using cached list and spatial optimization
local function findNearbyObject(centerPos, radius)
    local bestPart = nil
    local bestDist = math.huge
    local radiusSq = radius * radius -- use squared distance to avoid sqrt calculations
    
    -- Try fast path first: GetPartBoundsInBox (most efficient)
    if Workspace.GetPartBoundsInBox then
        local ok, parts = pcall(function()
            return Workspace:GetPartBoundsInBox(
                CFrame.new(centerPos), 
                Vector3.new(radius*2, radius*2, radius*2)
            )
        end)
        
        if ok and parts and #parts > 0 then
            for _, p in ipairs(parts) do
                if p and p:IsA("BasePart") then
                    -- Quick squared distance check
                    local offset = p.Position - centerPos
                    local distSq = offset.X*offset.X + offset.Y*offset.Y + offset.Z*offset.Z
                    
                    if distSq <= radiusSq and distSq < bestDist then
                        bestDist = distSq
                        bestPart = p
                    end
                end
            end
            return bestPart
        end
    end
    
    -- Fallback: use cached parts list (much faster than GetDescendants every time)
    updatePartCache()
    
    local checked = 0
    for _, part in ipairs(cachedParts) do
        if part and part.Parent then -- ensure part still exists
            -- Quick squared distance check
            local offset = part.Position - centerPos
            local distSq = offset.X*offset.X + offset.Y*offset.Y + offset.Z*offset.Z
            
            if distSq <= radiusSq and distSq < bestDist then
                bestDist = distSq
                bestPart = part
            end
            
            checked = checked + 1
            if checked >= module.MaxPartsToCheck then
                break -- anti-lag: limit checks per scan
            end
        end
    end
    
    return bestPart
end

-- Smart position resolver with caching
local function resolveActivePosition(eventName)
    local coords = module.Events[eventName]
    if not coords or #coords == 0 then
        return nil, false
    end
    
    -- Use cached position if still valid (reduces scanning frequency)
    if module.CacheValidPosition and lastValidPosition then
        local age = tick() - lastValidTime
        if age < module.CacheDuration then
            return lastValidPosition, true -- use cached position
        end
    end
    
    -- Scan for event spawn (optimized)
    for _, coord in ipairs(coords) do
        local part = findNearbyObject(coord, module.SearchRadius)
        if part then
            -- EVENT DETECTED! Apply height offset and cache
            local safePos = part.Position + Vector3.new(0, module.HeightOffset, 0)
            lastValidPosition = safePos
            lastValidTime = tick()
            return safePos, true
        end
    end
    
    -- No event detected
    if module.RequireEventSpawned then
        -- Clear cache if event despawned
        if lastValidPosition then
            lastValidPosition = nil
            lastValidTime = 0
        end
        return nil, false
    else
        -- Fallback mode: return closest coord with height offset
        local hrp = getHRP()
        if hrp then
            local best = nil
            local minDistSq = math.huge
            for _, coord in ipairs(coords) do
                local offset = hrp.Position - coord
                local distSq = offset.X*offset.X + offset.Y*offset.Y + offset.Z*offset.Z
                if distSq < minDistSq then
                    minDistSq = distSq
                    best = coord
                end
            end
            if best then
                return best + Vector3.new(0, module.HeightOffset, 0), false
            end
        end
        return coords[1] + Vector3.new(0, module.HeightOffset, 0), false
    end
end

-- Optimized teleport (single operation) with radius check
local function doTeleportToPos(pos)
    if not pos then return false end
    
    local char = LocalPlayer.Character
    if not char then return false end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    -- Check if player is already near target position (anti-spam teleport)
    local currentPos = hrp.Position
    local offset = currentPos - pos
    local distanceSq = offset.X*offset.X + offset.Y*offset.Y + offset.Z*offset.Z
    local radiusSq = module.TeleportRadius * module.TeleportRadius
    
    if distanceSq <= radiusSq then
        return false -- already near target, skip teleport
    end
    
    -- Single teleport operation (most reliable)
    local success = pcall(function()
        hrp.CFrame = CFrame.new(pos)
    end)
    
    return success
end

-- Exposed simple call: teleport once now to eventName
function module.TeleportNow(eventName)
    if not eventName then return false end
    
    local ok, pos, isSpawned = pcall(function()
        return resolveActivePosition(eventName)
    end)
    
    if not ok or not pos then
        return false
    end
    
    if module.RequireEventSpawned and not isSpawned then
        return false
    end
    
    return doTeleportToPos(pos)
end

-- Start auto-teleport loop (optimized, non-blocking)
function module.Start(eventName)
    if running then return false end
    if not eventName or not module.Events[eventName] then return false end
    
    running = true
    currentEventName = eventName
    eventDetectedOnce = false
    lastValidPosition = nil
    lastValidTime = 0
    
    -- Non-blocking coroutine loop
    scanCoroutine = task.spawn(function()
        while running do
            -- Wrap in pcall to prevent errors from breaking loop
            local ok, pos, isSpawned = pcall(function()
                return resolveActivePosition(currentEventName)
            end)
            
            if ok and pos then
                if module.RequireEventSpawned then
                    if isSpawned then
                        if not eventDetectedOnce then
                            eventDetectedOnce = true
                        end
                        doTeleportToPos(pos)
                    end
                else
                    doTeleportToPos(pos)
                end
            end
            
            -- Wait before next scan (reduces CPU usage significantly)
            task.wait(module.ScanInterval)
        end
    end)
    
    return true
end

function module.Stop()
    running = false
    currentEventName = nil
    eventDetectedOnce = false
    lastValidPosition = nil
    lastValidTime = 0
    cachedParts = {}
    
    if scanCoroutine then
        task.cancel(scanCoroutine)
        scanCoroutine = nil
    end
    
    return true
end

-- Utility: get event list (names)
function module.GetEventNames()
    local list = {}
    for name, _ in pairs(module.Events) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end

-- Utility: returns whether event has static coords
function module.HasCoords(eventName)
    local v = module.Events[eventName]
    return v ~= nil and #v > 0
end

-- Utility: check if event is currently spawned (cached result)
function module.IsEventActive(eventName)
    if not eventName then return false end
    
    -- Quick check using cache
    if lastValidPosition and currentEventName == eventName then
        local age = tick() - lastValidTime
        if age < module.CacheDuration then
            return true
        end
    end
    
    -- Full check if needed
    local ok, pos, isSpawned = pcall(function()
        return resolveActivePosition(eventName)
    end)
    
    return ok and isSpawned or false
end

-- Utility: get performance stats
function module.GetStats()
    return {
        running = running,
        eventName = currentEventName,
        eventDetected = eventDetectedOnce,
        cachedParts = #cachedParts,
        hasCachedPosition = lastValidPosition ~= nil,
        cacheAge = lastValidPosition and (tick() - lastValidTime) or 0
    }
end

return module