surface.CreateFont("PHE.HealthFont",
{
	font = "Roboto",
	size = 56,
	weight = 650,
	antialias = true,
	shadow = true
})

surface.CreateFont("PHE.AmmoFont",
{
	font = "Roboto",
	size = 86,
	weight = 500,
	antialias = true,
	shadow = true
})

surface.CreateFont("PHE.ArmorFont",
{
	font = "Roboto",
	size = 32,
	weight = 500,
	antialias = true,
	shadow = true
})

surface.CreateFont("PHE.TopBarFont",
{
	font = "Roboto",
	size = 20,
	weight = 500,
	antialias = true,
	shadow = true
})
surface.CreateFont("PHE.TopBarFontTeam",
{
	font = "Roboto",
	size = 60,
	weight = 650,
	antialias = true,
	shadow = true
})
surface.CreateFont("PHE.Trebuchet",
{
	font = "Trebuchet MS",
	size = 24,
	weight = 900,
	antialias = true,
	shadow = true
})

-- Hides HUD
local hide = {
	["CHudHealth"] 	= true,
	["CHudBattery"] = true,
	["CHudAmmo"]	= true,
	["CHudSecondaryAmmo"] = true
}

local curteam
local hudtopbar = {
	mat = Material("vgui/phehud/hud_topbar"),
	x	= 0,
	y	= 60
}
local matw = Material("vgui/phehud/res_wep")

local ava
local pos = { x = 0, y = ScrH() - 130 }
local posw = { x = ScrW() - 480, y = ScrH() - 130 }
local hp
local armor
local hpcolor

local bar = {
	hp = { h = 5, col = Color(250,40,10,240) },
	am = { h = 5, col = Color(80,190,255,220) }
}

hook.Add("HUDShouldDraw", "PHE.ShouldHideHUD", function(hudname)
	if GetConVar("ph_hud_use_new"):GetBool() && !matw:IsError () && hide[hudname] then
		return false
	end
end)

local function PopulateAliveTeam(tm)
	local tim = team.GetPlayers(tm)
	local liveply = liveply || 0

	for _,pl in pairs(tim) do
		if IsValid(pl) && pl:Alive() then liveply = liveply + 1 end
	end

	return liveply
end

local state = false
local disabledcolor = Color(100,100,100,255)

local matb = {
	[TEAM_HUNTERS] = Material("vgui/phehud/res_hp_1"), -- shame on you for not using the enums, wolvin
	[TEAM_PROPS] =	 Material("vgui/phehud/res_hp_2")
}

local SPOT_GLOW_TIME = GetConVar("ph_spot_highlight_time"):GetFloat()

local ICON_START = 168
local ICON_WIDTH = 48
local icons = {
	[TEAM_HUNTERS] = {
		armor = { 
			mat = Material("vgui/phehud/i_shield"),	
			[false] = Color(120,120,120,255), 
			[true] 	= Color(80,190,255,255),
			state 	= function() return LocalPlayer():Armor() > 0 end
		},
		spotting = {
			mat		= Material("vgui/phehud/i_spot.png"), -- to replace
			[false]	= Color(120,120,120,255), 
			[true]	= Color(255,255,255,255),
			state   = function() return LocalPlayer():GetNWFloat("PH:Infinity.SpotCooldown", 0) < CurTime() end
		}
	},
	[TEAM_PROPS] = {
		rotate = { 
			mat		= Material("vgui/phehud/i_rotate"), 
			[false]	= Color(120,120,120,255), 
			[true]	= Color(255,255,0,255),
			state   = function() return LocalPlayer():GetNWBool("PlayerLockedRotation", false) end
		},
		spotted = {
			mat		= Material("vgui/phehud/i_spot.png"), -- to replace
			[false]	= Color(120,120,120,255), 
			[true]	= Color(255,100,50,255),
			state   = function() return (CurTime() - (GLOBAL_LOCAL_LASTSPOTTED or 0) ) < SPOT_GLOW_TIME end
		}
	}
}


-- local indic = {
-- 	rotate 	= { mat = Material("vgui/phehud/i_rotate"), [0]	= Color(190,190,190,255), [1] = Color(255,255,0,255) },
-- 	halo 	= { mat = Material("vgui/phehud/i_halo"), 	[0]	= Color(190,190,190,255), [1] = Color(0,255,0,255) },
-- 	light 	= { mat = Material("vgui/phehud/i_light"), 	[0]	= Color(190,190,190,255), [1] = Color(255,255,0,255) },
-- 	armor	= { mat = Material("vgui/phehud/i_shield"),	[0] = Color(190,190,190,255), [1] = Color(80,190,255,255) }
-- }

