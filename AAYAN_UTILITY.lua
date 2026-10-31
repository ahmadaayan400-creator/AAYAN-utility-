--=================================================
-- AAYAN UTILITY  (premium purple multi-tool, local script)
-- Fly, speed/jump sliders, fullbright, time, FOV, freecam, emote wheel,
-- teleport spots (saved), FPS/ping overlay, screenshot mode, 3 themes.
-- Everything only affects YOUR client / YOUR character.
-- Toggle the panel with the round A button or RightShift.
-- Not run inside Roblox while writing it: test it and report what looks wrong.
--==================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

if _G.AAYAN_UTIL_STOP then pcall(_G.AAYAN_UTIL_STOP) end
do
	local o = PlayerGui:FindFirstChild("AAYAN_UTILITY")
	if o then o:Destroy() end
end

local conns = {}
local function bind(sig, fn)
	local c = sig:Connect(fn)
	conns[#conns + 1] = c
	return c
end

local function getChar() return Player.Character end
local function getHum()
	local c = Player.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
	local c = Player.Character
	return c and (c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart)
end
local function getCam() return workspace.CurrentCamera end

--==================================================
-- THEMES
--==================================================
local THEMES = {
	Purple = { bg = Color3.fromRGB(14, 9, 26), panel = Color3.fromRGB(24, 15, 44), btn = Color3.fromRGB(38, 24, 70),
		accent = Color3.fromRGB(150, 80, 255), accent2 = Color3.fromRGB(210, 150, 255), text = Color3.fromRGB(240, 232, 255), muted = Color3.fromRGB(150, 130, 190) },
	Pink = { bg = Color3.fromRGB(28, 9, 22), panel = Color3.fromRGB(46, 15, 36), btn = Color3.fromRGB(78, 26, 60),
		accent = Color3.fromRGB(255, 80, 180), accent2 = Color3.fromRGB(255, 170, 220), text = Color3.fromRGB(255, 235, 246), muted = Color3.fromRGB(200, 130, 175) },
	Blue = { bg = Color3.fromRGB(8, 14, 28), panel = Color3.fromRGB(13, 24, 46), btn = Color3.fromRGB(22, 40, 78),
		accent = Color3.fromRGB(60, 150, 255), accent2 = Color3.fromRGB(150, 210, 255), text = Color3.fromRGB(232, 242, 255), muted = Color3.fromRGB(120, 150, 195) },
}
local themeName = "Purple"
local T = THEMES[themeName]
local reg = {}
local function themed(obj, prop, key)
	reg[#reg + 1] = { o = obj, p = prop, k = key }
	obj[prop] = T[key]
end
local function applyTheme(name)
	themeName = name
	T = THEMES[name]
	for i = #reg, 1, -1 do
		local r = reg[i]
		if r.o.Parent then
			TweenService:Create(r.o, TweenInfo.new(0.25), { [r.p] = T[r.k] }):Play()
		else
			table.remove(reg, i)
		end
	end
end

--==================================================
-- SAVED DATA (teleport spots, theme) - needs writefile; safe without it
--==================================================
local FILE = "AAYAN_UTILITY_" .. tostring(game.PlaceId) .. ".json"
local saved = { spots = {}, theme = "Purple" }
pcall(function()
	if isfile and isfile(FILE) then
		local d = HttpService:JSONDecode(readfile(FILE))
		if type(d) == "table" then
			saved.spots = d.spots or {}
			saved.theme = d.theme or "Purple"
		end
	end
end)
local function save()
	pcall(function()
		if writefile then writefile(FILE, HttpService:JSONEncode(saved)) end
	end)
end
if THEMES[saved.theme] then themeName = saved.theme T = THEMES[themeName] end

--==================================================
-- UI HELPERS
--==================================================
local SG = Instance.new("ScreenGui")
SG.Name = "AAYAN_UTILITY"
SG.ResetOnSpawn = false
SG.IgnoreGuiInset = true
SG.DisplayOrder = 500
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent = PlayerGui

local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = p
	return c
end
local function strokeOf(p, th)
	local s = Instance.new("UIStroke")
	s.Thickness = th or 1.4
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = p
	return s
end
local function label(parent, text, size, key, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size
	l.Font = font or Enum.Font.GothamBold
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	themed(l, "TextColor3", key or "text")
	return l
end

-- light sweep across every registered button, every 2 seconds
local SHIMMERS = {}
local function addShimmer(btn)
	btn.ClipsDescendants = true
	local s = Instance.new("Frame")
	s.Name = "Shimmer"
	s.BackgroundColor3 = Color3.new(1, 1, 1)
	s.BackgroundTransparency = 0.8
	s.BorderSizePixel = 0
	s.Size = UDim2.new(0.22, 0, 2.2, 0)
	s.AnchorPoint = Vector2.new(0.5, 0.5)
	s.Position = UDim2.new(-0.3, 0, 0.5, 0)
	s.Rotation = 20
	s.ZIndex = btn.ZIndex + 2
	s.Parent = btn
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) })
	g.Parent = s
	SHIMMERS[#SHIMMERS + 1] = s
end
task.spawn(function()
	while SG.Parent do
		for i = #SHIMMERS, 1, -1 do
			local s = SHIMMERS[i]
			if s.Parent then
				if s.Parent.AbsoluteSize.X > 0 and s.Parent.Visible then
					s.Position = UDim2.new(-0.3, 0, 0.5, 0)
					TweenService:Create(s, TweenInfo.new(0.75, Enum.EasingStyle.Sine), { Position = UDim2.new(1.3, 0, 0.5, 0) }):Play()
				end
			else
				table.remove(SHIMMERS, i)
			end
		end
		task.wait(2)
	end
end)

local toastLbl = Instance.new("TextLabel")
toastLbl.AnchorPoint = Vector2.new(0.5, 1)
toastLbl.Position = UDim2.new(0.5, 0, 1, 40)
toastLbl.Size = UDim2.fromOffset(280, 34)
toastLbl.Font = Enum.Font.GothamBold
toastLbl.TextSize = 13
toastLbl.ZIndex = 800
toastLbl.Visible = false
toastLbl.Parent = SG
themed(toastLbl, "BackgroundColor3", "panel")
themed(toastLbl, "TextColor3", "text")
corner(toastLbl, 10)
local toastStroke = strokeOf(toastLbl, 1.5)
themed(toastStroke, "Color", "accent")
local toastId = 0
local function toast(text)
	toastId = toastId + 1
	local id = toastId
	toastLbl.Text = text
	toastLbl.Visible = true
	toastLbl.Position = UDim2.new(0.5, 0, 1, 40)
	TweenService:Create(toastLbl, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Position = UDim2.new(0.5, 0, 1, -24) }):Play()
	task.delay(1.8, function()
		if id ~= toastId then return end
		TweenService:Create(toastLbl, TweenInfo.new(0.2), { Position = UDim2.new(0.5, 0, 1, 40) }):Play()
		task.wait(0.22)
		if id == toastId then toastLbl.Visible = false end
	end)
