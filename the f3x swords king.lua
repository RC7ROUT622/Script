-- F3X Swords (one script). LocalScript in StarterGui. Keep F3X in your backpack.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ins, C, U = table.insert, Color3.fromRGB, UDim2.new
local NEON, METAL = Enum.Material.Neon, Enum.Material.Metal
local player = Players.LocalPlayer
if not player then
warn("[F3X] Must be a LocalScript in StarterGui")
return
end
local playerGui = player:WaitForChild("PlayerGui")
local function new(class, props, parent)
local o = Instance.new(class)
for k, v in pairs(props) do o[k] = v end
o.Parent = parent
return o
end
local function main()
local ORBIT_RADIUS, ORBIT_SPEED, SELF_SPIN = 5, 2, 4
local HEIGHT, LOADED_RADIUS, RISE_TIME = 9, 6, 0.5
local SWORD_SCALE, HUGE_SCALE, HUGE_HEIGHT = 0.8, 3, 26
local SHOOT_SPEED, MAX_RANGE = 120, 400
local PIN_DIST, UNPIN_DIST = 16, 24
local SYNC_EVERY, MAX_INFLIGHT = 0.05, 3
local PLATFORM_SIZE = 150
local COUNT = 7
local WHITE = C(255, 255, 255)
local BALL = Vector3.new(1.6, 1.6, 1.6)
local V, CF = Vector3.new, CFrame.new
local function hue(i) return Color3.fromHSV((i - 1) / 7 * 0.8, 0.85, 1) end
local del = { parts = true, players = false, platform = false }
local gui = new("ScreenGui", { Name = "F3XSwordsGui", ResetOnSpawn = false, DisplayOrder = 50 }, playerGui)
local column = new("Frame", {
BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Size = U(0, 150, 0, 0),
AnchorPoint = Vector2.new(0, 0.5), Position = U(0, 8, 0.5, 0),
}, gui)
new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, column)
local function makeButton(text, order, color, h)
local b = new("TextButton", {
Size = U(1, 0, 0, h or 38), LayoutOrder = order, BackgroundColor3 = color,
TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 15, Text = text,
}, column)
new("UICorner", {}, b)
return b
end
local buildBtn = makeButton("Build Rainbow", 1, C(60, 120, 255))
local loadBtn = makeButton("Load Sword", 2, C(255, 140, 20))
local fireBtn = makeButton("Fire", 3, C(200, 60, 60))
local combineBtn = makeButton("Combine", 4, C(150, 150, 160))
loadBtn.Visible, fireBtn.Visible, combineBtn.Visible = false, false, false
local delBtns = {}
for i, k in ipairs({ "parts", "players", "platform" }) do
local label = "Delete " .. k:sub(1, 1):upper() .. k:sub(2)
local b = makeButton("", 4 + i, C(90, 90, 100), 30)
local function upd()
b.Text = label .. ": " .. (del[k] and "ON" or "OFF")
b.BackgroundColor3 = del[k] and C(50, 160, 80) or C(90, 90, 100)
end
upd()
b.Visible = false
b.MouseButton1Click:Connect(function()
del[k] = not del[k]
upd()
end)
ins(delBtns, b)
end
local function showDel(v)
for _, b in ipairs(delBtns) do b.Visible = v end
end
local statusLabel = new("TextLabel", {
Size = U(1, 0, 0, 50), LayoutOrder = 10, BackgroundColor3 = C(20, 20, 28),
BackgroundTransparency = 0.3, TextColor3 = C(230, 230, 240), TextSize = 12,
TextWrapped = true, Text = "Ready",
}, column)
local function report(msg)
warn("[F3X] " .. tostring(msg))
statusLabel.Text = tostring(msg)
end
local function safe(name, fn)
return function(...)
local ok, err = pcall(fn, ...)
if not ok then report(name .. " error: " .. tostring(err)) end
end
end
local endpoint
local function refreshEndpoint()
if endpoint and endpoint.Parent then return true end
for _, c in ipairs({ player.Character, player.Backpack }) do
if c then
for _, tool in ipairs(c:GetChildren()) do
local api = tool:IsA("Tool") and tool:FindFirstChild("SyncAPI")
if api and api:FindFirstChild("ServerEndpoint") then
endpoint = api.ServerEndpoint
return true
end
end
end
end
return false
end
local function call(...)
if not refreshEndpoint() then return nil end
local args = { ... }
local ok, res = pcall(function()
return endpoint:InvokeServer(table.unpack(args))
end)
if not ok then
warn("[F3X] call failed: " .. tostring(res))
return nil
end
return res
end
local function getRoot()
return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end
local slots = {}
local active, building, combining = false, false, false
local free, syncT, inflight = false, 0, 0
local angle, loadCounter = 0, 0
local conn = nil
local stuck = {}
local function allParts()
local t = {}
for _, s in ipairs(slots) do
if s.block and s.block.Parent then ins(t, s.block) end
if s.sword then
for _, p in ipairs(s.sword.parts) do
if p.Parent then ins(t, p) end
end
end
end
return t
end
local function setFree(f)
free = f
local list = {}
for _, p in ipairs(allParts()) do ins(list, { Part = p, Anchored = not f }) end
if #list > 0 then task.spawn(call, "SyncAnchor", list) end
end
local function build(defs, fixed, weld)
local made, done = {}, 0
for i, d in ipairs(defs) do
task.spawn(function()
made[i] = call("CreatePart", d.shape, d.cf, workspace)
done = done + 1
end)
end
while done < #defs do task.wait() end
local rs, co, ma, cl, un, list = {}, {}, {}, {}, {}, {}
for i, d in ipairs(defs) do
local p = made[i]
if p then
ins(list, p)
ins(rs, { Part = p, Size = d.size, CFrame = d.cf })
ins(co, { Part = p, Color = d.color, UnionColoring = false })
ins(ma, { Part = p, Material = d.mat or NEON, Transparency = d.trans })
ins(cl, { Part = p, CanCollide = false })
ins(un, { Part = p, Anchored = false })
end
end
call("SyncResize", rs)
call("SyncColor", co)
call("SyncMaterial", ma)
call("SyncCollision", cl)
if weld and made[1] then call("CreateWelds", list, made[1]) end
if not fixed then
for _, p in ipairs(list) do
new("BodyForce", { Force = V(0, p.Mass * workspace.Gravity, 0) }, p)
end
if free then call("SyncAnchor", un) end
end
return made
end
local function swordDefs(color, scale, center)
local bp = {
{ "Normal", CF(0, 2.5, 0), V(1.2, 9, 0.35), NEON },
{ "Normal", CF(0, 7.2, 0) * CFrame.Angles(0, 0, math.rad(45)), V(0.85, 0.85, 0.35), NEON },
{ "Normal", CF(0, -2.2, 0), V(4.5, 0.6, 1), METAL },
{ "Normal", CF(0, -3.7, 0), V(0.6, 2.4, 0.6), METAL },
{ "Ball", CF(0, -5.2, 0), V(1, 1, 1), METAL },
}
local defs = {}
for i, b in ipairs(bp) do
local o = b[2]
defs[i] = {
shape = b[1], size = b[3] * scale, color = color, mat = b[4],
cf = center * (CF(o.Position * scale) * (CF(o.Position):Inverse() * o)),
}
end
return defs
end
local function toSword(made, defs)
local parts, rel, inv = {}, {}, defs[1].cf:Inverse()
for i, d in ipairs(defs) do
if made[i] then
ins(parts, made[i])
ins(rel, inv * d.cf)
end
end
if not made[1] then
if #parts > 0 then task.spawn(call, "Remove", parts) end
return nil
end
return { main = made[1], parts = parts, rel = rel }
end
local function place(part, cf)
part.CFrame = cf
part.AssemblyLinearVelocity = Vector3.zero
part.AssemblyAngularVelocity = Vector3.zero
end
local function placeSword(sw, cf)
for i, p in ipairs(sw.parts) do place(p, cf * sw.rel[i]) end
end
local function loadedCount()
local n = 0
for _, s in ipairs(slots) do
if s.state == "loaded" and not s.huge then n = n + 1 end
end
return n
end
local function lightning(center, removeNow)
local top = center + V(0, 80, 0)
local pts = { top }
for i = 1, 7 do
ins(pts, top:Lerp(center, i / 8) + V(math.random(-6, 6), 0, math.random(-6, 6)))
end
ins(pts, center)
local defs = {}
for i = 1, #pts - 1 do
local a, b = pts[i], pts[i + 1]
defs[i] = {
shape = "Normal", size = V(0.8, (b - a).Magnitude, 0.8), color = C(190, 225, 255),
cf = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(-math.pi / 2, 0, 0),
}
end
local made = build(defs, true)
if removeNow and #removeNow > 0 then call("Remove", removeNow) end
task.wait(0.6)
local rm = {}
for _, p in pairs(made) do ins(rm, p) end
call("Remove", rm)
end
local function trail(a, b, flightTime)
local len = (b - a).Magnitude
if len < 5 then return end
local base = CFrame.lookAt((a + b) / 2, b)
local defs = {}
for i = 1, 7 do
local ang = (i / 7) * math.pi * 2
defs[i] = {
shape = "Normal", size = V(0.7, 0.7, len), trans = 0.75, color = Color3.fromHSV(i / 7, 1, 1),
cf = base * CF(math.cos(ang) * 3, math.sin(ang) * 3, 0),
}
end
local made = build(defs, true)
task.wait((flightTime or 1) + 3)
local rm = {}
for _, p in pairs(made) do ins(rm, p) end
call("Remove", rm)
end
local function impact(hit)
local pos, normal, part = hit.Position, hit.Normal.Unit, hit.Instance
local deleted = false
if part and not part:IsA("Terrain") then
local model = part:FindFirstAncestorOfClass("Model")
local isPlayer = model and model:FindFirstChildOfClass("Humanoid")
local s = part.Size
local kind = isPlayer and "players" or (math.max(s.X, s.Y, s.Z) > PLATFORM_SIZE and "platform" or "parts")
if del[kind] then
local rm = { part }
if isPlayer then
rm = {}
for _, d in ipairs(model:GetDescendants()) do
if d:IsA("BasePart") then ins(rm, d) end
end
end
call("Remove", rm)
deleted = not part.Parent
end
end
local ref = math.abs(normal.Y) > 0.9 and V(1, 0, 0) or V(0, 1, 0)
local t1 = normal:Cross(ref).Unit
local t2 = normal:Cross(t1).Unit
local defs = {}
for i = 1, deleted and 0 or 9 do
local ang = (i / 9) * math.pi * 2 + math.random() * 0.4
local p0 = pos
for s = 1, 3 do
local len = math.random(5, 9)
ang = ang + (math.random() - 0.5) * 0.8
local p1 = p0 + (t1 * math.cos(ang) + t2 * math.sin(ang)) * len
ins(defs, {
shape = "Normal", size = V(0.9 - s * 0.2, 0.15, len + 0.3), color = C(255, 110, 20),
cf = CFrame.lookAt((p0 + p1) / 2 + normal * 0.1, p1 + normal * 0.1, normal),
})
p0 = p1
end
end
if #defs > 0 then build(defs, true) end
local c = pos + normal * 2
local balls = build({
{ shape = "Ball", cf = CF(c), size = V(2, 2, 2), color = C(255, 220, 120), trans = 0.2 },
{ shape = "Ball", cf = CF(c), size = V(3, 3, 3), color = C(255, 90, 20), trans = 0.45 },
}, true)
if not (balls[1] and balls[2]) then return end
for step = 1, 8 do
local k = step / 8
call("SyncResize", {
{ Part = balls[1], Size = V(1, 1, 1) * (2 + 20 * k), CFrame = CF(c) },
{ Part = balls[2], Size = V(1, 1, 1) * (3 + 32 * k), CFrame = CF(c) },
})
task.wait(0.07)
end
task.wait(5)
local rm = {}
for _, p in pairs(balls) do ins(rm, p) end
lightning(c, rm)
end
local function convert(slot)
local block, r = slot.block, getRoot()
slot.busy = true
local defs = swordDefs(slot.color, SWORD_SCALE, CF((r and r.Position or V(0, 50, 0)) + V(0, HEIGHT, 0)))
local sw = toSword(build(defs, false, true), defs)
slot.busy = false
if slot.state ~= "converting" then
if sw then call("Remove", sw.parts) end
return
end
if sw then
slot.sword = sw
slot.block = nil
loadCounter = loadCounter + 1
slot.loadedAt = loadCounter
slot.state = "loaded"
if block then task.spawn(call, "Remove", { block }) end
if loadedCount() == COUNT then
combineBtn.Visible = true
report("All 7 loaded! Combine!")
end
else
slot.state = "block"
end
end
local function endSet()
active, free, inflight = false, false, 0
if conn then
conn:Disconnect()
conn = nil
end
slots = {}
loadBtn.Visible, fireBtn.Visible, combineBtn.Visible = false, false, false
showDel(false)
buildBtn.Text = "Build Rainbow"
end
local function stopSet()
local rm = {}
for _, s in ipairs(slots) do
if s.block then ins(rm, s.block) end
if s.sword then
for _, p in ipairs(s.sword.parts) do ins(rm, p) end
end
s.block, s.sword, s.state = nil, nil, "done"
end
for _, sw in ipairs(stuck) do
for _, p in ipairs(sw.parts) do ins(rm, p) end
end
stuck = {}
if #rm > 0 then task.spawn(call, "Remove", rm) end
endSet()
end
local function frameUpdate(dt)
local r = getRoot()
if not r then return end
angle = angle + dt * ORBIT_SPEED
local head = r.Position + V(0, HEIGHT, 0)
local mine = allParts()
local near, lim = false, free and PIN_DIST or UNPIN_DIST
for _, pl in ipairs(Players:GetPlayers()) do
local h = pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
if h then
if (h.Position - r.Position).Magnitude < lim then near = true end
for _, p in ipairs(mine) do
if (h.Position - p.Position).Magnitude < lim then near = true end
end
end
end
if free == near then setFree(not near) end
local loaded, huge = {}, nil
for _, s in ipairs(slots) do
if s.state == "loaded" then
if s.sword and s.sword.main.Parent then
if s.huge then huge = s else ins(loaded, s) end
else
s.state = "done"
end
end
end
table.sort(loaded, function(a, b) return a.loadedAt < b.loadedAt end)
for _, slot in ipairs(slots) do
local st = slot.state
if st == "block" or st == "rising" or st == "converting" then
local b = slot.block
if b and b.Parent then
local a = angle + (slot.index / COUNT) * math.pi * 2
local pos
if st == "block" then
pos = r.Position + V(math.cos(a) * ORBIT_RADIUS, 0.5, math.sin(a) * ORBIT_RADIUS)
else
slot.riseT = math.min(slot.riseT + dt / RISE_TIME, 1)
local t = slot.riseT
pos = slot.riseFrom:Lerp(head, t * t * (3 - 2 * t))
if slot.riseT >= 1 and st == "rising" then
slot.state = "converting"
task.spawn(safe("Convert", convert), slot)
end
end
place(b, CF(pos) * CFrame.Angles(0, angle * SELF_SPIN, 0))
elseif st == "block" then
slot.state = "done"
end
end
end
for k, slot in ipairs(loaded) do
local pos = head
if #loaded > 1 then
local a = angle * 1.2 + (k / #loaded) * math.pi * 2
pos = head + V(math.cos(a) * LOADED_RADIUS, 0, math.sin(a) * LOADED_RADIUS)
end
placeSword(slot.sword, CF(pos) * CFrame.Angles(0, angle * SELF_SPIN, 0))
end
if huge then
placeSword(huge.sword, CF(r.Position + V(0, HUGE_HEIGHT, 0)) * CFrame.Angles(0, angle * 1.5, 0))
end
syncT = syncT + dt
if not free and syncT > SYNC_EVERY and inflight < MAX_INFLIGHT and #mine > 0 then
syncT = 0
inflight = inflight + 1
local list = {}
for _, p in ipairs(mine) do ins(list, { Part = p, CFrame = p.CFrame }) end
task.spawn(function()
call("SyncMove", list)
inflight = math.max(inflight - 1, 0)
end)
end
end
local function combine()
if combining or not active or loadedCount() < COUNT then return end
local r = getRoot()
if not r then return end
combining = true
combineBtn.Visible = false
report("Combining...")
local c = r.Position + V(0, HUGE_HEIGHT, 0)
local items = {}
for _, s in ipairs(slots) do
if s.state == "loaded" and not s.huge then
s.state = "combining"
local rel = s.sword.main.Position - c
ins(items, {
s = s, a0 = math.atan2(rel.Z, rel.X),
r0 = math.max(V(rel.X, 0, rel.Z).Magnitude, 4), y0 = rel.Y,
})
end
end
local T, t0 = 3.5, os.clock()
while active do
local u = math.min((os.clock() - t0) / T, 1)
local rr = getRoot()
if rr then c = rr.Position + V(0, HUGE_HEIGHT, 0) end
for _, it in ipairs(items) do
local th = it.a0 + 8 * (u + 3 * u * u)
local rad = it.r0 + (1 - it.r0) * u * u
if it.s.sword then
placeSword(it.s.sword, CF(c + V(math.cos(th) * rad, it.y0 * (1 - u), math.sin(th) * rad))
* CFrame.Angles(0, th * 2, 0))
end
end
if u >= 1 then break end
RunService.RenderStepped:Wait()
end
if not active then
combining = false
return
end
local rm = {}
for _, it in ipairs(items) do
if it.s.sword then
for _, p in ipairs(it.s.sword.parts) do ins(rm, p) end
end
end
lightning(c, rm)
for _, it in ipairs(items) do it.s.sword, it.s.state = nil, "done" end
if not active then
combining = false
return
end
local defs = swordDefs(WHITE, HUGE_SCALE, CF(c))
local sw = toSword(build(defs, false, true), defs)
if sw then
ins(slots, { index = COUNT + 1, color = WHITE, state = "loaded", huge = true, loadedAt = -1, sword = sw })
loadBtn.Visible = false
showDel(true)
report("Huge white sword! Pick what it deletes, then Fire.")
else
report("Combine failed")
end
combining = false
end
buildBtn.MouseButton1Click:Connect(safe("Build", function()
if building then return end
if active then
stopSet()
report("Stopped and cleared")
return
end
if not refreshEndpoint() or not getRoot() then
report("No F3X tool found.")
return
end
building = true
buildBtn.Text = "Building..."
slots = {}
local defs = {}
for i = 1, COUNT do
slots[i] = { index = i, color = hue(i), state = "empty", riseT = 0 }
defs[i] = { shape = "Ball", cf = getRoot().CFrame, size = BALL, color = hue(i) }
end
local made = build(defs)
if not made[1] then
building = false
buildBtn.Text = "Build Rainbow"
report("F3X did not respond. Hold the F3X tool.")
return
end
for i = 1, COUNT do
slots[i].block = made[i]
slots[i].state = made[i] and "block" or "done"
end
building = false
active = true
buildBtn.Text = "Stop Rainbow"
loadBtn.Visible, fireBtn.Visible = true, true
report("Rainbow built")
conn = RunService.RenderStepped:Connect(safe("Loop", frameUpdate))
end))
loadBtn.MouseButton1Click:Connect(safe("Load", function()
if not active then return end
for _, slot in ipairs(slots) do
if slot.state == "block" and slot.block and slot.block.Parent and not slot.busy then
slot.state = "rising"
slot.riseT = 0
slot.riseFrom = slot.block.Position
return
end
end
report("No balls left. Stop, then Build.")
end))
local function shoot(slot)
slot.state = "flying"
combineBtn.Visible = false
if slot.huge then showDel(false) end
local sw = slot.sword
local main = sw.main
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { player.Character }
params.RespectCanCollide = true
local cam = workspace.CurrentCamera
local origin, look = cam.CFrame.Position, cam.CFrame.LookVector
local hit = workspace:Raycast(origin, look * MAX_RANGE, params)
local target = hit and hit.Position or (origin + look * MAX_RANGE)
local pos = main.Position
local dir = (target - pos).Unit
local total = math.max((target - pos).Magnitude - 5.3 * (slot.huge and HUGE_SCALE or SWORD_SCALE), 0)
local travelled = 0
local tilt = CFrame.Angles(-math.pi / 2, 0, 0)
if slot.huge then task.spawn(trail, pos, pos + dir * total, total / SHOOT_SPEED) end
while travelled < total and main.Parent do
local dt = RunService.RenderStepped:Wait()
local step = math.min(SHOOT_SPEED * dt, total - travelled)
travelled = travelled + step
pos = pos + dir * step
placeSword(sw, CFrame.lookAt(pos, pos + dir) * tilt)
end
slot.sword = nil
slot.state = "done"
if main.Parent then
local mv, an = {}, {}
for _, p in ipairs(sw.parts) do
ins(mv, { Part = p, CFrame = p.CFrame })
ins(an, { Part = p, Anchored = true })
end
call("SyncMove", mv)
call("SyncAnchor", an)
ins(stuck, sw)
if slot.huge and hit then task.spawn(safe("Impact", impact), hit) end
end
end
fireBtn.MouseButton1Click:Connect(safe("Fire", function()
if not active then return end
local best = nil
for _, slot in ipairs(slots) do
if slot.state == "loaded" and slot.sword and slot.sword.main.Parent then
if not best or slot.loadedAt < best.loadedAt then best = slot end
end
end
if best then
task.spawn(safe("Shoot", shoot), best)
else
report("Load a sword first")
end
end))
combineBtn.MouseButton1Click:Connect(safe("Combine", combine))
report("Ready")
end
local ok, err = xpcall(main, function(e)
return tostring(e) .. "\n" .. debug.traceback()
end)
if not ok then
warn("[F3X] STARTUP ERROR: " .. tostring(err))
local g = new("ScreenGui", { ResetOnSpawn = false, DisplayOrder = 100 }, playerGui)
new("TextLabel", {
Size = U(0.9, 0, 0, 220), Position = U(0.05, 0, 0, 8),
BackgroundColor3 = C(120, 20, 20), TextColor3 = Color3.new(1, 1, 1),
TextSize = 14, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
Text = "F3X ERROR (send me this):\n" .. tostring(err),
}, g)
end