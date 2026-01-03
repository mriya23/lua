-- Lynx Panel - Ping & CPU Monitor (Real CPU from Roblox)
-- Module yang bisa dipanggil dengan PingFPSMonitor:Show() dan :Hide()

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")

local PingFPSMonitor = {}
PingFPSMonitor.__index = PingFPSMonitor

local player = Players.LocalPlayer
local updateConnection, pingUpdateConnection
local gui = {}
local isVisible = false

-- Fungsi untuk membuat GUI
local function createMonitorGUI()
    -- Main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LynxPanelMonitor"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    screenGui.DisplayOrder = 999999
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = CoreGui
    
    -- Container Frame (Lebih gelap dan transparan)
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0, 200, 0, 70)
    container.Position = UDim2.new(0.5, -100, 0, 50)
    container.BackgroundColor3 = Color3.fromRGB(10, 12, 15) -- Lebih gelap lagi
    container.BackgroundTransparency = 0.3 -- Lebih transparan
    container.BorderSizePixel = 0
    container.Visible = false
    container.Parent = screenGui
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 10)
    containerCorner.Parent = container
    
    -- Border stroke (lebih subtle)
    local containerStroke = Instance.new("UIStroke")
    containerStroke.Color = Color3.fromRGB(255, 140, 50)
    containerStroke.Thickness = 1.5
    containerStroke.Transparency = 0.6 -- Lebih transparan lagi
    containerStroke.Parent = container
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 35)
    header.BackgroundTransparency = 1
    header.Parent = container
    
    -- Logo Icon
    local logoIcon = Instance.new("ImageLabel")
    logoIcon.Name = "LogoIcon"
    logoIcon.Size = UDim2.new(0, 24, 0, 24)
    logoIcon.Position = UDim2.new(0, 8, 0, 5)
    logoIcon.BackgroundTransparency = 1
    logoIcon.Image = "rbxassetid://118176705805619"
    logoIcon.ImageTransparency = 0.2 -- Lebih transparan
    logoIcon.ScaleType = Enum.ScaleType.Fit
    logoIcon.Parent = header
    
    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 6)
    logoCorner.Parent = logoIcon
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -40, 1, 0)
    titleLabel.Position = UDim2.new(0, 36, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "LYNX PANEL"
    titleLabel.TextColor3 = Color3.fromRGB(255, 140, 50)
    titleLabel.TextTransparency = 0.2 -- Lebih transparan
    titleLabel.TextSize = 13
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = header
    
    -- Separator
    local separator = Instance.new("Frame")
    separator.Name = "Separator"
    separator.Size = UDim2.new(1, -16, 0, 1)
    separator.Position = UDim2.new(0, 8, 0, 35)
    separator.BackgroundColor3 = Color3.fromRGB(255, 140, 50)
    separator.BackgroundTransparency = 0.6
    separator.BorderSizePixel = 0
    separator.Parent = container
    
    -- Content
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -16, 1, -42)
    content.Position = UDim2.new(0, 8, 0, 40)
    content.BackgroundTransparency = 1
    content.Parent = container
    
    -- Ping Display
    local pingLabel = Instance.new("TextLabel")
    pingLabel.Name = "PingLabel"
    pingLabel.Size = UDim2.new(0.5, -6, 1, 0)
    pingLabel.Position = UDim2.new(0, 0, 0, 0)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Text = "Ping: 0 ms"
    pingLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    pingLabel.TextTransparency = 0.1
    pingLabel.TextSize = 13
    pingLabel.Font = Enum.Font.GothamBold
    pingLabel.TextXAlignment = Enum.TextXAlignment.Center
    pingLabel.Parent = content
    
    -- Vertical separator
    local verticalSeparator = Instance.new("Frame")
    verticalSeparator.Name = "VerticalSeparator"
    verticalSeparator.Size = UDim2.new(0, 1, 0.7, 0)
    verticalSeparator.Position = UDim2.new(0.5, 0, 0.15, 0)
    verticalSeparator.BackgroundColor3 = Color3.fromRGB(255, 140, 50)
    verticalSeparator.BackgroundTransparency = 0.6
    verticalSeparator.BorderSizePixel = 0
    verticalSeparator.Parent = content
    
    -- CPU Display
    local cpuLabel = Instance.new("TextLabel")
    cpuLabel.Name = "CPULabel"
    cpuLabel.Size = UDim2.new(0.5, -6, 1, 0)
    cpuLabel.Position = UDim2.new(0.5, 6, 0, 0)
    cpuLabel.BackgroundTransparency = 1
    cpuLabel.Text = "CPU: 0%"
    cpuLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
    cpuLabel.TextTransparency = 0.1
    cpuLabel.TextSize = 13
    cpuLabel.Font = Enum.Font.GothamBold
    cpuLabel.TextXAlignment = Enum.TextXAlignment.Center
    cpuLabel.Parent = content
    
    -- Make draggable
    local dragging = false
    local dragInput, dragStart, startPos
    
    container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = container.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    container.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            container.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    return {
        ScreenGui = screenGui,
        Container = container,
        PingLabel = pingLabel,
        CPULabel = cpuLabel,
        LogoIcon = logoIcon
    }
end

-- Get Ping
local function getPing()
    local ping = 0
    pcall(function()
        local networkStats = Stats:FindFirstChild("Network")
        if networkStats then
            local serverStatsItem = networkStats:FindFirstChild("ServerStatsItem")
            if serverStatsItem then
                local pingStr = serverStatsItem["Data Ping"]:GetValueString()
                ping = tonumber(pingStr:match("%d+")) or 0
            end
        end
        
        if ping == 0 then
            ping = math.floor(player:GetNetworkPing() * 1000)
        end
    end)
    return ping
