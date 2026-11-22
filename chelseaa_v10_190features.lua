--// =========================================================================
--// CHELSEAA SYSTEM V10 - 190 GENUINE FEATURES EDITION (NO SPEED FILLER)
--// Theme: Obsidian Cyber-Anime | Mobile, Tablet & Desktop Compatible
--// Brand: MADE BY CHELSEAA
--// Highlights:
--//   * 190 100% Genuine Interactive Features (Zero repetitive speed presets)
--//   * WalkSpeed, Fly Speed, JumpPower & Tween Speed as Dedicated Settings
--//   * Custom UI Wallpaper & Avatar Portrait (https://files.catbox.moe/5kbgpx.jpg)
--//   * Headless Horseman (31K Pose + Flame), Client Headless & Korblox (R6/R15)
--//   * Auto Train Cursor (1x, 2x, 2.30x, 3x, 4x) + Dynamic Tween & Waypoints
--// =========================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

local VirtualUser = nil
pcall(function()
    VirtualUser = game:GetService("VirtualUser")
end)

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait()
    LocalPlayer = Players.LocalPlayer
end

local function GetSafeGuiParent()
    local ok, core = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok and core then
        local test = Instance.new("Folder")
        local canParent = pcall(function()
            test.Parent = core
        end)
        if canParent then
            test:Destroy()
            return core
        end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local GuiParent = GetSafeGuiParent()

-- Clean up previous version if re-executed
for _, oldName in ipairs({ "ChelseaaSystemV9", "ChelseaaSystemV10" }) do
    local old = GuiParent:FindFirstChild(oldName)
    if old then
        old:Destroy()
    end
end

--// =========================================================================
--// STATE & CONFIGURATION (SPEED VALUES ARE SETTINGS, NOT FEATURE ITEMS)
--// =========================================================================
local State = {
    -- Adjustable Speed & Movement Settings
    WalkSpeed = 16,
    WalkSpeedLocked = false,
    JumpPower = 50,
    JumpPowerLocked = false,
    Fly = false,
    FlySpeed = 85,
    TweenSpeed = 250,
    SyncTweenToWalkSpeed = false,
    TweenSpeedMultiplier = 2.0,

    -- Movement & Physics Toggles
    InfiniteJump = false,
    Noclip = false,
    SpinSpeed = 0,
    AntiFling = false,
    BunnyHop = false,
    AirWalk = false,
    SwimAir = false,
    AntiRagdoll = false,
    OrbitPlayer = false,
    OrbitAngle = 0,
    SpiderClimb = false,
    AutoStrafe = false,
    StrafeAngle = 0,
    AutoObstacleJump = false,

    -- Waypoints & Tween Loop
    Waypoints = {},
    ActiveTween = nil,
    TweenLoopActive = false,

    -- Auto Train Cursor (1x, 2x, 2.30x, 3x, 4x) & Automation
    AutoTrainEnabled = false,
    AutoTrainFilter = "2X_PLUS", -- "ALL", "2X_PLUS", "MAX_ONLY", "2X_ONLY"
    AutoTrainMode = "SMART",     -- "SMART", "BAR_ALIGN", "POPUP_CLICK"
    CursorTolerancePx = 10,
    ClickCooldownMs = 70,
    LastClickTick = 0,
    TrainClickCount = 0,
    LastDetectedText = "None",

    AutoClickerCenter = false,
    AutoPrompts = false,
    AutoCollectTouch = false,
    AutoRespawnSpot = false,
    LastDeathCFrame = nil,

    -- Camera & Spectate
    FreeCamEnabled = false,
    FreeCamCFrame = nil,
    SpectateIndex = 0,

    -- Visuals, ESP & Avatar Cosmetics
    PlayerESP = false,
    NameplateESP = false,
    RainbowChar = false,
    XRayActive = false,
    ClientHeadless = false,
    ClientHeadlessHorseman = false,
    ClientKorblox = false,
    CustomMenuImageUrl = "https://files.catbox.moe/5kbgpx.jpg",
    MenuWallpaperVisible = true,

    -- Browser Pagination & Filter
    CurrentPage = 1,
    ItemsPerPage = 38,
    SearchQuery = "",
    NewFeatureFilter = "ALL",
    StatusMessage = "System Ready - 190 Real Features Loaded",
}

local OriginalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    FogColor = Lighting.FogColor,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    GlobalShadows = Lighting.GlobalShadows,
}

local SpawnedObjects = {}
local ActiveConnections = {}

local function TrackConn(conn)
    table.insert(ActiveConnections, conn)
    return conn
end

local function SetStatus(msg)
    State.StatusMessage = msg
end

--// =========================================================================
--// CHARACTER, TWEEN & CURSOR HELPERS
--// =========================================================================
local function GetCharacter()
    return LocalPlayer.Character
end

local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetRootPart()
    local char = GetCharacter()
    return char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
end

local function GetEffectiveTweenSpeed()
    if State.SyncTweenToWalkSpeed then
        return math.max(10, State.WalkSpeed * State.TweenSpeedMultiplier)
    end
    return math.max(10, State.TweenSpeed)
end

local function StopActiveTween()
    State.TweenLoopActive = false
    if State.ActiveTween then
        pcall(function()
            State.ActiveTween:Cancel()
        end)
        State.ActiveTween = nil
    end
end

local function TweenToCFrame(targetCFrame, customSpeed)
    local root = GetRootPart()
    if not root then return nil end

    if State.ActiveTween then
        pcall(function()
            State.ActiveTween:Cancel()
        end)
        State.ActiveTween = nil
    end

    local speed = customSpeed or GetEffectiveTweenSpeed()
    local distance = (targetCFrame.Position - root.Position).Magnitude
    local duration = math.max(0.05, distance / speed)

    local info = TweenInfo.new(
        duration,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )

    local tween = TweenService:Create(root, info, { CFrame = targetCFrame })
    State.ActiveTween = tween
    tween:Play()
    SetStatus(string.format("Tweening %.0f studs @ %d spd (%.2fs)", distance, speed, duration))
    return tween
end

local function FindNearestPlayerRoot()
    local root = GetRootPart()
    if not root then return nil, nil end
    local nearestRoot, nearestPlr, bestDist = nil, nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - root.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    nearestRoot = hrp
                    nearestPlr = plr
                end
            end
        end
    end
    return nearestRoot, nearestPlr
end

local function PerformCursorClickAt(screenX, screenY, guiObj)
    local now = os.clock()
    if (now - State.LastClickTick) * 1000 < State.ClickCooldownMs then
        return false
    end
    State.LastClickTick = now
    State.TrainClickCount = State.TrainClickCount + 1

    local inset = GuiService:GetGuiInset()
    local finalX = math.floor(screenX + inset.X)
    local finalY = math.floor(screenY + inset.Y)

    local clicked = false

    if VirtualInputManager then
        local ok = pcall(function()
            VirtualInputManager:SendMouseMoveEvent(finalX, finalY, game)
            VirtualInputManager:SendMouseButtonEvent(finalX, finalY, 0, true, game, 1)
            task.defer(function()
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(finalX, finalY, 0, false, game, 1)
                end)
            end)
        end)
        if ok then
            clicked = true
        end
    end

    if guiObj and (guiObj:IsA("TextButton") or guiObj:IsA("ImageButton")) then
        pcall(function()
            if type(firesignal) == "function" then
                firesignal(guiObj.MouseButton1Click)
                firesignal(guiObj.Activated)
            end
        end)
    end

    if not clicked and VirtualUser then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(finalX, finalY))
        end)
    end

    return true
end

--// =========================================================================
--// AUTO TRAIN MULTIPLIER DETECTOR (1x, 2x, 2.30x, 3x, 4x)
--// =========================================================================
local MultiplierPatterns = {
    ["4x"]    = { val = 4.0, patterns = { "^4%.?0*x$", "%f[%d]4%.?0*x%f[%A]", "x4%.?0*$" } },
    ["3x"]    = { val = 3.0, patterns = { "^3%.?0*x$", "%f[%d]3%.?0*x%f[%A]", "x3%.?0*$" } },
    ["2.30x"] = { val = 2.3, patterns = { "2%.30*x", "2%.3x", "x2%.30*" } },
    ["2x"]    = { val = 2.0, patterns = { "^2%.?0*x$", "%f[%d]2%.?0*x%f[%A]", "x2%.?0*$" } },
    ["1x"]    = { val = 1.0, patterns = { "^1%.?0*x$", "%f[%d]1%.?0*x%f[%A]", "x1%.?0*$" } },
}

local function MatchMultiplierLabel(rawText)
    if not rawText or rawText == "" then return nil, 0 end
    local clean = string.lower(string.gsub(rawText, "%s+", ""))
    if #clean > 18 then return nil, 0 end

    for _, pat in ipairs(MultiplierPatterns["2.30x"].patterns) do
        if string.find(clean, pat) then
            return "2.30x", 2.3
        end
    end

    for _, tag in ipairs({ "4x", "3x", "2x", "1x" }) do
        for _, pat in ipairs(MultiplierPatterns[tag].patterns) do
            if string.find(clean, pat) then
                return tag, MultiplierPatterns[tag].val
            end
        end
    end

    return nil, 0
end

local function IsMultiplierAllowed(tag, val)
    if State.AutoTrainFilter == "ALL" then
        return true
    elseif State.AutoTrainFilter == "2X_PLUS" then
        return val >= 2.0
    elseif State.AutoTrainFilter == "MAX_ONLY" then
        return val >= 2.3
    elseif State.AutoTrainFilter == "2X_ONLY" then
        return tag == "2x" or tag == "2.30x"
    end
    return true
end

local function IsGuiVisibleOnScreen(obj)
    if not obj or not obj:IsA("GuiObject") then return false end
    if not obj.Visible then return false end
    if obj.AbsoluteSize.X < 4 or obj.AbsoluteSize.Y < 4 then return false end

    local curr = obj.Parent
    while curr do
        if curr:IsA("ScreenGui") then
            return curr.Enabled
        elseif curr:IsA("GuiObject") then
            if not curr.Visible then
                return false
            end
        end
        curr = curr.Parent
    end
    return false
end

local function FindMovingIndicatorInContainer(container, zoneObj)
    if not container then return nil end
    local bestIndicator = nil
    for _, child in ipairs(container:GetDescendants()) do
        if child ~= zoneObj and child:IsA("GuiObject") and child.Visible then
            local nameLower = string.lower(child.Name)
            local isCursorName = string.find(nameLower, "cursor")
                or string.find(nameLower, "needle")
                or string.find(nameLower, "pointer")
                or string.find(nameLower, "arrow")
                or string.find(nameLower, "marker")
                or string.find(nameLower, "slider")
                or string.find(nameLower, "line")
                or string.find(nameLower, "indicator")

            local isThinBar = (child.AbsoluteSize.X >= 1 and child.AbsoluteSize.X <= 18 and child.AbsoluteSize.Y >= 12)
                or (child.AbsoluteSize.Y >= 1 and child.AbsoluteSize.Y <= 18 and child.AbsoluteSize.X >= 12)

            if isCursorName or isThinBar then
                bestIndicator = child
                if isCursorName then
                    break
                end
            end
        end
    end
    return bestIndicator
end

local function ProcessAutoTrainCursor()
    if not State.AutoTrainEnabled then return end
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return end

    local candidates = {}

    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled and gui.Name ~= "ChelseaaSystemV10" then
            for _, desc in ipairs(gui:GetDescendants()) do
                if (desc:IsA("TextLabel") or desc:IsA("TextButton")) and IsGuiVisibleOnScreen(desc) then
                    local tag, val = MatchMultiplierLabel(desc.Text)
                    if tag and IsMultiplierAllowed(tag, val) then
                        table.insert(candidates, {
                            obj = desc,
                            tag = tag,
                            val = val,
                        })
                    end
                end
            end
        end
    end

    if #candidates == 0 then return end

    table.sort(candidates, function(a, b)
        return a.val > b.val
    end)

    for _, item in ipairs(candidates) do
        local obj = item.obj
        local zonePos = obj.AbsolutePosition
        local zoneSize = obj.AbsoluteSize
        local zoneCenterX = zonePos.X + (zoneSize.X * 0.5)
        local zoneCenterY = zonePos.Y + (zoneSize.Y * 0.5)

        local barContainer = obj.Parent and obj.Parent.Parent or obj.Parent
        local indicator = FindMovingIndicatorInContainer(barContainer, obj)

        if indicator and (State.AutoTrainMode == "SMART" or State.AutoTrainMode == "BAR_ALIGN") then
            local indPos = indicator.AbsolutePosition
            local indSize = indicator.AbsoluteSize
            local indCenterX = indPos.X + (indSize.X * 0.5)
            local indCenterY = indPos.Y + (indSize.Y * 0.5)

            local isHorizontal = barContainer and (barContainer.AbsoluteSize.X >= barContainer.AbsoluteSize.Y)
            local dist = isHorizontal and math.abs(indCenterX - zoneCenterX) or math.abs(indCenterY - zoneCenterY)
            local halfZone = isHorizontal and (zoneSize.X * 0.5) or (zoneSize.Y * 0.5)

            if dist <= math.max(State.CursorTolerancePx, halfZone * 0.65) then
                local clickTarget = obj:IsA("TextButton") and obj or (obj.Parent:IsA("GuiButton") and obj.Parent or obj)
                if PerformCursorClickAt(zoneCenterX, zoneCenterY, clickTarget) then
                    State.LastDetectedText = item.tag .. " (Bar Align)"
                    return
                end
            end
        elseif State.AutoTrainMode == "SMART" or State.AutoTrainMode == "POPUP_CLICK" then
            local clickTarget = obj:IsA("TextButton") and obj or (obj.Parent:IsA("GuiButton") and obj.Parent or obj)
            if PerformCursorClickAt(zoneCenterX, zoneCenterY, clickTarget) then
                State.LastDetectedText = item.tag .. " (Cursor Hit)"
                return
            end
        end
    end
end

--// =========================================================================
--// VISUAL / ESP / AVATAR COSMETICS HELPERS
--// =========================================================================
local function UpdatePlayerESP(enabled)
    State.PlayerESP = enabled
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local existing = plr.Character:FindFirstChild("ChelseaaESP")
            if enabled then
                if not existing then
                    local hl = Instance.new("Highlight")
                    hl.Name = "ChelseaaESP"
                    hl.FillColor = Color3.fromRGB(220, 38, 68)
                    hl.OutlineColor = Color3.fromRGB(56, 189, 248)
                    hl.FillTransparency = 0.55
                    hl.OutlineTransparency = 0
                    hl.Parent = plr.Character
                end
            elseif existing then
                existing:Destroy()
            end
        end
    end
end

local function UpdateNameplateESP(enabled)
    State.NameplateESP = enabled
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            if head then
                local existing = head:FindFirstChild("ChelseaaNameTag")
                if enabled then
                    if not existing then
                        local bb = Instance.new("BillboardGui")
                        bb.Name = "ChelseaaNameTag"
                        bb.Size = UDim2.new(0, 140, 0, 34)
                        bb.StudsOffset = Vector3.new(0, 2.5, 0)
                        bb.AlwaysOnTop = true
                        bb.Parent = head

                        local tl = Instance.new("TextLabel")
                        tl.Size = UDim2.new(1, 0, 1, 0)
                        tl.BackgroundTransparency = 1
                        tl.Text = plr.DisplayName .. " (@" .. plr.Name .. ")"
                        tl.Font = Enum.Font.GothamBold
                        tl.TextSize = 11
                        tl.TextColor3 = Color3.fromRGB(56, 189, 248)
                        tl.TextStrokeTransparency = 0.2
                        tl.Parent = bb
                    end
                elseif existing then
                    existing:Destroy()
                end
            end
        end
    end
end

local function ToggleCharacterAura(auraClass, auraName)
    local root = GetRootPart()
    if not root then return end
    local existing = root:FindFirstChild(auraName)
    if existing then
        existing:Destroy()
        SetStatus("Removed " .. auraName)
    else
        local inst = Instance.new(auraClass)
        inst.Name = auraName
        inst.Parent = root
        SetStatus("Activated " .. auraName)
    end
