-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- State Variables
local noclipEnabled = false

-- Safe UI Parent for exploits
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NoclipGui"
screenGui.ResetOnSpawn = false
pcall(function()
    screenGui.Parent = CoreGui
end)
if screenGui.Parent ~= CoreGui then
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Draggable Toggle Button UI
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 160, 0, 45)
toggleBtn.Position = UDim2.new(0.5, -80, 0.3, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 14
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Text = "Noclip: OFF"
toggleBtn.Active = true
toggleBtn.Draggable = true
toggleBtn.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = toggleBtn

-- Button click toggles noclip on/off
toggleBtn.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    if noclipEnabled then
        toggleBtn.Text = "Noclip: ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    else
        toggleBtn.Text = "Noclip: OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end
end)

-- Noclip loop using Stepped to disable collisions on character parts
RunService.Stepped:Connect(function()
    if noclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)
