local ph_autotaunt_enabled = GetConVar("ph_autotaunt_enabled")
local ph_autotaunt_delay   = GetConVar("ph_autotaunt_delay")

function CalcAutotauntWarning(delay) -- todo: make this a convar
    return delay * 0.5
end

local AutotauntDelay = ph_autotaunt_delay:GetInt()
local AutotauntWarning = CalcAutotauntWarning(AutotauntDelay) -- TODO: make this a convar

local animStartTime = CurTime()

local function AutotauntColor(time)
    local lol = (time / AutotauntWarning)
    local col = HSVToColor( lol*120, 1, 1 )
    col.a = 50 + (1-lol) * 70
    return col
end

local function TimeLeft()
    local lastTauntTime = LocalPlayer():GetNW2Float("NextCanTaunt")
    local nextTauntTime = lastTauntTime + AutotauntDelay
    local currentTime = CurTime()

    return math.max( nextTauntTime - currentTime + 1, 1 )
end

-- a: amplitude
-- p: period
local function outElastic(t, b, c, d, a, p)
    local pi = math.pi
    if t == 0 then return b end
    t = t / d
    if t == 1 then return b + c end

    if not p then
        p = d * 0.3
    end

    local s

    if not a or a < math.abs(c) then
        a = c
        s = p / 4
    else
        s = p / (2 * pi) * math.asin(c / a)
    end

    return a * math.pow(2, -10 * t) * math.sin((t * d - s) * 2 * pi / p) + c + b
end

local function AutoTauntPaint()
    local t = CurTime()

    local ScrW = ScrW()
    local ScrH = ScrH()

    local w = 140
    local h = 30
    
    local x = ScrW - w - 32
    local y = ScrH - h - 32

    local time = TimeLeft()

    if time > AutotauntWarning then 
        animStartTime = t
        return
    else
        local tweenTime = math.Clamp( (t - animStartTime) * 0.5, 0, 1)
        animStopTime = t
        lastDelayTime = time
        x = x + outElastic( tweenTime, 200, -200, 1, 1, 0.5 )
    end

    local percent = (1 - (time-1) / AutotauntWarning)
    local spaz = math.Clamp(10*(percent-0.9), 0, 1)
    x = x + math.random(-2,2) * spaz
    y = y + math.random(-2,2) * spaz

    draw.RoundedBox(5, x, y, w, h, Color(0, 0, 0, 100))
    draw.RoundedBox(5, x + 5, y + 5, (w - 10) * percent, h - 10, AutotauntColor(time))
    draw.DrawText("Auto Taunt", "HunterBlindLockFont", x + 10, y + 8, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)
    draw.DrawText(math.ceil(time).."", "HunterBlindLockFont", x + w + -10, y + 8, Color(255, 255, 255, 255), TEXT_ALIGN_RIGHT)
end

local function AutoTauntRoundEnd()
    timer.Remove("PH:Infinity.AutoTauntChecker")
    hook.Remove("HUDPaint", "PH_AutoTauntPaint")
end

local function AutoTauntSpawn()
    if not ph_autotaunt_enabled:GetBool() then return end -- autotaunt disabled
    if LocalPlayer():Team() ~= TEAM_PROPS then return end -- not a prop

    AutotauntDelay = ph_autotaunt_delay:GetInt()
    AutotauntWarning = CalcAutotauntWarning(AutotauntDelay)

    hook.Add("HUDPaint", "PH_AutoTauntPaint", AutoTauntPaint)

    timer.Create("PH:Infinity.AutoTauntChecker", 1, 0, function()
        if not ph_autotaunt_enabled:GetBool() or not LocalPlayer():Alive() then 
            print("remove autotaunt")
            AutoTauntRoundEnd() 
        end
    end)

end

net.Receive("AutoTauntSpawn", AutoTauntSpawn)
net.Receive("AutoTauntRoundEnd", AutoTauntRoundEnd)