end

local function SetXRayWalls(enabled)
    State.XRayActive = enabled
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v:IsDescendantOf(LocalPlayer.Character or Instance.new("Folder")) then
            if enabled then
                if v.Transparency < 0.5 and v.CanCollide then
                    v:SetAttribute("ChelseaaOrigTrans", v.Transparency)
                    v.Transparency = 0.65
                end
            else
                local orig = v:GetAttribute("ChelseaaOrigTrans")
                if orig ~= nil then
                    v.Transparency = orig
                    v:SetAttribute("ChelseaaOrigTrans", nil)
                end
            end
        end
    end
end

local function ClearAllSpawnedObjects()
    for _, p in ipairs(SpawnedObjects) do
        if p and p.Parent then
            p:Destroy()
        end
    end
    SpawnedObjects = {}
end

local function ApplyClientHeadless(enabled)
    State.ClientHeadless = enabled
    local char = GetCharacter()
    if not char then return end
    local head = char:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        head.Transparency = enabled and 1 or 0
        for _, child in ipairs(head:GetChildren()) do
            if child:IsA("Decal") or child:IsA("Texture") then
                child.Transparency = enabled and 1 or 0
            end
        end
    end
end

local function ApplyClientKorblox(enabled)
    State.ClientKorblox = enabled
    local char = GetCharacter()
    if not char then return end

    local r15Parts = { "RightUpperLeg", "RightLowerLeg", "RightFoot" }
    local r6Part = char:FindFirstChild("Right Leg")
    local attachTarget = char:FindFirstChild("RightUpperLeg") or r6Part

    local oldMeshPart = char:FindFirstChild("ChelseaaKorbloxLeg")
    if oldMeshPart then
        oldMeshPart:Destroy()
    end

    if enabled then
        for _, partName in ipairs(r15Parts) do
            local p = char:FindFirstChild(partName)
            if p and p:IsA("BasePart") then
                p.Transparency = 1
            end
        end
        if r6Part and r6Part:IsA("BasePart") then
            r6Part.Transparency = 1
        end

        if attachTarget and attachTarget:IsA("BasePart") then
            local kPart = Instance.new("Part")
            kPart.Name = "ChelseaaKorbloxLeg"
            kPart.Size = Vector3.new(1, 2, 1)
            kPart.CanCollide = false
            kPart.Massless = true
            kPart.Color = Color3.fromRGB(45, 52, 68)
            kPart.Material = Enum.Material.SmoothPlastic
            kPart.CFrame = attachTarget.CFrame * CFrame.new(0, -0.35, 0)
            kPart.Parent = char

            local mesh = Instance.new("SpecialMesh")
            mesh.MeshType = Enum.MeshType.FileMesh
            mesh.MeshId = "rbxassetid://101851696"
            mesh.TextureId = "rbxassetid://101851254"
            mesh.Scale = Vector3.new(1, 1, 1)
            mesh.Parent = kPart

            local weld = Instance.new("WeldConstraint")
            weld.Part0 = attachTarget
            weld.Part1 = kPart
            weld.Parent = kPart
        end
    else
        for _, partName in ipairs(r15Parts) do
            local p = char:FindFirstChild(partName)
            if p and p:IsA("BasePart") then
                p.Transparency = 0
            end
        end
        if r6Part and r6Part:IsA("BasePart") then
            r6Part.Transparency = 0
        end
    end
end

local function UpdateHorsemanArmPose(char)
    if not char then return end
    local r15Shoulder = char:FindFirstChild("RightShoulder", true)
    local r15Elbow = char:FindFirstChild("RightElbow", true)
    local r15Wrist = char:FindFirstChild("RightWrist", true)
    if r15Shoulder and r15Shoulder:IsA("Motor6D") then
        r15Shoulder.Transform = CFrame.Angles(math.rad(56), math.rad(12), math.rad(-14))
        if r15Elbow and r15Elbow:IsA("Motor6D") then
            r15Elbow.Transform = CFrame.Angles(math.rad(32), 0, 0)
        end
        if r15Wrist and r15Wrist:IsA("Motor6D") then
            r15Wrist.Transform = CFrame.Angles(math.rad(-12), 0, 0)
        end
        return
    end

    local torso = char:FindFirstChild("Torso")
    local r6Shoulder = torso and torso:FindFirstChild("Right Shoulder")
    if r6Shoulder and r6Shoulder:IsA("Motor6D") then
        r6Shoulder.Transform = CFrame.Angles(0, 0, math.rad(68)) * CFrame.Angles(0, math.rad(-16), 0)
    end
end

local function ApplyClientHeadlessHorseman(enabled)
    State.ClientHeadlessHorseman = enabled
    local char = GetCharacter()
    if not char then return end

    local oldHeld = char:FindFirstChild("ChelseaaHorsemanHeldHead")
    if oldHeld then oldHeld:Destroy() end
    local oldNeck = char:FindFirstChild("ChelseaaHorsemanNeckFlame", true)
    if oldNeck then oldNeck:Destroy() end

    local head = char:FindFirstChild("Head")
    if enabled then
        if head and head:IsA("BasePart") then
            head.Transparency = 1
            for _, child in ipairs(head:GetChildren()) do
                if child:IsA("Decal") or child:IsA("Texture") then
                    child.Transparency = 1
                end
            end
        end

        UpdateHorsemanArmPose(char)

        local root = GetRootPart()
        local isR15 = char:FindFirstChild("RightHand") ~= nil
        local handPart = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
        if handPart and handPart:IsA("BasePart") then
            local heldHead = Instance.new("Part")
            heldHead.Name = "ChelseaaHorsemanHeldHead"
            heldHead.Size = Vector3.new(1.25, 1.25, 1.25)
            heldHead.CanCollide = false
            heldHead.Massless = true
            heldHead.Color = Color3.fromRGB(255, 115, 0)
            heldHead.Material = Enum.Material.Neon

            if root then
                local forwardDir = root.CFrame.LookVector
                local rightDir = root.CFrame.RightVector
                local palmOffset = isR15
                    and (forwardDir * 0.35 + Vector3.new(0, 0.38, 0) - rightDir * 0.05)
                    or (forwardDir * 0.85 + Vector3.new(0, -0.15, 0) - rightDir * 0.08)
                local headPos = handPart.Position + palmOffset
                heldHead.CFrame = CFrame.lookAt(headPos, headPos + forwardDir, Vector3.yAxis)
                    * CFrame.Angles(math.rad(10), math.rad(12), 0)
            else
                local fallbackOffset = isR15
                    and (CFrame.new(0, 0.35, -0.35) * CFrame.Angles(math.rad(-75), 0, 0))
                    or (CFrame.new(0, -0.85, -0.45) * CFrame.Angles(math.rad(-65), 0, 0))
                heldHead.CFrame = handPart.CFrame * fallbackOffset
            end
            heldHead.Parent = char

            local mesh = Instance.new("SpecialMesh")
            mesh.MeshType = Enum.MeshType.FileMesh
            mesh.MeshId = "rbxassetid://16627529"
            mesh.TextureId = "rbxassetid://16627494"
            mesh.Scale = Vector3.new(1.18, 1.18, 1.18)
            mesh.Parent = heldHead

            local hFire = Instance.new("Fire")
            hFire.Name = "HalloweenFire"
            hFire.Color = Color3.fromRGB(255, 110, 0)
            hFire.SecondaryColor = Color3.fromRGB(168, 35, 255)
            hFire.Size = 4.5
            hFire.Heat = 8
            hFire.Parent = heldHead

            local hLight = Instance.new("PointLight")
            hLight.Color = Color3.fromRGB(255, 125, 20)
            hLight.Brightness = 2.2
            hLight.Range = 12
            hLight.Parent = heldHead

            local hSparkles = Instance.new("Sparkles")
            hSparkles.SparkleColor = Color3.fromRGB(255, 145, 0)
            hSparkles.Parent = heldHead

            local weld = Instance.new("WeldConstraint")
            weld.Part0 = handPart
            weld.Part1 = heldHead
            weld.Parent = heldHead
        end

        local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        if torso and torso:IsA("BasePart") then
            local neckAtt = Instance.new("Attachment")
            neckAtt.Name = "ChelseaaHorsemanNeckFlame"
            neckAtt.Position = Vector3.new(0, torso.Size.Y * 0.5, 0)
            neckAtt.Parent = torso

            local neckFire = Instance.new("Fire")
            neckFire.Color = Color3.fromRGB(255, 95, 0)
            neckFire.SecondaryColor = Color3.fromRGB(145, 25, 255)
            neckFire.Size = 2.5
            neckFire.Heat = 5
            neckFire.Parent = neckAtt
        end
    else
        local r15Shoulder = char:FindFirstChild("RightShoulder", true)
        local r15Elbow = char:FindFirstChild("RightElbow", true)
        local r15Wrist = char:FindFirstChild("RightWrist", true)
        if r15Shoulder and r15Shoulder:IsA("Motor6D") then r15Shoulder.Transform = CFrame.new() end
        if r15Elbow and r15Elbow:IsA("Motor6D") then r15Elbow.Transform = CFrame.new() end
        if r15Wrist and r15Wrist:IsA("Motor6D") then r15Wrist.Transform = CFrame.new() end
        local torso = char:FindFirstChild("Torso")
        local r6Shoulder = torso and torso:FindFirstChild("Right Shoulder")
        if r6Shoulder and r6Shoulder:IsA("Motor6D") then r6Shoulder.Transform = CFrame.new() end

        if not State.ClientHeadless and head and head:IsA("BasePart") then
            head.Transparency = 0
            for _, child in ipairs(head:GetChildren()) do
                if child:IsA("Decal") or child:IsA("Texture") then
                    child.Transparency = 0
                end
            end
        end
    end
end

local function LoadCustomMenuImage(url, fileName)
    local resolved = ""
    pcall(function()
        local getAsset = getcustomasset or getsynasset
        if type(getAsset) == "function" and type(writefile) == "function" then
            local rawBytes = game:HttpGet(url)
            if rawBytes and #rawBytes > 0 then
                writefile(fileName, rawBytes)
                resolved = getAsset(fileName)
            end
        end
    end)
    return resolved
end

-- Forward references for UI updates
local ApplyUITheme = function(_) end
local ToggleMenuWallpaper = function(_) end
local SetWallpaperTransparency = function(_) end
local CenterMainWindow = function() end

--// =========================================================================
--// 190 GENUINE FEATURES REGISTRY (100% REAL FEATURES - ZERO SPEED FILLER)
--// =========================================================================
local Commands = {}
local New100Features = {}
local CommandLookup = {}

local function RegisterCommand(name, category, subTag, desc, isFeatured, callback)
    local idx = #Commands + 1
    local entry = {
        id = idx,
        name = name,
        category = category,
        subTag = subTag,
        desc = desc,
        isNew100 = isFeatured or false,
        run = function()
            callback()
            SetStatus(string.format("[#%d] %s", idx, desc))
        end,
    }
    Commands[idx] = entry
    CommandLookup[string.lower(name)] = entry
    CommandLookup[tostring(idx)] = entry
    if isFeatured then
        table.insert(New100Features, entry)
    end
end

