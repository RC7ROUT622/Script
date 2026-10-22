-- AI F3X Builder (Gemini 3) - key box + closable menu
local MODELS = { "gemini-3-flash-preview", "gemini-3.1-flash-lite", "gemini-2.5-flash" }
local KEY_FILE = "ai_f3x_key.txt"

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

local SYSTEM = [[You design Roblox builds. Reply with ONLY a JSON array, no prose, no code fences.
Each item: {"shape":"Normal|Wedge|Cylinder|Ball|Corner","pos":[x,y,z],"size":[x,y,z],"color":[r,g,b],"material":"Plastic|Wood|Brick|Concrete|Glass|Metal|Grass|Neon|SmoothPlastic"}
Positions in studs relative to build origin (0,0,0 = ground center, y up). Colors 0-255. Use at most 120 parts. Make it look good and structurally sensible.]]

local function getF3X()
    local function find(c)
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") and t:FindFirstChild("SyncAPI") then return t end
        end
    end
    return find(player.Backpack) or (player.Character and find(player.Character))
end

local function askAI(key, prompt, status)
    if not httpRequest then error("Executor has no request function") end

    local body = HttpService:JSONEncode({
        systemInstruction = { parts = {{ text = SYSTEM }} },
        contents = {{ role = "user", parts = {{ text = prompt }} }},
        generationConfig = { maxOutputTokens = 16000 },
    })

    local lastErr = "Unknown error"
    local text

    for attempt = 1, 2 do
        for _, model in ipairs(MODELS) do
            status.Text = "Asking " .. model .. "..."
            local url = "https://generativelanguage.googleapis.com/v1beta/models/" .. model .. ":generateContent"
            local ok, res = pcall(httpRequest, {
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json", ["x-goog-api-key"] = key },
                Body = body,
            })
            if ok and res and res.Body then
                print(model, "STATUS:", res.StatusCode)
                local okJ, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
                local cand = okJ and data.candidates and data.candidates[1]
                if cand and cand.content and cand.content.parts then
                    local out = {}
                    for _, part in ipairs(cand.content.parts) do
                        if part.text and not part.thought then table.insert(out, part.text) end
                    end
                    text = table.concat(out)
                    if text ~= "" then break end
                end
                lastErr = model .. ": " .. ((okJ and data.error and data.error.message) or tostring(res.Body))
                print(lastErr)
            else
                lastErr = tostring(res)
            end
        end
        if text and text ~= "" then break end
        task.wait(3)
    end

    if not text or text == "" then error("API: " .. lastErr) end
    local jsonText = text:match("%[.*%]")
    if not jsonText then error("AI reply had no JSON") end
    return HttpService:JSONDecode(jsonText)
end

local function build(parts, status)
    local tool = getF3X()
    if not tool then status.Text = "No F3X tool found!" return end
    local endpoint = tool.SyncAPI.ServerEndpoint
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local origin = (hrp.CFrame * CFrame.new(0, -3, -20)).Position

    for i, p in ipairs(parts) do
        status.Text = ("Building %d/%d"):format(i, #parts)
        local cf = CFrame.new(origin + Vector3.new(p.pos[1], p.pos[2], p.pos[3]))
        local ok, err = pcall(function()
            local part = endpoint:InvokeServer("CreatePart", p.shape or "Normal", cf, workspace)
            if not part then return end
            endpoint:InvokeServer("SyncResize", {{Part = part, CFrame = cf, Size = Vector3.new(p.size[1], p.size[2], p.size[3])}})
            endpoint:InvokeServer("SyncColor", {{Part = part, Color = Color3.fromRGB(p.color[1], p.color[2], p.color[3]), UnionColoring = false}})
            endpoint:InvokeServer("SyncMaterial", {{Part = part, Material = Enum.Material[p.material or "Plastic"] or Enum.Material.Plastic}})
            endpoint:InvokeServer("SyncAnchor", {{Part = part, Anchored = true}})
        end)
        if not ok then warn(err) end
        task.wait(0.05)
    end
    status.Text = "Done!"
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "AIBuilder"
gui.ResetOnSpawn = false
gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(320, 240)
frame.Position = UDim2.new(0.5, -160, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -50, 0, 30)
title.Position = UDim2.fromOffset(10, 4)
title.BackgroundTransparency = 1
title.Text = "AI F3X Builder"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.new(1, 1, 1)

local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.fromOffset(28, 28)
closeBtn.Position = UDim2.new(1, -36, 0, 5)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", closeBtn)

local function styledBox(y, h, placeholder)
    local b = Instance.new("TextBox", frame)
    b.Size = UDim2.new(1, -20, 0, h)
    b.Position = UDim2.fromOffset(10, y)
    b.PlaceholderText = placeholder
    b.Text = ""
    b.TextWrapped = true
    b.ClearTextOnFocus = false
    b.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
    Instance.new("UICorner", b)
    return b
end

local keyBox = styledBox(38, 34, "Paste Gemini API key here")
local promptBox = styledBox(80, 64, "Describe what to build...")

local btn = Instance.new("TextButton", frame)
btn.Size = UDim2.new(1, -20, 0, 36)
btn.Position = UDim2.fromOffset(10, 152)
btn.Text = "Build"
btn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
btn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", btn)

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1, -20, 0, 40)
status.Position = UDim2.fromOffset(10, 194)
status.BackgroundTransparency = 1
status.TextWrapped = true
status.TextColor3 = Color3.fromRGB(180, 180, 190)
status.Text = "Ready (RightShift toggles menu)"

-- load saved key if the executor supports files
pcall(function()
    if isfile and readfile and isfile(KEY_FILE) then
        keyBox.Text = readfile(KEY_FILE)
    end
end)

-- reopen button
local openBtn = Instance.new("TextButton", gui)
openBtn.Size = UDim2.fromOffset(44, 44)
openBtn.Position = UDim2.new(0, 10, 0.5, 0)
openBtn.Text = "AI"
openBtn.Font = Enum.Font.GothamBold
openBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
openBtn.TextColor3 = Color3.new(1, 1, 1)
openBtn.Visible = false
openBtn.Active = true
openBtn.Draggable = true
Instance.new("UICorner", openBtn)

local function setMenu(open)
    frame.Visible = open
    openBtn.Visible = not open
end

closeBtn.MouseButton1Click:Connect(function() setMenu(false) end)
openBtn.MouseButton1Click:Connect(function() setMenu(true) end)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        setMenu(not frame.Visible)
    end
end)

-- build button
local busy = false
btn.MouseButton1Click:Connect(function()
    if busy then return end
    local key = keyBox.Text:gsub("%s", "")
    if key == "" then status.Text = "Paste your API key in the top box" return end
    if promptBox.Text == "" then status.Text = "Type what to build" return end
    pcall(function() if writefile then writefile(KEY_FILE, key) end end)

    busy = true
    status.Text = "Thinking..."
    local ok, result = pcall(askAI, key, promptBox.Text, status)
    if ok then
        build(result, status)
    else
        status.Text = tostring(result):sub(1, 120)
        warn(result)
    end
    busy = false
end)