-- Initialize the shared variable
PHE = PHE or {}
PHE.__index = PHE
-- set these important enums ASAP
TEAM_HUNTERS = 1
TEAM_PROPS = 2
-- Initialize and Add ConVar Blocks.
AddCSLuaFile("sh_convars.lua")
include("sh_convars.lua")
-- Language implementation
AddCSLuaFile("sh_language.lua")
include("sh_language.lua")
-- Some config stuff
AddCSLuaFile("config/sh_init.lua")
include("config/sh_init.lua")
-- ULX Mapvote
AddCSLuaFile("ulx/modules/sh/sh_phe_mapvote.lua")
include("ulx/modules/sh/sh_phe_mapvote.lua")
-- ULX Unstuck
AddCSLuaFile("ulx/modules/sh/sh_phe_unstuck.lua")
include("ulx/modules/sh/sh_phe_unstuck.lua")
-- Include the required lua files
AddCSLuaFile("sh_config.lua")
include("sh_config.lua")
include("sh_player.lua")
-- Add Sound Precaching Functions
AddCSLuaFile("sh_precache.lua")
include("sh_precache.lua")
-- Plugins! :D
PHE.PLUGINS = {}
AddCSLuaFile("sh_plugins.lua")
include("sh_plugins.lua")

-- MapVote
if SERVER then
    AddCSLuaFile("sh_mapvote.lua")
    AddCSLuaFile("mapvote/cl_mapvote.lua")
    include("sh_mapvote.lua")
    include("mapvote/sv_mapvote.lua")
    include("mapvote/rtv.lua")
else
    include("sh_mapvote.lua")
    include("mapvote/cl_mapvote.lua")
end

-- Fretta!
DeriveGamemode("fretta")
IncludePlayerClasses()
-- Information about the gamemode
GM.Name = "Prop Hunt: INFINITY"
GM.Author = "Wolvindra-Vinzuerio, D4UNKN0WNM4N2010, Fafy, Dralga & Zero w/ tweaks by Fasteroid"
GM._VERSION = "16"
GM.REVISION = "A"
GM.DONATEURL = "https://prophunt.wolvindra.net/?go=donate"
GM.UPDATEURL = ""
-- Format PHE.LANG.Help
PHE.LANG.Help = string.format(PHE.LANG.Help, GM._VERSION, GM.REVISION)
-- Fretta configuration
GM.GameLength = GetConVar("ph_game_time"):GetInt()
GM.AddFragsToTeamScore = true
GM.CanOnlySpectateOwnTeam = true

GM.ValidSpectatorModes = {OBS_MODE_CHASE, OBS_MODE_IN_EYE, OBS_MODE_ROAMING}

GM.Data = {}
GM.EnableFreezeCam = true
GM.NoAutomaticSpawning = true
GM.NoNonPlayerPlayerDamage = true
GM.NoPlayerPlayerDamage = true
GM.RoundBased = true
GM.RoundLimit = GetConVar("ph_rounds_per_map"):GetInt()
GM.RoundLength = GetConVar("ph_round_time"):GetInt()
GM.RoundPreStartTime = 0
GM.SuicideString = "was dead or died mysteriously." -- i think this one is pretty obsolete.
GM.TeamBased = true
GM.AutomaticTeamBalance = false
GM.ForceJoinBalancedTeams = true

-- Called on gamemdoe initialization to create teams
function GM:CreateTeams()
    if not GAMEMODE.TeamBased then return end
    team.SetUp(TEAM_HUNTERS, "Hunters", Color(150, 205, 255, 255))

    team.SetSpawnPoint(TEAM_HUNTERS, {"info_player_counterterrorist", "info_player_combine", "info_player_deathmatch", "info_player_axis"})

    team.SetClass(TEAM_HUNTERS, {"Hunter"})

    team.SetUp(TEAM_PROPS, "Props", Color(255, 60, 60, 255))

    team.SetSpawnPoint(TEAM_PROPS, {"info_player_terrorist", "info_player_rebel", "info_player_deathmatch", "info_player_allies"})

    team.SetClass(TEAM_PROPS, {"Prop"})
end

-- Check collisions
function CheckPropCollision(entA, entB)
    -- Disable prop on prop collisions
    if not GetConVar("ph_prop_collision"):GetBool() and entA and entB and (entA:IsPlayer() and entA:Team() == TEAM_PROPS and entB:IsValid() and entB:GetClass() == "ph_prop" or entB:IsPlayer() and entB:Team() == TEAM_PROPS and entA:IsValid() and entA:GetClass() == "ph_prop") then return false end
    -- Disable hunter on hunter collisions so we can allow bullets through them
    if IsValid(entA) and IsValid(entB) and entA:IsPlayer() and entA:Team() == TEAM_HUNTERS and entB:IsPlayer() and entB:Team() == TEAM_HUNTERS then return false end
end

hook.Add("ShouldCollide", "CheckPropCollision", CheckPropCollision)