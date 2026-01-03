-- ============================================
-- MANUAL SAVE MODULE v2.3
-- Integrated Config System for LynX GUI
-- ============================================

local ManualSave = {}
local HttpService = game:GetService("HttpService")

-- ============================================
-- CONFIGURATION
-- ============================================
local CONFIG = {
    FOLDER = "LynxGUI_v23",
    FILE = "config.json",
    AUTO_SAVE = false,
    AUTO_SAVE_INTERVAL = 30,
    BACKUP_ENABLED = true,
    MAX_BACKUPS = 3
}

-- ============================================
-- DEFAULT CONFIGURATION STRUCTURE
-- ============================================
local DefaultConfig = {
    -- Version tracking
    ConfigVersion = "2.3.0",
    LastSaved = "",
    
    -- AUTO FISHING SETTINGS
    AutoFishing = {
        InstantMode = "None", -- "Fast", "Perfect", "None"
        InstantEnabled = false,
        FishingDelay = 1.30,
        CancelDelay = 0.19,
        
        -- Blatant Tester
        BlatantTesterEnabled = false,
        BlatantTesterCompleteDelay = 0.5,
        BlatantTesterCancelDelay = 0.1,
        
        -- Blatant V1
        BlatantV1Enabled = false,
        BlatantV1CompleteDelay = 0.05,
        BlatantV1CancelDelay = 0.1,
        
        -- Ultra Blatant
        UltraBlatantEnabled = false,
        UltraBlatantCompleteDelay = 0.05,
        UltraBlatantCancelDelay = 0.1,
        
        -- Fast Auto Fishing Perfect
        FastPerfectEnabled = false,
        FastPerfectFishingDelay = 0.05,
        FastPerfectCancelDelay = 0.01,
        FastPerfectTimeoutDelay = 0.8
    },
    
    -- SUPPORT FEATURES
    SupportFeatures = {
        NoFishingAnimation = false,
        PingFPSMonitor = false,
        LockPosition = false,
        DisableCutscenes = false,
        DisableFishNotification = false,
        DisableSkinEffect = false,
        WalkOnWater = false,
        GoodPerfectionStable = false
    },
    
    -- AUTO FAVORITE
    AutoFavorite = {
        Enabled = false,
        SelectedTiers = {},
        SelectedVariants = {}
    },
    
    -- AUTO TOTEM
    AutoTotem = {
        Running = false
    },
    
    -- SKIN ANIMATION
    SkinAnimation = {
        Enabled = false,
        SelectedSkin = nil -- "Eclipse", "HolyTrident", "SoulScythe"
    },
    
    -- TELEPORT SETTINGS
    Teleport = {
        LastLocation = nil,
        SavedLocation = nil,
        EventTeleport = {
            Enabled = false,
            SelectedEvent = nil
        }
    },
    
    -- SHOP SETTINGS
    Shop = {
        AutoSellTimer = {
            Enabled = false,
            Interval = 5
        },
        AutoSellByCount = {
            Enabled = false,
            Target = 235
        },
        AutoBuyWeather = {
            Enabled = false,
            SelectedWeathers = {}
        },
        LastSelectedRod = nil,
        LastSelectedBait = nil
    },
    
    -- WEBHOOK SETTINGS
    Webhook = {
        Enabled = false,
        URL = "",
        DiscordID = "",
        SelectedRarities = {}
    },
    
    -- CAMERA VIEW SETTINGS
    CameraView = {
        UnlimitedZoom = false,
        Freecam = {
            Enabled = false,
            Speed = 50,
            Sensitivity = 0.3
        }
    },
    
    -- SETTINGS PAGE
    Settings = {
        AntiAFK = false,
        Sprint = {
            Enabled = false,
            Speed = 50
        },
        InfiniteJump = false,
        FPSBooster = false,
        DisableRendering = false,
        FPSLimit = 60,
        HideStats = {
            Enabled = false,
            FakeName = "Guest",
            FakeLevel = "1"
        }
    },
    
    -- UI SETTINGS
    UI = {
        WindowPosition = {0.5, -210, 0.5, -140},
        WindowSize = {0, 420, 0, 280},
        Minimized = false,
        IconPosition = {0, 20, 0, 100},
        CurrentPage = "Main"
    }
}

-- ============================================
-- CURRENT CONFIGURATION (RUNTIME)
-- ============================================
ManualSave.Config = {}

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

-- Deep copy table
local function deepCopy(original)
    local copy
    if type(original) == 'table' then
        copy = {}
        for key, value in next, original, nil do
            copy[deepCopy(key)] = deepCopy(value)
        end
        setmetatable(copy, deepCopy(getmetatable(original)))
    else
        copy = original
    end
    return copy
end

-- Merge tables (updates target with source values)
local function mergeTables(target, source)
    for key, value in pairs(source) do
        if type(value) == "table" and type(target[key]) == "table" then
            mergeTables(target[key], value)
        else
            target[key] = value
        end
    end
end

-- Get full file path
local function getFilePath()
    return CONFIG.FOLDER .. "/" .. CONFIG.FILE
