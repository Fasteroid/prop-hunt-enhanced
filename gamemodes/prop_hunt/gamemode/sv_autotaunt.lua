local ph_autotaunt_enabled = GetConVar("ph_autotaunt_enabled")
local ph_autotaunt_delay = GetConVar("ph_autotaunt_delay")


local function AutoTauntThink()

    if ph_autotaunt_enabled:GetBool() then

        local TAUNTS = PHE.TAUNTS.FORCEABLE

        for _, ply in ipairs(team.GetPlayers(TEAM_PROPS)) do
            local nextAutoTaunt = ply:GetNW2Float("NextCanTaunt") + ph_autotaunt_delay:GetInt()
            if IsValid(ply) and ply:Alive() and nextAutoTaunt <= CurTime() then
                
                local rand_taunt = TAUNTS[ math.random(#TAUNTS) ]

                PHE:MakePlayerTaunt(ply, "taunts/" .. rand_taunt)
                ply:ChatPrint("You auto-taunted " .. rand_taunt)
            end
        end
        
    end
end

timer.Create("AutoTauntThinkTimer", 1, 0, AutoTauntThink)