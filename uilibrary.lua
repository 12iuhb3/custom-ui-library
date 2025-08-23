--// LunarUI v1.4.0
--// - Black boxes + purple outlines
--// - Gradient title
--// - Tabs / Sections / Buttons / Toggles / Keybinds
--// - NEW: Dropdown + Slider (auto-size containers; slider min/max/step)
--// - Minor DX: Button callback receives its API table (so you can SetText in-place)

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

local UILIB = {}
UILIB._version = "1.4.0"

-- THEME
local theme = {
    panel  = Color3.fromRGB(0,0,0),
    panel2 = Color3.fromRGB(0,0,0),
    outline       = Color3.fromRGB(167,139,250),
    outlineHover  = Color3.fromRGB(216,180,254),
    text          = Color3.fromRGB(235,235,240),
    subtext       = Color3.fromRGB(170,170,185),
    accent        = Color3.fromRGB(167,139,250),
    accent2       = Color3.fromRGB(216,180,254),
    shadow        = Color3.fromRGB(0,0,0),

    titleGradStart = Color3.fromRGB(167,139,250),
    titleGradEnd   = Color3.fromRGB(216,180,254),
}

-- ========= UTIL =========
local function roundify(inst, radius)
    local uic = Instance.new("UICorner")
    uic.CornerRadius = UDim.new(0, radius or 12)
    uic.Parent = inst
    return uic
end

local function stroke(inst, thickness, color, transparency)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 1.6
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Color = color or theme.outline
    s.Transparency = transparency or 0
    s.Parent = inst
    return s
end

local function padding(inst, l, t, r, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, l or 8)
    p.PaddingTop = UDim.new(0, t or 8)
    p.PaddingRight = UDim.new(0, r or l or 8)
    p.PaddingBottom = UDim.new(0, b or t or 8)
    p.Parent = inst
    return p
end

local function vlist(parent, pad)
    local ui = Instance.new("UIListLayout")
    ui.Padding = UDim.new(0, pad or 8)
    ui.HorizontalAlignment = Enum.HorizontalAlignment.Left
    ui.SortOrder = Enum.SortOrder.LayoutOrder
    ui.Parent = parent
    return ui
end

local function makeButtonLike(area)
    area.Active = true
    area.Selectable = false
    area.AutoButtonColor = false
end

