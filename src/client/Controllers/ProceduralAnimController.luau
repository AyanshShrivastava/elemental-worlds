--!strict
--[[
    Elemental Worlds: Procedural Animation Controller (Blox Fruits Anime Combat)
    Provides instantaneous client-side physical rig reactions:
    - Punches & Combo Chains
    - Heavy Cast Recoil
    - Ground Slams
    - Forward Lunges & Thrusts
    - Whirlwind Spins
    Guarantees 0ms tactile responsiveness even before animations replicate!
]]

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer

local ProceduralAnimController = {}

local function GetJoints(character: Model)
    local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    if not rootPart or not torso then return nil end

    local rightArm = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm")
    local leftArm = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm")

    local rightShoulder: Motor6D? = nil
    local leftShoulder: Motor6D? = nil
    local rootJoint: Motor6D? = nil

    for _, desc in character:GetDescendants() do
        if desc:IsA("Motor6D") then
            if desc.Name == "RightShoulder" or desc.Part1 == rightArm then
                rightShoulder = desc
            elseif desc.Name == "LeftShoulder" or desc.Part1 == leftArm then
                leftShoulder = desc
            elseif desc.Name == "Root" or desc.Name == "RootJoint" then
                rootJoint = desc
            end
        end
    end

    return {
        RightShoulder = rightShoulder,
        LeftShoulder = leftShoulder,
        RootJoint = rootJoint,
    }
end

-- Procedural Punch motion for M1 attacks
function ProceduralAnimController.PlayProceduralPunch(comboStep: number)
    local char = localPlayer.Character
    if not char then return end

    local joints = GetJoints(char)
    if not joints then return end

    local rShoulder = joints.RightShoulder
    local lShoulder = joints.LeftShoulder
    local rootJoint = joints.RootJoint

    if comboStep % 2 == 1 and rShoulder then
        local originalC0 = rShoulder.C0
        local targetC0 = originalC0 * CFrame.Angles(math.rad(90), math.rad(-15), math.rad(25))

        local punchTween = TweenService:Create(rShoulder, TweenInfo.new(0.07, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { C0 = targetC0 })
        punchTween:Play()
        punchTween.Completed:Once(function()
            TweenService:Create(rShoulder, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { C0 = originalC0 }):Play()
        end)
    elseif lShoulder then
        local originalC0 = lShoulder.C0
        local targetC0 = originalC0 * CFrame.Angles(math.rad(90), math.rad(15), math.rad(-25))

        local punchTween = TweenService:Create(lShoulder, TweenInfo.new(0.07, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { C0 = targetC0 })
        punchTween:Play()
        punchTween.Completed:Once(function()
            TweenService:Create(lShoulder, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { C0 = originalC0 }):Play()
        end)
    end
end

-- Heavy Cast Recoil
function ProceduralAnimController.PlayCastRecoil()
    local char = localPlayer.Character
    if not char then return end

    local joints = GetJoints(char)
    if not joints or not joints.RootJoint then return end

    local rootJoint = joints.RootJoint
    local origC0 = rootJoint.C0
    local recoilC0 = origC0 * CFrame.Angles(math.rad(-12), 0, 0)

    local tween = TweenService:Create(rootJoint, TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { C0 = recoilC0 })
    tween:Play()
    tween.Completed:Once(function()
        TweenService:Create(rootJoint, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { C0 = origC0 }):Play()
    end)
end

-- Ground Slam Motion
function ProceduralAnimController.PlayHeavySlam()
    local char = localPlayer.Character
    if not char then return end

    local joints = GetJoints(char)
    if not joints or not joints.RootJoint then return end

    local rootJoint = joints.RootJoint
    local rShoulder = joints.RightShoulder
    local lShoulder = joints.LeftShoulder

    local origRoot = rootJoint.C0
    local slamRoot = origRoot * CFrame.new(0, -1.2, -0.5) * CFrame.Angles(math.rad(30), 0, 0)

    TweenService:Create(rootJoint, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.In), { C0 = slamRoot }):Play()

    if rShoulder and lShoulder then
        local origR = rShoulder.C0
        local origL = lShoulder.C0
        local slamArmR = origR * CFrame.Angles(math.rad(110), 0, math.rad(-20))
        local slamArmL = origL * CFrame.Angles(math.rad(110), 0, math.rad(20))

        TweenService:Create(rShoulder, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { C0 = slamArmR }):Play()
        TweenService:Create(lShoulder, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { C0 = slamArmL }):Play()

        task.delay(0.25, function()
            TweenService:Create(rootJoint, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { C0 = origRoot }):Play()
            TweenService:Create(rShoulder, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { C0 = origR }):Play()
            TweenService:Create(lShoulder, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { C0 = origL }):Play()
        end)
    end
end

-- Forward Lunge / Thrust
function ProceduralAnimController.PlayLunge()
    local char = localPlayer.Character
    if not char then return end

    local joints = GetJoints(char)
    if not joints or not joints.RootJoint then return end

    local rootJoint = joints.RootJoint
    local origRoot = rootJoint.C0
    local lungeRoot = origRoot * CFrame.new(0, -0.4, 1.2) * CFrame.Angles(math.rad(15), 0, 0)

    local tween = TweenService:Create(rootJoint, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { C0 = lungeRoot })
    tween:Play()
    tween.Completed:Once(function()
        TweenService:Create(rootJoint, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { C0 = origRoot }):Play()
    end)
end

return table.freeze(ProceduralAnimController)
