-- AI F3X Builder (Gemini 3) - unlimited parts, all tools always on
local MODELS = { "gemini-3-flash-preview", "gemini-2.5-flash", "gemini-3.1-flash-lite" }
local KEY_FILE = "ai_f3x_key.txt"

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

----------------------------------------------------------------
-- GUI FIRST
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "AIBuilder"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999

for _, place in ipairs({ function() return gethui and gethui() end,
                         function() return game:GetService("CoreGui") end,
                         function() return player:FindFirstChild("PlayerGui") end }) do
    pcall(function()
        local p = place()
        if p then
            local old = p:FindFirstChild("AIBuilder")
            if old then old:Destroy() end
        end
    end)
end

local parented = false
if gethui then parented = pcall(function() gui.Parent = gethui() end) and gui.Parent ~= nil end
if not parented then parented = pcall(function() gui.Parent = game:GetService("CoreGui") end) and gui.Parent ~= nil end
if not parented then gui.Parent = player:WaitForChild("PlayerGui") end

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(320, 240)
frame.Position = UDim2.new(0.5, -160, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame)

local scale = Instance.new("UIScale", frame)
pcall(function()
    local vp = workspace.CurrentCamera.ViewportSize
    scale.Scale = math.clamp(math.min((vp.Y - 40) / 240, (vp.X - 20) / 320, 1), 0.4, 1)
end)

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

local keyBox = styledBox(38, 32, "Paste Gemini API key here")
local promptBox = styledBox(76, 70, "Describe what to build... (say \"model\" to group it)")

local btn = Instance.new("TextButton", frame)
btn.Size = UDim2.new(1, -20, 0, 36)
btn.Position = UDim2.fromOffset(10, 154)
btn.Text = "Build"
btn.Font = Enum.Font.GothamBold
btn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
btn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", btn)

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1, -20, 0, 40)
status.Position = UDim2.fromOffset(10, 196)
status.BackgroundTransparency = 1
status.TextWrapped = true
status.TextSize = 12
status.TextColor3 = Color3.fromRGB(180, 180, 190)
status.Text = "Ready (AI button or RightShift toggles menu)"

local openBtn = Instance.new("TextButton", gui)
openBtn.Size = UDim2.fromOffset(48, 48)
openBtn.Position = UDim2.new(0, 10, 0.4, 0)
openBtn.Text = "AI"
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 16
openBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
openBtn.TextColor3 = Color3.new(1, 1, 1)
openBtn.Active = true
openBtn.Draggable = true
Instance.new("UICorner", openBtn)

local function toggleMenu() frame.Visible = not frame.Visible end
closeBtn.MouseButton1Click:Connect(function() frame.Visible = false end)
openBtn.MouseButton1Click:Connect(toggleMenu)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then toggleMenu() end
end)

pcall(function()
    if isfile and readfile and isfile(KEY_FILE) then keyBox.Text = readfile(KEY_FILE) end
end)

----------------------------------------------------------------
-- AI
----------------------------------------------------------------
local function buildSystem(wantModel, wantWeld)
    local s = {
        "You are an expert Roblox builder using F3X building tools. Reply with ONLY one JSON object, no prose, no code fences.",
        'Format: {"name":"ModelName","parts":[ ... ]}',
        'Each part: {"shape":"Normal|Wedge|Corner|Cylinder|Ball|Truss|Seat","pos":[x,y,z],"size":[x,y,z],"color":[r,g,b],"material":"Plastic|Wood|Brick|Concrete|Glass|Metal|Grass|Neon|SmoothPlastic|Marble|Granite|Slate|Sand|Ice|Fabric"'
            .. ', optional fields: "rot":[x,y,z] (degrees), "anchored":true|false (default true), "collide":true|false, "transparency":0-1, "reflectance":0-1'
            .. ', "surfaces":{"Top":"Smooth|Studs|Inlet|Weld|Glue|Universal","Bottom":"...","Front":"...","Back":"...","Left":"...","Right":"..."}'
            .. ', "light":{"type":"PointLight|SpotLight|SurfaceLight","range":number,"brightness":number,"color":[r,g,b]}'
            .. ', "effect":"Fire|Smoke|Sparkles"'
            .. (wantModel and ', "group":"SubModelName" (parts with the same group become a sub-model, e.g. Roof, Walls, Furniture)' or "")
            .. "}",
        "Positions are in studs relative to the build origin (0,0,0 = ground center, y up). Colors 0-255.",
        "Use as many parts as the build needs to look great. There is no part limit. Be detailed: layered or sloped roofs, window frames with glass panes, door frames, trim, pillars, steps, fences, plants, furniture, lamps and small props. Mix colors and materials realistically with varied part sizes.",
        "Parts must connect properly with no gaps or floating pieces, and everything sits on the ground at y=0. Use the optional fields whenever they improve the build (rotation for roofs and ramps, lights for lamps and windows, effects for fire, transparency for glass).",
    }
    if wantWeld then table.insert(s, 'Also include top-level "weld":true so all parts get welded together.') end
    return table.concat(s, "\n")
