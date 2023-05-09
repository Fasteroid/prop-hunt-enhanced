-- Validity check to prevent some sort of spam
local function IsTaunting(ply)
    return ply:GetNW2Float("NextCanTaunt", 0) >= CurTime()
end

local function CanWaitHint(ply)
    return (ply.WaitHint or 0) < CurTime()
end

-- this now works because I made these enums init sooner
local TEAM_TAUNT_DIRS = {
    [TEAM_PROPS] = "taunts/props",
    [TEAM_HUNTERS] = "taunts/hunters"
}

function PHE:MakePlayerTaunt(ply, snd)
    if not file.Exists("sound/" .. snd, "GAME") then
        ply:ChatPrint("[PH: Infinity] - Failed to play taunt! (doesn't exist???)")

        return
    end

    local teamdir = TEAM_TAUNT_DIRS[ply:Team()] or "NONE"

    if not string.StartWith(snd, teamdir) then
        ply:ChatPrint("[PH: Infinity] - Failed to play taunt! (it doesn't belong to your team!)")

        return
    end

    if not ply:Alive() then
        ply:ChatPrint("[PH: Infinity] - Failed to play taunt! (ur dead, lol)")

        return
    end

    ply:EmitSound(snd, 100)
    local duration = NewSoundDuration("sound/" .. snd)
    local score = math.pow(duration, 1.2) -- reward longer taunts
    local decimal = score % 1
    score = math.floor(score) + (math.random() < decimal and 1 or 0) -- randomly sample to approach true point value at the limit

    if ply:Team() == TEAM_PROPS and GAMEMODE:IsRoundPlaying() then
        ply:PS2_AddStandardPoints(score, "Taunting")
    end

    ply:SetNW2Float("NextCanTaunt", CurTime() + duration)

end

net.Receive("CL2SV_PlayThisTaunt", function(len, ply)
    local snd = net.ReadString()
    if not snd then return end -- client is drunk

    snd = "taunts/" .. snd

    if IsTaunting(ply) then
        if CanWaitHint(ply) then
            ply.WaitHint = math.min(ply:GetNW2Float("NextCanTaunt", 0), CurTime() + 1)
            ply:ChatPrint("[PH: Infinity] - You're still playing a taunt. You can taunt again in " .. math.ceil(ply:GetNW2Float("NextCanTaunt", 0) - CurTime()) .. " seconds.")
        end

        return
    end

    PHE:MakePlayerTaunt(ply, snd)
end)