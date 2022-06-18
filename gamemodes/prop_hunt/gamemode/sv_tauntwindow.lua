-- Validity check to prevent some sort of spam
local function IsTaunting(ply)
	return ply:GetNWFloat("NextCanTaunt",0) >= CurTime()
end

local function CanWaitHint(ply)
	return ply.WaitHint < CurTime()
end

local TEAM_TAUNT_DIRS = {}

net.Receive("CL2SV_PlayThisTaunt", function(len, ply)

	local snd = net.ReadString() or "" -- don't error if client is drunk
	snd = "taunts/" .. snd

	if IsTaunting(ply) then
		if CanWaitHint(ply) then
			ply.WaitHint = math.min( ply:GetNWFloat("NextCanTaunt",0), CurTime() + 1 )
			ply:ChatPrint("[PH: Infinity] - You're still playing a taunt. You can taunt again in ".. math.ceil(ply:GetNWFloat("NextCanTaunt",0) - CurTime()) .. " seconds.")
		end
		return
	end

	if not file.Exists("sound/" .. snd, "GAME") then
		ply:ChatPrint("[PH: Infinity] - Failed to play taunt! (doesn't exist???)")
		return
	end

	local teamdir = ((ply:Team() == TEAM_HUNTERS) and "taunts/hunters") or ((ply:Team() == TEAM_PROPS) and "taunts/props") or "NONE"

	if not string.StartWith(snd, teamdir) then
		ply:ChatPrint("[PH: Infinity] - Failed to play taunt! (it doesn't belong to your team!)")
		return
	end

	if not ply:Alive() then
		ply:ChatPrint("[PH: Infinity] - Failed to play taunt! (ur dead, lol)")
		return
	end

	ply:EmitSound(snd, 100)
	ply:SetNWFloat("NextCanTaunt", CurTime() + NewSoundDuration("sound/" .. snd))

end)