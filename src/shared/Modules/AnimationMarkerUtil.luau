--!strict
--[[
    Elemental Worlds: Animation Marker Utility
    Coordinates animation playback and marker event binding.
    GUARANTEES fallback execution if asset ID is missing (e.g. rbxassetid://0) or marker fails.
]]

local AnimationMarkerUtil = {}

-- Safe playback helper with marker detection and fallback timer
function AnimationMarkerUtil.PlayWithMarker(
    humanoid: Humanoid,
    animationId: string,
    markerName: string,
    fallbackDelaySeconds: number,
    onMarkerFired: () -> (),
    onEnded: (() -> ())?
): AnimationTrack?
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    local fired = false
    local function triggerOnce()
        if not fired then
            fired = true
            task.spawn(onMarkerFired)
        end
    end

    -- If no valid animation ID is provided yet, execute fallback immediately
    if not animationId or animationId == "" or animationId == "rbxassetid://0" then
        task.delay(math.max(fallbackDelaySeconds, 0.05), triggerOnce)
        if onEnded then
            task.delay(math.max(fallbackDelaySeconds + 0.2, 0.25), onEnded)
        end
        return nil
    end

    local anim = Instance.new("Animation")
    anim.AnimationId = animationId

    local success, track = pcall(function()
        return animator:LoadAnimation(anim)
    end)

    if not success or not track then
        -- Fallback if animation fails to load
        task.delay(fallbackDelaySeconds, triggerOnce)
        if onEnded then
            task.delay(fallbackDelaySeconds + 0.2, onEnded)
        end
        return nil
    end

    -- Listen for specific marker
    local markerConn: RBXScriptConnection?
    markerConn = track:GetMarkerReachedSignal(markerName):Connect(function()
        if markerConn then
            markerConn:Disconnect()
            markerConn = nil
        end
        triggerOnce()
    end)

    -- Track stopped callback
    track.Stopped:Connect(function()
        if markerConn then
            markerConn:Disconnect()
            markerConn = nil
        end
        -- If marker was never reached before track ended, fire trigger
        triggerOnce()
        if onEnded then
            task.spawn(onEnded)
        end
    end)

    track:Play()

    -- Fallback safety timer in case marker name does not exist in track
    task.delay(fallbackDelaySeconds + 0.5, function()
        if not fired then
            if markerConn then
                markerConn:Disconnect()
                markerConn = nil
            end
            triggerOnce()
        end
    end)

    return track
end

return table.freeze(AnimationMarkerUtil)
