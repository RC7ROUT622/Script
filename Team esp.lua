-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Teams = game:GetService("Teams")

local LocalPlayer = Players.LocalPlayer

-- State Variables
local activeTeamFilter = nil -- nil means showing all teams, or holds a Team object
local highlights = {}

-- Give Infinite Jump automatically on startup
UserInputService.JumpRequest:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Safe UI Parent for exploits
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimpleTeamEspGui"
screenGui.ResetOnSpawn = false
pcall(function()
    screenGui.Parent = CoreGui
end)
if screenGui.Parent ~= CoreGui then
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Draggable Single Button UI
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 160, 0, 45)
toggleBtn.Position = UDim2.new(0.5, -80, 0.2, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 14
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Text = "ESP: All Teams"
toggleBtn.Active = true
toggleBtn.Draggable = true
toggleBtn.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = toggleBtn

-- Function to get a list of active teams dynamically
local function getActiveTeams()
    local activeTeams = {}
    for _, team in ipairs(Teams:GetTeams()) do
        local playersInTeam = team:GetPlayers()
        if #playersInTeam > 0 then
            table.insert(activeTeams, team)
        end
    end
    return activeTeams
end

-- Button click cycles through: All Teams -> Team 1 -> Team 2 -> ... -> Back to All Teams
toggleBtn.MouseButton1Click:Connect(function()
    local teamsList = getActiveTeams()
    
    if activeTeamFilter == nil then
        if #teamsList > 0 then
            activeTeamFilter = teamsList[1]
            toggleBtn.Text = "ESP: " .. activeTeamFilter.Name
            toggleBtn.BackgroundColor3 = activeTeamFilter.TeamColor.Color
        else
            toggleBtn.Text = "ESP: All Teams (No Active)"
        end
    else
        local currentIndex = nil
        for i, team in ipairs(teamsList) do
            if team == activeTeamFilter then
                currentIndex = i
                break
            end
        end
        
        if currentIndex and currentIndex < #teamsList then
            activeTeamFilter = teamsList[currentIndex + 1]
            toggleBtn.Text = "ESP: " .. activeTeamFilter.Name
            toggleBtn.BackgroundColor3 = activeTeamFilter.TeamColor.Color
        else
            activeTeamFilter = nil
            toggleBtn.Text = "ESP: All Teams"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end
    end
end)

-- Render Loop to manage character highlights based on selected team
RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local hl = highlights[player]
            
            -- Check if player matches the current team filter
            local shouldShow = false
            if activeTeamFilter == nil then
                shouldShow = true
            elseif player.Team == activeTeamFilter then
                shouldShow = true
            end
            
            if shouldShow then
                if not hl or hl.Parent ~= char then
                    if hl then hl:Destroy() end
                    hl = Instance.new("Highlight")
                    hl.Adornee = char
                    hl.Parent = char
                    highlights[player] = hl
                end
                
                if player.Team then
                    hl.FillColor = player.Team.TeamColor.Color
                    hl.OutlineColor = player.Team.TeamColor.Color
                else
                    hl.FillColor = Color3.new(1, 1, 1)
                    hl.OutlineColor = Color3.new(1, 1, 1)
                end
                hl.Enabled = true
            else
                if hl then
                    hl:Destroy()
                    highlights[player] = nil
                end
            end
        end
    end
end)

-- Cleanup when players leave
Players.PlayerRemoving:Connect(function(player)
    if highlights[player] then
        highlights[player]:Destroy()
        highlights[player] = nil
    end
end)
