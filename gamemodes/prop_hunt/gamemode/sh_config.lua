
-- Time (in seconds) for spectator check (Default: 0.1)
PHE.SPECTATOR_CHECK_ADD = 0.1

PHE.USABLE_PROP_ENTITIES = {
	"prop_physics",
	"prop_physics_multiplayer"
}

-- Configure your staff admin/mod or donator rank (vip/donator) to the ignore mute list so they cannot be muted for a reason.
PHE.IgnoreMutedUserGroup = {
	-- admin
	"superadmin",
	"admin"
}

-- Admin Staffs table for sv_admin.lua, which enables to modify gamemode settings under F1 > Prop Hunt Menu > Admin menu.
PHE.SVAdmins = {
	"admin",
	"superadmin",
	"owner"
}

-- Banned Props models
PHE.BANNED_PROP_MODELS = {}

-- Custom Player Model bans for props
PHE.PROP_PLMODEL_BANS = {
	"models/player.mdl"
}

PHE.WINNINGSOUNDS = {
	[1] 		= "misc/ph_hunterwin.mp3", 	-- hunter
	[2]			= "misc/ph_propwin.mp3",	-- props
	["Draw"]	= {"misc/ph_rounddraw_1.mp3", "misc/ph_rounddraw_2.mp3"}
}

-- Add the custom player model bans for props AND prop banned models
if SERVER then
	if ( !file.Exists( "phe_config", "DATA" ) ) then
		printVerbose("[PH: Enhanced] Warning: ./data/phe_config/ does not exist. Creating New One...")
		file.CreateDir( "phe_config" )
	end

	local function AddBadPLModels()

		local dir = "phe_config/prop_plymodel_bans"

		-- Create base config area
		if ( !file.Exists( dir, "DATA" ) ) then
			file.CreateDir( dir )
		end

		-- Create actual config
		if ( !file.Exists( dir .. "/bans.txt", "DATA" ) ) then
			file.Write( dir .. "/bans.txt", util.TableToJSON({"models/player.mdl"}, true) )
		end

		if ( file.Exists( dir .. "/bans.txt", "DATA" ) ) then

			local PROP_PLMODEL_BANS_READ = util.JSONToTable( file.Read( dir .. "/bans.txt", "DATA" ) )

			-- empty the table instead
			table.Empty(PHE.PROP_PLMODEL_BANS)

			for _, v in pairs(PROP_PLMODEL_BANS_READ) do
				printVerbose("[PH:E PlayerModels] Adding custom prop player model ban --> " .. string.lower(v))
				table.insert(PHE.PROP_PLMODEL_BANS, string.lower(v))
			end
		else

			printVerbose("[PH: Enhanced] Cannot read " .. dir .. "/bans.txt: Error - did not exist. Did you just delete it or what?")

		end

	end
	hook.Add("Initialize", "PHE.AddBadPlayerModels", AddBadPLModels)

	local function AddBannedPropModels()
		local dir = "phe_config/prop_model_bans"

		local mdlpermabans = {
			"models/props/cs_assault/dollar.mdl",
			"models/props/cs_assault/money.mdl",
			"models/props/cs_office/snowman_arm.mdl",
			"models/props/cs_office/computer_mouse.mdl",
			"models/props/cs_office/projector_remote.mdl",
			"models/foodnhouseholditems/egg.mdl",
			"models/props/cs_militia/reload_bullet_tray.mdl"
		}

		if ( !file.Exists(dir, "DATA") ) then
			file.CreateDir(dir)
		end

		if ( !file.Exists(dir .. "/model_bans.txt","DATA") ) then
			file.Write( dir .. "/model_bans.txt", util.TableToJSON( mdlpermabans, true ))
		end

		if ( file.Exists ( dir .. "/model_bans.txt","DATA" ) ) then
			local PROP_MODEL_BANS_READ = util.JSONToTable(file.Read(dir .. "/model_bans.txt"))
			-- empty the tables anyway.
			table.Empty(PHE.BANNED_PROP_MODELS)
			for _,v in pairs(PROP_MODEL_BANS_READ) do
				printVerbose("[PH:E Model Bans] Adding entry of restricted model to be used --> " .. string.lower(v))
				table.insert(PHE.BANNED_PROP_MODELS, string.lower(v))
			end
		else
			printVerbose("[PH: Enhanced] Cannot read " .. dir .. "/model_bans.txt: Error - did not exist. Did you just delete it or what?")
		end
	end
	hook.Add("Initialize", "PHE.AddBannedPropModels", AddBannedPropModels)

	-- Add ConCommands.
	concommand.Add("phe_refresh_plmodel_ban", AddBadPLModels, nil, "Refresh Server Playermodel Ban Lists, read from prop_plymodel_bans/bans.txt data.", FCVAR_SERVER_CAN_EXECUTE)
	concommand.Add("phe_refresh_propmodel_ban", AddBannedPropModels, nil, "Refresh Server Prop Models Ban Lists, read from prop_model_bans/model_bans.txt data.", FCVAR_SERVER_CAN_EXECUTE)
end
