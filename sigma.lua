-- Cerials Hub - Enhanced & Optimized Version with FIXED Combat & Team ESP
-- Fixed Aimbot with Camera/Cursor modes and FOV circle visualization

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")

local player = Players.LocalPlayer

-- Clean up existing
pcall(function()
    if CoreGui:FindFirstChild("CerialsHub") then CoreGui.CerialsHub:Destroy() end
    if player.PlayerGui:FindFirstChild("CerialsHub") then player.PlayerGui.CerialsHub:Destroy() end
end)

-- === CORE SYSTEM ===
local Core = {
    gui = nil, connections = {}, toggleStates = {}, toggleButtons = {}, toggleFrames = {},
    keybinds = {
        speed = "None", fly = "None", esp = "None", noclip = "None", infJump = "None",
        nofall = "None", fullbright = "None", messageSpammer = "None", blockTrail = "None",
        aimbot = "None", speedActivation = "Space", gui = "RightControl"
    },
    originalWalkSpeed = 16, timerGui = nil, notificationGui = nil, coordinatesGui = nil,
    speedWasEnabledBeforeFly = false
}

-- Store original values
if player.Character and player.Character:FindFirstChild("Humanoid") then
    Core.originalWalkSpeed = player.Character.Humanoid.WalkSpeed
end

local originalLighting = {
    Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient
}

-- === ENHANCED AIMBOT MODULE ===
local AimbotModule = {
    enabled = false,
    onlyWhenPressed = true,
    activationButton = "MouseButton2", -- Right click
    smoothing = 0.2,
    ignoreTeammates = true,
    fov = 90,
    maxDistance = 1000,
    mode = "Camera", -- "Camera" or "Cursor"
    showFOV = false,
    fovColor = Color3.new(1, 1, 1),
    fovCircle = nil,
    fovGui = nil
}

function AimbotModule.createFOVCircle()
    if AimbotModule.fovGui then AimbotModule.fovGui:Destroy() end
    
    local fovGui = Instance.new("ScreenGui")
    fovGui.Name = "AimbotFOV"
    fovGui.ResetOnSpawn = false
    fovGui.DisplayOrder = 999997
    fovGui.IgnoreGuiInset = true
    fovGui.Parent = player:WaitForChild("PlayerGui")
    AimbotModule.fovGui = fovGui
    
    local fovCircle = Instance.new("Frame")
    fovCircle.Name = "FOVCircle"
    fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
    fovCircle.BackgroundTransparency = 1
    fovCircle.Parent = fovGui
    AimbotModule.fovCircle = fovCircle
    
    local circle = Instance.new("UIStroke")
    circle.Color = AimbotModule.fovColor
    circle.Thickness = 2
    circle.Transparency = 0.3
    circle.Parent = fovCircle
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = fovCircle
    
    AimbotModule.updateFOVCircle()
end

function AimbotModule.updateFOVCircle()
    if not AimbotModule.fovCircle then return end
    
    local camera = workspace.CurrentCamera
    local viewportSize = camera.ViewportSize
    local centerX, centerY = viewportSize.X / 2, viewportSize.Y / 2
    
    -- Convert FOV degrees to pixels (more accurate calculation)
    local fovRadians = math.rad(AimbotModule.fov)
    local fovPixels = math.tan(fovRadians / 2) * math.min(viewportSize.X, viewportSize.Y) / 2
    
    -- Update circle position and size
    AimbotModule.fovCircle.Position = UDim2.new(0, centerX, 0, centerY)
    AimbotModule.fovCircle.Size = UDim2.new(0, fovPixels * 2, 0, fovPixels * 2)
    AimbotModule.fovCircle.Visible = AimbotModule.showFOV and AimbotModule.enabled
end

function AimbotModule.updateFOVColor(color)
    AimbotModule.fovColor = color
    if AimbotModule.fovCircle then
        local stroke = AimbotModule.fovCircle:FindFirstChild("UIStroke")
        if stroke then stroke.Color = color end
    end
end

function AimbotModule.isTeammate(targetPlayer)
    if not AimbotModule.ignoreTeammates then return false end
    
    -- Basic team detection methods
    if player.Team and targetPlayer.Team then
        return player.Team == targetPlayer.Team
    end
    
    -- Check for team-based name colors
    if player.TeamColor and targetPlayer.TeamColor then
        return player.TeamColor == targetPlayer.TeamColor
    end
    
    return false
end

function AimbotModule.getClosestPlayer()
    local camera = workspace.CurrentCamera
    local closestPlayer = nil
    local shortestDistance = math.huge
    local viewportSize = camera.ViewportSize
    local centerPoint = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    
    -- Convert FOV to pixels for accurate detection
    local fovRadians = math.rad(AimbotModule.fov)
    local fovPixels = math.tan(fovRadians / 2) * math.min(viewportSize.X, viewportSize.Y) / 2
    
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer ~= player and targetPlayer.Character then
            local character = targetPlayer.Character
            local head = character:FindFirstChild("Head")
            local humanoid = character:FindFirstChild("Humanoid")
            
            if head and humanoid and humanoid.Health > 0 then
                if AimbotModule.isTeammate(targetPlayer) then continue end
                
                local headPos = head.Position
                local distance = (camera.CFrame.Position - headPos).Magnitude
                
                if distance <= AimbotModule.maxDistance then
                    local screenPos, onScreen = camera:WorldToViewportPoint(headPos)
                    
                    if onScreen and screenPos.Z > 0 then
                        local screenPoint = Vector2.new(screenPos.X, screenPos.Y)
                        local screenDistance = (screenPoint - centerPoint).Magnitude
                        
                        -- Check if target is within FOV circle
                        if screenDistance <= fovPixels and screenDistance < shortestDistance then
                            -- Enhanced visibility check
                            local rayOrigin = camera.CFrame.Position
                            local rayDirection = (headPos - rayOrigin).Unit * distance
                            
                            local raycastParams = RaycastParams.new()
                            raycastParams.FilterDescendantsInstances = {player.Character}
                            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                            
                            local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                            
                            -- Target is visible if ray hits the character or nothing
                            if not raycastResult or raycastResult.Instance:IsDescendantOf(character) then
                                closestPlayer = targetPlayer
                                shortestDistance = screenDistance
                            end
                        end
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

function AimbotModule.aimAtTarget(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    
    local camera = workspace.CurrentCamera
    local head = targetPlayer.Character:FindFirstChild("Head")
    if not head then return end
    
    local targetPos = head.Position
    
    if AimbotModule.mode == "Camera" then
        -- Camera mode: Move player's camera to look at target
        local currentCFrame = camera.CFrame
        local targetCFrame = CFrame.lookAt(currentCFrame.Position, targetPos)
        
        -- Apply smoothing
        local lerpedCFrame = currentCFrame:Lerp(targetCFrame, AimbotModule.smoothing)
        camera.CFrame = lerpedCFrame
        
    elseif AimbotModule.mode == "Cursor" then
        -- Cursor mode: Move mouse cursor to target position on screen
        local screenPos, onScreen = camera:WorldToViewportPoint(targetPos)
        
        if onScreen and screenPos.Z > 0 then
            -- Calculate smooth movement towards target
            local currentMousePos = UserInputService:GetMouseLocation()
            local targetMousePos = Vector2.new(screenPos.X, screenPos.Y)
            
            -- Smooth interpolation
            local smoothPos = currentMousePos:Lerp(targetMousePos, AimbotModule.smoothing)
            
            -- This requires mouse manipulation which isn't always available in Roblox
            -- Some executors support this, others don't
            pcall(function()
                if mousemoveabs then
                    mousemoveabs(smoothPos.X, smoothPos.Y)
                elseif mouse1move then
                    mouse1move(smoothPos.X, smoothPos.Y)
                end
            end)
        end
    end
end

function AimbotModule.isActivationPressed()
    if not AimbotModule.onlyWhenPressed then return true end
    
    if AimbotModule.activationButton == "MouseButton1" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    elseif AimbotModule.activationButton == "MouseButton2" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    end
    
    return false
end

function AimbotModule.toggle(enabled)
    AimbotModule.enabled = enabled
    
    if Core.connections.aimbot then
        Core.connections.aimbot:Disconnect()
        Core.connections.aimbot = nil
    end
    
    if Core.connections.fovUpdate then
        Core.connections.fovUpdate:Disconnect()
        Core.connections.fovUpdate = nil
    end
    
    if enabled then
        AimbotModule.createFOVCircle()
        
        Core.connections.aimbot = RunService.Heartbeat:Connect(function()
            if AimbotModule.isActivationPressed() then
                local target = AimbotModule.getClosestPlayer()
                if target then
                    AimbotModule.aimAtTarget(target)
                end
            end
        end)
        
        -- Update FOV circle continuously
        Core.connections.fovUpdate = RunService.Heartbeat:Connect(function()
            AimbotModule.updateFOVCircle()
        end)
    else
        if AimbotModule.fovGui then
            AimbotModule.fovGui:Destroy()
            AimbotModule.fovGui = nil
            AimbotModule.fovCircle = nil
        end
    end
end

-- === ANTICHEAT SYSTEM ===
local AntiCheat = {
    enabled = false, notificationColor = Color3.fromRGB(255, 100, 100),
    selfColor = Color3.fromRGB(100, 255, 100), customMultiplier = 1.0,
    detectSelf = false, detectOthers = true,
    
    detections = { speed = false, fly = false, noclip = false, teleport = false },
    
    serverSettings = {
        walkSpeed = StarterPlayer.CharacterWalkSpeed or 16,
        jumpPower = StarterPlayer.CharacterJumpPower or 50,
        jumpHeight = StarterPlayer.CharacterJumpHeight or 7.2,
        useJumpPower = StarterPlayer.CharacterUseJumpPower
    },
    
    playerData = {}, totalDetections = 0, playerDetections = {},
    notificationContainer = nil
}

function AntiCheat.calculateThresholds()
    local base = AntiCheat.serverSettings.walkSpeed
    return {
        maxHorizontalSpeed = base * 1.8 * AntiCheat.customMultiplier,
        maxVerticalSpeed = (AntiCheat.serverSettings.useJumpPower and AntiCheat.serverSettings.jumpPower * 1.5 or 75) * AntiCheat.customMultiplier,
        maxAirTime = 15 * AntiCheat.customMultiplier,
        minGroundDistance = 25,
        maxTeleportDistance = 1.2 * AntiCheat.customMultiplier,
        rayDistance = 1.0
    }
end

function AntiCheat.createNotificationGUI()
    if AntiCheat.notificationContainer then AntiCheat.notificationContainer:Destroy() end
    
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "AntiCheatNotifications"
    notifGui.ResetOnSpawn = false
    notifGui.DisplayOrder = 999998
    notifGui.IgnoreGuiInset = true
    notifGui.Parent = player:WaitForChild("PlayerGui")
    
    AntiCheat.notificationContainer = Instance.new("Frame")
    AntiCheat.notificationContainer.Size = UDim2.new(0, 400, 1, 0)
    AntiCheat.notificationContainer.Position = UDim2.new(0, 20, 0, 60) -- Moved down 40 pixels
    AntiCheat.notificationContainer.BackgroundTransparency = 1
    AntiCheat.notificationContainer.Parent = notifGui
end

function AntiCheat.createNotification(targetPlayer, violationType, details)
    local isSelf = targetPlayer == player
    
    if not AntiCheat.enabled or not AntiCheat.detections[violationType:lower()] or
       (isSelf and not AntiCheat.detectSelf) or (not isSelf and not AntiCheat.detectOthers) or
       not AntiCheat.notificationContainer then return end
    
    local playerName = targetPlayer.Name
    if not AntiCheat.playerDetections[playerName] then AntiCheat.playerDetections[playerName] = {} end
    if not AntiCheat.playerDetections[playerName][violationType] then AntiCheat.playerDetections[playerName][violationType] = 0 end
    
    AntiCheat.playerDetections[playerName][violationType] = AntiCheat.playerDetections[playerName][violationType] + 1
    AntiCheat.totalDetections = AntiCheat.totalDetections + 1
    
    local notificationId = playerName .. "_" .. violationType
    local existingNotif = AntiCheat.notificationContainer:FindFirstChild(notificationId)
    
    if existingNotif then
        local countLabel = existingNotif:FindFirstChild("CountLabel")
        if countLabel then countLabel.Text = "x" .. AntiCheat.playerDetections[playerName][violationType] end
        return
    end
    
    local color = isSelf and AntiCheat.selfColor or AntiCheat.notificationColor
    
    local notification = Instance.new("Frame")
    notification.Name = notificationId
    notification.Size = UDim2.new(1, 0, 0, 65)
    notification.Position = UDim2.new(0, 0, 0, #AntiCheat.notificationContainer:GetChildren() * 70)
    notification.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    notification.BorderSizePixel = 0
    notification.ZIndex = 99998
    notification.Parent = AntiCheat.notificationContainer
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 6)
    notifCorner.Parent = notification
    
    local notifStroke = Instance.new("UIStroke")
    notifStroke.Color = color
    notifStroke.Thickness = 2
    notifStroke.Parent = notification
    
    local playerLabel = Instance.new("TextLabel")
    playerLabel.Size = UDim2.new(0.7, 0, 0, 22)
    playerLabel.Position = UDim2.new(0, 8, 0, 5)
    playerLabel.BackgroundTransparency = 1
    playerLabel.Text = playerName .. (isSelf and " (You) - " or " - ") .. violationType .. " Detection"
    playerLabel.TextColor3 = color
    playerLabel.TextSize = 14
    playerLabel.Font = Enum.Font.GothamBold
    playerLabel.TextXAlignment = Enum.TextXAlignment.Left
    playerLabel.ZIndex = 99998
    playerLabel.Parent = notification
    
    local countLabel = Instance.new("TextLabel")
    countLabel.Name = "CountLabel"
    countLabel.Size = UDim2.new(0.3, 0, 0, 22)
    countLabel.Position = UDim2.new(0.7, 0, 0, 5)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = "x" .. AntiCheat.playerDetections[playerName][violationType]
    countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    countLabel.TextSize = 16
    countLabel.Font = Enum.Font.GothamBold
    countLabel.TextXAlignment = Enum.TextXAlignment.Right
    countLabel.ZIndex = 99998
    countLabel.Parent = notification
    
    local detailsLabel = Instance.new("TextLabel")
    detailsLabel.Size = UDim2.new(1, -16, 0, 35)
    detailsLabel.Position = UDim2.new(0, 8, 0, 25)
    detailsLabel.BackgroundTransparency = 1
    detailsLabel.Text = details
    detailsLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    detailsLabel.TextSize = 12
    detailsLabel.Font = Enum.Font.GothamBold
    detailsLabel.TextXAlignment = Enum.TextXAlignment.Left
    detailsLabel.TextWrapped = true
    detailsLabel.ZIndex = 99998
    detailsLabel.Parent = notification
    
    notification.Position = UDim2.new(-1, 0, 0, (#AntiCheat.notificationContainer:GetChildren() - 1) * 70)
    TweenService:Create(notification, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
        Position = UDim2.new(0, 0, 0, (#AntiCheat.notificationContainer:GetChildren() - 1) * 70)
    }):Play()
    
    spawn(function()
        wait(15)
        if notification and notification.Parent then
            TweenService:Create(notification, TweenInfo.new(0.3), {
                Position = UDim2.new(-1, 0, 0, notification.Position.Y.Offset),
                BackgroundTransparency = 1
            }):Play()
            wait(0.3)
            if notification and notification.Parent then notification:Destroy() end
        end
    end)
end

function AntiCheat.initPlayerData(targetPlayer)
    if targetPlayer == player and not AntiCheat.detectSelf then return end
    AntiCheat.playerData[targetPlayer] = {
        lastPosition = nil, lastTime = tick(), airTime = 0, lastGroundTime = tick()
    }
end

function AntiCheat.checkSpeed(targetPlayer, character, humanoid, rootPart)
    if not AntiCheat.enabled or not AntiCheat.detections.speed then return end
    if targetPlayer == player and not AntiCheat.detectSelf then return end
    if targetPlayer ~= player and not AntiCheat.detectOthers then return end
    
    local thresholds = AntiCheat.calculateThresholds()
    local velocity = rootPart.AssemblyLinearVelocity
    local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
    local horizontalSpeed = horizontalVelocity.Magnitude
    local verticalSpeed = velocity.Y
    
    if horizontalSpeed > thresholds.maxHorizontalSpeed then
        AntiCheat.createNotification(targetPlayer, "Speed",
            string.format("Horizontal: %.1f > %.1f max", horizontalSpeed, thresholds.maxHorizontalSpeed))
    end
    
    if verticalSpeed > thresholds.maxVerticalSpeed then
        AntiCheat.createNotification(targetPlayer, "Speed",
            string.format("Vertical: %.1f > %.1f max", verticalSpeed, thresholds.maxVerticalSpeed))
    end
end

function AntiCheat.checkFly(targetPlayer, character, humanoid, rootPart)
    if not AntiCheat.enabled or not AntiCheat.detections.fly then return end
    if targetPlayer == player and not AntiCheat.detectSelf then return end
    if targetPlayer ~= player and not AntiCheat.detectOthers then return end
    
    local thresholds = AntiCheat.calculateThresholds()
    local data = AntiCheat.playerData[targetPlayer]
    local currentTime = tick()
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    
    local rayResult = workspace:Raycast(rootPart.Position, Vector3.new(0, -100, 0), raycastParams)
    local groundDistance = rayResult and (rootPart.Position.Y - rayResult.Position.Y) or 100
    local isOnGround = rayResult and groundDistance < 8
    
    if isOnGround then
        data.airTime = 0
        data.lastGroundTime = currentTime
    else
        data.airTime = data.airTime + 0.1
    end
    
    if data.airTime > thresholds.maxAirTime and groundDistance > thresholds.minGroundDistance then
        AntiCheat.createNotification(targetPlayer, "Fly",
            string.format("Airtime: %.1fs at %.1f studs high", data.airTime, groundDistance))
        data.airTime = 0
    end
end

function AntiCheat.checkNoclip(targetPlayer, character, humanoid, rootPart)
    if not AntiCheat.enabled or not AntiCheat.detections.noclip then return end
    if targetPlayer == player and not AntiCheat.detectSelf then return end
    if targetPlayer ~= player and not AntiCheat.detectOthers then return end
    
    local thresholds = AntiCheat.calculateThresholds()
    local data = AntiCheat.playerData[targetPlayer]
    
    if data.lastPosition then
        local direction = (rootPart.Position - data.lastPosition).Unit
        local distance = (rootPart.Position - data.lastPosition).Magnitude
        
        if distance > 0.8 then
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {character}
            
            local rayResult = workspace:Raycast(data.lastPosition, direction * thresholds.rayDistance, raycastParams)
            
            if rayResult and rayResult.Instance.CanCollide then
                local hitCharacter = rayResult.Instance:FindFirstAncestorWhichIsA("Model")
                if hitCharacter and hitCharacter:FindFirstChild("Humanoid") then
                    local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)
                    if hitPlayer and hitPlayer ~= targetPlayer then return end
                end
                
                AntiCheat.createNotification(targetPlayer, "Noclip",
                    string.format("Moved through %s", rayResult.Instance.Name))
            end
        end
    end
    
    data.lastPosition = rootPart.Position
end

function AntiCheat.checkTeleport(targetPlayer, character, humanoid, rootPart)
    if not AntiCheat.enabled or not AntiCheat.detections.teleport then return end
    if targetPlayer == player and not AntiCheat.detectSelf then return end
    if targetPlayer ~= player and not AntiCheat.detectOthers then return end
    
    local thresholds = AntiCheat.calculateThresholds()
    local data = AntiCheat.playerData[targetPlayer]
    
    if data.lastPosition then
        local horizontalDistance = math.sqrt(
            (rootPart.Position.X - data.lastPosition.X)^2 + 
            (rootPart.Position.Z - data.lastPosition.Z)^2
        )
        
        if horizontalDistance > thresholds.maxTeleportDistance then
            AntiCheat.createNotification(targetPlayer, "Teleport",
                string.format("Instant movement: %.2f studs", horizontalDistance))
        end
    end
end

function AntiCheat.monitorPlayers()
    if not AntiCheat.enabled then return end
    
    local hasActiveDetection = AntiCheat.detections.speed or AntiCheat.detections.fly or 
                              AntiCheat.detections.noclip or AntiCheat.detections.teleport
    if not hasActiveDetection then return end
    
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if (targetPlayer == player and AntiCheat.detectSelf) or (targetPlayer ~= player and AntiCheat.detectOthers) then
            if targetPlayer.Character then
                local character = targetPlayer.Character
                local humanoid = character:FindFirstChild("Humanoid")
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                
                if humanoid and rootPart then
                    if not AntiCheat.playerData[targetPlayer] then
                        AntiCheat.initPlayerData(targetPlayer)
                    end
                    
                    AntiCheat.checkSpeed(targetPlayer, character, humanoid, rootPart)
                    AntiCheat.checkFly(targetPlayer, character, humanoid, rootPart)
                    AntiCheat.checkNoclip(targetPlayer, character, humanoid, rootPart)
                    AntiCheat.checkTeleport(targetPlayer, character, humanoid, rootPart)
                end
            end
        end
    end
end

function AntiCheat.toggle(enabled)
    AntiCheat.enabled = enabled
    
    if Core.connections.anticheat then
        Core.connections.anticheat:Disconnect()
        Core.connections.anticheat = nil
    end
    
    if enabled then
        AntiCheat.createNotificationGUI()
        Core.connections.anticheat = RunService.Heartbeat:Connect(function()
            wait(0.1)
            AntiCheat.monitorPlayers()
        end)
    else
        if AntiCheat.notificationContainer and AntiCheat.notificationContainer.Parent then
            AntiCheat.notificationContainer.Parent:Destroy()
        end
    end
end

-- === COORDINATES DISPLAY ===
local CoordinatesModule = {
    enabled = false,
    gui = nil,
    updateRate = 0.1,
    lastUpdateTime = 0
}

function CoordinatesModule.createGUI()
    if CoordinatesModule.gui then CoordinatesModule.gui:Destroy() end
    
    local coordGui = Instance.new("ScreenGui")
    coordGui.Name = "CoordinatesDisplay"
    coordGui.ResetOnSpawn = false
    coordGui.DisplayOrder = 999998
    coordGui.IgnoreGuiInset = true
    coordGui.Parent = player:WaitForChild("PlayerGui")
    Core.coordinatesGui = coordGui
    
    local coordFrame = Instance.new("Frame")
    coordFrame.Name = "CoordFrame"
    coordFrame.Size = UDim2.new(0, 130, 0, 80)
    coordFrame.Position = UDim2.new(0, 20, 0, 20)
    coordFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    coordFrame.BorderSizePixel = 0
    coordFrame.ZIndex = 99998
    coordFrame.Parent = coordGui
    
    local coordCorner = Instance.new("UICorner")
    coordCorner.CornerRadius = UDim.new(0, 6)
    coordCorner.Parent = coordFrame
    
    local coordStroke = Instance.new("UIStroke")
    coordStroke.Color = Color3.fromRGB(86, 101, 245)
    coordStroke.Thickness = 2
    coordStroke.Parent = coordFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -10, 0, 20)
    titleLabel.Position = UDim2.new(0, 5, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "COORDINATES"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 12
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.ZIndex = 99998
    titleLabel.Parent = coordFrame
    
    local coordLabel = Instance.new("TextLabel")
    coordLabel.Name = "CoordLabel"
    coordLabel.Size = UDim2.new(1, -10, 0, 50)
    coordLabel.Position = UDim2.new(0, 5, 0, 25)
    coordLabel.BackgroundTransparency = 1
    coordLabel.Text = "X: 0\nY: 0\nZ: 0"
    coordLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    coordLabel.TextSize = 14
    coordLabel.Font = Enum.Font.GothamBold
    coordLabel.TextXAlignment = Enum.TextXAlignment.Left
    coordLabel.ZIndex = 99998
    coordLabel.Parent = coordFrame
    
    -- Make draggable
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    coordFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = coordFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            coordFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    CoordinatesModule.gui = coordGui
end

function CoordinatesModule.updateCoordinates()
    if not CoordinatesModule.enabled or not CoordinatesModule.gui then return end
    
    local currentTime = tick()
    if currentTime - CoordinatesModule.lastUpdateTime < CoordinatesModule.updateRate then return end
    
    local coordFrame = CoordinatesModule.gui:FindFirstChild("CoordFrame")
    if not coordFrame then return end
    
    local coordLabel = coordFrame:FindFirstChild("CoordLabel")
    if not coordLabel then return end
    
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local pos = player.Character.HumanoidRootPart.Position
        coordLabel.Text = string.format("X: %.1f\nY: %.1f\nZ: %.1f", pos.X, pos.Y, pos.Z)
    else
        coordLabel.Text = "X: N/A\nY: N/A\nZ: N/A"
    end
    
    CoordinatesModule.lastUpdateTime = currentTime
end

function CoordinatesModule.toggle(enabled)
    CoordinatesModule.enabled = enabled
    
    if Core.connections.coordinates then
        Core.connections.coordinates:Disconnect()
        Core.connections.coordinates = nil
    end
    
    if enabled then
        CoordinatesModule.createGUI()
        CoordinatesModule.lastUpdateTime = 0
        Core.connections.coordinates = RunService.Heartbeat:Connect(function()
            CoordinatesModule.updateCoordinates()
        end)
    else
        if CoordinatesModule.gui then
            CoordinatesModule.gui:Destroy()
            CoordinatesModule.gui = nil
        end
    end
end

-- === VISUAL TOGGLE STATE MANAGER ===
local ToggleManager = {}

function ToggleManager.updateVisualState(toggleName, enabled)
    local toggleFrame = Core.toggleFrames[toggleName]
    if not toggleFrame then return end
    
    local toggle = toggleFrame:FindFirstChild("ToggleButton")
    if not toggle then return end
    
    Core.toggleStates[toggleName] = enabled
    
    if enabled then
        toggle.BackgroundColor3 = Color3.fromRGB(86, 101, 245)
        toggle.Text = "ON"
    else
        toggle.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        toggle.Text = "OFF"
    end
end

function ToggleManager.disableToggle(toggleName)
    if Core.toggleStates[toggleName] then
        local callback = Core.toggleButtons[toggleName]
        if callback then callback() end
    end
end

-- === ENHANCED CLEANUP SYSTEM ===
local CleanupSystem = {}

function CleanupSystem.removeAllBodyObjects(rootPart)
    if not rootPart then return end
    
    local objectsToRemove = {
        "FlyVelocity", "OscFly_BodyVelocity", "OscFly_BodyPosition", "OscFly_BodyGyro",
        "BoostVelocity", "VelocitySpeed", "BodyVelocity", "BodyPosition", "BodyAngularVelocity",
        "PenabloxBypassVelocity"
    }
    
    for _, objName in pairs(objectsToRemove) do
        local obj = rootPart:FindFirstChild(objName)
        if obj then obj:Destroy() end
    end
    
    for _, child in pairs(rootPart:GetChildren()) do
        if child:IsA("BodyVelocity") or child:IsA("BodyPosition") or child:IsA("BodyAngularVelocity") or child:IsA("BodyGyro") then
            child:Destroy()
        end
    end
end

function CleanupSystem.fullCharacterRestore()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local character = player.Character
    local rootPart = character.HumanoidRootPart
    local humanoid = character:FindFirstChild("Humanoid")
    
    CleanupSystem.removeAllBodyObjects(rootPart)
    rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Parent == character then
            part.CanCollide = true
        end
    end
    
    if humanoid then
        humanoid.AutoRotate = true
        humanoid.PlatformStand = false
        humanoid.WalkSpeed = Core.originalWalkSpeed
        
        pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Running) end)
        
        spawn(function()
            wait(0.1)
            if humanoid and humanoid.Parent then
                pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Freefall) end)
                wait(0.1)
                pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Running) end)
            end
        end)
    end