end

-- keep every complete part even if the reply got cut off
local function parseResult(text)
    local obj = text:match("%b{}")
    if obj then
        local ok, decoded = pcall(function() return HttpService:JSONDecode(obj) end)
        if ok and decoded.parts then return decoded end
    end
    local name = text:match('"name"%s*:%s*"([^"]*)"') or "AI Build"
    local startPos = text:find('"parts"%s*:%s*%[') or 1
    local body = text:sub(startPos)
    local parts = {}
    for chunk in body:gmatch("%b{}") do
        local ok, p = pcall(function() return HttpService:JSONDecode(chunk) end)
        if ok and type(p) == "table" and p.pos and p.size then table.insert(parts, p) end
    end
    if #parts == 0 then error("AI reply had no usable parts") end
    return { name = name, parts = parts }
end

local function askAI(key, prompt, wantModel, wantWeld)
    if not httpRequest then error("Executor has no request function") end
    local sys = buildSystem(wantModel, wantWeld)
    local lastErr = "Unknown error"
    local text, usedModel

    for attempt = 1, 2 do
        for _, model in ipairs(MODELS) do
            status.Text = "Asking " .. model .. "..."
            local url = "https://generativelanguage.googleapis.com/v1beta/models/" .. model .. ":generateContent"
            local useThinking = (model == "gemini-3-flash-preview")

            for pass = 1, 2 do
                local cfg = { maxOutputTokens = 60000 }
                if useThinking and pass == 1 then
                    cfg.thinkingConfig = { thinkingLevel = "low" }
                end
                local body = HttpService:JSONEncode({
                    systemInstruction = { parts = {{ text = sys }} },
                    contents = {{ role = "user", parts = {{ text = prompt }} }},
                    generationConfig = cfg,
                })
                local ok, res = pcall(httpRequest, {
                    Url = url, Method = "POST",
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
                        if text ~= "" then usedModel = model break end
                    end
                    lastErr = model .. ": " .. ((okJ and data.error and data.error.message) or tostring(res.Body))
                    print(lastErr)
                    if not (res.StatusCode == 400 and useThinking and pass == 1) then break end
                else
                    lastErr = tostring(res)
                    break
                end
            end
            if text and text ~= "" then break end
        end
        if text and text ~= "" then break end
        task.wait(3)
    end

    if not text or text == "" then error("API: " .. lastErr) end
    return parseResult(text), usedModel
end

----------------------------------------------------------------
-- F3X BUILDING (all tools always on)
----------------------------------------------------------------
local function getF3X()
    local function find(c)
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") and t:FindFirstChild("SyncAPI") then return t end
        end
    end
    return find(player.Backpack) or (player.Character and find(player.Character))
end

local function build(data, usedModel, wantModel, wantWeld)
    local tool = getF3X()
    if not tool then status.Text = "No F3X tool found!" return end
    local endpoint = tool.SyncAPI.ServerEndpoint
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then status.Text = "No character found" return end
    local origin = (hrp.CFrame * CFrame.new(0, -3, -25)).Position

    local function call(...)
        local args = { ... }
        local ok, res = pcall(function() return endpoint:InvokeServer(unpack(args)) end)
        if not ok then warn("F3X call failed:", args[1], res) end
        return ok and res or nil
    end

    local created, ungrouped, groups, groupOrder = {}, {}, {}, {}
    local parts = data.parts or {}

    for i, p in ipairs(parts) do
        status.Text = ("Building %d/%d (%s)"):format(i, #parts, usedModel or "?")
        if type(p.pos) == "table" and type(p.size) == "table" then
            local cf = CFrame.new(origin + Vector3.new(p.pos[1], p.pos[2], p.pos[3]))
            if type(p.rot) == "table" then
                cf = cf * CFrame.Angles(math.rad(p.rot[1] or 0), math.rad(p.rot[2] or 0), math.rad(p.rot[3] or 0))
            end
            local part = call("CreatePart", p.shape or "Normal", cf, workspace)
            if part then
                table.insert(created, part)
                call("SyncResize", {{ Part = part, CFrame = cf, Size = Vector3.new(p.size[1], p.size[2], p.size[3]) }})
                if p.rot then call("SyncRotate", {{ Part = part, CFrame = cf }}) end

                local c = p.color or {163, 162, 165}
                call("SyncColor", {{ Part = part, Color = Color3.fromRGB(c[1], c[2], c[3]), UnionColoring = false }})

                local matInfo = { Part = part, Material = Enum.Material[p.material or "Plastic"] or Enum.Material.Plastic }
                if p.transparency then matInfo.Transparency = p.transparency end
                if p.reflectance then matInfo.Reflectance = p.reflectance end
                call("SyncMaterial", { matInfo })

                if type(p.surfaces) == "table" then
                    local surf = {}
                    for face, kind in pairs(p.surfaces) do
                        if Enum.SurfaceType[kind] then surf[face] = Enum.SurfaceType[kind] end
                    end
                    call("SyncSurface", {{ Part = part, Surfaces = surf }})
                end
                if p.collide ~= nil then
                    call("SyncCollision", {{ Part = part, CanCollide = p.collide }})
                end
                if type(p.light) == "table" then
                    local lt = p.light.type or "PointLight"
                    call("CreateLights", {{ Part = part, LightType = lt }})
                    local lc = p.light.color or {255, 255, 255}
                    call("SyncLighting", {{ Part = part, LightType = lt, Range = p.light.range,
                        Brightness = p.light.brightness, Color = Color3.fromRGB(lc[1], lc[2], lc[3]) }})
                end
                if p.effect then
                    call("CreateDecorations", {{ Part = part, DecorationType = p.effect }})
                end
                local anchored = true
                if p.anchored ~= nil then anchored = p.anchored end
                call("SyncAnchor", {{ Part = part, Anchored = anchored }})

                if wantModel and type(p.group) == "string" and p.group ~= "" then
                    if not groups[p.group] then groups[p.group] = {} table.insert(groupOrder, p.group) end
                    table.insert(groups[p.group], part)
                else
                    table.insert(ungrouped, part)
                end
            end
        end
        task.wait(0.03)
    end

    if wantWeld and #created > 1 then
        status.Text = "Welding..."
        call("CreateWelds", created, created[1])
    end

    -- only make a Model when the prompt asked for it
    if wantModel and #created > 0 then
        status.Text = "Making model..."
        local items = {}
        for _, part in ipairs(ungrouped) do table.insert(items, part) end
        for _, gname in ipairs(groupOrder) do
            local g = call("CreateGroup", "Model", workspace, groups[gname])
            if g then
                call("SetName", { g }, gname)
                table.insert(items, g)
            else
                for _, part in ipairs(groups[gname]) do table.insert(items, part) end
            end
        end
        local model = call("CreateGroup", "Model", workspace, items)
        if model then call("SetName", { model }, tostring(data.name or "AI Build")) end
    end

    status.Text = ("Done! %d parts (%s)"):format(#created, usedModel or "?")
end

----------------------------------------------------------------
-- BUILD BUTTON
----------------------------------------------------------------
local busy = false
btn.MouseButton1Click:Connect(function()
    if busy then return end
    local key = keyBox.Text:gsub("%s", "")
    if key == "" then status.Text = "Paste your API key in the top box" return end
    if promptBox.Text == "" then status.Text = "Type what to build" return end
    pcall(function() if writefile then writefile(KEY_FILE, key) end end)

    local lower = promptBox.Text:lower()
    local wantModel = lower:find("model") ~= nil or lower:find("group") ~= nil
    local wantWeld = lower:find("weld") ~= nil

    busy = true
    status.Text = "Thinking..."
    local ok, err = pcall(function()
        local result, usedModel = askAI(key, promptBox.Text, wantModel, wantWeld)
        build(result, usedModel, wantModel, wantWeld)
    end)
    if not ok then
        status.Text = tostring(err):sub(1, 120)
        warn(err)
    end
    busy = false
end)

print("AI F3X Builder loaded")