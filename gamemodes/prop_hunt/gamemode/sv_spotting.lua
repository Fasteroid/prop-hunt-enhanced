if CLIENT then return end
util.AddNetworkString("PH:Infinity.Spot")
local MIN_DOT_PROD = GetConVar("ph_spot_min_dot"):GetFloat()
local SPOT_GLOW_TIME = GetConVar("ph_spot_highlight_time"):GetFloat()
local SPOT_IMMUNE_TIME = GetConVar("ph_respot_immunity_time"):GetFloat()
local SPOT_FAIL_COOL = GetConVar("ph_spot_fail_antispam"):GetFloat()
local SPOT_POINT_VALUE = GetConVar("ph_spot_point_value"):GetInt()

local function pickRandom(tbl)
    for _, k in RandomPairs(table.GetKeys(tbl)) do
        return tbl[k]
    end
end

local function checkLineOfSight(point, ent)
    local filter = player.GetAll()
    table.insert(filter, ent.ph_prop)

    local tr = util.TraceLine({
        start = point,
        endpos = ent:NearestPoint(point),
        filter = filter
    })

    return tr.Fraction == 1
end

local function AttemptSpotting(hunter)
    local target = nil
    local bestscore = 2147483647

    for _, ply in pairs(player.GetAll()) do
        if ply:Team() ~= TEAM_PROPS then continue end -- nope
        if not ply:Alive() then continue end -- nah
        if ply:GetVelocity():LengthSqr() < 3600 then continue end -- too stealthy
        if not checkLineOfSight(hunter:GetShootPos(), ply) then continue end -- no
        ply.nextSpot = ply.nextSpot or 0
        if ply.nextSpot > CurTime() then continue end -- already spotted
        local pos_ply = ply:WorldSpaceCenter()
        local pos_hunter = hunter:GetShootPos()
        if (pos_ply - pos_hunter):GetNormalized():Dot(hunter:GetAimVector()) < MIN_DOT_PROD then continue end -- get better aim dude
        local score = ply:GetPos():DistToSqr(hunter:GetShootPos())

        if score < bestscore then
            bestscore = score
            target = ply
        end
    end

    return target
end

net.Receive("PH:Infinity.Spot", function(_, hunter)
    if hunter:GetNW2Float("PH:Infinity.SpotCooldown") > CurTime() then return end -- nice hacks dude
    if not hunter:Alive() then return end -- nice hacks dude
    if hunter:Team() ~= TEAM_HUNTERS then return end -- nope
    local victim = AttemptSpotting(hunter)

    if not victim then
        hunter:SetNW2Float("PH:Infinity.SpotCooldown", CurTime() + SPOT_FAIL_COOL)
        net.Start("PH:Infinity.Spot")
        net.WriteUInt(1, 4) -- spotting failed sound
        net.Send(hunter)

        return
    end

    hunter:SetNW2Float("PH:Infinity.SpotCooldown", CurTime() + 1)
    local glow_receivers = RecipientFilter()
    glow_receivers:AddRecipientsByTeam(TEAM_HUNTERS)
    glow_receivers:AddPlayer(victim)
    net.Start("PH:Infinity.Spot")
    net.WriteUInt(5, 4)
    net.WriteEntity(victim.ph_prop)
    net.Send(glow_receivers) -- send highlight to everyone
    -- send spotted sound to teammates
    local sound_receivers = RecipientFilter()
    sound_receivers:AddRecipientsByTeam(TEAM_HUNTERS)
    sound_receivers:RemovePlayer(hunter)
    net.Start("PH:Infinity.Spot")
    net.WriteUInt(3, 4)
    net.Send(sound_receivers)
    -- send spotted sound to spotter
    net.Start("PH:Infinity.Spot")
    net.WriteUInt(2, 4)
    net.Send(hunter)
    -- send ominous sound to spotted prop
    net.Start("PH:Infinity.Spot")
    net.WriteUInt(4, 4)
    net.Send(victim)
    -- force the prop to taunt with a fear taunt
    local randomtaunt = "taunts/" .. pickRandom(PHE.TAUNTS.PROPS.fear)
    victim:SetNW2Float("NextCanTaunt", CurTime() + NewSoundDuration("sound/" .. randomtaunt))
    victim:EmitSound(randomtaunt)
    victim.nextSpot = CurTime() + SPOT_IMMUNE_TIME

    if GAMEMODE:IsRoundPlaying() then
        hunter:PS2_AddStandardPoints(SPOT_POINT_VALUE, "Spotting Props")
    end
end)