end

-- === BLOCK TRAIL MODULE ===
local BlockTrailModule = {
    enabled = false, lastPosition = nil, blocks = {}, trailDistance = 1.0,
    blockSize = Vector3.new(1, 1, 1), blockColor = BrickColor.new("Bright blue"), despawnTime = 0.5
}

function BlockTrailModule.createTrailBlock(position)
    local block = Instance.new("Part")
    block.Name = "TrailBlock"
    block.Size = BlockTrailModule.blockSize
    block.Material = Enum.Material.Neon
    block.BrickColor = BlockTrailModule.blockColor
    block.CanCollide = false
    block.Anchored = true
    block.CFrame = CFrame.new(position)
    block.Parent = workspace
    
    table.insert(BlockTrailModule.blocks, block)
    
    spawn(function()
        wait(BlockTrailModule.despawnTime)
        if block and block.Parent then
            local fadeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local fadeTween = TweenService:Create(block, fadeInfo, {
                Transparency = 1, Size = Vector3.new(0.1, 0.1, 0.1)
            })
            fadeTween:Play()
            
            fadeTween.Completed:Connect(function()
                if block and block.Parent then block:Destroy() end
                for i, v in pairs(BlockTrailModule.blocks) do
                    if v == block then
                        table.remove(BlockTrailModule.blocks, i)
                        break
                    end
                end
            end)
        end
    end)
    
    return block
end

function BlockTrailModule.clearAllBlocks()
    for _, block in pairs(BlockTrailModule.blocks) do
        if block and block.Parent then block:Destroy() end
    end
    BlockTrailModule.blocks = {}
end

function BlockTrailModule.updateTrail()
    local character = player.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local currentPosition = rootPart.Position
    
    if BlockTrailModule.lastPosition then
        local distance = (currentPosition - BlockTrailModule.lastPosition).Magnitude
        
        if distance >= BlockTrailModule.trailDistance then
            local lookDirection = rootPart.CFrame.LookVector
            local behindPosition = currentPosition - (lookDirection * 2)
            
            BlockTrailModule.createTrailBlock(behindPosition)
            BlockTrailModule.lastPosition = currentPosition
        end
    else
        BlockTrailModule.lastPosition = currentPosition
    end
end

function BlockTrailModule.toggle(enabled)
    BlockTrailModule.enabled = enabled
    
    if Core.connections.blockTrail then
        Core.connections.blockTrail:Disconnect()
        Core.connections.blockTrail = nil
    end
    
    if enabled then
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            BlockTrailModule.lastPosition = player.Character.HumanoidRootPart.Position
        end
        
        Core.connections.blockTrail = RunService.Heartbeat:Connect(function()
            BlockTrailModule.updateTrail()
        end)
    else
        BlockTrailModule.clearAllBlocks()
        BlockTrailModule.lastPosition = nil
    end
end

-- === MESSAGE SPAMMER SYSTEM ===
local MessageSpammer = {
    mode = "New", enabled = false, message = "Cerial Hub On Top", delay = 0.5,
    lastSent = 0, randomization = 3
}

function MessageSpammer.generateRandomString(length)
    if length <= 0 then return "" end
    local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    local result = ""
    for i = 1, length do
        local randIndex = math.random(1, #chars)
        result = result .. string.sub(chars, randIndex, randIndex)
    end
    return result
end

function MessageSpammer.sendMessage(message)
    local finalMessage = message
    if MessageSpammer.randomization > 0 then
        finalMessage = message .. " " .. MessageSpammer.generateRandomString(MessageSpammer.randomization)
    end
    
    if MessageSpammer.mode == "Old" then
        pcall(function()
            local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if chatEvents and chatEvents:FindFirstChild("SayMessageRequest") then
                chatEvents.SayMessageRequest:FireServer(finalMessage, "All")
            end
        end)
    elseif MessageSpammer.mode == "New" then
        pcall(function()
            local chatInputBar = TextChatService:FindFirstChild("ChatInputBarConfiguration")
            if chatInputBar and chatInputBar.TargetTextChannel then
                chatInputBar.TargetTextChannel:SendAsync(finalMessage)
            end
        end)
    elseif MessageSpammer.mode == "Penablox" then
        pcall(function()
            ReplicatedStorage:WaitForChild("ChatEvent"):FireServer(finalMessage)
        end)
    end
end

function MessageSpammer.toggle(enabled)
    MessageSpammer.enabled = enabled
    
    if Core.connections.messageSpammer then
        Core.connections.messageSpammer:Disconnect()
        Core.connections.messageSpammer = nil
    end
    
    if enabled then
        Core.connections.messageSpammer = RunService.Heartbeat:Connect(function()
            local currentTime = tick()
            if currentTime - MessageSpammer.lastSent >= MessageSpammer.delay then
                MessageSpammer.sendMessage(MessageSpammer.message)
                MessageSpammer.lastSent = currentTime
            end
        end)
    end
end

-- === GAME EXPLOIT SYSTEM WITH SEMI WALLBANG ===
local GameExploits = {
    currentGame = "None", penabloxInfAmmo = false, penabloxSemiWallbang = false,
    wallSystem = {}, fakeWallsCreated = false
}

function GameExploits.penabloxAmmoLoop()
    if Core.connections.penabloxAmmo then
        Core.connections.penabloxAmmo:Disconnect()
        Core.connections.penabloxAmmo = nil
    end
    
    if GameExploits.penabloxInfAmmo then
        Core.connections.penabloxAmmo = RunService.Heartbeat:Connect(function()
            pcall(function()
                if game.ReplicatedStorage:FindFirstChild("Reload") then
                    game.ReplicatedStorage.Reload:FireServer()
                end
            end)
            wait(0.1)
        end)
    end
end

function GameExploits.findWalls()
    local walls = {}
    local mapFolder = workspace:FindFirstChild("map") or workspace:FindFirstChild("Map") or workspace
    
    for _, obj in pairs(mapFolder:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Wall" then
            local maxDim = math.max(obj.Size.X, obj.Size.Y, obj.Size.Z)
            if maxDim <= 100 then
                table.insert(walls, obj)
            end
        end
    end
    
    return walls
end

function GameExploits.createFakeWallSystem()
    local walls = GameExploits.findWalls()
    local totalCreated = 0
    
    for _, wall in pairs(walls) do
        if wall and wall.Parent then
            local originalPos = wall.Position
            local originalSize = wall.Size
            local originalRot = wall.Rotation
            local groundLevel = originalPos.Y - (originalSize.Y / 2)
            
            local bottomWall = Instance.new("Part")
            bottomWall.Name = "SwapWall_Bottom"
            bottomWall.Size = Vector3.new(originalSize.X, 3, originalSize.Z)
            bottomWall.Rotation = originalRot
            bottomWall.Material = Enum.Material.ForceField
            bottomWall.Color = Color3.fromRGB(255, 50, 50)
            bottomWall.Transparency = 0.7
            bottomWall.CanCollide = true
            bottomWall.Anchored = true
            bottomWall.Parent = workspace
            
            local remainingHeight = originalSize.Y - 6
            local topWall = nil
            
            if remainingHeight > 0 then
                topWall = Instance.new("Part")
                topWall.Name = "SwapWall_Top"
                topWall.Size = Vector3.new(originalSize.X, remainingHeight, originalSize.Z)
                topWall.Rotation = originalRot
                topWall.Material = Enum.Material.ForceField
                topWall.Color = Color3.fromRGB(50, 50, 255)
                topWall.Transparency = 0.7
                topWall.CanCollide = true
                topWall.Anchored = true
                topWall.Parent = workspace
            end
            
            GameExploits.wallSystem[wall] = {
                originalPosition = originalPos,
                hiddenPosition = originalPos - Vector3.new(0, 100, 0),
                bottomWall = bottomWall,
                topWall = topWall,
                groundLevel = groundLevel
            }
            
            bottomWall.Position = GameExploits.wallSystem[wall].hiddenPosition
            if topWall then
                topWall.Position = GameExploits.wallSystem[wall].hiddenPosition - Vector3.new(0, 10, 0)
            end
            
            totalCreated = totalCreated + 1
        end
    end
    
    GameExploits.fakeWallsCreated = true
    return totalCreated
end

function GameExploits.enableWallhack()
    if not GameExploits.fakeWallsCreated then return 0 end
    
    local swappedCount = 0
    
    for originalWall, data in pairs(GameExploits.wallSystem) do
        if originalWall and originalWall.Parent then
            originalWall.Position = data.hiddenPosition
            
            local groundLevel = data.groundLevel
            
            data.bottomWall.Position = Vector3.new(
                data.originalPosition.X,
                groundLevel + 1.5,
                data.originalPosition.Z
            )
            
            if data.topWall then
                local topWallHeight = data.topWall.Size.Y
                data.topWall.Position = Vector3.new(
                    data.originalPosition.X,
                    groundLevel + 6 + (topWallHeight / 2),
                    data.originalPosition.Z
                )
            end
            
            swappedCount = swappedCount + 1
        end
    end
    
    return swappedCount
end

function GameExploits.disableWallhack()
    if not GameExploits.fakeWallsCreated then return 0 end
    
    local swappedCount = 0
    
    for originalWall, data in pairs(GameExploits.wallSystem) do
        if originalWall and originalWall.Parent then
            originalWall.Position = data.originalPosition
            
            data.bottomWall.Position = data.hiddenPosition
            if data.topWall then
                data.topWall.Position = data.hiddenPosition - Vector3.new(0, 10, 0)
            end
            
            swappedCount = swappedCount + 1
        end
    end
    
    return swappedCount
end

function GameExploits.cleanupWallSystem()
    local cleanedCount = 0
    
    for originalWall, data in pairs(GameExploits.wallSystem) do
        if originalWall and originalWall.Parent then
            originalWall.Position = data.originalPosition
        end
        
        if data.bottomWall and data.bottomWall.Parent then
            data.bottomWall:Destroy()
            cleanedCount = cleanedCount + 1
        end
        
        if data.topWall and data.topWall.Parent then
            data.topWall:Destroy()
            cleanedCount = cleanedCount + 1
        end
    end
    
    GameExploits.wallSystem = {}
    GameExploits.fakeWallsCreated = false
    
    return cleanedCount
end

function GameExploits.toggleSemiWallbang(enabled)
    GameExploits.penabloxSemiWallbang = enabled
    
    if enabled then
        if not GameExploits.fakeWallsCreated then
            local created = GameExploits.createFakeWallSystem()
            if created > 0 then
                GameExploits.enableWallhack()
            else
                GameExploits.penabloxSemiWallbang = false
                return false
            end
        else
            GameExploits.enableWallhack()
        end
    else
        GameExploits.disableWallhack()
    end
    
    return true
end

-- === NOTIFICATION SYSTEM ===
local NotificationSystem = {
    position = "Bottom Right",
    notifications = {}
}

function NotificationSystem.createNotificationGUI()
    if Core.notificationGui then
        Core.notificationGui:Destroy()
    end
    
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "NotificationGui"
    notifGui.ResetOnSpawn = false
    notifGui.DisplayOrder = 999999
    notifGui.IgnoreGuiInset = true
    notifGui.Parent = player:WaitForChild("PlayerGui")
    Core.notificationGui = notifGui
end

function NotificationSystem.getPosition()
    local positions = {
        ["Bottom Right"] = UDim2.new(1, -220, 1, -80),
        ["Bottom Left"] = UDim2.new(0, 20, 1, -80),
        ["Top Right"] = UDim2.new(1, -220, 0, 80),
        ["Top Left"] = UDim2.new(0, 20, 0, 80)
    }
    return positions[NotificationSystem.position] or positions["Bottom Right"]
end

function NotificationSystem.createNotification(title, message, duration)
    if not Core.notificationGui then
        NotificationSystem.createNotificationGUI()
    end
    
    duration = duration or 3
    
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 200, 0, 60)
    notif.Position = NotificationSystem.getPosition()
    notif.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    notif.BorderSizePixel = 0
    notif.ZIndex = 99999
    notif.Parent = Core.notificationGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = notif
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(86, 101, 245)
    stroke.Thickness = 1
    stroke.Parent = notif
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -10, 0, 20)
    titleLabel.Position = UDim2.new(0, 5, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 12
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 99999
    titleLabel.Parent = notif
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -10, 0, 30)
    messageLabel.Position = UDim2.new(0, 5, 0, 25)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    messageLabel.TextSize = 10
    messageLabel.Font = Enum.Font.GothamBold
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextWrapped = true
    messageLabel.ZIndex = 99999
    messageLabel.Parent = notif
    
    notif.Position = notif.Position + UDim2.new(0, 220, 0, 0)
    TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = NotificationSystem.getPosition()
    }):Play()
    
    spawn(function()
        wait(duration)
        TweenService:Create(notif, TweenInfo.new(0.3), {
            Position = notif.Position + UDim2.new(0, 220, 0, 0),
            BackgroundTransparency = 1
        }):Play()
        wait(0.3)
        notif:Destroy()
    end)
