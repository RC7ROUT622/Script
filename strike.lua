-- Lightning Strike Script (0.2s Glowing Bolt, Dense/Compact Smoke Burst, 5s Ragdoll Stun, 30s Burn & Black Skin, Thunder Sound, Lockable UI)
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UIS = game:GetService("UserInputService")
local workspace = game:GetService("Workspace")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StrikeGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local damageEnabled = true -- Default state for damage toggle
local isLocked = false     -- Lock state for the main frame

-- Main Container Frame (Holds all utility buttons together)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 110, 0, 140)
mainFrame.Position = UDim2.new(0.8, 0, 0.35, 0)
mainFrame.BackgroundTransparency = 1
mainFrame.Active = true
mainFrame.Parent = screenGui

-- 1. Lock Button (Inside main frame, sits at the very top)
local btnLock = Instance.new("TextButton")
btnLock.Size = UDim2.new(1, 0, 0, 25)
btnLock.Position = UDim2.new(0, 0, 0, 0)
btnLock.Text = "Unlock"
btnLock.TextSize = 10
btnLock.BackgroundColor3 = Color3.fromRGB(0, 150, 0) -- Green means unlocked
btnLock.TextColor3 = Color3.new(1, 1, 1)
btnLock.Active = true
btnLock.Parent = mainFrame

-- 2. Damage Toggle Button
local btnToggleDmg = Instance.new("TextButton")
btnToggleDmg.Size = UDim2.new(1, 0, 0, 30)
btnToggleDmg.Position = UDim2.new(0, 0, 0, 30)
btnToggleDmg.Text = "Dmg: ON"
btnToggleDmg.TextSize = 11
btnToggleDmg.BackgroundColor3 = Color3.fromRGB(0, 120, 0) -- Green for ON
btnToggleDmg.TextColor3 = Color3.new(1, 1, 1)
btnToggleDmg.Active = true
btnToggleDmg.Parent = mainFrame

-- 3. Strike Button (Gray color)
local btnStrike = Instance.new("TextButton")
btnStrike.Size = UDim2.new(1, 0, 0, 35)
btnStrike.Position = UDim2.new(0, 0, 0, 65)
btnStrike.Text = "Strike Me!"
btnStrike.TextSize = 12
btnStrike.BackgroundColor3 = Color3.fromRGB(120, 120, 120) -- Gray
btnStrike.TextColor3 = Color3.new(1, 1, 1)
btnStrike.Active = true
btnStrike.Parent = mainFrame

-- Toggle lock state when clicking the Lock button
btnLock.MouseButton1Click:Connect(function()
    isLocked = not isLocked
    if isLocked then
        btnLock.Text = "Lock"
        btnLock.BackgroundColor3 = Color3.fromRGB(150, 0, 0) -- Red for locked
    else
        btnLock.Text = "Unlock"
        btnLock.BackgroundColor3 = Color3.fromRGB(0, 150, 0) -- Green for unlocked
    end
end)

-- Make Main Frame draggable only when NOT locked
local function makeMainDraggable()
    local isDragging = false
    local dragStart, startPos

    mainFrame.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            if isLocked then return end -- Blocks dragging completely if locked
            
            isDragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                end
            end)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

makeMainDraggable()

-- Toggle Damage Button Logic
btnToggleDmg.MouseButton1Click:Connect(function()
    damageEnabled = not damageEnabled
    if damageEnabled then
        btnToggleDmg.Text = "Dmg: ON"
        btnToggleDmg.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
    else
        btnToggleDmg.Text = "Dmg: OFF"
        btnToggleDmg.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
    end
end)

-- Strike Effect Logic
local function applyStrikeEffects(char, root)
    local originalColors = {}
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    
    if not humanoid then return end

    -- 1. Apply conditional damage
    if damageEnabled then
        humanoid.Health = math.max(0, humanoid.Health - 25)
    end

    -- 2. Play explicit thunder sound effect
    local strikeSound = Instance.new("Sound")
    strikeSound.SoundId = "rbxassetid://9114220405"
    strikeSound.Volume = 2.5
    strikeSound.Parent = root
    strikeSound:Play()
    game:GetService("Debris"):AddItem(strikeSound, 3)

    -- 3. Add compact, high-density particle smoke for 0.20s
    local smokeEmitter = Instance.new("ParticleEmitter")
    smokeEmitter.Name = "CompactDenseSmoke"
    smokeEmitter.Texture = "rbxassetid://243444903"
    smokeEmitter.Color = ColorSequence.new(Color3.fromRGB(15, 15, 15))
    smokeEmitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 1.5)})
    smokeEmitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)})
    smokeEmitter.Rate = 800
    smokeEmitter.Speed = NumberRange.new(2, 6)
    smokeEmitter.Lifetime = NumberRange.new(0.3, 0.7)
    smokeEmitter.Parent = root

    task.delay(0.20, function()
        if smokeEmitter and smokeEmitter.Parent then
            smokeEmitter.Enabled = false
            game:GetService("Debris"):AddItem(smokeEmitter, 1)
        end
    end)

    -- 4. Add burning fire effect to character for 30 seconds
    local fire = Instance.new("Fire")
    fire.Name = "StrikeFire"
    fire.Size = 4
    fire.Heat = 10
    fire.Parent = root

    -- 5. Controlled moderate fling
    root.AssemblyLinearVelocity = Vector3.new(math.random(-15, 15), 35, math.random(-15, 15))

    -- 6. Turn body parts black for 30 seconds
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            originalColors[part] = part.Color
            part.Color = Color3.fromRGB(15, 15, 15)
        end
    end

    -- 7. Create glowing white vertical lightning rod with PointLight for exactly 0.20 seconds
    local bolt = Instance.new("Part")
    bolt.Name = "LightningBolt"
    bolt.Size = Vector3.new(2, 150, 2)
    bolt.CFrame = root.CFrame + Vector3.new(0, 75, 0)
    bolt.Anchored = true
    bolt.CanCollide = false
    bolt.Material = Enum.Material.Neon
    bolt.Color = Color3.fromRGB(255, 255, 255)
    bolt.Parent = workspace

    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 255, 255)
    light.Range = 60
    light.Brightness = 20
    light.Parent = bolt

    -- 8. Ragdoll stun state set to last for exactly 5 seconds
    humanoid.PlatformStand = true

    task.delay(5.0, function()
        if humanoid and humanoid.Parent then
            humanoid.PlatformStand = false
        end
    end)

    -- Remove the glowing lightning bolt and light after exactly 0.20 seconds
    task.delay(0.20, function()
        if bolt and bolt.Parent then
            bolt:Destroy()
        end
    end)

    -- Remove fire and restore skin color after exactly 30 seconds
    task.delay(30, function()
        if fire and fire.Parent then
            fire:Destroy()
        end

        -- Restore original skin color
        for part, col in pairs(originalColors) do
            if part and part.Parent then
                part.Color = col
            end
        end
        
        btnStrike.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
        btnStrike.Text = "Strike Me!"
    end)
end

-- Strike Action Logic
btnStrike.MouseButton1Click:Connect(function()
    local char = player.Character
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
    
    if root and char then
        btnStrike.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        btnStrike.Text = "STRIKED!"
        applyStrikeEffects(char, root)
    end
end)