end

--==================================================
-- MAIN PANEL
--==================================================
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(350, 440)
main.Position = UDim2.new(0, 16, 0.5, -220)
main.BorderSizePixel = 0
main.Active = true
main.ClipsDescendants = true
main.ZIndex = 10
main.Parent = SG
themed(main, "BackgroundColor3", "bg")
corner(main, 16)
local mainStroke = strokeOf(main, 1.8)
themed(mainStroke, "Color", "accent")
local mainScale = Instance.new("UIScale")
mainScale.Parent = main
local function fitScale()
	local cam = getCam()
	local v = cam and cam.ViewportSize or Vector2.new(1280, 720)
	mainScale.Scale = math.clamp(math.min(v.X / 520, v.Y / 520), 0.6, 1.1)
end
fitScale()

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 58)
header.BackgroundTransparency = 1
header.ZIndex = 11
header.Parent = main
local grad = Instance.new("UIGradient")
grad.Rotation = 0
grad.Parent = mainStroke

local title = label(header, "AAYAN  UTILITY", 19, "text", Enum.Font.GothamBlack)
title.Position = UDim2.fromOffset(16, 8)
title.Size = UDim2.new(1, -90, 0, 26)
title.ZIndex = 12
local titleGrad = Instance.new("UIGradient")
titleGrad.Parent = title
local sub = label(header, "premium multi-tool", 11, "muted", Enum.Font.Gotham)
sub.Position = UDim2.fromOffset(16, 34)
sub.Size = UDim2.new(1, -90, 0, 16)
sub.ZIndex = 12

