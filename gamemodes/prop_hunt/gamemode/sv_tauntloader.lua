-- Global Var for custom taunt, delivering from taunts/prop -or- hunter_taunts.lua
util.AddNetworkString("PH_TauntRequest")


local function CompileTaunts()

    PHE.TAUNTS = {}
    PHE.TAUNTS.PROPS = {}
    PHE.TAUNTS.HUNTERS = {}
    PHE.TAUNTS.FORCEABLE = {}

    local _, hunterTauntGroups = file.Find("sound/taunts/hunters/*", "GAME");
    for _, dir in pairs( hunterTauntGroups ) do
        PHE.TAUNTS.HUNTERS[dir] = {}
        local tauntDir = PHE.TAUNTS.HUNTERS[dir]
        local tauntPath = "hunters/"..dir.."/"
        local tauntNames = file.Find("sound/taunts/"..tauntPath.."*", "GAME");
        for _, taunt in pairs( tauntNames ) do
            tauntDir[taunt] = tauntPath..taunt
        end
    end

    local _, propTauntGroups = file.Find("sound/taunts/props/*", "GAME");
    for _, dir in pairs( propTauntGroups ) do
        PHE.TAUNTS.PROPS[dir] = {}
        local tauntDir = PHE.TAUNTS.PROPS[dir]
        local tauntPath = "props/"..dir.."/"
        local tauntNames = file.Find("sound/taunts/"..tauntPath.."*", "GAME");
        for _, taunt in pairs( tauntNames ) do
            tauntDir[taunt] = tauntPath..taunt
            table.insert(PHE.TAUNTS.FORCEABLE, tauntDir[taunt])
        end
    end

	-- cache these for easy access
    PHE.TAUNTS.COMPRESSED = util.Compress( util.TableToJSON({
		h = PHE.TAUNTS.HUNTERS,
		p = PHE.TAUNTS.PROPS
	}))

end

CompileTaunts()

-- this really should be in a shared file but I'm lazy
function PHE:GetAllTeamTaunt(teamid)
	if teamid == TEAM_PROPS then
		local taunt = table.Copy(PHE.TAUNTS.PROPS)
		return taunt
	end

	if teamid == TEAM_HUNTERS then
		local taunt = table.Copy(PHE.TAUNTS.HUNTERS)
		return taunt
	end
	return false
end

net.Receive("PH_TauntRequest", function(size,sender)
    if not sender.HasTaunts then -- antispam
        sender.HasTaunts = true 
        print(sender:Nick() .. " requested Taunts.")
        net.Start("PH_TauntRequest")
			net.WriteUInt(#PHE.TAUNTS.COMPRESSED,16)
            net.WriteData(PHE.TAUNTS.COMPRESSED)
        net.Send(sender)
    end
end)