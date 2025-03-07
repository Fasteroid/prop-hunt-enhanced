function GM:HUDDrawTargetID()
    local tr = util.GetPlayerTrace(LocalPlayer())
    local trace = util.TraceLine(tr)
    -- Don't show if 'Player Names above their head' is enabled.
    if GetConVar("ph_enable_plnames"):GetBool() and GetConVar("ph_cl_pltext"):GetBool() then return end
    if not trace.Hit then return end
    if not trace.HitNonWorld then return end
    local text = "ERROR"
    local font = "TargetID"

    if trace.Entity:IsPlayer() and trace.Entity:Team() == LocalPlayer():Team() then
        text = trace.Entity:Nick()
    else
        return
    end

    surface.SetFont(font)
    local w, h = surface.GetTextSize(text)
    local MouseX, MouseY = gui.MousePos()

    if MouseX == 0 and MouseY == 0 then
        MouseX = ScrW() / 2
        MouseY = ScrH() / 2
    end

    local x = MouseX
    local y = MouseY
    x = x - w / 2
    y = y + 30
    draw.SimpleText(text, font, x + 1, y + 1, Color(0, 0, 0, 120))
    draw.SimpleText(text, font, x + 2, y + 2, Color(0, 0, 0, 50))
    draw.SimpleText(text, font, x, y, self:GetTeamColor(trace.Entity))
    y = y + h + 5
    local text = trace.Entity:Health() .. "%"
    local font = "TargetIDSmall"
    surface.SetFont(font)
    local w, _ = surface.GetTextSize(text)
    local x = MouseX - w / 2
    draw.SimpleText(text, font, x + 1, y + 1, Color(0, 0, 0, 120))
    draw.SimpleText(text, font, x + 2, y + 2, Color(0, 0, 0, 50))
    draw.SimpleText(text, font, x, y, self:GetTeamColor(trace.Entity))
end