local function setGrads()
	local cs = ColorSequence.new(T.accent, T.accent2)
	grad.Color = cs
	titleGrad.Color = ColorSequence.new(Color3.new(1, 1, 1), T.accent2)
end
setGrads()

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(32, 32)
closeBtn.Position = UDim2.new(1, -44, 0, 12)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 13
closeBtn.Parent = header
themed(closeBtn, "BackgroundColor3", "btn")
themed(closeBtn, "TextColor3", "text")
corner(closeBtn, 9)

-- tabs
local tabBar = Instance.new("Frame")
tabBar.Position = UDim2.fromOffset(10, 62)
tabBar.Size = UDim2.new(1, -20, 0, 32)
tabBar.BackgroundTransparency = 1
tabBar.ZIndex = 11
tabBar.Parent = main
local tl = Instance.new("UIListLayout")
tl.FillDirection = Enum.FillDirection.Horizontal
tl.Padding = UDim.new(0, 4)
tl.Parent = tabBar

local pages, tabBtns = {}, {}
local function showPage(name)
	for n, p in pairs(pages) do p.Visible = (n == name) end
	for n, b in pairs(tabBtns) do
		TweenService:Create(b, TweenInfo.new(0.2), { BackgroundColor3 = (n == name) and T.accent or T.btn }):Play()
	end
	main:SetAttribute("page", name)
end
local TABS = { "MOVE", "VISUAL", "CAMERA", "EMOTES", "TOOLS" }
for _, n in ipairs(TABS) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1 / #TABS, -4, 1, 0)
	b.Text = n
	b.Font = Enum.Font.GothamBold
	b.TextSize = 10
	b.AutoButtonColor = false
	b.ZIndex = 12
	b.Parent = tabBar
	themed(b, "BackgroundColor3", "btn")
	themed(b, "TextColor3", "text")
	corner(b, 8)
	addShimmer(b)
	tabBtns[n] = b
	local pg = Instance.new("ScrollingFrame")
	pg.Position = UDim2.fromOffset(10, 102)
	pg.Size = UDim2.new(1, -20, 1, -112)
	pg.BackgroundTransparency = 1
	pg.BorderSizePixel = 0
	pg.ScrollBarThickness = 3
	pg.AutomaticCanvasSize = Enum.AutomaticSize.Y
	pg.CanvasSize = UDim2.new()
	pg.Visible = false
	pg.ZIndex = 11
	pg.Parent = main
	themed(pg, "ScrollBarImageColor3", "accent")
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, 7)
	l.Parent = pg
	pages[n] = pg
	b.Activated:Connect(function() showPage(n) end)
end

local function btn(page, text, cb)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -6, 0, 38)
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.AutoButtonColor = false
	b.ZIndex = 12
	b.Parent = pages[page]
	themed(b, "BackgroundColor3", "btn")
	themed(b, "TextColor3", "text")
	corner(b, 10)
	local s = strokeOf(b, 1)
	themed(s, "Color", "accent")
	s.Transparency = 0.6
	addShimmer(b)
	bind(b.MouseEnter, function() TweenService:Create(s, TweenInfo.new(0.15), { Transparency = 0 }):Play() end)
	bind(b.MouseLeave, function() TweenService:Create(s, TweenInfo.new(0.15), { Transparency = 0.6 }):Play() end)
	b.Activated:Connect(cb)
	return b
end
local function toggleBtn(page, text, cb)
	local on = false
	local b
	b = btn(page, text .. "  :  OFF", function()
		on = not on
		b.Text = text .. (on and "  :  ON" or "  :  OFF")
		TweenService:Create(b, TweenInfo.new(0.2), { TextColor3 = on and T.accent2 or T.text }):Play()
		cb(on)
	end)
	return b, function(v)
		on = v
		b.Text = text .. (on and "  :  ON" or "  :  OFF")
	end
