--[[
    Oasis Blade Ball Script
    Version 3.0.0
    
    Features:
    - Auto Parry with customizable distance and timing
    - Auto Clash for fast balls
    - Visual cues for parry and clash events
    - Advanced GUI with draggable interface and animations
    - Client-side sky customization
    - Performance optimization settings
    - Detailed ball trajectory prediction
    - Customizable keyboard shortcuts
    - Anti-detection measures
    - Auto dodge for specific ball types
    - Player stats tracking
    - Hit prediction algorithm
    - Custom character effects
    - Session performance monitoring
    - 5 different GUI themes
    - Sound effects customization
    - Auto update notification system
    - Advanced configuration profiles
    - Auto healing when low health
    - Extended reach setting
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

-- Variables
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Remote events for parrying and clashing
local ParryButtonPress -- To store the Remote Event for parrying
local ClashButtonPress -- To store the Remote Event for clashing

-- Connection variables
local AutoParryConnection
local BallTrackerConnection
local VisualizerConnection
local InputConnection

-- Track all balls in the game
local ActiveBalls = {}

-- Settings (Default values)
local Settings = {
    AutoParry = {
        Enabled = false,
        Distance = 20, -- Max distance to auto parry
        PredictionMultiplier = 0.5, -- Adjust timing prediction
        Cooldown = 0.5, -- Cooldown between auto parry attempts
        LastParry = 0, -- Timestamp of last parry attempt
        PingAdjustment = true, -- Automatically adjust for ping
        SmartMode = true -- Uses AI prediction for trajectory
    },
    AutoClash = {
        Enabled = false,
        Distance = 10, -- Max distance to auto clash
        SpeedThreshold = 120, -- Min speed to trigger auto clash
        Cooldown = 0.4, -- Cooldown between auto clash attempts
        LastClash = 0, -- Timestamp of last clash attempt
        PriorityMode = "Speed" -- Speed, Distance, or Combined
    },
    AutoDodge = {
        Enabled = false,
        TriggerDistance = 15, -- Distance at which to start dodging
        DodgeMethod = "Jump", -- Jump, Sidestep, Smart
        OnlyForDangerousBalls = true, -- Only dodge for special balls
        Cooldown = 1.0 -- Cooldown between dodge attempts
    },
    ExtendedReach = {
        Enabled = false,
        ReachMultiplier = 1.2, -- How much to extend reach
        AffectParryOnly = true, -- Only affects parry, not combat
        AutoAdjust = true -- Automatically adjust based on situation
    },
    AutoHeal = {
        Enabled = false,
        HealthThreshold = 30, -- Percentage to trigger auto heal
        UseServerItems = true, -- Use healing items from server
        TryDodgeWhenLow = true -- Try to dodge when health is low
    },
    VisualCues = {
        Enabled = true,
        ParryColor = Color3.fromRGB(0, 255, 0), -- Green
        ClashColor = Color3.fromRGB(255, 165, 0), -- Orange
        DodgeColor = Color3.fromRGB(0, 170, 255), -- Blue
        Duration = 0.3, -- Duration of visual cue
        Style = "Ring", -- Ring, Flash, Pulse, Minimal
        Size = 1.0 -- Size multiplier for effects
    },
    BallPrediction = {
        Enabled = true,
        LineThickness = 0.2,
        LineColor = Color3.fromRGB(255, 255, 255),
        Transparency = 0.7,
        ShowImpactPoint = true, -- Shows where ball will hit
        ShowCountdown = true, -- Shows time until impact
        DetailLevel = "High" -- Low, Medium, High (affects performance)
    },
    CharacterEffects = {
        Enabled = false,
        TrailEffect = false, -- Leave a trail when moving
        HitEffect = true, -- Special effect on successful hit
        ParryEffect = true, -- Special effect on successful parry
        CustomAnimation = "Default" -- Default, Casual, Aggressive, Skillful
    },
    CustomSky = {
        Enabled = false,
        SkyType = "Default", -- Default, Space, Sunset, Night, Morning
        CustomColor = Color3.fromRGB(120, 180, 255),
        CycleMode = false, -- Cycle through skies over time
        CycleSpeed = 60 -- Seconds per cycle
    },
    SoundEffects = {
        Enabled = true,
        Volume = 0.5,
        ParrySound = "Default", -- Default, Satisfying, Minimal, Custom
        ClashSound = "Default",
        HitSound = "Default",
        CustomSoundIds = {} -- For custom sound IDs
    },
    Performance = {
        ReduceParticles = false,
        OptimizeBallTracking = true,
        LowGraphicsMode = false,
        ReduceAnimations = false,
        SimplifyEffects = false
    },
    Statistics = {
        Enabled = true,
        TrackHistory = true, -- Track parry/miss history
        ShowSuccessRate = true, -- Show success percentage
        RecordBestPerformance = true, -- Record personal bests
        SessionTracker = true -- Track statistics for current session
    },
    GuiTheme = "Dark", -- Dark, Light, Neon, Minimal, Custom
    ThemeColors = {
        Dark = {
            Background = Color3.fromRGB(25, 25, 30),
            CardBackground = Color3.fromRGB(35, 35, 40),
            PrimaryText = Color3.fromRGB(255, 255, 255),
            SecondaryText = Color3.fromRGB(180, 180, 180),
            Accent = Color3.fromRGB(131, 87, 255),
            Success = Color3.fromRGB(23, 224, 127),
            Warning = Color3.fromRGB(255, 165, 0),
            Danger = Color3.fromRGB(255, 59, 59)
        },
        Light = {
            Background = Color3.fromRGB(240, 240, 245),
            CardBackground = Color3.fromRGB(250, 250, 255),
            PrimaryText = Color3.fromRGB(30, 30, 35),
            SecondaryText = Color3.fromRGB(100, 100, 110),
            Accent = Color3.fromRGB(100, 120, 255),
            Success = Color3.fromRGB(40, 200, 120),
            Warning = Color3.fromRGB(255, 150, 50),
            Danger = Color3.fromRGB(255, 80, 80)
        },
        Neon = {
            Background = Color3.fromRGB(10, 10, 15),
            CardBackground = Color3.fromRGB(20, 20, 30),
            PrimaryText = Color3.fromRGB(240, 240, 255),
            SecondaryText = Color3.fromRGB(180, 180, 220),
            Accent = Color3.fromRGB(0, 200, 255),
            Success = Color3.fromRGB(0, 255, 170),
            Warning = Color3.fromRGB(255, 230, 0),
            Danger = Color3.fromRGB(255, 0, 100)
        },
        Minimal = {
            Background = Color3.fromRGB(10, 10, 10),
            CardBackground = Color3.fromRGB(20, 20, 20),
            PrimaryText = Color3.fromRGB(255, 255, 255),
            SecondaryText = Color3.fromRGB(200, 200, 200),
            Accent = Color3.fromRGB(150, 150, 150),
            Success = Color3.fromRGB(130, 200, 130),
            Warning = Color3.fromRGB(200, 180, 120),
            Danger = Color3.fromRGB(200, 120, 120)
        },
        Custom = {
            Background = Color3.fromRGB(25, 25, 30),
            CardBackground = Color3.fromRGB(35, 35, 40),
            PrimaryText = Color3.fromRGB(255, 255, 255),
            SecondaryText = Color3.fromRGB(180, 180, 180),
            Accent = Color3.fromRGB(131, 87, 255),
            Success = Color3.fromRGB(23, 224, 127),
            Warning = Color3.fromRGB(255, 165, 0),
            Danger = Color3.fromRGB(255, 59, 59)
        }
    },
    Profiles = {
        Active = "Default",
        Saved = {
            Default = {}, -- Will be populated with current settings on first save
            Aggressive = {}, -- Optimized for aggressive play
            Defensive = {}, -- Optimized for defensive play
            Performance = {} -- Optimized for lower-end devices
        }
    },
    ShowBallInfo = false, -- Show speed and distance info for balls
    GuiVisible = true, -- Toggle GUI visibility
    AnimationEnabled = true, -- Enable GUI animations
    KeyBinds = {
        ToggleGui = Enum.KeyCode.RightControl,
        QuickParry = Enum.KeyCode.E,
        QuickDodge = Enum.KeyCode.Q,
        CycleSky = Enum.KeyCode.K,
        ReloadScript = Enum.KeyCode.End
    }
}

-- GUI Colors and Design Constants
local Theme = {
    Background = Color3.fromRGB(25, 25, 30),
    CardBackground = Color3.fromRGB(35, 35, 40),
    PrimaryText = Color3.fromRGB(255, 255, 255),
    SecondaryText = Color3.fromRGB(180, 180, 180),
    Accent = Color3.fromRGB(131, 87, 255), -- Purple accent color
    Success = Color3.fromRGB(23, 224, 127),
    Warning = Color3.fromRGB(255, 165, 0),
    Danger = Color3.fromRGB(255, 59, 59),
    ToggleEnabled = Color3.fromRGB(131, 87, 255),
    ToggleDisabled = Color3.fromRGB(60, 60, 70),
    SliderBackground = Color3.fromRGB(60, 60, 70),
    SliderFill = Color3.fromRGB(131, 87, 255),
    Transparency = 0.9,
    RoundedCorner = 8
}

-- Sky presets
local SkyPresets = {
    Default = {
        SkyboxBk = "rbxassetid://7018684000",
        SkyboxDn = "rbxassetid://7018684000",
        SkyboxFt = "rbxassetid://7018684000", 
        SkyboxLf = "rbxassetid://7018684000",
        SkyboxRt = "rbxassetid://7018684000",
        SkyboxUp = "rbxassetid://7018684000"
    },
    Space = {
        SkyboxBk = "rbxassetid://149397692",
        SkyboxDn = "rbxassetid://149397684",
        SkyboxFt = "rbxassetid://149397697",
        SkyboxLf = "rbxassetid://149397686",
        SkyboxRt = "rbxassetid://149397688",
        SkyboxUp = "rbxassetid://149397702"
    },
    Sunset = {
        SkyboxBk = "rbxassetid://253027015",
        SkyboxDn = "rbxassetid://253027058",
        SkyboxFt = "rbxassetid://253027039",
        SkyboxLf = "rbxassetid://253027029",
        SkyboxRt = "rbxassetid://253027051",
        SkyboxUp = "rbxassetid://253027019"
    },
    Night = {
        SkyboxBk = "rbxassetid://12064107",
        SkyboxDn = "rbxassetid://12064152",
        SkyboxFt = "rbxassetid://12064121",
        SkyboxLf = "rbxassetid://12063984",
        SkyboxRt = "rbxassetid://12064115",
        SkyboxUp = "rbxassetid://12064131"
    },
    Morning = {
        SkyboxBk = "rbxassetid://196263782",
        SkyboxDn = "rbxassetid://196263249",
        SkyboxFt = "rbxassetid://196263721",
        SkyboxLf = "rbxassetid://196263635",
        SkyboxRt = "rbxassetid://196263616",
        SkyboxUp = "rbxassetid://196263855"
    }
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
                    print("Found parry remote: " .. v.Name)
                    break
                end
            end
        end
        
        -- Look for clash remote
        if not ClashButtonPress then
            for _, v in pairs(ReplicatedStorage:GetDescendants()) do
                if v:IsA("RemoteEvent") and (v.Name:find("Clash") or v.Name:find("clash")) then
                    ClashButtonPress = v
                    print("Found clash remote: " .. v.Name)
                    break
                end
            end
        end
        
        -- If we found what we need or reached max attempts, break the loop
        if (ParryButtonPress and ClashButtonPress) or attempts >= maxAttempts then
            break
        end
        
        -- Wait before trying again
        task.wait(1)
    end
    
    -- If we couldn't find the events, try alternative methods
    if not ParryButtonPress then
        for _, v in pairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") and string.len(v.Name) <= 12 then
                ParryButtonPress = v
                print("Using fallback parry remote: " .. v.Name)
                break
            end
        end
    end
    
    -- If we still can't find them, notify the user
    if not ParryButtonPress then
        print("Error: Could not find parry remote event. Script may not function correctly.")
    end
    
    if not ClashButtonPress then
        print("Note: Could not find clash remote event. Using parry remote for clashing.")
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
                    Prediction = nil
                }
                
                -- Create tracker for visualization if enabled
                if Settings.BallPrediction.Enabled then
                    createBallTracker(obj)
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

-- Function to update ball tracking and prediction
local function updateBallTracking()
    for ball, data in pairs(ActiveBalls) do
        if ball and ball:IsDescendantOf(workspace) then
            -- Calculate velocity and speed
            local currentPosition = ball.Position
            local velocity = (currentPosition - data.LastPosition) / RunService.Heartbeat:Wait()
            data.Velocity = velocity
            data.Speed = velocity.Magnitude
            data.LastPosition = currentPosition
            
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
        else
            -- Ball no longer exists, remove tracker
            if data.Tracker then
                data.Tracker:Destroy()
            end
            if data.Prediction then
                data.Prediction:Destroy()
            end
            ActiveBalls[ball] = nil
        end
    end
end

-- Function to apply custom sky settings
local function applySkySettings()
    -- Create or get existing skybox
    local skybox = Lighting:FindFirstChildOfClass("Sky")
    if not skybox then
        skybox = Instance.new("Sky")
        skybox.Parent = Lighting
    end
    
    if Settings.CustomSky.Enabled then
        local selectedSky = SkyPresets[Settings.CustomSky.SkyType] or SkyPresets.Default
        
        -- Apply skybox textures
        for prop, value in pairs(selectedSky) do
            skybox[prop] = value
        end
        
        -- Apply custom color tint to lighting
        if Settings.CustomSky.SkyType == "Custom" then
            Lighting.Ambient = Settings.CustomSky.CustomColor
            Lighting.OutdoorAmbient = Settings.CustomSky.CustomColor
        else
            -- Reset to default lighting
            Lighting.Ambient = Color3.fromRGB(127, 127, 127)
            Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
        end
    else
        -- Reset to game's default sky
        local defaultProps = SkyPresets.Default
        for prop, value in pairs(defaultProps) do
            skybox[prop] = value
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
    
    -- Check if ball is close enough
    local distance = (ball.Position - HumanoidRootPart.Position).Magnitude
    if distance > Settings.AutoParry.Distance then
        return false
    end
    
    -- Check if ball is moving toward us
    local ballToChar = (HumanoidRootPart.Position - ball.Position).Unit
    local dotProduct = ballToChar:Dot(ballData.Velocity.Unit)
    
    -- Ball is coming toward us if dot product is positive
    if dotProduct < 0.5 then -- Ball is not moving toward us enough
        return false
    end
    
    -- Calculate time to reach player
    local timeToReach = distance / math.max(ballData.Speed, 1)
    
    -- Only parry if ball will reach soon based on prediction multiplier
    return timeToReach < Settings.AutoParry.PredictionMultiplier
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

-- Function to create visual effect for parry/clash
local function createVisualEffect(type)
    if not Settings.VisualCues.Enabled then return end
    
    local color = type == "parry" and Settings.VisualCues.ParryColor or Settings.VisualCues.ClashColor
    
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
        {Size = Vector3.new(0.3, 20, 20), Transparency = 1}
    )
    
    tween:Play()
    
    tween.Completed:Connect(function()
        ring:Destroy()
    end)
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
                    print("Auto parry triggered!")
                end
            -- Check for auto clash
            elseif shouldAutoClash(ball, ballData) then
                if ClashButtonPress then
                    Settings.AutoClash.LastClash = tick()
                    ClashButtonPress:FireServer()
                    createVisualEffect("clash")
                    print("Auto clash triggered!")
                end
            end
        end
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
    ToggleUICorner.CornerRadius = UDim.new(0, Theme.RoundedCorner)
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
            
            -- Update visual
            updateToggleVisual()
            
            -- Apply changes if needed
            if settingPath:find("CustomSky") then
                applySkySettings()
            elseif settingPath:find("BallPrediction") then
                -- Update ball predictors
                for ball, _ in pairs(ActiveBalls) do
                    createBallTracker(ball)
                end
            end
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
    SliderUICorner.CornerRadius = UDim.new(0, Theme.RoundedCorner)
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

-- Function to create a dropdown menu
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
    DropdownUICorner.CornerRadius = UDim.new(0, Theme.RoundedCorner)
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
        currentSetting = currentSetting[part]
    end
    
    -- Update dropdown button text
    DropdownButton.Text = currentSetting
    
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
        if optionValue == currentSetting then
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
            
            -- Update dropdown button text
            DropdownButton.Text = optionValue
            
            -- Hide options
            OptionsFrame.Visible = false
            ArrowIcon.Text = "▼"
            
            -- Apply changes if needed
            if settingPath:find("CustomSky") then
                applySkySettings()
            end
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

-- Sound Effects IDs
local SoundEffects = {
    Parry = {
        Default = "rbxassetid://6545869031",
        Satisfying = "rbxassetid://9125635729",
        Minimal = "rbxassetid://3398620867",
        Retro = "rbxassetid://3835930797"
    },
    Clash = {
        Default = "rbxassetid://6332584152", 
        Satisfying = "rbxassetid://5869422451",
        Minimal = "rbxassetid://255679791",
        Retro = "rbxassetid://12221976"
    },
    Hit = {
        Default = "rbxassetid://6607204501",
        Satisfying = "rbxassetid://6462037197",
        Minimal = "rbxassetid://4942556877",
        Retro = "rbxassetid://4058231816"
    },
    UI = {
        Click = "rbxassetid://3061758043",
        Hover = "rbxassetid://3848738002", 
        Toggle = "rbxassetid://6895079853",
        Notification = "rbxassetid://6518811702"
    }
}

-- Animations and particle effects 
local ParticleEffects = {
    Parry = {
        Id = "rbxassetid://6590241902",
        Properties = {
            Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.3, 3),
                NumberSequenceKeypoint.new(1, 0)
            }),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.1, 0.2),
                NumberSequenceKeypoint.new(0.8, 0.2),
                NumberSequenceKeypoint.new(1, 1)
            }),
            Speed = NumberRange.new(10, 20),
            Lifetime = NumberRange.new(0.5, 1),
            SpreadAngle = Vector2.new(-360, 360),
            EmissionDirection = Enum.NormalId.Top
        }
    },
    Clash = {
        Id = "rbxassetid://6107359423",
        Properties = {
            Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.5),
                NumberSequenceKeypoint.new(0.5, 2),
                NumberSequenceKeypoint.new(1, 0)
            }),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.7, 0.5),
                NumberSequenceKeypoint.new(1, 1)
            }),
            Speed = NumberRange.new(15, 30),
            Lifetime = NumberRange.new(0.3, 0.6),
            SpreadAngle = Vector2.new(-180, 180),
            EmissionDirection = Enum.NormalId.Front
        }
    }
}

