local function requestTaunts()
    net.Start("PH_TauntRequest")
    net.SendToServer()
	print("Requesting taunts...")
end

local function consolidate(trunk)
	local pool = {}
	for _, branch in pairs(trunk) do
		for _, leaf in pairs(branch) do
			table.insert(pool, leaf)
		end
	end
	return pool
end

hook.Add( "InitPostEntity", "PHRequestTaunts", function() -- this was breaking for some reason when we did it on tick 1
    requestTaunts()
end )

requestTaunts()

PHE.TAUNTS = {}

net.Receive("PH_TauntRequest",function()
    local length = net.ReadUInt(16)
    local data = util.JSONToTable( util.Decompress( net.ReadData(length) ) )
    PHE.TAUNTS.HUNTERS = data.h
    PHE.TAUNTS.PROPS = data.p
	PHE.TAUNTS.PROPS_CONCOMMAND = consolidate(data.p)
	PHE.TAUNTS.HUNTERS_CONCOMMAND = consolidate(data.h)
end)

-- this really should be in a shared file but I'm lazy
function PHE:GetAllTeamTaunt(teamid)
	if teamid == TEAM_PROPS then
		local taunts = {}
        for k, v in pairs(PHE.TAUNTS.PROPS) do
            table.Merge(taunts,v)
        end
		return taunts
	end

	if teamid == TEAM_HUNTERS then
		local taunts = {}
        for k, v in pairs(PHE.TAUNTS.HUNTERS) do
            table.Merge(taunts,v)
        end
		return taunts
	end
	return false
end

function PHE:GetTeamTaunt(teamid)
	if teamid == TEAM_PROPS then
		return PHE.TAUNTS.PROPS
	end
	if teamid == TEAM_HUNTERS then
		return PHE.TAUNTS.HUNTERS
	end
	return false
end