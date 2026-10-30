--!strict
--[[
    Elemental Worlds: Procedural Animation Controller
    Provides high-fidelity procedural combat motion (Lunge, Recoil, Arm Thrusts, Torso Twists)
    guaranteeing satisfying combat feel even before custom animation IDs are uploaded.
]]

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer

local ProceduralAnimController = {}

-- Finds Motor6D joints on R15/R6 characters
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
        -- Right Punch Thrust
        local originalC0 = rShoulder.C0
        local targetC0 = originalC0 * CFrame.Angles(math.rad(85), math.rad(-15), math.rad(25))

        local punchTween = TweenService:Create(rShoulder, TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { C0 = targetC0 })
        punchTween:Play()
        punchTween.Completed:Once(function()
            local resetTween = TweenService:Create(rShoulder, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { C0 = originalC0 })
            resetTween:Play()
        end)
    elseif lShoulder then
        -- Left Punch Thrust
        local originalC0 = lShoulder.C0
        local targetC0 = originalC0 * CFrame.Angles(math.rad(85), math.rad(15), math.rad(-25))

        local punchTween = TweenService:Create(lShoulder, TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { C0 = targetC0 })
        punchTween:Play()
        punchTween.Completed:Once(function()
            local resetTween = TweenService:Create(lShoulder, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { C0 = originalC0 })
            resetTween:Play()
        end)
    end
end

-- Procedural Recoil on heavy cast
function ProceduralAnimController.PlayCastRecoil()
    local char = localPlayer.Character
    if not char then return end

    local joints = GetJoints(char)
    if not joints or not joints.RootJoint then return end

    local rootJoint = joints.RootJoint
    local origC0 = rootJoint.C0
    local recoilC0 = origC0 * CFrame.Angles(math.rad(-10), 0, 0)

    local tween = TweenService:Create(rootJoint, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { C0 = recoilC0 })
    tween:Play()
    tween.Completed:Once(function()
        local reset = TweenService:Create(rootJoint, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { C0 = origC0 })
        reset:Play()
    end)
end

return table.freeze(ProceduralAnimController)