-- 1. Visual, ESP & World Shaders (32 Features)
RegisterCommand("Player Highlight ESP ON", "Visual/ESP", "Visual/ESP", "Highlight all players through walls (Crimson/Cyan)", true, function()
    UpdatePlayerESP(true)
end)
RegisterCommand("Player Highlight ESP OFF", "Visual/ESP", "Visual/ESP", "Disable Player Highlight ESP", true, function()
    UpdatePlayerESP(false)
end)
RegisterCommand("Nameplate & Tag ESP ON", "Visual/ESP", "Visual/ESP", "Show floating player DisplayNames through walls", true, function()
    UpdateNameplateESP(true)
end)
RegisterCommand("Nameplate & Tag ESP OFF", "Visual/ESP", "Visual/ESP", "Remove floating player nameplates", true, function()
    UpdateNameplateESP(false)
end)
RegisterCommand("X-Ray Walls ON", "Visual/ESP", "Visual/ESP", "Make solid map walls semi-transparent (X-Ray)", true, function()
    SetXRayWalls(true)
end)
RegisterCommand("X-Ray Walls OFF", "Visual/ESP", "Visual/ESP", "Restore solid wall transparency", true, function()
    SetXRayWalls(false)
end)
RegisterCommand("Rainbow Character ON", "Visual/ESP", "Visual/ESP", "Cycle smooth RGB neon colors across avatar", true, function()
    State.RainbowChar = true
end)
RegisterCommand("Rainbow Character OFF", "Visual/ESP", "Visual/ESP", "Stop Rainbow Character color cycle", true, function()
    State.RainbowChar = false
end)
RegisterCommand("ForceField Body Shield", "Visual/ESP", "Visual/ESP", "Apply glowing ForceField material to avatar", true, function()
    local char = GetCharacter()
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.Material = Enum.Material.ForceField end
        end
    end
end)
RegisterCommand("Neon Glow Body", "Visual/ESP", "Visual/ESP", "Apply bright Neon material to avatar parts", true, function()
    local char = GetCharacter()
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.Material = Enum.Material.Neon end
        end
    end
end)
RegisterCommand("Fire Aura Toggle", "Visual/ESP", "Visual/ESP", "Toggle blazing Fire aura on HumanoidRootPart", true, function()
    ToggleCharacterAura("Fire", "ChelseaaFireAura")
end)
RegisterCommand("Sparkles Aura Toggle", "Visual/ESP", "Visual/ESP", "Toggle cyber Sparkles aura on HumanoidRootPart", true, function()
    ToggleCharacterAura("Sparkles", "ChelseaaSparklesAura")
end)
RegisterCommand("Smoke Aura Toggle", "Visual/ESP", "Visual/ESP", "Toggle dark Smoke aura on HumanoidRootPart", true, function()
    ToggleCharacterAura("Smoke", "ChelseaaSmokeAura")
end)
RegisterCommand("Cyber Trail Toggle", "Visual/ESP", "Visual/ESP", "Attach glowing crimson-cyan motion trail behind you", true, function()
    local root = GetRootPart()
    if not root then return end
    local old = root:FindFirstChild("ChelseaaTrail")
    if old then
        old:Destroy()
        return
    end
    local a0 = Instance.new("Attachment", root)
    a0.Position = Vector3.new(0, 1.5, 0)
    local a1 = Instance.new("Attachment", root)
    a1.Position = Vector3.new(0, -1.5, 0)
    local tr = Instance.new("Trail")
    tr.Name = "ChelseaaTrail"
    tr.Attachment0 = a0
    tr.Attachment1 = a1
    tr.Lifetime = 0.6
    tr.Color = ColorSequence.new(Color3.fromRGB(220, 38, 68), Color3.fromRGB(56, 189, 248))
    tr.Parent = root
end)
RegisterCommand("Fullbright Max", "Visual/ESP", "Visual/ESP", "Maximum daylight brightness with zero shadows", true, function()
    Lighting.Brightness = 3
    Lighting.ClockTime = 14
    Lighting.FogEnd = 100000
    Lighting.GlobalShadows = false
    Lighting.Ambient = Color3.fromRGB(180, 180, 180)
end)
RegisterCommand("Midnight Obsidian Sky", "Visual/ESP", "Visual/ESP", "Switch world sky to sleek dark midnight mode", true, function()
    Lighting.ClockTime = 0
    Lighting.Brightness = 1
    Lighting.Ambient = Color3.fromRGB(35, 35, 50)
end)
RegisterCommand("Cyber Crimson Shader", "Visual/ESP", "Visual/ESP", "Apply red-tinted cyber-anime atmosphere lighting", true, function()
    Lighting.Ambient = Color3.fromRGB(140, 30, 55)
    Lighting.OutdoorAmbient = Color3.fromRGB(160, 40, 70)
    Lighting.FogColor = Color3.fromRGB(45, 10, 20)
    Lighting.FogEnd = 800
end)
RegisterCommand("Golden Sunset Shader", "Visual/ESP", "Visual/ESP", "Apply warm golden hour sunset lighting", true, function()
    Lighting.ClockTime = 17.8
    Lighting.Ambient = Color3.fromRGB(150, 105, 65)
    Lighting.OutdoorAmbient = Color3.fromRGB(180, 120, 70)
end)
RegisterCommand("Night Vision Emerald Shader", "Visual/ESP", "Visual/ESP", "Bright emerald-green night vision filter", true, function()
    Lighting.Brightness = 2.5
    Lighting.Ambient = Color3.fromRGB(40, 180, 90)
    Lighting.OutdoorAmbient = Color3.fromRGB(50, 210, 110)
    Lighting.GlobalShadows = false
end)
RegisterCommand("Noir Monochrome Filter", "Visual/ESP", "Visual/ESP", "Turn world colors into dramatic black-and-white cinema", true, function()
    local cc = Lighting:FindFirstChild("ChelseaaNoir") or Instance.new("ColorCorrectionEffect", Lighting)
    cc.Name = "ChelseaaNoir"
    cc.Enabled = true
    cc.Saturation = -1
    cc.Contrast = 0.25
end)
RegisterCommand("Neon Cyber Bloom FX", "Visual/ESP", "Visual/ESP", "Add bright neon bloom glow to light sources", true, function()
    local bl = Lighting:FindFirstChild("ChelseaaBloom") or Instance.new("BloomEffect", Lighting)
    bl.Name = "ChelseaaBloom"
    bl.Enabled = true
    bl.Intensity = 0.85
    bl.Size = 24
end)
RegisterCommand("SunRays God-Beam FX", "Visual/ESP", "Visual/ESP", "Enable warm sunbeam light shafts across sky", true, function()
    local sr = Lighting:FindFirstChild("ChelseaaSunRays") or Instance.new("SunRaysEffect", Lighting)
    sr.Name = "ChelseaaSunRays"
    sr.Enabled = true
    sr.Intensity = 0.25
end)
RegisterCommand("PointLight Body Lantern ON", "Visual/ESP", "Visual/ESP", "Attach warm glowing lantern light around your avatar", true, function()
    local root = GetRootPart()
    if root and not root:FindFirstChild("ChelseaaLantern") then
        local pl = Instance.new("PointLight")
        pl.Name = "ChelseaaLantern"
        pl.Brightness = 2.2
        pl.Range = 28
        pl.Color = Color3.fromRGB(255, 225, 185)
        pl.Parent = root
    end
end)
RegisterCommand("PointLight Body Lantern OFF", "Visual/ESP", "Visual/ESP", "Turn off avatar lantern light", true, function()
    local root = GetRootPart()
    local pl = root and root:FindFirstChild("ChelseaaLantern")
    if pl then pl:Destroy() end
end)
RegisterCommand("Chams Box Nearest Player", "Visual/ESP", "Visual/ESP", "Draw 3D cyber selection box around nearest player", true, function()
    local nearRoot = FindNearestPlayerRoot()
    if nearRoot and nearRoot.Parent then
        local old = nearRoot.Parent:FindFirstChild("ChelseaaChamsBox")
        if old then old:Destroy() end
        local sb = Instance.new("SelectionBox")
        sb.Name = "ChelseaaChamsBox"
        sb.Adornee = nearRoot.Parent
        sb.Color3 = Color3.fromRGB(56, 189, 248)
        sb.LineThickness = 0.04
        sb.Parent = nearRoot.Parent
    end
end)
RegisterCommand("Clear Player Chams Boxes", "Visual/ESP", "Visual/ESP", "Remove all 3D selection boxes on players", true, function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            local sb = plr.Character:FindFirstChild("ChelseaaChamsBox")
            if sb then sb:Destroy() end
        end
    end
end)
RegisterCommand("Hide Terrain Water", "Visual/ESP", "Visual/ESP", "Make map water crystal clear / invisible", true, function()
    if workspace.Terrain then
        workspace.Terrain.WaterTransparency = 1
    end
end)
RegisterCommand("Remove Map Fog", "Visual/ESP", "Visual/ESP", "Clear all distance fog for crystal-clear vision", true, function()
    Lighting.FogEnd = 1000000
    Lighting.FogStart = 999999
end)
RegisterCommand("FPS Booster LowGFX", "Visual/ESP", "Visual/ESP", "Convert parts to SmoothPlastic & hide decals for max FPS", true, function()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        end
    end
end)
RegisterCommand("Disable Map Particles", "Visual/ESP", "Visual/ESP", "Turn off laggy ParticleEmitters & Beams in map", true, function()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Beam") then
            v.Enabled = false
        end
    end
end)
RegisterCommand("Disable Global Shadows", "Visual/ESP", "Visual/ESP", "Turn off world shadows for brighter vision & smoother FPS", true, function()
    Lighting.GlobalShadows = false
end)
RegisterCommand("Restore Default Lighting", "Visual/ESP", "Visual/ESP", "Reset lighting, shaders & fog back to original map settings", true, function()
    for k, v in pairs(OriginalLighting) do
        Lighting[k] = v
    end
    for _, fxName in ipairs({ "ChelseaaNoir", "ChelseaaBloom", "ChelseaaSunRays", "ChelseaaCC" }) do
        local fx = Lighting:FindFirstChild(fxName)
        if fx then fx:Destroy() end
    end
end)

-- 2. Camera & Spectate (25 Features)
RegisterCommand("Camera FOV 60 (Sniper Zoom)", "Camera", "Camera", "Set tight sniper zoom Field of View (60)", true, function()
    if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = 60 end
end)
RegisterCommand("Camera FOV 70 (Default)", "Camera", "Camera", "Reset Field of View to standard Roblox default (70)", true, function()
    if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = 70 end
end)
RegisterCommand("Camera FOV 90 (Wide)", "Camera", "Camera", "Set wide action Field of View (90)", true, function()
    if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = 90 end
end)
RegisterCommand("Camera FOV 105 (Pro)", "Camera", "Camera", "Set competitive wide Field of View (105)", true, function()
    if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = 105 end
end)
RegisterCommand("Camera FOV 120 (Ultra)", "Camera", "Camera", "Set maximum ultra-wide Field of View (120)", true, function()
    if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = 120 end
end)
RegisterCommand("FreeCam Detach Mode ON", "Camera", "Camera", "Detach camera to fly around map freely", true, function()
    local cam = workspace.CurrentCamera
    if cam then
        State.FreeCamEnabled = true
        State.FreeCamCFrame = cam.CFrame
        cam.CameraType = Enum.CameraType.Scriptable
    end
end)
RegisterCommand("FreeCam Detach Mode OFF", "Camera", "Camera", "Return camera back to normal character control", true, function()
    State.FreeCamEnabled = false
    local cam = workspace.CurrentCamera
    local hum = GetHumanoid()
    if cam then
        cam.CameraType = Enum.CameraType.Custom
        if hum then cam.CameraSubject = hum end
    end
end)
RegisterCommand("Over-Shoulder Action Cam", "Camera", "Camera", "Shift camera to a third-person over-the-shoulder angle", true, function()
    local hum = GetHumanoid()
    if hum then hum.CameraOffset = Vector3.new(2.2, 0.6, -1.2) end
end)
RegisterCommand("Reset Camera Offset", "Camera", "Camera", "Reset Humanoid CameraOffset to center", true, function()
    local hum = GetHumanoid()
    if hum then hum.CameraOffset = Vector3.zero end
end)
RegisterCommand("Unlock Zoom 500 Studs", "Camera", "Camera", "Allow zooming camera out up to 500 studs", true, function()
    LocalPlayer.CameraMaxZoomDistance = 500
end)
RegisterCommand("Unlock Zoom 5000 Studs", "Camera", "Camera", "Allow zooming camera out across entire map (5000)", true, function()
    LocalPlayer.CameraMaxZoomDistance = 5000
end)
RegisterCommand("Restore Default Zoom (128)", "Camera", "Camera", "Reset max zoom distance to standard 128 studs", true, function()
    LocalPlayer.CameraMaxZoomDistance = 128
end)
RegisterCommand("First Person Mode", "Camera", "Camera", "Lock camera into First-Person perspective", true, function()
    LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
end)
RegisterCommand("Third Person Classic", "Camera", "Camera", "Unlock Third-Person camera perspective", true, function()
    LocalPlayer.CameraMode = Enum.CameraMode.Classic
    LocalPlayer.CameraMinZoomDistance = 0.5
end)
RegisterCommand("Spectate Nearest Player", "Camera", "Camera", "Focus camera onto the closest player near you", true, function()
    local nearRoot = FindNearestPlayerRoot()
    local cam = workspace.CurrentCamera
    if nearRoot and nearRoot.Parent and cam then
        local hum = nearRoot.Parent:FindFirstChildOfClass("Humanoid")
        if hum then cam.CameraSubject = hum end
    end
end)
RegisterCommand("Spectate Next Player", "Camera", "Camera", "Cycle camera view forward to the next player", true, function()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local pool = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") then
            table.insert(pool, plr.Character:FindFirstChildOfClass("Humanoid"))
        end
    end
    if #pool > 0 then
        State.SpectateIndex = (State.SpectateIndex % #pool) + 1
        cam.CameraSubject = pool[State.SpectateIndex]
    end
end)
RegisterCommand("Spectate Previous Player", "Camera", "Camera", "Cycle camera view backward to previous player", true, function()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local pool = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") then
            table.insert(pool, plr.Character:FindFirstChildOfClass("Humanoid"))
        end
    end
    if #pool > 0 then
        State.SpectateIndex = ((State.SpectateIndex - 2) % #pool) + 1
        cam.CameraSubject = pool[State.SpectateIndex]
    end
end)
RegisterCommand("Spectate Random Player", "Camera", "Camera", "Switch camera view to a random player in server", true, function()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local pool = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") then
            table.insert(pool, plr.Character:FindFirstChildOfClass("Humanoid"))
        end
    end
    if #pool > 0 then
        cam.CameraSubject = pool[math.random(1, #pool)]
    end
end)
RegisterCommand("Reset Camera to Self", "Camera", "Camera", "Return camera focus back to your own character", true, function()
    State.FreeCamEnabled = false
    local cam = workspace.CurrentCamera
    local hum = GetHumanoid()
    if cam and hum then
        cam.CameraType = Enum.CameraType.Custom
        cam.CameraSubject = hum
    end
end)
RegisterCommand("ShiftLock Enable", "Camera", "Camera", "Enable Mouse ShiftLock toggle option", true, function()
    LocalPlayer.DevEnableMouseLock = true
end)
RegisterCommand("Face Camera Direction", "Camera", "Camera", "Snap character rotation to match camera look angle", true, function()
    local root = GetRootPart()
    local cam = workspace.CurrentCamera
    if root and cam then
        local look = cam.CFrame.LookVector
        root.CFrame = CFrame.lookAt(root.Position, root.Position + Vector3.new(look.X, 0, look.Z))
    end
end)
RegisterCommand("Cinematic Camera Shake", "Camera", "Camera", "Trigger brief action camera vibration effect", true, function()
    local hum = GetHumanoid()
    if hum then
        task.spawn(function()
            for i = 1, 12 do
                hum.CameraOffset = Vector3.new((math.random() - 0.5) * 0.5, (math.random() - 0.5) * 0.5, 0)
                task.wait(0.03)
            end
            hum.CameraOffset = Vector3.zero
        end)
    end
end)
RegisterCommand("Clear Camera Blur/Color", "Camera", "Camera", "Disable BlurEffect & ColorCorrection post-processing", true, function()
    for _, fx in ipairs(Lighting:GetChildren()) do
        if fx:IsA("BlurEffect") or fx:IsA("ColorCorrectionEffect") or fx:IsA("DepthOfFieldEffect") then
            fx.Enabled = false
        end
    end
end)
RegisterCommand("Cyber Contrast Enhance", "Camera", "Camera", "Add crisp ColorCorrection contrast boost", true, function()
    local cc = Lighting:FindFirstChild("ChelseaaCC") or Instance.new("ColorCorrectionEffect", Lighting)
    cc.Name = "ChelseaaCC"
    cc.Enabled = true
    cc.Contrast = 0.22
    cc.Saturation = 0.18
end)
RegisterCommand("Depth of Field Focus", "Camera", "Camera", "Enable subtle background depth-of-field blur", true, function()
    local dof = Lighting:FindFirstChild("ChelseaaDOF") or Instance.new("DepthOfFieldEffect", Lighting)
    dof.Name = "ChelseaaDOF"
    dof.Enabled = true
    dof.FocusDistance = 25
    dof.InFocusRadius = 35
end)

-- 3. Physics, Orbit & Movement Mechanics (34 Features)
RegisterCommand("Orbit Nearest Player ON", "Physics/Fun", "Physics/Fun", "Smoothly circle around the nearest player", true, function()
    State.OrbitPlayer = true
end)
RegisterCommand("Orbit Nearest Player OFF", "Physics/Fun", "Physics/Fun", "Stop orbiting nearest player", true, function()
    State.OrbitPlayer = false
end)
RegisterCommand("Spider Wall Climb ON", "Physics/Fun", "Physics/Fun", "Climb straight up walls when walking against them", true, function()
    State.SpiderClimb = true
end)
RegisterCommand("Spider Wall Climb OFF", "Physics/Fun", "Physics/Fun", "Disable Spider Wall Climb", true, function()
    State.SpiderClimb = false
end)
RegisterCommand("Auto-Strafe Circle ON", "Physics/Fun", "Physics/Fun", "Perform continuous circular combat strafe", true, function()
    State.AutoStrafe = true
end)
RegisterCommand("Auto-Strafe Circle OFF", "Physics/Fun", "Physics/Fun", "Disable circular auto-strafe", true, function()
    State.AutoStrafe = false
end)
RegisterCommand("Equip Click-TP Tool", "Physics/Fun", "Physics/Fun", "Add a local Click-to-Teleport tool into Backpack", true, function()
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not bp or bp:FindFirstChild("ChelseaaClickTP") then return end
    local tool = Instance.new("Tool")
    tool.Name = "ChelseaaClickTP"
    tool.RequiresHandle = false
    tool.Activated:Connect(function()
        local mouse = LocalPlayer:GetMouse()
        local root = GetRootPart()
        if mouse and mouse.Hit and root then
            root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3.2, 0))
        end
    end)
    tool.Parent = bp
end)
RegisterCommand("Remove Click-TP Tool", "Physics/Fun", "Physics/Fun", "Remove local Click-TP tool from Backpack/Character", true, function()
    for _, container in ipairs({ LocalPlayer:FindFirstChildOfClass("Backpack"), GetCharacter() }) do
        local t = container and container:FindFirstChild("ChelseaaClickTP")
        if t then t:Destroy() end
    end
end)
RegisterCommand("Slow Spin (Speed 5)", "Physics/Fun", "Physics/Fun", "Rotate character smoothly at speed 5", true, function()
    State.SpinSpeed = 5
end)
RegisterCommand("Fast Spinbot (Speed 25)", "Physics/Fun", "Physics/Fun", "Spin character rapidly at speed 25", true, function()
    State.SpinSpeed = 25
end)
RegisterCommand("Tornado Spin (Speed 65)", "Physics/Fun", "Physics/Fun", "Ultra-fast tornado spinbot at speed 65", true, function()
    State.SpinSpeed = 65
end)
RegisterCommand("Stop Character Spin", "Physics/Fun", "Physics/Fun", "Stop character rotation immediately", true, function()
    State.SpinSpeed = 0
end)
RegisterCommand("Moon Gravity (Low)", "Physics/Fun", "Physics/Fun", "Low lunar gravity (35) for floaty high jumps", true, function()
    workspace.Gravity = 35
end)
RegisterCommand("Zero-G Space Float", "Physics/Fun", "Physics/Fun", "Near-zero gravity (5) space floating", true, function()
    workspace.Gravity = 5
end)
RegisterCommand("Heavy Planet Gravity", "Physics/Fun", "Physics/Fun", "High gravity (350) for instant fast landing", true, function()
    workspace.Gravity = 350
end)
RegisterCommand("Reset Standard Gravity", "Physics/Fun", "Physics/Fun", "Restore standard Roblox gravity (196.2)", true, function()
    workspace.Gravity = 196.2
end)
RegisterCommand("Bunny Hop Auto-Jump ON", "Physics/Fun", "Physics/Fun", "Automatically jump continuously while moving", true, function()
    State.BunnyHop = true
end)
RegisterCommand("Bunny Hop Auto-Jump OFF", "Physics/Fun", "Physics/Fun", "Disable Bunny Hop auto-jump", true, function()
    State.BunnyHop = false
end)
RegisterCommand("Air Walk Sky Floor ON", "Physics/Fun", "Physics/Fun", "Walk in mid-air on an invisible dynamic floor", true, function()
    State.AirWalk = true
end)
RegisterCommand("Air Walk Sky Floor OFF", "Physics/Fun", "Physics/Fun", "Disable mid-air walking floor", true, function()
    State.AirWalk = false
end)
RegisterCommand("Spawn Neon Glass Platform", "Physics/Fun", "Physics/Fun", "Spawn a solid neon glass platform beneath your feet", true, function()
    local root = GetRootPart()
    if not root then return end
    local plat = Instance.new("Part")
    plat.Size = Vector3.new(16, 1, 16)
    plat.Anchored = true
    plat.Material = Enum.Material.Neon
    plat.Color = Color3.fromRGB(220, 38, 68)
    plat.Transparency = 0.35
    plat.CFrame = root.CFrame * CFrame.new(0, -3.5, 0)
    plat.Parent = workspace
    table.insert(SpawnedObjects, plat)
end)
RegisterCommand("Spawn Neon Sky Bridge", "Physics/Fun", "Physics/Fun", "Spawn a 45-stud neon bridge directly in front of you", true, function()
    local root = GetRootPart()
    if not root then return end
    local bridge = Instance.new("Part")
    bridge.Size = Vector3.new(8, 1, 45)
    bridge.Anchored = true
    bridge.Material = Enum.Material.Neon
    bridge.Color = Color3.fromRGB(56, 189, 248)
    bridge.Transparency = 0.3
    bridge.CFrame = root.CFrame * CFrame.new(0, -3.5, -24)
    bridge.Parent = workspace
    table.insert(SpawnedObjects, bridge)
end)
RegisterCommand("Spawn High-Bounce Trampoline", "Physics/Fun", "Physics/Fun", "Spawn a bouncy launch pad beneath your avatar", true, function()
    local root = GetRootPart()
    if not root then return end
    local pad = Instance.new("Part")
    pad.Size = Vector3.new(10, 1.2, 10)
    pad.Anchored = true
    pad.Material = Enum.Material.Neon
    pad.Color = Color3.fromRGB(34, 197, 94)
    pad.CFrame = root.CFrame * CFrame.new(0, -3.5, 0)
    pad.CustomPhysicalProperties = PhysicalProperties.new(1, 0.3, 1, 1, 100)
    pad.Touched:Connect(function(hit)
        if hit and hit.Parent == GetCharacter() then
            local hrp = GetRootPart()
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 125, hrp.AssemblyLinearVelocity.Z)
            end
        end
    end)
    pad.Parent = workspace
    table.insert(SpawnedObjects, pad)
end)
RegisterCommand("Clear Spawned Objects", "Physics/Fun", "Physics/Fun", "Remove all platforms, bridges & pads spawned by hub", true, function()
    ClearAllSpawnedObjects()
end)
RegisterCommand("Zero-Friction Ice Slide ON", "Physics/Fun", "Physics/Fun", "Make movement slippery like ice skating", true, function()
    local root = GetRootPart()
    if root then
        root.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0, 0, 100, 1)
    end
end)
RegisterCommand("Zero-Friction Ice Slide OFF", "Physics/Fun", "Physics/Fun", "Restore normal ground traction", true, function()
    local root = GetRootPart()
    if root then
        root.CustomPhysicalProperties = nil
    end
end)
RegisterCommand("Anti-Fling Protection ON", "Physics/Fun", "Physics/Fun", "Clamp extreme velocity spikes to prevent flinging", true, function()
    State.AntiFling = true
end)
RegisterCommand("Anti-Fling Protection OFF", "Physics/Fun", "Physics/Fun", "Disable Anti-Fling velocity clamp", true, function()
    State.AntiFling = false
end)
RegisterCommand("Swim in Air ON", "Physics/Fun", "Physics/Fun", "Enable mid-air swimming state anywhere", true, function()
    State.SwimAir = true
end)
RegisterCommand("Swim in Air OFF", "Physics/Fun", "Physics/Fun", "Disable mid-air swimming state", true, function()
    State.SwimAir = false
end)
RegisterCommand("Forward Dash Boost", "Physics/Fun", "Physics/Fun", "Instant forward momentum dash burst (+45 studs)", true, function()
    local root = GetRootPart()
    if root then
        root.CFrame = root.CFrame * CFrame.new(0, 0, -45)
    end
end)
RegisterCommand("Super Sky Launch", "Physics/Fun", "Physics/Fun", "Launch character upward with vertical velocity", true, function()
    local root = GetRootPart()
    if root then
        root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 140, root.AssemblyLinearVelocity.Z)
    end