end

function NotificationSystem.showToggleNotification(name, enabled)
    spawn(function()
        local status = enabled and "Enabled" or "Disabled"
        local message = name .. " has been " .. status:lower()
        NotificationSystem.createNotification("Cerials Hub", message, 2)
    end)
end

-- === BEDWARS TIMER SYSTEM ===
local BedwarsTimer = {
    timeLeft = 2.0, totalTime = 2.0, active = false, showTimer = false,
    timerBar = nil, timerLabel = nil, cooldownActive = false, cooldownTime = 3.0,
    controlsFrozen = false
}

function BedwarsTimer.createTimerGUI()
    if Core.timerGui then Core.timerGui:Destroy() end
    
    local timerGui = Instance.new("ScreenGui")
    timerGui.Name = "BedwarsTimer"
    timerGui.ResetOnSpawn = false
    timerGui.DisplayOrder = 999999
    timerGui.IgnoreGuiInset = true
    timerGui.Parent = player:WaitForChild("PlayerGui")
    Core.timerGui = timerGui
    
    local timerFrame = Instance.new("Frame")
    timerFrame.Name = "TimerFrame"
    timerFrame.Size = UDim2.new(0, 200, 0, 60)
    timerFrame.Position = UDim2.new(0.5, -100, 0.85, -100)
    timerFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    timerFrame.BorderSizePixel = 0
    timerFrame.ZIndex = 99999
    timerFrame.Parent = timerGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = timerFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(86, 101, 245)
    stroke.Thickness = 1
    stroke.Parent = timerFrame
    
    local timerBar = Instance.new("Frame")
    timerBar.Size = UDim2.new(1, -6, 0, 6)
    timerBar.Position = UDim2.new(0, 3, 0, 48)
    timerBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    timerBar.BorderSizePixel = 0
    timerBar.ZIndex = 99999
    timerBar.Parent = timerFrame
    BedwarsTimer.timerBar = timerBar
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 2)
    barCorner.Parent = timerBar
    
    local timerFill = Instance.new("Frame")
    timerFill.Name = "Fill"
    timerFill.Size = UDim2.new(1, 0, 1, 0)
    timerFill.BackgroundColor3 = Color3.fromRGB(86, 101, 245)
    timerFill.BorderSizePixel = 0
    timerFill.ZIndex = 99999
    timerFill.Parent = timerBar
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 2)
    fillCorner.Parent = timerFill
    
    local timerLabel = Instance.new("TextLabel")
    timerLabel.Size = UDim2.new(1, 0, 0, 20)
    timerLabel.Position = UDim2.new(0, 0, 0, 5)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Text = "Fly Time: 2.0s"
    timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    timerLabel.TextSize = 12
    timerLabel.Font = Enum.Font.GothamBold
    timerLabel.TextXAlignment = Enum.TextXAlignment.Center
    timerLabel.ZIndex = 99999
    timerLabel.Parent = timerFrame
    BedwarsTimer.timerLabel = timerLabel
    
    timerFrame.Visible = BedwarsTimer.showTimer
end

function BedwarsTimer.startCooldown()
    BedwarsTimer.cooldownActive = true
    BedwarsTimer.cooldownTime = 3.0
    
    if BedwarsTimer.timerLabel then
        BedwarsTimer.timerLabel.Text = "Cooldown: 3.0s"
    end
    
    if BedwarsTimer.timerBar and BedwarsTimer.timerBar:FindFirstChild("Fill") then
        BedwarsTimer.timerBar.Fill.BackgroundColor3 = Color3.fromRGB(245, 166, 35)
    end
    
    if Core.connections.cooldownTimer then
        Core.connections.cooldownTimer:Disconnect()
    end
    
    Core.connections.cooldownTimer = RunService.Heartbeat:Connect(function(dt)
        BedwarsTimer.cooldownTime = BedwarsTimer.cooldownTime - dt
        
        if BedwarsTimer.timerLabel then
            BedwarsTimer.timerLabel.Text = "Cooldown: " .. string.format("%.1f", math.max(0, BedwarsTimer.cooldownTime)) .. "s"
        end
        
        if BedwarsTimer.timerBar and BedwarsTimer.timerBar:FindFirstChild("Fill") then
            local percentage = 1 - (BedwarsTimer.cooldownTime / 3.0)
            BedwarsTimer.timerBar.Fill.Size = UDim2.new(percentage, 0, 1, 0)
        end
        
        if BedwarsTimer.cooldownTime <= 0 then
            BedwarsTimer.cooldownActive = false
            if Core.connections.cooldownTimer then
                Core.connections.cooldownTimer:Disconnect()
                Core.connections.cooldownTimer = nil
            end
            BedwarsTimer.reset()
        end
    end)
end

function BedwarsTimer.startTimer()
    if Core.connections.bedwarsTimer then
        Core.connections.bedwarsTimer:Disconnect()
    end
    
    Core.connections.bedwarsTimer = RunService.Heartbeat:Connect(function(dt)
        if not BedwarsTimer.active then return end
        
        BedwarsTimer.timeLeft = BedwarsTimer.timeLeft - dt
        
        if BedwarsTimer.timerLabel then
            BedwarsTimer.timerLabel.Text = "Fly Time: " .. string.format("%.2f", math.max(0, BedwarsTimer.timeLeft)) .. "s"
        end
        
        if BedwarsTimer.timerBar and BedwarsTimer.timerBar:FindFirstChild("Fill") then
            local totalProgress = (2.0 - BedwarsTimer.timeLeft) / 2.0
            totalProgress = math.clamp(totalProgress, 0, 1)
            BedwarsTimer.timerBar.Fill.Size = UDim2.new(totalProgress, 0, 1, 0)
            
            if totalProgress < 0.33 then
                BedwarsTimer.timerBar.Fill.BackgroundColor3 = Color3.fromRGB(86, 101, 245)
            elseif totalProgress < 0.66 then
                BedwarsTimer.timerBar.Fill.BackgroundColor3 = Color3.fromRGB(245, 166, 35)
            else
                BedwarsTimer.timerBar.Fill.BackgroundColor3 = Color3.fromRGB(245, 86, 86)
            end
        end
        
        if BedwarsTimer.timeLeft <= 0 then
            BedwarsTimer.stop()
            if Core.toggleStates.Fly then
                Core.toggleButtons.Fly()
            end
            BedwarsTimer.startCooldown()
        end
    end)
end

function BedwarsTimer.start()
    if BedwarsTimer.cooldownActive then return false end
    
    BedwarsTimer.timeLeft = 2.0
    BedwarsTimer.active = true
    BedwarsTimer.controlsFrozen = false
    
    if not Core.timerGui then
        BedwarsTimer.createTimerGUI()
    end
    
    BedwarsTimer.startTimer()
    return true
end

function BedwarsTimer.stop()
    BedwarsTimer.active = false
    BedwarsTimer.controlsFrozen = false
    if Core.connections.bedwarsTimer then
        Core.connections.bedwarsTimer:Disconnect()
        Core.connections.bedwarsTimer = nil
    end
    BedwarsTimer.reset()
end

function BedwarsTimer.reset()
    BedwarsTimer.timeLeft = 2.0
    
    if BedwarsTimer.timerLabel then
        BedwarsTimer.timerLabel.Text = "Fly Time: 2.0s"
    end
    
    if BedwarsTimer.timerBar and BedwarsTimer.timerBar:FindFirstChild("Fill") then
        BedwarsTimer.timerBar.Fill.Size = UDim2.new(1, 0, 1, 0)
        BedwarsTimer.timerBar.Fill.BackgroundColor3 = Color3.fromRGB(86, 101, 245)
    end
end

function BedwarsTimer.updateVisibility(show)
    BedwarsTimer.showTimer = show
    if Core.timerGui then
        local timerFrame = Core.timerGui:FindFirstChild("TimerFrame")
        if timerFrame then
            timerFrame.Visible = show
        end
    end
    
    ToggleManager.updateVisualState("Show Fly Time", show)
end

-- === NOFALL MODULE ===
local NoFallModule = {
    mode = "Bedwars",
    lastActivation = 0,
    lastResetTime = 0
}

function NoFallModule.activateBedwarsMode()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local rootPart = player.Character.HumanoidRootPart
    local currentTime = tick()
    
    if currentTime - NoFallModule.lastActivation < 0.02 then return end
    
    if rootPart.AssemblyLinearVelocity.Y < -7 then
        local raycast = workspace:Raycast(rootPart.Position, Vector3.new(0, -500, 0))
        
        if raycast then
            local distanceToGround = rootPart.Position.Y - raycast.Position.Y
            
            if distanceToGround > 7 then
                local currentVel = rootPart.AssemblyLinearVelocity
                if currentVel.Y < -4 then
                    rootPart.AssemblyLinearVelocity = Vector3.new(currentVel.X, -4, currentVel.Z)
                    NoFallModule.lastActivation = currentTime
                end
            end
        end
    end
end

function NoFallModule.toggle(enabled)
    if Core.connections.nofall then
        Core.connections.nofall:Disconnect()
        Core.connections.nofall = nil
    end
    
    NoFallModule.lastResetTime = 0
    
    if enabled and NoFallModule.mode == "Bedwars" then
        Core.connections.nofall = RunService.Heartbeat:Connect(function()
            NoFallModule.activateBedwarsMode()
        end)
    end
end

-- === FULLBRIGHT MODULE ===
local FullbrightModule = {
    enabled = false
}

function FullbrightModule.applyFullbright()
    Lighting.Brightness = 3
    Lighting.ClockTime = 12
    Lighting.FogEnd = 100000
    Lighting.GlobalShadows = false
    Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
end

function FullbrightModule.restoreOriginal()
    for prop, value in pairs(originalLighting) do
        Lighting[prop] = value
    end
end

function FullbrightModule.toggle(enabled)
    FullbrightModule.enabled = enabled
    
    if Core.connections.fullbrightLoop then
        Core.connections.fullbrightLoop:Disconnect()
        Core.connections.fullbrightLoop = nil
    end
    
    if enabled then
        FullbrightModule.applyFullbright()
        -- Always loop fullbright to maintain it
        Core.connections.fullbrightLoop = RunService.Heartbeat:Connect(function()
            FullbrightModule.applyFullbright()
        end)
    else
        FullbrightModule.restoreOriginal()
    end
end

-- === SPEED MODULE ===
local SpeedModule = {
    mode = "Normal", value = 50, disableSpeed = false, velocitySpeed = 50,
    boostSpeed = 100, boostTime = 1.0, boostCooldown = 1.5, boostMode = "Normal",
    boostStartTime = 0, boostCooldownStartTime = 0, boostActive = false, inCooldown = false,
    onlyWhenPressed = false, activationKey = "Space"
}

function SpeedModule.resetAllTimers()
    SpeedModule.boostStartTime = 0
    SpeedModule.boostCooldownStartTime = 0
    SpeedModule.boostActive = false
    SpeedModule.inCooldown = false
end

function SpeedModule.updateBoostTiming(currentTime)
    if SpeedModule.boostActive then
        local boostElapsed = currentTime - SpeedModule.boostStartTime
        if SpeedModule.mode == "Penablox" then
            if boostElapsed >= 0.05 then
                SpeedModule.boostActive = false
                SpeedModule.inCooldown = true
                SpeedModule.boostCooldownStartTime = currentTime
            end
        else
            if boostElapsed >= SpeedModule.boostTime then
                SpeedModule.boostActive = false
                SpeedModule.inCooldown = true
                SpeedModule.boostCooldownStartTime = currentTime
            end
        end
    elseif SpeedModule.inCooldown then
        local cooldownElapsed = currentTime - SpeedModule.boostCooldownStartTime
        if SpeedModule.mode == "Penablox" then
            if cooldownElapsed >= 0.2 then
                SpeedModule.inCooldown = false
            end
        else
            if cooldownElapsed >= SpeedModule.boostCooldown then
                SpeedModule.inCooldown = false
            end
        end
    end
end

function SpeedModule.startBoost(currentTime)
    if not SpeedModule.boostActive and not SpeedModule.inCooldown then
        SpeedModule.boostActive = true
        SpeedModule.boostStartTime = currentTime
    end
end

function SpeedModule.isActivationKeyPressed()
    if not SpeedModule.onlyWhenPressed then return true end
    
    local keyEnum = nil
    if SpeedModule.activationKey == "Space" then
        keyEnum = Enum.KeyCode.Space
    elseif SpeedModule.activationKey == "LeftShift" then
        keyEnum = Enum.KeyCode.LeftShift
    elseif SpeedModule.activationKey == "RightShift" then
        keyEnum = Enum.KeyCode.RightShift
    elseif SpeedModule.activationKey == "LeftControl" then
        keyEnum = Enum.KeyCode.LeftControl
    elseif SpeedModule.activationKey == "RightControl" then
        keyEnum = Enum.KeyCode.RightControl
    elseif #SpeedModule.activationKey == 1 then
        keyEnum = Enum.KeyCode[SpeedModule.activationKey:upper()]
    end
    
    return keyEnum and UserInputService:IsKeyDown(keyEnum) or false
end

