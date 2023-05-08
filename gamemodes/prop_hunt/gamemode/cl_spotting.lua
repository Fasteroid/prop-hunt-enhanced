if SERVER then return end
local MIN_DOT_PROD = GetConVar("ph_spot_min_dot"):GetFloat()
local SPOT_GLOW_TIME = GetConVar("ph_spot_highlight_time"):GetFloat()
local SPOT_IMMUNE_TIME = GetConVar("ph_respot_immunity_time"):GetFloat()
local SPOT_FAIL_COOL = GetConVar("ph_spot_fail_antispam"):GetFloat()
local SPOT_POINT_VALUE = GetConVar("ph_spot_point_value"):GetInt()
HUDVariables = HUDVariables or {} -- not sure if cl_hud.lua runs first

function PHE:Spot()
    if LocalPlayer():Team() ~= TEAM_HUNTERS then return end -- we'll check again serverside for good measure
    if not LocalPlayer():Alive() then return end -- also check this serverside
    if LocalPlayer():GetNW2Bool("PH:Infinity.Locked", false) then return end -- also check this serverside

    -- still on cooldown
    if LocalPlayer():GetNW2Float("PH:Infinity.SpotCooldown", 0) > CurTime() then
        surface.PlaySound("common/talk.wav")

        return
    end

    net.Start("PH:Infinity.Spot")
    net.SendToServer()
end

concommand.Add("ph_spot", PHE.Spot)

hook.Add("PlayerButtonDown", "PH:Infinity.Spot", function(ply, key)
    if not IsFirstTimePredicted() then return end -- stupid hook
    if key ~= KEY_G then return end
    RunConsoleCommand("ph_spot")
end)

local halo_objects = {}

local function unsetHalo(ent)
    local obj = halo_objects[ent]

    if obj then
        obj.holo:Remove()
        halo_objects[ent] = nil
    end
end

local function getSpawnIconPath(model)
    return "spawnicons/" .. string.StripExtension(model) .. ".png"
end

local function setHalo(ent, time)
    local obj = halo_objects[ent]

    if not obj then
        local model = ent:GetModel()

        halo_objects[ent] = {
            holo = ClientsideModel(model),
            delete = CurTime() + time,
            time = time,
            mater = Material(getSpawnIconPath(model)),
        }

        -- halo_objects[ent].holo:SetColor( Color(0,0,0,0) )
        halo_objects[ent].holo:SetPos(ent:GetPos())
        halo_objects[ent].holo:SetAngles(ent:GetAngles())
        halo_objects[ent].holo:SetParent(ent)

        ent:CallOnRemove("killCSEnt", function()
            unsetHalo(ent)
        end)
    else
        halo_objects[ent].time = time
        halo_objects[ent].delete = CurTime() + time
    end
end

local function getGlowColor(obj)
    local mul = math.Clamp((obj.delete - CurTime()) * 2 / obj.time, 0, 1)

    return Color(255 * mul, 100 * mul, 50 * mul)
end

local glow_color = Color(255, 100, 50)

hook.Add("PreDrawHalos", "AddPropHalos", function()
    local tbl = {}

    for ent, obj in pairs(halo_objects) do
        if obj.delete < CurTime() or not IsValid(obj.holo) then
            unsetHalo(ent)
            continue
        end

        obj.holo:SetPos(ent:GetPos())
        obj.holo:SetAngles(ent:GetAngles())
        local model = ent:GetModel()

        -- in the rare case they change while spotted
        if model ~= obj.holo:GetModel() then
            obj.mater = Material(getSpawnIconPath(model))
            obj.holo:SetModel(model)
        end

        local dist = LocalPlayer():GetShootPos():Distance(ent:GetPos())
        obj.holo:SetModelScale(math.max(dist / ent:GetModelRadius() * 0.01, 1))

        halo.Add({obj.holo}, getGlowColor(obj), 2, 2, 5, true, true)
    end
end)

local receive_handlers = {
    [1] = function()
        surface.PlaySound("ui/spot_fail.wav")

        timer.Simple(SPOT_FAIL_COOL, function()
            surface.PlaySound("ui/spot_ready.wav")
        end)
    end,
    -- spot fail client sound
    [2] = function()
        surface.PlaySound("ui/spot_hunter_client.wav")
        HUDVariables.SpotSuccess = CurTime() + 2
    end,
    -- spot success client sound
    [3] = function()
        surface.PlaySound("ui/spot_hunter_global.wav")
    end,
    -- spot success team sound
    [4] = function()
        surface.PlaySound("ui/spot_prop.wav")
        HUDVariables.LastSpotted = CurTime() + SPOT_GLOW_TIME
    end,
    -- scare the prop player with an ominous sound
    [5] = function()
        setHalo(net.ReadEntity(), SPOT_GLOW_TIME)
    end,
}

-- add them to halo drawing
net.Receive("PH:Infinity.Spot", function()
    local enum = net.ReadUInt(4)
    receive_handlers[enum]()
end)

local pointer = Material("ph_infinity/spotted_pointer.png")

local function HUDPaint()
    -- Draw spotted prop icons
    if LocalPlayer():Team() == TEAM_HUNTERS then
        local w = ScrW()
        local h = ScrH()
        local cX = w / 2
        local cY = h / 2

        for ent, obj in pairs(halo_objects) do
            local pos = ent:WorldSpaceCenter()
            local poscr = pos:ToScreen()

            if (pos - LocalPlayer():GetShootPos()):GetNormalized():Dot(LocalPlayer():GetAimVector()) < 0.7 then
                local r = math.Round(cX / 2)
                local rad = math.atan2(poscr.y - cY, poscr.x - cX)
                local deg = 0 - math.Round(math.deg(rad))
                surface.SetDrawColor(255, 255, 255, 255)
                surface.SetMaterial(pointer)
                surface.DrawTexturedRectRotated(math.cos(rad) * r + cX, math.sin(rad) * r + cY, 128, 128, deg + 90)
                surface.SetMaterial(obj.mater)
                r = r - 16
                surface.DrawTexturedRectRotated(math.cos(rad) * r + cX, math.sin(rad) * r + cY, 48, 48, 0)
            end
        end
    end
end

hook.Add("HUDPaint", "PH:Infinity.SpottedPropHUDPaint", HUDPaint)