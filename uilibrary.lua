--// DarkPanel UI Library - sidebar/tabs/sections/dropdowns/toggles
--// Single file. No dependencies. Works in Studio or live.
--// API:
--// local ui = Library:CreateWindow({Title="Title", AccentColor=Color3, Size=Vector2})
--// local tab = ui:AddTab("Pets")
--// local sec = tab:AddSection("Before Hatching Eggs", "This needs to be paired with the Auto Hatch feature.")
--// sec:AddDropdown("Select Pets", {"Set A","Set B","Set C"}, nil, function(value) end)
--// sec:AddToggle("Auto Switch: Before Hatch", false, function(on) end)

local Library = {}
Library.__index = Library

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local function new(inst, props, parent)
	local o = Instance.new(inst)
	if props then
		for k, v in pairs(props) do o[k] = v end
	end
	if parent then o.Parent = parent end
	return o
end

local function protect(gui)
	pcall(function()
		if syn and syn.protect_gui then syn.protect_gui(gui) end
	end)
end

local function round(frame, r)
	new("UICorner", {CornerRadius = UDim.new(0, r or 8)}, frame)
end

local function stroke(frame, c, t)
	new("UIStroke", {Color = c, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, frame)
end

local Theme = {
	BG      = Color3.fromRGB(14, 17, 23),
	Panel   = Color3.fromRGB(18, 23, 30),
	Sub     = Color3.fromRGB(28, 34, 43),
	Sidebar = Color3.fromRGB(16, 20, 26),
	Text    = Color3.fromRGB(225, 230, 236),
	Muted   = Color3.fromRGB(160, 170, 180),
	Accent  = Color3.fromRGB(80, 255, 160),
	Purple  = Color3.fromRGB(145, 115, 255),
	Shadow  = Color3.fromRGB(0, 0, 0),
}

local function makeDraggable(frame, dragHandle)
	dragHandle = dragHandle or frame
	local dragging, startPos, startInput
	dragHandle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = i.Position
			startInput = i
		end
	end)
	dragHandle.InputEnded:Connect(function(i)
		if i == startInput then dragging = false end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local delta = i.Position - startPos
			frame.Position = frame.Position + UDim2.fromOffset(delta.X, delta.Y)
			startPos = i.Position
		end
	end)
end

-- Window
function Library:CreateWindow(opts)
	opts = opts or {}
	local self = setmetatable({}, Library)

	self.Title = opts.Title or "UI Panel"
	self.Accent = opts.AccentColor or Theme.Accent
	self.Size = opts.Size or Vector2.new(760, 480)
	self.Tabs = {}

	-- Root
	local guiParent = game:GetService("CoreGui")
	if Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui") then
		guiParent = Players.LocalPlayer.PlayerGui
	end
	self.Gui = new("ScreenGui", {Name = "DarkPanelUILib", ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, guiParent)
	protect(self.Gui)

	-- Backdrop
	self.Root = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(self.Size.X, self.Size.Y),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Theme.Panel,
	}, self.Gui)
	round(self.Root, 12)
	stroke(self.Root, Color3.fromRGB(45, 55, 68), 1)

	-- Topbar
	self.Topbar = new("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = Theme.Sub,
	}, self.Root)
	round(self.Topbar, 12)
	stroke(self.Topbar, Color3.fromRGB(55, 65, 80), 1)

	self.TitleLabel = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		Text = self.Title,
		TextColor3 = self.Accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
	}, self.Topbar)

	makeDraggable(self.Root, self.Topbar)

	-- Sidebar
	self.Sidebar = new("Frame", {
		Size = UDim2.new(0, 170, 1, -36),
		Position = UDim2.fromOffset(0, 36),
		BackgroundColor3 = Theme.Sidebar,
	}, self.Root)
	stroke(self.Sidebar, Color3.fromRGB(45, 55, 68), 1)

	local sideList = new("UIListLayout", {
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
	}, self.Sidebar)
	new("UIPadding", {PaddingTop = UDim.new(0, 10)}, self.Sidebar)

	-- Content holder
	self.Pages = new("Frame", {
		Size = UDim2.new(1, -170, 1, -36),
		Position = UDim2.fromOffset(170, 36),
		BackgroundColor3 = Theme.BG,
	}, self.Root)
	stroke(self.Pages, Color3.fromRGB(45, 55, 68), 1)

	return self
end