function SpeedModule.toggle(enabled)
    if Core.connections.speed then
        Core.connections.speed:Disconnect()
        Core.connections.speed = nil
    end
    
    if not enabled then
        SpeedModule.resetAllTimers()
        
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            CleanupSystem.removeAllBodyObjects(player.Character.HumanoidRootPart)
        end
        
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.WalkSpeed = Core.originalWalkSpeed
        end
        return
    end
    
    if not player.Character then return end
    local humanoid = player.Character:FindFirstChild("Humanoid")
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoid then return end
    
    SpeedModule.resetAllTimers()
    
    if SpeedModule.mode == "Normal" then
        Core.connections.speed = RunService.Heartbeat:Connect(function()
            if SpeedModule.isActivationKeyPressed() then
                humanoid.WalkSpeed = SpeedModule.value
            else
                humanoid.WalkSpeed = Core.originalWalkSpeed
            end
        end)
        
    elseif SpeedModule.mode == "CFrame" and rootPart then
        humanoid.WalkSpeed = Core.originalWalkSpeed
        Core.connections.speed = RunService.Heartbeat:Connect(function()
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not player.Character:FindFirstChild("Humanoid") then 
                return 
            end
            
            local currentHumanoid = player.Character.Humanoid
            local currentRootPart = player.Character.HumanoidRootPart
            
            if currentHumanoid.MoveDirection.Magnitude > 0 and SpeedModule.isActivationKeyPressed() then
                local speed = (SpeedModule.value - 16) / 50
                currentRootPart.CFrame = currentRootPart.CFrame + currentHumanoid.MoveDirection * speed
            end
        end)
        
    elseif SpeedModule.mode == "TP Walk" and rootPart then
        humanoid.WalkSpeed = Core.originalWalkSpeed
        Core.connections.speed = RunService.Heartbeat:Connect(function()
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not player.Character:FindFirstChild("Humanoid") then 
                return 
            end
            
            local currentHumanoid = player.Character.Humanoid
            local currentRootPart = player.Character.HumanoidRootPart
            
            if currentHumanoid.MoveDirection.Magnitude > 0 and SpeedModule.isActivationKeyPressed() then
                local speed = (SpeedModule.value - 16) / 80
                currentRootPart.CFrame = currentRootPart.CFrame + currentHumanoid.MoveDirection * speed
            end
        end)
        
    elseif SpeedModule.mode == "Velocity" and rootPart then
        humanoid.WalkSpeed = Core.originalWalkSpeed
        
        local bodyVel = Instance.new("BodyVelocity")
        bodyVel.Name = "VelocitySpeed"
        bodyVel.MaxForce = Vector3.new(4000, 0, 4000)
        bodyVel.Velocity = Vector3.new(0, 0, 0)
        bodyVel.Parent = rootPart
        
        Core.connections.speed = RunService.Heartbeat:Connect(function()
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not player.Character:FindFirstChild("Humanoid") then 
                return
            end
            
            local currentRootPart = player.Character.HumanoidRootPart
            local currentHumanoid = player.Character.Humanoid
            local currentBodyVel = currentRootPart:FindFirstChild("VelocitySpeed")
            if not currentBodyVel then return end
            
            if currentHumanoid.MoveDirection.Magnitude > 0 and SpeedModule.isActivationKeyPressed() then
                local velocity = currentHumanoid.MoveDirection * SpeedModule.velocitySpeed
                currentBodyVel.Velocity = Vector3.new(velocity.X, 0, velocity.Z)
            else
                currentBodyVel.Velocity = Vector3.new(0, 0, 0)
            end
        end)
        
    elseif SpeedModule.mode == "Boost" and rootPart then
        humanoid.WalkSpeed = Core.originalWalkSpeed
        
        if SpeedModule.boostMode == "Normal" then
            Core.connections.speed = RunService.Heartbeat:Connect(function()
                if not player.Character or not player.Character:FindFirstChild("Humanoid") then return end
                
                local currentTime = tick()
                local currentHumanoid = player.Character.Humanoid
                
                SpeedModule.updateBoostTiming(currentTime)
                
                if currentHumanoid.MoveDirection.Magnitude > 0 and SpeedModule.isActivationKeyPressed() then
                    SpeedModule.startBoost(currentTime)
                    local speed = SpeedModule.boostActive and SpeedModule.boostSpeed or 16
                    currentHumanoid.WalkSpeed = speed
                else
                    currentHumanoid.WalkSpeed = Core.originalWalkSpeed
                end
            end)
        end
        
    elseif SpeedModule.mode == "Penablox" and rootPart then
        humanoid.WalkSpeed = Core.originalWalkSpeed
        Core.connections.speed = RunService.Heartbeat:Connect(function()
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not player.Character:FindFirstChild("Humanoid") then return end
            
            local currentTime = tick()
            local currentRootPart = player.Character.HumanoidRootPart
            local currentHumanoid = player.Character.Humanoid
            
            SpeedModule.updateBoostTiming(currentTime)
            
            if currentHumanoid.MoveDirection.Magnitude > 0 and SpeedModule.isActivationKeyPressed() then
                SpeedModule.startBoost(currentTime)
                local speed = SpeedModule.boostActive and (60 - 16) / 80 or 0
                currentRootPart.CFrame = currentRootPart.CFrame + currentHumanoid.MoveDirection * speed
            end
        end)
        
    elseif SpeedModule.mode == "VRAN" and rootPart then
        humanoid.WalkSpeed = Core.originalWalkSpeed
        Core.connections.speed = RunService.Heartbeat:Connect(function()
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not player.Character:FindFirstChild("Humanoid") then 
                return 
            end
            
            local currentHumanoid = player.Character.Humanoid
            local currentRootPart = player.Character.HumanoidRootPart
            
            if currentHumanoid.MoveDirection.Magnitude > 0 and SpeedModule.isActivationKeyPressed() then
                local speed = (20 - 16) / 80
                currentRootPart.CFrame = currentRootPart.CFrame + currentHumanoid.MoveDirection * speed
            end
        end)
        
    elseif SpeedModule.mode == "Bedwars" and rootPart then
        humanoid.WalkSpeed = Core.originalWalkSpeed
        Core.connections.speed = RunService.Heartbeat:Connect(function()
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not player.Character:FindFirstChild("Humanoid") then 
                return 
            end
            
            local currentHumanoid = player.Character.Humanoid
            local currentRootPart = player.Character.HumanoidRootPart
            
            if currentHumanoid.MoveDirection.Magnitude > 0 and SpeedModule.isActivationKeyPressed() then
                local speed = (17 - 16) / 80
                currentRootPart.CFrame = currentRootPart.CFrame + currentHumanoid.MoveDirection * speed
            end
        end)
    end
end

-- === FLY MODULE ===
local FlyModule = {
    mode = "Velocity", speed = 50, amplitude = 1.0, oscSpeed = 1.0, verticalSpeed = 10,
    oscTime = 0, baseHeight = 0, penabloxDropDistance = 2.3, penabloxCurrentBlock = nil,
    penabloxAntiHeightKick = false, penabloxGhostCeiling = nil, penabloxPlatformBuffer = 0.5,
    penabloxPlatformSize = Vector3.new(1, 0.1, 1), penabloxUpdateDistance = 2.0
}

function FlyModule.createPenabloxPlatform(position)
    local block = Instance.new("Part")
    block.Name = "PenabloxPlatform"
    block.Size = FlyModule.penabloxPlatformSize
    block.Material = Enum.Material.Plastic
    block.BrickColor = BrickColor.new("Medium stone grey")
    block.CanCollide = true
    block.Anchored = true
    block.Transparency = 1
    block.CFrame = CFrame.new(position)
    block.Parent = workspace
    
    return block
end

function FlyModule.clearPenabloxPlatform()
    if FlyModule.penabloxCurrentBlock and FlyModule.penabloxCurrentBlock.Parent then
        FlyModule.penabloxCurrentBlock:Destroy()
        FlyModule.penabloxCurrentBlock = nil
    end
end

function FlyModule.createGhostCeiling()
    if FlyModule.penabloxGhostCeiling then return end
    
    local ghostCeiling = Instance.new("Part")
    ghostCeiling.Size = Vector3.new(10000, 1, 10000)
    ghostCeiling.Position = Vector3.new(0, 37, 0)
    ghostCeiling.Anchored = true
    ghostCeiling.CanCollide = true
    ghostCeiling.Transparency = 1
    ghostCeiling.Locked = true
    ghostCeiling.Name = "GhostCeiling"
    ghostCeiling.Parent = workspace
    
    FlyModule.penabloxGhostCeiling = ghostCeiling
end

function FlyModule.removeGhostCeiling()
    if FlyModule.penabloxGhostCeiling and FlyModule.penabloxGhostCeiling.Parent then
        FlyModule.penabloxGhostCeiling:Destroy()
        FlyModule.penabloxGhostCeiling = nil
    end
end

function FlyModule.cleanupModeEffects()
    FlyModule.clearPenabloxPlatform()
    FlyModule.removeGhostCeiling()
    BedwarsTimer.stop()
    FlyModule.penabloxAntiHeightKick = false
end

function FlyModule.toggle(enabled)
    if enabled and FlyModule.mode == "Bedwars" and BedwarsTimer.cooldownActive then
        spawn(function()
            wait(0.1)
            if Core.toggleStates.Fly then
                Core.toggleButtons.Fly()
            end
        end)
        return
    end
    
    if Core.connections.fly then
        Core.connections.fly:Disconnect()
        Core.connections.fly = nil
    end
    if Core.connections.flyAnim then
        Core.connections.flyAnim:Stop()
        Core.connections.flyAnim = nil
    end
    
    -- Always clean up mode effects when toggling
    FlyModule.cleanupModeEffects()
    
    if SpeedModule.disableSpeed then
        if enabled then
            Core.speedWasEnabledBeforeFly = Core.toggleStates.Speed
            if Core.toggleStates.Speed then
                ToggleManager.disableToggle("Speed")
            end
        else
            if Core.speedWasEnabledBeforeFly and not Core.toggleStates.Speed then
                Core.toggleButtons.Speed()
            end
            Core.speedWasEnabledBeforeFly = false
        end
    end
    
    if not enabled then
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            CleanupSystem.fullCharacterRestore()
        end
        return
    end
    
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local rootPart = player.Character.HumanoidRootPart
    local humanoid = player.Character:FindFirstChild("Humanoid")
    
    if FlyModule.mode == "Velocity" then
        local bodyVel = Instance.new("BodyVelocity")
        bodyVel.Name = "FlyVelocity"
        bodyVel.MaxForce = Vector3.new(4000, 4000, 4000)
        bodyVel.Velocity = Vector3.new(0, 0, 0)
        bodyVel.Parent = rootPart
        
        Core.connections.fly = RunService.Heartbeat:Connect(function()
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
            
            local currentRootPart = player.Character.HumanoidRootPart
            local camera = workspace.CurrentCamera
            local velocity = Vector3.new(0, 0, 0)
            
            local look = camera.CFrame.LookVector
            local right = camera.CFrame.RightVector
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                velocity = velocity + Vector3.new(look.X, 0, look.Z) * FlyModule.speed
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                velocity = velocity - Vector3.new(look.X, 0, look.Z) * FlyModule.speed
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                velocity = velocity - Vector3.new(right.X, 0, right.Z) * FlyModule.speed
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                velocity = velocity + Vector3.new(right.X, 0, right.Z) * FlyModule.speed
            end
            
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                velocity = velocity + Vector3.new(0, FlyModule.speed, 0)
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                velocity = velocity + Vector3.new(0, -FlyModule.speed, 0)
            end
            
            local currentBodyVel = currentRootPart:FindFirstChild("FlyVelocity")
            if currentBodyVel then
                currentBodyVel.Velocity = velocity
            end
        end)
        
    elseif FlyModule.mode == "Physics" then
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Physics)
            humanoid.AutoRotate = false
            
            if humanoid:FindFirstChild("Animator") then
                local animator = humanoid.Animator
                local idleAnim = Instance.new("Animation")
                idleAnim.AnimationId = "rbxassetid://507766666"
                Core.connections.flyAnim = animator:LoadAnimation(idleAnim)
                Core.connections.flyAnim.Priority = Enum.AnimationPriority.Action
                Core.connections.flyAnim.Looped = true
                Core.connections.flyAnim:Play()
            end
        end
        
        Core.connections.fly = RunService.RenderStepped:Connect(function()
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
            
            local currentRootPart = player.Character.HumanoidRootPart
            local camera = workspace.CurrentCamera
            
            for _, part in pairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            
            local direction = Vector3.new(0, 0, 0)
            local lookVector = camera.CFrame.LookVector
            local rightVector = camera.CFrame.RightVector
            
            lookVector = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                direction = direction + lookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                direction = direction - lookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                direction = direction - rightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                direction = direction + rightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                direction = direction + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                direction = direction + Vector3.new(0, -1, 0)
            end
            
            if direction.Magnitude > 0 then
                direction = direction.Unit * FlyModule.speed
            end
            currentRootPart.AssemblyLinearVelocity = direction
            
            currentRootPart.CFrame = CFrame.new(currentRootPart.Position, currentRootPart.Position + lookVector)
        end)
        
    elseif FlyModule.mode == "Bedwars" then
        if not BedwarsTimer.start() then return end
        
        local bodyVel = Instance.new("BodyVelocity")
        bodyVel.Name = "FlyVelocity"
        bodyVel.MaxForce = Vector3.new(4000, 4000, 4000)
        bodyVel.Velocity = Vector3.new(0, 0, 0)
        bodyVel.Parent = rootPart
        
        Core.connections.fly = RunService.Heartbeat:Connect(function()
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
            
            if BedwarsTimer.controlsFrozen then return end
            
            local currentRootPart = player.Character.HumanoidRootPart
            local camera = workspace.CurrentCamera
            local velocity = Vector3.new(0, 0, 0)
            
            local flySpeed = 15
            local look = camera.CFrame.LookVector
            local right = camera.CFrame.RightVector
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                velocity = velocity + Vector3.new(look.X, 0, look.Z) * flySpeed
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                velocity = velocity - Vector3.new(look.X, 0, look.Z) * flySpeed
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                velocity = velocity - Vector3.new(right.X, 0, right.Z) * flySpeed
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                velocity = velocity + Vector3.new(right.X, 0, right.Z) * flySpeed
            end
            
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                velocity = velocity + Vector3.new(0, flySpeed, 0)
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                velocity = velocity + Vector3.new(0, -flySpeed, 0)
            end
            
            local currentBodyVel = currentRootPart:FindFirstChild("FlyVelocity")
            if currentBodyVel then
                currentBodyVel.Velocity = velocity
            end
        end)
        
    elseif FlyModule.mode == "Penablox" then
        -- Always create ghost ceiling when Penablox fly is enabled
        if FlyModule.penabloxAntiHeightKick then
            FlyModule.createGhostCeiling()
        end
        
        Core.connections.fly = RunService.Heartbeat:Connect(function()
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
            
            local currentRootPart = player.Character.HumanoidRootPart
            local playerY = currentRootPart.Position.Y
            local targetY = playerY - FlyModule.penabloxDropDistance - FlyModule.penabloxPlatformBuffer
            
            local platformPosition = Vector3.new(
                currentRootPart.Position.X,
                targetY,
                currentRootPart.Position.Z
            )
            
            if not FlyModule.penabloxCurrentBlock or 
               (FlyModule.penabloxCurrentBlock.Position - platformPosition).Magnitude > FlyModule.penabloxUpdateDistance then
                FlyModule.clearPenabloxPlatform()
                FlyModule.penabloxCurrentBlock = FlyModule.createPenabloxPlatform(platformPosition)
            end
        end)
        
    elseif FlyModule.mode == "Oscillating" then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "OscFly_BodyVelocity"
        bv.MaxForce = Vector3.new(1e6, 0, 1e6)
        bv.Velocity = Vector3.new(0,0,0)
        bv.P = 1200
        bv.Parent = rootPart

        local bp = Instance.new("BodyPosition")
        bp.Name = "OscFly_BodyPosition"
        bp.MaxForce = Vector3.new(0, 1e6, 0)
        bp.P = 3000
        bp.D = 120
        bp.Position = rootPart.Position
        bp.Parent = rootPart

        local bg = Instance.new("BodyGyro")
        bg.Name = "OscFly_BodyGyro"
        bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
        bg.P = 6000
        bg.CFrame = rootPart.CFrame
        bg.Parent = rootPart
        
        if humanoid then
            humanoid.PlatformStand = true
            humanoid.AutoRotate = false
        end
        
        FlyModule.baseHeight = rootPart.Position.Y
        FlyModule.oscTime = 0
        
        Core.connections.fly = RunService.Heartbeat:Connect(function(dt)
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
            
            local currentRootPart = player.Character.HumanoidRootPart
            local camera = workspace.CurrentCamera
            
            local oscHz = math.max(0.0001, FlyModule.oscSpeed)
            FlyModule.oscTime = FlyModule.oscTime + dt * oscHz * (2 * math.pi)
            local yOffset = math.sin(FlyModule.oscTime) * FlyModule.amplitude
            
            local move = Vector3.new()
            local look = camera.CFrame.LookVector
            local right = camera.CFrame.RightVector

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then 
                move = move + Vector3.new(look.X, 0, look.Z) 
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then 
                move = move - Vector3.new(look.X, 0, look.Z) 
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then 
                move = move - Vector3.new(right.X, 0, right.Z) 
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then 
                move = move + Vector3.new(right.X, 0, right.Z) 
            end

            local horizVel = Vector3.new()
            if move.Magnitude > 0.001 then 
                horizVel = move.Unit * FlyModule.speed 
            end
            
            local currentBV = currentRootPart:FindFirstChild("OscFly_BodyVelocity")
            if currentBV then
                currentBV.Velocity = Vector3.new(horizVel.X, 0, horizVel.Z)
            end

            local verticalInput = 0
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then 
                verticalInput = verticalInput + 1 
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then 
                verticalInput = verticalInput - 1 
            end
            FlyModule.baseHeight = FlyModule.baseHeight + verticalInput * FlyModule.verticalSpeed * dt

            local targetPos = Vector3.new(currentRootPart.Position.X, FlyModule.baseHeight + yOffset, currentRootPart.Position.Z)
            local currentBP = currentRootPart:FindFirstChild("OscFly_BodyPosition")
            if currentBP then
                currentBP.Position = targetPos
            end

            local lookVec = camera.CFrame.LookVector
            local yaw = math.atan2(lookVec.Z, lookVec.X)
            local yawCFrame = CFrame.Angles(0, -yaw + math.pi/2, 0)
            local currentBG = currentRootPart:FindFirstChild("OscFly_BodyGyro")
            if currentBG then
                currentBG.CFrame = yawCFrame
            end
        end)
    end