-- UI Animation presets
local UIAnimations = {
    PopIn = function(element, startScale, endScale, startPos, endPos, duration)
        startScale = startScale or 0.7
        endScale = endScale or 1
        duration = duration or 0.3
        
        element.Size = element.Size * startScale
        if startPos then element.Position = startPos end
        
        local tweenInfo = TweenInfo.new(
            duration,
            Enum.EasingStyle.Back,
            Enum.EasingDirection.Out
        )
        
        local properties = {Size = element.Size / startScale * endScale}
        if endPos then properties.Position = endPos end
        
        local tween = TweenService:Create(element, tweenInfo, properties)
        tween:Play()
        return tween
    end,
    
    FadeIn = function(element, duration)
        duration = duration or 0.3
        element.BackgroundTransparency = 1
        
        -- Handle text transparency if applicable
        if element:IsA("TextLabel") or element:IsA("TextButton") or element:IsA("TextBox") then
            element.TextTransparency = 1
        end
        
        -- Handle image transparency if applicable
        if element:IsA("ImageLabel") or element:IsA("ImageButton") then
            element.ImageTransparency = 1
        end
        
        local tweenInfo = TweenInfo.new(
            duration,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        )
        
        local properties = {BackgroundTransparency = element.BackgroundTransparency - 0.9}
        
        -- Add text properties if needed
        if element:IsA("TextLabel") or element:IsA("TextButton") or element:IsA("TextBox") then
            properties.TextTransparency = 0
        end
        
        -- Add image properties if needed
        if element:IsA("ImageLabel") or element:IsA("ImageButton") then
            properties.ImageTransparency = 0
        end
        
        local tween = TweenService:Create(element, tweenInfo, properties)
        tween:Play()
        return tween
    end,
    
    Pulse = function(element, scaleAmount, duration)
        scaleAmount = scaleAmount or 1.1
        duration = duration or 0.3
        
        local originalSize = element.Size
        
        local tweenInfoGrow = TweenInfo.new(
            duration / 2,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        )
        
        local tweenInfoShrink = TweenInfo.new(
            duration / 2,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.In
        )
        
        local growTween = TweenService:Create(
            element, 
            tweenInfoGrow, 
            {Size = originalSize * scaleAmount}
        )
        
        local shrinkTween = TweenService:Create(
            element, 
            tweenInfoShrink, 
            {Size = originalSize}
        )
        
        growTween:Play()
        growTween.Completed:Connect(function()
            shrinkTween:Play()
        end)
        
        return shrinkTween
    end,
    
    Ripple = function(parent, mousePos)
        -- Create ripple effect from mouse position
        local ripple = Instance.new("Frame")
        ripple.Name = "Ripple"
        ripple.AnchorPoint = Vector2.new(0.5, 0.5)
        ripple.Size = UDim2.new(0, 0, 0, 0)
        ripple.BorderSizePixel = 0
        ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ripple.BackgroundTransparency = 0.7
        ripple.Position = UDim2.new(
            0, mousePos.X - parent.AbsolutePosition.X,
            0, mousePos.Y - parent.AbsolutePosition.Y
        )
        
        local circle = Instance.new("UICorner")
        circle.CornerRadius = UDim.new(1, 0)
        circle.Parent = ripple
        
        ripple.Parent = parent
        
        local maxSize = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2
        
        local tweenInfo = TweenInfo.new(
            0.5,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        )
        
        local tween = TweenService:Create(
            ripple,
            tweenInfo,
            {
                Size = UDim2.new(0, maxSize, 0, maxSize),
                BackgroundTransparency = 1
            }
        )
        
        tween:Play()
        tween.Completed:Connect(function()
            ripple:Destroy()
        end)
        
        return tween
    end,
    
    Shake = function(element, intensity, duration)
        intensity = intensity or 5
        duration = duration or 0.5
        
        local originalPosition = element.Position
        local startTime = tick()
        
        -- Disconnect existing shake if there is one
        if element._shakeConnection then
            element._shakeConnection:Disconnect()
        end
        
        element._shakeConnection = RunService.Heartbeat:Connect(function()
            local elapsed = tick() - startTime
            
            if elapsed < duration then
                local remainingIntensity = intensity * (1 - (elapsed / duration))
                local randomOffset = Vector2.new(
                    (math.random() - 0.5) * remainingIntensity,
                    (math.random() - 0.5) * remainingIntensity
                )
                
                element.Position = UDim2.new(
                    originalPosition.X.Scale, 
                    originalPosition.X.Offset + randomOffset.X,
                    originalPosition.Y.Scale, 
                    originalPosition.Y.Offset + randomOffset.Y
                )
            else
                element.Position = originalPosition
                element._shakeConnection:Disconnect()
                element._shakeConnection = nil
            end
        end)
    end
}

