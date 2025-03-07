local meta = FindMetaTable("Player")
if not meta then return end

function meta:SetPlayerClass(strName)
    self:SetNW2String("Class", strName)
    local c = player_class.Get(strName)

    if not c then
        MsgN("Warning: Player joined undefined class (", strName, ")")
    end
end

function meta:GetPlayerClassName()
    return self:GetNW2String("Class", "Default")
end

function meta:GetPlayerClass()
    -- Class that has been set using SetClass
    local ClassName = self:GetPlayerClassName()
    local c = player_class.Get(ClassName)
    if c then return c end
    -- Class based on their Team
    local c = player_class.Get(self:Team())
    if c then return c end
    -- If all else fails, use the default
    local c = player_class.Get("Default")
    if c then return c end
end

function meta:SetRandomClass()
    local Classes = team.GetClass(self:Team())

    if Classes then
        local Class = table.Random(Classes)
        self:SetPlayerClass(Class)

        return
    end
end

function meta:CheckPlayerClassOnSpawn()
    local Classes = team.GetClass(self:Team())

    -- The player has requested to spawn as a new class
    if self.m_SpawnAsClass then
        self:SetPlayerClass(self.m_SpawnAsClass)
        self.m_SpawnAsClass = nil
    end

    -- Make sure the player isn't using the wrong class
    if Classes and #Classes > 0 and not table.HasValue(Classes, self:GetPlayerClassName()) then
        self:SetRandomClass()
    end

    -- If the player is on a team with only one class,
    -- make sure we're that one when we spawn.
    if Classes and #Classes == 1 then
        self:SetPlayerClass(Classes[1])
    end

    -- No defined classes, use default class
    if not Classes or #Classes == 0 then
        self:SetPlayerClass("Default")
    end
end

function meta:OnSpawn()
    local Class = self:GetPlayerClass()
    if not Class then return end

    if Class.DuckSpeed then
        self:SetDuckSpeed(Class.DuckSpeed)
    end

    if Class.WalkSpeed then
        self:SetWalkSpeed(Class.WalkSpeed)
    end

    if Class.RunSpeed then
        self:SetRunSpeed(Class.RunSpeed)
    end

    if Class.CrouchedWalkSpeed then
        self:SetCrouchedWalkSpeed(Class.CrouchedWalkSpeed)
    end

    if Class.JumpPower then
        self:SetJumpPower(Class.JumpPower)
    end

    if Class.DrawTeamRing then
        self:SetNW2Bool("DrawRing", true)
    else
        self:SetNW2Bool("DrawRing", false)
    end

    if Class.DrawViewModel == false then
        self:DrawViewModel(false)
    else
        self:DrawViewModel(true)
    end

    if Class.CanUseFlashlight ~= nil then
        self:AllowFlashlight(Class.CanUseFlashlight)
    end

    if Class.StartHealth then
        self:SetHealth(Class.StartHealth)
    end

    if Class.MaxHealth then
        self:SetMaxHealth(Class.MaxHealth)
    end

    if Class.StartArmor then
        self:SetArmor(Class.StartArmor)
    end

    if Class.RespawnTime then
        self:SetRespawnTime(Class.RespawnTime)
    end

    if Class.DropWeaponOnDie ~= nil then
        self:ShouldDropWeapon(Class.DropWeaponOnDie)
    end

    if Class.TeammateNoCollide ~= nil then
        self:SetNoCollideWithTeammates(Class.TeammateNoCollide)
    end

    if Class.AvoidPlayers ~= nil then
        self:SetAvoidPlayers(Class.AvoidPlayers)
    end

    if Class.FullRotation ~= nil then
        self:SetAllowFullRotation(Class.FullRotation)
    end

    self:CallClassFunction("OnSpawn")
end

function meta:CallClassFunction(name, ...)
    local Class = self:GetPlayerClass()
    if not Class then return end
    if not Class[name] then return end
    --print( "Class Function: ", self:GetPlayerClassName(), name )

    return Class[name](Class, self, ...)
end

function meta:OnLoadout()
    self:CallClassFunction("Loadout")
end

function meta:OnDeath()
end

function meta:OnPlayerModel()
    -- If the class forces a player model, use that..
    -- If not, use our preferred model..
    local Class = self:GetPlayerClass()

    if Class and Class.PlayerModel then
        local mdl = Class.PlayerModel

        -- table of models, set random
        if type(mdl) == "table" then
            mdl = table.Random(Class.PlayerModel)
        end

        util.PrecacheModel(mdl)
        self:SetModel(mdl)

        return
    end

    local cl_playermodel = self:GetInfo("cl_playermodel")
    local modelname = player_manager.TranslatePlayerModel(cl_playermodel)
    util.PrecacheModel(modelname)
    self:SetModel(modelname)
end

function meta:AllowFlashlight(bAble)
    self.m_bFlashlight = bAble
end

function meta:CanUseFlashlight()
    if self.m_bFlashlight == nil then return true end -- Default to true unless modified by the player class

    return self.m_bFlashlight
end

function meta:SetRespawnTime(num)
    self.m_iSpawnTime = num
end

function meta:GetRespawnTime(num)
    if self.m_iSpawnTime == 0 or not self.m_iSpawnTime then return GAMEMODE.MinimumDeathLength end

    return self.m_iSpawnTime
end

function meta:DisableRespawn(strReason)
    self.m_bCanRespawn = false
end

function meta:EnableRespawn()
    self.m_bCanRespawn = true
end

function meta:CanRespawn()
    return self.m_bCanRespawn == nil or self.m_bCanRespawn == true
end

function meta:IsObserver()
    return self:GetObserverMode() > OBS_MODE_NONE
end

function meta:UpdateNameColor()
    if GAMEMODE.SelectColor then
        self:SetNW2String("NameColor", self:GetInfo("cl_playercolor"))
    end
end