local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character, hrp

local settings = {
    range = 8,
    cooldown = 0.6,
    knockback = 60,
    damage = 15
}

local lastPunch = 0

local function getChar()
    character = player.Character
    hrp = character and character:FindFirstChild("HumanoidRootPart")
end
getChar()
player.CharacterAdded:Connect(getChar)

local function ragdoll(targetChar)
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.PlatformStand = true
    for _, joint in pairs(targetChar:GetDescendants()) do
        if joint:IsA("Motor6D") then
            local socket = Instance.new("BallSocketConstraint")
            local a0 = Instance.new("Attachment")
            local a1 = Instance.new("Attachment")
            a0.Parent = joint.Part0
            a1.Parent = joint.Part1
            socket.Attachment0 = a0
            socket.Attachment1 = a1
            socket.LimitsEnabled = true
            socket.TwistLimitsEnabled = true
            socket.Parent = joint.Parent
            joint.Enabled = false
        end
    end
    task.delay(3, function()
        if not targetChar or not targetChar.Parent then return end
        local h = targetChar:FindFirstChildOfClass("Humanoid")
        if h then h.PlatformStand = false end
        for _, v in pairs(targetChar:GetDescendants()) do
            if v:IsA("BallSocketConstraint") then v:Destroy() end
            if v:IsA("Attachment") and v.Name == "Attachment" then v:Destroy() end
            if v:IsA("Motor6D") then v.Enabled = true end
        end
    end)
end

local function getTarget()
    if not hrp then return nil end
    local closest, closestDist = nil, settings.range
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local targetHRP = p.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                local dist = (hrp.Position - targetHRP.Position).Magnitude
                if dist < closestDist then
                    closest = p.Character
                    closestDist = dist
                end
            end
        end
    end
    return closest
end

local function punch()
    local now = tick()
    if now - lastPunch < settings.cooldown then return end
    lastPunch = now
    local target = getTarget()
    if not target then return end
    local targetHRP = target:FindFirstChild("HumanoidRootPart")
    local targetHum = target:FindFirstChildOfClass("Humanoid")
    if not targetHRP or not targetHum or targetHum.Health <= 0 then return end
    local knockDir = (targetHRP.Position - hrp.Position).Unit
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = (knockDir + Vector3.new(0, 0.5, 0)) * settings.knockback
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.P = 1e5
    bv.Parent = targetHRP
    game:GetService("Debris"):AddItem(bv, 0.15)
    targetHum:TakeDamage(settings.damage)
    ragdoll(target)
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F then punch() end
end)

-----------------------------
-- GUI
-----------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PunchGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player.PlayerGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 240, 0, 230)
main.Position = UDim2.new(0, 16, 0, 16)
main.BackgroundColor3 = Color3.fromRGB(17, 19, 24)
main.BorderSizePixel = 0
main.Parent = screenGui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 36)
header.BackgroundColor3 = Color3.fromRGB(26, 29, 38)
header.BorderSizePixel = 0
header.Parent = main
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 12)
headerFix.Position = UDim2.new(0, 0, 1, -12)
headerFix.BackgroundColor3 = Color3.fromRGB(26, 29, 38)
headerFix.BorderSizePixel = 0
headerFix.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "👊 Punch Pro"
titleLabel.TextColor3 = Color3.fromRGB(200, 202, 216)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 24, 0, 24)
minBtn.Position = UDim2.new(1, -32, 0.5, -12)
minBtn.BackgroundColor3 = Color3.fromRGB(40, 43, 56)
minBtn.BorderSizePixel = 0
minBtn.Text = "—"
minBtn.TextColor3 = Color3.fromRGB(160, 163, 180)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 13
minBtn.Parent = header
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

local body = Instance.new("Frame")
body.Size = UDim2.new(1, 0, 0, 194)
body.Position = UDim2.new(0, 0, 0, 36)
body.BackgroundTransparency = 1
body.ClipsDescendants = true
body.Parent = main

-- Slider builder
local sliderDefs = {
    {label = "Range",     key = "range",     min = 2,  max = 30,  default = 8},
    {label = "Cooldown",  key = "cooldown",  min = 0.1,max = 3,   default = 0.6},
    {label = "Knockback", key = "knockback", min = 10, max = 200, default = 60},
    {label = "Damage",    key = "damage",    min = 1,  max = 100, default = 15},
}

for i, def in ipairs(sliderDefs) do
    local yPos = 10 + (i - 1) * 46

    local rowLabel = Instance.new("TextLabel")
    rowLabel.Size = UDim2.new(1, -24, 0, 16)
    rowLabel.Position = UDim2.new(0, 12, 0, yPos)
    rowLabel.BackgroundTransparency = 1
    rowLabel.Font = Enum.Font.Gotham
    rowLabel.TextSize = 11
    rowLabel.TextXAlignment = Enum.TextXAlignment.Left
    rowLabel.TextColor3 = Color3.fromRGB(130, 135, 160)
    rowLabel.Parent = body

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0, 40, 0, 16)
    valLabel.Position = UDim2.new(1, -52, 0, yPos)
    valLabel.BackgroundTransparency = 1
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextSize = 11
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.TextColor3 = Color3.fromRGB(63, 216, 122)
    valLabel.Parent = body

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -24, 0, 8)
    barBg.Position = UDim2.new(0, 12, 0, yPos + 20)
    barBg.BackgroundColor3 = Color3.fromRGB(30, 33, 48)
    barBg.BorderSizePixel = 0
    barBg.Parent = body
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local barFill = Instance.new("Frame")
    barFill.BackgroundColor3 = Color3.fromRGB(63, 216, 122)
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

    local function updateSlider(val)
        val = math.clamp(val, def.min, def.max)
        settings[def.key] = val
        local pct = (val - def.min) / (def.max - def.min)
        barFill.Size = UDim2.new(pct, 0, 1, 0)
        local display = def.key == "cooldown" and string.format("%.1f", val) or math.floor(val)
        rowLabel.Text = def.label
        valLabel.Text = tostring(display)
    end

    updateSlider(def.default)

    -- Drag logic
    local draggingSlider = false
    barBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = true
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
            local relX = math.clamp(input.Position.X - barBg.AbsolutePosition.X, 0, barBg.AbsoluteSize.X)
            local pct = relX / barBg.AbsoluteSize.X
            local val = def.min + (def.max - def.min) * pct
            updateSlider(val)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = false
        end
    end)
end

-- Key hint
local keyHint = Instance.new("TextLabel")
keyHint.Size = UDim2.new(1, -24, 0, 14)
keyHint.Position = UDim2.new(0, 12, 0, 174)
keyHint.BackgroundTransparency = 1
keyHint.Text = "Press [F] to punch"
keyHint.TextColor3 = Color3.fromRGB(80, 85, 110)
keyHint.Font = Enum.Font.Gotham
keyHint.TextSize = 11
keyHint.TextXAlignment = Enum.TextXAlignment.Left
keyHint.Parent = body

-- Minimize
local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
    if minimized then
        TweenService:Create(main, info, {Size = UDim2.new(0, 240, 0, 36)}):Play()
        TweenService:Create(body, info, {Size = UDim2.new(1, 0, 0, 0)}):Play()
        minBtn.Text = "+"
    else
        TweenService:Create(main, info, {Size = UDim2.new(0, 240, 0, 230)}):Play()
        TweenService:Create(body, info, {Size = UDim2.new(1, 0, 0, 194)}):Play()
        minBtn.Text = "—"
    end
end)

-- Dragging
local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true dragStart = input.Position startPos = main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local d = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

print("Punch Pro loaded! Press F to punch.")