end)
RegisterCommand("Mid-Air Backflip Impulse", "Physics/Fun", "Physics/Fun", "Jump and perform a 360-degree backward flip", true, function()
    local root = GetRootPart()
    if root then
        root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 65, root.AssemblyLinearVelocity.Z)
        task.spawn(function()
            for i = 1, 18 do
                if root and root.Parent then
                    root.CFrame = root.CFrame * CFrame.Angles(math.rad(20), 0, 0)
                end
                task.wait(0.02)
            end
        end)
    end
end)
RegisterCommand("Emergency Ground Snap", "Physics/Fun", "Physics/Fun", "Raycast straight down and land safely on solid floor", true, function()
    local root = GetRootPart()
    if root then
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = { GetCharacter() }
        params.FilterType = Enum.RaycastFilterType.Exclude
        local hit = workspace:Raycast(root.Position, Vector3.new(0, -1000, 0), params)
        if hit then
            root.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3.2, 0))
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end
end)

-- 4. Tween & Multi-Slot Waypoints (30 Features)
for slot = 1, 6 do
    RegisterCommand("Save Waypoint Slot " .. slot, "Tween/Waypoints", "Tween/Waypoints", "Save current coordinates to Waypoint Slot #" .. slot, true, function()
        local root = GetRootPart()
        if root then
            State.Waypoints[slot] = root.CFrame
        end
    end)
    RegisterCommand("Tween to Waypoint Slot " .. slot, "Tween/Waypoints", "Tween/Waypoints", "Smoothly tween to Waypoint Slot #" .. slot .. " at Tween Speed", true, function()
        if State.Waypoints[slot] then
            TweenToCFrame(State.Waypoints[slot])
        end
    end)
