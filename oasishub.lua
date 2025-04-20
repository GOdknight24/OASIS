--[[
    Oasis Ultimate Blade Ball Script by Bane
    Version 4.0.0 - Ultra Edition
]]

-- Anti-detection protection
if getgenv().OasisExecuted then return end
getgenv().OasisExecuted = true

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

-- Constants
local SCRIPT_VERSION = "4.0.0-Ultra"

-- Variables
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Remote events for parrying and clashing
local ParryButtonPress
local ClashButtonPress

-- Connection variables
local AutoParryConnection
local BallTrackerConnection
local VisualizerConnection
local InputConnection
local AutoSpamConnection
local SpeedBoostConnection
local AutoDodgeConnection
local HealthCheckConnection

-- Track all balls in the game
local ActiveBalls = {}

-- Function to deep copy a table
local function deepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepCopy(orig_key)] = deepCopy(orig_value)
        end
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Settings (Default values)
local Settings = {
    AutoParry = {
        Enabled = false,
        Distance = 20,
        PredictionMultiplier = 0.5,
        Cooldown = 0.5,
        LastParry = 0,
        PingAdjustment = true,
        SmartMode = true,
        HitboxExpander = true,
        HitboxSize = 1.2,
        AutoAim = true,
        TargetBallsOnly = true,
        IgnoreSlowBalls = false,
        SlowThreshold = 15,
        FlickMode = false,
        FlickDuration = 0.15
    },
    AutoClash = {
        Enabled = false,
        Distance = 10,
        SpeedThreshold = 120,
        Cooldown = 0.4,
        LastClash = 0,
        PriorityMode = "Speed"
    },
    AutoSpam = {
        Enabled = false,
        Interval = 0.1,
        PressKey = "F",
        Mode = "Parry",
        BurstMode = false,
        BurstCount = 3,
        BurstDelay = 0.05
    },
    AutoDodge = {
        Enabled = false,
        TriggerDistance = 15,
        DodgeMethod = "Jump",
        OnlyForDangerousBalls = true,
        Cooldown = 1.0,
        LastDodge = 0
    },
    MovementAdjuster = {
        Enabled = false,
        SpeedMultiplier = 1.5,
        JumpHeight = 1.2,
        AirControl = true
    },
    ExtendedReach = {
        Enabled = false,
        ReachMultiplier = 1.2,
        AffectParryOnly = true,
        AutoAdjust = true
    },
    AutoHeal = {
        Enabled = false,
        HealthThreshold = 30,
        UseServerItems = true,
        TryDodgeWhenLow = true
    },
    VisualCues = {
        Enabled = true,
        ParryColor = Color3.fromRGB(0, 255, 0),
        ClashColor = Color3.fromRGB(255, 165, 0),
        DodgeColor = Color3.fromRGB(0, 170, 255),
        Duration = 0.3,
        Style = "Ring",
        Size = 1.0
    },
    BallESP = {
        Enabled = true,
        ShowDistance = true,
        ShowSpeed = true,
        ShowTrajectory = true,
        RainbowMode = false,
        TextSize = 14,
        DisplayMode = "Always"
    },
    PlayerESP = {
        Enabled = false,
        ShowDistance = true,
        ShowHealth = true,
        TeamColors = true,
        TextSize = 14,
        BoxESP = true,
        TracerESP = false
    },
    BallPrediction = {
        Enabled = true,
        LineThickness = 0.2,
        LineColor = Color3.fromRGB(255, 255, 255),
        Transparency = 0.7,
        ShowImpactPoint = true,
        ShowCountdown = true,
        MaxDistance = 100
    },
    Performance = {
        ReduceParticles = false,
        OptimizeBallTracking = true,
        LowGraphicsMode = false,
        RenderDistance = 250
    },
    SafeMode = {
        Enabled = true,
        AntiCheatBypass = true,
        RandomizeTimings = true,
        MinimizeDetection = true
    },
    NoClip = {
        Enabled = false,
        KeyBind = "N",
        Speed = 50
    },
    InventorySpoofer = {
        Enabled = false,
        SpawnItems = true,
        ShowItemsToOthers = true
    },
    GuiTheme = "Dark",
    ShowBallInfo = false,
    GuiVisible = true,
    AnimationEnabled = true,
    KeyBinds = {
        ToggleGui = Enum.KeyCode.RightControl,
        QuickParry = Enum.KeyCode.E,
        QuickDodge = Enum.KeyCode.Q,
        ToggleAutoSpam = Enum.KeyCode.T,
        ToggleNoClip = Enum.KeyCode.N
    }
}

-- GUI Colors and Design Constants
local Themes = {
    Dark = {
        Background = Color3.fromRGB(25, 25, 30),
        CardBackground = Color3.fromRGB(35, 35, 40),
        PrimaryText = Color3.fromRGB(255, 255, 255),
        SecondaryText = Color3.fromRGB(180, 180, 180),
        Accent = Color3.fromRGB(131, 87, 255),
        Success = Color3.fromRGB(23, 224, 127),
        Warning = Color3.fromRGB(255, 165, 0),
        Danger = Color3.fromRGB(255, 59, 59),
        ToggleEnabled = Color3.fromRGB(131, 87, 255),
        ToggleDisabled = Color3.fromRGB(60, 60, 70),
        SliderBackground = Color3.fromRGB(60, 60, 70),
        SliderFill = Color3.fromRGB(131, 87, 255)
    },
    Light = {
        Background = Color3.fromRGB(240, 240, 245),
        CardBackground = Color3.fromRGB(250, 250, 255),
        PrimaryText = Color3.fromRGB(30, 30, 35),
        SecondaryText = Color3.fromRGB(100, 100, 110),
        Accent = Color3.fromRGB(100, 120, 255),
        Success = Color3.fromRGB(40, 200, 120),
        Warning = Color3.fromRGB(255, 150, 50),
        Danger = Color3.fromRGB(255, 80, 80),
        ToggleEnabled = Color3.fromRGB(100, 120, 255),
        ToggleDisabled = Color3.fromRGB(200, 200, 210),
        SliderBackground = Color3.fromRGB(200, 200, 210),
        SliderFill = Color3.fromRGB(100, 120, 255)
    },
    Neon = {
        Background = Color3.fromRGB(10, 10, 15),
        CardBackground = Color3.fromRGB(20, 20, 30),
        PrimaryText = Color3.fromRGB(240, 240, 255),
        SecondaryText = Color3.fromRGB(180, 180, 220),
        Accent = Color3.fromRGB(0, 200, 255),
        Success = Color3.fromRGB(0, 255, 170),
        Warning = Color3.fromRGB(255, 230, 0),
        Danger = Color3.fromRGB(255, 0, 100),
        ToggleEnabled = Color3.fromRGB(0, 200, 255),
        ToggleDisabled = Color3.fromRGB(40, 40, 60),
        SliderBackground = Color3.fromRGB(40, 40, 60),
        SliderFill = Color3.fromRGB(0, 200, 255)
    },
    Minimal = {
        Background = Color3.fromRGB(10, 10, 10),
        CardBackground = Color3.fromRGB(20, 20, 20),
        PrimaryText = Color3.fromRGB(255, 255, 255),
        SecondaryText = Color3.fromRGB(200, 200, 200),
        Accent = Color3.fromRGB(150, 150, 150),
        Success = Color3.fromRGB(130, 200, 130),
        Warning = Color3.fromRGB(200, 180, 120),
        Danger = Color3.fromRGB(200, 120, 120),
        ToggleEnabled = Color3.fromRGB(150, 150, 150),
        ToggleDisabled = Color3.fromRGB(70, 70, 70),
        SliderBackground = Color3.fromRGB(70, 70, 70),
        SliderFill = Color3.fromRGB(150, 150, 150)
    },
    Gaming = {
        Background = Color3.fromRGB(15, 15, 25),
        CardBackground = Color3.fromRGB(30, 30, 45),
        PrimaryText = Color3.fromRGB(220, 240, 255),
        SecondaryText = Color3.fromRGB(150, 170, 200),
        Accent = Color3.fromRGB(255, 0, 100),
        Success = Color3.fromRGB(0, 255, 140),
        Warning = Color3.fromRGB(255, 220, 0),
        Danger = Color3.fromRGB(255, 40, 40),
        ToggleEnabled = Color3.fromRGB(255, 0, 100),
        ToggleDisabled = Color3.fromRGB(50, 50, 80),
        SliderBackground = Color3.fromRGB(50, 50, 80),
        SliderFill = Color3.fromRGB(255, 0, 100)
    }
}

-- Current active theme
local Theme = Themes[Settings.GuiTheme]

-- Statistics tracking
local Stats = {
    ParryAttempts = 0,
    SuccessfulParries = 0,
    ClashAttempts = 0,
    SuccessfulClashes = 0,
    DodgeAttempts = 0,
    Kills = 0,
    GamesPlayed = 0,
    SessionStartTime = tick(),
    
    GetParryRate = function()
        if Stats.ParryAttempts == 0 then return 0 end
        return (Stats.SuccessfulParries / Stats.ParryAttempts) * 100
    end,
    
    GetSessionTime = function()
        local diff = tick() - Stats.SessionStartTime
        local hours = math.floor(diff / 3600)
        local minutes = math.floor((diff % 3600) / 60)
        local seconds = math.floor(diff % 60)
        return string.format("%02d:%02d:%02d", hours, minutes, seconds)
    end,
    
    Reset = function()
        Stats.ParryAttempts = 0
        Stats.SuccessfulParries = 0
        Stats.ClashAttempts = 0
        Stats.SuccessfulClashes = 0
        Stats.DodgeAttempts = 0
        Stats.SessionStartTime = tick()
    end
}

-- Function to find required game elements
local function getGameElements()
    local attempts = 0
    local maxAttempts = 10
    
    -- Try to find the remote events for parrying and clashing
    while attempts < maxAttempts do
        attempts = attempts + 1
        
        -- Look for parry remote
        if not ParryButtonPress then
            for _, v in pairs(ReplicatedStorage:GetDescendants()) do
                if v:IsA("RemoteEvent") and (v.Name:find("Parry") or v.Name:find("parry") or v.Name:find("ParryAttempt")) then
                    ParryButtonPress = v
                    print("Oasis: Found parry remote: " .. v.Name)
                    break
                end
            end
        end
        
        -- Look for clash remote
        if not ClashButtonPress then
            for _, v in pairs(ReplicatedStorage:GetDescendants()) do
                if v:IsA("RemoteEvent") and (v.Name:find("Clash") or v.Name:find("clash")) then
                    ClashButtonPress = v
                    print("Oasis: Found clash remote: " .. v.Name)
                    break
                end
            end
        end
        
        -- If we found what we need or reached max attempts, break the loop
        if (ParryButtonPress and ClashButtonPress) or attempts >= maxAttempts then
            break
        end
        
        -- Wait before trying again
        task.wait(0.5)
    end
    
    -- If we couldn't find the events, try alternative methods
    if not ParryButtonPress then
        for _, v in pairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") and string.len(v.Name) <= 12 then
                ParryButtonPress = v
                print("Oasis: Using fallback parry remote: " .. v.Name)
                break
            end
        end
    end
    
    -- If we still can't find them, notify the user
    if not ParryButtonPress then
        print("Oasis Error: Could not find parry remote event. Script may not function correctly.")
    end
    
    if not ClashButtonPress then
        print("Oasis Note: Could not find clash remote event. Using parry remote for clashing.")
        ClashButtonPress = ParryButtonPress
    end
end

