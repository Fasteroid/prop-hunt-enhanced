AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName = "Prop Entity"
ENT.Author = "Wolvindra-Vinzuerio"
ENT.Information	= "A prop entity for Prop Hunt: Enhanced"
ENT.Category = ""
ENT.Editable = true
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_BOTH

local function UpdatePropTransforms(ply, prop, pos, angle)
	if not IsValid(ply) or not ply:Alive() then return end
	
	if not ply:GetPlayerLockedRot() then prop:SetAngles(Angle(0,angle.y,0)) end
	if prop:GetModel() == "models/player/kleiner.mdl" then
		prop:SetPos(pos)
	else
		local offset = prop:OBBCenter()
		offset[3] = 0
		offset:Rotate( prop:GetAngles() )
		prop:SetPos(pos - Vector(0, 0, prop:OBBMins().z) - offset)
	end	
end

function ENT:SetupDataTables() end

if CLIENT then

	function ENT:Draw()
		self:DrawModel()
	end

	function ENT:Think()
		local pl = self:GetOwner()
		if pl == LocalPlayer() then
			local me  = LocalPlayer()
			UpdatePropTransforms(pl, self, me:GetPos(), me:GetAngles())
		end
	end

end

if SERVER then

	function ENT:Initialize()
		self:SetModel("models/player/kleiner.mdl")
		self:SetLagCompensated(true)			
		self:SetMoveType(MOVETYPE_NONE)
		self.health = 100
	end

	-- sh_drive_prop.lua
	hook.Add("Move", "moveProp", function(ply, move)
		if ply:Team() == TEAM_PROPS then

			local ent = ply.ph_prop
			if IsValid(ent) then
				UpdatePropTransforms(ply, ent, move:GetOrigin(), move:GetAngles())
			end

		end
	end)
	
	-- Transmit update
	function ENT:UpdateTransmitState()
		return TRANSMIT_ALWAYS
	end
	
	-- Main Function
	function ENT:OnTakeDamage(dmg)
		local pl = self:GetOwner()
		local attacker = dmg:GetAttacker()
		local inflictor = dmg:GetInflictor()

		-- Health
		if GAMEMODE:InRound() && IsValid(pl) && pl:Alive() && pl:IsPlayer() && attacker:IsPlayer() && dmg:GetDamage() > 0 then
			if pl:Armor() >= 10 then
				self.health = self.health - (math.Round(dmg:GetDamage()/2))
				pl:SetArmor(pl:Armor() - 20)
			else
				self.health = self.health - dmg:GetDamage()
			end
			pl:SetHealth(self.health)
			
			if self.health <= 0 then
				pl:KillSilent()
				pl:SetArmor(0)
				
				if inflictor && inflictor == attacker && inflictor:IsPlayer() then
					inflictor = inflictor:GetActiveWeapon()
					if !inflictor || inflictor == NULL then inflictor = attacker end
				end
				
				net.Start( "PlayerKilledByPlayer" )
			
				net.WriteEntity( pl )
				net.WriteString( inflictor:GetClass() )
				net.WriteEntity( attacker )
			
				net.Broadcast()

		
				MsgAll(attacker:Name() .. " found and killed " .. pl:Name() .. "\n") 

				if GetConVar("ph_freezecam"):GetBool() then
					if pl:GetNWBool("InFreezeCam", false) then
						pl:PrintMessage(HUD_PRINTCONSOLE, "!! WARNING: Something went wrong with the Freeze Camera, but it's still enabled!")
					else
						timer.Simple(0.5, function()
							if !pl:GetNWBool("InFreezeCam", false) then
								-- Play the good old Freeze Cam sound
								net.Start("PlayFreezeCamSound")
								net.Send(pl)
							
								pl:SetNWEntity("PlayerKilledByPlayerEntity", attacker)
								pl:SetNWBool("InFreezeCam", true)
								pl:SpectateEntity( attacker )
								pl:Spectate( OBS_MODE_FREEZECAM )
							end
						end)
						
						timer.Simple(4.5, function()
							if pl:GetNWBool("InFreezeCam", false) then
								pl:SetNWBool("InFreezeCam", false)
								pl:Spectate( OBS_MODE_CHASE )
								pl:SpectateEntity( nil )
							end
						end)
					end
				end
				
				attacker:AddFrags(1)
				pl:AddDeaths(1)
				attacker:SetHealth(math.Clamp(attacker:Health() + GetConVarNumber("ph_hunter_kill_bonus"), 1, 100))
				
				hook.Call("PH_OnPropKilled", nil, pl, attacker)			
				pl:RemoveProp()
			end
		end
	end
	
end