-- Advanced Stats Tracking System
local StatsTracker = {
    CurrentSession = {
        ParryAttempts = 0,
        SuccessfulParries = 0,
        Misses = 0,
        ClashAttempts = 0,
        SuccessfulClashes = 0,
        DodgeAttempts = 0,
        SuccessfulDodges = 0,
        StartTime = 0,
        BestStreak = 0,
        CurrentStreak = 0
    },
    
    Initialize = function(self)
        -- Reset session stats
        self.CurrentSession = {
            ParryAttempts = 0,
            SuccessfulParries = 0, 
            Misses = 0,
            ClashAttempts = 0,
            SuccessfulClashes = 0,
            DodgeAttempts = 0,
            SuccessfulDodges = 0,
            StartTime = tick(),
            BestStreak = 0,
            CurrentStreak = 0
        }
    end,
    
    RecordParryAttempt = function(self, success)
        self.CurrentSession.ParryAttempts = self.CurrentSession.ParryAttempts + 1
        
        if success then
            self.CurrentSession.SuccessfulParries = self.CurrentSession.SuccessfulParries + 1
            self.CurrentSession.CurrentStreak = self.CurrentSession.CurrentStreak + 1
            
            if self.CurrentSession.CurrentStreak > self.CurrentSession.BestStreak then
                self.CurrentSession.BestStreak = self.CurrentSession.CurrentStreak
            end
        else
            self.CurrentSession.Misses = self.CurrentSession.Misses + 1
            self.CurrentSession.CurrentStreak = 0
        end
    end,
    
    RecordClashAttempt = function(self, success)
        self.CurrentSession.ClashAttempts = self.CurrentSession.ClashAttempts + 1
        
        if success then
            self.CurrentSession.SuccessfulClashes = self.CurrentSession.SuccessfulClashes + 1
        end
    end,
    
    RecordDodgeAttempt = function(self, success)
        self.CurrentSession.DodgeAttempts = self.CurrentSession.DodgeAttempts + 1
        
        if success then
            self.CurrentSession.SuccessfulDodges = self.CurrentSession.SuccessfulDodges + 1
        end
    end,
    
    GetSuccessRate = function(self)
        local totalAttempts = self.CurrentSession.ParryAttempts
        if totalAttempts == 0 then
            return 0
        end
        
        return (self.CurrentSession.SuccessfulParries / totalAttempts) * 100
    end,
    
    GetSessionDuration = function(self)
        return tick() - self.CurrentSession.StartTime
    end,
    
    FormatTime = function(self, seconds)
        local minutes = math.floor(seconds / 60)
        local remainingSeconds = math.floor(seconds % 60)
        return string.format("%02d:%02d", minutes, remainingSeconds)
    end,
    
    GetSessionSummary = function(self)
        local duration = self:GetSessionDuration()
        local formattedTime = self:FormatTime(duration)
        local successRate = string.format("%.1f", self:GetSuccessRate())
        
        return {
            Duration = formattedTime,
            SuccessRate = successRate,
            TotalParries = self.CurrentSession.SuccessfulParries,
            TotalMisses = self.CurrentSession.Misses,
            TotalAttempts = self.CurrentSession.ParryAttempts,
            BestStreak = self.CurrentSession.BestStreak
        }
    end
}