end

-- Get backup file path
local function getBackupPath(index)
    return CONFIG.FOLDER .. "/backup_" .. index .. ".json"
end

-- ============================================
-- FOLDER MANAGEMENT
-- ============================================

function ManualSave.EnsureFolderExists()
    if not (isfolder and makefolder) then
        warn("❌ [ManualSave] Executor does not support file operations!")
        return false
    end
    
    if not isfolder(CONFIG.FOLDER) then
        pcall(function()
            makefolder(CONFIG.FOLDER)
            print("📁 [ManualSave] Created config folder:", CONFIG.FOLDER)
        end)
    end
    
    return isfolder(CONFIG.FOLDER)
end

-- ============================================
-- BACKUP MANAGEMENT
-- ============================================

function ManualSave.CreateBackup()
    if not CONFIG.BACKUP_ENABLED then return end
    if not (isfile and readfile and writefile) then return end
    
    local success, err = pcall(function()
        local filePath = getFilePath()
        
        if isfile(filePath) then
            local currentData = readfile(filePath)
            
            -- Shift existing backups
            for i = CONFIG.MAX_BACKUPS - 1, 1, -1 do
                local oldBackup = getBackupPath(i)
                local newBackup = getBackupPath(i + 1)
                
                if isfile(oldBackup) then
                    local backupData = readfile(oldBackup)
                    writefile(newBackup, backupData)
                end
            end
            
            -- Create new backup
            writefile(getBackupPath(1), currentData)
            print("💾 [ManualSave] Backup created")
        end
    end)
    
    if not success then
        warn("⚠️ [ManualSave] Backup failed:", err)
    end
end

function ManualSave.RestoreBackup(index)
    if not (isfile and readfile and writefile) then
        return false, "File operations not supported"
    end
    
    index = index or 1
    local backupPath = getBackupPath(index)
    
    if not isfile(backupPath) then
        return false, "Backup " .. index .. " not found"
    end
    
    local success, err = pcall(function()
        local backupData = readfile(backupPath)
        writefile(getFilePath(), backupData)
    end)
    
    if success then
        ManualSave.LoadConfig()
        return true, "Backup " .. index .. " restored successfully"
    else
        return false, "Failed to restore backup: " .. tostring(err)
    end
end

-- ============================================
-- SAVE CONFIGURATION
-- ============================================

function ManualSave.SaveConfig()
    if not writefile then
        warn("❌ [ManualSave] Executor does not support writefile!")
        return false, "File writing not supported"
    end
    
    if not ManualSave.EnsureFolderExists() then
        return false, "Failed to create config folder"
    end
    
    local success, err = pcall(function()
        -- Create backup before saving
        ManualSave.CreateBackup()
        
        -- Update timestamp
        ManualSave.Config.LastSaved = os.date("%Y-%m-%d %H:%M:%S")
        
        -- Convert to JSON
        local jsonData = HttpService:JSONEncode(ManualSave.Config)
        
        -- Write to file
        writefile(getFilePath(), jsonData)
        
        print("✅ [ManualSave] Configuration saved successfully!")
        print("📝 [ManualSave] Location:", getFilePath())
    end)
    
    if success then
        return true, "Configuration saved successfully"
    else
        warn("❌ [ManualSave] Save failed:", err)
        return false, "Save failed: " .. tostring(err)
    end
end

-- ============================================
-- LOAD CONFIGURATION
-- ============================================

function ManualSave.LoadConfig()
    if not (readfile and isfile) then
        warn("❌ [ManualSave] Executor does not support file operations!")
        ManualSave.Config = deepCopy(DefaultConfig)
        return false, "File operations not supported"
    end
    
    ManualSave.EnsureFolderExists()
    
    local filePath = getFilePath()
    
    if not isfile(filePath) then
        print("⚠️ [ManualSave] No saved config found, using defaults")
        ManualSave.Config = deepCopy(DefaultConfig)
        return false, "No saved config found"
    end
    
    local success, err = pcall(function()
        -- Read file
        local jsonData = readfile(filePath)
        
        -- Parse JSON
        local loadedConfig = HttpService:JSONDecode(jsonData)
        
        -- Start with default config
        ManualSave.Config = deepCopy(DefaultConfig)
        
        -- Merge loaded config (preserves new fields from updates)
        mergeTables(ManualSave.Config, loadedConfig)
        
        print("✅ [ManualSave] Configuration loaded successfully!")
        print("📝 [ManualSave] Version:", ManualSave.Config.ConfigVersion)
        print("📝 [ManualSave] Last Saved:", ManualSave.Config.LastSaved)
    end)
    
    if success then
        return true, "Configuration loaded"
    else
        warn("❌ [ManualSave] Load failed:", err)
        ManualSave.Config = deepCopy(DefaultConfig)
        return false, "Load failed: " .. tostring(err)
    end
end

-- ============================================
-- RESET CONFIGURATION
-- ============================================