-- Function to detect balls in the game
local function detectBalls()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and 
           (obj.Name:lower():find("ball") or 
            obj.Name:lower():find("bomb") or 
            obj.Name:lower():find("projectile")) then
            
            -- Only add if not already tracked
            if not ActiveBalls[obj] then
                ActiveBalls[obj] = {
                    LastPosition = obj.Position,
                    Velocity = Vector3.new(0, 0, 0),
                    Speed = 0,
                    Tracker = nil,
                    Prediction = nil,
                    IsTargetingMe = false,
                    LastUpdateTime = tick()
                }
                
                -- Create tracker for visualization if enabled
                if Settings.BallPrediction.Enabled then
                    createBallTracker(obj)
                end
                
                -- Create ESP for ball if enabled
                if Settings.BallESP.Enabled then
                    createBallESP(obj)
                end
                
                -- Track when ball is removed from workspace
                obj.AncestryChanged:Connect(function(_, parent)
                    if not parent or not parent:IsDescendantOf(workspace) then
                        if ActiveBalls[obj] then
                            if ActiveBalls[obj].Tracker then
                                ActiveBalls[obj].Tracker:Destroy()
                            end
                            if ActiveBalls[obj].Prediction then
                                ActiveBalls[obj].Prediction:Destroy()
                            end
                            if ActiveBalls[obj].ESP then
                                ActiveBalls[obj].ESP:Destroy()
                            end
                            ActiveBalls[obj] = nil
                        end
                    end
                end)
            end
        end
    end
end

-- Function to create a ball tracker visualization
local function createBallTracker(ball)
    if not Settings.BallPrediction.Enabled or not ActiveBalls[ball] then return end
    
    -- Remove existing tracker if any
    if ActiveBalls[ball].Tracker then
        ActiveBalls[ball].Tracker:Destroy()
    end
    
    -- Create tracker
    local tracker = Instance.new("Part")
    tracker.Name = "BallTracker"
    tracker.Anchored = true
    tracker.CanCollide = false
    tracker.Material = Enum.Material.Neon
    tracker.Size = Vector3.new(0.5, 0.5, 0.5)
    tracker.Shape = Enum.PartType.Ball
    tracker.Color = Settings.BallPrediction.LineColor
    tracker.Transparency = 0.5
    tracker.Parent = workspace
    
    -- Create prediction line
    local prediction = Instance.new("Part")
    prediction.Name = "BallPrediction"
    prediction.Anchored = true
    prediction.CanCollide = false
    prediction.Material = Enum.Material.Neon
    prediction.Size = Vector3.new(0.1, 0.1, 10) -- Will be resized based on velocity
    prediction.Color = Settings.BallPrediction.LineColor
    prediction.Transparency = Settings.BallPrediction.Transparency
    prediction.Parent = workspace
    
    ActiveBalls[ball].Tracker = tracker
    ActiveBalls[ball].Prediction = prediction
end

-- Function to create ESP for ball
local function createBallESP(ball)
    if not Settings.BallESP.Enabled or not ActiveBalls[ball] then return end
    
    -- Create BillboardGui for ESP
    local ballESP = Instance.new("BillboardGui")
    ballESP.Name = "BallESP"
    ballESP.AlwaysOnTop = true
    ballESP.Size = UDim2.new(0, 200, 0, 50)
    ballESP.StudsOffset = Vector3.new(0, 2, 0)
    ballESP.Parent = ball
    
    -- ESP Text
    local infoText = Instance.new("TextLabel")
    infoText.Name = "InfoText"
    infoText.Size = UDim2.new(1, 0, 1, 0)
    infoText.BackgroundTransparency = 1
    infoText.Text = "Ball"
    infoText.Font = Enum.Font.GothamBold
    infoText.TextSize = Settings.BallESP.TextSize
    infoText.TextColor3 = Color3.new(1, 1, 1)
    infoText.TextStrokeTransparency = 0
    infoText.TextStrokeColor3 = Color3.new(0, 0, 0)
    infoText.Parent = ballESP
    
    ActiveBalls[ball].ESP = ballESP
end

-- Function to update ball tracking and prediction
local function updateBallTracking()
    for ball, data in pairs(ActiveBalls) do
        if ball and ball:IsDescendantOf(workspace) then
            -- Calculate velocity and speed
            local currentPosition = ball.Position
            local timeDelta = tick() - data.LastUpdateTime
            if timeDelta > 0 then
                local velocity = (currentPosition - data.LastPosition) / timeDelta
                data.Velocity = velocity
                data.Speed = velocity.Magnitude
                data.LastPosition = currentPosition
                data.LastUpdateTime = tick()
                
                -- Determine if ball is targeting the local player
                local ballDirection = velocity.Unit
                local toPlayer = (HumanoidRootPart.Position - ball.Position).Unit
                local dotProduct = ballDirection:Dot(toPlayer)
                data.IsTargetingMe = dotProduct > 0.7
                
                -- Update tracker visualization if enabled
                if Settings.BallPrediction.Enabled and data.Tracker and data.Tracker.Parent and data.Prediction and data.Prediction.Parent then
                    data.Tracker.Position = currentPosition
                    
                    -- Only show prediction for fast-moving balls
                    if data.Speed > 15 then
                        local predictionLength = math.min(data.Speed * 0.3, 50) -- Limit length
                        data.Prediction.Size = Vector3.new(
                            Settings.BallPrediction.LineThickness,
                            Settings.BallPrediction.LineThickness,
                            predictionLength
                        )
                        
                        -- Position and orient prediction line
                        if data.Speed > 0.1 then -- Only when moving
                            local direction = velocity.Unit
                            data.Prediction.CFrame = CFrame.new(
                                currentPosition + direction * predictionLength/2,
                                currentPosition + direction * predictionLength
                            )
                        end
                        
                        data.Prediction.Transparency = Settings.BallPrediction.Transparency
                    else
                        data.Prediction.Transparency = 1 -- Hide when slow
                    end
                end
                
                -- Update Ball ESP
                if Settings.BallESP.Enabled and data.ESP then
                    local distance = (HumanoidRootPart.Position - currentPosition).Magnitude
                    local text = "Ball"
                    
                    if Settings.BallESP.ShowDistance then
                        text = text .. " | " .. math.floor(distance) .. " studs"
                    end
                    
                    if Settings.BallESP.ShowSpeed then
                        text = text .. " | " .. math.floor(data.Speed) .. " speed"
                    end
                    
                    if data.IsTargetingMe then
                        text = "⚠️ " .. text .. " ⚠️"
                    end
                    
                    data.ESP.InfoText.Text = text
                    
                    -- Rainbow mode for ball ESP
                    if Settings.BallESP.RainbowMode then
                        local hue = (tick() * 0.1) % 1
                        data.ESP.InfoText.TextColor3 = Color3.fromHSV(hue, 1, 1)
                    else
                        data.ESP.InfoText.TextColor3 = data.IsTargetingMe and Color3.new(1, 0.5, 0) or Color3.new(1, 1, 1)
                    end
                    
                    -- Display mode check
                    if Settings.BallESP.DisplayMode == "TargetOnly" then
                        data.ESP.Enabled = data.IsTargetingMe
                    elseif Settings.BallESP.DisplayMode == "CloseOnly" then
                        data.ESP.Enabled = distance < 50
                    else
                        data.ESP.Enabled = true
                    end
                end
            end
        else
            -- Ball no longer exists, remove tracker
            if data.Tracker then
                data.Tracker:Destroy()
            end
            if data.Prediction then
                data.Prediction:Destroy()
            end
            if data.ESP then
                data.ESP:Destroy()
            end
            ActiveBalls[ball] = nil
        end
    end
end

-- Function to check if we should auto parry a ball
local function shouldAutoParry(ball, ballData)
    if not Settings.AutoParry.Enabled or not ball or not ballData then 
        return false 
    end
    
    -- Check cooldown
    local currentTime = tick()
    if currentTime - Settings.AutoParry.LastParry < Settings.AutoParry.Cooldown then
        return false
    end
    
    -- Distance check
    local distance = (ball.Position - HumanoidRootPart.Position).Magnitude
    local effectiveDistance = Settings.AutoParry.Distance
    
    -- Apply hitbox expander if enabled
    if Settings.AutoParry.HitboxExpander then
        effectiveDistance = effectiveDistance * Settings.AutoParry.HitboxSize
    end
    
    if distance > effectiveDistance then
        return false
    end
    
    -- Check if ball is moving toward us
    local ballToChar = (HumanoidRootPart.Position - ball.Position).Unit
    local dotProduct = ballToChar:Dot(ballData.Velocity.Unit)
    
    -- Ball is coming toward us if dot product is positive
    local minDot = Settings.AutoParry.AutoAim and 0.4 or 0.6
    if dotProduct < minDot then
        return false
    end
    
    -- Speed check - ignore if it's too slow and the setting is enabled
    if Settings.AutoParry.IgnoreSlowBalls and ballData.Speed < Settings.AutoParry.SlowThreshold then
        return false
    end
    
    -- Calculate time to reach player
    local timeToReach = distance / math.max(ballData.Speed, 1)
    
    -- Add ping-based adjustment if enabled
    local pingAdjustment = 0
    if Settings.AutoParry.PingAdjustment then
        local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
        pingAdjustment = ping * 0.5 -- Adjust based on ping
    end
    
    -- Only parry if ball will reach soon based on prediction multiplier
    local targetTime = Settings.AutoParry.PredictionMultiplier + pingAdjustment
    
    -- Add randomization for anti-cheat bypass
    if Settings.SafeMode.RandomizeTimings then
        targetTime = targetTime + (math.random(-10, 10) / 100) -- Add ±0.1s randomness
    end
    
    return timeToReach < targetTime
end

-- Function to check if we should auto clash a ball
local function shouldAutoClash(ball, ballData)
    if not Settings.AutoClash.Enabled or not ball or not ballData then 
        return false 
    end
    
    -- Check cooldown
    local currentTime = tick()
    if currentTime - Settings.AutoClash.LastClash < Settings.AutoClash.Cooldown then
        return false
    end
    
    -- Check if ball is close enough
    local distance = (ball.Position - HumanoidRootPart.Position).Magnitude
    if distance > Settings.AutoClash.Distance then
        return false
    end
    
    -- Check if ball is moving toward us
    local ballToChar = (HumanoidRootPart.Position - ball.Position).Unit
    local dotProduct = ballToChar:Dot(ballData.Velocity.Unit)
    
    -- Ball is coming toward us if dot product is positive
    if dotProduct < 0.7 then -- Ball is not moving directly toward us
        return false
    end
    
    -- Check if ball is fast enough for clash
    return ballData.Speed > Settings.AutoClash.SpeedThreshold
end

-- Function to check if we should auto dodge a ball
local function shouldAutoDodge(ball, ballData)
    if not Settings.AutoDodge.Enabled or not ball or not ballData then
        return false 
    end
    
    -- Check cooldown
    local currentTime = tick()
    if currentTime - Settings.AutoDodge.LastDodge < Settings.AutoDodge.Cooldown then
        return false
    end
    
    -- Check if ball is close enough and coming toward us
    local distance = (ball.Position - HumanoidRootPart.Position).Magnitude
    if distance > Settings.AutoDodge.TriggerDistance then
        return false
    end
    
    -- Check if ball is coming toward us
    local ballToChar = (HumanoidRootPart.Position - ball.Position).Unit
    local dotProduct = ballToChar:Dot(ballData.Velocity.Unit)
    if dotProduct < 0.6 then
        return false
    end
    
    -- Check if it's a dangerous ball (if setting enabled)
    if Settings.AutoDodge.OnlyForDangerousBalls then
        local isDangerous = ball.Name:lower():find("special") or
                            ball.Name:lower():find("bomb") or
                            ballData.Speed > 160
        
        if not isDangerous then
            return false
        end
    end
    
    return true