-- Advanced notification system
local NotificationSystem = {
    ActiveNotifications = {},
    MaxNotifications = 5,
    
    CreateNotification = function(self, title, message, type, duration)
        type = type or "Info" -- Info, Success, Warning, Error
        duration = duration or 3
        
        -- Create notification UI
        local notification = Instance.new("Frame")
        notification.Name = "Notification"
        notification.Size = UDim2.new(0, 250, 0, 80)
        notification.Position = UDim2.new(1, -270, 1, 20) -- Start below screen
        notification.BackgroundColor3 = Theme.CardBackground
        notification.BorderSizePixel = 0
        notification.ZIndex = 100
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = notification
        
        local iconColors = {
            Info = Theme.Accent,
            Success = Theme.Success,
            Warning = Theme.Warning,
            Error = Theme.Danger
        }
        
        local iconSymbols = {
            Info = "ℹ️",
            Success = "✓",
            Warning = "⚠️",
            Error = "✕"
        }
        
        -- Icon
        local icon = Instance.new("TextLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, 30, 0, 30)
        icon.Position = UDim2.new(0, 15, 0, 15)
        icon.BackgroundColor3 = iconColors[type]
        icon.Text = iconSymbols[type]
        icon.TextColor3 = Color3.fromRGB(255, 255, 255)
        icon.TextSize = 16
        icon.Font = Enum.Font.GothamBold
        icon.BorderSizePixel = 0
        icon.ZIndex = 101
        icon.Parent = notification
        
        local iconCorner = Instance.new("UICorner")
        iconCorner.CornerRadius = UDim.new(1, 0)
        iconCorner.Parent = icon
        
        -- Title
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Title"
        titleLabel.Size = UDim2.new(1, -60, 0, 20)
        titleLabel.Position = UDim2.new(0, 55, 0, 10)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = Theme.PrimaryText
        titleLabel.TextSize = 16
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.ZIndex = 101
        titleLabel.Parent = notification
        
        -- Message
        local messageLabel = Instance.new("TextLabel")
        messageLabel.Name = "Message"
        messageLabel.Size = UDim2.new(1, -60, 0, 40)
        messageLabel.Position = UDim2.new(0, 55, 0, 30)
        messageLabel.BackgroundTransparency = 1
        messageLabel.Text = message
        messageLabel.TextColor3 = Theme.SecondaryText
        messageLabel.TextSize = 14
        messageLabel.Font = Enum.Font.Gotham
        messageLabel.TextXAlignment = Enum.TextXAlignment.Left
        messageLabel.TextYAlignment = Enum.TextYAlignment.Top
        messageLabel.TextWrapped = true
        messageLabel.ZIndex = 101
        messageLabel.Parent = notification
        
        -- Close button
        local closeButton = Instance.new("TextButton")
        closeButton.Name = "CloseButton"
        closeButton.Size = UDim2.new(0, 20, 0, 20)
        closeButton.Position = UDim2.new(1, -25, 0, 10)
        closeButton.BackgroundTransparency = 1
        closeButton.Text = "✕"
        closeButton.TextColor3 = Theme.SecondaryText
        closeButton.TextSize = 14
        closeButton.Font = Enum.Font.GothamBold
        closeButton.ZIndex = 101
        closeButton.Parent = notification
        
        -- Progress bar
        local progressBar = Instance.new("Frame")
        progressBar.Name = "ProgressBar"
        progressBar.Size = UDim2.new(1, 0, 0, 3)
        progressBar.Position = UDim2.new(0, 0, 1, -3)
        progressBar.BackgroundColor3 = iconColors[type]
        progressBar.BorderSizePixel = 0
        progressBar.ZIndex = 101
        progressBar.Parent = notification
        
        -- Add to screen
        notification.Parent = CoreGui:FindFirstChild("OasisBladeballGui")
        
        -- Play sound
        local sound = Instance.new("Sound")
        sound.SoundId = SoundEffects.UI.Notification
        sound.Volume = 0.5
        sound.Parent = notification
        sound:Play()
        
        -- Animate in
        notification.Position = UDim2.new(1, 300, 1, -100) -- Start off-screen
        
        -- Reposition existing notifications
        self:RepositionNotifications()
        
        -- Add to active notifications
        table.insert(self.ActiveNotifications, 1, notification)
        
        -- Remove oldest if we have too many
        if #self.ActiveNotifications > self.MaxNotifications then
            local oldest = table.remove(self.ActiveNotifications)
            self:RemoveNotification(oldest, true)
        end
        
        -- Slide in animation
        local tweenIn = TweenService:Create(
            notification,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = UDim2.new(1, -270, 1, -100)}
        )
        tweenIn:Play()
        
        -- Progress bar animation
        local tweenProgress = TweenService:Create(
            progressBar,
            TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
            {Size = UDim2.new(0, 0, 0, 3)}
        )
        tweenProgress:Play()
        
        -- Close button functionality
        closeButton.MouseButton1Click:Connect(function()
            self:RemoveNotification(notification)
        end)
        
        -- Auto remove after duration
        task.delay(duration, function()
            self:RemoveNotification(notification)
        end)
        
        return notification
    end,
    
    RemoveNotification = function(self, notification, instant)
        -- Find index of the notification
        local index = -1
        for i, notif in ipairs(self.ActiveNotifications) do
            if notif == notification then
                index = i
                break
            end
        end
        
        if index > 0 then
            table.remove(self.ActiveNotifications, index)
        end
        
        -- Animate out
        if instant then
            notification:Destroy()
            self:RepositionNotifications()
        else
            local tweenOut = TweenService:Create(
                notification,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {Position = UDim2.new(1, 300, notification.Position.Y.Scale, notification.Position.Y.Offset)}
            )
            
            tweenOut:Play()
            tweenOut.Completed:Connect(function()
                notification:Destroy()
                self:RepositionNotifications()
            end)
        end
    end,
    
    RepositionNotifications = function(self)
        -- Animate all notifications to their proper positions
        local baseOffset = -100
        local spacing = 90
        
        for i, notification in ipairs(self.ActiveNotifications) do
            local targetY = baseOffset - (i-1) * spacing
            
            TweenService:Create(
                notification,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = UDim2.new(1, -270, 1, targetY)}
            ):Play()
        end
    end,
    
    Info = function(self, title, message, duration)
        return self:CreateNotification(title, message, "Info", duration)
    end,
    
    Success = function(self, title, message, duration)
        return self:CreateNotification(title, message, "Success", duration)
    end,
    
    Warning = function(self, title, message, duration)
        return self:CreateNotification(title, message, "Warning", duration)
    end,
    
    Error = function(self, title, message, duration)
        return self:CreateNotification(title, message, "Error", duration)
    end
}

