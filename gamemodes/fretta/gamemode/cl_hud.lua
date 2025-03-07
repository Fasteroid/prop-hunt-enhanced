-- GAMEMODE.HudScreen // commented out so it works with autorefresh
local Alive = false
local Class = nil
local Team = 0
local WaitingToRespawn = false
local InRound = false
local RoundResult = 0
local RoundWinner = nil
local IsObserver = false
local ObserveMode = 0
local ObserveTarget = NULL
local InVote = false

function GM:AddHUDItem(item, pos, parent)
    GAMEMODE.HudScreen:AddItem(item, parent, pos)
end

function GM:HUDNeedsUpdate()
    local lp = LocalPlayer()
    if not IsValid(lp) then return false end
    if Class ~= lp:GetNW2String("Class", "Default") then return true end
    if Alive ~= lp:Alive() then return true end
    if Team ~= lp:Team() then return true end
    if WaitingToRespawn ~= (lp:GetNW2Float("RespawnTime", 0) > CurTime() and lp:Team() ~= TEAM_SPECTATOR and not lp:Alive()) then return true end
    if InRound ~= GetGlobalBool("InRound", false) then return true end
    if RoundResult ~= GetGlobalInt("RoundResult", 0) then return true end
    if RoundWinner ~= GetGlobalEntity("RoundWinner", nil) then return true end
    if IsObserver ~= lp:IsObserver() then return true end
    if ObserveMode ~= lp:GetObserverMode() then return true end
    if ObserveTarget ~= lp:GetObserverTarget() then return true end
    if InVote ~= GAMEMODE:InGamemodeVote() then return true end

    return false
end

function GM:OnHUDUpdated()
    local lp = LocalPlayer()
    Class = lp:GetNW2String("Class", "Default")
    Alive = lp:Alive()
    Team = lp:Team()
    WaitingToRespawn = lp:GetNW2Float("RespawnTime", 0) > CurTime() and lp:Team() ~= TEAM_SPECTATOR and not Alive
    InRound = GetGlobalBool("InRound", false)
    RoundResult = GetGlobalInt("RoundResult", 0)
    RoundWinner = GetGlobalEntity("RoundWinner", nil)
    IsObserver = lp:IsObserver()
    ObserveMode = lp:GetObserverMode()
    ObserveTarget = lp:GetObserverTarget()
    InVote = GAMEMODE:InGamemodeVote()
end

function GM:OnHUDPaint()
end

function GM:RefreshHUD()
    if not GAMEMODE:HUDNeedsUpdate() then return end
    GAMEMODE:OnHUDUpdated()

    if IsValid(GAMEMODE.HudScreen) then
        GAMEMODE.HudScreen:Remove()
    end

    GAMEMODE.HudScreen = vgui.Create("DHudLayout")
    if InVote then return end

    if RoundWinner and RoundWinner ~= NULL then
        GAMEMODE:UpdateHUD_RoundResult(RoundWinner, Alive)
    elseif RoundResult ~= 0 then
        GAMEMODE:UpdateHUD_RoundResult(RoundResult, Alive)
    elseif IsObserver then
        GAMEMODE:UpdateHUD_Observer(WaitingToRespawn, InRound, ObserveMode, ObserveTarget)
    elseif not Alive then
        GAMEMODE:UpdateHUD_Dead(WaitingToRespawn, InRound)
    else
        GAMEMODE:UpdateHUD_Alive(InRound)

        if GetGlobalBool("RoundWaitForPlayers") and (team.NumPlayers(TEAM_HUNTERS) < 1 or team.NumPlayers(TEAM_PROPS) < 1) then
            GAMEMODE:UpdateHUD_WaitForPlayers(InRound)
        end
    end
end

function GM:HUDPaint()
    self.BaseClass:HUDPaint()
    GAMEMODE:OnHUDPaint()
    GAMEMODE:RefreshHUD()
end

function GM:UpdateHUD_WaitForPlayers(InRound)
    if InRound and Alive then
        local WaitText = vgui.Create("DHudElement")
        WaitText:SizeToContents()
        WaitText:SetText(PHE.LANG.HUD.WAIT)
        GAMEMODE:AddHUDItem(WaitText, 8)
    end
end

function GM:UpdateHUD_RoundResult(RoundResult, Alive)
    local txt = GetGlobalString("RRText")

    if type(RoundResult) == "number" and team.GetAllTeams()[RoundResult] and txt == "" then
        local TeamName = team.GetName(RoundResult)

        if TeamName then
            txt = string.format(PHE.LANG.HUD.WIN, TeamName)
        end
    elseif type(RoundResult) == "Player" and IsValid(RoundResult) and txt == "" then
        txt = RoundResult:Name() .. " Wins!"
    end

    local RespawnText = vgui.Create("DHudElement")
    RespawnText:SizeToContents()
    RespawnText:SetText(txt)
    GAMEMODE:AddHUDItem(RespawnText, 8)
end

function GM:UpdateHUD_Observer(bWaitingToSpawn, InRound, ObserveMode, ObserveTarget)
    local lbl = nil
    local txt = nil
    local col = Color(255, 255, 255)

    if IsValid(ObserveTarget) and ObserveTarget:IsPlayer() and ObserveTarget ~= LocalPlayer() and ObserveMode ~= OBS_MODE_ROAMING then
        lbl = "SPECTATING"
        txt = ObserveTarget:Nick()
        col = team.GetColor(ObserveTarget:Team())
    end

    if ObserveMode == OBS_MODE_DEATHCAM or ObserveMode == OBS_MODE_FREEZECAM then
        txt = "You Died!" -- were killed by?
    end

    if txt then
        local txtLabel = vgui.Create("DHudElement")
        txtLabel:SetText(txt)

        if lbl then
            txtLabel:SetLabel(lbl)
        end

        txtLabel:SetTextColor(col)
        GAMEMODE:AddHUDItem(txtLabel, 2)
    end

    GAMEMODE:UpdateHUD_Dead(bWaitingToSpawn, InRound)