local function tween(inst, props, t, style, dir)
    return TweenService:Create(inst, TweenInfo.new(t or 0.12, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
end

local function pulseStrokeHover(s)
    if not s then return end
    tween(s, {Thickness = 2.4, Color = theme.outlineHover}, 0.10):Play()
end
local function pulseStrokeIdle(s)
    if not s then return end
    tween(s, {Thickness = 1.6, Color = theme.outline}, 0.14):Play()
end
local function pulseStrokeClick(s)
    if not s then return end
    tween(s, {Thickness = 3.0}, 0.06):Play()
    task.delay(0.08, function() pulseStrokeHover(s) end)
end

-- gradient utilities
local function lerp(a,b,t) return a + (b-a)*t end
local function lerpC(c1,c2,t) return Color3.new(lerp(c1.R,c2.R,t), lerp(c1.G,c2.G,t), lerp(c1.B,c2.B,t)) end
local function toHex255(x) local n = math.clamp(math.floor(x*255+0.5),0,255) return string.format("%02X", n) end
local function hex(c) return "#" .. toHex255(c.R)..toHex255(c.G)..toHex255(c.B) end
local function gradientRichText(text, c1, c2)
    local n = #text
    if n <= 1 then return string.format('<font color="%s">%s</font>', hex(c1), text) end
    local t = table.create(n)
    for i=1,n do t[i] = string.format('<font color="%s">%s</font>', hex(lerpC(c1,c2,(i-1)/(n-1))), text:sub(i,i)) end
    return table.concat(t)
end

local function safeParent(gui)
    local ok = pcall(function() return game:GetService("CoreGui").Parent end)
    if ok then gui.Parent = game:GetService("CoreGui") else gui.Parent = PlayerGui end
end

-- ========= WINDOW =========
function UILIB:CreateWindow(opts)
    opts = opts or {}
    local title = opts.Title or "Lunar UI Library"
    local size  = opts.Size or Vector2.new(580, 420)
    local toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
    local startVisible = (opts.Visible ~= false)
    local gradStart = opts.TitleGradientStart or theme.titleGradStart
    local gradEnd   = opts.TitleGradientEnd   or theme.titleGradEnd

    local sg = Instance.new("ScreenGui")
    sg.Name = "LunarUI_" .. tostring(math.random(1000,9999))
    sg.IgnoreGuiInset = true
    sg.ResetOnSpawn   = false
    sg.Enabled = startVisible
    safeParent(sg)

    local shadow = Instance.new("Frame")
    shadow.BackgroundColor3 = theme.shadow
    shadow.BackgroundTransparency = 0.8
    shadow.BorderSizePixel = 0
    shadow.Size = UDim2.fromOffset(size.X + 24, size.Y + 24)
    shadow.Position = UDim2.fromScale(0.5, 0.5)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Parent = sg
    roundify(shadow, 22)

    local win = Instance.new("Frame")
    win.Name = "Window"
    win.Size = UDim2.fromOffset(size.X, size.Y)
    win.Position = UDim2.fromScale(0.5, 0.5)
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    win.BackgroundColor3 = theme.panel
    win.BorderSizePixel = 0
    win.Parent = sg
    roundify(win, 18)
    local winStroke = stroke(win, 1.6, theme.outline, 0)

    -- Drag zone
    do
        local dragging, dragStart, startPos
        local top = Instance.new("TextButton")
        top.BackgroundTransparency = 1
        top.Text = ""
        top.AutoButtonColor = false
        top.Size = UDim2.new(1,0,0,36)
        top.Parent = win
        makeButtonLike(top)
        top.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; dragStart = input.Position; startPos = win.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local d = input.Position - dragStart
                win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
                shadow.Position = win.Position
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end
        end)
    end

    -- Title
    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.RichText = true
    titleLbl.Text = gradientRichText(title, gradStart, gradEnd)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 18
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Size = UDim2.new(1,-20,0,24)
    titleLbl.Position = UDim2.fromOffset(10,6)
    titleLbl.Parent = win

    -- Body
    local body = Instance.new("Frame")
    body.BackgroundTransparency = 1
    body.Size = UDim2.new(1,-16,1,-52)
    body.Position = UDim2.fromOffset(8,44)
    body.Parent = win

    local tabsBar = Instance.new("Frame")
    tabsBar.BackgroundColor3 = theme.panel
    tabsBar.BorderSizePixel = 0
    tabsBar.Size = UDim2.new(0,180,1,0)
    tabsBar.Parent = body
    roundify(tabsBar, 14)
    local tabsStroke = stroke(tabsBar, 1.6, theme.outline, 0)
    padding(tabsBar, 8,10,8,10)
    vlist(tabsBar, 6)

    local content = Instance.new("Frame")
    content.BackgroundColor3 = theme.panel
    content.BorderSizePixel = 0
    content.Size = UDim2.new(1,-196,1,0)
    content.Position = UDim2.fromOffset(196,0)
    content.Parent = body
    roundify(content, 14)
    local contentStroke = stroke(content, 1.6, theme.outline, 0)
    padding(content,10,10,10,10)

    local windowObj = {
        _gui = sg, _root = win, _shadow = shadow,
        _tabsBar = tabsBar, _contentHolder = content,
        _activeTab = nil, _toggleKey = toggleKey,
        _gradStart = gradStart, _gradEnd = gradEnd, _titleLbl = titleLbl,
    }

    local function bindToggle()
        if windowObj._toggleConn then windowObj._toggleConn:Disconnect() end
        windowObj._toggleConn = UserInputService.InputBegan:Connect(function(input,gpe)
            if gpe then return end
            if input.KeyCode == windowObj._toggleKey then
                windowObj._gui.Enabled = not windowObj._gui.Enabled
            end
        end)
    end
    bindToggle()

    function windowObj:SetToggleKey(key) self._toggleKey = key; bindToggle() end
    function windowObj:SetTitle(t) self._titleLbl.Text = gradientRichText(tostring(t or ""), self._gradStart, self._gradEnd) end
    function windowObj:SetTitleGradient(c1,c2) self._gradStart=c1 or self._gradStart; self._gradEnd=c2 or self._gradEnd; self:SetTitle(self._titleLbl.ContentText ~= "" and self._titleLbl.ContentText or title) end
    function windowObj:Destroy() if self._toggleConn then self._toggleConn:Disconnect() end self._gui:Destroy() end

    function windowObj:CreateTab(tabName)
        tabName = tostring(tabName or "Tab")

        local tabBtn = Instance.new("TextButton")
        tabBtn.Text = tabName
        tabBtn.Font = Enum.Font.GothamMedium
        tabBtn.TextSize = 15
        tabBtn.TextColor3 = theme.text
        tabBtn.BackgroundColor3 = theme.panel
        tabBtn.BorderSizePixel = 0
        tabBtn.AutoButtonColor = false
        tabBtn.Size = UDim2.new(1,0,0,34)
        tabBtn.Parent = tabsBar
        roundify(tabBtn, 10)
        local tabStroke = stroke(tabBtn, 1.6, theme.outline, 0)
        makeButtonLike(tabBtn)

        local selGlow = Instance.new("Frame")
        selGlow.BackgroundColor3 = theme.accent
        selGlow.BackgroundTransparency = 0.85
        selGlow.BorderSizePixel = 0
        selGlow.Visible = false
        selGlow.Size = UDim2.new(1,0,1,0)
        roundify(selGlow, 10)
        selGlow.Parent = tabBtn

        local tabPage = Instance.new("ScrollingFrame")
        tabPage.BackgroundTransparency = 1
        tabPage.Size = UDim2.new(1,0,1,0)
        tabPage.CanvasSize = UDim2.new(0,0,0,0)
        tabPage.ScrollBarImageTransparency = 0.4
        tabPage.ScrollBarThickness = 4
        tabPage.Visible = false
        tabPage.Parent = content
        padding(tabPage,2,2,2,8)
        local pageList = vlist(tabPage, 10)
        pageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabPage.CanvasSize = UDim2.new(0,0,0,pageList.AbsoluteContentSize.Y + 10)
        end)

        local tabObj = { _window = windowObj, _button = tabBtn, _glow = selGlow, _page = tabPage }

        function tabObj:_setActive(active)
            self._page.Visible = active
            self._glow.Visible = active
            if active then pulseStrokeClick(tabStroke) else pulseStrokeIdle(tabStroke) end
        end

        function tabObj:_select()
            if self._window._activeTab == self then return end
            if self._window._activeTab then self._window._activeTab:_setActive(false) end
            self:_setActive(true)
            self._window._activeTab = self
        end

        tabBtn.MouseEnter:Connect(function() pulseStrokeHover(tabStroke) end)
        tabBtn.MouseLeave:Connect(function() if windowObj._activeTab ~= tabObj then pulseStrokeIdle(tabStroke) end end)
        tabBtn.MouseButton1Down:Connect(function() pulseStrokeClick(tabStroke) end)
        tabBtn.MouseButton1Up:Connect(function() tabObj:_select() end)

        function tabObj:AddSection(titleText)
            local section = Instance.new("Frame")
            section.BackgroundColor3 = theme.panel
            section.BorderSizePixel = 0
            section.AutomaticSize = Enum.AutomaticSize.Y
            section.Size = UDim2.new(1,-6,0,0)
            section.Parent = tabPage
            roundify(section, 12)
            local secStroke = stroke(section, 1.6, theme.outline, 0)
            padding(section,12,12,12,12)

            local stack = vlist(section, 8)

            local title = Instance.new("TextLabel")
            title.BackgroundTransparency = 1
            title.Text = tostring(titleText or "Section")
            title.Font = Enum.Font.GothamBold
            title.TextSize = 15
            title.TextColor3 = theme.text
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.TextWrapped = true
            title.AutomaticSize = Enum.AutomaticSize.Y
            title.Size = UDim2.new(1,0,0,0)
            title.Parent = section
            title.LayoutOrder = 1

            local items = Instance.new("Frame")
            items.BackgroundTransparency = 1
            items.AutomaticSize = Enum.AutomaticSize.Y
            items.Size = UDim2.new(1,0,0,0)
            items.Parent = section
            items.LayoutOrder = 2
            local list = vlist(items, 8)

            local secObj = {}

            -- BUTTON
            function secObj:AddButton(opts)
                opts = opts or {}
                local text = opts.Text or "Button"
                local callback = opts.Callback or function() end

                local b = Instance.new("TextButton")
                b.Text = text
                b.Font = Enum.Font.GothamMedium
                b.TextSize = 15
                b.TextColor3 = theme.text
                b.AutoButtonColor = false
                b.BackgroundColor3 = theme.panel
                b.BorderSizePixel = 0
                b.AutomaticSize = Enum.AutomaticSize.Y
                b.Size = UDim2.new(1,0,0,0)
                b.TextWrapped = true
                b.Parent = items
                roundify(b, 10)
                local bStroke = stroke(b, 1.6, theme.outline, 0)
                makeButtonLike(b)

                local min = Instance.new("Frame")
                min.BackgroundTransparency = 1
                min.Size = UDim2.new(1,0,0,34)
                min.Parent = b

                local api = {
                    SetText = function(_, t) b.Text = t end
                }

                b.MouseEnter:Connect(function() pulseStrokeHover(bStroke) end)
                b.MouseLeave:Connect(function() pulseStrokeIdle(bStroke) end)
                b.MouseButton1Down:Connect(function() pulseStrokeClick(bStroke) end)
                b.MouseButton1Up:Connect(function() task.defer(callback, api) end)

                return api
            end

            -- TOGGLE
            function secObj:AddToggle(opts)
                opts = opts or {}
                local text = opts.Text or "Toggle"
                local default = opts.Default or false
                local callback = opts.Callback or function(_) end

                local holder = Instance.new("Frame")
                holder.BackgroundColor3 = theme.panel
                holder.BorderSizePixel = 0
                holder.AutomaticSize = Enum.AutomaticSize.Y
                holder.Size = UDim2.new(1,0,0,0)
                holder.Parent = items
                roundify(holder, 10)
                local hStroke = stroke(holder, 1.6, theme.outline, 0)

                local minH = Instance.new("Frame")
                minH.BackgroundTransparency = 1
                minH.Size = UDim2.new(1,0,0,38)
                minH.Parent = holder

                local label = Instance.new("TextLabel")
                label.BackgroundTransparency = 1
                label.Text = text
                label.Font = Enum.Font.Gotham
                label.TextSize = 14
                label.TextColor3 = theme.text
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.TextWrapped = true
                label.AutomaticSize = Enum.AutomaticSize.Y
                label.Size = UDim2.new(1,-70,0,0)
                label.Position = UDim2.fromOffset(12,10)
                label.Parent = holder

                local knob = Instance.new("Frame")
                knob.BackgroundColor3 = default and theme.accent or theme.panel
                knob.Size = UDim2.fromOffset(44,22)
                knob.Position = UDim2.new(1,-56,0.5,-11)
                knob.BorderSizePixel = 0
                knob.Parent = holder
                roundify(knob, 11)
                local kStroke = stroke(knob, 1.4, theme.outline, 0)

                local dot = Instance.new("Frame")
                dot.BackgroundColor3 = Color3.fromRGB(255,255,255)
                dot.Size = UDim2.fromOffset(18,18)
                dot.Position = default and UDim2.fromOffset(24,2) or UDim2.fromOffset(2,2)
                dot.BorderSizePixel = 0
                dot.Parent = knob
                roundify(dot, 9)

                local overlay = Instance.new("TextButton")
                overlay.BackgroundTransparency = 1
                overlay.Text = ""
                overlay.AutoButtonColor = false
                overlay.Size = UDim2.fromScale(1,1)
                overlay.Parent = holder
                makeButtonLike(overlay)

                local state = default
                local function set(val, fire)
                    state = val and true or false
                    tween(knob, {BackgroundColor3 = state and theme.accent or theme.panel}, 0.10):Play()
                    tween(dot, {Position = state and UDim2.fromOffset(24,2) or UDim2.fromOffset(2,2)}, 0.10):Play()
                    if fire ~= false then task.defer(callback, state) end
                end

                overlay.MouseButton1Click:Connect(function()
                    pulseStrokeClick(hStroke)
                    set(not state, true)
                end)
                holder.MouseEnter:Connect(function() pulseStrokeHover(hStroke) end)
                holder.MouseLeave:Connect(function() pulseStrokeIdle(hStroke) end)

                task.defer(callback, state)

                return {
                    Set = function(_, v) set(v, true) end,
                    Get = function() return state end,
                    SetText = function(_, t) label.Text = t end
                }
            end

            -- KEYBIND (unchanged)
            function secObj:AddKeybind(opts)
                opts = opts or {}
                local text = opts.Text or "Keybind"
                local default = opts.Default or Enum.KeyCode.G
                local onSet = opts.OnSet or function(_) end
                local onPressed = opts.OnPressed or function() end

                local holder = Instance.new("Frame")
                holder.BackgroundColor3 = theme.panel
                holder.BorderSizePixel = 0
                holder.AutomaticSize = Enum.AutomaticSize.Y
                holder.Size = UDim2.new(1,0,0,0)
                holder.Parent = items
                roundify(holder, 10)
                local hStroke = stroke(holder, 1.6, theme.outline, 0)

                local minH = Instance.new("Frame")
                minH.BackgroundTransparency = 1
                minH.Size = UDim2.new(1,0,0,38)
                minH.Parent = holder

                local label = Instance.new("TextLabel")
                label.BackgroundTransparency = 1
                label.Text = text
                label.Font = Enum.Font.Gotham
                label.TextSize = 14
                label.TextColor3 = theme.text
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.TextWrapped = true
                label.AutomaticSize = Enum.AutomaticSize.Y
                label.Size = UDim2.new(1,-160,0,0)
                label.Position = UDim2.fromOffset(12,10)
                label.Parent = holder

                local setBtn = Instance.new("TextButton")
                setBtn.Text = "Set: " .. default.Name
                setBtn.Font = Enum.Font.GothamMedium
                setBtn.TextSize = 14
                setBtn.TextColor3 = theme.text
                setBtn.BackgroundColor3 = theme.panel
                setBtn.AutoButtonColor = false
                setBtn.Size = UDim2.fromOffset(120,28)
                setBtn.Position = UDim2.new(1,-132,0.5,-14)
                setBtn.Parent = holder
                roundify(setBtn, 8)
                local setStroke = stroke(setBtn, 1.6, theme.outline, 0)
                makeButtonLike(setBtn)

                local current = default
                local listening = false
                local pressConn
                local function bindListener()
                    if pressConn then pressConn:Disconnect() end
                    pressConn = UserInputService.InputBegan:Connect(function(input,gpe)
                        if gpe then return end
                        if not listening and input.KeyCode == current then task.defer(onPressed) end
                    end)
                end
                bindListener()

                setBtn.MouseEnter:Connect(function() pulseStrokeHover(setStroke) end)
                setBtn.MouseLeave:Connect(function() pulseStrokeIdle(setStroke) end)
                setBtn.MouseButton1Down:Connect(function() pulseStrokeClick(setStroke) end)

                setBtn.MouseButton1Click:Connect(function()
                    listening = true
                    setBtn.Text = "Press any key..."
                    local conn; conn = UserInputService.InputBegan:Connect(function(input,gpe)
                        if gpe then return end
                        if input.KeyCode ~= Enum.KeyCode.Unknown then
                            current = input.KeyCode
                            setBtn.Text = "Set: " .. current.Name
                            listening = false
                            conn:Disconnect()
                            task.defer(onSet, current)
                            bindListener()
                        end
                    end)
                end)

                holder.MouseEnter:Connect(function() pulseStrokeHover(hStroke) end)
                holder.MouseLeave:Connect(function() pulseStrokeIdle(hStroke) end)

                return {
                    SetKey = function(_, key) current = key; setBtn.Text = "Set: " .. current.Name; bindListener(); task.defer(onSet, current) end,
                    GetKey = function() return current end,
                    SetText = function(_, t) label.Text = t end
                }
            end

