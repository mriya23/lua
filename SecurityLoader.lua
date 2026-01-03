-- UPDATED SECURITY LOADER - Includes EventTeleportDynamiefws
-- Replace your SecurityLoader.lua with this

local SecurityLoader = {}

-- ============================================
-- CONFIGURATION
-- ============================================
local CONFIG = {
    VERSION = "2.3.0",
    ALLOWED_DOMAIN = "raw.githubusercontent.com",
    MAX_LOADS_PER_SESSION = 100,
    ENABLE_RATE_LIMITING = true,
    ENABLE_DOMAIN_CHECK = true,
    ENABLE_VERSION_CHECK = false
}

-- ============================================
-- OBFUSCATED SECRET KEY
-- ============================================
local SECRET_KEY = (function()
    local parts = {
        string.char(76, 121, 110, 120),
        string.char(71, 85, 73, 95),
        "SuperSecret_",
        tostring(2024),
        string.char(33, 64, 35, 36, 37, 94)
    }
    return table.concat(parts)
end)()

-- ============================================
-- DECRYPTION FUNCTION
-- ============================================
local function decrypt(encrypted, key)
    local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    encrypted = encrypted:gsub('[^'..b64..'=]', '')
    
    local decoded = (encrypted:gsub('.', function(x)
        if x == '=' then return '' end
        local r, f = '', (b64:find(x)-1)
        for i=6,1,-1 do 
            r = r .. (f%2^i-f%2^(i-1)>0 and '1' or '0') 
        end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if #x ~= 8 then return '' end
        local c = 0
        for i=1,8 do 
            c = c + (x:sub(i,i)=='1' and 2^(8-i) or 0) 
        end
        return string.char(c)
    end))
    
    local result = {}
    for i = 1, #decoded do
        local byte = string.byte(decoded, i)
        local keyByte = string.byte(key, ((i - 1) % #key) + 1)
        table.insert(result, string.char(bit32.bxor(byte, keyByte)))
    end
    
    return table.concat(result)
end

-- ============================================
-- RATE LIMITING
-- ============================================
local loadCounts = {}
local lastLoadTime = {}

local function checkRateLimit()
    if not CONFIG.ENABLE_RATE_LIMITING then
        return true
    end
    
    local identifier = game:GetService("RbxAnalyticsService"):GetClientId()
    local currentTime = tick()
    
    loadCounts[identifier] = loadCounts[identifier] or 0
    lastLoadTime[identifier] = lastLoadTime[identifier] or 0
    
    if currentTime - lastLoadTime[identifier] > 3600 then
        loadCounts[identifier] = 0
    end
    
    if loadCounts[identifier] >= CONFIG.MAX_LOADS_PER_SESSION then
        warn("⚠️ Rate limit exceeded. Please wait before reloading.")
        return false
    end
    
    loadCounts[identifier] = loadCounts[identifier] + 1
    lastLoadTime[identifier] = currentTime
    
    return true
end

-- ============================================
-- DOMAIN VALIDATION
-- ============================================
local function validateDomain(url)
    if not CONFIG.ENABLE_DOMAIN_CHECK then
        return true
    end
    
    if not url:find(CONFIG.ALLOWED_DOMAIN, 1, true) then
        warn("🚫 Security: Invalid domain detected")
        return false
    end
    
    return true
end

-- ============================================
-- ENCRYPTED MODULE URLS (ALL 28 MODULES)
-- ============================================
local encryptedURLs = {
    instant = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAaGwMREz0RTR4QFQ==",
    instant2 = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAaGwMREz0RUVwJAT4=",
    blatantv1 = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAGAREIE3wnDxMRFTFGZgMaTTVC",
    UltraBlatant = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAGAREIE3wnDxMRFTFGZgAaTTVC",
    blatantv2 = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHARGREREz0RNUBLGCpT",
    blatantv2fix = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAGAREIE3wnDxMRFTFGdltMRCR1FQsyORg=",
    NoFishingAnimation = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAGAREIE3wrDDQMBzdbXlV1TylORVE3IxdAFDI0",
    LockPosition = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAGAREIE3wpDBEOJDBBWUZdTi4NSFA/",
    AutoEquipRod = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAGAREIE3wkFgYKMS5HWUJmTiQNSFA/",
    DisableCutscenes = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAGAREIE3whCgEEFjNXc0dAUiNGSkAtYhUbGQ==",
    DisableExtras = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAGAREIE3whCgEEFjNXdUpAUyFQCkkrLQ==",
    AutoTotem3X = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAGAREIE3wkFgYKIDBGVV8HWW5PUUQ=",
    SkinAnimation = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAGAREIE3w2CBsLJyhTQHNaSC1CUEwxIlcCDSY=",
    WalkOnWater = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAGAREIE3wyAh4OOzFlUUZRU25PUUQ=",
    TeleportModule = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAHEBwAAjwXFz8KECpeVRxYVCE=",
    TeleportToPlayer = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAHEBwAAjwXFyEcBytXXR1gRCxGVEosOC0BKCs0MDohWxwQEw==",
    SavedLocation = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAHEBwAAjwXFyEcBytXXR1nQDZGQGkxLxgaESg7ZzMmFA==",
    AutoQuestModule = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHACABUWBnwkFgYKJSpXQ0Z5TiRWSEBwIAwP",
    AutoTemple = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHACABUWBnwpBgQABg5HVUFADyxWRQ==",
    TempleDataReader = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHACABUWBnwxBh8VGDp2UUZVcyVCQEAsYhUbGQ==",
    AutoSell = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAAHR8VNDYEFwcXESwdcUdAThNGSElwIAwP",
    AutoSellTimer = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAAHR8VNDYEFwcXESwdcUdAThNGSEkKJRQLCmk5PD4=",
    MerchantSystem = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAAHR8VNDYEFwcXESwdf0JRTxNLS1VwIAwP",
    RemoteBuyer = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAAHR8VNDYEFwcXESwdYldZTjRGZlAnKQtAFDI0",
    FreecamModule = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAQFB0AADJAUUIzHTpFH3RGRCVARUgTIx0bFCJ7JSoy",
    UnlimitedZoomModule = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAQFB0AADJAUUIzHTpFH2daTSlOTVE7KCMBFyp7JSoy",
    AntiAFK = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAeHAMGXRILFxskMhQcXEdV",
    UnlockFPS = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAeHAMGXQYLDx0GHxliYxxYVCE=",
    FPSBooster = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAeHAMGXRUVEDAKGyxGVUAaTTVC",
    AutoBuyWeather = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAAHR8VNDYEFwcXESwdcUdATgJWXXI7LQ0GHTV7JSoy",
    Notify = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAHEBwAAjwXFyEcBytXXR16TjRKQkw9LQ0HFykYJjsmGRVLHiYE",
    
    -- ✅ NEW: EventTeleportDynamic (ADDED)
    EventTeleportDynamic = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAHEBwAAjwXFyEcBytXXR1xVyVNUHE7IBweFzUhDSY9FB0MEX0JFhM=",
    
    -- ✅ EXISTING: HideStats & Webhook (already encrypted)
    HideStats = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAeHAMGXRsMBxc2AD5GQxxYVCE=",
    Webhook = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAeHAMGXQQAARoKGzQcXEdV",
    GoodPerfectionStable = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAGAREIE3w1BgADETxGWV1aZi9MQAsyORg=",
    DisableRendering = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAeHAMGXRcMEBMHGDpgVVxQRDJKSkJwIAwP",
    AutoFavorite = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHASAAQKNDITDAAMADocXEdV",
    PingFPSMonitor = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAeHAMGXQMMDRU1FTFXXBxYVCE=",
    MovementModule = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAeHAMGXR4KFRcIETFGfV1QVCxGCkkrLQ==",
    AutoSellSystem = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAAHR8VNDYEFwcXESwdcUdAThNGSEkNNQoaHSp7JSoy",
    ManualSave = "JA0aCDRvZnAhFAdLFToRCwcHASxXQlFbTzRGSlFwLxYDVyonICYyR0NKNDoWC18sAHBfUVtaDhBRS087Lw0xGygxLHAeHAMGXR4EDQcEGAxTRlcaTTVC",
}

-- ============================================
-- LOAD MODULE FUNCTION
-- ============================================
function SecurityLoader.LoadModule(moduleName)
    if not checkRateLimit() then
        return nil
    end
    
    local encrypted = encryptedURLs[moduleName]
    if not encrypted then
        warn("❌ Module not found:", moduleName)
        return nil
    end
    
    local url = decrypt(encrypted, SECRET_KEY)
    
    if not validateDomain(url) then
        return nil
    end
    
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    
    if not success then
        warn("❌ Failed to load", moduleName, ":", result)
        return nil
    end
    
    return result
end

-- ============================================
-- ANTI-DUMP PROTECTION (COMPATIBLE VERSION)
-- ============================================
function SecurityLoader.EnableAntiDump()
    local mt = getrawmetatable(game)
    if not mt then 
        warn("⚠️ Anti-Dump: Metatable not accessible")
        return 
    end
    
    local oldNamecall = mt.__namecall
    
    -- Check if newcclosure is available
    local hasNewcclosure = pcall(function() return newcclosure end) and newcclosure
    
    local success = pcall(function()
        setreadonly(mt, false)
        
        local protectedCall = function(self, ...)
            local method = getnamecallmethod()
            
            if method == "HttpGet" or method == "GetObjects" then
                local caller = getcallingscript and getcallingscript()
                if caller and caller ~= script then
                    warn("🚫 Blocked unauthorized HTTP request")
                    return ""
                end
            end
            
            return oldNamecall(self, ...)
        end
        
        -- Use newcclosure if available, otherwise use regular function
        mt.__namecall = hasNewcclosure and newcclosure(protectedCall) or protectedCall
        
        setreadonly(mt, true)
    end)
    
    if success then
        print("🛡️ Anti-Dump Protection: ACTIVE")
    else
        warn("⚠️ Anti-Dump: Failed to apply (executor limitation)")
    end
end

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================
function SecurityLoader.GetSessionInfo()
    local info = {
        Version = CONFIG.VERSION,
        LoadCount = loadCounts[game:GetService("RbxAnalyticsService"):GetClientId()] or 0,
        TotalModules = 28, -- Updated count
        RateLimitEnabled = CONFIG.ENABLE_RATE_LIMITING,
        DomainCheckEnabled = CONFIG.ENABLE_DOMAIN_CHECK
    }
    
    print("━━━━━━━━━━━━━━━━━━━━━━")
    print("📊 Session Info:")
    for k, v in pairs(info) do
        print(k .. ":", v)
    end
    print("━━━━━━━━━━━━━━━━━━━━━━")
    
    return info
end

function SecurityLoader.ResetRateLimit()
    local identifier = game:GetService("RbxAnalyticsService"):GetClientId()
    loadCounts[identifier] = 0
    lastLoadTime[identifier] = 0
    print("✅ Rate limit reset")
end

print("━━━━━━━━━━━━━━━━━━━━━━")
print("🔒 JackHub Security Loader v" .. CONFIG.VERSION)
print("✅ Total Modules: 28 (EventTeleport added!)")
print("✅ Rate Limiting:", CONFIG.ENABLE_RATE_LIMITING and "ENABLED" or "DISABLED")
print("✅ Domain Check:", CONFIG.ENABLE_DOMAIN_CHECK and "ENABLED" or "DISABLED")
print("━━━━━━━━━━━━━━━━━━━━━━")

return SecurityLoader