end
local function sliderRow(page, text, mn, mx, def, cb, int)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, -6, 0, 52)
	f.ZIndex = 12
	f.Parent = pages[page]
	themed(f, "BackgroundColor3", "panel")
	corner(f, 10)
	local l = label(f, text, 12, "text")
	l.Position = UDim2.fromOffset(12, 6)
	l.Size = UDim2.new(1, -90, 0, 16)
	l.ZIndex = 13
	local v = label(f, tostring(def), 12, "accent2")
	v.Position = UDim2.new(1, -78, 0, 6)
	v.Size = UDim2.fromOffset(66, 16)
	v.TextXAlignment = Enum.TextXAlignment.Right
	v.ZIndex = 13
	local track = Instance.new("Frame")
	track.Position = UDim2.fromOffset(12, 32)
	track.Size = UDim2.new(1, -24, 0, 8)
	track.ZIndex = 13
	track.Parent = f
	themed(track, "BackgroundColor3", "btn")
	corner(track, 4)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale((def - mn) / (mx - mn), 1)
	fill.BorderSizePixel = 0
	fill.ZIndex = 14
	fill.Parent = track
	themed(fill, "BackgroundColor3", "accent")
	corner(fill, 4)
	local knob = Instance.new("Frame")
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Size = UDim2.fromOffset(16, 16)
	knob.Position = UDim2.new(1, 0, 0.5, 0)
	knob.ZIndex = 15
	knob.Parent = fill
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	corner(knob, 8)
	local dragging = false
	local function setFrom(x)
		local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		local val = mn + (mx - mn) * a
		if int ~= false then val = math.floor(val + 0.5) end
		fill.Size = UDim2.fromScale(a, 1)
		v.Text = tostring(val)
		cb(val)
	end
	track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFrom(i.Position.X)
		end
	end)
	bind(UIS.InputChanged, function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			setFrom(i.Position.X)
		end
	end)
	bind(UIS.InputEnded, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	return f
end

--==================================================
-- MOVE: fly, walk speed, jump power
--==================================================
local Fly = { on = false, speed = 70, up = false, down = false }
local flyBV, flyBG
local function stopFly()
	Fly.on = false
	if flyBV then flyBV:Destroy() flyBV = nil end
	if flyBG then flyBG:Destroy() flyBG = nil end
	local h = getHum()
	if h then h.PlatformStand = false end
end
local function startFly()
	local r, h = getRoot(), getHum()
	if not r or not h then return false end
	Fly.on = true
	flyBV = Instance.new("BodyVelocity")
	flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	flyBV.Velocity = Vector3.zero
	flyBV.Parent = r
	flyBG = Instance.new("BodyGyro")
	flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	flyBG.P = 9000
	flyBG.CFrame = r.CFrame
	flyBG.Parent = r
	h.PlatformStand = true
	return true
end
local flyBtn, flySet = toggleBtn("MOVE", "FLY", function(on)
	if on then
		if not startFly() then toast("Character not ready") end
	else
		stopFly()
	end
end)
sliderRow("MOVE", "Fly speed", 20, 300, 70, function(v) Fly.speed = v end)

local udRow = Instance.new("Frame")
udRow.Size = UDim2.new(1, -6, 0, 38)
udRow.BackgroundTransparency = 1
udRow.ZIndex = 12
udRow.Parent = pages.MOVE
local udl = Instance.new("UIListLayout")
udl.FillDirection = Enum.FillDirection.Horizontal
udl.Padding = UDim.new(0, 7)
udl.Parent = udRow
local function holdBtn(text, flag)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.5, -4, 1, 0)
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.AutoButtonColor = false
	b.ZIndex = 12
	b.Parent = udRow
	themed(b, "BackgroundColor3", "btn")
	themed(b, "TextColor3", "text")
	corner(b, 10)
	b.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then Fly[flag] = true end
	end)
	b.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then Fly[flag] = false end
	end)
end
holdBtn("HOLD: UP", "up")
holdBtn("HOLD: DOWN", "down")

local wantWalk, wantJump = nil, nil
sliderRow("MOVE", "Walk speed", 16, 200, 16, function(v) wantWalk = v local h = getHum() if h then h.WalkSpeed = v end end)
sliderRow("MOVE", "Jump power", 50, 300, 50, function(v)
	wantJump = v
	local h = getHum()
	if h then h.UseJumpPower = true h.JumpPower = v end
end)
btn("MOVE", "RESET SPEED AND JUMP", function()
	wantWalk, wantJump = nil, nil
	local h = getHum()
	if h then h.WalkSpeed = 16 h.UseJumpPower = true h.JumpPower = 50 end
	toast("Reset to default")
end)