function ManualSave.ResetConfig()
    ManualSave.Config = deepCopy(DefaultConfig)
    print("🔄 [ManualSave] Configuration reset to defaults")
    return true, "Configuration reset"
end

function ManualSave.DeleteConfig()
    if not (delfile and isfile) then
        return false, "File operations not supported"
    end
    
    local filePath = getFilePath()
    
    if isfile(filePath) then
        local success, err = pcall(function()
            delfile(filePath)
        end)
        
        if success then
            ManualSave.Config = deepCopy(DefaultConfig)
            print("🗑️ [ManualSave] Configuration file deleted")
            return true, "Config deleted"
        else
            return false, "Delete failed: " .. tostring(err)
        end
    else
        return false, "No config file to delete"
    end
end

-- ============================================
-- CONFIGURATION GETTERS/SETTERS
-- ============================================

-- Get value from config path (e.g., "AutoFishing.InstantMode")
function ManualSave.GetValue(path)
    local keys = {}
    for key in path:gmatch("[^.]+") do
        table.insert(keys, key)
    end
    
    local value = ManualSave.Config
    for _, key in ipairs(keys) do
        if type(value) ~= "table" then
            return nil
        end
        value = value[key]
    end
    
    return value
end

-- Set value in config path
function ManualSave.SetValue(path, value)
    local keys = {}
    for key in path:gmatch("[^.]+") do
        table.insert(keys, key)
    end
    
    local current = ManualSave.Config
    for i = 1, #keys - 1 do
        local key = keys[i]
        if type(current[key]) ~= "table" then
            current[key] = {}
        end
        current = current[key]
    end
    
    current[keys[#keys]] = value
end

-- ============================================
-- AUTO-SAVE SYSTEM
-- ============================================

local autoSaveConnection

function ManualSave.EnableAutoSave(interval)
    interval = interval or CONFIG.AUTO_SAVE_INTERVAL
    
    if autoSaveConnection then
        autoSaveConnection:Disconnect()
    end
    
    CONFIG.AUTO_SAVE = true
    
    local lastSave = tick()
    autoSaveConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if tick() - lastSave >= interval then
            ManualSave.SaveConfig()
            lastSave = tick()
            print("💾 [ManualSave] Auto-saved (interval: " .. interval .. "s)")
        end
    end)
    
    print("⏰ [ManualSave] Auto-save enabled (every " .. interval .. " seconds)")
end

function ManualSave.DisableAutoSave()
    CONFIG.AUTO_SAVE = false
    
    if autoSaveConnection then
        autoSaveConnection:Disconnect()
        autoSaveConnection = nil
    end
    
    print("⏰ [ManualSave] Auto-save disabled")
end

-- ============================================
-- EXPORT/IMPORT CONFIGURATION
-- ============================================

function ManualSave.ExportToClipboard()
    if not setclipboard then
        return false, "Clipboard not supported"
    end
    
    local success, err = pcall(function()
        local jsonData = HttpService:JSONEncode(ManualSave.Config)
        setclipboard(jsonData)
    end)
    
    if success then
        return true, "Configuration copied to clipboard"
    else
        return false, "Export failed: " .. tostring(err)
    end
end

function ManualSave.ImportFromClipboard()
    if not getclipboard then
        return false, "Clipboard not supported"
    end
    
    local success, err = pcall(function()
        local jsonData = getclipboard()
        local importedConfig = HttpService:JSONDecode(jsonData)
        
        ManualSave.Config = deepCopy(DefaultConfig)
        mergeTables(ManualSave.Config, importedConfig)
    end)
    
    if success then
        return true, "Configuration imported from clipboard"
    else
        return false, "Import failed: " .. tostring(err)
    end
end

-- ============================================
-- DEBUG & INFO
-- ============================================

function ManualSave.PrintConfig()
    print("=".rep(50))
    print("📋 CURRENT CONFIGURATION")
    print("=".rep(50))
    print(HttpService:JSONEncode(ManualSave.Config))
    print("=".rep(50))
end

function ManualSave.GetInfo()
    local info = {
        ConfigVersion = ManualSave.Config.ConfigVersion,
        LastSaved = ManualSave.Config.LastSaved,
        FileLocation = getFilePath(),
        FolderExists = (isfolder and isfolder(CONFIG.FOLDER)) or false,
        FileExists = (isfile and isfile(getFilePath())) or false,
        AutoSaveEnabled = CONFIG.AUTO_SAVE,
        BackupEnabled = CONFIG.BACKUP_ENABLED
    }
    
    return info
end

-- ============================================
-- INITIALIZATION
-- ============================================

function ManualSave.Initialize()
    print("🚀 [ManualSave] Initializing...")
    
    -- Try to load existing config
    local success, message = ManualSave.LoadConfig()
    
    if not success then
        print("💡 [ManualSave] " .. message)
        print("💡 [ManualSave] Using default configuration")
    end
    
    print("✅ [ManualSave] Initialization complete")
    
    return ManualSave
end

-- ============================================
-- MODULE EXPORT
-- ============================================

return ManualSave