end
RegisterCommand("Tween Path Loop (Slot 1 <-> 2)", "Tween/Waypoints", "Tween/Waypoints", "Continuously patrol back and forth between Slot 1 & 2", true, function()
    if not State.Waypoints[1] or not State.Waypoints[2] then
        SetStatus("Save Slot 1 and Slot 2 first!")
        return
    end
    State.TweenLoopActive = true
    task.spawn(function()
        local targetIdx = 1
        while State.TweenLoopActive do
            local dest = State.Waypoints[targetIdx]
            if dest then
                local tw = TweenToCFrame(dest)
                if tw then tw.Completed:Wait() end
            end
            targetIdx = (targetIdx == 1) and 2 or 1
            task.wait(0.15)
        end
    end)
end)
RegisterCommand("Stop Tween Path Loop", "Tween/Waypoints", "Tween/Waypoints", "Stop Slot 1 <-> 2 patrol loop immediately", true, function()
    StopActiveTween()
end)
RegisterCommand("Clear All Waypoint Slots", "Tween/Waypoints", "Tween/Waypoints", "Erase all saved coordinates in Slots 1 - 6", true, function()
    State.Waypoints = {}
end)
RegisterCommand("Tween to Nearest Player", "Tween/Waypoints", "Tween/Waypoints", "Tween smoothly to the nearest player at Tween Speed", true, function()
    local nearRoot = FindNearestPlayerRoot()
    if nearRoot then
        TweenToCFrame(nearRoot.CFrame * CFrame.new(0, 0, 3))
    end
end)
RegisterCommand("Tween to Farthest Player", "Tween/Waypoints", "Tween/Waypoints", "Tween across the map to the farthest player", true, function()
    local root = GetRootPart()
    if not root then return end
    local farthest, maxDist = nil, -1
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local d = (plr.Character.HumanoidRootPart.Position - root.Position).Magnitude
            if d > maxDist then
                maxDist = d
                farthest = plr.Character.HumanoidRootPart
            end
        end
    end
    if farthest then
        TweenToCFrame(farthest.CFrame * CFrame.new(0, 0, 3))
    end
end)
RegisterCommand("Tween to Highest Player", "Tween/Waypoints", "Tween/Waypoints", "Tween smoothly to the player at highest altitude", true, function()
    local bestRoot, maxY = nil, -math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = plr.Character.HumanoidRootPart
            if hrp.Position.Y > maxY then
                maxY = hrp.Position.Y
                bestRoot = hrp
            end
        end
    end
    if bestRoot then TweenToCFrame(bestRoot.CFrame * CFrame.new(0, 0, 3)) end
end)
RegisterCommand("Tween to Lowest Player", "Tween/Waypoints", "Tween/Waypoints", "Tween smoothly to the player at lowest altitude", true, function()
    local bestRoot, minY = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = plr.Character.HumanoidRootPart
            if hrp.Position.Y < minY then
                minY = hrp.Position.Y
                bestRoot = hrp
            end
        end
    end
    if bestRoot then TweenToCFrame(bestRoot.CFrame * CFrame.new(0, 0, 3)) end
end)
RegisterCommand("Instant TP to Nearest Player", "Tween/Waypoints", "Tween/Waypoints", "Instant CFrame teleport behind the nearest player", true, function()
    local root = GetRootPart()
    local nearRoot = FindNearestPlayerRoot()
    if root and nearRoot then
        root.CFrame = nearRoot.CFrame * CFrame.new(0, 0, 3)
    end
end)
RegisterCommand("Instant TP to Random Player", "Tween/Waypoints", "Tween/Waypoints", "Instant CFrame teleport to a random player in server", true, function()
    local root = GetRootPart()
    if not root then return end
    local pool = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(pool, plr.Character.HumanoidRootPart)
        end
    end
    if #pool > 0 then
        root.CFrame = pool[math.random(1, #pool)].CFrame * CFrame.new(0, 0, 3)
    end
end)
RegisterCommand("Instant TP to Slot 1", "Tween/Waypoints", "Tween/Waypoints", "Instant CFrame teleport to Waypoint Slot #1", true, function()
    local root = GetRootPart()
    if root and State.Waypoints[1] then
        root.CFrame = State.Waypoints[1]
    end
end)
RegisterCommand("Tween to Map Origin (0,50,0)", "Tween/Waypoints", "Tween/Waypoints", "Tween smoothly to center coordinates (0, 50, 0)", true, function()
    TweenToCFrame(CFrame.new(0, 50, 0))
end)
RegisterCommand("Tween High Sky (+500)", "Tween/Waypoints", "Tween/Waypoints", "Tween 500 studs straight up into the sky", true, function()
    local root = GetRootPart()
    if root then TweenToCFrame(root.CFrame + Vector3.new(0, 500, 0)) end
end)
RegisterCommand("Tween Backward (+50)", "Tween/Waypoints", "Tween/Waypoints", "Smoothly tween 50 studs backward", true, function()
    local root = GetRootPart()
    if root then TweenToCFrame(root.CFrame * CFrame.new(0, 0, 50)) end
end)
RegisterCommand("Tween Strafe Left (+50)", "Tween/Waypoints", "Tween/Waypoints", "Smoothly tween 50 studs to the left", true, function()
    local root = GetRootPart()
    if root then TweenToCFrame(root.CFrame * CFrame.new(-50, 0, 0)) end
end)
RegisterCommand("Tween Strafe Right (+50)", "Tween/Waypoints", "Tween/Waypoints", "Smoothly tween 50 studs to the right", true, function()
    local root = GetRootPart()
    if root then TweenToCFrame(root.CFrame * CFrame.new(50, 0, 0)) end
end)
RegisterCommand("Sync Tween Speed = 2x WS ON", "Tween/Waypoints", "Tween/Waypoints", "Scale Tween Speed dynamically with WalkSpeed (2x)", true, function()
    State.SyncTweenToWalkSpeed = true
end)
RegisterCommand("Sync Tween Speed = 2x WS OFF", "Tween/Waypoints", "Tween/Waypoints", "Use manual Tween Speed input value", true, function()
    State.SyncTweenToWalkSpeed = false
end)
RegisterCommand("Stop Active Tween", "Tween/Waypoints", "Tween/Waypoints", "Cancel active Tween movement immediately", true, function()
    StopActiveTween()
end)

-- 5. Automation & Utility (26 Features)
RegisterCommand("Auto Train Cursor ON", "Automation", "Automation", "Enable precision cursor clicker for 1x/2x/2.30x/3x/4x", true, function()
    State.AutoTrainEnabled = true
end)
RegisterCommand("Auto Train Cursor OFF", "Automation", "Automation", "Disable Auto Train Cursor", true, function()
    State.AutoTrainEnabled = false
end)
RegisterCommand("Auto Train Filter: All (1x-4x)", "Automation", "Automation", "Target all multiplier zones from 1x to 4x", true, function()
    State.AutoTrainFilter = "ALL"
    State.AutoTrainEnabled = true
end)
RegisterCommand("Auto Train Filter: 2x+", "Automation", "Automation", "Target 2x, 2.30x, 3x, and 4x multipliers only", true, function()
    State.AutoTrainFilter = "2X_PLUS"
    State.AutoTrainEnabled = true
end)
RegisterCommand("Auto Train Filter: High Max", "Automation", "Automation", "Target highest multipliers (2.30x / 3x / 4x)", true, function()
    State.AutoTrainFilter = "MAX_ONLY"
    State.AutoTrainEnabled = true
end)
RegisterCommand("Auto Screen Clicker ON", "Automation", "Automation", "Auto-tap center screen continuously for rapid training", true, function()
    State.AutoClickerCenter = true
end)
RegisterCommand("Auto Screen Clicker OFF", "Automation", "Automation", "Stop center screen auto-clicker", true, function()
    State.AutoClickerCenter = false
end)
RegisterCommand("Auto ProximityPrompts ON", "Automation", "Automation", "Automatically trigger nearby interact/collect prompts", true, function()
    State.AutoPrompts = true
end)
RegisterCommand("Auto ProximityPrompts OFF", "Automation", "Automation", "Disable automatic ProximityPrompt interaction", true, function()
    State.AutoPrompts = false
end)
RegisterCommand("Auto Collect TouchItems ON", "Automation", "Automation", "Trigger touch pickup on nearby coins/orbs/items", true, function()
    State.AutoCollectTouch = true
end)
RegisterCommand("Auto Collect TouchItems OFF", "Automation", "Automation", "Disable automatic TouchInterest item pickup", true, function()
    State.AutoCollectTouch = false
end)
RegisterCommand("Auto Jump Obstacles ON", "Automation", "Automation", "Automatically jump over low walls/steps while walking", true, function()
    State.AutoObstacleJump = true
end)
RegisterCommand("Auto Jump Obstacles OFF", "Automation", "Automation", "Disable automatic obstacle jump", true, function()
    State.AutoObstacleJump = false
end)
RegisterCommand("Auto Respawn Death Spot ON", "Automation", "Automation", "Return automatically to your exact death location on respawn", true, function()
    State.AutoRespawnSpot = true
end)
RegisterCommand("Auto Respawn Death Spot OFF", "Automation", "Automation", "Disable auto-return on respawn", true, function()
    State.AutoRespawnSpot = false
end)
RegisterCommand("Equip First Backpack Tool", "Automation", "Automation", "Equip the first available tool from your Backpack", true, function()
    local hum = GetHumanoid()
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if hum and bp then
        local tool = bp:FindFirstChildWhichIsA("Tool")
        if tool then hum:EquipTool(tool) end
    end
end)
RegisterCommand("Unequip All Tools", "Automation", "Automation", "Put held tools back into Backpack", true, function()
    local hum = GetHumanoid()
    if hum then hum:UnequipTools() end
end)
RegisterCommand("Anti-AFK Idle Bypass", "Automation", "Automation", "Prevent 20-minute idle disconnect kick", true, function()
    TrackConn(LocalPlayer.Idled:Connect(function()
        if VirtualUser then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end))
end)
RegisterCommand("Freeze Character Position", "Automation", "Automation", "Anchor HumanoidRootPart in place", true, function()
    local root = GetRootPart()
    if root then root.Anchored = true end
end)
RegisterCommand("Unfreeze Character Position", "Automation", "Automation", "Unanchor HumanoidRootPart to move freely", true, function()
    local root = GetRootPart()
    if root then root.Anchored = false end
end)
RegisterCommand("Copy Current Coordinates", "Automation", "Automation", "Copy current X, Y, Z position to clipboard", true, function()
    local root = GetRootPart()
    if root then
        local posStr = string.format("%.2f, %.2f, %.2f", root.Position.X, root.Position.Y, root.Position.Z)
        if type(setclipboard) == "function" then setclipboard(posStr) end
        SetStatus("Coords: " .. posStr)
    end
end)
RegisterCommand("Copy Server JobId", "Automation", "Automation", "Copy current server JobId to clipboard", true, function()
    if type(setclipboard) == "function" then setclipboard(game.JobId) end
    SetStatus("Copied JobId: " .. tostring(game.JobId))
end)
RegisterCommand("Unlock FPS Cap (240 FPS)", "Automation", "Automation", "Set max framerate cap to 240 FPS if supported", true, function()
    if type(setfpscap) == "function" then setfpscap(240) end
end)
RegisterCommand("Battery Saver Cap (60 FPS)", "Automation", "Automation", "Limit framerate to 60 FPS for cooler device temp", true, function()
    if type(setfpscap) == "function" then setfpscap(60) end
end)
RegisterCommand("Rejoin Current Server", "Automation", "Automation", "Reconnect immediately to current server instance", true, function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)
RegisterCommand("Server Hop (New Server)", "Automation", "Automation", "Join another active public server", true, function()
    pcall(function()
        local raw = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        local data = HttpService:JSONDecode(raw)
        if data and data.data then
            for _, srv in ipairs(data.data) do
                if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
                    break
                end
            end
        end
    end)
end)

-- 6. Character FX, Headless, Korblox & UI Controls (33 Features)
RegisterCommand("Client Headless ON", "Character/UI", "Character/UI", "Make avatar head & face invisible (keeps hair/hats)", true, function()
    ApplyClientHeadless(true)
end)
RegisterCommand("Client Headless OFF", "Character/UI", "Character/UI", "Restore avatar head & face visibility", true, function()
    ApplyClientHeadless(false)
end)
RegisterCommand("Client Headless Horseman ON", "Character/UI", "Character/UI", "31K Robux Halloween bundle: Headless + flaming pumpkin head held in hand", true, function()
    ApplyClientHeadlessHorseman(true)
end)
RegisterCommand("Client Headless Horseman OFF", "Character/UI", "Character/UI", "Remove Headless Horseman held head & Halloween fire", true, function()
    ApplyClientHeadlessHorseman(false)
end)
RegisterCommand("Client Korblox ON", "Character/UI", "Character/UI", "Equip Korblox Deathspeaker right leg (R6 & R15)", true, function()
    ApplyClientKorblox(true)
end)
RegisterCommand("Client Korblox OFF", "Character/UI", "Character/UI", "Restore normal avatar right leg", true, function()
    ApplyClientKorblox(false)
end)
RegisterCommand("Big Head Mode (Client)", "Character/UI", "Character/UI", "Enlarge local avatar head mesh 2.2x", true, function()
    local char = GetCharacter()
    local head = char and char:FindFirstChild("Head")
    local mesh = head and head:FindFirstChildOfClass("SpecialMesh")
    if mesh then mesh.Scale = Vector3.new(2.2, 2.2, 2.2) end
end)
RegisterCommand("Mini Tiny Head (Client)", "Character/UI", "Character/UI", "Shrink local avatar head mesh 0.5x", true, function()
    local char = GetCharacter()
    local head = char and char:FindFirstChild("Head")
    local mesh = head and head:FindFirstChildOfClass("SpecialMesh")
    if mesh then mesh.Scale = Vector3.new(0.5, 0.5, 0.5) end
end)
RegisterCommand("Reset Head Scale", "Character/UI", "Character/UI", "Restore normal 1.0x head mesh scale", true, function()
    local char = GetCharacter()
    local head = char and char:FindFirstChild("Head")
    local mesh = head and head:FindFirstChildOfClass("SpecialMesh")
    if mesh then mesh.Scale = Vector3.new(1.25, 1.25, 1.25) end
end)
RegisterCommand("Cyber Halo Crown ON", "Character/UI", "Character/UI", "Equip glowing floating neon halo ring above head", true, function()
    local char = GetCharacter()
    local head = char and char:FindFirstChild("Head")
    if not head or char:FindFirstChild("ChelseaaHaloCrown") then return end
    local halo = Instance.new("Part")
    halo.Name = "ChelseaaHaloCrown"
    halo.Shape = Enum.PartType.Cylinder
    halo.Size = Vector3.new(0.18, 2.1, 2.1)
    halo.Material = Enum.Material.Neon
    halo.Color = Color3.fromRGB(56, 189, 248)
    halo.CanCollide = false
    halo.Massless = true
    halo.CFrame = head.CFrame * CFrame.new(0, 1.25, 0) * CFrame.Angles(0, 0, math.rad(90))
    halo.Parent = char
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = head
    weld.Part1 = halo
    weld.Parent = halo
end)
RegisterCommand("Cyber Halo Crown OFF", "Character/UI", "Character/UI", "Remove floating neon halo ring", true, function()
    local char = GetCharacter()
    local halo = char and char:FindFirstChild("ChelseaaHaloCrown")
    if halo then halo:Destroy() end
end)
RegisterCommand("Anti-Ragdoll Lock ON", "Character/UI", "Character/UI", "Prevent falling down / ragdoll states", true, function()
    State.AntiRagdoll = true
end)
RegisterCommand("Anti-Ragdoll Lock OFF", "Character/UI", "Character/UI", "Disable Anti-Ragdoll lock", true, function()
    State.AntiRagdoll = false
end)
RegisterCommand("Sit Character", "Character/UI", "Character/UI", "Force local character to sit", true, function()
    local hum = GetHumanoid()
    if hum then hum.Sit = true end
end)
RegisterCommand("Stand Up Character", "Character/UI", "Character/UI", "Stand up from seated state", true, function()
    local hum = GetHumanoid()
    if hum then hum.Sit = false end
end)
RegisterCommand("HipHeight Float (+5)", "Character/UI", "Character/UI", "Hover 5 studs above ground via HipHeight", true, function()
    local hum = GetHumanoid()
    if hum then hum.HipHeight = 5 end
end)
RegisterCommand("HipHeight Reset (0)", "Character/UI", "Character/UI", "Reset character HipHeight to default", true, function()
    local hum = GetHumanoid()
    if hum then hum.HipHeight = 0 end
end)
RegisterCommand("Remove Accessories (Clean)", "Character/UI", "Character/UI", "Strip hats/accessories locally for clean hitbox view", true, function()
    local char = GetCharacter()
    if char then
        for _, acc in ipairs(char:GetChildren()) do
            if acc:IsA("Accessory") then acc:Destroy() end
        end
    end
end)
RegisterCommand("Client Ghost Invisibility", "Character/UI", "Character/UI", "Make character semi-invisible locally (0.75)", true, function()
    local char = GetCharacter()
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                p.Transparency = 0.75
            end
        end
    end
end)
RegisterCommand("Restore Character Visibility", "Character/UI", "Character/UI", "Restore full opacity to character parts", true, function()
    local char = GetCharacter()
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                p.Transparency = 0
            end
        end
    end
end)
RegisterCommand("Reset All Character FX", "Character/UI", "Character/UI", "Clear all local auras, trails, halo, Headless & Korblox FX", true, function()
    ApplyClientHeadless(false)
    ApplyClientHeadlessHorseman(false)
    ApplyClientKorblox(false)
    State.RainbowChar = false
    local char = GetCharacter()
    local root = GetRootPart()
    if char then
        local halo = char:FindFirstChild("ChelseaaHaloCrown")
        if halo then halo:Destroy() end
    end
    if root then
        for _, fxName in ipairs({ "ChelseaaFireAura", "ChelseaaSparklesAura", "ChelseaaSmokeAura", "ChelseaaTrail", "ChelseaaLantern" }) do
            local fx = root:FindFirstChild(fxName)
            if fx then fx:Destroy() end
        end
    end
end)
RegisterCommand("Reset Character", "Character/UI", "Character/UI", "Respawn local character cleanly", true, function()
    local hum = GetHumanoid()
    if hum then hum.Health = 0 end
end)
RegisterCommand("UI Wallpaper: Show / Hide", "Character/UI", "Character/UI", "Toggle custom background wallpaper image inside UI", true, function()
    State.MenuWallpaperVisible = not State.MenuWallpaperVisible
    ToggleMenuWallpaper(State.MenuWallpaperVisible)
end)
RegisterCommand("UI Wallpaper: Bright (Clear)", "Character/UI", "Character/UI", "Make UI background image brighter and clearer", true, function()
    SetWallpaperTransparency(0.25)
end)
RegisterCommand("UI Wallpaper: Subtle (Dark)", "Character/UI", "Character/UI", "Make UI background image darker for crisp text", true, function()
    SetWallpaperTransparency(0.55)
end)
RegisterCommand("Center UI Window", "Character/UI", "Character/UI", "Reset main window position to center of screen", true, function()
    CenterMainWindow()
end)
RegisterCommand("Hide Roblox PlayerList", "Character/UI", "Character/UI", "Hide top-right Roblox leaderboard UI", true, function()
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false) end)
end)
RegisterCommand("Show Roblox PlayerList", "Character/UI", "Character/UI", "Restore top-right Roblox leaderboard UI", true, function()
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true) end)
end)
RegisterCommand("UI Theme: Cyber Crimson", "Character/UI", "Character/UI", "Switch UI accent to Obsidian Cyber Crimson", true, function()
    ApplyUITheme("CRIMSON")
end)
RegisterCommand("UI Theme: Electric Cyan", "Character/UI", "Character/UI", "Switch UI accent to Neon Electric Cyan", true, function()
    ApplyUITheme("CYAN")
end)
RegisterCommand("UI Theme: Emerald Matrix", "Character/UI", "Character/UI", "Switch UI accent to Emerald Matrix Green", true, function()
    ApplyUITheme("EMERALD")
end)
RegisterCommand("UI Theme: Royal Violet", "Character/UI", "Character/UI", "Switch UI accent to Cyber Royal Violet", true, function()
    ApplyUITheme("VIOLET")
end)
RegisterCommand("UI Theme: Pure Monochrome", "Character/UI", "Character/UI", "Switch UI accent to Sleek Silver Monochrome", true, function()
    ApplyUITheme("MONO")
end)

-- 7. Core Movement Toggles (10 Features - Speed values are configured in Tab 1!)
RegisterCommand("WalkSpeed Anti-Reset Lock ON", "Movement", "Movement", "Lock WalkSpeed permanently against game resets", false, function()
    State.WalkSpeedLocked = true
end)
RegisterCommand("WalkSpeed Anti-Reset Lock OFF", "Movement", "Movement", "Unlock WalkSpeed anti-reset protection", false, function()
    State.WalkSpeedLocked = false
end)
RegisterCommand("JumpPower Lock ON", "Movement", "Movement", "Lock JumpPower permanently against resets", false, function()
    State.JumpPowerLocked = true
end)
RegisterCommand("JumpPower Lock OFF", "Movement", "Movement", "Unlock JumpPower protection", false, function()
    State.JumpPowerLocked = false
end)
RegisterCommand("Infinite Jump ON", "Movement", "Movement", "Allow unlimited mid-air jumps", false, function()
    State.InfiniteJump = true
end)
RegisterCommand("Infinite Jump OFF", "Movement", "Movement", "Disable Infinite Jump", false, function()
    State.InfiniteJump = false
end)
RegisterCommand("Noclip Walk-Through ON", "Movement", "Movement", "Walk seamlessly through walls and doors", false, function()
    State.Noclip = true
end)
RegisterCommand("Noclip Walk-Through OFF", "Movement", "Movement", "Restore solid wall collision", false, function()
    State.Noclip = false
end)
RegisterCommand("Smooth Flight Mode ON", "Movement", "Movement", "Enable directional camera flight (speed set in Tab 1)", false, function()
    State.Fly = true
end)
RegisterCommand("Smooth Flight Mode OFF", "Movement", "Movement", "Disable Smooth Flight mode", false, function()
    State.Fly = false
end)

--// =========================================================================
--// RUNTIME LOOPS
--// =========================================================================
local AirPlatformPart = nil
local RainbowHue = 0
local LastPromptTick = 0
local LastTouchTick = 0

