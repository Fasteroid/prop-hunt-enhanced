surface.CreateFont("PHE.TauntFont",
{
	font = "Roboto",
	size = 16,
	weight = 500,
	antialias = true,
	shadow = false
})

local isplayed = false
local isopened = false
local isforcedclose = false
local hastaunt = false

local lastcategory = nil
local lastteam = nil

net.Receive("PH_ForceCloseTauntWindow", function()
	isforcedclose = true
end)

net.Receive("PH_AllowTauntWindow", function()
	isforcedclose = false
end)

local function SendTaunt(snd)
	net.Start("CL2SV_PlayThisTaunt")
		net.WriteString(tostring(snd))
	net.SendToServer();
end

local function MainFrame()
	if GetConVar("ph_enable_custom_taunts"):GetInt() < 1 then
		return
	end

	isopened = true

	if( LocalPlayer():Team() ~= lastteam ) then 
		lastcategory = nil 
		lastteam = LocalPlayer():Team()
	end

	local frame = vgui.Create("DFrame")
	frame:SetSize(400,600)
	frame:SetTitle("Prop Hunt | Taunt Menu")
	frame:Center()
	frame:SetVisible(true)
	frame:ShowCloseButton(true)
	-- Make sure they have Mouse & Keyboard interactions.
	frame:SetMouseInputEnabled(true)
	frame:SetKeyboardInputEnabled(true)

	frame.Paint = function(self,w,h)
		surface.SetDrawColor(Color(40,40,40,180))
		surface.DrawRect(0,0,w,h)
	end

	frame.OnClose = function()
		isopened = false
		hastaunt = false
	end

	-- removing this was dumb on my part
	-- TODO: modify this behavior directly in init.lua
	--[[
		local function frame_Think_Force()
			if isforcedclose == true && isopened == true then
				isopened = false
				hastaunt = false
				frame:Close()
			end
		end
		hook.Add("Think", "CloseWindowFrame_Force", frame_Think_Force)
	]]--

	local list = vgui.Create("DListView", frame)

	list:SetMultiSelect(false)
	list:AddColumn("soundlist") -- because header is gone.
	list.m_bHideHeaders = true
	list:SetPos(10,52)
	list:SetSize(0,450)
	list:Dock(BOTTOM)

	local TEAM_TAUNTS = PHE:GetTeamTaunt( LocalPlayer():Team() )
	local WHOLE_TEAM_TAUNTS = PHE:GetAllTeamTaunt( LocalPlayer():Team() )

	local comb = vgui.Create("DComboBox", frame)

	comb:Dock(TOP)
	comb:SetSize(0, 20)

	function comb:SortAndStyle(pnl)
		pnl:SortByColumn(1,false)

		pnl.Paint = function(self,w,h)
			surface.SetDrawColor(Color(50,50,50,180))
			surface.DrawRect(0,0,w,h)
		end

		local color =
		{
			hover 	= Color(80,80,80,200),
			select 	= Color(120,120,120,255),
			alt		= Color(60,60,60,180),
			normal 	= Color(50,50,50,180)
		}

		for _,line in pairs( pnl:GetLines() ) do
			function line:Paint( w, h )
				if ( self:IsHovered() ) then
					surface.SetDrawColor(color.hover)
				elseif ( self:IsSelected() ) then
					surface.SetDrawColor(color.select)
				elseif ( self:GetAltLine() ) then
					surface.SetDrawColor(color.alt)
				else
					surface.SetDrawColor(color.normal)
				end
				surface.DrawRect(0,0,w,h)
			end
			for _,col in pairs(line["Columns"]) do
				col:SetFont("PHE.TauntFont")
				col:SetTextColor(color_white)
			end
		end
	end

	comb.OnSelect = function(pnl, idx, val)
		list:Clear()
		hastaunt = false
		lastcategory = val
		if TEAM_TAUNTS and TEAM_TAUNTS[val] then
			for name, _ in pairs(TEAM_TAUNTS[val]) do
				list:AddLine(name)
			end
		end
		pnl:SortAndStyle(list)
	end

	for group, tbl in pairs(TEAM_TAUNTS) do
		comb:AddChoice(group)
	end

	if LocalPlayer():Team() == TEAM_HUNTERS then
		lastcategory = lastcategory or "searching"
	else
		lastcategory = lastcategory or "annoying"
	end

	comb:SetValue(lastcategory)
	comb.OnSelect(comb,0,lastcategory)

	-- I know, this one is fixed style.
	local btnpanel = vgui.Create("DPanel", frame)
	btnpanel:Dock(FILL)
	btnpanel:SetBackgroundColor(Color(20,20,20,200))

	local function CreateStyledButton(dock,size,ttip,margin,texture,imagedock, btnfunction)
		local left,top,right,bottom = margin[1],margin[2],margin[3],margin[4]

		local button = vgui.Create("DButton", btnpanel)
		button:Dock(dock)
		button:SetSize(size,0)
		button:DockMargin(left,top,right,bottom)
		button:SetText("")
		button:SetTooltip(ttip)

		button.Paint = function(self,w,h)
			if self:IsHovered() then
				surface.SetDrawColor(Color(90,90,90,200))
			else
				surface.SetDrawColor(Color(0,0,0,0))
			end
			surface.DrawRect(0,0,w,h)
		end

		button.DoClick = btnfunction

		local image = vgui.Create("DImage", button)
		image:SetImage(texture)
		image:Dock(imagedock)
	end

	local function TranslateTaunt(linename)
		return WHOLE_TEAM_TAUNTS[linename]
	end

	CreateStyledButton(LEFT,86,"Play Taunt Locally",{5,5,5,5},"vgui/phehud/btn_play.vmt",FILL, function()
		if hastaunt then
			local getline = TranslateTaunt(list:GetLine(list:GetSelectedLine()):GetValue(1))
			surface.PlaySound(getline)
		end
	end)
	CreateStyledButton(LEFT,86,"Play Taunt Globally",{5,5,5,5}, "vgui/phehud/btn_playpub.vmt",FILL, function()
		if hastaunt then
			local getline = TranslateTaunt(list:GetLine(list:GetSelectedLine()):GetValue(1))
			SendTaunt(getline)
		end
	end)
	CreateStyledButton(LEFT,86,"Play Taunt Globally and Close",{5,5,5,5},"vgui/phehud/btn_playx.vmt",FILL, function()
		if hastaunt then
			local getline = TranslateTaunt(list:GetLine(list:GetSelectedLine()):GetValue(1))

			SendTaunt(getline)
			frame:Close()
		end
	end)
	CreateStyledButton(FILL,86,"Close the Window",{5,5,5,5},"vgui/phehud/btn_close.vmt",FILL, function()
		frame:Close()
	end)

	list.OnRowRightClick = function(panel,line)
		hastaunt = true
		local getline = TranslateTaunt(list:GetLine(list:GetSelectedLine()):GetValue(1))

		local menu = DermaMenu()
		menu:AddOption("Play (Local)", function() surface.PlaySound(getline); print("Playing: " .. getline); end):SetIcon("icon16/control_play.png")
		menu:AddOption("Play (Global)", function() SendTaunt(getline); end):SetIcon("icon16/sound.png")
		menu:AddOption("Play and Close (Global)", function() SendTaunt(getline); frame:Close(); end):SetIcon("icon16/sound_delete.png")
		menu:AddSpacer()
		menu:AddOption("Close Menu", function() frame:Close(); end):SetIcon("icon16/cross.png")
		menu:Open()
	end

	list.OnRowSelected = function()
		hastaunt = true
	end

	list.DoDoubleClick = function(id,line)
		hastaunt = true
		local getline = TranslateTaunt(list:GetLine(list:GetSelectedLine()):GetValue(1))
		SendTaunt(getline)

		if GetConVar("ph_cl_autoclose_taunt"):GetBool() then frame:Close(); end
	end

	frame:MakePopup()
	frame:SetKeyboardInputEnabled(false)
