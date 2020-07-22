
function RTRank:initStatusBar()
    -- adapted from: https://authors.curseforge.com/forums/world-of-warcraft/general-chat/lua-code-discussion/225562-looking-for-statusbar-create-code-in-lua
    local statusbar = CreateFrame("StatusBar", nil, UIParent)
    statusbar:SetPoint("TOPLEFT", RTRank.config.bar_xOfs, RTRank.config.bar_yOfs)
    statusbar:SetWidth(200)
    statusbar:SetHeight(20)
    statusbar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    statusbar:GetStatusBarTexture():SetHorizTile(false)
    statusbar:GetStatusBarTexture():SetVertTile(false)
    statusbar:SetStatusBarColor(0.1, 0.5, 0.8)
    statusbar:SetMinMaxValues(0, 100)

    statusbar.bg = statusbar:CreateTexture(nil, "BACKGROUND")
    statusbar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    statusbar.bg:SetAllPoints(true)
    statusbar.bg:SetVertexColor(0.8, 0.6, 0.1)

    statusbar.value = statusbar:CreateFontString(nil, "OVERLAY")
    statusbar.value:SetPoint("LEFT", statusbar, "LEFT", 4, 0)
    statusbar.value:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    statusbar.value:SetJustifyH("LEFT")
    statusbar.value:SetShadowOffset(1, -1)
    statusbar.value:SetTextColor(1, 1, 1)
    statusbar.value:SetText("100%")

    --
    statusbar:SetMovable(true)
    statusbar:EnableMouse(true)
    statusbar:RegisterForDrag("LeftButton")
    statusbar:SetScript("OnDragStart", statusbar.StartMoving)
    statusbar:SetScript("OnDragStop", barDragStop)
    self.statusbar = statusbar
end

function barDragStop()
	local _, _, _, xOfs, yOfs = RTRank.statusbar:GetPoint()

	RTRank:setBarPosition(xOfs, yOfs)
	RTRank.statusbar:StopMovingOrSizing()
end

function RTRank:setBarValue(pct) -- could maybe have an interpolation animation to smooth this
    --- negative means player behind x, positive means player ahead

    -- change background color
    if pct < 0 then
        self.statusbar.bg:SetVertexColor(0.8, 0.6, 0.1) -- orange
    else
        self.statusbar.bg:SetVertexColor(0.2, 1, 0) -- green
    end

    local display_pct = string.format("%.0f", pct)
    if pct > 0 then
        display_pct = "+" .. display_pct
    end

    self.statusbar:SetValue(math.max(0, 100 - math.abs(pct)))
    self.statusbar.value:SetText(display_pct .. "%")
end
