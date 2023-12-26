local function pickRandom(tbl)
    for _, k in RandomPairs(table.GetKeys(tbl)) do
        return tbl[k]
    end
end

function PHE:PropReactFear(ply)
    PHE:MakePlayerTaunt(ply, "taunts/" .. pickRandom(PHE.TAUNTS.PROPS.fear), true) -- don't award points for this
end

function PHE:HunterReactSpotted(ply)
    PHE:MakePlayerTaunt(ply, "taunts/" .. pickRandom(PHE.TAUNTS.HUNTERS.spot_reaction))
end

function PHE:HunterReactKill(ply)
    PHE:MakePlayerTaunt(ply, "taunts/" .. pickRandom(PHE.TAUNTS.HUNTERS.kill_reaction))
end