end

-- === NOCLIP MODULE ===
local NoclipModule = {
    mode = "Vanilla"
}

function NoclipModule.toggle(enabled)
    if Core.connections.noclip then
        Core.connections.noclip:Disconnect()
        Core.connections.noclip = nil
    end
    
    if enabled then
        if player.Character then
            for _, part in pairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
        
        Core.connections.noclip = RunService.Heartbeat:Connect(function()
            if player.Character then
                for _, part in pairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        CleanupSystem.fullCharacterRestore()
    end
end

-- === ESP MODULE ===
local ESPModule = {
    mode = "Normal", -- "Normal" or "Team"
    normalColor = Color3.new(1, 0, 0),
    teamColor = Color3.new(0, 1, 0),
    enemyColor = Color3.new(1, 0, 0),
    objects = {},
    enabled = false
}

function ESPModule.isTeammate(targetPlayer)
    -- Basic team detection methods
    if player.Team and targetPlayer.Team then
        return player.Team == targetPlayer.Team
    end
    
    -- Check for team-based name colors
    if player.TeamColor and targetPlayer.TeamColor then
        return player.TeamColor == targetPlayer.TeamColor
    end
    
    return false
end

function ESPModule.getPlayerColor(targetPlayer)
    if ESPModule.mode == "Normal" then
        return ESPModule.normalColor
    else -- Team mode
        return ESPModule.isTeammate(targetPlayer) and ESPModule.teamColor or ESPModule.enemyColor
    end
end

function ESPModule.createESP(plr)
    if plr == player or not plr.Character then return end
    
    ESPModule.removeESP(plr)
    
    local char = plr.Character
    local head = char:FindFirstChild("Head")
    if not head then return end
    
    local playerColor = ESPModule.getPlayerColor(plr)
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillColor = playerColor
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = playerColor
    highlight.OutlineTransparency = 0
    highlight.Parent = char
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.Size = UDim2.new(0, 120, 0, 30)
    billboard.AlwaysOnTop = true
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Parent = head
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = plr.Name
    label.TextColor3 = playerColor
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Parent = billboard
    
    ESPModule.objects[plr] = {
        highlight = highlight,
        billboard = billboard,
        label = label
    }
end

function ESPModule.removeESP(plr)
    local obj = ESPModule.objects[plr]
    if not obj then return end
    
    if obj.highlight and obj.highlight.Parent then 
        obj.highlight:Destroy() 
    end
    if obj.billboard and obj.billboard.Parent then 
        obj.billboard:Destroy() 
    end
    
    ESPModule.objects[plr] = nil
end

function ESPModule.updateLoop()
    if not ESPModule.enabled then return end
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            if plr.Character and plr.Character:FindFirstChild("Head") then
                if not ESPModule.objects[plr] then
                    ESPModule.createESP(plr)
                end
                
                local obj = ESPModule.objects[plr]
                if obj and obj.highlight and obj.label then
                    local playerColor = ESPModule.getPlayerColor(plr)
                    obj.highlight.FillColor = playerColor
                    obj.highlight.OutlineColor = playerColor
                    obj.label.TextColor3 = playerColor
                end
            else
                if ESPModule.objects[plr] then
                    ESPModule.removeESP(plr)
                end
            end
        end
    end
    
    for plr, _ in pairs(ESPModule.objects) do
        if not Players:FindFirstChild(plr.Name) then
            ESPModule.removeESP(plr)
        end
    end
end

function ESPModule.toggle(enabled)
    ESPModule.enabled = enabled
    
    if Core.connections.espLoop then
        Core.connections.espLoop:Disconnect()
        Core.connections.espLoop = nil
    end
    
    if enabled then
        Core.connections.espLoop = RunService.Heartbeat:Connect(function()
            ESPModule.updateLoop()
        end)
        ESPModule.updateLoop()
    else
        for plr, _ in pairs(ESPModule.objects) do
            ESPModule.removeESP(plr)
        end
    end
end

function ESPModule.updateColor(color, isTeam)
    if ESPModule.mode == "Normal" then
        ESPModule.normalColor = color
    else
        if isTeam then
            ESPModule.teamColor = color
        else
            ESPModule.enemyColor = color
        end
    end
    ESPModule.updateLoop()
end

-- === ENHANCED CLEANUP ===
function Core.fullCleanup()
    CleanupSystem.fullCharacterRestore()
    
    for _, connection in pairs(Core.connections) do
        if connection then connection:Disconnect() end
    end
    Core.connections = {}
    
    BedwarsTimer.stop()
    if Core.timerGui then Core.timerGui:Destroy() end
    if Core.notificationGui then Core.notificationGui:Destroy() end
    if Core.coordinatesGui then Core.coordinatesGui:Destroy() end
    if AntiCheat.notificationContainer and AntiCheat.notificationContainer.Parent then
        AntiCheat.notificationContainer.Parent:Destroy()
    end
    
    FlyModule.clearPenabloxPlatform()
    FlyModule.removeGhostCeiling()
    BlockTrailModule.clearAllBlocks()
    GameExploits.cleanupWallSystem()
    
    -- Clean up aimbot FOV circle
    if AimbotModule.fovGui then
        AimbotModule.fovGui:Destroy()
        AimbotModule.fovGui = nil
        AimbotModule.fovCircle = nil
    end
    
    for key, _ in pairs(Core.toggleStates) do Core.toggleStates[key] = false end
    Core.toggleButtons = {}
    Core.toggleFrames = {}
    
    Core.speedWasEnabledBeforeFly = false
    GameExploits.penabloxInfAmmo = false
    GameExploits.penabloxSemiWallbang = false
    MessageSpammer.enabled = false
    
    for prop, value in pairs(originalLighting) do
        Lighting[prop] = value
    end
end

-- === KEYBIND SYSTEM ===
local KeybindSystem = {}

function KeybindSystem.init()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        local keyName = input.KeyCode.Name
        
        if keyName == Core.keybinds.gui then
            if Core.gui then Core.gui.Enabled = not Core.gui.Enabled end
            return
        end
        
        if keyName == Core.keybinds.speed and Core.keybinds.speed ~= "None" then
            local speedToggle = Core.toggleButtons.Speed
            if speedToggle then speedToggle() end
        elseif keyName == Core.keybinds.fly and Core.keybinds.fly ~= "None" then
            local flyToggle = Core.toggleButtons.Fly  
            if flyToggle then flyToggle() end
        elseif keyName == Core.keybinds.esp and Core.keybinds.esp ~= "None" then
            local espToggle = Core.toggleButtons.ESP
            if espToggle then espToggle() end
        elseif keyName == Core.keybinds.noclip and Core.keybinds.noclip ~= "None" then
            local noclipToggle = Core.toggleButtons.Noclip
            if noclipToggle then noclipToggle() end
        elseif keyName == Core.keybinds.infJump and Core.keybinds.infJump ~= "None" then
            local infJumpToggle = Core.toggleButtons["Infinite Jump"]
            if infJumpToggle then infJumpToggle() end
        elseif keyName == Core.keybinds.nofall and Core.keybinds.nofall ~= "None" then
            local nofallToggle = Core.toggleButtons.NoFall
            if nofallToggle then nofallToggle() end
        elseif keyName == Core.keybinds.fullbright and Core.keybinds.fullbright ~= "None" then
            local fullbrightToggle = Core.toggleButtons.Fullbright
            if fullbrightToggle then fullbrightToggle() end
        elseif keyName == Core.keybinds.messageSpammer and Core.keybinds.messageSpammer ~= "None" then
            local messageSpammerToggle = Core.toggleButtons["Message Spammer"]
            if messageSpammerToggle then messageSpammerToggle() end
        elseif keyName == Core.keybinds.blockTrail and Core.keybinds.blockTrail ~= "None" then
            local blockTrailToggle = Core.toggleButtons["Block Trail"]
            if blockTrailToggle then blockTrailToggle() end
        elseif keyName == Core.keybinds.aimbot and Core.keybinds.aimbot ~= "None" then
            local aimbotToggle = Core.toggleButtons.Aimbot
            if aimbotToggle then aimbotToggle() end
        end
    end)
end

-- === DRAGGING FUNCTIONALITY ===
local function makeDraggable(frame, dragHandle)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- === CSGO STYLE GUI CREATION ===
local function createCSGOGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "CerialsHub"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999999
    gui.IgnoreGuiInset = true
    
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then gui.Parent = player:WaitForChild("PlayerGui") end
    
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 620, 0, 450)
    main.Position = UDim2.new(0.5, -310, 0.5, -225)
    main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    main.BorderSizePixel = 0
    main.ZIndex = 99999
    main.Parent = gui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 6)
    mainCorner.Parent = main
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(86, 101, 245)
    mainStroke.Thickness = 2
    mainStroke.Parent = main
    
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = main.ZIndex + 1
    titleBar.Parent = main
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 6)
    titleCorner.Parent = titleBar
    
    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 6)
    titleFix.Position = UDim2.new(0, 0, 1, -6)
    titleFix.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    titleFix.BorderSizePixel = 0
    titleFix.ZIndex = titleBar.ZIndex
    titleFix.Parent = titleBar
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "CERIALS HUB"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = titleBar.ZIndex + 1
    title.Parent = titleBar
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Position = UDim2.new(1, -25, 0.5, -10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(245, 86, 86)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.ZIndex = titleBar.ZIndex + 1
    closeBtn.Parent = titleBar
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 3)
    closeBtnCorner.Parent = closeBtn
    
    return gui, main, titleBar, closeBtn
end

-- === CSGO STYLE UI COMPONENTS ===
local UI = {}

function UI.createTabSystem(main, yOffset)
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(0, 120, 1, -yOffset)
    tabContainer.Position = UDim2.new(0, 0, 0, yOffset)
    tabContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    tabContainer.BorderSizePixel = 0
    tabContainer.ZIndex = main.ZIndex + 1
    tabContainer.Parent = main
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Vertical
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 2)
    tabLayout.Parent = tabContainer
    
    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -125, 1, -yOffset)
    content.Position = UDim2.new(0, 125, 0, yOffset)
    content.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = Color3.fromRGB(86, 101, 245)
    content.ZIndex = main.ZIndex + 1
    content.Parent = main
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 4)
    contentCorner.Parent = content
    
    local tabs = {}
    
    local function resetVisualStates()
        BedwarsTimer.updateVisibility(false)
        if Core.timerGui then
            local timerFrame = Core.timerGui:FindFirstChild("TimerFrame")
            if timerFrame then timerFrame.Visible = false end
        end
    end
    
    local function createTab(name, order)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 35)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        btn.BorderSizePixel = 0
        btn.Text = name:upper()
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamBold
        btn.LayoutOrder = order
        btn.ZIndex = tabContainer.ZIndex + 1
        btn.Parent = tabContainer
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn
        
        local tabContent = Instance.new("Frame")
        tabContent.Size = UDim2.new(1, -10, 0, 0)
        tabContent.Position = UDim2.new(0, 5, 0, 5)
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = false
        tabContent.ZIndex = content.ZIndex + 1
        tabContent.Parent = content
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 5)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = tabContent
        
        btn.MouseButton1Click:Connect(function()
            resetVisualStates()
            
            for _, child in pairs(tabContainer:GetChildren()) do
                if child:IsA("TextButton") then
                    child.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
                    child.TextColor3 = Color3.fromRGB(200, 200, 200)
                end
            end
            btn.BackgroundColor3 = Color3.fromRGB(86, 101, 245)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            
            for _, child in pairs(content:GetChildren()) do
                if child:IsA("Frame") then child.Visible = false end
            end
            tabContent.Visible = true
            
            tabContent.Size = UDim2.new(1, -10, 0, layout.AbsoluteContentSize.Y + 10)
            content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end)
        
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if tabContent.Visible then
                tabContent.Size = UDim2.new(1, -10, 0, layout.AbsoluteContentSize.Y + 10)
                content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
            end
        end)
        
        tabs[name] = {content = tabContent, layout = layout, button = btn, resetVisuals = resetVisualStates}
        return tabContent
    end
    
    return tabs, createTab, content
end

function UI.createSection(parent, title, order)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 25)
    section.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    section.BorderSizePixel = 0
    section.LayoutOrder = order
    section.ZIndex = parent.ZIndex + 1
    section.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = section
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(86, 101, 245)
    stroke.Thickness = 1
    stroke.Parent = section
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = title:upper()
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = section.ZIndex + 1
    label.Parent = section
    
    return section
end

function UI.createToggle(parent, name, callback, order, keybindCallback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order
    frame.ZIndex = parent.ZIndex + 1
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    if keybindCallback then
        label.Size = UDim2.new(0.4, 0, 1, 0)
    else
        label.Size = UDim2.new(0.7, 0, 1, 0)
    end
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = frame.ZIndex + 1
    label.Parent = frame
    
    local keybindBox = nil
    if keybindCallback then
        keybindBox = Instance.new("TextBox")
        keybindBox.Size = UDim2.new(0.25, 0, 0.6, 0)
        keybindBox.Position = UDim2.new(0.4, 5, 0.2, 0)
        keybindBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        keybindBox.BorderSizePixel = 0
        keybindBox.Text = "None"
        keybindBox.PlaceholderText = "Key"
        keybindBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        keybindBox.TextSize = 12
        keybindBox.Font = Enum.Font.GothamBold
        keybindBox.ZIndex = frame.ZIndex + 1
        keybindBox.Parent = frame
        
        local keybindCorner = Instance.new("UICorner")
        keybindCorner.CornerRadius = UDim.new(0, 3)
        keybindCorner.Parent = keybindBox
    end
    
    local toggle = Instance.new("TextButton")
    toggle.Name = "ToggleButton"
    toggle.Size = UDim2.new(0, 40, 0, 18)
    toggle.Position = UDim2.new(1, -45, 0.5, -9)
    toggle.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    toggle.BorderSizePixel = 0
    toggle.Text = "OFF"
    toggle.TextColor3 = Color3.fromRGB(200, 200, 200)
    toggle.TextSize = 11
    toggle.Font = Enum.Font.GothamBold
    toggle.ZIndex = frame.ZIndex + 1
    toggle.Parent = frame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 9)
    toggleCorner.Parent = toggle
    
    Core.toggleStates[name] = false
    Core.toggleFrames[name] = frame
    
    local function updateToggle()
        local isEnabled = Core.toggleStates[name]
        if isEnabled then
            toggle.BackgroundColor3 = Color3.fromRGB(86, 101, 245)
            toggle.Text = "ON"
            toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            toggle.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            toggle.Text = "OFF"
            toggle.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end
    
    toggle.MouseButton1Click:Connect(function()
        Core.toggleStates[name] = not Core.toggleStates[name]
        updateToggle()
        NotificationSystem.showToggleNotification(name, Core.toggleStates[name])
        if callback then callback(Core.toggleStates[name]) end
    end)
    
    Core.toggleButtons[name] = function()
        Core.toggleStates[name] = not Core.toggleStates[name]
        updateToggle()
        NotificationSystem.showToggleNotification(name, Core.toggleStates[name])
        if callback then callback(Core.toggleStates[name]) end
    end
    
    if keybindBox and keybindCallback then
        keybindBox.FocusLost:Connect(function()
            local key = keybindBox.Text:gsub("%s+", "")
            if key == "" then key = "None" end
            
            if key ~= "None" then
                if #key == 1 then
                    key = key:upper()
                elseif #key > 1 then
                    local validKeys = {
                        "SPACE", "LEFTSHIFT", "RIGHTSHIFT", "LEFTCONTROL", "RIGHTCONTROL",
                        "LEFTALT", "RIGHTALT", "TAB", "ESCAPE", "RETURN", "BACKSPACE"
                    }
                    local isValid = false
                    for _, validKey in pairs(validKeys) do
                        if key:upper() == validKey then
                            key = validKey
                            isValid = true
                            break
                        end
                    end
                    if not isValid then key = "None" end
                end
            end
            
            keybindBox.Text = key
            keybindCallback(key)
        end)
        
        keybindBox.Focused:Connect(function()
            keybindBox.Text = ""
        end)
    end
    
    return frame, updateToggle
end