end

function GM:UpdateHUD_Dead(bWaitingToSpawn, InRound)
    if not InRound and GAMEMODE.RoundBased then
        local RespawnText = vgui.Create("DHudElement")
        RespawnText:SizeToContents()
        RespawnText:SetText(PHE.LANG.HUD.WAIT)
        GAMEMODE:AddHUDItem(RespawnText, 8)

        return
    end

    if bWaitingToSpawn then
        local RespawnTimer = vgui.Create("DHudCountdown")
        RespawnTimer:SizeToContents()

        RespawnTimer:SetValueFunction(function()
            return LocalPlayer():GetNW2Float("RespawnTime", 0)
        end)

        RespawnTimer:SetLabel("SPAWN IN")
        GAMEMODE:AddHUDItem(RespawnTimer, 8)

        return
    end

    --[[
	if ( InRound ) then

		local RoundTimer = vgui.Create( "DHudCountdown" );
			RoundTimer:SizeToContents()
			RoundTimer:SetValueFunction( function()
											if ( GetGlobalFloat( "RoundStartTime", 0 ) > CurTime() ) then return GetGlobalFloat( "RoundStartTime", 0 )  end
											return GetGlobalFloat( "RoundEndTime" ) end )
			RoundTimer:SetLabel( "TIME" )
		GAMEMODE:AddHUDItem( RoundTimer, 8 )
		return

	end
	]]
    --
    local Bar = vgui.Create("DHudBar")
    GAMEMODE:AddHUDItem(Bar, 8)

    -- This should show on dead players too
    if InRound then
        local TeamIndicator_Name_AddString = "(DEAD) "

        if LocalPlayer():Team() == TEAM_SPECTATOR then
            TeamIndicator_Name_AddString = ""
        end

        local TeamIndicator = vgui.Create("DHudUpdater")
        TeamIndicator:SizeToContents()

        TeamIndicator:SetValueFunction(function()
            return TeamIndicator_Name_AddString .. "" .. team.GetName(LocalPlayer():Team())
        end)

        TeamIndicator:SetColorFunction(function()
            return team.GetColor(LocalPlayer():Team())
        end)

        TeamIndicator:SetFont("HudSelectionText")
        Bar:AddItem(TeamIndicator)
        local RoundNumber = vgui.Create("DHudUpdater")
        RoundNumber:SizeToContents()

        RoundNumber:SetValueFunction(function()
            return GetGlobalInt("RoundNumber", 0)
        end)

        RoundNumber:SetLabel(PHE.LANG.HUD.ROUND)
        Bar:AddItem(RoundNumber)
        local RoundTimer = vgui.Create("DHudCountdown")
        RoundTimer:SizeToContents()

        RoundTimer:SetValueFunction(function()
            if GetGlobalFloat("RoundStartTime", 0) > CurTime() then return GetGlobalFloat("RoundStartTime", 0) end

            return GetGlobalFloat("RoundEndTime")
        end)

        RoundTimer:SetLabel(PHE.LANG.HUD.TIME)
        Bar:AddItem(RoundTimer)
    end

    if Team ~= TEAM_SPECTATOR and not Alive and not GAMEMODE.RoundBased then
        local RespawnText = vgui.Create("DHudElement")
        RespawnText:SizeToContents()
        RespawnText:SetText("Press Fire to Spawn")
        GAMEMODE:AddHUDItem(RespawnText, 8)
    end
end

function GM:UpdateHUD_Alive(InRound)
    if GAMEMODE.RoundBased or GAMEMODE.TeamBased then
        local Bar = vgui.Create("DHudBar")
        GAMEMODE:AddHUDItem(Bar, 2)

        if GAMEMODE.TeamBased and GAMEMODE.ShowTeamName then
            local TeamIndicator = vgui.Create("DHudUpdater")
            TeamIndicator:SizeToContents()

            TeamIndicator:SetValueFunction(function()
                return team.GetName(LocalPlayer():Team())
            end)

            TeamIndicator:SetColorFunction(function()
                return team.GetColor(LocalPlayer():Team())
            end)

            TeamIndicator:SetFont("HudSelectionText")
            Bar:AddItem(TeamIndicator)
        end

        if GAMEMODE.RoundBased then
            local RoundNumber = vgui.Create("DHudUpdater")
            RoundNumber:SizeToContents()

            RoundNumber:SetValueFunction(function()
                return GetGlobalInt("RoundNumber", 0)
            end)

            RoundNumber:SetLabel(PHE.LANG.HUD.ROUND)
            Bar:AddItem(RoundNumber)
            local RoundTimer = vgui.Create("DHudCountdown")
            RoundTimer:SizeToContents()

            RoundTimer:SetValueFunction(function()
                if GetGlobalFloat("RoundStartTime", 0) > CurTime() then return GetGlobalFloat("RoundStartTime", 0) end

                return GetGlobalFloat("RoundEndTime")
            end)

            RoundTimer:SetLabel(PHE.LANG.HUD.TIME)
            Bar:AddItem(RoundTimer)
        end
    end
end
--[[
	this thing is obsolete/depcretaed. Sorry!

function GM:UpdateHUD_AddedTime( iTimeAdded )
	// to do or to override, your choice
end
usermessage.Hook( "RoundAddedTime", function( um ) if( GAMEMODE && um ) then GAMEMODE:UpdateHUD_AddedTime( um:ReadFloat() ) end end )
]]
--