bind(RunService.Heartbeat, function()
	if Fly.on then
		local r, h, cam = getRoot(), getHum(), getCam()
		if r and h and cam and flyBV then
			local md = h.MoveDirection
			local lv = cam.CFrame:VectorToObjectSpace(md)
			local dir = cam.CFrame.LookVector * -lv.Z + cam.CFrame.RightVector * lv.X
			if Fly.up then dir = dir + Vector3.new(0, 1, 0) end
			if Fly.down then dir = dir - Vector3.new(0, 1, 0) end
			flyBV.Velocity = dir.Magnitude > 0.05 and dir.Unit * Fly.speed or Vector3.zero
			flyBG.CFrame = CFrame.new(r.Position, r.Position + Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z))
		end
	end
	local h = getHum()
	if h then
		if wantWalk and h.WalkSpeed ~= wantWalk then h.WalkSpeed = wantWalk end
		if wantJump and h.JumpPower ~= wantJump then h.UseJumpPower = true h.JumpPower = wantJump end
	end
end)
bind(Player.CharacterAdded, function()
	if Fly.on then
		Fly.on = false
		flyBV, flyBG = nil, nil
		flySet(false)
		flyBtn.TextColor3 = T.text
	end
end)

--==================================================
-- VISUAL: fullbright, time, FOV, themes
--==================================================
local lightBackup = nil
local function fullbrightOn()
	lightBackup = {
		Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd,
		GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
	}
	Lighting.Brightness = 2
	Lighting.ClockTime = 14
	Lighting.FogEnd = 1e6
	Lighting.GlobalShadows = false
	Lighting.Ambient = Color3.fromRGB(190, 190, 190)
	Lighting.OutdoorAmbient = Color3.fromRGB(190, 190, 190)
end
local function fullbrightOff()
	if lightBackup then
		for k, v in pairs(lightBackup) do pcall(function() Lighting[k] = v end) end
		lightBackup = nil
	end
end
toggleBtn("VISUAL", "FULLBRIGHT", function(on) if on then fullbrightOn() else fullbrightOff() end end)
sliderRow("VISUAL", "Time of day", 0, 24, math.floor(Lighting.ClockTime), function(v) Lighting.ClockTime = v end)
sliderRow("VISUAL", "Field of view", 40, 120, 70, function(v)
	local cam = getCam()
	if cam then cam.FieldOfView = v end
end)
local themeRow = Instance.new("Frame")
themeRow.Size = UDim2.new(1, -6, 0, 38)
themeRow.BackgroundTransparency = 1
themeRow.ZIndex = 12
themeRow.Parent = pages.VISUAL
local thl = Instance.new("UIListLayout")
thl.FillDirection = Enum.FillDirection.Horizontal
thl.Padding = UDim.new(0, 6)
thl.Parent = themeRow
for _, n in ipairs({ "Purple", "Pink", "Blue" }) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1 / 3, -4, 1, 0)
	b.Text = string.upper(n)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.AutoButtonColor = false
	b.ZIndex = 12
	b.Parent = themeRow
	b.BackgroundColor3 = THEMES[n].accent
	b.TextColor3 = Color3.new(1, 1, 1)
	corner(b, 10)
	addShimmer(b)
	b.Activated:Connect(function()
		applyTheme(n)
		setGrads()
		saved.theme = n
		save()
		showPage(main:GetAttribute("page") or "VISUAL")
		toast("Theme: " .. n)
	end)
end

--==================================================
-- CAMERA: freecam
--==================================================
local Free = { on = false, yaw = 0, pitch = 0, speed = 60, up = false, down = false, pos = Vector3.zero }
local function stopFree()
	Free.on = false
	local cam, h, r = getCam(), getHum(), getRoot()
	if cam then
		cam.CameraType = Enum.CameraType.Custom
		if h then cam.CameraSubject = h end
	end
	if r then r.Anchored = false end