end

-- Function to create visual effect for parry/clash
local function createVisualEffect(type)
    if not Settings.VisualCues.Enabled then return end
    
    local color = Theme.Success
    if type == "clash" then
        color = Theme.Warning
    elseif type == "dodge" then
        color = Theme.Accent
    end
    
    -- Create ring effect
    local ring = Instance.new("Part")
    ring.Name = "VisualEffect"
    ring.Shape = Enum.PartType.Cylinder
    ring.Orientation = Vector3.new(0, 0, 90)
    ring.Size = Vector3.new(0.3, 1, 1)
    ring.Material = Enum.Material.Neon
    ring.Color = color
    ring.Transparency = 0.3
    ring.Anchored = true
    ring.CanCollide = false
    ring.CFrame = HumanoidRootPart.CFrame
    ring.Parent = workspace
    
    -- Animation
    local tween = TweenService:Create(
        ring,
        TweenInfo.new(Settings.VisualCues.Duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = Vector3.new(0.3, 20 * Settings.VisualCues.Size, 20 * Settings.VisualCues.Size), Transparency = 1}
    )
    
    tween:Play()
    
    tween.Completed:Connect(function()
        ring:Destroy()
    end)
end

-- Function to apply auto dodge
local function applyAutoDodge()
    if not Settings.AutoDodge.Enabled then return end
    
    for ball, ballData in pairs(ActiveBalls) do
        if ball and ball:IsDescendantOf(workspace) then
            if shouldAutoDodge(ball, ballData) then
                Settings.AutoDodge.LastDodge = tick()
                
                if Settings.AutoDodge.DodgeMethod == "Jump" then
                    -- Simple jump dodge
                    Humanoid.Jump = true
                    Stats.DodgeAttempts = Stats.DodgeAttempts + 1
                    createVisualEffect("dodge")
                    
                elseif Settings.AutoDodge.DodgeMethod == "Sidestep" then
                    -- Dodge perpendicular to ball direction
                    local sideDirection = Vector3.new(ballData.Velocity.Z, 0, -ballData.Velocity.X).Unit
                    local moveDirection = sideDirection * 20
                    
                    -- Apply movement
                    HumanoidRootPart.Velocity = Vector3.new(moveDirection.X, HumanoidRootPart.Velocity.Y, moveDirection.Z)
                    Stats.DodgeAttempts = Stats.DodgeAttempts + 1
                    createVisualEffect("dodge")
                    
                else -- Smart dodge
                    -- Combine jump and sidestep based on ball height
                    local ballHeight = ball.Position.Y - HumanoidRootPart.Position.Y
                    
                    if ballHeight > 2 then
                        -- Ball is high, dodge down or side
                        local sideDirection = Vector3.new(ballData.Velocity.Z, 0, -ballData.Velocity.X).Unit
                        local moveDirection = sideDirection * 10
                        HumanoidRootPart.Velocity = Vector3.new(moveDirection.X, HumanoidRootPart.Velocity.Y, moveDirection.Z)
                    else
                        -- Ball is low, jump
                        Humanoid.Jump = true
                    end
                    Stats.DodgeAttempts = Stats.DodgeAttempts + 1
                    createVisualEffect("dodge")
                end
                
                print("Oasis: Auto dodge triggered!")
                return -- Only dodge one ball at a time
            end
        end
    end
end

-- Function to handle auto spam
local function startAutoSpam()
    if AutoSpamConnection then
        AutoSpamConnection:Disconnect()
        AutoSpamConnection = nil
    end
    
    if not Settings.AutoSpam.Enabled then return end
    
    print("Oasis: Auto spam started")
    
    AutoSpamConnection = RunService.Heartbeat:Connect(function()
        if Settings.AutoSpam.Enabled then
            if Settings.AutoSpam.BurstMode then
                -- Burst mode - click multiple times quickly, then wait
                for i = 1, Settings.AutoSpam.BurstCount do
                    if Settings.AutoSpam.Mode == "Parry" and ParryButtonPress then
                        ParryButtonPress:FireServer()
                    else
                        -- Simulate keypress for custom key
                        local keyCode = Enum.KeyCode[Settings.AutoSpam.PressKey] or Enum.KeyCode.F
                        VirtualUser:TypeKey(keyCode.Value)
                    end
                    task.wait(Settings.AutoSpam.BurstDelay)
                end
                task.wait(Settings.AutoSpam.Interval)
            else
                -- Normal mode - click at regular intervals
                if Settings.AutoSpam.Mode == "Parry" and ParryButtonPress then
                    ParryButtonPress:FireServer()
                else
                    -- Simulate keypress for custom key
                    local keyCode = Enum.KeyCode[Settings.AutoSpam.PressKey] or Enum.KeyCode.F
                    VirtualUser:TypeKey(keyCode.Value)
                end
                task.wait(Settings.AutoSpam.Interval)
            end
        end
    end)
end

-- Function to stop auto spam
local function stopAutoSpam()
    if AutoSpamConnection then
        AutoSpamConnection:Disconnect()
        AutoSpamConnection = nil
        print("Oasis: Auto spam stopped")
    end
end

-- Function to toggle auto spam
local function toggleAutoSpam()
    Settings.AutoSpam.Enabled = not Settings.AutoSpam.Enabled
    
    if Settings.AutoSpam.Enabled then
        startAutoSpam()
    else
        stopAutoSpam()
    end
    
    -- You could add a notification here if needed
    print("Oasis: Auto spam " .. (Settings.AutoSpam.Enabled and "enabled" or "disabled"))
end

-- Function to update auto parry and clash logic
local function updateAutoParryAndClash()
    for ball, ballData in pairs(ActiveBalls) do
        if ball and ball:IsDescendantOf(workspace) then
            -- Check for auto parry
            if shouldAutoParry(ball, ballData) then
                if ParryButtonPress then
                    Settings.AutoParry.LastParry = tick()
                    ParryButtonPress:FireServer()
                    createVisualEffect("parry")
                    Stats.ParryAttempts = Stats.ParryAttempts + 1
                    print("Oasis: Auto parry triggered!")
                    
                    -- Apply flick if enabled (temporary camera movement)
                    if Settings.AutoParry.FlickMode then
                        local camera = workspace.CurrentCamera
                        local originalCFrame = camera.CFrame
                        local lookAt = CFrame.lookAt(camera.CFrame.Position, ball.Position)
                        
                        -- Flick to ball
                        camera.CFrame = lookAt
                        
                        -- Return to original position after short delay
                        task.delay(Settings.AutoParry.FlickDuration, function()
                            camera.CFrame = originalCFrame
                        end)
                    end
                end
            -- Check for auto clash
            elseif shouldAutoClash(ball, ballData) then
                if ClashButtonPress then
                    Settings.AutoClash.LastClash = tick()
                    ClashButtonPress:FireServer()
                    createVisualEffect("clash")
                    Stats.ClashAttempts = Stats.ClashAttempts + 1
                    print("Oasis: Auto clash triggered!")
                end
            end
        end
    end
end

-- Function to enhance player movement
local function enhanceMovement()
    if not Settings.MovementAdjuster.Enabled then return end
    
    -- Set walk speed
    if Humanoid.WalkSpeed > 0 then
        Humanoid.WalkSpeed = 16 * Settings.MovementAdjuster.SpeedMultiplier
    end
    
    -- Set jump power/height if available
    if Humanoid:FindFirstProperty("JumpPower") then
        Humanoid.JumpPower = 50 * Settings.MovementAdjuster.JumpHeight
    elseif Humanoid:FindFirstProperty("JumpHeight") then
        Humanoid.JumpHeight = 7.2 * Settings.MovementAdjuster.JumpHeight
    end
    
    -- Enhanced air control
    if Settings.MovementAdjuster.AirControl and not Humanoid.FloorMaterial.Name == "Air" then
        local moveDir = Humanoid.MoveDirection
        if moveDir.Magnitude > 0 then
            -- Apply additional velocity in the move direction while in air
            HumanoidRootPart.Velocity = Vector3.new(
                HumanoidRootPart.Velocity.X + moveDir.X * 2,
                HumanoidRootPart.Velocity.Y,
                HumanoidRootPart.Velocity.Z + moveDir.Z * 2
            )
        end
    end
end

-- Function to handle no clip
local function toggleNoClip()
    Settings.NoClip.Enabled = not Settings.NoClip.Enabled
    
    if Settings.NoClip.Enabled then
        print("Oasis: NoClip enabled")
        
        if NoClipConnection then
            NoClipConnection:Disconnect()
        end
        
        NoClipConnection = RunService.Stepped:Connect(function()
            if Character and Settings.NoClip.Enabled then
                for _, part in pairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
                
                -- Move in camera direction when holding forward key
                local camera = workspace.CurrentCamera
                local moveDirection = Humanoid.MoveDirection
                
                if moveDirection.Magnitude > 0 then
                    local speed = Settings.NoClip.Speed
                    local direction = camera.CFrame.LookVector * moveDirection.Z + camera.CFrame.RightVector * moveDirection.X
                    
                    if direction.Magnitude > 0 then
                        direction = direction.Unit
                        HumanoidRootPart.CFrame = HumanoidRootPart.CFrame + direction * speed * RunService.Stepped:Wait()
                    end
                end
            end
        end)
    else
        print("Oasis: NoClip disabled")
        if NoClipConnection then
            NoClipConnection:Disconnect()
            NoClipConnection = nil
        end
    end
end

-- Function to check and heal player
local function checkAndHeal()
    if not Settings.AutoHeal.Enabled then return end
    
    -- Check if health is below threshold
    local healthPercent = (Humanoid.Health / Humanoid.MaxHealth) * 100
    if healthPercent > Settings.AutoHeal.HealthThreshold then return end
    
    -- Try to use healing items if available
    if Settings.AutoHeal.UseServerItems then
        -- Search for heal remote events or healing items in backpack
        for _, v in pairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") and 
               (v.Name:find("Heal") or v.Name:find("heal") or v.Name:find("Health")) then
                v:FireServer()
                return
            end
        end
        
        -- Check for healing tools in backpack
        for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") and 
               (tool.Name:find("Health") or tool.Name:find("Heal") or tool.Name:find("Med")) then
                Humanoid:EquipTool(tool)
                task.wait(0.1)
                tool:Activate()
                return
            end
        end
    end
    
    -- If no healing available and health is very low, try to dodge
    if Settings.AutoHeal.TryDodgeWhenLow and healthPercent < 15 then
        -- Activate more aggressive dodging
        local originalDodgeSetting = Settings.AutoDodge.Enabled
        Settings.AutoDodge.Enabled = true
        
        -- Reset after a short time
        task.delay(5, function()
            Settings.AutoDodge.Enabled = originalDodgeSetting
        end)
    end
end

-- Function to create a separator line in GUI
local function createSeparator(parent, yPos)
    local separator = Instance.new("Frame")
    separator.Name = "Separator"
    separator.Size = UDim2.new(1, -30, 0, 1)
    separator.Position = UDim2.new(0, 15, 0, yPos)
    separator.BackgroundColor3 = Theme.SliderBackground
    separator.BorderSizePixel = 0
    separator.Parent = parent
    
    return separator
end