-- DROPDOWN (STICKY + POST-REFRESH REAPPLY)
function secObj:AddDropdown(opts)
    opts = opts or {}
    local text   = opts.Text or "Dropdown"
    local values = opts.Values or {}
    local defaultIndex = opts.DefaultIndex or 1
    local onChanged = opts.OnChanged or function(_) end
    local maxHeight = opts.MaxHeight or 240

    local holder = Instance.new("Frame")
    holder.BackgroundColor3 = theme.panel
    holder.BorderSizePixel = 0
    holder.AutomaticSize = Enum.AutomaticSize.Y
    holder.Size = UDim2.new(1,0,0,0)
    holder.Parent = items
    roundify(holder, 10)
    local hStroke = stroke(holder, 1.6, theme.outline, 0)

    local topRow = Instance.new("Frame")
    topRow.BackgroundTransparency = 1
    topRow.Size = UDim2.new(1,0,0,38)
    topRow.Parent = holder
    local topList = Instance.new("UIListLayout")
    topList.FillDirection = Enum.FillDirection.Horizontal
    topList.HorizontalAlignment = Enum.HorizontalAlignment.Left
    topList.VerticalAlignment = Enum.VerticalAlignment.Center
    topList.Padding = UDim.new(0,8)
    topList.Parent = topRow
    padding(topRow,12,6,12,6)

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextColor3 = theme.text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(1,-140,1,0)
    label.Parent = topRow

    local openBtn = Instance.new("TextButton")
    openBtn.Text = "Select ▾"
    openBtn.Font = Enum.Font.GothamMedium
    openBtn.TextSize = 14
    openBtn.TextColor3 = theme.text
    openBtn.BackgroundColor3 = theme.panel
    openBtn.AutoButtonColor = false
    openBtn.Size = UDim2.fromOffset(120,26)
    openBtn.Parent = topRow
    roundify(openBtn, 8)
    local openStroke = stroke(openBtn, 1.6, theme.outline, 0)
    makeButtonLike(openBtn)

    local optionsScroll = Instance.new("ScrollingFrame")
    optionsScroll.BackgroundColor3 = theme.panel
    optionsScroll.BorderSizePixel = 0
    optionsScroll.Visible = false
    optionsScroll.ScrollBarImageTransparency = 0.4
    optionsScroll.ScrollBarThickness = 4
    optionsScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
    optionsScroll.Size = UDim2.new(1,-24,0,0)
    optionsScroll.Position = UDim2.fromOffset(12,0)
    optionsScroll.Parent = holder
    roundify(optionsScroll, 8)
    local optStroke = stroke(optionsScroll, 1.6, theme.outline, 0)
    padding(optionsScroll,6,6,6,6)
    local optList = vlist(optionsScroll, 6)

    local function indexOf(t, val)
        for i,v in ipairs(t) do if v == val then return i end end
        return nil
    end

    local currentIndex = (#values > 0) and math.clamp(defaultIndex, 1, #values) or 0
    local currentValue = (currentIndex > 0) and values[currentIndex] or nil
    local desiredValue = currentValue -- what we *want* to keep across refreshes
    local open = false

    local function refreshButtonText()
        openBtn.Text = (currentValue and tostring(currentValue) or "Select") .. " ▾"
    end

    local function setCanvasAndHeight()
        task.defer(function()
            local contentY = optList.AbsoluteContentSize.Y + 12
            local h = math.min(contentY, maxHeight)
            optionsScroll.CanvasSize = UDim2.new(0,0,0,contentY)
            if optionsScroll.Visible then
                optionsScroll.Size = UDim2.new(1,-24,0,h)
            end
        end)
    end

    local function selectIndex(i, fire)
        if i < 1 or i > #values then return end
        local newVal = values[i]
        if newVal ~= currentValue then
            currentIndex = i
            currentValue = newVal
            desiredValue = newVal  -- <-- lock what the user just chose
            refreshButtonText()
            if fire ~= false then task.defer(onChanged, currentValue) end
        end
        optionsScroll.Visible = false
        optionsScroll.Size = UDim2.new(1,-24,0,0)
        open = false
    end

    local function rebuildOptions()
        for _, child in ipairs(optionsScroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for i, val in ipairs(values) do
            local b = Instance.new("TextButton")
            b.Text = tostring(val)
            b.Font = Enum.Font.Gotham
            b.TextSize = 14
            b.TextColor3 = theme.text
            b.BackgroundColor3 = theme.panel
            b.AutoButtonColor = false
            b.BorderSizePixel = 0
            b.Size = UDim2.new(1,0,0,28)
            b.Parent = optionsScroll
            roundify(b, 8)
            local s = stroke(b, 1.4, theme.outline, 0)
            makeButtonLike(b)
            b.MouseEnter:Connect(function() pulseStrokeHover(s) end)
            b.MouseLeave:Connect(function() pulseStrokeIdle(s) end)
            b.MouseButton1Down:Connect(function() pulseStrokeClick(s) end)
            b.MouseButton1Up:Connect(function() selectIndex(i, true) end)
        end
        setCanvasAndHeight()
    end

    local function toggleOpen()
        open = not open
        optionsScroll.Visible = open
        if open then
            pulseStrokeClick(openStroke)
            setCanvasAndHeight()
        else
            optionsScroll.Size = UDim2.new(1,-24,0,0)
        end
    end

    openBtn.MouseEnter:Connect(function() pulseStrokeHover(openStroke) end)
    openBtn.MouseLeave:Connect(function() pulseStrokeIdle(openStroke) end)
    openBtn.MouseButton1Down:Connect(function() pulseStrokeClick(openStroke) end)
    openBtn.MouseButton1Up:Connect(toggleOpen)

    refreshButtonText()
    rebuildOptions()

    return {
        SetValues = function(self, newValues)
            newValues = newValues or {}
            -- remember what we *want* selected across refreshes
            local prevDesired = desiredValue or currentValue

            values = newValues
            rebuildOptions()

            -- Try to keep desired/previous selection if still present
            local idx = prevDesired and indexOf(values, prevDesired) or nil
            if idx then
                currentIndex = idx
                currentValue = values[idx]
                desiredValue = currentValue
            else
                -- leave unselected if previous choice vanished
                currentIndex = 0
                currentValue = nil
            end
            refreshButtonText()

            -- If some external code immediately forces first option,
            -- re-apply our desired choice on the next tick.
            if idx then
                local reapplyValue = values[idx]
                task.defer(function()
                    -- re-check it's still there, then re-apply
                    local nowIdx = indexOf(values, reapplyValue)
                    if nowIdx and currentValue ~= reapplyValue then
                        selectIndex(nowIdx, true)
                    end
                end)
            end
        end,

        SetValue = function(self, val)
            local idx = indexOf(values, val)
            if idx then
                selectIndex(idx, true)
            end
        end,

        GetValue = function() return currentValue end,
        OnChanged = function(_, cb) onChanged = cb or onChanged end,
        SetText   = function(_, t) label.Text = t end,
        Close     = function() if open then toggleOpen() end end
    }
end


            -- SLIDER (NEW)
            function secObj:AddSlider(opts)
                opts = opts or {}
                local text = opts.Text or "Slider"
                local min  = tonumber(opts.Min)  or 0
                local max  = tonumber(opts.Max)  or 100
                local step = tonumber(opts.Step) or 1
                local default = math.clamp(tonumber(opts.Default) or min, min, max)
                local suffix  = opts.Suffix or ""
                local onChanged = opts.OnChanged or function(_) end

                if max <= min then max = min + 1 end
                if step <= 0 then step = 1 end

                local holder = Instance.new("Frame")
                holder.BackgroundColor3 = theme.panel
                holder.BorderSizePixel = 0
                holder.AutomaticSize = Enum.AutomaticSize.Y
                holder.Size = UDim2.new(1,0,0,0)
                holder.Parent = items
                roundify(holder, 10)
                local hStroke = stroke(holder, 1.6, theme.outline, 0)
                padding(holder,12,12,12,12)

                local labelRow = Instance.new("Frame")
                labelRow.BackgroundTransparency = 1
                labelRow.Size = UDim2.new(1,0,0,22)
                labelRow.Parent = holder
                local lr = Instance.new("UIListLayout")
                lr.FillDirection = Enum.FillDirection.Horizontal
                lr.HorizontalAlignment = Enum.HorizontalAlignment.Left
                lr.VerticalAlignment = Enum.VerticalAlignment.Center
                lr.Padding = UDim.new(0,8)
                lr.Parent = labelRow

                local label = Instance.new("TextLabel")
                label.BackgroundTransparency = 1
                label.Text = text
                label.Font = Enum.Font.Gotham
                label.TextSize = 14
                label.TextColor3 = theme.text
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Size = UDim2.new(1,-80,1,0)
                label.Parent = labelRow

                local valLbl = Instance.new("TextLabel")
                valLbl.BackgroundTransparency = 1
                valLbl.Font = Enum.Font.GothamMedium
                valLbl.TextSize = 14
                valLbl.TextColor3 = theme.text
                valLbl.TextXAlignment = Enum.TextXAlignment.Right
                valLbl.Size = UDim2.new(0,72,1,0)
                valLbl.Parent = labelRow

                local track = Instance.new("Frame")
                track.BackgroundColor3 = theme.panel
                track.BorderSizePixel = 0
                track.Size = UDim2.new(1,0,0,10)
                track.Position = UDim2.new(0,0,0,28)
                track.Parent = holder
                roundify(track, 6)
                local tStroke = stroke(track, 1.6, theme.outline, 0)

                local fill = Instance.new("Frame")
                fill.BackgroundColor3 = theme.accent
                fill.BorderSizePixel = 0
                fill.Size = UDim2.new(0,0,1,0)
                fill.Parent = track
                roundify(fill, 6)

                local knob = Instance.new("Frame")
                knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
                knob.BorderSizePixel = 0
                knob.Size = UDim2.fromOffset(14,14)
                knob.Parent = track
                roundify(knob, 7)
                local kStroke = stroke(knob, 1.2, theme.outline, 0)

                local value = default
                local dragging = false

                local function snap(v)
                    v = math.clamp(v, min, max)
                    local n = math.floor((v - min)/step + 0.5)*step + min
                    n = math.clamp(n, min, max)
                    return n
                end
                local function setValue(v, fire)
                    value = snap(v)
                    local alpha = (value - min)/(max - min)
                    fill.Size = UDim2.new(alpha, 0, 1, 0)
                    knob.Position = UDim2.new(alpha, -7, 0.5, -7)
                    valLbl.Text = tostring(value) .. (suffix ~= "" and (" "..suffix) or "")
                    if fire ~= false then task.defer(onChanged, value) end
                end

                setValue(default, false)

                local function pickAt(x)
                    local absX = track.AbsolutePosition.X
                    local width = track.AbsoluteSize.X
                    local t = math.clamp((x - absX)/math.max(1,width), 0, 1)
                    setValue(min + t*(max-min), true)
                end

                track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        pulseStrokeClick(tStroke)
                        pickAt(input.Position.X)
                    end
                end)
                knob.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        pulseStrokeClick(kStroke)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        pickAt(input.Position.X)
                    end
                end)

                track.MouseEnter:Connect(function() pulseStrokeHover(tStroke) end)
                track.MouseLeave:Connect(function() pulseStrokeIdle(tStroke) end)

                return {
                    Set = function(_, v) setValue(v, true) end,
                    Get = function() return value end,
                    SetText = function(_, t) label.Text = t end,
                    OnChanged = function(_, cb) onChanged = cb or onChanged end
                }
            end

            return secObj
        end

        if not windowObj._activeTab then tabObj:_select() end
        return tabObj
    end

    return windowObj
end

function UILIB:SetToggleKey(key, window) if window then window:SetToggleKey(key) end end

return UILIB