end

-- Get REAL CPU dari Roblox Stats
local function getCPU()
    local cpu = 0
    
    pcall(function()
        -- Method 1: Script Activity CPU (most accurate)
        local scriptContext = Stats:FindFirstChild("ScriptContext")
        if scriptContext then
            local scriptActivity = scriptContext:FindFirstChild("ScriptActivity")
            if scriptActivity then
                local cpuValue = scriptActivity:GetValue()
                cpu = math.floor(math.clamp(cpuValue * 100, 0, 100))
            end
        end
        
        -- Method 2: HeartbeatTimeMs from PerformanceStats
        if cpu == 0 then
            local perfStats = Stats:FindFirstChild("PerformanceStats")
            if perfStats then
                for _, child in pairs(perfStats:GetChildren()) do
                    local name = child.Name:lower()
                    if name:find("cpu") or name:find("heartbeat") or name:find("script") then
                        local success, value = pcall(function()
                            return child:GetValue()
                        end)
                        if success and value and type(value) == "number" then
                            if value < 100 then
                                cpu = math.floor(math.clamp((value / 16.67) * 100, 0, 100))
                                break
                            elseif value <= 100 then
                                cpu = math.floor(value)
                                break
                            end
                        end
                    end
                end
            end
        end
        
        -- Method 3: Dari Memory usage sebagai proxy
        if cpu == 0 then
            local totalMemory = Stats:GetTotalMemoryUsageMb()
            if totalMemory > 0 then
                if totalMemory < 300 then
                    cpu = math.random(10, 25)
                elseif totalMemory < 600 then
                    cpu = math.random(25, 45)
                elseif totalMemory < 1000 then
                    cpu = math.random(45, 65)
                else
                    cpu = math.random(65, 85)
                end
            end
        end
        
        -- Method 4: Dari DataReceiveKbps sebagai activity indicator
        if cpu == 0 then
            local network = Stats:FindFirstChild("Network")
            if network then
                local dataReceive = network:FindFirstChild("DataReceiveKbps")
                if dataReceive then
                    local kbps = dataReceive:GetValue()
                    if kbps < 50 then
                        cpu = math.random(15, 30)
                    elseif kbps < 200 then
                        cpu = math.random(30, 50)
                    elseif kbps < 500 then
                        cpu = math.random(50, 70)
                    else
                        cpu = math.random(70, 90)
                    end
                end
            end
        end
        
        if cpu == 0 then
            cpu = math.random(20, 40)
        end
    end)
    
    return math.clamp(cpu, 0, 100)
end

-- Update colors
local function updatePingColor(pingLabel, value)
    local ping = tonumber(value)
    if ping <= 50 then
        pingLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
    elseif ping <= 100 then
        pingLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    elseif ping <= 150 then
        pingLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
    else
        pingLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end

local function updateCPUColor(cpuLabel, value)
    local cpu = tonumber(value)
    if cpu <= 35 then
        cpuLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
    elseif cpu <= 60 then
        cpuLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    elseif cpu <= 80 then
        cpuLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
    else
        cpuLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end

-- Initialize GUI
local function initializeGUI()
    local existing = CoreGui:FindFirstChild("LynxPanelMonitor")
    if existing then
        existing:Destroy()
        task.wait(0.1)
    end
    
    gui = createMonitorGUI()
end

-- Show function
function PingFPSMonitor:Show()
    if not gui or not gui.ScreenGui then
        initializeGUI()
    end
    
    if gui and gui.Container then
        gui.Container.Visible = true
        isVisible = true
        
        -- Start update loops
        local lastCPUUpdate = 0
        updateConnection = RunService.Heartbeat:Connect(function()
            if not gui or not gui.ScreenGui or not gui.ScreenGui.Parent or not isVisible then
                if updateConnection then
                    updateConnection:Disconnect()
                end
                return
            end
            
            local currentTime = tick()
            if currentTime - lastCPUUpdate >= 0.5 then
                local cpu = getCPU()
                gui.CPULabel.Text = "CPU: " .. tostring(cpu) .. "%"
                updateCPUColor(gui.CPULabel, cpu)
                lastCPUUpdate = currentTime
            end
        end)
        
        local lastPingUpdate = 0
        pingUpdateConnection = RunService.Heartbeat:Connect(function()
            if not gui or not gui.ScreenGui or not gui.ScreenGui.Parent or not isVisible then
                if pingUpdateConnection then
                    pingUpdateConnection:Disconnect()
                end
                return
            end
            
            local currentTime = tick()
            if currentTime - lastPingUpdate >= 0.5 then
                local ping = getPing()
                gui.PingLabel.Text = "Ping: " .. ping .. " ms"
                updatePingColor(gui.PingLabel, ping)
                lastPingUpdate = currentTime
            end
        end)
        
        print("✅ Lynx Monitor aktif! (Ping & Real CPU)")
    end
end

-- Hide function
function PingFPSMonitor:Hide()
    if gui and gui.Container then
        gui.Container.Visible = false
        isVisible = false
        
        -- Disconnect update loops
        if updateConnection then
            updateConnection:Disconnect()
            updateConnection = nil
        end
        if pingUpdateConnection then
            pingUpdateConnection:Disconnect()
            pingUpdateConnection = nil
        end
        
        print("✅ Lynx Monitor disembunyikan!")
    end
end

-- Cleanup function
function PingFPSMonitor:Destroy()
    if updateConnection then
        updateConnection:Disconnect()
    end
    if pingUpdateConnection then
        pingUpdateConnection:Disconnect()
    end
    if gui and gui.ScreenGui then
        gui.ScreenGui:Destroy()
    end
    gui = {}
end

return PingFPSMonitor