-- Function to create a section title in GUI
local function createSectionTitle(parent, title, yPos)
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = title .. "Title"
    titleLabel.Size = UDim2.new(1, -30, 0, 20)
    titleLabel.Position = UDim2.new(0, 15, 0, yPos)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextColor3 = Theme.Accent
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = parent
    
    return titleLabel
end

-- Function to create a toggle button in GUI
local function createToggle(parent, name, description, yPos, settingPath)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Name = name .. "Toggle"
    ToggleFrame.Size = UDim2.new(1, -30, 0, 60)
    ToggleFrame.Position = UDim2.new(0, 15, 0, yPos)
    ToggleFrame.BackgroundColor3 = Theme.CardBackground
    ToggleFrame.BackgroundTransparency = 0.3
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.Parent = parent
    
    local ToggleUICorner = Instance.new("UICorner")
    ToggleUICorner.CornerRadius = UDim.new(0, 8)
    ToggleUICorner.Parent = ToggleFrame
    
    local ToggleTitle = Instance.new("TextLabel")
    ToggleTitle.Name = "Title"
    ToggleTitle.Size = UDim2.new(1, -75, 0, 25)
    ToggleTitle.Position = UDim2.new(0, 15, 0, 8)
    ToggleTitle.BackgroundTransparency = 1
    ToggleTitle.Text = name
    ToggleTitle.Font = Enum.Font.GothamBold
    ToggleTitle.TextSize = 15
    ToggleTitle.TextColor3 = Theme.PrimaryText
    ToggleTitle.TextXAlignment = Enum.TextXAlignment.Left
    ToggleTitle.Parent = ToggleFrame
    
    local ToggleDescription = Instance.new("TextLabel")
    ToggleDescription.Name = "Description"
    ToggleDescription.Size = UDim2.new(1, -75, 0, 25)
    ToggleDescription.Position = UDim2.new(0, 15, 0, 28)
    ToggleDescription.BackgroundTransparency = 1
    ToggleDescription.Text = description
    ToggleDescription.Font = Enum.Font.Gotham
    ToggleDescription.TextSize = 13
    ToggleDescription.TextColor3 = Theme.SecondaryText
    ToggleDescription.TextXAlignment = Enum.TextXAlignment.Left
    ToggleDescription.TextWrapped = true
    ToggleDescription.Parent = ToggleFrame
    
    -- Toggle Button
    local ToggleButton = Instance.new("Frame")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Size = UDim2.new(0, 44, 0, 22)
    ToggleButton.Position = UDim2.new(1, -55, 0, 19)
    ToggleButton.BackgroundColor3 = Theme.ToggleDisabled
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Parent = ToggleFrame
    
    local ToggleButtonUICorner = Instance.new("UICorner")
    ToggleButtonUICorner.CornerRadius = UDim.new(1, 0)
    ToggleButtonUICorner.Parent = ToggleButton
    
    local ToggleCircle = Instance.new("Frame")
    ToggleCircle.Name = "ToggleCircle"
    ToggleCircle.Size = UDim2.new(0, 18, 0, 18)
    ToggleCircle.Position = UDim2.new(0, 2, 0.5, -9)
    ToggleCircle.BackgroundColor3 = Theme.PrimaryText
    ToggleCircle.BorderSizePixel = 0
    ToggleCircle.Parent = ToggleButton
    
    local ToggleCircleUICorner = Instance.new("UICorner")
    ToggleCircleUICorner.CornerRadius = UDim.new(1, 0)
    ToggleCircleUICorner.Parent = ToggleCircle
    
    -- Get the current state from settings
    local parts = settingPath:split(".")
    local currentSetting = Settings
    for _, part in ipairs(parts) do
        currentSetting = currentSetting[part]
    end
    
    -- Update toggle visuals based on current settings
    local function updateToggleVisual()
        parts = settingPath:split(".")
        currentSetting = Settings
        for _, part in ipairs(parts) do
            currentSetting = currentSetting[part]
        end
        
        if currentSetting then
            ToggleButton.BackgroundColor3 = Theme.ToggleEnabled
            ToggleCircle:TweenPosition(
                UDim2.new(0, 24, 0.5, -9),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.15,
                true
            )
        else
            ToggleButton.BackgroundColor3 = Theme.ToggleDisabled
            ToggleCircle:TweenPosition(
                UDim2.new(0, 2, 0.5, -9),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.15,
                true
            )
        end
    end
    
    updateToggleVisual()
    
    -- Make toggle clickable
    ToggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Toggle the setting
            parts = settingPath:split(".")
            local settingRef = Settings
            for i = 1, #parts - 1 do
                settingRef = settingRef[parts[i]]
            end
            settingRef[parts[#parts]] = not settingRef[parts[#parts]]
            
            -- Special handling for auto spam toggle
            if settingPath == "AutoSpam.Enabled" then
                if settingRef[parts[#parts]] then
                    startAutoSpam()
                else
                    stopAutoSpam()
                end
            elseif settingPath == "NoClip.Enabled" then
                toggleNoClip()
            end
            
            -- Update visual
            updateToggleVisual()
        end
    end)
    
    return ToggleFrame
end

-- Function to create a slider in GUI
local function createSlider(parent, name, description, yPos, settingPath, minValue, maxValue, increment)
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Name = name .. "Slider"
    SliderFrame.Size = UDim2.new(1, -30, 0, 80)
    SliderFrame.Position = UDim2.new(0, 15, 0, yPos)
    SliderFrame.BackgroundColor3 = Theme.CardBackground
    SliderFrame.BackgroundTransparency = 0.3
    SliderFrame.BorderSizePixel = 0
    SliderFrame.Parent = parent
    
    local SliderUICorner = Instance.new("UICorner")
    SliderUICorner.CornerRadius = UDim.new(0, 8)
    SliderUICorner.Parent = SliderFrame
    
    local SliderTitle = Instance.new("TextLabel")
    SliderTitle.Name = "Title"
    SliderTitle.Size = UDim2.new(1, -30, 0, 25)
    SliderTitle.Position = UDim2.new(0, 15, 0, 8)
    SliderTitle.BackgroundTransparency = 1
    SliderTitle.Text = name
    SliderTitle.Font = Enum.Font.GothamBold
    SliderTitle.TextSize = 15
    SliderTitle.TextColor3 = Theme.PrimaryText
    SliderTitle.TextXAlignment = Enum.TextXAlignment.Left
    SliderTitle.Parent = SliderFrame
    
    local SliderDescription = Instance.new("TextLabel")
    SliderDescription.Name = "Description"
    SliderDescription.Size = UDim2.new(1, -30, 0, 20)
    SliderDescription.Position = UDim2.new(0, 15, 0, 28)
    SliderDescription.BackgroundTransparency = 1
    SliderDescription.Text = description
    SliderDescription.Font = Enum.Font.Gotham
    SliderDescription.TextSize = 13
    SliderDescription.TextColor3 = Theme.SecondaryText
    SliderDescription.TextXAlignment = Enum.TextXAlignment.Left
    SliderDescription.TextWrapped = true
    SliderDescription.Parent = SliderFrame
    
    -- Value display
    local ValueDisplay = Instance.new("TextBox")
    ValueDisplay.Name = "ValueDisplay"
    ValueDisplay.Size = UDim2.new(0, 50, 0, 20)
    ValueDisplay.Position = UDim2.new(1, -65, 0, 15)
    ValueDisplay.BackgroundColor3 = Theme.Background
    ValueDisplay.BackgroundTransparency = 0.5
    ValueDisplay.BorderSizePixel = 0
    ValueDisplay.Font = Enum.Font.GothamSemibold
    ValueDisplay.TextSize = 14
    ValueDisplay.TextColor3 = Theme.PrimaryText
    ValueDisplay.TextXAlignment = Enum.TextXAlignment.Center
    ValueDisplay.Parent = SliderFrame
    
    local ValueDisplayUICorner = Instance.new("UICorner")
    ValueDisplayUICorner.CornerRadius = UDim.new(0, 4)
    ValueDisplayUICorner.Parent = ValueDisplay
    
    -- Slider track
    local SliderTrack = Instance.new("Frame")
    SliderTrack.Name = "SliderTrack"
    SliderTrack.Size = UDim2.new(1, -30, 0, 6)
    SliderTrack.Position = UDim2.new(0, 15, 0, 55)
    SliderTrack.BackgroundColor3 = Theme.SliderBackground
    SliderTrack.BorderSizePixel = 0
    SliderTrack.Parent = SliderFrame
    
    local SliderTrackUICorner = Instance.new("UICorner")
    SliderTrackUICorner.CornerRadius = UDim.new(1, 0)
    SliderTrackUICorner.Parent = SliderTrack
    
    -- Slider fill
    local SliderFill = Instance.new("Frame")
    SliderFill.Name = "SliderFill"
    SliderFill.Size = UDim2.new(0.5, 0, 1, 0) -- Will be set based on value
    SliderFill.Position = UDim2.new(0, 0, 0, 0)
    SliderFill.BackgroundColor3 = Theme.SliderFill
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderTrack
    
    local SliderFillUICorner = Instance.new("UICorner")
    SliderFillUICorner.CornerRadius = UDim.new(1, 0)
    SliderFillUICorner.Parent = SliderFill
    
    -- Slider handle
    local SliderHandle = Instance.new("Frame")
    SliderHandle.Name = "SliderHandle"
    SliderHandle.Size = UDim2.new(0, 16, 0, 16)
    SliderHandle.Position = UDim2.new(0.5, -8, 0.5, -8)
    SliderHandle.BackgroundColor3 = Theme.PrimaryText
    SliderHandle.BorderSizePixel = 0
    SliderHandle.ZIndex = 2
    SliderHandle.Parent = SliderTrack
    
    local SliderHandleUICorner = Instance.new("UICorner")
    SliderHandleUICorner.CornerRadius = UDim.new(1, 0)
    SliderHandleUICorner.Parent = SliderHandle
    
    -- Get the current value from settings
    local parts = settingPath:split(".")
    local currentSetting = Settings
    for _, part in ipairs(parts) do
        currentSetting = currentSetting[part]
    end
    
    -- Update slider visuals based on current value
    local function updateSliderVisual()
        local percentage = (currentSetting - minValue) / (maxValue - minValue)
        SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
        SliderHandle.Position = UDim2.new(percentage, -8, 0.5, -8)
        ValueDisplay.Text = tostring(math.floor(currentSetting * 100) / 100)
    end
    
    updateSliderVisual()
    
    -- Allow direct input via text box
    ValueDisplay.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local newValue = tonumber(ValueDisplay.Text)
            if newValue then
                newValue = math.clamp(newValue, minValue, maxValue)
                
                -- Update setting
                parts = settingPath:split(".")
                local settingRef = Settings
                for i = 1, #parts - 1 do
                    settingRef = settingRef[parts[i]]
                end
                settingRef[parts[#parts]] = newValue
                
                -- Update visual
                updateSliderVisual()
            else
                -- Revert to current value if input was invalid
                ValueDisplay.Text = tostring(math.floor(currentSetting * 100) / 100)
            end
        end
    end)
    
    -- Slider dragging functionality
    local isDragging = false
    
    SliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
        end
    end)
    
    SliderHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            -- Calculate the slider position based on mouse position
            local trackAbsolutePos = SliderTrack.AbsolutePosition
            local trackAbsoluteSize = SliderTrack.AbsoluteSize
            
            local relativeX = input.Position.X - trackAbsolutePos.X
            local percentage = math.clamp(relativeX / trackAbsoluteSize.X, 0, 1)
            
            -- Convert to actual value with correct increments
            local rawValue = minValue + percentage * (maxValue - minValue)
            local newValue = math.floor(rawValue / increment) * increment
            newValue = math.clamp(newValue, minValue, maxValue)
            
            -- Update setting
            parts = settingPath:split(".")
            local settingRef = Settings
            for i = 1, #parts - 1 do
                settingRef = settingRef[parts[i]]
            end
            settingRef[parts[#parts]] = newValue
            
            -- Update visual
            updateSliderVisual()
        end
    end)
    
    return SliderFrame
end

-- Function to create a dropdown menu in GUI
local function createDropdown(parent, name, description, yPos, settingPath, options)
    local DropdownFrame = Instance.new("Frame")
    DropdownFrame.Name = name .. "Dropdown"
    DropdownFrame.Size = UDim2.new(1, -30, 0, 70)
    DropdownFrame.Position = UDim2.new(0, 15, 0, yPos)
    DropdownFrame.BackgroundColor3 = Theme.CardBackground
    DropdownFrame.BackgroundTransparency = 0.3
    DropdownFrame.BorderSizePixel = 0
    DropdownFrame.Parent = parent
    
    local DropdownUICorner = Instance.new("UICorner")
    DropdownUICorner.CornerRadius = UDim.new(0, 8)
    DropdownUICorner.Parent = DropdownFrame
    
    local DropdownTitle = Instance.new("TextLabel")
    DropdownTitle.Name = "Title"
    DropdownTitle.Size = UDim2.new(1, -30, 0, 25)
    DropdownTitle.Position = UDim2.new(0, 15, 0, 8)
    DropdownTitle.BackgroundTransparency = 1
    DropdownTitle.Text = name
    DropdownTitle.Font = Enum.Font.GothamBold
    DropdownTitle.TextSize = 15
    DropdownTitle.TextColor3 = Theme.PrimaryText
    DropdownTitle.TextXAlignment = Enum.TextXAlignment.Left
    DropdownTitle.Parent = DropdownFrame
    
    local DropdownDescription = Instance.new("TextLabel")
    DropdownDescription.Name = "Description"
    DropdownDescription.Size = UDim2.new(1, -30, 0, 20)
    DropdownDescription.Position = UDim2.new(0, 15, 0, 28)
    DropdownDescription.BackgroundTransparency = 1
    DropdownDescription.Text = description
    DropdownDescription.Font = Enum.Font.Gotham
    DropdownDescription.TextSize = 13
    DropdownDescription.TextColor3 = Theme.SecondaryText
    DropdownDescription.TextXAlignment = Enum.TextXAlignment.Left
    DropdownDescription.TextWrapped = true
    DropdownDescription.Parent = DropdownFrame
    
    -- Dropdown button
    local DropdownButton = Instance.new("TextButton")
    DropdownButton.Name = "DropdownButton"
    DropdownButton.Size = UDim2.new(0, 110, 0, 28)
    DropdownButton.Position = UDim2.new(1, -125, 0, 21)
    DropdownButton.BackgroundColor3 = Theme.Background
    DropdownButton.BackgroundTransparency = 0.5
    DropdownButton.BorderSizePixel = 0
    DropdownButton.Font = Enum.Font.GothamSemibold
    DropdownButton.TextSize = 14
    DropdownButton.TextColor3 = Theme.PrimaryText
    DropdownButton.TextXAlignment = Enum.TextXAlignment.Left
    DropdownButton.TextTruncate = Enum.TextTruncate.AtEnd
    DropdownButton.Parent = DropdownFrame
    
    local ButtonPadding = Instance.new("UIPadding")
    ButtonPadding.PaddingLeft = UDim.new(0, 8)
    ButtonPadding.Parent = DropdownButton
    
    local DropdownButtonUICorner = Instance.new("UICorner")
    DropdownButtonUICorner.CornerRadius = UDim.new(0, 6)
    DropdownButtonUICorner.Parent = DropdownButton
    
    -- Arrow icon
    local ArrowIcon = Instance.new("TextLabel")
    ArrowIcon.Name = "ArrowIcon"
    ArrowIcon.Size = UDim2.new(0, 20, 0, 20)
    ArrowIcon.Position = UDim2.new(1, -25, 0.5, -10)
    ArrowIcon.BackgroundTransparency = 1
    ArrowIcon.Text = "▼"
    ArrowIcon.Font = Enum.Font.GothamBold
    ArrowIcon.TextSize = 12
    ArrowIcon.TextColor3 = Theme.SecondaryText
    ArrowIcon.Parent = DropdownButton
    
    -- Options container
    local OptionsFrame = Instance.new("Frame")
    OptionsFrame.Name = "OptionsFrame"
    OptionsFrame.Size = UDim2.new(0, 110, 0, 0) -- Height will be set dynamically
    OptionsFrame.Position = UDim2.new(1, -125, 0, 50)
    OptionsFrame.BackgroundColor3 = Theme.Background
    OptionsFrame.BackgroundTransparency = 0.2
    OptionsFrame.BorderSizePixel = 0
    OptionsFrame.ClipsDescendants = true
    OptionsFrame.Visible = false
    OptionsFrame.ZIndex = 5
    OptionsFrame.Parent = DropdownFrame
    
    local OptionsFrameUICorner = Instance.new("UICorner")
    OptionsFrameUICorner.CornerRadius = UDim.new(0, 6)
    OptionsFrameUICorner.Parent = OptionsFrame
    
    -- Get the current value from settings
    local parts = settingPath:split(".")
    local currentSetting = Settings
    for _, part in ipairs(parts) do
        if currentSetting and type(currentSetting) == "table" then
            currentSetting = currentSetting[part]
        else
            currentSetting = nil
            break
        end
    end
    
    -- Handle case where setting might be nil
    if currentSetting == nil then
        if #options > 0 then
            currentSetting = options[1]
            
            -- Update setting with default
            local settingRef = Settings
            for i = 1, #parts - 1 do
                settingRef = settingRef[parts[i]]
            end
            settingRef[parts[#parts]] = currentSetting
        else
            currentSetting = "Default"
        end
    end
    
    -- Update dropdown button text
    DropdownButton.Text = tostring(currentSetting)
    
    -- Create option buttons
    local optionHeight = 30
    OptionsFrame.Size = UDim2.new(0, 110, 0, optionHeight * #options)
    
    for i, optionValue in ipairs(options) do
        local OptionButton = Instance.new("TextButton")
        OptionButton.Name = "Option_" .. optionValue
        OptionButton.Size = UDim2.new(1, 0, 0, optionHeight)
        OptionButton.Position = UDim2.new(0, 0, 0, (i-1) * optionHeight)
        OptionButton.BackgroundTransparency = 1
        OptionButton.Text = optionValue
        OptionButton.Font = Enum.Font.GothamSemibold
        OptionButton.TextSize = 14
        OptionButton.TextColor3 = Theme.PrimaryText
        OptionButton.ZIndex = 6
        OptionButton.Parent = OptionsFrame
        
        -- Highlight current option
        if tostring(optionValue) == tostring(currentSetting) then
            OptionButton.TextColor3 = Theme.Accent
        end
        
        -- Option selection logic
        OptionButton.MouseButton1Click:Connect(function()
            -- Update setting
            parts = settingPath:split(".")
            local settingRef = Settings
            for i = 1, #parts - 1 do
                settingRef = settingRef[parts[i]]
            end
            settingRef[parts[#parts]] = optionValue
            
            -- Update theme if theme setting changed
            if settingPath == "GuiTheme" then
                Theme = Themes[optionValue] or Themes.Dark
                -- Would need to refresh UI if implementing full theme change
            end
            
            -- Update dropdown button text
            DropdownButton.Text = tostring(optionValue)
            
            -- Hide options
            OptionsFrame.Visible = false
            ArrowIcon.Text = "▼"
        end)
    end
    
    -- Toggle dropdown options visibility
    DropdownButton.MouseButton1Click:Connect(function()
        OptionsFrame.Visible = not OptionsFrame.Visible
        ArrowIcon.Text = OptionsFrame.Visible and "▲" or "▼"
    end)
    
    -- Close dropdown when clicking elsewhere
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UserInputService:GetMouseLocation()
            local dropdownFrame = DropdownFrame.AbsolutePosition
            local dropdownSize = DropdownFrame.AbsoluteSize
            local optionsFrame = OptionsFrame.AbsolutePosition
            local optionsSize = OptionsFrame.AbsoluteSize
            
            local inDropdown = mousePos.X >= dropdownFrame.X and mousePos.X <= dropdownFrame.X + dropdownSize.X and
                              mousePos.Y >= dropdownFrame.Y and mousePos.Y <= dropdownFrame.Y + dropdownSize.Y
            
            local inOptions = OptionsFrame.Visible and
                             mousePos.X >= optionsFrame.X and mousePos.X <= optionsFrame.X + optionsSize.X and
                             mousePos.Y >= optionsFrame.Y and mousePos.Y <= optionsFrame.Y + optionsSize.Y
            
            if OptionsFrame.Visible and not inDropdown and not inOptions then
                OptionsFrame.Visible = false
                ArrowIcon.Text = "▼"
            end
        end
    end)
    
    return DropdownFrame
end

-- Function to create key input in GUI
local function createKeyInput(parent, name, description, yPos, settingPath)
    local KeyInputFrame = Instance.new("Frame")
    KeyInputFrame.Name = name .. "KeyInput"
    KeyInputFrame.Size = UDim2.new(1, -30, 0, 70)
    KeyInputFrame.Position = UDim2.new(0, 15, 0, yPos)
    KeyInputFrame.BackgroundColor3 = Theme.CardBackground
    KeyInputFrame.BackgroundTransparency = 0.3
    KeyInputFrame.BorderSizePixel = 0
    KeyInputFrame.Parent = parent
    
    local KeyInputUICorner = Instance.new("UICorner")
    KeyInputUICorner.CornerRadius = UDim.new(0, 8)
    KeyInputUICorner.Parent = KeyInputFrame
    
    local KeyInputTitle = Instance.new("TextLabel")
    KeyInputTitle.Name = "Title"
    KeyInputTitle.Size = UDim2.new(1, -30, 0, 25)
    KeyInputTitle.Position = UDim2.new(0, 15, 0, 8)
    KeyInputTitle.BackgroundTransparency = 1
    KeyInputTitle.Text = name
    KeyInputTitle.Font = Enum.Font.GothamBold
    KeyInputTitle.TextSize = 15
    KeyInputTitle.TextColor3 = Theme.PrimaryText
    KeyInputTitle.TextXAlignment = Enum.TextXAlignment.Left
    KeyInputTitle.Parent = KeyInputFrame
    
    local KeyInputDescription = Instance.new("TextLabel")
    KeyInputDescription.Name = "Description"
    KeyInputDescription.Size = UDim2.new(1, -30, 0, 20)
    KeyInputDescription.Position = UDim2.new(0, 15, 0, 28)
    KeyInputDescription.BackgroundTransparency = 1
    KeyInputDescription.Text = description
    KeyInputDescription.Font = Enum.Font.Gotham
    KeyInputDescription.TextSize = 13
    KeyInputDescription.TextColor3 = Theme.SecondaryText
    KeyInputDescription.TextXAlignment = Enum.TextXAlignment.Left
    KeyInputDescription.TextWrapped = true
    KeyInputDescription.Parent = KeyInputFrame
    
    -- Key button
    local KeyButton = Instance.new("TextButton")
    KeyButton.Name = "KeyButton"
    KeyButton.Size = UDim2.new(0, 110, 0, 28)
    KeyButton.Position = UDim2.new(1, -125, 0, 21)
    KeyButton.BackgroundColor3 = Theme.Background
    KeyButton.BackgroundTransparency = 0.5
    KeyButton.BorderSizePixel = 0
    KeyButton.Font = Enum.Font.GothamSemibold
    KeyButton.TextSize = 14
    KeyButton.TextColor3 = Theme.PrimaryText
    KeyButton.Parent = KeyInputFrame
    
    local KeyButtonUICorner = Instance.new("UICorner")
    KeyButtonUICorner.CornerRadius = UDim.new(0, 6)
    KeyButtonUICorner.Parent = KeyButton
    
    -- Get the current key from settings
    local parts = settingPath:split(".")
    local currentSetting = Settings
    for _, part in ipairs(parts) do
        currentSetting = currentSetting[part]
    end
    
    -- Update key button text
    local function updateKeyText()
        if typeof(currentSetting) == "EnumItem" then
            KeyButton.Text = currentSetting.Name
        elseif typeof(currentSetting) == "string" then
            KeyButton.Text = currentSetting
        else
            KeyButton.Text = "NONE"
        end
    end
    
    updateKeyText()
    
    -- Key input handling
    local listeningForKey = false
    
    KeyButton.MouseButton1Click:Connect(function()
        if listeningForKey then return end
        
        listeningForKey = true
        KeyButton.Text = "Press Key..."
        KeyButton.TextColor3 = Theme.Accent
        
        local connection = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                -- Update setting
                parts = settingPath:split(".")
                local settingRef = Settings
                for i = 1, #parts - 1 do
                    settingRef = settingRef[parts[i]]
                end
                
                if settingPath:find("KeyBinds") then
                    settingRef[parts[#parts]] = input.KeyCode
                else
                    settingRef[parts[#parts]] = input.KeyCode.Name
                end
                
                -- Update visuals
                listeningForKey = false
                KeyButton.TextColor3 = Theme.PrimaryText
                updateKeyText()
                
                -- Special handling for auto spam keybind
                if settingPath == "AutoSpam.PressKey" then
                    -- Auto restart if enabled
                    if Settings.AutoSpam.Enabled then
                        stopAutoSpam()
                        startAutoSpam()
                    end
                end
                
                connection:Disconnect()
            end
        end)
    end)
    
    return KeyInputFrame
end

-- Function to create a stats display
local function createStatsDisplay(parent, yPos)
    local StatsFrame = Instance.new("Frame")
    StatsFrame.Name = "StatsDisplay"
    StatsFrame.Size = UDim2.new(1, -30, 0, 120)
    StatsFrame.Position = UDim2.new(0, 15, 0, yPos)
    StatsFrame.BackgroundColor3 = Theme.CardBackground
    StatsFrame.BackgroundTransparency = 0.3
    StatsFrame.BorderSizePixel = 0
    StatsFrame.Parent = parent
    
    local StatsUICorner = Instance.new("UICorner")
    StatsUICorner.CornerRadius = UDim.new(0, 8)
    StatsUICorner.Parent = StatsFrame
    
    -- Title
    local StatsTitle = Instance.new("TextLabel")
    StatsTitle.Name = "Title"
    StatsTitle.Size = UDim2.new(1, -20, 0, 25)
    StatsTitle.Position = UDim2.new(0, 10, 0, 5)
    StatsTitle.BackgroundTransparency = 1
    StatsTitle.Text = "Session Statistics"
    StatsTitle.Font = Enum.Font.GothamBold
    StatsTitle.TextSize = 16
    StatsTitle.TextColor3 = Theme.PrimaryText
    StatsTitle.TextXAlignment = Enum.TextXAlignment.Left
    StatsTitle.Parent = StatsFrame
    
    -- Session time
    local TimeLabel = Instance.new("TextLabel")
    TimeLabel.Name = "TimeLabel"
    TimeLabel.Size = UDim2.new(0.5, -20, 0, 20)
    TimeLabel.Position = UDim2.new(0, 10, 0, 35)
    TimeLabel.BackgroundTransparency = 1
    TimeLabel.Text = "Session Time:"
    TimeLabel.Font = Enum.Font.Gotham
    TimeLabel.TextSize = 14
    TimeLabel.TextColor3 = Theme.SecondaryText
    TimeLabel.TextXAlignment = Enum.TextXAlignment.Left
    TimeLabel.Parent = StatsFrame
    
    local TimeValue = Instance.new("TextLabel")
    TimeValue.Name = "TimeValue"
    TimeValue.Size = UDim2.new(0.5, -10, 0, 20)
    TimeValue.Position = UDim2.new(0.5, 0, 0, 35)
    TimeValue.BackgroundTransparency = 1
    TimeValue.Text = "00:00:00"
    TimeValue.Font = Enum.Font.GothamSemibold
    TimeValue.TextSize = 14
    TimeValue.TextColor3 = Theme.PrimaryText
    TimeValue.TextXAlignment = Enum.TextXAlignment.Left
    TimeValue.Parent = StatsFrame
    
    -- Parry success rate
    local RateLabel = Instance.new("TextLabel")
    RateLabel.Name = "RateLabel"
    RateLabel.Size = UDim2.new(0.5, -20, 0, 20)
    RateLabel.Position = UDim2.new(0, 10, 0, 55)
    RateLabel.BackgroundTransparency = 1
    RateLabel.Text = "Success Rate:"
    RateLabel.Font = Enum.Font.Gotham
    RateLabel.TextSize = 14
    RateLabel.TextColor3 = Theme.SecondaryText
    RateLabel.TextXAlignment = Enum.TextXAlignment.Left
    RateLabel.Parent = StatsFrame
    
    local RateValue = Instance.new("TextLabel")
    RateValue.Name = "RateValue"
    RateValue.Size = UDim2.new(0.5, -10, 0, 20)
    RateValue.Position = UDim2.new(0.5, 0, 0, 55)
    RateValue.BackgroundTransparency = 1
    RateValue.Text = "0%"
    RateValue.Font = Enum.Font.GothamSemibold
    RateValue.TextSize = 14
    RateValue.TextColor3 = Theme.Success
    RateValue.TextXAlignment = Enum.TextXAlignment.Left
    RateValue.Parent = StatsFrame
    
    -- Parry count
    local ParryLabel = Instance.new("TextLabel")
    ParryLabel.Name = "ParryLabel"
    ParryLabel.Size = UDim2.new(0.5, -20, 0, 20)
    ParryLabel.Position = UDim2.new(0, 10, 0, 75)
    ParryLabel.BackgroundTransparency = 1
    ParryLabel.Text = "Parry Count:"
    ParryLabel.Font = Enum.Font.Gotham
    ParryLabel.TextSize = 14
    ParryLabel.TextColor3 = Theme.SecondaryText
    ParryLabel.TextXAlignment = Enum.TextXAlignment.Left
    ParryLabel.Parent = StatsFrame
    
    local ParryValue = Instance.new("TextLabel")
    ParryValue.Name = "ParryValue"
    ParryValue.Size = UDim2.new(0.5, -10, 0, 20)
    ParryValue.Position = UDim2.new(0.5, 0, 0, 75)
    ParryValue.BackgroundTransparency = 1
    ParryValue.Text = "0"
    ParryValue.Font = Enum.Font.GothamSemibold
    ParryValue.TextSize = 14
    ParryValue.TextColor3 = Theme.PrimaryText
    ParryValue.TextXAlignment = Enum.TextXAlignment.Left
    ParryValue.Parent = StatsFrame
    
    -- Reset button
    local ResetButton = Instance.new("TextButton")
    ResetButton.Name = "ResetButton"
    ResetButton.Size = UDim2.new(0.4, 0, 0, 24)
    ResetButton.Position = UDim2.new(0.3, 0, 0, 95)
    ResetButton.BackgroundColor3 = Theme.Danger
    ResetButton.BackgroundTransparency = 0.3
    ResetButton.BorderSizePixel = 0
    ResetButton.Text = "Reset Stats"
    ResetButton.Font = Enum.Font.GothamSemibold
    ResetButton.TextSize = 14
    ResetButton.TextColor3 = Theme.PrimaryText
    ResetButton.Parent = StatsFrame
    
    local ResetButtonUICorner = Instance.new("UICorner")
    ResetButtonUICorner.CornerRadius = UDim.new(0, 6)
    ResetButtonUICorner.Parent = ResetButton
    
    -- Update stats display
    local function updateStats()
        TimeValue.Text = Stats.GetSessionTime()
        RateValue.Text = string.format("%.1f%%", Stats.GetParryRate())
        ParryValue.Text = tostring(Stats.SuccessfulParries) .. "/" .. tostring(Stats.ParryAttempts)
        
        -- Update color based on rate
        local rate = Stats.GetParryRate()
        if rate >= 75 then
            RateValue.TextColor3 = Theme.Success
        elseif rate >= 50 then
            RateValue.TextColor3 = Theme.Warning
        else
            RateValue.TextColor3 = Theme.Danger
        end
    end
    
    -- Reset button functionality
    ResetButton.MouseButton1Click:Connect(function()
        Stats.Reset()
        updateStats()
    end)
    
    -- Update stats periodically
    RunService.Heartbeat:Connect(function()
        if StatsFrame.Parent and StatsFrame.Parent.Visible then
            updateStats()
        end
    end)
    
    return StatsFrame
end

-- Function to create the GUI
local function createGui()
    -- Remove any existing GUI with the same name
    for _, v in pairs(game.CoreGui:GetChildren()) do
        if v.Name == "OasisBladeballGui" then
            v:Destroy()
        end
    end
    
    -- Create ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "OasisBladeballGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Use appropriate parent based on environment
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(ScreenGui)
            ScreenGui.Parent = game.CoreGui
        elseif gethui then
            ScreenGui.Parent = gethui()
        else
            ScreenGui.Parent = game.CoreGui
        end
    end)
    
    -- Create logo image
    local Logo = Instance.new("TextLabel")
    Logo.Name = "Logo"
    Logo.Size = UDim2.new(0, 100, 0, 100)
    Logo.Position = UDim2.new(0.5, -50, 0.5, -50)
    Logo.BackgroundTransparency = 1
    Logo.Text = "OASIS"
    Logo.TextColor3 = Theme.Accent
    Logo.TextSize = 42
    Logo.Font = Enum.Font.GothamBold
    Logo.Parent = ScreenGui
    
    -- Create logo text
    local LogoText = Instance.new("TextLabel")
    LogoText.Name = "LogoText"
    LogoText.Size = UDim2.new(0, 200, 0, 40)
    LogoText.Position = UDim2.new(0.5, -100, 0.5, 40)
    LogoText.BackgroundTransparency = 1
    LogoText.Text = "BLADE BALL"
    LogoText.Font = Enum.Font.GothamBold
    LogoText.TextSize = 24
    LogoText.TextColor3 = Theme.PrimaryText
    LogoText.Parent = ScreenGui
    
    -- Animate logo on start
    Logo.TextTransparency = 1
    LogoText.TextTransparency = 1
    
    TweenService:Create(Logo, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -50, 0.5, -70),
        TextTransparency = 0
    }):Play()
    
    TweenService:Create(LogoText, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        TextTransparency = 0
    }):Play()
    
    -- Wait and fade out logo after a delay
    task.spawn(function()
        task.wait(1.5)
        
        TweenService:Create(Logo, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            TextTransparency = 1
        }):Play()
        
        TweenService:Create(LogoText, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            TextTransparency = 1
        }):Play()
        
        task.wait(0.6)
        Logo:Destroy()
        LogoText:Destroy()
    end)
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 320, 0, 450)
    MainFrame.Position = UDim2.new(0.02, 0, 0.5, -225)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BackgroundTransparency = 0.1
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.ClipsDescendants = false -- For shadow
    MainFrame.Visible = false
    MainFrame.Parent = ScreenGui
    
    -- Add shadow effect
    local Shadow = Instance.new("Frame")
    Shadow.Name = "Shadow"
    Shadow.Size = UDim2.new(1, 40, 1, 40)
    Shadow.Position = UDim2.new(0, -20, 0, -20)
    Shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    Shadow.BackgroundTransparency = 0.6
    Shadow.BorderSizePixel = 0
    Shadow.ZIndex = -1
    Shadow.Parent = MainFrame
    
    local ShadowUICorner = Instance.new("UICorner")
    ShadowUICorner.CornerRadius = UDim.new(0, 16)
    ShadowUICorner.Parent = Shadow
    
    -- Apply rounded corners to main frame
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.Position = UDim2.new(0, 0, 0, 0)
    TitleBar.BackgroundColor3 = Theme.Accent
    TitleBar.BackgroundTransparency = 0.2
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local TitleBarUICorner = Instance.new("UICorner")
    TitleBarUICorner.CornerRadius = UDim.new(0, 8)
    TitleBarUICorner.Parent = TitleBar
    
    -- Create a frame to cover the bottom rounded corners of the title bar
    local CoverFrame = Instance.new("Frame")
    CoverFrame.Name = "CoverFrame"
    CoverFrame.Size = UDim2.new(1, 0, 0, 10)
    CoverFrame.Position = UDim2.new(0, 0, 1, -10)
    CoverFrame.BackgroundColor3 = Theme.Accent
    CoverFrame.BackgroundTransparency = 0.2
    CoverFrame.BorderSizePixel = 0
    CoverFrame.Parent = TitleBar
    
    -- Title Bar Logo
    local TitleLogo = Instance.new("TextLabel")
    TitleLogo.Name = "TitleLogo"
    TitleLogo.Size = UDim2.new(0, 24, 0, 24)
    TitleLogo.Position = UDim2.new(0, 12, 0.5, -12)
    TitleLogo.BackgroundTransparency = 1
    TitleLogo.Text = "O"
    TitleLogo.TextColor3 = Theme.PrimaryText
    TitleLogo.Font = Enum.Font.GothamBlack
    TitleLogo.TextSize = 18
    TitleLogo.Parent = TitleBar
    
    -- Title Text
    local TitleText = Instance.new("TextLabel")
    TitleText.Name = "TitleText"
    TitleText.Size = UDim2.new(1, -130, 1, 0)
    TitleText.Position = UDim2.new(0, 45, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = "Oasis Blade Ball"
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextSize = 18
    TitleText.TextColor3 = Theme.PrimaryText
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = TitleBar
    
    -- Developer Credit
    local DevCredit = Instance.new("TextLabel")
    DevCredit.Name = "DevCredit"
    DevCredit.Size = UDim2.new(0, 100, 0, 20)
    DevCredit.Position = UDim2.new(1, -115, 0.5, -10)
    DevCredit.BackgroundTransparency = 1
    DevCredit.Text = "by Bane"
    DevCredit.Font = Enum.Font.GothamSemibold
    DevCredit.TextSize = 14
    DevCredit.TextColor3 = Theme.PrimaryText
    DevCredit.TextXAlignment = Enum.TextXAlignment.Right
    DevCredit.Parent = TitleBar
    
    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -35, 0.5, -15)
    CloseButton.BackgroundTransparency = 1
    CloseButton.Text = "✕"
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 16
    CloseButton.TextColor3 = Theme.PrimaryText
    CloseButton.Parent = TitleBar
    
    CloseButton.MouseButton1Click:Connect(function()
        Settings.GuiVisible = false
        ScreenGui.Enabled = false
    end)
    
    -- Minimize Button
    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Name = "MinimizeButton"
    MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
    MinimizeButton.Position = UDim2.new(1, -65, 0.5, -15)
    MinimizeButton.BackgroundTransparency = 1
    MinimizeButton.Text = "−"
    MinimizeButton.Font = Enum.Font.GothamBold
    MinimizeButton.TextSize = 18
    MinimizeButton.TextColor3 = Theme.PrimaryText
    MinimizeButton.Parent = TitleBar
    
    local minimized = false
    local originalSize = MainFrame.Size
    
    MinimizeButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        if Settings.AnimationEnabled then
            if minimized then
                -- Minimize animation
                local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                local tween = TweenService:Create(MainFrame, tweenInfo, {Size = UDim2.new(0, 320, 0, 40)})
                tween:Play()
            else
                -- Restore animation
                local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                local tween = TweenService:Create(MainFrame, tweenInfo, {Size = originalSize})
                tween:Play()
            end
        else
            -- Instant size change if animations disabled
            MainFrame.Size = minimized and UDim2.new(0, 320, 0, 40) or originalSize
        end
    end)
    
    -- Tab buttons container
    local TabButtonsFrame = Instance.new("Frame")
    TabButtonsFrame.Name = "TabButtonsFrame"
    TabButtonsFrame.Size = UDim2.new(1, 0, 0, 40)
    TabButtonsFrame.Position = UDim2.new(0, 0, 0, 40)
    TabButtonsFrame.BackgroundColor3 = Theme.CardBackground
    TabButtonsFrame.BackgroundTransparency = 0.2
    TabButtonsFrame.BorderSizePixel = 0
    TabButtonsFrame.Parent = MainFrame
    
    -- Content Frame (contains the tab pages)
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, 0, 1, -80)
    ContentContainer.Position = UDim2.new(0, 0, 0, 80)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.BorderSizePixel = 0
    ContentContainer.Parent = MainFrame
    
    -- Create tab pages
    local tabPages = {}
    local tabButtons = {}
    local activeTab = "Main"
    
    -- Function to create a new tab
    local function createTab(tabName)
        -- Tab button
        local tabWidth = 1/5 -- Five tabs: Main, Combat, Visual, Extra, Settings
        
        local TabButton = Instance.new("TextButton")
        TabButton.Name = tabName .. "Button"
        TabButton.Size = UDim2.new(tabWidth, 0, 1, 0)
        TabButton.Position = UDim2.new(tabWidth * (#tabButtons), 0, 0, 0)
        TabButton.BackgroundTransparency = 1
        TabButton.Text = tabName
        TabButton.Font = Enum.Font.GothamSemibold
        TabButton.TextSize = 15
        TabButton.TextColor3 = Theme.SecondaryText
        TabButton.Parent = TabButtonsFrame
        
        -- Indicator for active tab
        local ActiveIndicator = Instance.new("Frame")
        ActiveIndicator.Name = "ActiveIndicator"
        ActiveIndicator.Size = UDim2.new(0.7, 0, 0, 3)
        ActiveIndicator.Position = UDim2.new(0.15, 0, 1, -3)
        ActiveIndicator.BackgroundColor3 = Theme.Accent
        ActiveIndicator.BorderSizePixel = 0
        ActiveIndicator.Visible = tabName == activeTab
        ActiveIndicator.Parent = TabButton
        
        -- Tab content scrolling frame
        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Name = tabName .. "Tab"
        TabPage.Size = UDim2.new(1, 0, 1, 0)
        TabPage.Position = UDim2.new(0, 0, 0, 0)
        TabPage.BackgroundTransparency = 1
        TabPage.BorderSizePixel = 0
        TabPage.ScrollBarThickness = 4
        TabPage.ScrollBarImageColor3 = Theme.Accent
        TabPage.Visible = tabName == activeTab
        TabPage.CanvasSize = UDim2.new(0, 0, 3, 0) -- Adjusted based on content
        TabPage.Parent = ContentContainer
        
        -- Tab switching functionality
        TabButton.MouseButton1Click:Connect(function()
            -- Update active tab
            activeTab = tabName
            
            -- Update tab button appearance
            for btnName, btn in pairs(tabButtons) do
                if btnName == tabName then
                    btn.TextColor3 = Theme.PrimaryText
                    btn.ActiveIndicator.Visible = true
                else
                    btn.TextColor3 = Theme.SecondaryText
                    btn.ActiveIndicator.Visible = false
                end
            end
            
            -- Show active tab page
            for pageName, page in pairs(tabPages) do
                page.Visible = pageName == tabName
            end
        end)
        
        -- Store references
        tabButtons[tabName] = {
            TextColor3 = TabButton.TextColor3,
            ActiveIndicator = ActiveIndicator
        }
        tabPages[tabName] = TabPage
        
        return TabPage
    end
    
    -- Create the tab pages
    local MainTab = createTab("Main")
    local CombatTab = createTab("Combat")
    local VisualTab = createTab("Visual")
    local ExtraTab = createTab("Extra")
    local SettingsTab = createTab("Settings")
    
    -- Populate Main Tab
    local mainYPos = 15
    createSectionTitle(MainTab, "Core Features", mainYPos)
    mainYPos += 30
    
    createToggle(MainTab, "Auto Parry", "Automatically parry incoming balls", mainYPos, "AutoParry.Enabled")
    mainYPos += 70
    
    createToggle(MainTab, "Auto Clash", "Automatically clash with fast balls", mainYPos, "AutoClash.Enabled")
    mainYPos += 70
    
    createToggle(MainTab, "Auto Dodge", "Automatically dodge dangerous balls", mainYPos, "AutoDodge.Enabled")
    mainYPos += 70
    
    createToggle(MainTab, "Auto Spam", "Rapidly spam parry or custom key", mainYPos, "AutoSpam.Enabled")
    mainYPos += 70
    
    createToggle(MainTab, "Auto Heal", "Automatically heal at low health", mainYPos, "AutoHeal.Enabled")
    mainYPos += 70
    
    createSeparator(MainTab, mainYPos)
    mainYPos += 15
    
    createSectionTitle(MainTab, "Statistics", mainYPos)
    mainYPos += 30
    
    createStatsDisplay(MainTab, mainYPos)
    mainYPos += 130
    
    -- Adjust canvas size based on content
    MainTab.CanvasSize = UDim2.new(0, 0, 0, mainYPos + 20)
    
    -- Populate Combat Tab
    local combatYPos = 15
    createSectionTitle(CombatTab, "Auto Parry Settings", combatYPos)
    combatYPos += 30
    
    createToggle(CombatTab, "Ping Adjustment", "Auto-adjust timing based on ping", combatYPos, "AutoParry.PingAdjustment")
    combatYPos += 70
    
    createSlider(CombatTab, "Parry Distance", "Maximum distance to trigger auto parry", combatYPos, "AutoParry.Distance", 5, 50, 1)
    combatYPos += 90
    
    createSlider(CombatTab, "Parry Timing", "Adjust parry timing (lower = earlier)", combatYPos, "AutoParry.PredictionMultiplier", 0.1, 1.0, 0.05)
    combatYPos += 90
    
    createToggle(CombatTab, "Hitbox Expander", "Increase parry detection range", combatYPos, "AutoParry.HitboxExpander")
    combatYPos += 70
    
    createSlider(CombatTab, "Hitbox Size", "Size multiplier for hitbox expansion", combatYPos, "AutoParry.HitboxSize", 1.0, 2.0, 0.1)
    combatYPos += 90
    
    createSeparator(CombatTab, combatYPos)
    combatYPos += 15
    
    createSectionTitle(CombatTab, "Spam Settings", combatYPos)
    combatYPos += 30
    
    createSlider(CombatTab, "Spam Interval", "Time between spam clicks (seconds)", combatYPos, "AutoSpam.Interval", 0.01, 0.5, 0.01)
    combatYPos += 90
    
    createKeyInput(CombatTab, "Spam Key", "Key to spam if using custom mode", combatYPos, "AutoSpam.PressKey")
    combatYPos += 80
    
    createDropdown(CombatTab, "Spam Mode", "What action to spam", combatYPos, "AutoSpam.Mode", {"Parry", "Custom"})
    combatYPos += 80
    
    createToggle(CombatTab, "Burst Mode", "Spam multiple times in quick succession", combatYPos, "AutoSpam.BurstMode")
    combatYPos += 70
    
    -- Adjust canvas size based on content
    CombatTab.CanvasSize = UDim2.new(0, 0, 0, combatYPos + 20)
    
    -- Populate Visual Tab
    local visualYPos = 15
    createSectionTitle(VisualTab, "Ball ESP", visualYPos)
    visualYPos += 30
    
    createToggle(VisualTab, "Ball ESP", "Show information about balls", visualYPos, "BallESP.Enabled")
    visualYPos += 70
    
    createToggle(VisualTab, "Show Distance", "Display distance to each ball", visualYPos, "BallESP.ShowDistance")
    visualYPos += 70
    
    createToggle(VisualTab, "Show Speed", "Display speed of each ball", visualYPos, "BallESP.ShowSpeed")
    visualYPos += 70
    
    createToggle(VisualTab, "Rainbow Mode", "Cycle through colors for ESP text", visualYPos, "BallESP.RainbowMode")
    visualYPos += 70
    
    createDropdown(VisualTab, "Display Mode", "When to show ESP", visualYPos, "BallESP.DisplayMode", {"Always", "TargetOnly", "CloseOnly"})
    visualYPos += 80
    
    createSeparator(VisualTab, visualYPos)
    visualYPos += 15
    
    createSectionTitle(VisualTab, "Ball Prediction", visualYPos)
    visualYPos += 30
    
    createToggle(VisualTab, "Ball Prediction", "Show ball trajectory predictions", visualYPos, "BallPrediction.Enabled")
    visualYPos += 70
    
    createSlider(VisualTab, "Line Thickness", "Adjust prediction line thickness", visualYPos, "BallPrediction.LineThickness", 0.1, 1.0, 0.05)
    visualYPos += 90
    
    createToggle(VisualTab, "Impact Point", "Show where ball will hit", visualYPos, "BallPrediction.ShowImpactPoint")
    visualYPos += 70
    
    -- Adjust canvas size based on content
    VisualTab.CanvasSize = UDim2.new(0, 0, 0, visualYPos + 20)
    
    -- Populate Extra Tab
    local extraYPos = 15
    createSectionTitle(ExtraTab, "Movement", extraYPos)
    extraYPos += 30
    
    createToggle(ExtraTab, "Enhanced Movement", "Improve speed and jump height", extraYPos, "MovementAdjuster.Enabled")
    extraYPos += 70
    
    createSlider(ExtraTab, "Speed Multiplier", "Adjust movement speed", extraYPos, "MovementAdjuster.SpeedMultiplier", 1.0, 2.0, 0.1)
    extraYPos += 90
    
    createSlider(ExtraTab, "Jump Height", "Adjust jump height multiplier", extraYPos, "MovementAdjuster.JumpHeight", 1.0, 2.0, 0.1)
    extraYPos += 90
    
    createToggle(ExtraTab, "Air Control", "Better control while in air", extraYPos, "MovementAdjuster.AirControl")
    extraYPos += 70
    
    createSeparator(ExtraTab, extraYPos)
    extraYPos += 15
    
    createSectionTitle(ExtraTab, "Utilities", extraYPos)
    extraYPos += 30
    
    createToggle(ExtraTab, "NoClip", "Walk through walls and objects", extraYPos, "NoClip.Enabled")
    extraYPos += 70
    
    createSlider(ExtraTab, "NoClip Speed", "Movement speed while noclipping", extraYPos, "NoClip.Speed", 20, 100, 5)
    extraYPos += 90
    
    createKeyInput(ExtraTab, "NoClip Key", "Toggle noclip on/off", extraYPos, "KeyBinds.ToggleNoClip")
    extraYPos += 80
    
    -- Adjust canvas size based on content
    ExtraTab.CanvasSize = UDim2.new(0, 0, 0, extraYPos + 20)
    
    -- Populate Settings Tab
    local settingsYPos = 15
    createSectionTitle(SettingsTab, "Interface", settingsYPos)
    settingsYPos += 30
    
    createToggle(SettingsTab, "GUI Animations", "Enable smooth GUI animations", settingsYPos, "AnimationEnabled")
    settingsYPos += 70
    
    createDropdown(SettingsTab, "GUI Theme", "Change the interface appearance", settingsYPos, "GuiTheme", {"Dark", "Light", "Neon", "Minimal", "Gaming"})
    settingsYPos += 80
    
    createSeparator(SettingsTab, settingsYPos)
    settingsYPos += 15
    
    createSectionTitle(SettingsTab, "Performance", settingsYPos)
    settingsYPos += 30
    
    createToggle(SettingsTab, "Optimize Tracking", "Reduce ball tracking calculations", settingsYPos, "Performance.OptimizeBallTracking")
    settingsYPos += 70
    
    createToggle(SettingsTab, "Low Graphics", "Disable visual effects for performance", settingsYPos, "Performance.LowGraphicsMode")
    settingsYPos += 70
    
    createSeparator(SettingsTab, settingsYPos)
    settingsYPos += 15
    
    createSectionTitle(SettingsTab, "Security", settingsYPos)
    settingsYPos += 30
    
    createToggle(SettingsTab, "Safe Mode", "Minimize detection risk", settingsYPos, "SafeMode.Enabled")
    settingsYPos += 70
    
    createToggle(SettingsTab, "Randomize Timings", "Add variation to auto parry timing", settingsYPos, "SafeMode.RandomizeTimings")
    settingsYPos += 70
    
    createSeparator(SettingsTab, settingsYPos)
    settingsYPos += 15
    
    createSectionTitle(SettingsTab, "About", settingsYPos)
    settingsYPos += 30
    
    -- Version info
    local VersionInfo = Instance.new("TextLabel")
    VersionInfo.Name = "VersionInfo"
    VersionInfo.Size = UDim2.new(1, -30, 0, 25)
    VersionInfo.Position = UDim2.new(0, 15, 0, settingsYPos)
    VersionInfo.BackgroundTransparency = 1
    VersionInfo.Text = "Version: " .. SCRIPT_VERSION
    VersionInfo.Font = Enum.Font.Gotham
    VersionInfo.TextSize = 14
    VersionInfo.TextColor3 = Theme.SecondaryText
    VersionInfo.TextXAlignment = Enum.TextXAlignment.Left
    VersionInfo.Parent = SettingsTab
    settingsYPos += 25
    
    -- Developer info
    local DeveloperInfo = Instance.new("TextLabel")
    DeveloperInfo.Name = "DeveloperInfo"
    DeveloperInfo.Size = UDim2.new(1, -30, 0, 25)
    DeveloperInfo.Position = UDim2.new(0, 15, 0, settingsYPos)
    DeveloperInfo.BackgroundTransparency = 1
    DeveloperInfo.Text = "Developed by Bane"
    DeveloperInfo.Font = Enum.Font.Gotham
    DeveloperInfo.TextSize = 14
    DeveloperInfo.TextColor3 = Theme.SecondaryText
    DeveloperInfo.TextXAlignment = Enum.TextXAlignment.Left
    DeveloperInfo.Parent = SettingsTab
    settingsYPos += 25
    
    -- Last updated info
    local UpdatedInfo = Instance.new("TextLabel")
    UpdatedInfo.Name = "UpdatedInfo"
    UpdatedInfo.Size = UDim2.new(1, -30, 0, 25)
    UpdatedInfo.Position = UDim2.new(0, 15, 0, settingsYPos)
    UpdatedInfo.BackgroundTransparency = 1
    UpdatedInfo.Text = "Last Updated: April 2025"
    UpdatedInfo.Font = Enum.Font.Gotham
    UpdatedInfo.TextSize = 14
    UpdatedInfo.TextColor3 = Theme.SecondaryText
    UpdatedInfo.TextXAlignment = Enum.TextXAlignment.Left
    UpdatedInfo.Parent = SettingsTab
    settingsYPos += 40
    
    -- Adjust canvas size based on content
    SettingsTab.CanvasSize = UDim2.new(0, 0, 0, settingsYPos + 60)
    
    -- Initialize GUI visibility
    MainFrame.Visible = Settings.GuiVisible
    
    -- Show the GUI with animation
    task.spawn(function()
        task.wait(2) -- Wait for splash screen to finish
        if Settings.AnimationEnabled then
            MainFrame.Visible = true
            MainFrame.Position = UDim2.new(-0.5, 0, 0.5, -225)
            
            TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.02, 0, 0.5, -225)
            }):Play()
        else
            MainFrame.Visible = true
        end
    end)
    
    -- Key bindings for showing/hiding GUI and other actions
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
            -- Toggle GUI visibility
            if input.KeyCode == Settings.KeyBinds.ToggleGui then
                Settings.GuiVisible = not Settings.GuiVisible
                ScreenGui.Enabled = Settings.GuiVisible
                
            -- Quick parry key
            elseif input.KeyCode == Settings.KeyBinds.QuickParry and ParryButtonPress then
                ParryButtonPress:FireServer()
                createVisualEffect("parry")
                
            -- Toggle auto spam
            elseif input.KeyCode == Settings.KeyBinds.ToggleAutoSpam then
                toggleAutoSpam()
                
            -- Toggle noclip
            elseif input.KeyCode == Settings.KeyBinds.ToggleNoClip then
                toggleNoClip()
            end
        end
    end)
    
    return ScreenGui
