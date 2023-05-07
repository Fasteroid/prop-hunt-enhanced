local CATEGORY_NAME = "Utility"

-- TODO: force an unstuck if all corners of their OBB are inside something

if SERVER then -- client doesn't need to see this

    local Player = FindMetaTable("Player")
    if !Player then return end

    function Player:CheckOBB(maxs,mins)
        local tr = {}
        tr.start = self:GetPos()
        tr.endpos = self:GetPos()
        tr.filter = {self, self.ph_prop}
        tr.maxs = maxs
        tr.mins = mins
        tr.mask = MASK_PLAYERSOLID

        local trx = util.TraceHull(tr)
        if trx.Hit then return false end
        return true
    end

    function Player:GetHullTrue()
        if self:Crouching() then
            return self:GetHullDuck()
        else
            return self:GetHull()
        end
    end

    util.AddNetworkString("PH:Infinity.StuckNotifySound")
    local UNSTUCK_COOLDOWN = 10
    local UNSTUCK_OBSERVE_TICKS = 1 / engine.TickInterval()

    local function notifyStuck(ply)

        local data = ply.UnstuckData
        data.speedTick  = 0
        data.velTotal   = Vector(0,0,0)

        local timername = ply:SteamID64().."_unstuck"

        timer.Create(timername, 0, UNSTUCK_OBSERVE_TICKS, function() -- determine it over the next second\
            if not IsValid(ply) then timer.Remove(timername) end

            data.speedTick = data.speedTick + 1
            data.velTotal  = data.velTotal + ply:GetVelocity()

            if data.speedTick >= UNSTUCK_OBSERVE_TICKS then
                local mins, maxs = ply:GetHullTrue()
                if( data.velTotal:Length() / data.speedTick < 50 and not ply:CheckOBB(maxs, mins) ) then
                    ULib.tsayError( ply, "You look like you might be stuck.  If you need a hand use !unstuck in chat." ) -- tsayerror is more likely to grab their attention
                    net.Start("PH:Infinity.StuckNotifySound")
                    net.Send(ply)
                end
            end

        end)

    end

    local unstuck_tick_handlers = {
        [TEAM_PROPS] = function(ply)
            ply.UnstuckData = ply.UnstuckData or {
                nextAllowed = 0,
                isFree = true,
                lastGoodPosition = Vector(0,0,0),
                lastGoodModel = "",
            }
            local data = ply.UnstuckData

            local curPos = ply:GetPos()
            local curModel = ply.ph_prop:GetModel()
            
            local mins, maxs = ply:GetHullTrue()
            local free = ply:CheckOBB(maxs, mins)

            if data.isFree and not free then
                notifyStuck(ply)
            end

            if free then
                data.lastGoodPosition = curPos
                data.lastGoodModel = curModel
            end

            data.isFree = free
        end,
        [TEAM_HUNTERS] = function(ply) -- they deserve it too!
            ply.UnstuckData = ply.UnstuckData or {
                nextAllowed = 0,
                isFree = true,
                lastGoodPosition = Vector(0,0,0),
            }
            local data = ply.UnstuckData

            local curPos = ply:GetPos()

            local mins, maxs = ply:GetHullTrue()
            local free = ply:CheckOBB(maxs, mins)

            if data.isFree and not free then
                notifyStuck(ply)
            end

            if free then
                data.lastGoodPosition = curPos
            end

            data.isFree = free
        end
    }

    local unstuck_action_handlers = {
        [TEAM_PROPS] = function(ply, data)
            ply:SetPos( data.lastGoodPosition ) -- force them back to the last good position

            -- Temporarily Spawn a prop. (wolvin's solution from prop chooser)
            -- TODO: make this less aids
            local pos = ply:GetPos()
            local ent = ents.Create("prop_physics")
            ent:SetPos( Vector(0,0,0) )
            ent:SetAngles(Angle(0,0,0))
            ent:SetKeyValue("spawnflags","654")
            ent:SetNoDraw(true)
            ent:SetModel(data.lastGoodModel)
		
		    ent:Spawn()
            GAMEMODE:PlayerExchangeProp(ply,ent) -- force them back to the last good model
            ent:Remove()
        end,
        [TEAM_HUNTERS] = function(ply, data)
            ply:SetPos( data.lastGoodPosition ) -- all we can really do
        end
    }

    function ulx.unstuck( calling_ply )

        local UnstuckData = calling_ply.UnstuckData

        if not calling_ply:Alive() then
            ULib.tsayError( calling_ply, "This does nothing right now, you are dead! (lol)", true )
            return
        end

        if UnstuckData.isFree then
            ULib.tsayError( calling_ply, "You do not appear to be stuck right now.", true )
            return
        end

        if UnstuckData.nextAllowed > CurTime() then
            ULib.tsayError( calling_ply, "Unstuck is on cooldown for " .. math.ceil( UnstuckData.nextAllowed - CurTime() ) .. " more seconds.  Stop trying to cheat!", true )
            return
        end

        local unstuck = unstuck_action_handlers[ calling_ply:Team() ]
        if unstuck then 
            unstuck(calling_ply, UnstuckData) 
            ULib.tsayColor( calling_ply, true, Color(151,211,255), "There you go, hopefully that helped!" )
        end

        UnstuckData.nextAllowed = CurTime() + UNSTUCK_COOLDOWN
        
    end
    local unstuck = ulx.command( CATEGORY_NAME, "ulx unstuck", ulx.unstuck, "!unstuck", true )
    unstuck:defaultAccess( ULib.ACCESS_ALL )
    unstuck:help( "Attempts to get you unstuck." )

    hook.Add("Think", "PH:Infinity.UnstuckLogic", function()
        for k, ply in pairs( player.GetHumans() ) do

            if not ply:Alive() then continue end
            local tick_handler = unstuck_tick_handlers[ ply:Team() ]
            if not tick_handler then continue end

            tick_handler(ply)

        end
    end)

end

if CLIENT then
    net.Receive("PH:Infinity.StuckNotifySound", function()
        surface.PlaySound("common/warning.wav")
    end)
end