-- Initialize new features when script starts
local function initExtendedFeatures()
    -- Initialize stats tracking
    StatsTracker:Initialize()
    
    -- Show welcome notification when script is loaded
    task.delay(2, function()
        if NotificationSystem and NotificationSystem.Success then
            NotificationSystem:Success(
                "Oasis Script Loaded", 
                "Version 3.0.0 activated with extended features. Press Right Ctrl to toggle GUI.",
                5
            )
        end
    end)
}

-- Function to create the GUI
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
    
    -- Use appropriate parent based on environment
    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = game.CoreGui
    elseif gethui then
        ScreenGui.Parent = gethui()
    else
        ScreenGui.Parent = game.CoreGui
    end
    
    -- Create logo image (using a purple-themed logo)
    local Logo = Instance.new("ImageLabel")
    Logo.Name = "Logo"
    Logo.Size = UDim2.new(0, 100, 0, 100)
    Logo.Position = UDim2.new(0.5, -50, 0.5, -50)
    Logo.BackgroundTransparency = 1
    Logo.Image = "rbxassetid://13377453032" -- Replace with actual logo asset ID
    Logo.ImageTransparency = 0
    Logo.Parent = ScreenGui
    
    -- Create logo text
    local LogoText = Instance.new("TextLabel")
    LogoText.Name = "LogoText"
    LogoText.Size = UDim2.new(0, 200, 0, 40)
    LogoText.Position = UDim2.new(0.5, -100, 0.5, 40)
    LogoText.BackgroundTransparency = 1
    LogoText.Text = "Oasis Blade Ball"
    LogoText.Font = Enum.Font.GothamBold
    LogoText.TextSize = 18
    LogoText.TextColor3 = Theme.PrimaryText
    LogoText.Parent = ScreenGui
    
    -- Animate logo on start
    Logo.ImageTransparency = 1
    LogoText.TextTransparency = 1
    
    TweenService:Create(Logo, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -50, 0.5, -70),
        ImageTransparency = 0
    }):Play()
    
    TweenService:Create(LogoText, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        TextTransparency = 0
    }):Play()
    
    -- Wait and fade out logo after a delay
    task.spawn(function()
        task.wait(1.5)
        
        TweenService:Create(Logo, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            ImageTransparency = 1
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
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.Size = UDim2.new(1, 40, 1, 40)
    Shadow.Position = UDim2.new(0, -20, 0, -20)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://5554236805"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 0.6
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    Shadow.ZIndex = -1
    Shadow.Parent = MainFrame
    
    -- Apply rounded corners to main frame
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, Theme.RoundedCorner)
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
    TitleBarUICorner.CornerRadius = UDim.new(0, Theme.RoundedCorner)
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
    local TitleLogo = Instance.new("ImageLabel")
    TitleLogo.Name = "TitleLogo"
    TitleLogo.Size = UDim2.new(0, 24, 0, 24)
    TitleLogo.Position = UDim2.new(0, 12, 0.5, -12)
    TitleLogo.BackgroundTransparency = 1
    TitleLogo.Image = "rbxassetid://13377453032" -- Replace with actual logo asset ID
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
        local tabWidth = 1/#{"Main", "Visual", "Advanced", "Settings"} -- Adjust based on tab count
        
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
            Button = TabButton,
            TextColor3 = TabButton.TextColor3,
            ActiveIndicator = ActiveIndicator
        }
        tabPages[tabName] = TabPage
        
        return TabPage
    end
    
    -- Create the tab pages
    local MainTab = createTab("Main")
    local VisualTab = createTab("Visual")
    local AdvancedTab = createTab("Advanced")
    local SettingsTab = createTab("Settings")
    
    -- Populate Main Tab
    local mainYPos = 15
    createSectionTitle(MainTab, "Core Features", mainYPos)
    mainYPos += 30
    
    createToggle(MainTab, "Auto Parry", "Automatically parry incoming balls", mainYPos, "AutoParry.Enabled")
    mainYPos += 70
    
    createToggle(MainTab, "Auto Clash", "Automatically clash with fast balls", mainYPos, "AutoClash.Enabled")
    mainYPos += 70
    
    createSlider(MainTab, "Parry Distance", "Maximum distance to trigger auto parry", mainYPos, "AutoParry.Distance", 5, 50, 1)
    mainYPos += 90
    
    createSlider(MainTab, "Parry Timing", "Adjust parry timing (lower = earlier)", mainYPos, "AutoParry.PredictionMultiplier", 0.1, 1.0, 0.05)
    mainYPos += 90
    
    createSlider(MainTab, "Clash Speed", "Minimum ball speed to trigger clash", mainYPos, "AutoClash.SpeedThreshold", 50, 300, 5)
    mainYPos += 90
    
    createToggle(MainTab, "Show Ball Info", "Display speed and distance of balls", mainYPos, "ShowBallInfo")
    mainYPos += 70
    
    -- Adjust canvas size based on content
    MainTab.CanvasSize = UDim2.new(0, 0, 0, mainYPos + 20)
    
    -- Populate Visual Tab
    local visualYPos = 15
    createSectionTitle(VisualTab, "Visual Features", visualYPos)
    visualYPos += 30
    
    createToggle(VisualTab, "Visual Cues", "Show visual effects for parry/clash", visualYPos, "VisualCues.Enabled")
    visualYPos += 70
    
    createToggle(VisualTab, "Ball Prediction", "Show ball trajectory predictions", visualYPos, "BallPrediction.Enabled")
    visualYPos += 70
    
    createSlider(VisualTab, "Line Thickness", "Adjust prediction line thickness", visualYPos, "BallPrediction.LineThickness", 0.1, 1.0, 0.05)
    visualYPos += 90
    
    createSeparator(VisualTab, visualYPos)
    visualYPos += 15
    
    createSectionTitle(VisualTab, "Sky Customization", visualYPos)
    visualYPos += 30
    
    createToggle(VisualTab, "Custom Sky", "Enable client-side sky changes", visualYPos, "CustomSky.Enabled")
    visualYPos += 70
    
    createDropdown(VisualTab, "Sky Type", "Choose your sky theme", visualYPos, "CustomSky.SkyType", {"Default", "Space", "Sunset", "Night", "Morning"})
    visualYPos += 80
    
    -- Adjust canvas size based on content
    VisualTab.CanvasSize = UDim2.new(0, 0, 0, visualYPos + 20)
    
    -- Populate Advanced Tab
    local advancedYPos = 15
    createSectionTitle(AdvancedTab, "Advanced Settings", advancedYPos)
    advancedYPos += 30
    
    createSlider(AdvancedTab, "Parry Cooldown", "Time between parry attempts (seconds)", advancedYPos, "AutoParry.Cooldown", 0.1, 1.0, 0.05)
    advancedYPos += 90
    
    createSlider(AdvancedTab, "Clash Cooldown", "Time between clash attempts (seconds)", advancedYPos, "AutoClash.Cooldown", 0.1, 1.0, 0.05)
    advancedYPos += 90
    
    createSlider(AdvancedTab, "Clash Distance", "Maximum distance to trigger auto clash", advancedYPos, "AutoClash.Distance", 5, 30, 1)
    advancedYPos += 90
    
    createSeparator(AdvancedTab, advancedYPos)
    advancedYPos += 15
    
    createSectionTitle(AdvancedTab, "Performance", advancedYPos)
    advancedYPos += 30
    
    createToggle(AdvancedTab, "Reduce Particles", "Disable some particle effects for better FPS", advancedYPos, "Performance.ReduceParticles")
    advancedYPos += 70
    
    createToggle(AdvancedTab, "Optimize Tracking", "Reduce ball tracking calculations", advancedYPos, "Performance.OptimizeBallTracking")
    advancedYPos += 70
    
    -- Adjust canvas size based on content
    AdvancedTab.CanvasSize = UDim2.new(0, 0, 0, advancedYPos + 20)
    
    -- Populate Settings Tab
    local settingsYPos = 15
    createSectionTitle(SettingsTab, "User Interface", settingsYPos)
    settingsYPos += 30
    
    createToggle(SettingsTab, "GUI Animations", "Enable smooth GUI animations", settingsYPos, "AnimationEnabled")
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
    VersionInfo.Text = "Version: 2.0.0"
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
    
    -- Reset settings button
    local ResetButton = Instance.new("TextButton")
    ResetButton.Name = "ResetButton"
    ResetButton.Size = UDim2.new(0, 120, 0, 30)
    ResetButton.Position = UDim2.new(0, 15, 0, settingsYPos)
    ResetButton.BackgroundColor3 = Theme.Danger
    ResetButton.BackgroundTransparency = 0.3
    ResetButton.BorderSizePixel = 0
    ResetButton.Text = "Reset Settings"
    ResetButton.Font = Enum.Font.GothamSemibold
    ResetButton.TextSize = 14
    ResetButton.TextColor3 = Theme.PrimaryText
    ResetButton.Parent = SettingsTab
    
    local ResetButtonUICorner = Instance.new("UICorner")
    ResetButtonUICorner.CornerRadius = UDim.new(0, 6)
    ResetButtonUICorner.Parent = ResetButton
    
    ResetButton.MouseButton1Click:Connect(function()
        -- Reset to default settings
        Settings = {
            AutoParry = {
                Enabled = false,
                Distance = 20,
                PredictionMultiplier = 0.5,
                Cooldown = 0.5,
                LastParry = 0
            },
            AutoClash = {
                Enabled = false,
                Distance = 10,
                SpeedThreshold = 120,
                Cooldown = 0.4,
                LastClash = 0
            },
            VisualCues = {
                Enabled = true,
                ParryColor = Color3.fromRGB(0, 255, 0),
                ClashColor = Color3.fromRGB(255, 165, 0),
                Duration = 0.3
            },
            BallPrediction = {
                Enabled = true,
                LineThickness = 0.2,
                LineColor = Color3.fromRGB(255, 255, 255),
                Transparency = 0.7
            },
            CustomSky = {
                Enabled = false,
                SkyType = "Default",
                CustomColor = Color3.fromRGB(120, 180, 255)
            },
            Performance = {
                ReduceParticles = false,
                OptimizeBallTracking = true
            },
            ShowBallInfo = false,
            GuiVisible = true,
            AnimationEnabled = true,
            KeyBinds = {
                ToggleGui = Enum.KeyCode.RightControl,
                QuickParry = Enum.KeyCode.E
            }
        }
        
        -- Recreate the GUI with default settings
        ScreenGui:Destroy()
        createGui()
    end)
    
    -- Adjust canvas size based on content
    SettingsTab.CanvasSize = UDim2.new(0, 0, 0, settingsYPos + 60)
    
    -- Initialize GUI visibility
    MainFrame.Visible = Settings.GuiVisible
    
    -- Key bindings for showing/hiding GUI
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed then
            if input.KeyCode == Settings.KeyBinds.ToggleGui then
                Settings.GuiVisible = not Settings.GuiVisible
                ScreenGui.Enabled = Settings.GuiVisible
            elseif input.KeyCode == Settings.KeyBinds.QuickParry and ParryButtonPress then
                ParryButtonPress:FireServer()
                createVisualEffect("parry")
            end
        end
    end)
    
    return ScreenGui
end

-- Main initialization function
local function initialize()
    print("Bane's Ultimate Blade Ball Script - Loading...")
    
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
    
    -- Apply custom sky settings
    applySkySettings()
    
    -- Listen for character changes
    LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        Character = newCharacter
        Humanoid = Character:WaitForChild("Humanoid")
        HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    end)
    
    -- Apply performance settings
    if Settings.Performance.ReduceParticles then
        for _, particle in pairs(workspace:GetDescendants()) do
            if particle:IsA("ParticleEmitter") or particle:IsA("Trail") then
                particle.Enabled = false
            end
        end
    end
    
    print("Bane's Ultimate Blade Ball Script - Loaded successfully!")
    print("Press Right Ctrl to toggle the GUI")
end

-- Initialize extended features
initExtendedFeatures()

-- Start the script
initialize()