function UI.createDropdown(parent, name, options, default, callback, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order
    frame.ZIndex = parent.ZIndex + 1
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = frame.ZIndex + 1
    label.Parent = frame
    
    local dropdown = Instance.new("TextButton")
    dropdown.Size = UDim2.new(0.45, 0, 0.7, 0)
    dropdown.Position = UDim2.new(0.5, 5, 0.15, 0)
    dropdown.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    dropdown.BorderSizePixel = 0
    dropdown.Text = default
    dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdown.TextSize = 13
    dropdown.Font = Enum.Font.GothamBold
    dropdown.ZIndex = frame.ZIndex + 1
    dropdown.Parent = frame
    
    local dropCorner = Instance.new("UICorner")
    dropCorner.CornerRadius = UDim.new(0, 3)
    dropCorner.Parent = dropdown
    
    local currentIndex = 1
    for i, option in pairs(options) do
        if option == default then
            currentIndex = i
            break
        end
    end
    
    dropdown.MouseButton1Click:Connect(function()
        currentIndex = currentIndex + 1
        if currentIndex > #options then currentIndex = 1 end
        local newOption = options[currentIndex]
        dropdown.Text = newOption
        if callback then callback(newOption) end
    end)
    
    return frame, dropdown
end

function UI.createSlider(parent, name, min, max, default, callback, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 45)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order
    frame.ZIndex = parent.ZIndex + 1
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 3)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. default
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = frame.ZIndex + 1
    label.Parent = frame
    
    local sliderBack = Instance.new("Frame")
    sliderBack.Size = UDim2.new(1, -20, 0, 6)
    sliderBack.Position = UDim2.new(0, 10, 0, 30)
    sliderBack.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    sliderBack.BorderSizePixel = 0
    sliderBack.ZIndex = frame.ZIndex + 1
    sliderBack.Parent = frame
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 3)
    sliderCorner.Parent = sliderBack
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(86, 101, 245)
    sliderFill.BorderSizePixel = 0
    sliderFill.ZIndex = sliderBack.ZIndex + 1
    sliderFill.Parent = sliderBack
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = sliderFill
    
    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Size = UDim2.new(0, 12, 0, 12)
    sliderBtn.Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6)
    sliderBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderBtn.BorderSizePixel = 0
    sliderBtn.Text = ""
    sliderBtn.ZIndex = sliderBack.ZIndex + 2
    sliderBtn.Parent = sliderBack
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = sliderBtn
    
    local dragging = false
    local currentValue = default
    
    sliderBtn.MouseButton1Down:Connect(function() dragging = true end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mouse = Players.LocalPlayer:GetMouse()
            local relativeX = mouse.X - sliderBack.AbsolutePosition.X
            local percentage = math.clamp(relativeX / sliderBack.AbsoluteSize.X, 0, 1)
            
            currentValue = min + (max - min) * percentage
            -- Special handling for randomization slider to only allow integers
            if name == "Text Randomization" then
                currentValue = math.floor(currentValue + 0.5) -- Round to nearest integer
            elseif max <= 10 then
                currentValue = math.floor(currentValue * 10) / 10
            else
                currentValue = math.floor(currentValue)
            end
            
            label.Text = name .. ": " .. currentValue
            
            sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
            sliderBtn.Position = UDim2.new(percentage, -6, 0.5, -6)
            
            if callback then callback(currentValue) end
        end
    end)
    
    return frame
end

function UI.createTextInput(parent, name, default, callback, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order
    frame.ZIndex = parent.ZIndex + 1
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.3, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = frame.ZIndex + 1
    label.Parent = frame
    
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0.65, 0, 0.7, 0)
    textBox.Position = UDim2.new(0.3, 5, 0.15, 0)
    textBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    textBox.BorderSizePixel = 0
    textBox.Text = default
    textBox.PlaceholderText = "Enter text..."
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.TextSize = 13
    textBox.Font = Enum.Font.GothamBold
    textBox.ClearTextOnFocus = false
    textBox.ZIndex = frame.ZIndex + 1
    textBox.Parent = frame
    
    local textBoxCorner = Instance.new("UICorner")
    textBoxCorner.CornerRadius = UDim.new(0, 3)
    textBoxCorner.Parent = textBox
    
    textBox.FocusLost:Connect(function()
        local text = textBox.Text:gsub("^%s*(.-)%s*$", "%1")
        if text ~= "" then
            if callback then callback(text) end
        else
            textBox.Text = default
        end
    end)
    
    return frame
end