end
local freeBtn, freeSet = toggleBtn("CAMERA", "FREECAM", function(on)
	local cam, r = getCam(), getRoot()
	if on and cam and r then
		local look = cam.CFrame.LookVector
		Free.yaw = math.atan2(-look.X, -look.Z)
		Free.pitch = math.asin(look.Y)
		Free.pos = cam.CFrame.Position
		Free.on = true
		cam.CameraType = Enum.CameraType.Scriptable
		r.Anchored = true
		toast("Freecam: move with stick, drag screen to look")
	else
		stopFree()
	end
end)
sliderRow("CAMERA", "Freecam speed", 10, 250, 60, function(v) Free.speed = v end)
local fr = Instance.new("Frame")
fr.Size = UDim2.new(1, -6, 0, 38)
fr.BackgroundTransparency = 1
fr.ZIndex = 12
fr.Parent = pages.CAMERA
local fl = Instance.new("UIListLayout")
fl.FillDirection = Enum.FillDirection.Horizontal
fl.Padding = UDim.new(0, 7)
fl.Parent = fr
for _, d in ipairs({ { "HOLD: UP", "up" }, { "HOLD: DOWN", "down" } }) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.5, -4, 1, 0)
	b.Text = d[1]
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.AutoButtonColor = false
	b.ZIndex = 12
	b.Parent = fr
	themed(b, "BackgroundColor3", "btn")
	themed(b, "TextColor3", "text")
	corner(b, 10)
	b.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then Free[d[2]] = true end
	end)
	b.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then Free[d[2]] = false end
	end)
end
local lastTouch = nil
bind(UIS.InputChanged, function(i, gp)
	if not Free.on or gp then return end
	if i.UserInputType == Enum.UserInputType.MouseMovement and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		Free.yaw = Free.yaw - i.Delta.X * 0.004
		Free.pitch = math.clamp(Free.pitch - i.Delta.Y * 0.004, -1.5, 1.5)
	elseif i.UserInputType == Enum.UserInputType.Touch then
		Free.yaw = Free.yaw - i.Delta.X * 0.006
		Free.pitch = math.clamp(Free.pitch - i.Delta.Y * 0.006, -1.5, 1.5)
	end
end)
bind(RunService.RenderStepped, function(dt)
	if not Free.on then return end
	local cam, h = getCam(), getHum()
	if not cam then return end
	local rot = CFrame.Angles(0, Free.yaw, 0) * CFrame.Angles(Free.pitch, 0, 0)
	local md = h and h.MoveDirection or Vector3.zero
	local lv = Vector3.zero
	if md.Magnitude > 0.05 then
		local c0 = CFrame.new(Vector3.zero, Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z))
		lv = c0:VectorToObjectSpace(md)
	end
	local move = rot.LookVector * -lv.Z + rot.RightVector * lv.X
	if Free.up then move = move + Vector3.new(0, 1, 0) end
	if Free.down then move = move - Vector3.new(0, 1, 0) end
	Free.pos = Free.pos + move * Free.speed * dt
	cam.CFrame = CFrame.new(Free.pos) * rot
end)

--==================================================
-- EMOTES: wheel
--==================================================
local EMOTES = {
	{ "WAVE", 507770239 }, { "POINT", 507770453 }, { "CHEER", 507770677 }, { "LAUGH", 507770818 },
	{ "DANCE 1", 507771019 }, { "DANCE 2", 507776043 }, { "DANCE 3", 507777268 }, { "STOP", 0 },
}
local track
local function stopEmote()
	if track then pcall(function() track:Stop() end) track = nil end
end
local function playEmote(id)
	stopEmote()
	if id == 0 then return end
	local h = getHum()
	if not h then return end
	if h.RigType ~= Enum.HumanoidRigType.R15 then toast("These emotes need an R15 avatar") return end
	local an = Instance.new("Animation")
	an.AnimationId = "rbxassetid://" .. id
	local ok = pcall(function()
		local animator = h:FindFirstChildOfClass("Animator") or h
		track = animator:LoadAnimation(an)
		track.Priority = Enum.AnimationPriority.Action
		track.Looped = true
		track:Play()
	end)
	if not ok then toast("Emote could not load here") end