TrackConn(RunService.Heartbeat:Connect(function(dt)
    local char = GetCharacter()
    local hum = GetHumanoid()
    local root = GetRootPart()

    if hum then
        if State.WalkSpeedLocked and hum.WalkSpeed ~= State.WalkSpeed then
            hum.WalkSpeed = State.WalkSpeed
        end
        if State.JumpPowerLocked then
            hum.UseJumpPower = true
            if hum.JumpPower ~= State.JumpPower then
                hum.JumpPower = State.JumpPower
            end
        end
        if State.BunnyHop and hum.MoveDirection.Magnitude > 0 and hum.FloorMaterial ~= Enum.Material.Air then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        if State.SwimAir then
            hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
            hum:ChangeState(Enum.HumanoidStateType.Swimming)
        end
        if State.AntiRagdoll then
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        end
        if State.AutoObstacleJump and root and hum.MoveDirection.Magnitude > 0 and hum.FloorMaterial ~= Enum.Material.Air then
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = { char }
            params.FilterType = Enum.RaycastFilterType.Exclude
            local wallHit = workspace:Raycast(root.Position - Vector3.new(0, 1.2, 0), hum.MoveDirection * 2.8, params)
            if wallHit then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end

    if State.Noclip and char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    if State.Fly and root and hum then
        local cam = workspace.CurrentCamera
        local moveDir = hum.MoveDirection
        if cam then
            local flyVel = Vector3.zero
            if moveDir.Magnitude > 0 then
                flyVel = cam.CFrame.LookVector * moveDir.Magnitude * State.FlySpeed
            end
            root.AssemblyLinearVelocity = flyVel
        end
    end

    if State.SpiderClimb and root and hum and hum.MoveDirection.Magnitude > 0 then
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = { char }
        params.FilterType = Enum.RaycastFilterType.Exclude
        local hit = workspace:Raycast(root.Position, hum.MoveDirection * 2.5, params)
        if hit then
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 34, root.AssemblyLinearVelocity.Z)
        end
    end

    if State.OrbitPlayer and root then
        local nearRoot = FindNearestPlayerRoot()
        if nearRoot then
            State.OrbitAngle = (State.OrbitAngle + dt * 3.2) % (math.pi * 2)
            local offset = Vector3.new(math.cos(State.OrbitAngle) * 7, 0, math.sin(State.OrbitAngle) * 7)
            local targetPos = nearRoot.Position + offset
            root.CFrame = CFrame.lookAt(targetPos, nearRoot.Position)
        end
    end

    if State.AutoStrafe and root then
        State.StrafeAngle = (State.StrafeAngle + dt * 4.5) % (math.pi * 2)
        root.CFrame = root.CFrame * CFrame.new(math.cos(State.StrafeAngle) * 0.45, 0, math.sin(State.StrafeAngle) * 0.45)
    end

    if State.FreeCamEnabled and State.FreeCamCFrame then
        local cam = workspace.CurrentCamera
        if cam then
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += State.FreeCamCFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= State.FreeCamCFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= State.FreeCamCFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += State.FreeCamCFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then move += Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then move -= Vector3.yAxis end
            if move.Magnitude > 0 then
                State.FreeCamCFrame = State.FreeCamCFrame + (move.Unit * (State.FlySpeed * dt))
            end
            cam.CFrame = State.FreeCamCFrame
        end
    end

    if State.SpinSpeed > 0 and root then
        root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(State.SpinSpeed), 0)
    end

    if State.AntiFling and root then
        if root.AssemblyLinearVelocity.Magnitude > 180 then
            root.AssemblyLinearVelocity = Vector3.zero
        end
        if root.AssemblyAngularVelocity.Magnitude > 50 then
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end

    if State.AirWalk and root then
        if not AirPlatformPart or not AirPlatformPart.Parent then
            AirPlatformPart = Instance.new("Part")
            AirPlatformPart.Name = "ChelseaaAirWalk"
            AirPlatformPart.Size = Vector3.new(12, 1, 12)
            AirPlatformPart.Anchored = true
            AirPlatformPart.Transparency = 1
            AirPlatformPart.Parent = workspace
        end
        AirPlatformPart.CFrame = CFrame.new(root.Position.X, root.Position.Y - 3.5, root.Position.Z)
    elseif AirPlatformPart then
        AirPlatformPart:Destroy()
        AirPlatformPart = nil
    end

    if State.RainbowChar and char then
        RainbowHue = (RainbowHue + dt * 0.35) % 1
        local col = Color3.fromHSV(RainbowHue, 0.85, 1)
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                p.Color = col
            end
        end
    end

    if State.AutoTrainEnabled then
        ProcessAutoTrainCursor()
    end

    if State.AutoClickerCenter then
        local cam = workspace.CurrentCamera
        if cam then
            local vp = cam.ViewportSize
            PerformCursorClickAt(vp.X * 0.5, vp.Y * 0.5, nil)
        end
    end

    if State.AutoPrompts and root and (os.clock() - LastPromptTick) > 0.25 then
        LastPromptTick = os.clock()
        if type(fireproximityprompt) == "function" then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") and obj.Enabled then
                    local parentPart = obj.Parent and (obj.Parent:IsA("BasePart") and obj.Parent or obj.Parent:FindFirstChildWhichIsA("BasePart"))
                    if parentPart and (parentPart.Position - root.Position).Magnitude <= (obj.MaxActivationDistance + 8) then
                        pcall(fireproximityprompt, obj)
                    end
                end
            end
        end
    end

    if State.AutoCollectTouch and root and (os.clock() - LastTouchTick) > 0.3 then
        LastTouchTick = os.clock()
        if type(firetouchinterest) == "function" then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("TouchTransmitter") and obj.Parent and obj.Parent:IsA("BasePart") then
                    if (obj.Parent.Position - root.Position).Magnitude <= 35 then
                        pcall(firetouchinterest, root, obj.Parent, 0)
                        pcall(firetouchinterest, root, obj.Parent, 1)
                    end
                end
            end
        end
    end
end))

TrackConn(RunService.Stepped:Connect(function()
    if State.ClientHeadlessHorseman then
        local char = GetCharacter()
        if char then
            UpdateHorsemanArmPose(char)
        end
    end
end))

TrackConn(UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump then
        local hum = GetHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))

local function BindCharacterEvents(char)
    local hum = char:WaitForChild("Humanoid", 5)
    local root = char:WaitForChild("HumanoidRootPart", 5)
    if hum then
        if State.WalkSpeedLocked then hum.WalkSpeed = State.WalkSpeed end
        if State.JumpPowerLocked then
            hum.UseJumpPower = true
            hum.JumpPower = State.JumpPower
        end
        hum.Died:Connect(function()
            if root then
                State.LastDeathCFrame = root.CFrame
            end
        end)
    end
    if State.AutoRespawnSpot and State.LastDeathCFrame and root then
        task.wait(0.2)
        root.CFrame = State.LastDeathCFrame
    end
    task.defer(function()
        task.wait(0.15)
        if State.ClientHeadless then ApplyClientHeadless(true) end
        if State.ClientHeadlessHorseman then ApplyClientHeadlessHorseman(true) end
        if State.ClientKorblox then ApplyClientKorblox(true) end
    end)
end

if LocalPlayer.Character then
    task.spawn(BindCharacterEvents, LocalPlayer.Character)
end
TrackConn(LocalPlayer.CharacterAdded:Connect(BindCharacterEvents))

--// =========================================================================
--// OBSIDIAN CYBER-ANIME RICH TABBED GUI
--// =========================================================================
local Themes = {
    CRIMSON = {
        Accent = Color3.fromRGB(220, 38, 68),
        AccentSoft = Color3.fromRGB(48, 20, 28),
        Secondary = Color3.fromRGB(56, 189, 248),
    },
    CYAN = {
        Accent = Color3.fromRGB(14, 165, 233),
        AccentSoft = Color3.fromRGB(18, 42, 58),
        Secondary = Color3.fromRGB(244, 63, 94),
    },
    EMERALD = {
        Accent = Color3.fromRGB(16, 185, 129),
        AccentSoft = Color3.fromRGB(18, 48, 38),
        Secondary = Color3.fromRGB(56, 189, 248),
    },
    VIOLET = {
        Accent = Color3.fromRGB(168, 85, 247),
        AccentSoft = Color3.fromRGB(42, 24, 62),
        Secondary = Color3.fromRGB(236, 72, 153),
    },
    MONO = {
        Accent = Color3.fromRGB(228, 228, 235),
        AccentSoft = Color3.fromRGB(38, 38, 46),
        Secondary = Color3.fromRGB(161, 161, 170),
    },
}

local Palette = {
    BgMain     = Color3.fromRGB(10, 10, 14),
    BgPanel    = Color3.fromRGB(17, 17, 23),
    BgCard     = Color3.fromRGB(24, 24, 33),
    BgInput    = Color3.fromRGB(14, 14, 20),
    Stroke     = Color3.fromRGB(50, 52, 68),
    Accent     = Themes.CRIMSON.Accent,
    AccentSoft = Themes.CRIMSON.AccentSoft,
    Cyan       = Themes.CRIMSON.Secondary,
    Green      = Color3.fromRGB(34, 197, 94),
    TextMain   = Color3.fromRGB(244, 244, 248),
    TextMuted  = Color3.fromRGB(154, 158, 176),
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ChelseaaSystemV10"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = GuiParent

local function AddCorner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = obj
    return c
end

local function AddStroke(obj, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Palette.Stroke
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
    return s
end

-- Floating Minimize Bubble
local ToggleBubble = Instance.new("TextButton")
ToggleBubble.Name = "ToggleBubble"
ToggleBubble.Size = UDim2.new(0, 50, 0, 50)
ToggleBubble.Position = UDim2.new(0, 16, 0.5, -25)
ToggleBubble.BackgroundColor3 = Palette.BgMain
ToggleBubble.Text = "CS"
ToggleBubble.Font = Enum.Font.GothamBlack
ToggleBubble.TextSize = 15
ToggleBubble.TextColor3 = Palette.Accent
ToggleBubble.Visible = false
ToggleBubble.Parent = ScreenGui
AddCorner(ToggleBubble, 25)
local BubbleStroke = AddStroke(ToggleBubble, Palette.Accent, 1.6)

local BubbleImage = Instance.new("ImageLabel")
BubbleImage.Name = "BubbleImage"
BubbleImage.Size = UDim2.new(1, 0, 1, 0)
BubbleImage.BackgroundTransparency = 1
BubbleImage.Image = ""
BubbleImage.ScaleType = Enum.ScaleType.Crop
BubbleImage.Parent = ToggleBubble
AddCorner(BubbleImage, 25)

-- Main Window
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 560, 0, 395)
MainFrame.Position = UDim2.new(0.5, -280, 0.5, -197)
MainFrame.BackgroundColor3 = Palette.BgMain
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
AddCorner(MainFrame, 12)
local MainStroke = AddStroke(MainFrame, Palette.Stroke, 1.3)

local MenuWallpaper = Instance.new("ImageLabel")
MenuWallpaper.Name = "MenuWallpaper"
MenuWallpaper.Size = UDim2.new(1, 0, 1, 0)
MenuWallpaper.Position = UDim2.new(0, 0, 0, 0)
MenuWallpaper.BackgroundTransparency = 1
MenuWallpaper.Image = ""
MenuWallpaper.ImageTransparency = 0.45
MenuWallpaper.ScaleType = Enum.ScaleType.Crop
MenuWallpaper.ZIndex = 0
MenuWallpaper.Parent = MainFrame
AddCorner(MenuWallpaper, 12)

-- Top Header Bar
local Topbar = Instance.new("Frame")
Topbar.Name = "Topbar"
Topbar.Size = UDim2.new(1, 0, 0, 42)
Topbar.BackgroundColor3 = Palette.BgPanel
Topbar.BackgroundTransparency = 0.15
Topbar.Parent = MainFrame
AddCorner(Topbar, 12)

local BrandBadge = Instance.new("TextLabel")
BrandBadge.Size = UDim2.new(0, 36, 0, 24)
BrandBadge.Position = UDim2.new(0, 10, 0.5, -12)
BrandBadge.BackgroundColor3 = Palette.Accent
BrandBadge.Text = "V10"
BrandBadge.Font = Enum.Font.GothamBlack
BrandBadge.TextSize = 11
BrandBadge.TextColor3 = Palette.BgMain
BrandBadge.Parent = Topbar
AddCorner(BrandBadge, 6)

local HeaderAvatar = Instance.new("ImageLabel")
HeaderAvatar.Name = "HeaderAvatar"
HeaderAvatar.Size = UDim2.new(0, 28, 0, 28)
HeaderAvatar.Position = UDim2.new(0, 52, 0.5, -14)
HeaderAvatar.BackgroundColor3 = Palette.BgCard
HeaderAvatar.Image = ""
HeaderAvatar.ScaleType = Enum.ScaleType.Crop
HeaderAvatar.Parent = Topbar
AddCorner(HeaderAvatar, 6)
AddStroke(HeaderAvatar, Palette.Accent, 1)

task.spawn(function()
    local customAsset = LoadCustomMenuImage(State.CustomMenuImageUrl, "chelseaa_v10_5kbgpx.jpg")
    if customAsset ~= "" then
        MenuWallpaper.Image = customAsset
        HeaderAvatar.Image = customAsset
        BubbleImage.Image = customAsset
        ToggleBubble.Text = ""
    end
end)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -168, 1, 0)
TitleLabel.Position = UDim2.new(0, 88, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "CHELSEAA SYSTEM  |  190 REAL FEATURES HUB"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 13
TitleLabel.TextColor3 = Palette.TextMain
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Topbar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 26)
MinBtn.Position = UDim2.new(1, -66, 0.5, -13)
MinBtn.BackgroundColor3 = Palette.BgCard
MinBtn.Text = "-"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16
MinBtn.TextColor3 = Palette.TextMain
MinBtn.Parent = Topbar
AddCorner(MinBtn, 6)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 26)
CloseBtn.Position = UDim2.new(1, -34, 0.5, -13)
CloseBtn.BackgroundColor3 = Palette.AccentSoft
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.TextColor3 = Palette.Accent
CloseBtn.Parent = Topbar
AddCorner(CloseBtn, 6)

MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    ToggleBubble.Visible = true
end)

ToggleBubble.MouseButton1Click:Connect(function()
    ToggleBubble.Visible = false
    MainFrame.Visible = true
end)

CloseBtn.MouseButton1Click:Connect(function()
    State.AutoTrainEnabled = false
    State.WalkSpeedLocked = false
    State.AutoClickerCenter = false
    State.AutoPrompts = false
    State.AutoCollectTouch = false
    State.SpinSpeed = 0
    State.OrbitPlayer = false
    State.FreeCamEnabled = false
    StopActiveTween()
    ClearAllSpawnedObjects()
    if AirPlatformPart then AirPlatformPart:Destroy() end
    for _, c in ipairs(ActiveConnections) do
        pcall(function() c:Disconnect() end)
    end
    ScreenGui:Destroy()
end)

-- Drag Support (Touch & Mouse)
local function EnableDrag(handle, target)
    local dragging = false
    local dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    TrackConn(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end))
end

EnableDrag(Topbar, MainFrame)
EnableDrag(ToggleBubble, ToggleBubble)

-- 5 Rich Category Navigation Tabs
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -20, 0, 34)
TabBar.Position = UDim2.new(0, 10, 0, 48)
TabBar.BackgroundColor3 = Palette.BgPanel
TabBar.BackgroundTransparency = 0.15
TabBar.Parent = MainFrame
AddCorner(TabBar, 8)
AddStroke(TabBar, Palette.Stroke, 1)

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 4)
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabLayout.Parent = TabBar

local PagesContainer = Instance.new("Frame")
PagesContainer.Size = UDim2.new(1, -20, 1, -124)
PagesContainer.Position = UDim2.new(0, 10, 0, 88)
PagesContainer.BackgroundTransparency = 1
PagesContainer.Parent = MainFrame

local FooterBar = Instance.new("Frame")
FooterBar.Size = UDim2.new(1, -20, 0, 26)
FooterBar.Position = UDim2.new(0, 10, 1, -32)
FooterBar.BackgroundColor3 = Palette.BgPanel
FooterBar.BackgroundTransparency = 0.15
FooterBar.Parent = MainFrame
AddCorner(FooterBar, 7)
AddStroke(FooterBar, Palette.Stroke, 1)

local TelemetryLabel = Instance.new("TextLabel")
TelemetryLabel.Size = UDim2.new(1, -16, 1, 0)
TelemetryLabel.Position = UDim2.new(0, 10, 0, 0)
TelemetryLabel.BackgroundTransparency = 1
TelemetryLabel.Text = "MADE BY CHELSEAA  |  190 Real Features Active"
TelemetryLabel.Font = Enum.Font.GothamBold
TelemetryLabel.TextSize = 10
TelemetryLabel.TextColor3 = Palette.Cyan
TelemetryLabel.TextXAlignment = Enum.TextXAlignment.Left
TelemetryLabel.Parent = FooterBar

-- Tab Builder
local Tabs = {}
local Pages = {}
local ActiveTabName = "Movement"

local function CreatePage(name, labelText)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.192, 0, 0, 25)
    btn.BackgroundColor3 = Palette.BgCard
    btn.Text = labelText
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.TextColor3 = Palette.TextMuted
    btn.Parent = TabBar
    AddCorner(btn, 6)

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Palette.Accent
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = PagesContainer

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    Tabs[name] = btn
    Pages[name] = page

    btn.MouseButton1Click:Connect(function()
        ActiveTabName = name
        for k, p in pairs(Pages) do
            p.Visible = (k == name)
            Tabs[k].BackgroundColor3 = (k == name) and Palette.Accent or Palette.BgCard
            Tabs[k].TextColor3 = (k == name) and (Palette.Accent == Themes.MONO.Accent and Palette.BgMain or Palette.TextMain) or Palette.TextMuted
        end
    end)

    return page
end

local PageMove   = CreatePage("Movement", "Speed & Tween")
local PageTrain  = CreatePage("Train",    "Auto Train")
local PageVisual = CreatePage("Visual",   "Visual & World")
local PageNew100 = CreatePage("New100",   "Featured FX")
local PageAll    = CreatePage("All5100",  "All 190")

Pages["Movement"].Visible = true
Tabs["Movement"].BackgroundColor3 = Palette.Accent
Tabs["Movement"].TextColor3 = Palette.TextMain