end

---- concommand for playing taunts directly ----
local function trimToDepth(str, depth)
	local explode = string.Explode("/",str)
	if depth > #explode then return end
	return table.concat(explode, "/", 1, depth)
end

local function ConCommand_FilterAdd(pool, items, filter)
	local depth = #string.Explode("/",filter)
	local cache = {}
	for k, v in ipairs(items) do
		v = trimToDepth(v, depth)
		if not v then return end
		if string.StartWith(v, filter) and not cache[v] then
			cache[v] = true
			table.insert(pool, "ph_taunt " .. v)
		end
	end
end

local function ConCommand_SendTaunt(ply, cmd, args)
	SendTaunt(args[1])
end

local hint = false
local function ConCommand_Autocomplete(cmd, stringargs) -- this isn't perfect by any means, but it works

	if not hint then 
		local menu = Color(200,200,200)
		local auto = Color(150,255,255)
		local user = Color(255,255,150)
		local whit = Color(255,255,255)
		MsgC( menu, "┌────────────────────────────────────────────────┐\n" ) -- 48
		MsgC( menu, "│                                                │\n" ) -- 48
		MsgC( menu, "│    ", whit, "Incremental autocomplete example usage:", menu, "     │\n" )
		MsgC( menu, "│     ", user, "ph_taunt ", auto, "props", user, "/", auto, "miscellaneous", user, "/", auto, "bruh.mp3", menu, "      │\n" )
		MsgC( menu, "│", user,"                   ^             ^              ", menu, "│\n" ) -- 48
		MsgC( menu, "│   ", user, "██ - type to advance     ", auto, "██ - tab to fill", menu, "    │\n")
		MsgC( menu, "│                                                │\n" ) -- 48
		MsgC( menu, "└────────────────────────────────────────────────┘\n" ) -- 48
		hint = true
	end

	stringargs = string.sub(stringargs, 2) or "'"
	local options = {}
	
	if LocalPlayer():Team() == TEAM_PROPS then
		ConCommand_FilterAdd(options, PHE.TAUNTS.PROPS_CONCOMMAND, stringargs)
		ConCommand_FilterAdd(options, PHE.TAUNTS.HUNTERS_CONCOMMAND, stringargs)
	else
		ConCommand_FilterAdd(options, PHE.TAUNTS.HUNTERS_CONCOMMAND, stringargs)
		ConCommand_FilterAdd(options, PHE.TAUNTS.PROPS_CONCOMMAND, stringargs)
	end

	return options
end

concommand.Add("ph_taunt", ConCommand_SendTaunt, ConCommand_Autocomplete)

---- concommand for menu ----
concommand.Add("ph_showtaunts", function()
	if LocalPlayer():Alive() && LocalPlayer():GetObserverMode() == OBS_MODE_NONE then
		if isopened != true then
			MainFrame()
		end
	else
		chat.AddText("You can only taunt when you're alive.")
	end
end, nil, "Show Prop Hunt taunt list, so you can select and play for self or play as a taunt.")

---- run menu concommand on context menu bind ----
local function BindPress(ply, bind, pressed)
	if string.find(bind, "+menu_context") && pressed then
		RunConsoleCommand("ph_showtaunts")
	end
end
hook.Add("PlayerBindPress", "PlayerBindPress_menuContext", BindPress)
-- init.lua