hook.Add("HUDPaint", "PHE.MainHUD", function()

	if GetConVar("ph_hud_use_new"):GetBool() then state = true else state = false end;

	-- Don't draw if materials didn't load correctly
	if matw:IsError () && state then
		state = false
	end

	if IsValid(LocalPlayer()) && LocalPlayer():Alive() && state && (LocalPlayer():Team() == TEAM_HUNTERS || LocalPlayer():Team() == TEAM_PROPS) then
		-- Begin Player Info
		if !IsValid(ava) then
			ava = vgui.Create("AvatarMask")
			ava:SetPos(16, pos.y + 18)
			ava:SetSize(86,86)
			ava:SetPlayer(LocalPlayer(),128)
			ava:SetVisible(true)
		end

		-- Player Info
		curteam = LocalPlayer():Team()
		hp = LocalPlayer():Health()
		armor = LocalPlayer():Armor()

		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.SetMaterial( matb[curteam] )
		surface.DrawTexturedRect( pos.x, pos.y, 480, 120 )

		draw.DrawText( PHE.LANG.HUD.HEALTH, "PHE.Trebuchet", pos.x + 175, pos.y + 14, color_white, TEXT_ALIGN_LEFT )

		if hp < 0 then hp = 0 end
		if armor < 0 then armor = 0 end

		if hp < 30 then
			hpcolor = Color( 255, 1 * (hp * 8), 1 * (hp * 8), 255 )
		else
			hpcolor = Color( 255, 255, 255, 255 )
		end

		-- hp bar
		if hp > 100 then hpx = 100 else hpx = hp end
		if armor > 100 then armx = 100 else armx = armor end

		surface.SetDrawColor(bar.hp.col)
		surface.DrawRect(pos.x + 175, pos.y + 57, 1 * (hpx * 2.9), bar.hp.h)

		surface.SetDrawColor(bar.am.col)
		surface.DrawRect(pos.x + 175, pos.y + 62, 1 * (armx * 2.9), bar.am.h)

		draw.DrawText( hp, "PHE.HealthFont", pos.x + 350, pos.y - 4, hpcolor, TEXT_ALIGN_RIGHT )
		draw.DrawText( " / " .. armor, "PHE.ArmorFont", pos.x + 350, pos.y + 14, Color( 255,255,255,255 ), TEXT_ALIGN_LEFT )

		local iconset = icons[ LocalPlayer():Team() ]

		local offset = ICON_START
		for k, ico in pairs(iconset) do
			surface.SetDrawColor( ico[ ico.state() ] )
			surface.SetMaterial( ico.mat )
			surface.DrawTexturedRect( pos.x + offset, pos.y + 74, 32, 32 )
			offset = offset + ICON_WIDTH
		end

	end

	-- Weapon HUD
	if IsValid(LocalPlayer()) && LocalPlayer():Alive() && state && LocalPlayer():Team() == TEAM_HUNTERS then
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.SetMaterial( matw )
		surface.DrawTexturedRect( posw.x, posw.y, 480, 120 )

		local curWep = LocalPlayer():GetActiveWeapon()

		local clip
		local maxclip
		local mag
		local mag2
		local name
		local percent

		draw.DrawText( PHE.LANG.HUD.AMMO, "PHE.Trebuchet", posw.x + 318, posw.y + 14, color_white, TEXT_ALIGN_RIGHT )

		if IsValid(curWep) then
			clip 	= curWep:Clip1()
			maxclip = curWep:GetMaxClip1()
			mag 	= LocalPlayer():GetAmmoCount(curWep:GetPrimaryAmmoType())
			mag2	= LocalPlayer():GetAmmoCount(curWep:GetSecondaryAmmoType())
			name	= language.GetPhrase(curWep:GetPrintName())

			if clip < 0 then clip = 0 end
			if maxclip < 0 then maxclip = 0 end

			if (clip < 0 || maxclip < 0) then
				percent = 0
			else
				percent = math.Round(clip / maxclip * 300)
			end

			surface.SetDrawColor(255,200,15,255)
			surface.DrawRect(posw.x + 8, posw.y + 58, percent, 8)

			draw.DrawText( clip, "PHE.HealthFont", posw.x + 136, posw.y -4, color_white, TEXT_ALIGN_RIGHT )
			draw.DrawText( " / " .. mag, "PHE.ArmorFont", posw.x + 136, posw.y + 14, color_white, TEXT_ALIGN_LEFT )
			draw.DrawText( mag2, "PHE.AmmoFont", ScrW() - 58, posw.y + 14, 		color_white, TEXT_ALIGN_CENTER )
			draw.DrawText( name, "PHE.TopBarFont", posw.x + 136, posw.y + 80, 	color_white, TEXT_ALIGN_LEFT )

		end
	end

	if IsValid(LocalPlayer()) && !LocalPlayer():Alive() && IsValid(ava) then
		ava:SetVisible(false)
		ava:Remove()
	end
	if IsValid(LocalPlayer()) && !state && IsValid(ava) then
		ava:SetVisible(false)
		ava:Remove()
	end
	if IsValid(LocalPlayer()) && (LocalPlayer():Team() == TEAM_SPECTATOR || LocalPlayer():Team() == TEAM_UNASSIGNED) && IsValid(ava) then
		ava:SetVisible(false)
		ava:Remove()
	end

	-- the Team Bar. This requires at least 4 players to get this displayed.
	if GetConVar("ph_show_team_topbar"):GetBool() && ((player.GetCount() >= 4 && LocalPlayer():Alive()) && (LocalPlayer():Team() != TEAM_UNASSIGNED && LocalPlayer():Team() != TEAM_SPECTATOR)) then
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.SetMaterial( hudtopbar.mat )
		surface.DrawTexturedRect( hudtopbar.x, hudtopbar.y, 400, 50 )

		-- Draw Props
		draw.DrawText( "Props", "PHE.TopBarFont", 4, hudtopbar.y + 2, Color(255,255,255,255), TEXT_ALIGN_LEFT )
		draw.DrawText( tostring(PopulateAliveTeam(TEAM_PROPS)), "PHE.TopBarFontTeam", 96, hudtopbar.y - 8, Color(255,255,255,255), TEXT_ALIGN_LEFT )

		-- Draw Hunters
		draw.DrawText( "Hunter", "PHE.TopBarFont", 300, hudtopbar.y + 22, Color(255,255,255,255), TEXT_ALIGN_LEFT )
		draw.DrawText( tostring(PopulateAliveTeam(TEAM_HUNTERS)), "PHE.TopBarFontTeam", 220, hudtopbar.y - 8, Color(255,255,255,255), TEXT_ALIGN_LEFT )
	end
end)