ApplyUITheme = function(themeKey)
    local th = Themes[themeKey] or Themes.CRIMSON
    Palette.Accent = th.Accent
    Palette.AccentSoft = th.AccentSoft
    Palette.Cyan = th.Secondary
    BrandBadge.BackgroundColor3 = th.Accent
    ToggleBubble.TextColor3 = th.Accent
    BubbleStroke.Color = th.Accent
    CloseBtn.BackgroundColor3 = th.AccentSoft
    CloseBtn.TextColor3 = th.Accent
    TelemetryLabel.TextColor3 = th.Secondary
    for k, btn in pairs(Tabs) do
        btn.BackgroundColor3 = (k == ActiveTabName) and th.Accent or Palette.BgCard
        btn.TextColor3 = (k == ActiveTabName) and (themeKey == "MONO" and Palette.BgMain or Palette.TextMain) or Palette.TextMuted
    end
end

ToggleMenuWallpaper = function(vis)
    MenuWallpaper.Visible = vis
end

SetWallpaperTransparency = function(alpha)
    MenuWallpaper.Visible = true
    MenuWallpaper.ImageTransparency = alpha
end

CenterMainWindow = function()
    MainFrame.Position = UDim2.new(0.5, -280, 0.5, -197)
end

-- Widget Helpers
local function CreateCard(parent, titleText, height)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -6, 0, height)
    card.BackgroundColor3 = Palette.BgPanel
    card.BackgroundTransparency = 0.18
    card.Parent = parent
    AddCorner(card, 8)
    AddStroke(card, Palette.Stroke, 1)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -16, 0, 22)
    title.Position = UDim2.new(0, 10, 0, 6)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.Font = Enum.Font.GothamBold
    title.TextSize = 11
    title.TextColor3 = Palette.TextMain
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = card

    return card
end

local function CreateToggleButton(parent, pos, size, text, initialState, onToggle)
    local btn = Instance.new("TextButton")
    btn.Position = pos
    btn.Size = size
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.Parent = parent
    AddCorner(btn, 6)

    local stateVal = initialState
    local function Refresh()
        btn.BackgroundColor3 = stateVal and Palette.Green or Palette.BgCard
        btn.TextColor3 = stateVal and Palette.BgMain or Palette.TextMain
        btn.Text = text .. (stateVal and ": ON" or ": OFF")
    end
    Refresh()

    btn.MouseButton1Click:Connect(function()
        stateVal = not stateVal
        Refresh()
        onToggle(stateVal)
    end)

    return btn
end

--// =========================================================================
--// TAB 1: ADJUSTABLE SPEED SETTINGS (WALKSPEED, FLY SPEED, JUMPPOWER & TWEEN)
--// =========================================================================
local WsCard = CreateCard(PageMove, "MOVEMENT & SPEED SETTINGS (WALKSPEED, FLY SPEED & JUMPPOWER)", 148)

local WsInput = Instance.new("TextBox")
WsInput.Size = UDim2.new(0, 88, 0, 28)
WsInput.Position = UDim2.new(0, 10, 0, 32)
WsInput.BackgroundColor3 = Palette.BgInput
WsInput.Text = tostring(State.WalkSpeed)
WsInput.PlaceholderText = "WalkSpeed"
WsInput.Font = Enum.Font.GothamBold
WsInput.TextSize = 12
WsInput.TextColor3 = Palette.Cyan
WsInput.Parent = WsCard
AddCorner(WsInput, 6)
AddStroke(WsInput, Palette.Stroke, 1)

local ApplyWsBtn = Instance.new("TextButton")
ApplyWsBtn.Size = UDim2.new(0, 72, 0, 28)
ApplyWsBtn.Position = UDim2.new(0, 104, 0, 32)
ApplyWsBtn.BackgroundColor3 = Palette.Accent
ApplyWsBtn.Text = "SET WS"
ApplyWsBtn.Font = Enum.Font.GothamBold
ApplyWsBtn.TextSize = 10
ApplyWsBtn.TextColor3 = Palette.TextMain
ApplyWsBtn.Parent = WsCard
AddCorner(ApplyWsBtn, 6)

CreateToggleButton(WsCard, UDim2.new(0, 182, 0, 32), UDim2.new(0, 110, 0, 28), "WS Lock", State.WalkSpeedLocked, function(v)
    State.WalkSpeedLocked = v
end)

CreateToggleButton(WsCard, UDim2.new(0, 298, 0, 32), UDim2.new(0, 108, 0, 28), "Noclip", State.Noclip, function(v)
    State.Noclip = v
end)

CreateToggleButton(WsCard, UDim2.new(0, 412, 0, 32), UDim2.new(0, 112, 0, 28), "Inf Jump", State.InfiniteJump, function(v)
    State.InfiniteJump = v
end)

ApplyWsBtn.MouseButton1Click:Connect(function()
    local num = tonumber(WsInput.Text)
    if num then
        num = math.clamp(num, 1, 5000)
        State.WalkSpeed = num
        State.WalkSpeedLocked = true
        WsInput.Text = tostring(num)
        local hum = GetHumanoid()
        if hum then hum.WalkSpeed = num end
        SetStatus("WalkSpeed setting updated to " .. num)
    end
end)

-- Fly Speed & JumpPower Settings Row
local FlyInput = Instance.new("TextBox")
FlyInput.Size = UDim2.new(0, 88, 0, 28)
FlyInput.Position = UDim2.new(0, 10, 0, 68)
FlyInput.BackgroundColor3 = Palette.BgInput
FlyInput.Text = tostring(State.FlySpeed)
FlyInput.PlaceholderText = "Fly Speed"
FlyInput.Font = Enum.Font.GothamBold
FlyInput.TextSize = 12
FlyInput.TextColor3 = Palette.Cyan
FlyInput.Parent = WsCard
AddCorner(FlyInput, 6)
AddStroke(FlyInput, Palette.Stroke, 1)

local ApplyFlyBtn = Instance.new("TextButton")
ApplyFlyBtn.Size = UDim2.new(0, 72, 0, 28)
ApplyFlyBtn.Position = UDim2.new(0, 104, 0, 68)
ApplyFlyBtn.BackgroundColor3 = Palette.Accent
ApplyFlyBtn.Text = "SET FLY"
ApplyFlyBtn.Font = Enum.Font.GothamBold
ApplyFlyBtn.TextSize = 10
ApplyFlyBtn.TextColor3 = Palette.TextMain
ApplyFlyBtn.Parent = WsCard
AddCorner(ApplyFlyBtn, 6)

ApplyFlyBtn.MouseButton1Click:Connect(function()
    local num = tonumber(FlyInput.Text)
    if num then
        State.FlySpeed = math.clamp(num, 5, 5000)
        FlyInput.Text = tostring(State.FlySpeed)
        SetStatus("Fly Speed setting updated to " .. State.FlySpeed)
    end
end)

local JpInput = Instance.new("TextBox")
JpInput.Size = UDim2.new(0, 88, 0, 28)
JpInput.Position = UDim2.new(0, 182, 0, 68)
JpInput.BackgroundColor3 = Palette.BgInput
JpInput.Text = tostring(State.JumpPower)
JpInput.PlaceholderText = "JumpPower"
JpInput.Font = Enum.Font.GothamBold
JpInput.TextSize = 12
JpInput.TextColor3 = Palette.Cyan
JpInput.Parent = WsCard
AddCorner(JpInput, 6)
AddStroke(JpInput, Palette.Stroke, 1)

local ApplyJpBtn = Instance.new("TextButton")
ApplyJpBtn.Size = UDim2.new(0, 72, 0, 28)
ApplyJpBtn.Position = UDim2.new(0, 276, 0, 68)
ApplyJpBtn.BackgroundColor3 = Palette.Accent
ApplyJpBtn.Text = "SET JP"
ApplyJpBtn.Font = Enum.Font.GothamBold
ApplyJpBtn.TextSize = 10
ApplyJpBtn.TextColor3 = Palette.TextMain
ApplyJpBtn.Parent = WsCard
AddCorner(ApplyJpBtn, 6)

ApplyJpBtn.MouseButton1Click:Connect(function()
    local num = tonumber(JpInput.Text)
    if num then
        State.JumpPower = math.clamp(num, 10, 5000)
        State.JumpPowerLocked = true
        JpInput.Text = tostring(State.JumpPower)
        local hum = GetHumanoid()
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = State.JumpPower
        end
        SetStatus("JumpPower setting updated to " .. State.JumpPower)
    end
end)

CreateToggleButton(WsCard, UDim2.new(0, 354, 0, 68), UDim2.new(0, 170, 0, 28), "Orbit Nearest", State.OrbitPlayer, function(v)
    State.OrbitPlayer = v
end)

CreateToggleButton(WsCard, UDim2.new(0, 10, 0, 106), UDim2.new(0, 122, 0, 28), "Smooth Fly", State.Fly, function(v)
    State.Fly = v
end)
CreateToggleButton(WsCard, UDim2.new(0, 138, 0, 106), UDim2.new(0, 124, 0, 28), "Air Walk", State.AirWalk, function(v)
    State.AirWalk = v
end)
CreateToggleButton(WsCard, UDim2.new(0, 268, 0, 106), UDim2.new(0, 124, 0, 28), "Anti-Fling", State.AntiFling, function(v)
    State.AntiFling = v
end)
CreateToggleButton(WsCard, UDim2.new(0, 398, 0, 106), UDim2.new(0, 126, 0, 28), "Spider Climb", State.SpiderClimb, function(v)
    State.SpiderClimb = v
end)

-- Dynamic Tween Speed & Waypoint Slots Card
local TwCard = CreateCard(PageMove, "TWEEN SPEED SETTING & WAYPOINT NAVIGATION", 114)

local TwInput = Instance.new("TextBox")
TwInput.Size = UDim2.new(0, 88, 0, 28)
TwInput.Position = UDim2.new(0, 10, 0, 32)
TwInput.BackgroundColor3 = Palette.BgInput
TwInput.Text = tostring(State.TweenSpeed)
TwInput.PlaceholderText = "Tween Spd"
TwInput.Font = Enum.Font.GothamBold
TwInput.TextSize = 12
TwInput.TextColor3 = Palette.Cyan
TwInput.Parent = TwCard
AddCorner(TwInput, 6)
AddStroke(TwInput, Palette.Stroke, 1)

local ApplyTwBtn = Instance.new("TextButton")
ApplyTwBtn.Size = UDim2.new(0, 86, 0, 28)
ApplyTwBtn.Position = UDim2.new(0, 104, 0, 32)
ApplyTwBtn.BackgroundColor3 = Palette.Accent
ApplyTwBtn.Text = "SET TWEEN"
ApplyTwBtn.Font = Enum.Font.GothamBold
ApplyTwBtn.TextSize = 10
ApplyTwBtn.TextColor3 = Palette.TextMain
ApplyTwBtn.Parent = TwCard
AddCorner(ApplyTwBtn, 6)

CreateToggleButton(TwCard, UDim2.new(0, 196, 0, 32), UDim2.new(0, 154, 0, 28), "Sync = 2x WS", State.SyncTweenToWalkSpeed, function(v)
    State.SyncTweenToWalkSpeed = v
end)

local StopTwBtn = Instance.new("TextButton")
StopTwBtn.Size = UDim2.new(0, 168, 0, 28)
StopTwBtn.Position = UDim2.new(0, 356, 0, 32)
StopTwBtn.BackgroundColor3 = Palette.AccentSoft
StopTwBtn.Text = "STOP ACTIVE TWEEN"
StopTwBtn.Font = Enum.Font.GothamBold
StopTwBtn.TextSize = 10
StopTwBtn.TextColor3 = Palette.Accent
StopTwBtn.Parent = TwCard
AddCorner(StopTwBtn, 6)

ApplyTwBtn.MouseButton1Click:Connect(function()
    local num = tonumber(TwInput.Text)
    if num then
        State.TweenSpeed = math.clamp(num, 10, 15000)
        State.SyncTweenToWalkSpeed = false
        TwInput.Text = tostring(State.TweenSpeed)
        SetStatus("Tween Speed setting updated to " .. State.TweenSpeed .. " studs/sec")
    end
end)

StopTwBtn.MouseButton1Click:Connect(function()
    StopActiveTween()
    SetStatus("Tween movement cancelled")
end)

local SaveWp1 = Instance.new("TextButton")
SaveWp1.Size = UDim2.new(0, 122, 0, 28)
SaveWp1.Position = UDim2.new(0, 10, 0, 70)
SaveWp1.BackgroundColor3 = Palette.BgCard
SaveWp1.Text = "Save Slot 1"
SaveWp1.Font = Enum.Font.GothamBold
SaveWp1.TextSize = 10
SaveWp1.TextColor3 = Palette.TextMain
SaveWp1.Parent = TwCard
AddCorner(SaveWp1, 6)

local GoWp1 = Instance.new("TextButton")
GoWp1.Size = UDim2.new(0, 124, 0, 28)
GoWp1.Position = UDim2.new(0, 138, 0, 70)
GoWp1.BackgroundColor3 = Palette.BgCard
GoWp1.Text = "Tween Slot 1"
GoWp1.Font = Enum.Font.GothamBold
GoWp1.TextSize = 10
GoWp1.TextColor3 = Palette.Cyan
GoWp1.Parent = TwCard
AddCorner(GoWp1, 6)

local TweenUpBtn = Instance.new("TextButton")
TweenUpBtn.Size = UDim2.new(0, 124, 0, 28)
TweenUpBtn.Position = UDim2.new(0, 268, 0, 70)
TweenUpBtn.BackgroundColor3 = Palette.BgCard
TweenUpBtn.Text = "Tween Sky +500"
TweenUpBtn.Font = Enum.Font.GothamBold
TweenUpBtn.TextSize = 10
TweenUpBtn.TextColor3 = Palette.TextMain
TweenUpBtn.Parent = TwCard
AddCorner(TweenUpBtn, 6)

local TweenNearBtn = Instance.new("TextButton")
TweenNearBtn.Size = UDim2.new(0, 126, 0, 28)
TweenNearBtn.Position = UDim2.new(0, 398, 0, 70)
TweenNearBtn.BackgroundColor3 = Palette.BgCard
TweenNearBtn.Text = "Tween Nearest"
TweenNearBtn.Font = Enum.Font.GothamBold
TweenNearBtn.TextSize = 10
TweenNearBtn.TextColor3 = Palette.TextMain
TweenNearBtn.Parent = TwCard
AddCorner(TweenNearBtn, 6)

SaveWp1.MouseButton1Click:Connect(function()
    local root = GetRootPart()
    if root then
        State.Waypoints[1] = root.CFrame
        SetStatus("Saved Waypoint Slot 1")
    end
end)
GoWp1.MouseButton1Click:Connect(function()
    if State.Waypoints[1] then TweenToCFrame(State.Waypoints[1]) end
end)
TweenUpBtn.MouseButton1Click:Connect(function()
    local root = GetRootPart()
    if root then TweenToCFrame(root.CFrame + Vector3.new(0, 500, 0)) end
end)
TweenNearBtn.MouseButton1Click:Connect(function()
    CommandLookup["tween to nearest player"].run()
end)

--// =========================================================================
--// TAB 2: AUTO TRAIN CURSOR (1x, 2x, 2.30x, 3x, 4x) & AUTOMATION
--// =========================================================================
local TrainCard = CreateCard(PageTrain, "AUTO TRAIN CURSOR PRECISION (1x / 2x / 2.30x / 3x / 4x)", 230)

local TrainStatusLabel = Instance.new("TextLabel")
TrainStatusLabel.Size = UDim2.new(1, -20, 0, 20)
TrainStatusLabel.Position = UDim2.new(0, 10, 0, 30)
TrainStatusLabel.BackgroundTransparency = 1
TrainStatusLabel.Text = "Cursor Status: IDLE  |  Last Hit: None  |  Clicks: 0"
TrainStatusLabel.Font = Enum.Font.GothamBold
TrainStatusLabel.TextSize = 11
TrainStatusLabel.TextColor3 = Palette.Cyan
TrainStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
TrainStatusLabel.Parent = TrainCard