end
do
	local wheel = Instance.new("Frame")
	wheel.Size = UDim2.new(1, -6, 0, 290)
	wheel.BackgroundTransparency = 1
	wheel.ZIndex = 12
	wheel.Parent = pages.EMOTES
	local center = Instance.new("TextLabel")
	center.AnchorPoint = Vector2.new(0.5, 0.5)
	center.Position = UDim2.fromScale(0.5, 0.5)
	center.Size = UDim2.fromOffset(86, 86)
	center.Text = "EMOTE\nWHEEL"
	center.Font = Enum.Font.GothamBlack
	center.TextSize = 12
	center.ZIndex = 13
	center.Parent = wheel
	themed(center, "BackgroundColor3", "panel")
	themed(center, "TextColor3", "accent2")
	corner(center, 43)
	local cs = strokeOf(center, 2)
	themed(cs, "Color", "accent")
	for i, e in ipairs(EMOTES) do
		local a = (i - 1) / #EMOTES * math.pi * 2 - math.pi / 2
		local b = Instance.new("TextButton")
		b.AnchorPoint = Vector2.new(0.5, 0.5)
		b.Size = UDim2.fromOffset(78, 40)
		b.Position = UDim2.new(0.5, math.cos(a) * 108, 0.5, math.sin(a) * 110)
		b.Text = e[1]
		b.Font = Enum.Font.GothamBold
		b.TextSize = 11
		b.AutoButtonColor = false
		b.ZIndex = 13
		b.Parent = wheel
		themed(b, "BackgroundColor3", "btn")
		themed(b, "TextColor3", "text")
		corner(b, 12)
		local s = strokeOf(b, 1.2)
		themed(s, "Color", "accent")
		addShimmer(b)
		b.Activated:Connect(function() playEmote(e[2]) end)
	end
end
bind(RunService.Heartbeat, function()
	if track then
		local h = getHum()
		if h and h.MoveDirection.Magnitude > 0.1 and not Fly.on then stopEmote() end
	end
end)

--==================================================
-- TOOLS: teleport spots, FPS/ping overlay, screenshot mode
--==================================================
local spotHolder = Instance.new("Frame")
spotHolder.Size = UDim2.new(1, -6, 0, 0)
spotHolder.AutomaticSize = Enum.AutomaticSize.Y
spotHolder.BackgroundTransparency = 1
spotHolder.ZIndex = 12
spotHolder.LayoutOrder = 50
local sl = Instance.new("UIListLayout")
sl.Padding = UDim.new(0, 6)
sl.Parent = spotHolder

local function rebuildSpots()
	for _, c in ipairs(spotHolder:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	for i, s in ipairs(saved.spots) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 36)
		row.ZIndex = 12
		row.Parent = spotHolder
		themed(row, "BackgroundColor3", "panel")
		corner(row, 10)
		local go = Instance.new("TextButton")
		go.Size = UDim2.new(1, -46, 1, 0)
		go.Text = "  " .. s.name
		go.TextXAlignment = Enum.TextXAlignment.Left
		go.Font = Enum.Font.GothamBold
		go.TextSize = 12
		go.BackgroundTransparency = 1
		go.ZIndex = 13
		go.Parent = row
		themed(go, "TextColor3", "text")
		go.Activated:Connect(function()
			local c = getChar()
			if c then c:PivotTo(CFrame.new(s.x, s.y + 3, s.z)) toast("Teleported: " .. s.name) end
		end)
		local del = Instance.new("TextButton")
		del.Position = UDim2.new(1, -40, 0, 4)
		del.Size = UDim2.fromOffset(32, 28)
		del.Text = "DEL"
		del.Font = Enum.Font.GothamBold
		del.TextSize = 10
		del.ZIndex = 13
		del.Parent = row
		del.BackgroundColor3 = Color3.fromRGB(150, 40, 70)
		del.TextColor3 = Color3.new(1, 1, 1)
		corner(del, 8)
		del.Activated:Connect(function()
			table.remove(saved.spots, i)
			save()
			rebuildSpots()
		end)
	end
