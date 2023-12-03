if CLIENT then return end
util.AddNetworkString("PH:Infinity.Spot")
local MIN_DOT_PROD = GetConVar("ph_spot_min_dot"):GetFloat()
local SPOT_GLOW_TIME = GetConVar("ph_spot_highlight_time"):GetFloat()
local SPOT_IMMUNE_TIME = GetConVar("ph_respot_immunity_time"):GetFloat()
local SPOT_FAIL_COOL = GetConVar("ph_spot_fail_antispam"):GetFloat()
local SPOT_POINT_VALUE = GetConVar("ph_spot_point_value"):GetInt()
local MAX_POS_HISTORY  = GetConVar("ph_position_history_max"):GetInt()

local function pickRandom(tbl)
    for _, k in RandomPairs(table.GetKeys(tbl)) do
        return tbl[k]
    end
end

do
    PHE.PlayerHistory = {}

    -- Register the player's Position at every PlayerTick
    hook.Add("PlayerTick", "PH:Infinity.PlayerHistory", function(ply, mv)
        PHE.PlayerHistory[ply] = PHE.PlayerHistory[ply] or {}
        local history = PHE.PlayerHistory[ply]

        if #history > MAX_POS_HISTORY then
            table.remove(history, 1)
        end

        local data = {}
        if ply:Team() == TEAM_PROPS then
            data.boxcenter = ply:WorldSpaceCenter()
            data.speed     = ply:GetVelocity():LengthSqr()
        else
            data.shootpos  = ply:GetShootPos()
            data.aimvector = ply:GetAimVector()
        end

        history[#history + 1] = data
    end)

    -- Cleanup the PositionHistory to save a few bytes :skullemoji:
    hook.Add("PlayerDisconnected", "PH:Infinity.HistoryCleaner", function(ply)
        PHE.PlayerHistory[ply] = nil
    end)

    -- Reset the player history every round (every respawn)
    hook.Add("PlayerSpawn", "PH:Infinity.HistoryCleaner", function(ply)
        PHE.PlayerHistory[ply] = {}
    end)
end

local player_meta = FindMetaTable("Player")
local tick_interval = engine.TickInterval()

function player_meta:GetLaggedData( ping, key )
    local history = PHE.PlayerHistory[self]
    local ping_ind = math.floor( ping * tick_interval ) -- where does the 6 come from? who cares?!
    ping_ind = #history - math.min(ping_ind, #history)
    local data = history[ping_ind]
    return data[key]
end

local function checkLineOfSight(hunter_pos, prop_pos, filter_ent)
    local filter = player.GetAll()
    table.insert(filter, filter_ent)

    local tr = util.TraceLine({
        start = hunter_pos,
        endpos = prop_pos,
        filter = filter
    })

    return tr.Fraction == 1
end

local function AttemptSpotting(hunter)
    local target = nil
    local bestscore = 9e9

    local player_count = player.GetCount()
    local players      = player.GetAll()

    for i = 1, player_count do
        local ply = players[i]
        if ply:Team() ~= TEAM_PROPS then continue end -- nope
        if not ply:Alive() then continue end -- nah

        local lag = hunter:Ping()

        local aim_hunter = hunter:GetLaggedData(lag, "aimvector")
        local pos_hunter = hunter:GetLaggedData(lag, "shootpos")
        local pos_prop   = ply:GetLaggedData(lag, "boxcenter")
        local speed_prop = ply:GetLaggedData(lag, "speed")

        if speed_prop < 2800 then continue end -- too stealthy

        if not checkLineOfSight(pos_hunter, pos_prop, ply.ph_prop) then continue end -- no

        ply.nextSpot = ply.nextSpot or 0

        if ply.nextSpot > CurTime() then continue end -- already spotted

        if (pos_prop - pos_hunter):GetNormalized():Dot( aim_hunter ) < MIN_DOT_PROD then continue end -- get better aim dude

        local score = pos_prop:DistToSqr(pos_hunter)

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