-- === MAIN INITIALIZATION ===
local function init()
    local gui, main, titleBar, closeBtn = createCSGOGUI()
    Core.gui = gui
    
    makeDraggable(main, titleBar)
    
    local tabs, createTab, content = UI.createTabSystem(main, 30)
    
    KeybindSystem.init()
    NotificationSystem.createNotificationGUI()
    
    local movementTab = createTab("Movement", 1)
    local combatTab = createTab("Combat", 2)
    local playerTab = createTab("Player", 3) 
    local visualsTab = createTab("Visuals", 4)
    local exploitsTab = createTab("Exploits", 5)
    local anticheatTab = createTab("Anticheat", 6)
    local settingsTab = createTab("Settings", 7)
    
    -- Set default active tab
    tabs.Movement.button.BackgroundColor3 = Color3.fromRGB(86, 101, 245)
    tabs.Movement.button.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabs.Movement.content.Visible = true
    
    -- === MOVEMENT TAB ===
    UI.createSection(movementTab, "Speed Settings", 1)
    UI.createToggle(movementTab, "Speed", SpeedModule.toggle, 2, function(key)
        Core.keybinds.speed = key
    end)
    
    UI.createDropdown(movementTab, "Mode", {"Normal", "CFrame", "TP Walk", "Velocity", "Boost", "Penablox", "VRAN", "Bedwars"}, "Normal", function(mode)
        SpeedModule.mode = mode
        local speedSlider = movementTab:FindFirstChild("SpeedSlider")
        local velocitySlider = movementTab:FindFirstChild("VelocitySlider")
        local boostModeDropdown = movementTab:FindFirstChild("BoostModeDropdown")
        local boostSpeedSlider = movementTab:FindFirstChild("BoostSpeedSlider")
        local boostTimeSlider = movementTab:FindFirstChild("BoostTimeSlider")
        local boostCooldownSlider = movementTab:FindFirstChild("BoostCooldownSlider")
        
        if speedSlider then speedSlider.Visible = false end
        if velocitySlider then velocitySlider.Visible = false end
        if boostModeDropdown then boostModeDropdown.Visible = false end
        if boostSpeedSlider then boostSpeedSlider.Visible = false end
        if boostTimeSlider then boostTimeSlider.Visible = false end
        if boostCooldownSlider then boostCooldownSlider.Visible = false end
        
        if mode == "Normal" or mode == "CFrame" or mode == "TP Walk" then
            if speedSlider then speedSlider.Visible = true end
        elseif mode == "Velocity" then
            if velocitySlider then velocitySlider.Visible = true end
        elseif mode == "Boost" then
            if boostModeDropdown then boostModeDropdown.Visible = true end
            if boostSpeedSlider then boostSpeedSlider.Visible = true end
            if boostTimeSlider then boostTimeSlider.Visible = true end
            if boostCooldownSlider then boostCooldownSlider.Visible = true end
        end
        
        if Core.toggleStates.Speed then SpeedModule.toggle(true) end
    end, 3)
    
    local speedSlider = UI.createSlider(movementTab, "Value", 16, 200, 50, function(value)
        SpeedModule.value = value
        if Core.toggleStates.Speed then SpeedModule.toggle(true) end
    end, 4)
    speedSlider.Name = "SpeedSlider"
    
    local velocitySlider = UI.createSlider(movementTab, "Velocity Speed", 10, 150, 50, function(value)
        SpeedModule.velocitySpeed = value
        if Core.toggleStates.Speed and SpeedModule.mode == "Velocity" then SpeedModule.toggle(true) end
    end, 5)
    velocitySlider.Name = "VelocitySlider"
    velocitySlider.Visible = false
    
    local boostModeDropdown = UI.createDropdown(movementTab, "Boost Mode", {"Normal", "CFrame", "TP Walk", "Velocity"}, "Normal", function(mode)
        SpeedModule.boostMode = mode
        if Core.toggleStates.Speed and SpeedModule.mode == "Boost" then SpeedModule.toggle(true) end
    end, 6)
    boostModeDropdown.Name = "BoostModeDropdown"
    boostModeDropdown.Visible = false
    
    local boostSpeedSlider = UI.createSlider(movementTab, "Boost Speed", 16, 200, 100, function(value)
        SpeedModule.boostSpeed = value
    end, 7)
    boostSpeedSlider.Name = "BoostSpeedSlider"
    boostSpeedSlider.Visible = false
    
    local boostTimeSlider = UI.createSlider(movementTab, "Boost Time (ms)", 50, 2500, 1000, function(value)
        SpeedModule.boostTime = value / 1000
    end, 8)
    boostTimeSlider.Name = "BoostTimeSlider"
    boostTimeSlider.Visible = false
    
    local boostCooldownSlider = UI.createSlider(movementTab, "Boost Cooldown (ms)", 50, 2500, 1500, function(value)
        SpeedModule.boostCooldown = value / 1000
    end, 9)
    boostCooldownSlider.Name = "BoostCooldownSlider"
    boostCooldownSlider.Visible = false
    
    UI.createToggle(movementTab, "Only When Pressing Key", function(enabled)
        SpeedModule.onlyWhenPressed = enabled
    end, 10)
    
    -- Speed activation key input
    local speedKeyFrame = Instance.new("Frame")
    speedKeyFrame.Size = UDim2.new(1, 0, 0, 30)
    speedKeyFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    speedKeyFrame.BorderSizePixel = 0
    speedKeyFrame.LayoutOrder = 11
    speedKeyFrame.ZIndex = movementTab.ZIndex + 1
    speedKeyFrame.Parent = movementTab
    
    local speedKeyCorner = Instance.new("UICorner")
    speedKeyCorner.CornerRadius = UDim.new(0, 4)
    speedKeyCorner.Parent = speedKeyFrame
    
    local speedKeyLabel = Instance.new("TextLabel")
    speedKeyLabel.Size = UDim2.new(0.6, 0, 1, 0)
    speedKeyLabel.Position = UDim2.new(0, 10, 0, 0)
    speedKeyLabel.BackgroundTransparency = 1
    speedKeyLabel.Text = "Activation Key"
    speedKeyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedKeyLabel.TextSize = 14
    speedKeyLabel.Font = Enum.Font.GothamBold
    speedKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
    speedKeyLabel.ZIndex = speedKeyFrame.ZIndex + 1
    speedKeyLabel.Parent = speedKeyFrame
    
    local speedKeyBox = Instance.new("TextBox")
    speedKeyBox.Size = UDim2.new(0.35, 0, 0.6, 0)
    speedKeyBox.Position = UDim2.new(0.6, 5, 0.2, 0)
    speedKeyBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    speedKeyBox.BorderSizePixel = 0
    speedKeyBox.Text = "Space"
    speedKeyBox.PlaceholderText = "Key"
    speedKeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedKeyBox.TextSize = 13
    speedKeyBox.Font = Enum.Font.GothamBold
    speedKeyBox.ZIndex = speedKeyFrame.ZIndex + 1
    speedKeyBox.Parent = speedKeyFrame
    
    local speedKeyBoxCorner = Instance.new("UICorner")
    speedKeyBoxCorner.CornerRadius = UDim.new(0, 3)
    speedKeyBoxCorner.Parent = speedKeyBox
    
    speedKeyBox.FocusLost:Connect(function()
        local key = speedKeyBox.Text:gsub("%s+", "")
        if key == "" then key = "Space" end
        
        if key ~= "Space" then
            if #key == 1 then
                key = key:upper()
            elseif #key > 1 then
                local validKeys = {
                    "SPACE", "LEFTSHIFT", "RIGHTSHIFT", "LEFTCONTROL", "RIGHTCONTROL"
                }
                local isValid = false
                for _, validKey in pairs(validKeys) do
                    if key:upper() == validKey then
                        key = validKey
                        isValid = true
                        break
                    end
                end
                if not isValid then key = "Space" end
            end
        end
        
        speedKeyBox.Text = key
        SpeedModule.activationKey = key
        Core.keybinds.speedActivation = key
    end)
    
    speedKeyBox.Focused:Connect(function()
        speedKeyBox.Text = ""
    end)
    
    UI.createSection(movementTab, "Fly Settings", 12)
    UI.createToggle(movementTab, "Fly", FlyModule.toggle, 13, function(key)
        Core.keybinds.fly = key
    end)
    
    UI.createDropdown(movementTab, "Mode", {"Velocity", "Physics", "Oscillating", "Bedwars", "Penablox"}, "Velocity", function(mode)
        local wasEnabled = Core.toggleStates.Fly
        
        if wasEnabled then FlyModule.toggle(false) end
        FlyModule.cleanupModeEffects()
        
        if FlyModule.mode == "Penablox" and mode ~= "Penablox" then
            FlyModule.penabloxAntiHeightKick = false
            local antiHeightKickToggle = movementTab:FindFirstChild("AntiHeightKickToggle")
            if antiHeightKickToggle then
                local toggleButton = antiHeightKickToggle:FindFirstChild("ToggleButton")
                if toggleButton then
                    toggleButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
                    toggleButton.Text = "OFF"
                end
            end
        end
        
        FlyModule.mode = mode
        
        local flySpeedSlider = movementTab:FindFirstChild("FlySpeedSlider")
        local amplitudeSlider = movementTab:FindFirstChild("AmplitudeSlider")
        local oscSpeedSlider = movementTab:FindFirstChild("OscSpeedSlider")
        local verticalSpeedSlider = movementTab:FindFirstChild("VerticalSpeedSlider")
        local showTimerToggle = movementTab:FindFirstChild("ShowTimerToggle")
        local antiHeightKickToggle = movementTab:FindFirstChild("AntiHeightKickToggle")
        local penabloxBufferSlider = movementTab:FindFirstChild("PenabloxBufferSlider")
        local penabloxSizeSlider = movementTab:FindFirstChild("PenabloxSizeSlider")
        local penabloxDistanceSlider = movementTab:FindFirstChild("PenabloxDistanceSlider")
        
        BedwarsTimer.updateVisibility(false)
        
        if flySpeedSlider then flySpeedSlider.Visible = false end
        if amplitudeSlider then amplitudeSlider.Visible = false end
        if oscSpeedSlider then oscSpeedSlider.Visible = false end
        if verticalSpeedSlider then verticalSpeedSlider.Visible = false end
        if showTimerToggle then showTimerToggle.Visible = false end
        if antiHeightKickToggle then antiHeightKickToggle.Visible = false end
        if penabloxBufferSlider then penabloxBufferSlider.Visible = false end
        if penabloxSizeSlider then penabloxSizeSlider.Visible = false end
        if penabloxDistanceSlider then penabloxDistanceSlider.Visible = false end
        
        if mode == "Oscillating" then
            if flySpeedSlider then flySpeedSlider.Visible = true end
            if amplitudeSlider then amplitudeSlider.Visible = true end
            if oscSpeedSlider then oscSpeedSlider.Visible = true end
            if verticalSpeedSlider then verticalSpeedSlider.Visible = true end
        elseif mode == "Bedwars" then
            if showTimerToggle then showTimerToggle.Visible = true end
            BedwarsTimer.createTimerGUI()
        elseif mode == "Penablox" then
            if antiHeightKickToggle then antiHeightKickToggle.Visible = true end
            if penabloxBufferSlider then penabloxBufferSlider.Visible = true end
            if penabloxSizeSlider then penabloxSizeSlider.Visible = true end
            if penabloxDistanceSlider then penabloxDistanceSlider.Visible = true end
        else
            if flySpeedSlider then flySpeedSlider.Visible = true end
        end
        
        if wasEnabled then FlyModule.toggle(true) end
    end, 14)
    
    UI.createToggle(movementTab, "Disable Speed While Flying", function(enabled)
        SpeedModule.disableSpeed = enabled
    end, 15)
    
    local flySpeedSlider = UI.createSlider(movementTab, "Speed", 10, 150, 50, function(value)
        FlyModule.speed = value
    end, 16)
    flySpeedSlider.Name = "FlySpeedSlider"
    
    local amplitudeSlider = UI.createSlider(movementTab, "Oscillation Amplitude", 0.1, 6, 1.0, function(value)
        FlyModule.amplitude = value
    end, 17)
    amplitudeSlider.Name = "AmplitudeSlider"
    amplitudeSlider.Visible = false
    
    local oscSpeedSlider = UI.createSlider(movementTab, "Oscillation Speed", 0.1, 6, 1.0, function(value)
        FlyModule.oscSpeed = value
    end, 18)
    oscSpeedSlider.Name = "OscSpeedSlider"
    oscSpeedSlider.Visible = false
    
    local verticalSpeedSlider = UI.createSlider(movementTab, "Vertical Speed", 1, 40, 10, function(value)
        FlyModule.verticalSpeed = value
    end, 19)
    verticalSpeedSlider.Name = "VerticalSpeedSlider"
    verticalSpeedSlider.Visible = false
    
    local showTimerToggle = UI.createToggle(movementTab, "Show Fly Time", function(enabled)
        BedwarsTimer.updateVisibility(enabled)
    end, 20)
    showTimerToggle.Name = "ShowTimerToggle"
    showTimerToggle.Visible = false
    
    local antiHeightKickToggle = UI.createToggle(movementTab, "Anti Height Kick", function(enabled)
        FlyModule.penabloxAntiHeightKick = enabled
        if enabled then
            FlyModule.createGhostCeiling()
        else
            FlyModule.removeGhostCeiling()
        end
    end, 21)
    antiHeightKickToggle.Name = "AntiHeightKickToggle"
    antiHeightKickToggle.Visible = false
    
    local penabloxBufferSlider = UI.createSlider(movementTab, "Platform Buffer", 0.1, 2.0, 0.5, function(value)
        FlyModule.penabloxPlatformBuffer = value
    end, 22)
    penabloxBufferSlider.Name = "PenabloxBufferSlider"
    penabloxBufferSlider.Visible = false
    
    local penabloxSizeSlider = UI.createSlider(movementTab, "Platform Size", 0.5, 3.0, 1.0, function(value)
        FlyModule.penabloxPlatformSize = Vector3.new(value, 0.1, value)
    end, 23)
    penabloxSizeSlider.Name = "PenabloxSizeSlider"
    penabloxSizeSlider.Visible = false
    
    local penabloxDistanceSlider = UI.createSlider(movementTab, "Update Distance", 1.0, 5.0, 2.0, function(value)
        FlyModule.penabloxUpdateDistance = value
    end, 24)
    penabloxDistanceSlider.Name = "PenabloxDistanceSlider"
    penabloxDistanceSlider.Visible = false
    
    -- === COMBAT TAB ===
    UI.createSection(combatTab, "Aimbot Settings", 1)
    UI.createToggle(combatTab, "Aimbot", AimbotModule.toggle, 2, function(key)
        Core.keybinds.aimbot = key
    end)
    
    UI.createDropdown(combatTab, "Aimbot Mode", {"Camera", "Cursor"}, "Camera", function(mode)
        AimbotModule.mode = mode
    end, 3)
    
    UI.createToggle(combatTab, "Only When Pressing Mouse", function(enabled)
        AimbotModule.onlyWhenPressed = enabled
    end, 4)
    
    UI.createDropdown(combatTab, "Activation Button", {"MouseButton1", "MouseButton2"}, "MouseButton2", function(button)
        AimbotModule.activationButton = button
    end, 5)
    
    UI.createSlider(combatTab, "Smoothing", 0.1, 1.0, 0.2, function(value)
        AimbotModule.smoothing = value
    end, 6)
    
    UI.createSlider(combatTab, "FOV", 30, 180, 90, function(value)
        AimbotModule.fov = value
        AimbotModule.updateFOVCircle()
    end, 7)
    
    UI.createSlider(combatTab, "Max Distance", 100, 2000, 1000, function(value)
        AimbotModule.maxDistance = value
    end, 8)
    
    UI.createToggle(combatTab, "Ignore Teammates", function(enabled)
        AimbotModule.ignoreTeammates = enabled
    end, 9)
    
    UI.createToggle(combatTab, "Show FOV Circle", function(enabled)
        AimbotModule.showFOV = enabled
        AimbotModule.updateFOVCircle()
    end, 10)
    
    -- FOV Color picker
    local fovColorFrame = Instance.new("Frame")
    fovColorFrame.Size = UDim2.new(1, 0, 0, 30)
    fovColorFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    fovColorFrame.BorderSizePixel = 0
    fovColorFrame.LayoutOrder = 11
    fovColorFrame.ZIndex = combatTab.ZIndex + 1
    fovColorFrame.Parent = combatTab
    
    local fovColorCorner = Instance.new("UICorner")
    fovColorCorner.CornerRadius = UDim.new(0, 4)
    fovColorCorner.Parent = fovColorFrame
    
    local fovColorLabel = Instance.new("TextLabel")
    fovColorLabel.Size = UDim2.new(0.7, 0, 1, 0)
    fovColorLabel.Position = UDim2.new(0, 10, 0, 0)
    fovColorLabel.BackgroundTransparency = 1
    fovColorLabel.Text = "FOV Circle Color"
    fovColorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    fovColorLabel.TextSize = 14
    fovColorLabel.Font = Enum.Font.GothamBold
    fovColorLabel.TextXAlignment = Enum.TextXAlignment.Left
    fovColorLabel.ZIndex = fovColorFrame.ZIndex + 1
    fovColorLabel.Parent = fovColorFrame
    
    local fovColorBtn = Instance.new("TextButton")
    fovColorBtn.Size = UDim2.new(0, 50, 0, 18)
    fovColorBtn.Position = UDim2.new(1, -55, 0.5, -9)
    fovColorBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fovColorBtn.BorderSizePixel = 0
    fovColorBtn.Text = ""
    fovColorBtn.ZIndex = fovColorFrame.ZIndex + 1
    fovColorBtn.Parent = fovColorFrame
    
    local fovColorBtnCorner = Instance.new("UICorner")
    fovColorBtnCorner.CornerRadius = UDim.new(0, 3)
    fovColorBtnCorner.Parent = fovColorBtn
    
    local fovColors = {
        Color3.new(1, 1, 1), Color3.new(1, 0, 0), Color3.new(0, 1, 0), Color3.new(0, 0, 1),
        Color3.new(1, 1, 0), Color3.new(1, 0, 1), Color3.new(0, 1, 1), Color3.new(1, 0.5, 0)
    }
    
    local fovColorIndex = 1
    fovColorBtn.MouseButton1Click:Connect(function()
        fovColorIndex = fovColorIndex + 1
        if fovColorIndex > #fovColors then fovColorIndex = 1 end
        local newColor = fovColors[fovColorIndex]
        fovColorBtn.BackgroundColor3 = newColor
        AimbotModule.updateFOVColor(newColor)
    end)
    
    -- === PLAYER TAB ===
    UI.createSection(playerTab, "Player Options", 1)
    UI.createToggle(playerTab, "Noclip", NoclipModule.toggle, 2, function(key)
        Core.keybinds.noclip = key
    end)
    
    UI.createDropdown(playerTab, "Noclip Mode", {"Vanilla"}, "Vanilla", function(mode)
        NoclipModule.mode = mode
        if Core.toggleStates.Noclip then NoclipModule.toggle(true) end
    end, 3)
    
    UI.createToggle(playerTab, "Infinite Jump", function(enabled)
        if enabled then
            Core.connections.infJump = UserInputService.JumpRequest:Connect(function()
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        else
            if Core.connections.infJump then
                Core.connections.infJump:Disconnect()
                Core.connections.infJump = nil
            end
        end
    end, 4, function(key)
        Core.keybinds.infJump = key
    end)
    
    UI.createToggle(playerTab, "NoFall", NoFallModule.toggle, 5, function(key)
        Core.keybinds.nofall = key
    end)
    
    UI.createDropdown(playerTab, "NoFall Mode", {"Bedwars"}, "Bedwars", function(mode)
        NoFallModule.mode = mode
        if Core.toggleStates.NoFall then NoFallModule.toggle(true) end
    end, 6)
    
    -- === VISUALS TAB ===
    UI.createSection(visualsTab, "ESP Settings", 1)
    UI.createToggle(visualsTab, "ESP", ESPModule.toggle, 2, function(key)
        Core.keybinds.esp = key
    end)
    
    UI.createDropdown(visualsTab, "ESP Mode", {"Normal", "Team"}, "Normal", function(mode)
        ESPModule.mode = mode
        
        local normalColorFrame = visualsTab:FindFirstChild("NormalColorFrame")
        local teamColorFrame = visualsTab:FindFirstChild("TeamColorFrame")
        local enemyColorFrame = visualsTab:FindFirstChild("EnemyColorFrame")
        
        if normalColorFrame then normalColorFrame.Visible = mode == "Normal" end
        if teamColorFrame then teamColorFrame.Visible = mode == "Team" end
        if enemyColorFrame then enemyColorFrame.Visible = mode == "Team" end
        
        ESPModule.updateLoop()
    end, 3)
    
    -- Normal mode color picker
    local normalColorFrame = Instance.new("Frame")
    normalColorFrame.Name = "NormalColorFrame"
    normalColorFrame.Size = UDim2.new(1, 0, 0, 30)
    normalColorFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    normalColorFrame.BorderSizePixel = 0
    normalColorFrame.LayoutOrder = 4
    normalColorFrame.ZIndex = visualsTab.ZIndex + 1
    normalColorFrame.Parent = visualsTab
    
    local normalColorCorner = Instance.new("UICorner")
    normalColorCorner.CornerRadius = UDim.new(0, 4)
    normalColorCorner.Parent = normalColorFrame
    
    local normalColorLabel = Instance.new("TextLabel")
    normalColorLabel.Size = UDim2.new(0.7, 0, 1, 0)
    normalColorLabel.Position = UDim2.new(0, 10, 0, 0)
    normalColorLabel.BackgroundTransparency = 1
    normalColorLabel.Text = "ESP Color"
    normalColorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    normalColorLabel.TextSize = 14
    normalColorLabel.Font = Enum.Font.GothamBold
    normalColorLabel.TextXAlignment = Enum.TextXAlignment.Left
    normalColorLabel.ZIndex = normalColorFrame.ZIndex + 1
    normalColorLabel.Parent = normalColorFrame
    
    local normalColorBtn = Instance.new("TextButton")
    normalColorBtn.Size = UDim2.new(0, 50, 0, 18)
    normalColorBtn.Position = UDim2.new(1, -55, 0.5, -9)
    normalColorBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    normalColorBtn.BorderSizePixel = 0
    normalColorBtn.Text = ""
    normalColorBtn.ZIndex = normalColorFrame.ZIndex + 1
    normalColorBtn.Parent = normalColorFrame
    
    local normalColorBtnCorner = Instance.new("UICorner")
    normalColorBtnCorner.CornerRadius = UDim.new(0, 3)
    normalColorBtnCorner.Parent = normalColorBtn
    
    -- Team mode color pickers
    local teamColorFrame = Instance.new("Frame")
    teamColorFrame.Name = "TeamColorFrame"
    teamColorFrame.Size = UDim2.new(1, 0, 0, 30)
    teamColorFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    teamColorFrame.BorderSizePixel = 0
    teamColorFrame.LayoutOrder = 5
    teamColorFrame.ZIndex = visualsTab.ZIndex + 1
    teamColorFrame.Visible = false
    teamColorFrame.Parent = visualsTab
    
    local teamColorCorner = Instance.new("UICorner")
    teamColorCorner.CornerRadius = UDim.new(0, 4)
    teamColorCorner.Parent = teamColorFrame
    
    local teamColorLabel = Instance.new("TextLabel")
    teamColorLabel.Size = UDim2.new(0.7, 0, 1, 0)
    teamColorLabel.Position = UDim2.new(0, 10, 0, 0)
    teamColorLabel.BackgroundTransparency = 1
    teamColorLabel.Text = "Team Color"
    teamColorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    teamColorLabel.TextSize = 14
    teamColorLabel.Font = Enum.Font.GothamBold
    teamColorLabel.TextXAlignment = Enum.TextXAlignment.Left
    teamColorLabel.ZIndex = teamColorFrame.ZIndex + 1
    teamColorLabel.Parent = teamColorFrame
    
    local teamColorBtn = Instance.new("TextButton")
    teamColorBtn.Size = UDim2.new(0, 50, 0, 18)
    teamColorBtn.Position = UDim2.new(1, -55, 0.5, -9)
    teamColorBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    teamColorBtn.BorderSizePixel = 0
    teamColorBtn.Text = ""
    teamColorBtn.ZIndex = teamColorFrame.ZIndex + 1
    teamColorBtn.Parent = teamColorFrame
    
    local teamColorBtnCorner = Instance.new("UICorner")
    teamColorBtnCorner.CornerRadius = UDim.new(0, 3)
    teamColorBtnCorner.Parent = teamColorBtn
    
    local enemyColorFrame = Instance.new("Frame")
    enemyColorFrame.Name = "EnemyColorFrame"
    enemyColorFrame.Size = UDim2.new(1, 0, 0, 30)
    enemyColorFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    enemyColorFrame.BorderSizePixel = 0
    enemyColorFrame.LayoutOrder = 6
    enemyColorFrame.ZIndex = visualsTab.ZIndex + 1
    enemyColorFrame.Visible = false
    enemyColorFrame.Parent = visualsTab
    
    local enemyColorCorner = Instance.new("UICorner")
    enemyColorCorner.CornerRadius = UDim.new(0, 4)
    enemyColorCorner.Parent = enemyColorFrame
    
    local enemyColorLabel = Instance.new("TextLabel")
    enemyColorLabel.Size = UDim2.new(0.7, 0, 1, 0)
    enemyColorLabel.Position = UDim2.new(0, 10, 0, 0)
    enemyColorLabel.BackgroundTransparency = 1
    enemyColorLabel.Text = "Enemy Color"
    enemyColorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    enemyColorLabel.TextSize = 14
    enemyColorLabel.Font = Enum.Font.GothamBold
    enemyColorLabel.TextXAlignment = Enum.TextXAlignment.Left
    enemyColorLabel.ZIndex = enemyColorFrame.ZIndex + 1
    enemyColorLabel.Parent = enemyColorFrame
    
    local enemyColorBtn = Instance.new("TextButton")
    enemyColorBtn.Size = UDim2.new(0, 50, 0, 18)
    enemyColorBtn.Position = UDim2.new(1, -55, 0.5, -9)
    enemyColorBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    enemyColorBtn.BorderSizePixel = 0
    enemyColorBtn.Text = ""
    enemyColorBtn.ZIndex = enemyColorFrame.ZIndex + 1
    enemyColorBtn.Parent = enemyColorFrame
    
    local enemyColorBtnCorner = Instance.new("UICorner")
    enemyColorBtnCorner.CornerRadius = UDim.new(0, 3)
    enemyColorBtnCorner.Parent = enemyColorBtn
    
    local colors = {
        Color3.new(1, 0, 0), Color3.new(0, 1, 0), Color3.new(0, 0, 1),
        Color3.new(1, 1, 0), Color3.new(1, 0, 1), Color3.new(0, 1, 1),
        Color3.new(1, 1, 1), Color3.new(1, 0.5, 0), Color3.new(0.5, 0, 1)
    }
    
    local normalColorIndex = 1
    normalColorBtn.MouseButton1Click:Connect(function()
        normalColorIndex = normalColorIndex + 1
        if normalColorIndex > #colors then normalColorIndex = 1 end
        local newColor = colors[normalColorIndex]
        normalColorBtn.BackgroundColor3 = newColor
        ESPModule.updateColor(newColor, false)
    end)
    
    local teamColorIndex = 2
    teamColorBtn.MouseButton1Click:Connect(function()
        teamColorIndex = teamColorIndex + 1
        if teamColorIndex > #colors then teamColorIndex = 1 end
        local newColor = colors[teamColorIndex]
        teamColorBtn.BackgroundColor3 = newColor
        ESPModule.updateColor(newColor, true)
    end)
    
    local enemyColorIndex = 1
    enemyColorBtn.MouseButton1Click:Connect(function()
        enemyColorIndex = enemyColorIndex + 1
        if enemyColorIndex > #colors then enemyColorIndex = 1 end
        local newColor = colors[enemyColorIndex]
        enemyColorBtn.BackgroundColor3 = newColor
        ESPModule.updateColor(newColor, false)
    end)
    
    UI.createSection(visualsTab, "World Options", 7)
    UI.createToggle(visualsTab, "Fullbright", FullbrightModule.toggle, 8, function(key)
        Core.keybinds.fullbright = key
    end)
    
    UI.createSection(visualsTab, "Coordinates", 9)
    UI.createToggle(visualsTab, "Show Coordinates", CoordinatesModule.toggle, 10)
    
    UI.createSlider(visualsTab, "Update Rate (ms)", 50, 500, 100, function(value)
        CoordinatesModule.updateRate = value / 1000
    end, 11)
    
    UI.createSection(visualsTab, "Trail Effects", 12)
    UI.createToggle(visualsTab, "Block Trail", BlockTrailModule.toggle, 13, function(key)
        Core.keybinds.blockTrail = key
    end)
    
    UI.createSlider(visualsTab, "Trail Distance", 0.5, 5.0, 1.0, function(value)
        BlockTrailModule.trailDistance = value
    end, 14)
    
    UI.createSlider(visualsTab, "Block Size", 0.5, 3.0, 1.0, function(value)
        BlockTrailModule.blockSize = Vector3.new(value, value, value)
    end, 15)
    
    UI.createSlider(visualsTab, "Despawn Time", 0.2, 2.0, 0.5, function(value)
        BlockTrailModule.despawnTime = value
    end, 16)
    
    -- === EXPLOITS TAB ===
    UI.createSection(exploitsTab, "Message Spammer", 1)
    
    UI.createToggle(exploitsTab, "Message Spammer", MessageSpammer.toggle, 2, function(key)
        Core.keybinds.messageSpammer = key
    end)
    
    UI.createDropdown(exploitsTab, "Chat Mode", {"New", "Old", "Penablox"}, "New", function(mode)
        MessageSpammer.mode = mode
        if MessageSpammer.enabled then MessageSpammer.toggle(true) end
    end, 3)
    
    UI.createTextInput(exploitsTab, "Message:", "Cerial Hub On Top", function(text)
        MessageSpammer.message = text
    end, 4)
    
    UI.createSlider(exploitsTab, "Send Delay (ms)", 100, 5000, 500, function(value)
        MessageSpammer.delay = value / 1000
    end, 5)
    
    UI.createSlider(exploitsTab, "Text Randomization", 0, 10, 3, function(value)
        MessageSpammer.randomization = value
    end, 6)
    
    UI.createSection(exploitsTab, "Games", 7)
    
    UI.createDropdown(exploitsTab, "Game Mode", {"None", "Penablox"}, "None", function(mode)
        GameExploits.currentGame = mode
        
        local infAmmoToggle = exploitsTab:FindFirstChild("InfAmmoToggle")
        local semiWallbangToggle = exploitsTab:FindFirstChild("SemiWallbangToggle")
        
        if infAmmoToggle then infAmmoToggle.Visible = mode == "Penablox" end
        if semiWallbangToggle then semiWallbangToggle.Visible = mode == "Penablox" end
        
        if mode ~= "Penablox" then
            if Core.toggleStates["Infinite Ammo"] then ToggleManager.disableToggle("Infinite Ammo") end
            if Core.toggleStates["Semi Wallbang"] then ToggleManager.disableToggle("Semi Wallbang") end
            GameExploits.penabloxInfAmmo = false
            GameExploits.penabloxSemiWallbang = false
            GameExploits.penabloxAmmoLoop()
            GameExploits.cleanupWallSystem()
        end
    end, 8)
    
    local infAmmoToggle = UI.createToggle(exploitsTab, "Infinite Ammo", function(enabled)
        GameExploits.penabloxInfAmmo = enabled
        GameExploits.penabloxAmmoLoop()
    end, 9)
    infAmmoToggle.Name = "InfAmmoToggle"
    infAmmoToggle.Visible = false
    
    local semiWallbangToggle = UI.createToggle(exploitsTab, "Semi Wallbang", function(enabled)
        GameExploits.toggleSemiWallbang(enabled)
    end, 10)
    semiWallbangToggle.Name = "SemiWallbangToggle"
    semiWallbangToggle.Visible = false
    
    -- === ANTICHEAT TAB ===
    local betaWarning = Instance.new("Frame")
    betaWarning.Size = UDim2.new(1, 0, 0, 30)
    betaWarning.BackgroundColor3 = Color3.fromRGB(245, 166, 35)
    betaWarning.BorderSizePixel = 0
    betaWarning.LayoutOrder = 0
    betaWarning.ZIndex = anticheatTab.ZIndex + 1
    betaWarning.Parent = anticheatTab
    
    local warningCorner = Instance.new("UICorner")
    warningCorner.CornerRadius = UDim.new(0, 4)
    warningCorner.Parent = betaWarning
    
    local warningLabel = Instance.new("TextLabel")
    warningLabel.Size = UDim2.new(1, -10, 1, 0)
    warningLabel.Position = UDim2.new(0, 10, 0, 0)
    warningLabel.BackgroundTransparency = 1
    warningLabel.Text = "⚠ CLIENT-SIDE ANTICHEAT BETA V1 ⚠"
    warningLabel.TextColor3 = Color3.fromRGB(25, 25, 35)
    warningLabel.TextSize = 14
    warningLabel.Font = Enum.Font.GothamBold
    warningLabel.TextXAlignment = Enum.TextXAlignment.Center
    warningLabel.TextWrapped = true
    warningLabel.ZIndex = betaWarning.ZIndex + 1
    warningLabel.Parent = betaWarning
    
    local explanationFrame = Instance.new("Frame")
    explanationFrame.Size = UDim2.new(1, 0, 0, 80)
    explanationFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    explanationFrame.BorderSizePixel = 0
    explanationFrame.LayoutOrder = 1
    explanationFrame.ZIndex = anticheatTab.ZIndex + 1
    explanationFrame.Parent = anticheatTab
    
    local explanationCorner = Instance.new("UICorner")
    explanationCorner.CornerRadius = UDim.new(0, 4)
    explanationCorner.Parent = explanationFrame
    
    local explanationLabel = Instance.new("TextLabel")
    explanationLabel.Size = UDim2.new(1, -10, 1, 0)
    explanationLabel.Position = UDim2.new(0, 10, 0, 0)
    explanationLabel.BackgroundTransparency = 1
    explanationLabel.Text = "Custom Multiplier: Base speed thresholds are calculated as: Base WalkSpeed (16) × 1.8 × Multiplier. Example: With 1.5x multiplier, max speed becomes 16 × 1.8 × 1.5 = 43.2 before detection. Use higher values for games with sprint mechanics. Jump detection uses similar calculations with jump power/height."
    explanationLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
    explanationLabel.TextSize = 12
    explanationLabel.Font = Enum.Font.GothamBold
    explanationLabel.TextXAlignment = Enum.TextXAlignment.Left
    explanationLabel.TextWrapped = true
    explanationLabel.ZIndex = explanationFrame.ZIndex + 1
    explanationLabel.Parent = explanationFrame
    
    UI.createSection(anticheatTab, "Main Settings", 2)
    UI.createToggle(anticheatTab, "Enable Client Anticheat", AntiCheat.toggle, 3)
    
    UI.createSlider(anticheatTab, "Custom Multiplier", 1.0, 2.5, 1.0, function(value)
        AntiCheat.customMultiplier = value
        local serverInfoLabel = anticheatTab:FindFirstChild("ServerInfoFrame"):FindFirstChild("ServerInfoLabel")
        if serverInfoLabel then
            serverInfoLabel.Text = string.format("Server Settings:\nWalkSpeed: %d | Jump: %s | Max Speed: %.1f", 
                AntiCheat.serverSettings.walkSpeed,
                AntiCheat.serverSettings.useJumpPower and AntiCheat.serverSettings.jumpPower or AntiCheat.serverSettings.jumpHeight,
                AntiCheat.calculateThresholds().maxHorizontalSpeed)
        end
    end, 4)
    
    local serverInfoFrame = Instance.new("Frame")
    serverInfoFrame.Name = "ServerInfoFrame"
    serverInfoFrame.Size = UDim2.new(1, 0, 0, 45)
    serverInfoFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    serverInfoFrame.BorderSizePixel = 0
    serverInfoFrame.LayoutOrder = 5
    serverInfoFrame.ZIndex = anticheatTab.ZIndex + 1
    serverInfoFrame.Parent = anticheatTab
    
    local serverInfoCorner = Instance.new("UICorner")
    serverInfoCorner.CornerRadius = UDim.new(0, 4)
    serverInfoCorner.Parent = serverInfoFrame
    
    local serverInfoLabel = Instance.new("TextLabel")
    serverInfoLabel.Name = "ServerInfoLabel"
    serverInfoLabel.Size = UDim2.new(1, -10, 1, 0)
    serverInfoLabel.Position = UDim2.new(0, 10, 0, 0)
    serverInfoLabel.BackgroundTransparency = 1
    serverInfoLabel.Text = string.format("Server Settings:\nWalkSpeed: %d | Jump: %s | Max Speed: %.1f", 
        AntiCheat.serverSettings.walkSpeed,
        AntiCheat.serverSettings.useJumpPower and AntiCheat.serverSettings.jumpPower or AntiCheat.serverSettings.jumpHeight,
        AntiCheat.calculateThresholds().maxHorizontalSpeed)
    serverInfoLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
    serverInfoLabel.TextSize = 12
    serverInfoLabel.Font = Enum.Font.GothamBold
    serverInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    serverInfoLabel.TextWrapped = true
    serverInfoLabel.ZIndex = serverInfoFrame.ZIndex + 1
    serverInfoLabel.Parent = serverInfoFrame
    
    UI.createSection(anticheatTab, "Detection Targets", 6)
    
    UI.createToggle(anticheatTab, "Detect Others", function(enabled)
        AntiCheat.detectOthers = enabled
    end, 7)
    
    local othersColorFrame = Instance.new("Frame")
    othersColorFrame.Size = UDim2.new(1, 0, 0, 30)
    othersColorFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    othersColorFrame.BorderSizePixel = 0
    othersColorFrame.LayoutOrder = 8
    othersColorFrame.ZIndex = anticheatTab.ZIndex + 1
    othersColorFrame.Parent = anticheatTab
    
    local othersColorCorner = Instance.new("UICorner")
    othersColorCorner.CornerRadius = UDim.new(0, 4)
    othersColorCorner.Parent = othersColorFrame
    
    local othersColorLabel = Instance.new("TextLabel")
    othersColorLabel.Size = UDim2.new(0.7, 0, 1, 0)
    othersColorLabel.Position = UDim2.new(0, 10, 0, 0)
    othersColorLabel.BackgroundTransparency = 1
    othersColorLabel.Text = "Others Color"
    othersColorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    othersColorLabel.TextSize = 14
    othersColorLabel.Font = Enum.Font.GothamBold
    othersColorLabel.TextXAlignment = Enum.TextXAlignment.Left
    othersColorLabel.ZIndex = othersColorFrame.ZIndex + 1
    othersColorLabel.Parent = othersColorFrame
    
    local othersColorBtn = Instance.new("TextButton")
    othersColorBtn.Size = UDim2.new(0, 50, 0, 18)
    othersColorBtn.Position = UDim2.new(1, -55, 0.5, -9)
    othersColorBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    othersColorBtn.BorderSizePixel = 0
    othersColorBtn.Text = ""
    othersColorBtn.ZIndex = othersColorFrame.ZIndex + 1
    othersColorBtn.Parent = othersColorFrame
    
    local othersColorBtnCorner = Instance.new("UICorner")
    othersColorBtnCorner.CornerRadius = UDim.new(0, 3)
    othersColorBtnCorner.Parent = othersColorBtn
    
    UI.createToggle(anticheatTab, "Detect Myself", function(enabled)
        AntiCheat.detectSelf = enabled
    end, 9)
    
    local selfColorFrame = Instance.new("Frame")
    selfColorFrame.Size = UDim2.new(1, 0, 0, 30)
    selfColorFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    selfColorFrame.BorderSizePixel = 0
    selfColorFrame.LayoutOrder = 10
    selfColorFrame.ZIndex = anticheatTab.ZIndex + 1
    selfColorFrame.Parent = anticheatTab
    
    local selfColorCorner = Instance.new("UICorner")
    selfColorCorner.CornerRadius = UDim.new(0, 4)
    selfColorCorner.Parent = selfColorFrame
    
    local selfColorLabel = Instance.new("TextLabel")
    selfColorLabel.Size = UDim2.new(0.7, 0, 1, 0)
    selfColorLabel.Position = UDim2.new(0, 10, 0, 0)
    selfColorLabel.BackgroundTransparency = 1
    selfColorLabel.Text = "Self Color"
    selfColorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    selfColorLabel.TextSize = 14
    selfColorLabel.Font = Enum.Font.GothamBold
    selfColorLabel.TextXAlignment = Enum.TextXAlignment.Left
    selfColorLabel.ZIndex = selfColorFrame.ZIndex + 1
    selfColorLabel.Parent = selfColorFrame
    
    local selfColorBtn = Instance.new("TextButton")
    selfColorBtn.Size = UDim2.new(0, 50, 0, 18)
    selfColorBtn.Position = UDim2.new(1, -55, 0.5, -9)
    selfColorBtn.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
    selfColorBtn.BorderSizePixel = 0
    selfColorBtn.Text = ""
    selfColorBtn.ZIndex = selfColorFrame.ZIndex + 1
    selfColorBtn.Parent = selfColorFrame
    
    local selfColorBtnCorner = Instance.new("UICorner")
    selfColorBtnCorner.CornerRadius = UDim.new(0, 3)
    selfColorBtnCorner.Parent = selfColorBtn
    
    local anticheatColors = {
        Color3.fromRGB(255, 100, 100), Color3.fromRGB(100, 255, 100), Color3.fromRGB(100, 100, 255),
        Color3.fromRGB(255, 255, 100), Color3.fromRGB(255, 100, 255), Color3.fromRGB(100, 255, 255),
        Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 150, 100), Color3.fromRGB(150, 100, 255)
    }
    
    local othersColorIndex = 1
    othersColorBtn.MouseButton1Click:Connect(function()
        othersColorIndex = othersColorIndex + 1
        if othersColorIndex > #anticheatColors then othersColorIndex = 1 end
        local newColor = anticheatColors[othersColorIndex]
        othersColorBtn.BackgroundColor3 = newColor
        AntiCheat.notificationColor = newColor
    end)
    
    local selfColorIndex = 2
    selfColorBtn.MouseButton1Click:Connect(function()
        selfColorIndex = selfColorIndex + 1
        if selfColorIndex > #anticheatColors then selfColorIndex = 1 end
        local newColor = anticheatColors[selfColorIndex]
        selfColorBtn.BackgroundColor3 = newColor
        AntiCheat.selfColor = newColor
    end)
    
    UI.createSection(anticheatTab, "Detection Types", 11)
    
    UI.createToggle(anticheatTab, "Speed Detection", function(enabled)
        AntiCheat.detections.speed = enabled
    end, 12)
    
    UI.createToggle(anticheatTab, "Fly Detection", function(enabled)
        AntiCheat.detections.fly = enabled
    end, 13)
    
    UI.createToggle(anticheatTab, "Noclip Detection", function(enabled)
        AntiCheat.detections.noclip = enabled
    end, 14)
    
    UI.createToggle(anticheatTab, "Teleport Detection", function(enabled)
        AntiCheat.detections.teleport = enabled
    end, 15)
    
    -- === SETTINGS TAB ===
    UI.createSection(settingsTab, "GUI Settings", 1)
    
    local guiKeybindFrame = Instance.new("Frame")
    guiKeybindFrame.Size = UDim2.new(1, 0, 0, 30)
    guiKeybindFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    guiKeybindFrame.BorderSizePixel = 0
    guiKeybindFrame.LayoutOrder = 2
    guiKeybindFrame.ZIndex = settingsTab.ZIndex + 1
    guiKeybindFrame.Parent = settingsTab
    
    local guiKeybindCorner = Instance.new("UICorner")
    guiKeybindCorner.CornerRadius = UDim.new(0, 4)
    guiKeybindCorner.Parent = guiKeybindFrame
    
    local guiKeybindLabel = Instance.new("TextLabel")
    guiKeybindLabel.Size = UDim2.new(0.6, 0, 1, 0)
    guiKeybindLabel.Position = UDim2.new(0, 10, 0, 0)
    guiKeybindLabel.BackgroundTransparency = 1
    guiKeybindLabel.Text = "GUI Toggle Key"
    guiKeybindLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    guiKeybindLabel.TextSize = 14
    guiKeybindLabel.Font = Enum.Font.GothamBold
    guiKeybindLabel.TextXAlignment = Enum.TextXAlignment.Left
    guiKeybindLabel.ZIndex = guiKeybindFrame.ZIndex + 1
    guiKeybindLabel.Parent = guiKeybindFrame
    
    local guiKeybindBox = Instance.new("TextBox")
    guiKeybindBox.Size = UDim2.new(0.35, 0, 0.6, 0)
    guiKeybindBox.Position = UDim2.new(0.6, 5, 0.2, 0)
    guiKeybindBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    guiKeybindBox.BorderSizePixel = 0
    guiKeybindBox.Text = "RightControl"
    guiKeybindBox.PlaceholderText = "Key"
    guiKeybindBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    guiKeybindBox.TextSize = 13
    guiKeybindBox.Font = Enum.Font.GothamBold
    guiKeybindBox.ZIndex = guiKeybindFrame.ZIndex + 1
    guiKeybindBox.Parent = guiKeybindFrame
    
    local guiKeybindBoxCorner = Instance.new("UICorner")
    guiKeybindBoxCorner.CornerRadius = UDim.new(0, 3)
    guiKeybindBoxCorner.Parent = guiKeybindBox
    
    guiKeybindBox.FocusLost:Connect(function()
        local key = guiKeybindBox.Text:gsub("%s+", "")
        if key == "" then key = "RightControl" end
        
        if key ~= "RightControl" and key ~= "None" then
            if #key == 1 then
                key = key:upper()
            elseif #key > 1 then
                local validKeys = {
                    "SPACE", "LEFTSHIFT", "RIGHTSHIFT", "LEFTCONTROL", "RIGHTCONTROL",
                    "LEFTALT", "RIGHTALT", "TAB", "ESCAPE", "RETURN", "BACKSPACE"
                }
                local isValid = false
                for _, validKey in pairs(validKeys) do
                    if key:upper() == validKey then
                        key = validKey
                        isValid = true
                        break
                    end
                end
                if not isValid then key = "RightControl" end
            end
        end
        
        guiKeybindBox.Text = key
        Core.keybinds.gui = key
    end)
    
    guiKeybindBox.Focused:Connect(function()
        guiKeybindBox.Text = ""
    end)
    
    UI.createSection(settingsTab, "Notification Settings", 3)
    
    UI.createDropdown(settingsTab, "Notification Position", {"Bottom Right", "Bottom Left", "Top Right", "Top Left"}, "Bottom Right", function(position)
        NotificationSystem.position = position
    end, 4)
    
    -- Event handlers
    closeBtn.MouseButton1Click:Connect(function()
        Core.fullCleanup()
        TweenService:Create(main, TweenInfo.new(0.3), {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        }):Play()
        wait(0.3)
        gui:Destroy()
    end)
    
    player.CharacterAdded:Connect(function()
        wait(1)
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            Core.originalWalkSpeed = player.Character.Humanoid.WalkSpeed
        end
        if Core.toggleStates.Speed then SpeedModule.toggle(true) end
        if Core.toggleStates.Fly then FlyModule.toggle(true) end
        if Core.toggleStates["Block Trail"] then BlockTrailModule.toggle(true) end
    end)
    
    Players.PlayerAdded:Connect(function(newPlayer)
        if newPlayer ~= player then
            newPlayer.CharacterAdded:Connect(function()
                wait(1)
                AntiCheat.initPlayerData(newPlayer)
            end)
        end
    end)
    
    Players.PlayerRemoving:Connect(function(leavingPlayer)
        AntiCheat.playerData[leavingPlayer] = nil
        AntiCheat.playerDetections[leavingPlayer] = nil
    end)
    
    main.Size = UDim2.new(0, 0, 0, 0)
    main.BackgroundTransparency = 1
    
    TweenService:Create(main, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 620, 0, 450),
        BackgroundTransparency = 0
    }):Play()
    
    print("Cerials Hub - FIXED Aimbot with FOV Circle & Camera/Cursor Modes!")
    print("🎯 FIXED AIMBOT FEATURES:")
    print("✅ FIXED: Accurate FOV calculation using proper screen pixel conversion")
    print("✅ FIXED: Enhanced target detection with better visibility checks")
    print("✅ FIXED: Proper mouse button detection for activation")
    print("✅ NEW: Camera Mode - Moves your camera to aim at targets")
    print("✅ NEW: Cursor Mode - Moves mouse cursor to target position")
    print("✅ NEW: FOV Circle - Visual circle showing aimbot detection range")
    print("✅ NEW: FOV Color Picker - Customize FOV circle color")
    print("✅ ENHANCED: Better team detection for 'Ignore Teammates'")
    print("✅ ENHANCED: Improved smoothing system for natural movement")
    print("✅ ENHANCED: More accurate distance and visibility checks")
    print("🔧 AIMBOT USAGE:")
    print("- Enable Aimbot and choose Camera or Cursor mode")
    print("- Adjust FOV (30-180 degrees) and smoothing (0.1-1.0)")
    print("- Toggle 'Show FOV Circle' to see detection area")
    print("- Use 'Only When Pressing Mouse' for manual control")
    print("- Right-click (default) or left-click to activate")
    print("- 'Ignore Teammates' prevents targeting team members")
    print("🎨 VISUAL IMPROVEMENTS:")
    print("✅ Better text readability with GothamBold font and larger sizes")
    print("✅ Enhanced tab visibility and keybind text clarity") 
    print("✅ Professional CSGO-style dark theme with blue accents")
    print("🛡️ ANTICHEAT FIXES & FEATURES:")
    print("✅ Fixed detection logic - notifications positioned 40px lower")
    print("✅ Added self-detection toggle with separate color coding")
    print("✅ Improved multiplier explanation with calculation examples")
    print("✅ Smart notification system with per-player counters")
    print("🔍 ENHANCED ESP SYSTEM:")
    print("✅ Normal mode: Single color for all players")
    print("✅ Team mode: Separate colors for teammates vs enemies")
    print("✅ Automatic team detection via Team/TeamColor properties")
    print("✅ Dynamic color switching based on team relationships")
    print("🆕 OTHER FEATURES:")
    print("✅ Draggable coordinates display in Visuals tab")
    print("✅ Speed 'Only When Pressing Key' option with custom keybind")
    print("✅ Message spammer randomization slider (0-10 characters)")
    print("✅ Fullbright now always loops to maintain effect")
    print("- Press " .. Core.keybinds.gui .. " to toggle GUI")
    print("- Combat tab includes working aimbot with FOV visualization")
    print("- ESP now supports both Normal and Team modes")
end

init()