end
btn("TOOLS", "SAVE THIS SPOT", function()
	local r = getRoot()
	if not r then return end
	local p = r.Position
	saved.spots[#saved.spots + 1] = { name = "Spot " .. (#saved.spots + 1), x = p.X, y = p.Y, z = p.Z }
	save()
	rebuildSpots()
	toast("Spot saved")
end)
spotHolder.Parent = pages.TOOLS

local hud = Instance.new("TextLabel")
hud.Position = UDim2.new(0, 8, 0, 8)
hud.Size = UDim2.fromOffset(150, 24)
hud.Font = Enum.Font.GothamBold
hud.TextSize = 12
hud.Visible = false
hud.ZIndex = 600
hud.Parent = SG
themed(hud, "BackgroundColor3", "bg")
themed(hud, "TextColor3", "accent2")
corner(hud, 8)
local hs = strokeOf(hud, 1.2)
themed(hs, "Color", "accent")
local fpsAcc, fpsN = 0, 0
local hudOn = false
bind(RunService.RenderStepped, function(dt)
	if not hudOn then return end
	fpsAcc = fpsAcc + dt
	fpsN = fpsN + 1
	if fpsAcc >= 0.5 then
		local ping = 0
		pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
		hud.Text = string.format("FPS %d   PING %d ms", math.floor(fpsN / fpsAcc + 0.5), ping)
		fpsAcc, fpsN = 0, 0
	end
end)
toggleBtn("TOOLS", "FPS AND PING", function(on) hudOn = on hud.Visible = on end)

local dot = Instance.new("TextButton")
dot.AnchorPoint = Vector2.new(1, 1)
dot.Position = UDim2.new(1, -8, 1, -8)
dot.Size = UDim2.fromOffset(18, 18)
dot.Text = ""
dot.Visible = false
dot.ZIndex = 900
dot.BackgroundTransparency = 0.5
dot.Parent = SG
themed(dot, "BackgroundColor3", "accent")
corner(dot, 9)

--==================================================
-- OPEN / CLOSE, TOGGLE BUTTON, DRAG
--==================================================
local opened = true
local function setOpen(v)
	opened = v
	main.Visible = true
	TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
		Position = v and UDim2.new(0, 16, 0.5, -220) or UDim2.new(0, -420, 0.5, -220) }):Play()
end
btn("TOOLS", "SCREENSHOT MODE (hide all)", function()
	main.Visible = false
	SG.Toggle.Visible = false
	dot.Visible = true
	hud.Visible = false
end)
dot.Activated:Connect(function()
	main.Visible = true
	SG.Toggle.Visible = true
	dot.Visible = false
	hud.Visible = hudOn
end)

local tog = Instance.new("TextButton")
tog.Name = "Toggle"
tog.Size = UDim2.fromOffset(52, 52)
tog.AnchorPoint = Vector2.new(0.5, 0.5)
tog.Position = UDim2.new(0.5, 0, 0.2, 0)
tog.Text = "A"
tog.Font = Enum.Font.GothamBlack
tog.TextSize = 24
tog.AutoButtonColor = false
tog.ZIndex = 700
tog.Parent = SG
themed(tog, "BackgroundColor3", "bg")
themed(tog, "TextColor3", "accent2")
corner(tog, 26)
local tgs = strokeOf(tog, 2.2)
themed(tgs, "Color", "accent")
addShimmer(tog)

-- drag (works for mouse and touch); a tap without movement toggles
local function makeDraggable(handle, target, onTap)
	local dragging, start, startPos, moved = false, nil, nil, false
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, moved = true, false
			start = i.Position
			startPos = target.Position
		end
	end)
	bind(UIS.InputChanged, function(i)
		if not dragging then return end
		if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
			local d = i.Position - start
			if d.Magnitude > 6 then moved = true end
			if moved then
				target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end
	end)
	bind(UIS.InputEnded, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			if dragging and not moved and onTap then onTap() end
			dragging = false
		end
	end)
end
makeDraggable(header, main)
makeDraggable(tog, tog, function() setOpen(not opened) end)
closeBtn.Activated:Connect(function() setOpen(false) end)
bind(UIS.InputBegan, function(i, gp)
	if gp then return end
	if i.KeyCode == Enum.KeyCode.RightShift then setOpen(not opened) end
end)

--==================================================
-- STOP / CLEANUP (re-running the script removes the old one)
--==================================================
_G.AAYAN_UTIL_STOP = function()
	stopFly()
	stopFree()
	stopEmote()
	fullbrightOff()
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	local h = getHum()
	if h then h.WalkSpeed = 16 h.JumpPower = 50 end
	pcall(function() SG:Destroy() end)
	_G.AAYAN_UTIL_STOP = nil
end

rebuildSpots()
setGrads()
applyTheme(themeName)
showPage("MOVE")
toast("AAYAN UTILITY ready")