end

-- Main initialization function
local function initialize()
    print("Oasis Blade Ball Script - Loading...")
    
    -- Find game elements (parry/clash remotes)
    getGameElements()
    
    -- Create GUI
    local gui = createGui()
    
    -- Connect update functions to RunService
    BallTrackerConnection = RunService.Heartbeat:Connect(function()
        -- Detect new balls
        detectBalls()
        
        -- Update ball tracking and prediction
        if Settings.Performance.OptimizeBallTracking then
            -- Only update every other frame for performance
            if tick() % 0.06 <= 0.03 then
                updateBallTracking()
            end
        else
            updateBallTracking()
        end
    end)
    
    AutoParryConnection = RunService.Heartbeat:Connect(updateAutoParryAndClash)
    
    -- Auto dodge connection
    AutoDodgeConnection = RunService.Heartbeat:Connect(applyAutoDodge)
    
    -- Health check connection
    HealthCheckConnection = RunService.Heartbeat:Connect(function()
        if tick() % 1 <= 0.1 then -- Check every second
            checkAndHeal()
        end
    end)
    
    -- Movement enhancer connection
    SpeedBoostConnection = RunService.Heartbeat:Connect(enhanceMovement)
    
    -- Listen for character changes
    LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        Character = newCharacter
        Humanoid = Character:WaitForChild("Humanoid")
        HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    end)
    
    -- Start auto spam if enabled
    if Settings.AutoSpam.Enabled then
        startAutoSpam()
    end
    
    print("Oasis Blade Ball Script - Loaded successfully!")
    print("Press " .. Settings.KeyBinds.ToggleGui.Name .. " to toggle the GUI")
end

-- Start the script
initialize()

-- Return an empty table to avoid errors in some exploit environments
return {}