-- Add Tab
function Library:AddTab(name)
	local tab = {}
	tab.Sections = {}
	tab.Name = name
	tab._page = new("ScrollingFrame", {
		Visible = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 4,
		Parent = self.Pages
	})
	local list = new("UIListLayout", {
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder
	}, tab._page)
	new("UIPadding", {PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18), PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14)}, tab._page)
	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		tab._page.CanvasSize = UDim2.fromOffset(0, list.AbsoluteContentSize.Y + 20)
	end)

	-- Sidebar button
	local btn = new("TextButton", {
		Text = name,
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Sidebar,
		TextColor3 = Theme.Text,
		Font = Enum.Font.Gotham,
		TextSize = 14,
		Size = UDim2.new(1, -20, 0, 28),
		Parent = self.Sidebar
	})
	round(btn, 8)
	stroke(btn, Color3.fromRGB(45, 55, 68), 1)
	btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Theme.Sub end)
	btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Theme.Sidebar end)
	btn.MouseButton1Click:Connect(function()
		for _, t in pairs(self.Tabs) do t._page.Visible = false end
		tab._page.Visible = true
		for _, b in pairs(self.Sidebar:GetChildren()) do
			if b:IsA("TextButton") then b.TextColor3 = Theme.Text end
		end
		btn.TextColor3 = self.Accent
	end)

	function tab:AddSection(title, subtitle)
		local s = {}
		s._frame = new("Frame", {
			BackgroundColor3 = Theme.Panel,
			Size = UDim2.new(1, 0, 0, 80),
			Parent = tab._page
		})
		round(s._frame, 10)
		stroke(s._frame, Color3.fromRGB(45, 55, 68), 1)
		new("UIPadding", {PaddingLeft = UDim.new(0, 14), PaddingTop = UDim.new(0, 12), PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 12)}, s._frame)

		local titleLbl = new("TextLabel", {
			Text = title or "Section",
			Font = Enum.Font.GothamBold,
			TextSize = 15,
			TextColor3 = self.Accent,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -10, 0, 18),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = s._frame
		})

		if subtitle then
			new("TextLabel", {
				Text = subtitle,
				Font = Enum.Font.Gotham,
				TextSize = 12,
				TextColor3 = Theme.Muted,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 16),
				Position = UDim2.fromOffset(0, 20),
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = s._frame
			})
		end

		s._container = new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.fromOffset(0, subtitle and 40 or 24),
			Parent = s._frame
		})
		local sl = new("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder
		}, s._container)

		sl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			s._container.Size = UDim2.fromOffset(s._container.AbsoluteSize.X, sl.AbsoluteContentSize.Y)
			s._frame.Size = UDim2.new(1, 0, 0, (subtitle and 40 or 24) + sl.AbsoluteContentSize.Y + 22)
		end)

		function s:AddLabel(text, muted)
			new("TextLabel", {
				Text = text,
				Font = Enum.Font.Gotham,
				TextSize = 13,
				TextColor3 = muted and Theme.Muted or Theme.Text,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -6, 0, 18),
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = s._container
			})
		end

		function s:_makeRow(height)
			local r = new("Frame", {
				BackgroundColor3 = Theme.Sub,
				Size = UDim2.new(1, 0, 0, height or 34),
				Parent = s._container
			})
			round(r, 8)
			stroke(r, Color3.fromRGB(55, 65, 80), 1)
			new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, r)
			return r
		end

		-- Dropdown
		function s:AddDropdown(label, list, default, callback)
			list = list or {}
			local row = s:_makeRow(36)

			local lbl = new("TextLabel", {
				Text = label or "Dropdown",
				Font = Enum.Font.Gotham,
				TextSize = 13,
				TextColor3 = Theme.Text,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -110, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row
			})

			local btn = new("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -6, 0.5, 0),
				Size = UDim2.fromOffset(170, 26),
				Text = "",
				AutoButtonColor = false,
				BackgroundColor3 = Theme.Panel,
				Parent = row
			})
			round(btn, 8)
			stroke(btn, Color3.fromRGB(55, 65, 80), 1)

			local valueLbl = new("TextLabel", {
				Text = default or "Select...",
				Font = Enum.Font.Gotham,
				TextSize = 12,
				TextColor3 = Theme.Muted,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -24, 1, 0),
				Position = UDim2.fromOffset(8, 0),
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = btn
			})
			local caret = new("ImageLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -6, 0.5, 0),
				Size = UDim2.fromOffset(12, 12),
				Image = "rbxassetid://7072718266",
				ImageColor3 = Theme.Muted,
				Parent = btn
			})

			-- Menu
			local open = false
			local menu = new("Frame", {
				Visible = false,
				BackgroundColor3 = Theme.Panel,
				Size = UDim2.new(0, 170, 0, math.clamp(#list * 26 + 10, 36, 170)),
				Position = UDim2.fromOffset(btn.AbsolutePosition.X, btn.AbsolutePosition.Y + 30),
				Parent = self.Gui
			})
			round(menu, 8); stroke(menu, Color3.fromRGB(55, 65, 80), 1)
			local mList = new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, menu)
			new("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)}, menu)

			local function refreshMenu()
				menu:ClearAllChildren()
				round(menu, 8); stroke(menu, Color3.fromRGB(55, 65, 80), 1)
				new("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)}, menu)
				new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, menu)
				for _, item in ipairs(list) do
					local opt = new("TextButton", {
						Text = tostring(item),
						AutoButtonColor = false,
						BackgroundColor3 = Theme.Sub,
						TextColor3 = Theme.Text,
						Font = Enum.Font.Gotham,
						TextSize = 12,
						Size = UDim2.new(1, 0, 0, 24),
						Parent = menu
					})
					round(opt, 6)
					opt.MouseEnter:Connect(function() opt.BackgroundColor3 = Theme.BG end)
					opt.MouseLeave:Connect(function() opt.BackgroundColor3 = Theme.Sub end)
					opt.MouseButton1Click:Connect(function()
						valueLbl.Text = tostring(item)
						valueLbl.TextColor3 = Theme.Text
						open = false; menu.Visible = false
						if callback then task.spawn(callback, item) end
					end)
				end
				menu.Size = UDim2.new(0, 170, 0, math.clamp(#list * 26 + 10, 36, 170))
			end
			refreshMenu()

			btn.MouseButton1Click:Connect(function()
				open = not open
				local abs = btn.AbsolutePosition
				menu.Position = UDim2.fromOffset(abs.X, abs.Y + btn.AbsoluteSize.Y + 4)
				menu.Visible = open
			end)
			UIS.InputBegan:Connect(function(i)
				if open and i.UserInputType == Enum.UserInputType.MouseButton1 then
					local p = UIS:GetMouseLocation()
					local pos = menu.AbsolutePosition
					local size = menu.AbsoluteSize
					local inside = p.X >= pos.X and p.X <= pos.X + size.X and p.Y >= pos.Y and p.Y <= pos.Y + size.Y
					if not inside then open = false; menu.Visible = false end
				end
			end)

			return {
				SetList = function(_, newList) list = newList or {}; refreshMenu() end,
				SetValue = function(_, v) valueLbl.Text = tostring(v); valueLbl.TextColor3 = Theme.Text end
			}
		end

		-- Toggle (checkbox)
		function s:AddToggle(label, default, callback)
			local state = not not default
			local row = s:_makeRow(34)

			local box = new("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = Theme.BG,
				Size = UDim2.fromOffset(22, 22),
				Position = UDim2.fromOffset(4, 6),
				Text = "",
				Parent = row
			})
			round(box, 6)
			stroke(box, Theme.Purple, 2)

			local check = new("Frame", {
				BackgroundColor3 = Theme.Purple,
				Visible = state,
				Size = UDim2.fromOffset(12, 12),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Parent = box
			})
			round(check, 3)

			local lbl = new("TextLabel", {
				Text = label or "Toggle",
				Font = Enum.Font.Gotham,
				TextSize = 13,
				TextColor3 = Theme.Text,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -40, 1, 0),
				Position = UDim2.fromOffset(36, 0),
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row
			})

			local function set(v)
				state = not not v
				check.Visible = state
				if callback then task.spawn(callback, state) end
			end

			box.MouseButton1Click:Connect(function() set(not state) end)
			lbl.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then set(not state) end end)

			if default ~= nil then set(default) end
			return {Set = set, Get = function() return state end}
		end

		table.insert(tab.Sections, s)
		return s
	end

	table.insert(self.Tabs, tab)
	-- Auto-select first tab
	if #self.Tabs == 1 then
		for _, t in pairs(self.Tabs) do t._page.Visible = false end
		tab._page.Visible = true
		for _, b in pairs(self.Sidebar:GetChildren()) do
			if b:IsA("TextButton") then b.TextColor3 = Theme.Text end
		end
		for _, b in pairs(self.Sidebar:GetChildren()) do
			if b:IsA("TextButton") and b.Text == name then b.TextColor3 = self.Accent end
		end
	end

	return tab
end

function Library:Destroy()
	if self.Gui then self.Gui:Destroy() end
end

return setmetatable({}, {__index = Library})