CreateToggleButton(TrainCard, UDim2.new(0, 10, 0, 56), UDim2.new(0, 168, 0, 30), "Auto Train Cursor", State.AutoTrainEnabled, function(v)
    State.AutoTrainEnabled = v
end)

CreateToggleButton(TrainCard, UDim2.new(0, 184, 0, 56), UDim2.new(0, 168, 0, 30), "Center Clicker", State.AutoClickerCenter, function(v)
    State.AutoClickerCenter = v
end)

CreateToggleButton(TrainCard, UDim2.new(0, 358, 0, 56), UDim2.new(0, 166, 0, 30), "Auto Prompts", State.AutoPrompts, function(v)
    State.AutoPrompts = v
end)

local FilterLabel = Instance.new("TextLabel")
FilterLabel.Size = UDim2.new(1, -20, 0, 18)
FilterLabel.Position = UDim2.new(0, 10, 0, 96)
FilterLabel.BackgroundTransparency = 1
FilterLabel.Text = "Multiplier Target Filter:"
FilterLabel.Font = Enum.Font.GothamBold
FilterLabel.TextSize = 10
FilterLabel.TextColor3 = Palette.TextMuted
FilterLabel.TextXAlignment = Enum.TextXAlignment.Left
FilterLabel.Parent = TrainCard

local FilterOptions = {
    { id = "2X_PLUS",  label = "2x+ (2x/2.30x/3x/4x)" },
    { id = "ALL",      label = "All (1x - 4x)" },
    { id = "MAX_ONLY", label = "High (2.30x/3x/4x)" },
    { id = "2X_ONLY",  label = "2x / 2.30x Only" },
}

local FilterBtns = {}
for i, opt in ipairs(FilterOptions) do
    local fBtn = Instance.new("TextButton")
    fBtn.Size = UDim2.new(0, 124, 0, 28)
    fBtn.Position = UDim2.new(0, 10 + (i - 1) * 129, 0, 116)
    fBtn.BackgroundColor3 = (State.AutoTrainFilter == opt.id) and Palette.Accent or Palette.BgCard
    fBtn.Text = opt.label
    fBtn.Font = Enum.Font.GothamBold
    fBtn.TextSize = 10
    fBtn.TextColor3 = Palette.TextMain
    fBtn.Parent = TrainCard
    AddCorner(fBtn, 6)
    FilterBtns[opt.id] = fBtn

    fBtn.MouseButton1Click:Connect(function()
        State.AutoTrainFilter = opt.id
        for k, b in pairs(FilterBtns) do
            b.BackgroundColor3 = (k == opt.id) and Palette.Accent or Palette.BgCard
        end
    end)
end

local ModeLabel = Instance.new("TextLabel")
ModeLabel.Size = UDim2.new(1, -20, 0, 18)
ModeLabel.Position = UDim2.new(0, 10, 0, 154)
ModeLabel.BackgroundTransparency = 1
ModeLabel.Text = "Cursor Precision Mode:"
ModeLabel.Font = Enum.Font.GothamBold
ModeLabel.TextSize = 10
ModeLabel.TextColor3 = Palette.TextMuted
ModeLabel.TextXAlignment = Enum.TextXAlignment.Left
ModeLabel.Parent = TrainCard

local ModeOptions = {
    { id = "SMART",       label = "Smart Auto (Bar + Popup)" },
    { id = "BAR_ALIGN",   label = "Bar Needle Alignment" },
    { id = "POPUP_CLICK", label = "Direct Cursor Tap" },
}

local ModeBtns = {}
for i, mOpt in ipairs(ModeOptions) do
    local mBtn = Instance.new("TextButton")
    mBtn.Size = UDim2.new(0, 166, 0, 30)
    mBtn.Position = UDim2.new(0, 10 + (i - 1) * 172, 0, 174)
    mBtn.BackgroundColor3 = (State.AutoTrainMode == mOpt.id) and Palette.Accent or Palette.BgCard
    mBtn.Text = mOpt.label
    mBtn.Font = Enum.Font.GothamBold
    mBtn.TextSize = 10
    mBtn.TextColor3 = Palette.TextMain
    mBtn.Parent = TrainCard
    AddCorner(mBtn, 6)
    ModeBtns[mOpt.id] = mBtn

    mBtn.MouseButton1Click:Connect(function()
        State.AutoTrainMode = mOpt.id
        for k, b in pairs(ModeBtns) do
            b.BackgroundColor3 = (k == mOpt.id) and Palette.Accent or Palette.BgCard
        end
    end)
end

--// =========================================================================
--// TAB 3: VISUAL, AVATAR COSMETICS, CAMERA & WORLD SHADERS
--// =========================================================================
local VisCard = CreateCard(PageVisual, "ESP, HEADLESS HORSEMAN, KORBLOX & WORLD SHADERS", 296)

CreateToggleButton(VisCard, UDim2.new(0, 10, 0, 32), UDim2.new(0, 166, 0, 28), "Player ESP", State.PlayerESP, function(v)
    UpdatePlayerESP(v)
end)
CreateToggleButton(VisCard, UDim2.new(0, 184, 0, 32), UDim2.new(0, 166, 0, 28), "X-Ray Walls", State.XRayActive, function(v)
    SetXRayWalls(v)
end)
CreateToggleButton(VisCard, UDim2.new(0, 358, 0, 32), UDim2.new(0, 166, 0, 28), "Rainbow Body", State.RainbowChar, function(v)
    State.RainbowChar = v
end)

local QuickVisualCmds = {
    "Client Headless Horseman ON",
    "Client Headless Horseman OFF",
    "Client Headless ON",
    "Client Headless OFF",
    "Client Korblox ON",
    "Client Korblox OFF",
    "Fullbright Max",
    "Midnight Obsidian Sky",
    "Cyber Crimson Shader",
    "Golden Sunset Shader",
    "FPS Booster LowGFX",
    "Restore Default Lighting",
    "FreeCam Detach Mode ON",
    "FreeCam Detach Mode OFF",
    "Camera FOV 105 (Pro)",
    "Unlock Zoom 5000 Studs",
    "Spectate Next Player",
    "Reset Camera to Self",
}

for idx, cmdName in ipairs(QuickVisualCmds) do
    local col = (idx - 1) % 3
    local row = math.floor((idx - 1) / 3)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 166, 0, 28)
    b.Position = UDim2.new(0, 10 + col * 172, 0, 72 + row * 34)
    b.BackgroundColor3 = Palette.BgCard
    b.Text = cmdName
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.TextColor3 = Palette.TextMain
    b.Parent = VisCard
    AddCorner(b, 6)

    b.MouseButton1Click:Connect(function()
        local entry = CommandLookup[string.lower(cmdName)]
        if entry then pcall(entry.run) end
    end)
end

--// =========================================================================
--// TAB 4: FEATURED FX SHOWCASE (FILTERABLE BY CATEGORY)
--// =========================================================================
local NewFilterBar = Instance.new("Frame")
NewFilterBar.Size = UDim2.new(1, -6, 0, 32)
NewFilterBar.BackgroundColor3 = Palette.BgPanel
NewFilterBar.BackgroundTransparency = 0.15
NewFilterBar.Parent = PageNew100
AddCorner(NewFilterBar, 8)
AddStroke(NewFilterBar, Palette.Stroke, 1)

local NewSubCats = { "ALL", "Visual/ESP", "Camera", "Physics/Fun", "Tween/Waypoints", "Automation", "Character/UI" }
local NewCatBtns = {}
local NewFeatureRows = {}

local function RenderNew100List()
    for _, item in ipairs(NewFeatureRows) do
        local match = (State.NewFeatureFilter == "ALL") or (item.cmd.subTag == State.NewFeatureFilter)
        item.btn.Visible = match
    end
end

for i, sub in ipairs(NewSubCats) do
    local cb = Instance.new("TextButton")
    cb.Size = UDim2.new(0, 72, 0, 22)
    cb.Position = UDim2.new(0, 6 + (i - 1) * 75, 0.5, -11)
    cb.BackgroundColor3 = (sub == "ALL") and Palette.Accent or Palette.BgCard
    cb.Text = (sub == "Tween/Waypoints") and "Waypoints" or sub
    cb.Font = Enum.Font.GothamBold
    cb.TextSize = 9
    cb.TextColor3 = Palette.TextMain
    cb.Parent = NewFilterBar
    AddCorner(cb, 5)
    NewCatBtns[sub] = cb

    cb.MouseButton1Click:Connect(function()
        State.NewFeatureFilter = sub
        for k, b in pairs(NewCatBtns) do
            b.BackgroundColor3 = (k == sub) and Palette.Accent or Palette.BgCard
        end
        RenderNew100List()
    end)
end

for _, cmd in ipairs(New100Features) do
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, -6, 0, 30)
    row.BackgroundColor3 = Palette.BgPanel
    row.BackgroundTransparency = 0.15
    row.Text = ""
    row.AutoButtonColor = true
    row.Parent = PageNew100
    AddCorner(row, 6)
    AddStroke(row, Palette.Stroke, 1)

    local tagBadge = Instance.new("TextLabel")
    tagBadge.Size = UDim2.new(0, 92, 0, 20)
    tagBadge.Position = UDim2.new(0, 6, 0.5, -10)
    tagBadge.BackgroundColor3 = Palette.AccentSoft
    tagBadge.Text = cmd.subTag
    tagBadge.Font = Enum.Font.GothamBold
    tagBadge.TextSize = 9
    tagBadge.TextColor3 = Palette.Accent
    tagBadge.Parent = row
    AddCorner(tagBadge, 4)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -112, 1, 0)
    lbl.Position = UDim2.new(0, 104, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = string.format("#%d  %s  —  %s", cmd.id, cmd.name, cmd.desc)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 10
    lbl.TextColor3 = Palette.TextMain
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    row.MouseButton1Click:Connect(function()
        pcall(cmd.run)
    end)

    table.insert(NewFeatureRows, { btn = row, cmd = cmd })
end

--// =========================================================================
--// TAB 5: ALL 190 REAL FEATURES BROWSER (PAGINATED + LIVE SEARCH)
--// =========================================================================
local SearchRow = Instance.new("Frame")
SearchRow.Size = UDim2.new(1, -6, 0, 32)
SearchRow.BackgroundTransparency = 1
SearchRow.Parent = PageAll

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -172, 1, 0)
SearchBox.BackgroundColor3 = Palette.BgPanel
SearchBox.PlaceholderText = "Search 190 real features (e.g. horseman, orbit, freecam, esp, bridge)..."
SearchBox.Text = ""
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 11
SearchBox.TextColor3 = Palette.TextMain
SearchBox.PlaceholderColor3 = Palette.TextMuted
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = SearchRow
AddCorner(SearchBox, 6)
AddStroke(SearchBox, Palette.Stroke, 1)

local PrevPageBtn = Instance.new("TextButton")
PrevPageBtn.Size = UDim2.new(0, 42, 1, 0)
PrevPageBtn.Position = UDim2.new(1, -164, 0, 0)
PrevPageBtn.BackgroundColor3 = Palette.BgCard
PrevPageBtn.Text = "<"
PrevPageBtn.Font = Enum.Font.GothamBold
PrevPageBtn.TextSize = 13
PrevPageBtn.TextColor3 = Palette.TextMain
PrevPageBtn.Parent = SearchRow
AddCorner(PrevPageBtn, 6)

local PageInfoLabel = Instance.new("TextLabel")
PageInfoLabel.Size = UDim2.new(0, 74, 1, 0)
PageInfoLabel.Position = UDim2.new(1, -118, 0, 0)
PageInfoLabel.BackgroundTransparency = 1
PageInfoLabel.Text = "1 / 5"
PageInfoLabel.Font = Enum.Font.GothamBold
PageInfoLabel.TextSize = 11
PageInfoLabel.TextColor3 = Palette.Cyan
PageInfoLabel.Parent = SearchRow

local NextPageBtn = Instance.new("TextButton")
NextPageBtn.Size = UDim2.new(0, 42, 1, 0)
NextPageBtn.Position = UDim2.new(1, -42, 0, 0)
NextPageBtn.BackgroundColor3 = Palette.BgCard
NextPageBtn.Text = ">"
NextPageBtn.Font = Enum.Font.GothamBold
NextPageBtn.TextSize = 13
NextPageBtn.TextColor3 = Palette.TextMain
NextPageBtn.Parent = SearchRow
AddCorner(NextPageBtn, 6)

local CmdRows = {}
local RowBoundCmds = {}

for i = 1, State.ItemsPerPage do
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, -6, 0, 28)
    row.BackgroundColor3 = Palette.BgPanel
    row.BackgroundTransparency = 0.15
    row.Text = ""
    row.AutoButtonColor = true
    row.Parent = PageAll
    AddCorner(row, 6)
    AddStroke(row, Palette.Stroke, 1)

    local lbl = Instance.new("TextLabel")
    lbl.Name = "Label"
    lbl.Size = UDim2.new(1, -16, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 10
    lbl.TextColor3 = Palette.TextMain
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    row.MouseButton1Click:Connect(function()
        local bound = RowBoundCmds[i]
        if bound then
            pcall(bound.run)
        end
    end)

    CmdRows[i] = row
end

local FilteredCommands = Commands

local function RebuildFilteredCommands()
    local q = string.lower(string.gsub(State.SearchQuery, "%s+", ""))
    if q == "" then
        FilteredCommands = Commands
    else
        local res = {}
        for _, cmd in ipairs(Commands) do
            local nameClean = string.lower(string.gsub(cmd.name, "%s+", ""))
            local descClean = string.lower(string.gsub(cmd.desc, "%s+", ""))
            local catClean  = string.lower(string.gsub(cmd.category, "%s+", ""))
            if string.find(nameClean, q, 1, true)
                or string.find(descClean, q, 1, true)
                or string.find(catClean, q, 1, true)
                or tostring(cmd.id) == q then
                res[#res + 1] = cmd
            end
        end
        FilteredCommands = res
    end
    State.CurrentPage = 1
end

local function RenderCommandPage()
    local total = #FilteredCommands
    local maxPage = math.max(1, math.ceil(total / State.ItemsPerPage))
    State.CurrentPage = math.clamp(State.CurrentPage, 1, maxPage)
    PageInfoLabel.Text = State.CurrentPage .. " / " .. maxPage

    local startIdx = (State.CurrentPage - 1) * State.ItemsPerPage + 1
    for i = 1, State.ItemsPerPage do
        local row = CmdRows[i]
        local cmd = FilteredCommands[startIdx + i - 1]
        RowBoundCmds[i] = cmd
        if cmd then
            row.Visible = true
            row.Label.Text = string.format("[#%d | %s] %s  -  %s", cmd.id, cmd.category, cmd.name, cmd.desc)
        else
            row.Visible = false
        end
    end
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    State.SearchQuery = SearchBox.Text
    RebuildFilteredCommands()
    RenderCommandPage()
end)

PrevPageBtn.MouseButton1Click:Connect(function()
    if State.CurrentPage > 1 then
        State.CurrentPage = State.CurrentPage - 1
        RenderCommandPage()
    end
end)

NextPageBtn.MouseButton1Click:Connect(function()
    local maxPage = math.max(1, math.ceil(#FilteredCommands / State.ItemsPerPage))
    if State.CurrentPage < maxPage then
        State.CurrentPage = State.CurrentPage + 1
        RenderCommandPage()
    end
end)

RenderCommandPage()

-- Live Telemetry & Auto Train Status Updater
task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        local st = State.AutoTrainEnabled and "ACTIVE" or "IDLE"
        TrainStatusLabel.Text = string.format(
            "Cursor Status: %s  |  Last Hit: %s  |  Clicks: %d",
            st,
            State.LastDetectedText,
            State.TrainClickCount
        )
        TelemetryLabel.Text = string.format(
            "WS: %d%s  |  Fly: %d  |  Tween: %d  |  %s",
            State.WalkSpeed,
            State.WalkSpeedLocked and " (LOCK)" or "",
            State.FlySpeed,
            GetEffectiveTweenSpeed(),
            State.StatusMessage
        )
        task.wait(0.25)
    end
end)
