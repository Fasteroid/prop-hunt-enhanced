-- Validity check to prevent some sort of spam
local function CanTaunt(ply)
	return ply:GetNWFloat("NextCanTaunt",0) < CurTime()
end

net.Receive("CL2SV_PlayThisTaunt", function(len, ply)
	local snd = net.ReadString()

	if IsValid(ply) && CanTaunt(ply) then
		if file.Exists("sound/" .. snd, "GAME") then
			ply:EmitSound(snd, 100)
			ply:SetNWFloat("NextCanTaunt", CurTime() + NewSoundDuration("sound/" .. snd))
		else
			ply:ChatPrint("[PH: Enhanced] - Failed to play taunt! (doesn't exist???)")
		end
	else
		ply:ChatPrint("[PH: Enhanced] - You're still playing a taunt. You can taunt again in ".. math.ceil(ply:GetNWFloat("NextCanTaunt",0) - CurTime()) .. " seconds.")
	end
end)
