-- ++++++++ WAX BUNDLED DATA BELOW ++++++++ --

-- Will be used later for getting flattened globals
local ImportGlobals

-- Holds direct closure data (defining this before the DOM tree for line debugging etc)
local ClosureBindings = {
    function()local wax,script,require=ImportGlobals(1)local ImportGlobals return (function(...)wait(1)
function generateRandomString(length)
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+[]{}|;:',.<>?/`~"
    local randomString = ""
    math.randomseed(os.time()) -- Seed the random generator

    for i = 1, length do
        local randomIndex = math.random(1, #charset)
        randomString = randomString .. charset:sub(randomIndex, randomIndex)
    end

    return randomString
end

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local ElementsTable = require(script.elements)
local Tools = require(script.tools)
local Components = script.components

local Create = Tools.Create
local AddConnection = Tools.AddConnection
local AddScrollAnim = Tools.AddScrollAnim
local isMobile = Tools.isMobile()
local CurrentThemeProps = Tools.GetPropsCurrentTheme()

local function MakeDraggable(DragPoint, Main)
	-- if isMobile then return end
	local Dragging, DragInput, MousePos, FramePos = false
	AddConnection(DragPoint.InputBegan, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			Dragging = true
			MousePos = Input.Position
			FramePos = Main.Position

			AddConnection(Input.Changed, function()
				if Input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
			end)
		end
	end)
	AddConnection(DragPoint.InputChanged, function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseMovement then
			DragInput = Input
		end
	end)
	AddConnection(UserInputService.InputChanged, function(Input)
		if
			(Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
			and Dragging
		then
			local Delta = Input.Position - MousePos
			Main.Position =
				UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
		end
	end)
end

local Library = {
	Window = nil,
	Flags = {},
	Signals = {},
	ToggleBind = nil,
}



local GUI = Create("ScreenGui", {
	Name = generateRandomString(16),
	Parent = gethui(), --game.Players.LocalPlayer.PlayerGui,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

require(Components.notif):Init(GUI)

function Library:SetTheme(themeName)
	Tools.SetTheme(themeName)
end

function Library:GetTheme()
	return Tools.GetPropsCurrentTheme()
end

function Library:AddTheme(themeName, themeProps)
	Tools.AddTheme(themeName, themeProps)
end

function Library:IsRunning()
	return GUI.Parent == gethui() -- game.Players.LocalPlayer.PlayerGui -- testing ver with playergui
end

task.spawn(function()
	while Library:IsRunning() do
		task.wait()
	end
	for i, Connection in pairs(Tools.Signals) do
		Connection:Disconnect()
	end
end)

local Elements = {}
Elements.__index = Elements
Elements.__namecall = function(Table, Key, ...)
	return Elements[Key](...)
end

for _, ElementComponent in ipairs(ElementsTable) do
	assert(ElementComponent.__type, "ElementComponent missing __type")
	assert(type(ElementComponent.New) == "function", "ElementComponent missing New function")

	Elements["Add" .. ElementComponent.__type] = function(self, Idx, Config)
		ElementComponent.Container = self.Container
		ElementComponent.Type = self.Type
		ElementComponent.ScrollFrame = self.ScrollFrame
		ElementComponent.Library = Library -- Assign Library correctly

		return ElementComponent:New(Idx, Config)
	end
end

Library.Elements = Elements

function Library:Callback(Callback, ...)
	local success, result = pcall(Callback, ...)

	if success then
		-- print(`Callback executed successfully!`)
		return result
	else
		local errorMessage = tostring(result)
		local errorLine = string.match(errorMessage, ":(%d+):")
		local errorInfo = `Callback execution failed.\n`
		errorInfo = errorInfo .. `Error: {errorMessage}\n`

		if errorLine then
			errorInfo = errorInfo .. `Occurred on line: {errorLine}\n`
		end

		errorInfo = errorInfo
			.. `Possible Fix: Please check the function implementation for potential issues such as invalid arguments or logic errors at the indicated line number.`
		print(errorInfo)
	end
end

function Library:Notification(titleText, descriptionText, duration)
	require(Components.notif):ShowNotification(titleText, descriptionText, duration)
end

function Library:Dialog(config)
    return require(Components.dialog):Create(config, self.LoadedWindow)
end

function Library:Load(cfgs)

	cfgs = cfgs or {}
	cfgs.Title = cfgs.Title or "Window"
	cfgs.ToggleButton = cfgs.ToggleButton or ""
	cfgs.BindGui = cfgs.BindGui or Enum.KeyCode.RightControl

	if Library.Window then
		print("Cannot create more than one window.")
		GUI:Destroy()
	end
	
	Library.Window = GUI

	local canvas_group = Create("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		-- BackgroundColor3 = Color3.fromRGB(9, 9, 9),
		ThemeProps = {
			BackgroundColor3 = "maincolor",
		},
		Position = UDim2.new(0.5, 0, 0.3, 0),
		Size = UDim2.new(0, 650, 0, 400),
		Parent = GUI,
		Visible = false
	}, {
		Create("UICorner", {
			CornerRadius = UDim.new(0, 6),
		}),
	})

	-- shared.Window = canvas_group

	if isMobile then
		canvas_group.Size = UDim2.new(0.8, 0, 0.8, 0)
	end

	local togglebtn = Create("ImageButton", {
		AnchorPoint = Vector2.new(0.5, 0),
		AutoButtonColor = false,
		ThemeProps = {
			BackgroundColor3 = "maincolor",
		},
		Position = UDim2.new(0.5, 8, 0, 0),
		Size = UDim2.new(0, 45, 0, 45),
		Parent = GUI,
		Image = "rbxassetid://135668421955688",
	}, {
		Create("UICorner", {
			CornerRadius = UDim.new(0, 6),
		}),
		Create("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeProps = {
				Color = "bordercolor",
			},
			Enabled = true,
			LineJoinMode = Enum.LineJoinMode.Round,
			Thickness = 1,
			Archivable = true,
		}),
	})

	local function ToggleVisibility()
		local isVisible = canvas_group.Visible
		local endPosition = isVisible and UDim2.new(0.5, 0, -1, 0) or UDim2.new(0.5, 0, 0.5, 0)
		local fadeTo = isVisible and 1 or 0
	
		local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	
		local positionTween = TweenService:Create(canvas_group, tweenInfo, { Position = endPosition })
		-- local fadeTween = TweenService:Create(canvas_group, tweenInfo, { BackgroundTransparency = fadeTo })
		-- local toggleFadeTween = TweenService:Create(togglebtn, tweenInfo, { BackgroundTransparency = fadeTo })
		-- local toggleFadeSTween = TweenService:Create(togglebtn.UIStroke, tweenInfo, { Transparency = fadeTo })
	
		canvas_group.Visible = true
		togglebtn.Visible = false
	
		positionTween:Play()
		-- fadeTween:Play()
		-- toggleFadeTween:Play()
		-- toggleFadeSTween:Play()
		
	
		positionTween.Completed:Connect(function()
			if isVisible then
				canvas_group.Visible = false
				togglebtn.Visible = true
			end
		end)
	end

	ToggleVisibility()
	-- ToggleVisibility()

	MakeDraggable(togglebtn, togglebtn)
	AddConnection(togglebtn.MouseButton1Click, ToggleVisibility)
	AddConnection(UserInputService.InputBegan, function(value)
		if value.KeyCode == cfgs.BindGui then
			ToggleVisibility()
		end
	end)

	local top_frame = Create("Frame", {
		ThemeProps = {
			BackgroundColor3 = "maincolor",
		},
		BorderColor3 = Color3.fromRGB(39, 39, 42),
		Size = UDim2.new(1, 0, 0, 40),
		ZIndex = 9,
		Parent = canvas_group,
	}, {
		Create("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeProps = {
				Color = "bordercolor",
			},
			Thickness = 1,
		}),
	})

	local title = Create("TextLabel", {
		Font = Enum.Font.GothamMedium,
		RichText = true,
		Text = cfgs.Title,
		ThemeProps = {
			TextColor3 = "titlecolor",
			BackgroundColor3 = "maincolor",
		},
		BorderSizePixel = 0,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(0, 200, 0, 40),
		ZIndex = 10,
		Parent = top_frame,
	})

	local minimizebtn = Create("TextButton", {
		Text = "",
		BackgroundTransparency = 1,
		ThemeProps = {
			BackgroundColor3 = "maincolor",
		},
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -36, 0.5, 0),
		Size = UDim2.new(0, 28, 0, 28),
		ZIndex = 10,
		Parent = top_frame,
	}, {
		Create("ImageLabel", {
			Image = "rbxassetid://15269257100",
			ImageRectOffset = Vector2.new(514, 257),
			ImageRectSize = Vector2.new(256, 256),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, -10, 1, -10),
			ThemeProps = {
				BackgroundColor3 = "maincolor",
			},
			BorderSizePixel = 0,
			ZIndex = 11,
		}),
	})

	local closebtn = Create("TextButton", {
		Text = "",
		BackgroundTransparency = 1,
		ThemeProps = {
			BackgroundColor3 = "maincolor",
		},
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0, 28, 0, 28),
		ZIndex = 10,
		Parent = top_frame,
	}, {
		Create("ImageLabel", {
			Image = "rbxassetid://15269329696",
			ImageRectOffset = Vector2.new(0, 514),
			ImageRectSize = Vector2.new(256, 256),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, -10, 1, -10),
			ThemeProps = {
				BackgroundColor3 = "maincolor",
			},
			BorderSizePixel = 0,
			ZIndex = 11,
		}),
	})

	AddConnection(minimizebtn.MouseButton1Click, ToggleVisibility)
	AddConnection(closebtn.MouseButton1Click, function()
		canvas_group:Destroy()
		togglebtn:Destroy()
	end)

	local tab_frame = Create("Frame", {
		BackgroundTransparency = 1,
		ThemeProps = {
			BackgroundColor3 = "maincolor",
		},
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(39, 39, 42),
		Position = UDim2.new(0, 0, 0, 40),
		Size = UDim2.new(0, 140, 1, -40),
		Parent = canvas_group,
	}, {
		Create("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			-- Color = Color3.fromRGB(39, 39, 42),
			ThemeProps = {
				Color = "bordercolor",
			},
			Thickness = 1,
		}),
	})

	local TabHolder = Create("ScrollingFrame", {
		ThemeProps = {
			ScrollBarImageColor3 = "scrollcolor",
			BackgroundColor3 = "maincolor",
		},
		ScrollBarThickness = 2,
		ScrollBarImageTransparency = 1,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		Parent = tab_frame,
	}, {
		Create("UIPadding", {
			PaddingBottom = UDim.new(0, 6),
			PaddingTop = UDim.new(0, 0),
		}),
		Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabHolder.UIListLayout.AbsoluteContentSize.Y + 28)
	end)

	AddScrollAnim(TabHolder)

	local containerFolder = Create("Folder", {
		Parent = canvas_group,
	})

	if not isMobile then
		MakeDraggable(top_frame, canvas_group)
	end

	Library.LoadedWindow = canvas_group

	local Tabs = {}

	local TabModule = require(Components.tab):Init(containerFolder)
	function Tabs:AddTab(title)
		return TabModule:New(title, TabHolder)
	end
	function Tabs:SelectTab(Tab)
		Tab = Tab or 1
		TabModule:SelectTab(Tab)
	end

	return Tabs
end
return Library

end)() end,
    [3] = function()local wax,script,require=ImportGlobals(3)local ImportGlobals return (function(...)local Tools = require(script.Parent.Parent.tools)
local ButtonComponent = require(script.Parent.Parent.elements.buttons)

local Create = Tools.Create

local DialogModule = {}
local ActiveDialog = nil

function DialogModule:Create(config, parent)
    -- Remove existing dialog if any
    if ActiveDialog then
        ActiveDialog:Destroy()
    end

    local scrolling_frame = Instance.new("ScrollingFrame")
    scrolling_frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrolling_frame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrolling_frame.ScrollBarImageColor3 = Color3.new(0.109804, 0.109804, 0.117647)
    scrolling_frame.ScrollBarThickness = 4
    scrolling_frame.Active = true
    scrolling_frame.BackgroundColor3 = Color3.new(0, 0, 0)
    scrolling_frame.BackgroundTransparency = 0.1
    scrolling_frame.BorderColor3 = Color3.new(0, 0, 0)
    scrolling_frame.BorderSizePixel = 0
    scrolling_frame.Size = UDim2.new(1, 0, 1, 0)
    scrolling_frame.Visible = true
    scrolling_frame.ZIndex = 100
    scrolling_frame.Parent = parent

    -- Add a full-frame button to prevent clicks passing through
    local blocker = Instance.new("TextButton")
    blocker.Size = UDim2.new(1, 0, 1, 0)
    blocker.Position = UDim2.new(0, 0, 0, 0)
    blocker.BackgroundTransparency = 1 -- Fully transparent
    blocker.Text = "" -- No text
    blocker.AutoButtonColor = false -- Prevents hover effects
    blocker.Parent = scrolling_frame

    local uipadding_3 = Instance.new("UIPadding")
    uipadding_3.PaddingBottom = UDim.new(0, 45)
    uipadding_3.PaddingTop = UDim.new(0, 45)
    uipadding_3.Parent = scrolling_frame

    local dialog = Create("CanvasGroup", {
        AnchorPoint = Vector2.new(0.5, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(0, 400, 0, 0),
        ThemeProps = {
            BackgroundColor3 = "maincolor",
        },
        Parent = scrolling_frame,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Create("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            ThemeProps = { Color = "bordercolor" },
            Thickness = 1,
        }),
    })

    local uilist_layout = Instance.new("UIListLayout")
    uilist_layout.SortOrder = Enum.SortOrder.LayoutOrder
    uilist_layout.Parent = dialog

    -- Create top bar with title
    Create("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        ThemeProps = { BackgroundColor3 = "maincolor" },
        Parent = dialog,
    }, {
        Create("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            ThemeProps = { Color = "bordercolor" },
            Thickness = 1,
        }),
        Create("TextLabel", {
            Font = Enum.Font.GothamMedium,
            Text = config.Title,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(1, -24, 1, 0),
            BackgroundTransparency = 1,
            ThemeProps = { TextColor3 = "titlecolor" },
        }),
    })

    -- Create content container
    local content = Create("TextLabel", {
        Text = config.Content,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Size = UDim2.new(1, -24, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0, 12, 0, 50),
        RichText = true,
        BackgroundTransparency = 1,
        ThemeProps = { TextColor3 = "descriptioncolor" },
        Parent = dialog,
    })

    local uipadding = Instance.new("UIPadding")
    uipadding.PaddingBottom = UDim.new(0, 8)
    uipadding.PaddingLeft = UDim.new(0, 12)
    uipadding.PaddingRight = UDim.new(0, 12)
    uipadding.PaddingTop = UDim.new(0, 8)
    uipadding.Parent = content

    -- Create button container
    local buttonContainer = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 52),
        AutomaticSize = Enum.AutomaticSize.Y,
        ThemeProps = { BackgroundColor3 = "maincolor" },
        Parent = dialog,
    }, {
        Create("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            ThemeProps = { Color = "bordercolor" },
            Thickness = 1,
        }),
        Create("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
        }),
        Create("UIListLayout", {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    -- Add buttons
    for i, buttonConfig in ipairs(config.Buttons) do
        local wrappedCallback = function()
            buttonConfig.Callback()
            scrolling_frame:Destroy()
        end

        -- Create a new button instance with the container
        local button = setmetatable({
            Container = buttonContainer
        }, ButtonComponent):New({
            Title = buttonConfig.Title,
            Variant = buttonConfig.Variant or (i == 1 and "Primary" or "Ghost"),
            Callback = wrappedCallback,
        })
    end

    ActiveDialog = scrolling_frame
    return dialog
end


return DialogModule

end)() end,
    [4] = function()local wax,script,require=ImportGlobals(4)local ImportGlobals return (function(...)local Tools = require(script.Parent.Parent.tools)
local Create = Tools.Create

return function(title, desc, parent)
	local Element = {}
	Element.Frame = Create("TextButton", {
		Font = Enum.Font.SourceSans,
		Text = "",
		Name = "Element",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 14,
		AutomaticSize = Enum.AutomaticSize.Y,

		BackgroundTransparency = 1,
		ThemeProps = {
			BackgroundColor3 = "maincolor",
		},
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0.519230783, 0),
		Size = UDim2.new(1, 0, 0, 0),
		Visible = true,
		Parent = parent,
	}, {
		Create("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, {}),
	})

	Element.topbox = Create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,

		BackgroundTransparency = 1,
		ThemeProps = {
			BackgroundColor3 = "maincolor",
		},
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		Visible = true,
		Parent = Element.Frame,
	})

	local name = Create("TextLabel", {
		Font = Enum.Font.Gotham,
		LineHeight = 1.2,
		RichText = true,
		Text = title,
		ThemeProps = {
			TextColor3 = "titlecolor",
			BackgroundColor3 = "maincolor",
		},
		TextSize = 16,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y,

		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		Visible = true,
		Parent = Element.topbox,
		Name = "Title",
	}, {
		Create("UIPadding", {
			PaddingBottom = UDim.new(0, 0),
			PaddingLeft = UDim.new(0, 0),
			PaddingRight = UDim.new(0, 36),
			PaddingTop = UDim.new(0, 2),
			Archivable = true,
		}),
	})

	local description = Create("TextLabel", {
		Font = Enum.Font.Gotham,
		RichText = true,
		Name = "Description",
		-- TextColor3 = Color3.fromRGB(168, 168, 168),
		ThemeProps = {
			TextColor3 = "elementdescription",
			BackgroundColor3 = "maincolor",
		},
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = desc,
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 23),
		Size = UDim2.new(1, 0, 0, 0),
		Visible = true,
		Parent = Element.Frame,
	}, {})

	function Element:SetTitle(Set)
		name.Text = Set
	end

	function Element:SetDesc(Set)
		if Set == nil then
			Set = ""
		end
		if Set == "" then
			description.Visible = false
		else
			description.Visible = true
		end
		description.Text = Set
	end

	Element:SetDesc(desc)
	Element:SetTitle(title)

	function Element:Destroy()
		Element.Frame:Destroy()
	end

	return Element
end

end)() end,
    [5] = function()local wax,script,require=ImportGlobals(5)local ImportGlobals return (function(...)local Tools = require(script.Parent.Parent.tools)
local TweenService = game:GetService("TweenService")

local Create = Tools.Create
local AddConnection = Tools.AddConnection

local Notif = {}

function Notif:Init(Gui)
    self.MainHolder = Create("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        BackgroundColor3 = Color3.fromRGB(255,255,255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0,0,0),
        BorderSizePixel = 0,
        Position = UDim2.new(1, 0, 1, 0),
        Size = UDim2.new(0, 262, 0, 100),
        Visible = true,
        Parent = Gui,
    }, {
        Create("UIPadding", {
            PaddingBottom = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 0),
            PaddingRight = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 0),
            Archivable = true,
        }),
        Create("UIListLayout", {
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Padding = UDim.new(0, 8),
        })
    })
    
end

function Notif:ShowNotification(titleText, descriptionText, duration)
    local main = Create("CanvasGroup", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(9, 9, 9),
        BackgroundTransparency = 1, -- Начальная прозрачность для эффекта появления
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Size = UDim2.new(0, 300, 0, 0),
        Position = UDim2.new(1, -10, 0.5, -150),
        AnchorPoint = Vector2.new(1, 0.5),
        Visible = true,
        Parent = self.MainHolder,
    }, {
        Create("UICorner", {
            CornerRadius = UDim.new(0, 6),
        }),
        Create("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = Color3.fromRGB(23, 23, 23),
            Thickness = 1,
        }),
    })

    local holderin = Create("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        Visible = true,
        Parent = main,
    }, {
        Create("UIPadding", {
            PaddingBottom = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 14),
            PaddingRight = UDim.new(0, 14),
            PaddingTop = UDim.new(0, 12),
        }),
        Create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    local topframe = Create("Frame", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Visible = true,
        Parent = holderin,
    })

    local user = Create("ImageLabel", {
        Image = "rbxassetid://10723415903",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 18, 0, 18),
        Visible = true,
        Parent = topframe,
    })

    local title = Create("TextLabel", {
        Font = Enum.Font.GothamMedium,
        LineHeight = 1.2,
        RichText = true,
        TextColor3 = Color3.fromRGB(225, 225, 225),
        TextSize = 18,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Text = titleText,
        Visible = true,
        Parent = topframe,
    }, {
        Create("UIPadding", {
            PaddingLeft = UDim.new(0, 24),
        }),
    })

    local description = Create("TextLabel", {
        Font = Enum.Font.Gotham,
        RichText = true,
        TextColor3 = Color3.fromRGB(225, 225, 225),
        TextSize = 16,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        AutomaticSize = Enum.AutomaticSize.XY,
        LayoutOrder = 1,
        BackgroundTransparency = 1,
        Text = descriptionText,
        Visible = true,
        Parent = holderin,
    })

    local progress = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 2),
        Visible = true,
        Parent = main,
    }, {
        Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
        }),
    })

    local progressindicator = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Size = UDim2.new(1, 0, 0, 2),
        Visible = true,
        Parent = progress,
    }, {
        Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
        }),
    })

    -- Анимация плавного появления для всех элементов
    local fadeInTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local fadeInTween = TweenService:Create(main, fadeInTweenInfo, {BackgroundTransparency = 0.4})
    fadeInTween:Play()

    local fadeInTweenTitle = TweenService:Create(title, fadeInTweenInfo, {TextTransparency = 0})
    fadeInTweenTitle:Play()

    local fadeInTweenDescription = TweenService:Create(description, fadeInTweenInfo, {TextTransparency = 0})
    fadeInTweenDescription:Play()

    local fadeInTweenUser = TweenService:Create(user, fadeInTweenInfo, {ImageTransparency = 0})
    fadeInTweenUser:Play()

    -- Tween для прогресса
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
    local tween = TweenService:Create(progressindicator, tweenInfo, {Size = UDim2.new(0, 0, 0, 2)})
    tween:Play()

    -- Удаление уведомления после завершения Tween
    tween.Completed:Connect(function()
        main:Destroy()
    end)

    -- if not game:GetService("RunService"):IsStudio() then
    --require(script.Parent.Parent.Packages.blurModule):ModifyFrame(main)
    -- end
end

return Notif

end)() end,
    [6] = function()local wax,script,require=ImportGlobals(6)local ImportGlobals return (function(...)local Tools = require(script.Parent.Parent.tools)

local Create = Tools.Create
local AddConnection = Tools.AddConnection

return function(cfgs, Parent)
	cfgs = cfgs or {}
	cfgs.Title = cfgs.Title or nil
	cfgs.Description = cfgs.Description or nil
	cfgs.Defualt  = cfgs.Defualt or false
	cfgs.Locked = cfgs.Locked or false
	cfgs.TitleTextSize = cfgs.TitleTextSize or 14

	local Section = {}

	Section.SectionFrame = Create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		Name = "Section",
		BackgroundTransparency = 1,
		ThemeProps = {
			BackgroundColor3 = "maincolor",
		},
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, 0, 0, 0),
		Visible = true,
		Parent = Parent,
	}, {
		Create("UIPadding", {
			PaddingBottom = UDim.new(0, 6),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 6),
			Archivable = true,
		}),
		Create("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeProps = {
				Color = "bordercolor"
			},
			Enabled = true,
			LineJoinMode = Enum.LineJoinMode.Round,
			Thickness = 1,
			Archivable = true,
		}),
		Create("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local topbox = Create("TextButton", {
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = "",
		BackgroundTransparency = 1,
		ThemeProps = {
			BackgroundColor3 = "maincolor",
		},
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, 0, 0, 0),
		Visible = true,
		Parent = Section.SectionFrame,
	}, {
		Create("UIListLayout", {
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, {}),
	})

	local chevronIcon = Create("ImageButton", {
		ThemeProps = {
			ImageColor3 = "titlecolor",
		},
		Image = "rbxassetid://15269180996",
		ImageRectOffset = Vector2.new(0, 257),
		ImageRectSize = Vector2.new(256, 256),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 24, 0, 24),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Rotation = 90,
		Name = "chevron-down",
		ZIndex = 99,
		-- Parent = topbox,
	})
	
	local name = Create("TextLabel", {
		Font = Enum.Font.Gotham,
		LineHeight = 1.2000000476837158,
		RichText = true,
		-- TextColor3 = Color3.fromRGB(234, 234, 234),
		ThemeProps = {
			TextColor3 = "titlecolor",
			BackgroundColor3 = "maincolor",
		},
		TextSize = 14,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = "",
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		Visible = false,
		Parent = topbox,
	}, {
		chevronIcon
	})
	if cfgs.description ~= nil and cfgs.description ~= "" then
	local description = Create("TextLabel", {
		Font = Enum.Font.Gotham,
		RichText = true,
		-- TextColor3 = Color3.fromRGB(168, 168, 168),
		ThemeProps = {
			TextColor3 = "descriptioncolor",
			BackgroundColor3 = "maincolor",
		},
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = "",
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 23),
		Size = UDim2.new(1, 0, 0, 16),
		Visible = true,
		Parent = topbox,
	}, {})
	description.Text = cfgs.Description or ""
	description.Visible = cfgs.Description ~= nil
	end

	if cfgs.Title ~= nil and cfgs.Title ~= "" then
		-- topbox.AutomaticSize = Enum.AutomaticSize.Y

		-- name.AutomaticSize = Enum.AutomaticSize.Y
		-- name.TextWrapped = true
		name.Size = UDim2.new(1, 0, 0, 16)
		name.Text = cfgs.Title
		name.TextSize = cfgs.TitleTextSize
		name.Visible = true
	end

	Section.SectionContainer = Create("Frame", {
		-- AutomaticSize = Enum.AutomaticSize.Y,
		Name = "SectionContainer",
		ClipsDescendants = true,
		BackgroundTransparency = 1,
		ThemeProps = {
			BackgroundColor3 = "maincolor",
		},
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, 0, 0, 0),
		Visible = true,
		Parent = Section.SectionFrame,
	}, {
		Create("UIListLayout", {
			Padding = UDim.new(0, 12),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, {}),
		Create("UIPadding", {
			PaddingBottom = UDim.new(0, 1),
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 1),
			PaddingTop = UDim.new(0, 1),
			Archivable = true,
		}),
	})

	local isExpanded = cfgs.Defualt
	if cfgs.Defualt == true then
	chevronIcon.Rotation = 0
	end
	local function toggleSection()
		isExpanded = not isExpanded
		local targetRotation = isExpanded and 0 or 90
		
		-- Animate chevron rotation
		game:GetService("TweenService"):Create(chevronIcon, TweenInfo.new(0.3), {
			Rotation = targetRotation
		}):Play()
		
		-- Animate section container
		local targetSize = isExpanded and UDim2.new(1, 0, 0, Section.SectionContainer.UIListLayout.AbsoluteContentSize.Y + 18) or UDim2.new(1, 0, 0, 0)
		game:GetService("TweenService"):Create(Section.SectionContainer, TweenInfo.new(0.3), {
			Size = targetSize
		}):Play()
	end
	if cfgs.Locked == false then
	AddConnection(topbox.MouseButton1Click, toggleSection)
	AddConnection(chevronIcon.MouseButton1Click, toggleSection)
	end
	if cfgs.Locked == true then
	topbox:Destroy()
	end
	
	AddConnection(Section.SectionContainer.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		if isExpanded then
			Section.SectionContainer.Size = UDim2.new(1, 0, 0, Section.SectionContainer.UIListLayout.AbsoluteContentSize.Y + 18)
		end
	end)

	return Section
end
end)() end,
    [7] = function()local wax,script,require=ImportGlobals(7)local ImportGlobals return (function(...)local Tools = require(script.Parent.Parent.tools)

local TweenService = game:GetService("TweenService")

local Create = Tools.Create
local AddConnection = Tools.AddConnection
local AddScrollAnim = Tools.AddScrollAnim
local CurrentThemeProps = Tools.GetPropsCurrentTheme()

-- Add debug toggle
local SEARCH_DEBUG = false

local function debugLog(...)
	if SEARCH_DEBUG then
		print("[Search]", ...)
	end
end

local TabModule = {
	Window = nil,
	Tabs = {},
	Containers = {},
	SelectedTab = 0,
	TabCount = 0,
}

function TabModule:Init(Window)
	TabModule.Window = Window
	return TabModule
end

function TabModule:New(Title, Parent)
	local Library = require(script.Parent.Parent)
	local Window = TabModule.Window
	local Elements = Library.Elements

	TabModule.TabCount = TabModule.TabCount + 1
	local TabIndex = TabModule.TabCount

	local Tab = {
		Selected = false,
		Name = Title,
		Type = "Tab",
	}

	Tab.TabBtn = Create("TextButton", {
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 32),
		Parent = Parent,
		ThemeProps = {
			BackgroundColor3 = "maincolor",
		},
		BorderSizePixel = 0,
	}, {
		Create("TextLabel", {
			Name = "Title",
			Font = Enum.Font.Gotham,
			TextColor3 = Color3.fromRGB(63, 63, 63),
			TextSize = 14,
			ThemeProps = {
				BackgroundColor3 = "maincolor",
			},
			BorderSizePixel = 0,
			TextXAlignment = Enum.TextXAlignment.Left,
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 14, 0.5, 0),
			Size = UDim2.new(0.8, 0, 0.9, 0),
			Text = Title,
		}),
		Create("Frame", {
			Name = "Line",
			BackgroundColor3 = Color3.fromRGB(29, 29, 29),
			Position = UDim2.new(0, 4, 0, 0),
			Size = UDim2.new(0, 2, 1, 0),
			BorderSizePixel = 0,
		}),
	})
	Tab.Container = Create("ScrollingFrame", {
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ThemeProps = {
			ScrollBarImageColor3 = "scrollocolor",
			BackgroundColor3 = "maincolor",
		},
		ScrollBarThickness = 2,
		ScrollBarImageTransparency = 1,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 140, 0, 40),
		Size = UDim2.new(1, -140, 1, -40),
		Visible = false,
		Parent = TabModule.Window,
	}, {
		Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	AddScrollAnim(Tab.Container)

	AddConnection(Tab.Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		Tab.Container.CanvasSize = UDim2.new(0, 0, 0, Tab.Container.UIListLayout.AbsoluteContentSize.Y + 28)
	end)

	-- Add search container at the top of the tab container
	Tab.SearchContainer = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		Parent = Parent,
		LayoutOrder = -1, -- Make sure it appears at the top
		ThemeProps = {
			BackgroundColor3 = "maincolor",
		},
	})

	local SearchBox = Create("TextBox", {
		Size = UDim2.new(1, 0, 0, 32),
		Position = UDim2.new(0, 0, 0, 0),
		PlaceholderText = "Search elements...",
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
		Font = Enum.Font.Gotham,
		TextSize = 14,
		BackgroundTransparency = 1,
		ThemeProps = {
			-- BackgroundColor3 = "elementbackground",
			TextColor3 = "titlecolor",
			PlaceholderColor3 = "descriptioncolor",
		},
		Parent = Tab.SearchContainer,
		ClearTextOnFocus = false,
	}, {
		Create("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),

		Create("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeProps = {
				Color = "bordercolor",
			},
			Thickness = 1,
		}),
	})

	-- Function to filter elements based on search text
	local function searchInElement(element, searchText)
		local title = element:FindFirstChild("Title", true)
		local desc = element:FindFirstChild("Description", true)

		if title then
			debugLog("Checking title:", title.Text)
			local cleanTitle = title.Text:gsub("^%s+", "")
			if string.find(string.lower(cleanTitle), searchText) then
				debugLog("Found match in title")
				return true
			end
		end

		if desc then
			debugLog("Checking description:", desc.Text)
			if string.find(string.lower(desc.Text), searchText) then
				debugLog("Found match in description")
				return true
			end
		end

		return false
	end

	local function updateSearch()
		local searchText = string.lower(SearchBox.Text)
		debugLog("Search text:", searchText)

		if not Tab.Container.Visible then
			debugLog("Tab not visible, skipping search")
			return
		end

		-- Loop through all children in the container
		for _, child in ipairs(Tab.Container:GetChildren()) do
			if child ~= SearchContainer then
				if child.Name == "Section" then
					-- Handle section elements
					local sectionContainer = child:FindFirstChild("SectionContainer")
					if sectionContainer then
						local visible = false
						debugLog("Checking section:", child.Name)

						-- Search through elements in section
						for _, element in ipairs(sectionContainer:GetChildren()) do
							if element.Name == "Element" then
								local elementVisible = searchInElement(element, searchText)
								element.Visible = elementVisible or searchText == ""
								if elementVisible then
									visible = true
								end
							end
						end

						-- Show section if any elements match or search is empty
						child.Visible = visible or searchText == ""
						debugLog("Section visibility:", child.Visible)
					end
				elseif child.Name == "Element" then
					-- Handle standalone elements
					local elementVisible = searchInElement(child, searchText)
					child.Visible = elementVisible or searchText == ""
					debugLog("Standalone element visibility:", child.Visible)
				end
			end
		end
	end

	-- Update search when tab is selected
	AddConnection(Tab.Container:GetPropertyChangedSignal("Visible"), function()
		if Tab.Container.Visible then
			updateSearch()
		end
	end)

	AddConnection(SearchBox:GetPropertyChangedSignal("Text"), updateSearch)

	Tab.ContainerFrame = Tab.Container

	AddConnection(Tab.TabBtn.MouseButton1Click, function()
		TabModule:SelectTab(TabIndex)
	end)

	TabModule.Containers[TabIndex] = Tab.ContainerFrame
	TabModule.Tabs[TabIndex] = Tab

	function Tab:AddSection(cfgs)
		cfgs = cfgs or {}
		cfgs.Title = cfgs.Title or nil
		cfgs.Description = cfgs.Description or nil
		local Section = { Type = "Section" }

		local SectionFrame = require(script.Parent.section)(cfgs, Tab.Container)
		Section.Container = SectionFrame.SectionContainer

		function Section:AddGroupButton()
			local GroupButton = { Type = "Group" }
			GroupButton.GroupContainer = Create("Frame", {
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				Visible = true,
				ThemeProps = {
					BackgroundColor3 = "maincolor",
				},
				BorderSizePixel = 0,
				Parent = SectionFrame.SectionContainer,
			}, {
				Create("UIListLayout", {
					Padding = UDim.new(0, 6),
					Wraps = true,
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			})

			GroupButton.Container = GroupButton.GroupContainer

			setmetatable(GroupButton, Elements)
			return GroupButton
		end

		setmetatable(Section, Elements)
		return Section
	end

	-- setmetatable(Tab, Elements)
	return Tab
end

function TabModule:SelectTab(Tab)
    TabModule.SelectedTab = Tab

    for _, v in next, TabModule.Tabs do
        TweenService:Create(
            v.TabBtn.Title,
            TweenInfo.new(0.125, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            { TextColor3 = CurrentThemeProps.offTextBtn }
        ):Play()
        TweenService:Create(
            v.TabBtn.Line,
            TweenInfo.new(0.125, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            { BackgroundColor3 = CurrentThemeProps.offBgLineBtn }
        ):Play()
        v.Selected = false
        
        -- Hide search container for non-selected tabs
        if v.SearchContainer then
            v.SearchContainer.Visible = false
        end
    end

    local selectedTab = TabModule.Tabs[Tab]
    TweenService:Create(
        selectedTab.TabBtn.Title,
        TweenInfo.new(0.125, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        { TextColor3 = CurrentThemeProps.onTextBtn }
    ):Play()
    TweenService:Create(
        selectedTab.TabBtn.Line,
        TweenInfo.new(0.125, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        { BackgroundColor3 = CurrentThemeProps.onBgLineBtn }
    ):Play()

    task.spawn(function()
        for _, Container in pairs(TabModule.Containers) do
            Container.Visible = false
        end

        -- Show search container for selected tab
        if selectedTab.SearchContainer then
            selectedTab.SearchContainer.Visible = true
        end

        TabModule.Containers[Tab].Visible = true
    end)
end

return TabModule

end)() end,
    [8] = function()local wax,script,require=ImportGlobals(8)local ImportGlobals return (function(...)local Elements = {}

for _, Theme in next, script:GetChildren() do
	table.insert(Elements, require(Theme))
end

return Elements
end)() end,
    [9] = function()local wax,script,require=ImportGlobals(9)local ImportGlobals return (function(...)local UserInputService = game:GetService("UserInputService")

local Tools = require(script.Parent.Parent.tools)
local Components = script.Parent.Parent.components

local Create = Tools.Create
local AddConnection = Tools.AddConnection

local BlacklistedKeys = {
	Enum.KeyCode.Unknown,
	Enum.KeyCode.W,
	Enum.KeyCode.A,
	Enum.KeyCode.S,
	Enum.KeyCode.D,
	Enum.KeyCode.Up,
	Enum.KeyCode.Left,
	Enum.KeyCode.Down,
	Enum.KeyCode.Right,
	Enum.KeyCode.Slash,
	Enum.KeyCode.Tab,
	Enum.KeyCode.Backspace,
	Enum.KeyCode.Escape,
}

local Element = {}
Element.__index = Element
Element.__type = "Bind"

function Element:New(Idx, Config)
	assert(Config.Title, "Bind - Missing Title")
	Config.Description = Config.Description or nil
	Config.Hold = Config.Hold or false
	Config.Callback = Config.Callback or function() end
	Config.ChangeCallback = Config.ChangeCallback or function() end
	local Bind = { Value = nil, Binding = false, Type = "Bind" }
	local Holding = false

	local BindFrame = require(Components.element)(Config.Title, Config.Description, self.Container)

	local value = Create("TextLabel", {
		Font = Enum.Font.Gotham,
		RichText = true,
		Text = "",
		ThemeProps = {
			BackgroundColor3 = "bordercolor",
			TextColor3 = "titlecolor",
		},
		TextSize = 14,
		AnchorPoint = Vector2.new(1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 0, 0, 16),
		Visible = true,
		Parent = BindFrame.topbox,
	}, {
		Create("UIPadding", {
			PaddingBottom = UDim.new(0, 0),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
			PaddingTop = UDim.new(0, 0),
			Archivable = true,
		}),
		Create("UICorner", {
			CornerRadius = UDim.new(0, 4),
			Archivable = true,
		}),
	})

	AddConnection(BindFrame.Frame.InputEnded, function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			if Bind.Binding then
				return
			end
			Bind.Binding = true
			value.Text = "..."
		end
	end)

	function Bind:Set(Key)
		Bind.Binding = false
		Bind.Value = Key or Bind.Value
		Bind.Value = Bind.Value.Name or Bind.Value
		value.Text = Bind.Value
		Config.ChangeCallback(Bind.Value)
	end

	AddConnection(UserInputService.InputBegan, function(Input)
		if UserInputService:GetFocusedTextBox() then
			return
		end
		if (Input.KeyCode.Name == Bind.Value or Input.UserInputType.Name == Bind.Value) and not Bind.Binding then
			if Config.Hold then
				Holding = true
				Config.Callback(Holding)
			else
				Config.Callback()
			end
		elseif Bind.Binding then
			local Key
			pcall(function()
				if not table.find(BlacklistedKeys, Input.KeyCode) then
					Key = Input.KeyCode
				end
			end)
			Key = Key or Bind.Value
			Bind:Set(Key)
		end
	end)

	AddConnection(UserInputService.InputEnded, function(Input)
		if Input.KeyCode.Name == Bind.Value or Input.UserInputType.Name == Bind.Value then
			if Config.Hold and Holding then
				Holding = false
				Config.Callback(Holding)
			end
		end
	end)

	Bind:Set(Config.Default)

	self.Library.Flags[Idx] = Bind
	return Bind
end

return Element

end)() end,
    [10] = function()local wax,script,require=ImportGlobals(10)local ImportGlobals return (function(...)local TweenService = game:GetService("TweenService")

local Tools = require(script.Parent.Parent.tools)

local Create = Tools.Create
local AddConnection = Tools.AddConnection
local CurrentThemeProps = Tools.GetPropsCurrentTheme()

local Element = {}
Element.__index = Element
Element.__type = "Button"

local ButtonStyles = {
	Primary = {
		TextColor3 = Color3.fromRGB(9, 9, 9),
		BackgroundColor3 = CurrentThemeProps.primarycolor,
		BackgroundTransparency = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		HoverConfig = {
			BackgroundTransparency = 0.1,
		},
		FocusConfig = {
			BackgroundTransparency = 0.2,
		},
	},
	Ghost = {
		TextColor3 = Color3.fromRGB(244, 244, 244),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		HoverConfig = {
			BackgroundTransparency = 0.98,
		},
		FocusConfig = {
			BackgroundTransparency = 0.94,
		},
	},
	Outline = {
		TextColor3 = Color3.fromRGB(244, 244, 244),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 1,
		UIStroke = {
			Color = Color3.fromRGB(39, 39, 42),
			Thickness = 1,
		},
		HoverConfig = {
			BackgroundTransparency = 0.94,
		},
		FocusConfig = {
			BackgroundTransparency = 0.98,
		},
	},
}

local function ApplyTweens(button, config, uiStroke)
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tweenGoals = {}

	for property, value in pairs(config) do
		if property ~= "UIStroke" then
			tweenGoals[property] = value
		end
	end

	local tween = TweenService:Create(button, tweenInfo, tweenGoals)
	tween:Play()

	if uiStroke and config.UIStroke then
		local strokeTweenGoals = {}
		for property, value in pairs(config.UIStroke) do
			strokeTweenGoals[property] = value
		end
		local strokeTween = TweenService:Create(uiStroke, tweenInfo, strokeTweenGoals)
		strokeTween:Play()
	end
end

local function CreateButton(style, text, parent)
	local config = ButtonStyles[style]
	assert(config, "Invalid button style: " .. style)

	local button = Create("TextButton", {
		Font = Enum.Font.Gotham,
		LineHeight = 1.25,
		Text = text,
		TextColor3 = config.TextColor3,
		TextSize = 14,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = config.BackgroundColor3,
		BackgroundTransparency = config.BackgroundTransparency,
		BorderColor3 = config.BorderColor3,
		BorderSizePixel = config.BorderSizePixel,
		Visible = true,
		Parent = parent,
	}, {
		Create("UIPadding", {
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
			PaddingTop = UDim.new(0, 8),
			Archivable = true,
		}),
		Create("UICorner", {
			CornerRadius = UDim.new(0, 6),
			Archivable = true,
		}),
	})

	if config.UIStroke then
		Create("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = config.UIStroke.Color,
			Enabled = true,
			LineJoinMode = Enum.LineJoinMode.Round,
			Thickness = config.UIStroke.Thickness,
			Archivable = true,
			Parent = button,
		})
	end

	button.MouseEnter:Connect(function()
		if config.HoverConfig then
			ApplyTweens(button, config.HoverConfig)
		end
	end)

	button.MouseLeave:Connect(function()
		ApplyTweens(button, {
			BackgroundColor3 = config.BackgroundColor3,
			TextColor3 = config.TextColor3,
			BackgroundTransparency = config.BackgroundTransparency,
			BorderColor3 = config.BorderColor3,
			BorderSizePixel = config.BorderSizePixel,
			UIStroke = config.UIStroke,
		})
	end)

	button.MouseButton1Down:Connect(function()
		if config.FocusConfig then
			ApplyTweens(button, config.FocusConfig)
		end
	end)

	button.MouseButton1Up:Connect(function()
		if config.HoverConfig then
			ApplyTweens(button, config.HoverConfig)
		else
			ApplyTweens(button, {
				BackgroundColor3 = config.BackgroundColor3,
				TextColor3 = config.TextColor3,
				BackgroundTransparency = config.BackgroundTransparency,
				BorderColor3 = config.BorderColor3,
				BorderSizePixel = config.BorderSizePixel,
				UIStroke = config.UIStroke,
			})
		end
	end)

	return button
end

function Element:New(Config)
	assert(Config.Title, "Button - Missing Title")
	Config.Variant = Config.Variant or "Primary"
	Config.Callback = Config.Callback or function() end
	local Button = {}

	Button.StyledButton = CreateButton(Config.Variant, Config.Title, self.Container)
	Button.StyledButton.MouseButton1Click:Connect(Config.Callback)

	return Button
end

return Element

end)() end,
    [11] = function()local wax,script,require=ImportGlobals(11)local ImportGlobals return (function(...)local Tools = require(script.Parent.Parent.tools)
local Components = script.Parent.Parent.components

local TweenService = game:GetService("TweenService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local mouse = LocalPlayer:GetMouse()

local Create = Tools.Create
local AddConnection = Tools.AddConnection

local HueSelectionPosition, RainbowColorValue = 0, 0
local rainbowIncrement, hueIncrement, maxHuePosition = 1 / 255, 1, 127
coroutine.wrap(function()
	while true do
		RainbowColorValue = (RainbowColorValue + rainbowIncrement) % 1
		HueSelectionPosition = (HueSelectionPosition + hueIncrement) % maxHuePosition
		wait(0.06)
	end
end)()

local Element = {}
Element.__index = Element
Element.__type = "Colorpicker"

function Element:New(Idx, Config)
	assert(Config.Title, "Colorpicker - Missing Title")
	Config.Description = Config.Description or nil
	assert(Config.Default, "AddColorPicker: Missing default value.")

    local Colorpicker = {
        Value = Config.Default,
        Transparency = Config.Transparency or 0,
        Type = "Colorpicker",
        Callback = Config.Callback or function(Color) end,
        RainbowColorPicker = false,
        ColorpickerToggle = false, -- Added missing toggle state
    }

	local RainbowColorPicker = Colorpicker.RainbowColorPicker

	function Colorpicker:SetHSVFromRGB(Color)
		local H, S, V = Color3.toHSV(Color)
		Colorpicker.Hue = H
		Colorpicker.Sat = S
		Colorpicker.Vib = V
	end
	Colorpicker:SetHSVFromRGB(Colorpicker.Value)

	local ColorpickerFrame = require(Components.element)(Config.Title, Config.Description, self.Container)

	local InputFrame = Create("CanvasGroup", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 30),
		Visible = true,
		Parent = ColorpickerFrame.Frame,
	}, {
		Create("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Color3.fromRGB(24, 24, 26),
			Enabled = true,
			LineJoinMode = Enum.LineJoinMode.Round,
			Thickness = 1,
			Archivable = true,
		}),
		Create("UICorner", {
			CornerRadius = UDim.new(0, 4),
			Archivable = true,
		}),
	})

	local colorBox = Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(3, 255, 150),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 30, 1, 0),
		Visible = true,
		Parent = InputFrame,
	}, {
		Create("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Color3.fromRGB(24, 24, 26),
			Enabled = true,
			LineJoinMode = Enum.LineJoinMode.Round,
			Thickness = 1,
			Archivable = true,
		}),
	})

	local inputHex = Create("TextBox", {
		Font = Enum.Font.GothamMedium,
		LineHeight = 1.2000000476837158,
		PlaceholderColor3 = Color3.fromRGB(178, 178, 178),
		Text = "#03ff96",
		TextColor3 = Color3.fromRGB(178, 178, 178),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(1, -30, 1, 0),
		Visible = true,
		Parent = InputFrame,
	}, {
		Create("UIPadding", {
			PaddingBottom = UDim.new(0, 0),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 0),
			Archivable = true,
		}),
	})

	AddConnection(inputHex.FocusLost, function(Enter)
		if Enter then
			local Success, Result = pcall(Color3.fromHex, inputHex.Text)
			if Success and typeof(Result) == "Color3" then
				Colorpicker.Hue, Colorpicker.Sat, Colorpicker.Vib = Color3.toHSV(Result)
			end
		end
	end)

	-- Colorpicker
	local colorpicker_frame = Create("TextButton", {
		AutoButtonColor = false,
		Text = "",
		ZIndex = 20,
		BackgroundColor3 = Color3.fromRGB(9, 9, 11),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 46),
		Size = UDim2.new(1, 0, 0, 166),
		Visible = false,
		Parent = ColorpickerFrame.Frame,
	}, {
		Create("UIPadding", {
			PaddingBottom = UDim.new(0, 6),
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
			PaddingTop = UDim.new(0, 6),
			Archivable = true,
		}),
	})

	local color = Create("ImageLabel", {
		Image = "rbxassetid://4155801252",
		BackgroundColor3 = Color3.fromRGB(255, 0, 4),
		Size = UDim2.new(1, -10, 0, 127),
		Visible = true,
		ZIndex = 10,
		Parent = colorpicker_frame,
	}, {
		Create("UICorner", {
			CornerRadius = UDim.new(0, 8),
			Archivable = true,
		}),
	})

	local color_selection = Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 0, 0),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 12, 0, 12),
		Visible = true,
		Parent = color,
	}, {
		Create("UICorner", {
			CornerRadius = UDim.new(1, 0),
			Archivable = true,
		}),
		Create("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			Color = Color3.fromRGB(255, 255, 255),
			Enabled = true,
			LineJoinMode = Enum.LineJoinMode.Round,
			Thickness = 1.2000000476837158,
			Archivable = true,
		}),
	})

	local hue = Create("ImageLabel", {
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 6, 0, 127),
		Visible = true,
		Parent = colorpicker_frame,
	}, {
		Create("UICorner", {
			CornerRadius = UDim.new(0, 9),
			Archivable = true,
		}),
		Create("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 0, 255)),
				ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
				ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 255, 0)),
				ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 255, 0)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
			}),
			Enabled = true,
			Offset = Vector2.new(0, 0),
			Rotation = 270,
			Archivable = true,
		}),
	})

	local hue_selection = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 0, 0),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.1, 0),
		Size = UDim2.new(0, 8, 0, 8),
		Visible = true,
		Parent = hue,
	}, {
		Create("UICorner", {
			CornerRadius = UDim.new(1, 0),
			Archivable = true,
		}),
		Create("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			Color = Color3.fromRGB(255, 255, 255),
			Enabled = true,
			LineJoinMode = Enum.LineJoinMode.Round,
			Thickness = 1.2000000476837158,
			Archivable = true,
		}),
	})

	local rainbowtoggle = Create("TextButton", {
		Font = Enum.Font.SourceSans,
		Text = "",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 14,
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 16),
		Visible = true,
		Parent = colorpicker_frame,
	})

	local togglebox = Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(250, 250, 250),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 16, 0, 16),
		Visible = true,
		Parent = rainbowtoggle,
	}, {
		Create("UICorner", {
			CornerRadius = UDim.new(0, 5),
			Archivable = true,
		}),
		Create("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Color3.fromRGB(250, 250, 250),
			Enabled = true,
			LineJoinMode = Enum.LineJoinMode.Round,
			Thickness = 1,
			Archivable = true,
		}),

		Create("ImageLabel", {
			Image = "http://www.roblox.com/asset/?id=6031094667",
			ImageColor3 = Color3.fromRGB(9, 9, 11),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 12, 0, 12),
			Visible = true,
		}),
		Create("TextLabel", {
			Font = Enum.Font.Gotham,
			Text = "Rainbow",
			TextColor3 = Color3.fromRGB(234, 234, 234),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 26, 0, 0),
			Size = UDim2.new(1, 0, 0, 16),
			Visible = true,
		}),
	})

	local function UpdateColorPicker()
        if not (Colorpicker.Hue and Colorpicker.Sat and Colorpicker.Vib) then
            warn("Missing HSV values in UpdateColorPicker")
            return
        end
        
        local newColor = Color3.fromHSV(Colorpicker.Hue, Colorpicker.Sat, Colorpicker.Vib)
        colorBox.BackgroundColor3 = newColor
        color.BackgroundColor3 = Color3.fromHSV(Colorpicker.Hue, 1, 1)
        color_selection.BackgroundColor3 = newColor
        
        -- Update hex input safely
        if inputHex then
            inputHex.Text = "#" .. newColor:ToHex()
        end
        
        -- Call callback safely
        pcall(Colorpicker.Callback, newColor)
    end
	
	local function UpdateColorPickerPosition()
		local ColorX = math.clamp(mouse.X - color.AbsolutePosition.X, 0, color.AbsoluteSize.X)
		local ColorY = math.clamp(mouse.Y - color.AbsolutePosition.Y, 0, color.AbsoluteSize.Y)
		color_selection.Position = UDim2.new(ColorX / color.AbsoluteSize.X, 0, ColorY / color.AbsoluteSize.Y, 0)
		Colorpicker.Sat = ColorX / color.AbsoluteSize.X
		Colorpicker.Vib = 1 - (ColorY / color.AbsoluteSize.Y)
		UpdateColorPicker()
		inputHex.Text = "#" .. Color3.fromHSV(Colorpicker.Hue, Colorpicker.Sat, Colorpicker.Vib):ToHex()
	end
	
	local function UpdateHuePickerPosition()
		local HueY = math.clamp(mouse.Y - hue.AbsolutePosition.Y, 0, hue.AbsoluteSize.Y)
		hue_selection.Position = UDim2.new(0.5, 0, HueY / hue.AbsoluteSize.Y, 0)
		Colorpicker.Hue = HueY / hue.AbsoluteSize.Y
		UpdateColorPicker()
		inputHex.Text = "#" .. Color3.fromHSV(Colorpicker.Hue, Colorpicker.Sat, Colorpicker.Vib):ToHex()
	end
	
	local ColorInput, HueInput = nil, nil
	
	AddConnection(color.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if RainbowColorPicker then
				return
			end
			if ColorInput then
				ColorInput:Disconnect()
			end
			ColorInput = AddConnection(mouse.Move, UpdateColorPickerPosition)
			UpdateColorPickerPosition()
		end
	end)
	
	AddConnection(color.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if ColorInput then
				ColorInput:Disconnect()
				ColorInput = nil
			end
		end
	end)
	
	AddConnection(hue.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if RainbowColorPicker then
				return
			end
			if HueInput then
				HueInput:Disconnect()
			end
			HueInput = AddConnection(mouse.Move, UpdateHuePickerPosition)
			UpdateHuePickerPosition()
		end
	end)
	
	AddConnection(hue.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if HueInput then
				HueInput:Disconnect()
				HueInput = nil
			end
		end
	end)	

	AddConnection(ColorpickerFrame.Frame.MouseButton1Click, function()
		Colorpicker.ColorpickerToggle = not Colorpicker.ColorpickerToggle
		colorpicker_frame.Visible = Colorpicker.ColorpickerToggle
	end)

	AddConnection(rainbowtoggle.MouseButton1Click, function()
		RainbowColorPicker = not RainbowColorPicker
		Colorpicker.RainbowMode = RainbowColorPicker -- Update the Colorpicker table
		TweenService:Create(
			togglebox,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = RainbowColorPicker and 0 or 1 }
		):Play()
		if RainbowColorPicker then
			local function UpdateRainbowColor()
				while RainbowColorPicker do
					Colorpicker.Hue, Colorpicker.Sat, Colorpicker.Vib = RainbowColorValue, 1, 1
					hue_selection.Position = UDim2.new(0.5, 0, 0, HueSelectionPosition)
					hue_selection.Position = UDim2.new(1, -10, 0, 0)
					UpdateColorPicker()
					wait()
				end
			end
			coroutine.wrap(UpdateRainbowColor)()
		end
	end)

    function Colorpicker:Set(newColor)
        if typeof(newColor) ~= "Color3" then
            warn("Invalid color value provided to Set")
            return
        end
        
        self:SetHSVFromRGB(newColor)
        
        -- Update UI elements safely
        if color_selection and colorBox and hue_selection then
            color_selection.Position = UDim2.new(self.Sat, 0, 1 - self.Vib, 0)
            colorBox.BackgroundColor3 = newColor
            hue_selection.Position = UDim2.new(0.5, 0, self.Hue, 0)
            UpdateColorPicker()
        end
    end

	self.Library.Flags[Idx] = Colorpicker
	return Colorpicker
end

return Element

end)() end,
    [12] = function()local wax,script,require=ImportGlobals(12)local ImportGlobals return (function(...)local Tools = require(script.Parent.Parent.tools)
local Components = script.Parent.Parent.components
local TweenService = game:GetService("TweenService")

local Create = Tools.Create
local AddConnection = Tools.AddConnection
local CurrentThemeProps = Tools.GetPropsCurrentTheme()

local Element = {}
Element.__index = Element
Element.__type = "Dropdown"

-- helpers
local function toSet(list)
	local set = {}
	for _, v in ipairs(list) do
		if v ~= nil then set[v] = true end
	end
	return set
end

local TI_150 = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function Element:New(Idx, Config)
	assert(Config.Title, "Dropdown - Missing Title")
	Config.Description   = Config.Description or nil
	Config.Options       = Config.Options or {}
	Config.Default       = Config.Default
	Config.Multiple      = Config.Multiple or false
	Config.MaxOptions    = Config.MaxOptions or math.huge
	Config.PlaceHolder   = Config.PlaceHolder or ""
	Config.IgnoreFirst   = Config.IgnoreFirst or false
	Config.Callback      = Config.Callback or function(_) end

	-- De-dupe once up front
	do
		local seen, unique = {}, {}
		for _, opt in ipairs(Config.Options) do
			if opt ~= nil and not seen[opt] then
				seen[opt] = true
				table.insert(unique, opt)
			end
		end
		Config.Options = unique
	end

	local Dropdown = {
		Type      = "Dropdown",
		Toggled   = false,
		Multiple  = Config.Multiple,
		Options   = table.clone(Config.Options),
		Buttons   = {},      -- [option] = {button, label, check}
		Value     = Config.Multiple and {} or (Config.Default or ""),
		_callback = Config.Callback,
	}

	local Root = require(Components.element)(Config.Title, Config.Description, self.Container)

	-- Head (chips + input)
	local Head = Create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ThemeProps = { BackgroundColor3 = "maincolor" },
		Size = UDim2.new(1, 0, 0, 30),
		Parent = Root.Frame,
	}, {
		Create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, ThemeProps = { Color = "bordercolor" }, Thickness = 1 }),
		Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
		Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Wraps = true }),
		Create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
	})

	local ChipHolder = Create("Frame", {
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Parent = Head,
	}, {
		Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center }),
		Create("UIFlexItem", { FlexMode = Enum.UIFlexMode.Shrink }),
	})

	local SearchBox = Create("TextBox", {
		ClearTextOnFocus = false,
		Font = Enum.Font.Gotham,
		PlaceholderText = Config.PlaceHolder,
		Text = "",
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		ThemeProps = { TextColor3 = "titlecolor", BackgroundColor3 = "maincolor" },
		Size = UDim2.new(0, 140, 0, 22),
		Parent = Head,
	}, {
		Create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
		Create("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
	})

	-- Body (options list)
	local Body = Create("ScrollingFrame", {
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 2,
		ScrollBarImageTransparency = 1,
		Visible = false,
		BackgroundTransparency = 1,
		ThemeProps = { BackgroundColor3 = "containeritemsbg" },
		Size = UDim2.new(1, 0, 0, 0),
		Parent = Root.Frame,
	}, {
		Create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, ThemeProps = { Color = "bordercolor" }, Thickness = 1 }),
		Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Create("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
		Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	Tools.AddScrollAnim(Body)

	-- UI helpers
	local function clearChips()
		for _, c in ipairs(ChipHolder:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
	end

	local function addChip(text)
		local chip = Create("TextButton", {
			Text = "",
			AutomaticSize = Enum.AutomaticSize.X,
			ThemeProps = { BackgroundColor3 = "valuebg" },
			Size = UDim2.new(0, 0, 0, 22),
			Parent = ChipHolder,
		}, {
			Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
			Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 6) }),
			Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4) }),
			Create("TextLabel", {
				BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = text, TextSize = 14,
				AutomaticSize = Enum.AutomaticSize.X, ThemeProps = { TextColor3 = "valuetext" },
			}),
		})

		local close = Create("TextButton", {
			Text = "", BackgroundTransparency = 1, Size = UDim2.new(0, 16, 0, 16), Parent = chip,
		}, {
			Create("ImageLabel", {
				Image = "rbxassetid://15269329696", ImageRectOffset = Vector2.new(0, 514),
				ImageRectSize = Vector2.new(256, 256), BackgroundTransparency = 1, Size = UDim2.new(0, 16, 0, 16),
			})
		})

		local function removeThis()
			if Dropdown.Multiple then
				local idx = table.find(Dropdown.Value, text)
				if idx then
					table.remove(Dropdown.Value, idx)
					Dropdown:Set(Dropdown.Value)
					if #Dropdown.Value == 0 then Dropdown._callback("") end
				end
			else
				Dropdown:Set("")
				Dropdown._callback("")
			end
		end

		close.MouseButton1Click:Connect(removeThis)
		chip.MouseButton1Click:Connect(removeThis)
	end

	local function setButtonVisual(btn, on)
		TweenService:Create(btn, TI_150, { BackgroundTransparency = on and 0 or 1 }):Play()
		local check = btn:FindFirstChild("Check")
		local txt   = btn:FindFirstChild("Txt")
		if check then TweenService:Create(check, TI_150, { ImageTransparency = on and 0 or 1 }):Play() end
		if txt then
			TweenService:Create(txt, TI_150, {
				TextColor3 = on and CurrentThemeProps.itemTextOn or CurrentThemeProps.itemTextOff
			}):Play()
		end
	end

	local function ensureButtonFor(option)
		if Dropdown.Buttons[option] then return Dropdown.Buttons[option] end

		local check = Create("ImageLabel", {
			Name = "Check", Image = "rbxassetid://15269180838",
			ImageRectOffset = Vector2.new(514, 257), ImageRectSize = Vector2.new(256, 256),
			BackgroundTransparency = 1, ThemeProps = { ImageColor3 = "itemcheckmarkcolor" },
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -9, 0.5, 0), Size = UDim2.new(0, 14, 0, 14),
		})

		local label = Create("TextLabel", {
			Name = "Txt", BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = option, TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left, ThemeProps = { TextColor3 = "elementdescription" },
			Size = UDim2.new(1, -28, 1, 0),
		}, {
			Create("UIPadding", { PaddingLeft = UDim.new(0, 14) })
		})

		local btn = Create("TextButton", {
			Text = "", BackgroundTransparency = 1, ThemeProps = { BackgroundColor3 = "itembg" },
			Size = UDim2.new(1, 0, 0, 30), Parent = Body,
		}, {
			Create("UICorner", { CornerRadius = UDim.new(0, 6) }), label, check,
		})

		btn.MouseButton1Click:Connect(function()
			if Dropdown.Multiple then
				local val = Dropdown.Value
				if type(val) ~= "table" then val = {} end
				local idx = table.find(val, option)
				if idx then
					table.remove(val, idx)
				else
					if #val < Config.MaxOptions then table.insert(val, option) end
				end
				Dropdown:Set(val)
				if #Dropdown.Value == 0 then Dropdown._callback("") end
			else
				if Dropdown.Value == option then
					Dropdown:Set("")
					Dropdown._callback("")
				else
					Dropdown:Set(option)
				end
				Dropdown.Toggled = false
				Body.Visible = false
				Body.Size = UDim2.new(1, 0, 0, 0)
			end
		end)

		local rec = { button = btn, label = label, check = check }
		Dropdown.Buttons[option] = rec
		return rec
	end

	local function renderOptionsFiltered(filterText)
		local showCount = 0
		for _, rec in pairs(Dropdown.Buttons) do rec.button.Visible = false end

		local selectedSet = Dropdown.Multiple and toSet(Dropdown.Value) or nil
		for _, opt in ipairs(Dropdown.Options) do
			if filterText == "" or string.find(string.lower(opt), filterText, 1, true) then
				local rec = ensureButtonFor(opt)
				rec.button.Visible = true
				showCount += 1
				local isOn = (Dropdown.Multiple and selectedSet[opt]) or (not Dropdown.Multiple and Dropdown.Value == opt)
				setButtonVisual(rec.button, isOn)
			end
		end

		if Dropdown.Toggled then
			local height = math.min(showCount, 8) * 30 + 20
			Body.Size = UDim2.new(1, 0, 0, showCount > 0 and height or 0)
		end
	end

	function Dropdown:Refresh(newOptions)
		local seen, unique = {}, {}
		for _, opt in ipairs(newOptions or {}) do
			if opt ~= nil and not seen[opt] then
				seen[opt] = true
				table.insert(unique, opt)
			end
		end
		self.Options = unique

		local keep = toSet(self.Options)
		for opt, rec in pairs(self.Buttons) do
			if not keep[opt] then
				rec.button:Destroy()
				self.Buttons[opt] = nil
			end
		end
		for _, opt in ipairs(self.Options) do ensureButtonFor(opt) end
		renderOptionsFiltered(string.lower(SearchBox.Text))
	end

	function Dropdown:Set(Value, ignore)
		if self.Multiple then
			local arr = {}
			if type(Value) == "table" then
				for _, v in ipairs(Value) do if v ~= "" then table.insert(arr, v) end end
			elseif Value ~= "" and Value ~= nil then
				table.insert(arr, Value)
			end
			local valid = toSet(self.Options)
			for i = #arr, 1, -1 do if not valid[arr[i]] then table.remove(arr, i) end end
			self.Value = arr
		else
			if Value == "" or not table.find(self.Options, Value) then
				self.Value = ""
			else
				self.Value = Value
			end
		end

		clearChips()
		if self.Multiple then
			for _, v in ipairs(self.Value) do addChip(v) end
		elseif self.Value ~= "" then
			addChip(self.Value)
		end

		local selectedSet = self.Multiple and toSet(self.Value) or nil
		for opt, rec in pairs(self.Buttons) do
			local on = (self.Multiple and selectedSet[opt]) or (not self.Multiple and opt == self.Value)
			setButtonVisual(rec.button, on)
		end

		if not ignore then self._callback(self.Value) end
	end

	-- open/close + search
	SearchBox.Focused:Connect(function()
		Dropdown.Toggled = true
		Body.Visible = true
		renderOptionsFiltered(string.lower(SearchBox.Text))
	end)

	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		renderOptionsFiltered(string.lower(SearchBox.Text))
	end)

	Root.Frame.MouseButton1Click:Connect(function()
		if not Body.Visible then
			Dropdown.Toggled = true
			Body.Visible = true
			renderOptionsFiltered(string.lower(SearchBox.Text))
		end
	end)

	Dropdown:Refresh(Dropdown.Options)
	Dropdown:Set(Dropdown.Multiple and (type(Config.Default) == "table" and Config.Default or {}) or (Config.Default or ""), Config.IgnoreFirst)

	self.Library.Flags[Idx] = Dropdown
	return Dropdown
end

return Element

end)() end,
    [13] = function()local wax,script,require=ImportGlobals(13)local ImportGlobals return (function(...)local Components = script.Parent.Parent.components

local Element = {}
Element.__index = Element
Element.__type = "Paragraph"

function Element:New(Config)
	assert(Config.Title, "Paragraph - Missing Title")
	Config.Description = Config.Description or nil

	local paragraph = require(Components.element)(Config.Title, Config.Description, self.Container)

	return paragraph
end

return Element

end)() end,
    [14] = function()local wax,script,require=ImportGlobals(14)local ImportGlobals return (function(...)local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Tools = require(script.Parent.Parent.tools)
local Components = script.Parent.Parent.components

local Create = Tools.Create
local AddConnection = Tools.AddConnection
local function Round(Number, Factor)
    local Result = math.floor(Number / Factor + (math.sign(Number) * 0.5)) * Factor
    if Result < 0 then
        Result = Result + Factor
    end
    return Result
end

local Element = {}
Element.__index = Element
Element.__type = "Slider"

function Element:New(Idx, Config)
    local Library = self.Library
    assert(Config.Title, "Slider - Missing Title")
    Config.Description = Config.Description or nil

    Config.Min = Config.Min or 10
    Config.Max = Config.Max or 20
    Config.Increment = Config.Increment or 1
    Config.Default = Config.Default or 0
    Config.IgnoreFirst = Config.IgnoreFirst or false

    local Slider = {
        Value = Config.Default,
        Min = Config.Min,
        Max = Config.Max,
        Increment = Config.Increment,
        IgnoreFirst = Config.IgnoreFirst,
        Callback = Config.Callback or function(Value) end,
        Type = "Slider",
    }

    local Dragging = false
    local DraggingDot = false

    local SliderFrame = require(Components.element)(Config.Title, Config.Description, self.Container)

    local ValueText = Create("TextLabel", {
        Font = Enum.Font.Gotham,
        RichText = true,
        Text = "fix it good pls",
        ThemeProps = {
            TextColor3 = "titlecolor",
        },
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Right,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(0.754537523, 8, 0, 0),
        Size = UDim2.new(0, 90, 0, 16),
        Visible = true,
        Parent = SliderFrame.topbox,
    })

    local SliderBar = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        ThemeProps = { BackgroundColor3 = "sliderbar" },
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0, 26),
        Size = UDim2.new(1, -6, 0, 2),
        Visible = true,
        Parent = SliderFrame.Frame,
    }, {
        Create("UICorner", {
            CornerRadius = UDim.new(0, 2),
            Archivable = true,
        }),
        Create("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            ThemeProps = { Color = "sliderbarstroke" },
            Enabled = true,
            LineJoinMode = Enum.LineJoinMode.Round,
            Thickness = 1,
            Archivable = true,
        }),
    })

    local SliderProgress = Create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        ThemeProps = { BackgroundColor3 = "sliderprogressbg" },
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 100, 1, 0),
        Visible = true,
        Parent = SliderBar,
    }, {
        Create("UICorner", {
            CornerRadius = UDim.new(0, 2),
            Archivable = true,
        }),
        Create("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            ThemeProps = { Color = "sliderprogressborder" },
            Enabled = true,
            LineJoinMode = Enum.LineJoinMode.Round,
            Thickness = 1,
            Archivable = true,
        }),
    })

    -- Adjusted dot size to 14x14 (smaller than 20x20 but larger than original 10x10)
    local SliderDot = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        ThemeProps = { BackgroundColor3 = "sliderdotbg" },
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 10, 0, 10),  -- Adjusted size
        Visible = true,
        Parent = SliderBar,
    }, {
        Create("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            ThemeProps = { Color = "sliderdotstroke" },
            Enabled = true,
            LineJoinMode = Enum.LineJoinMode.Round,
            Thickness = 1,
            Archivable = true,
        }),
        Create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Archivable = true,
        }),
    })

    function Slider:Set(Value, ignore)
        self.Value = math.clamp(Round(Value, Config.Increment), Config.Min, Config.Max)
        ValueText.Text = string.format("%s<font transparency='0.5'>/%s </font>", tostring(self.Value), Config.Max)
        
        local newPosition = (self.Value - Config.Min) / (Config.Max - Config.Min)
        
        if DraggingDot then
            -- Instant update when dragging dot
            SliderDot.Position = UDim2.new(newPosition, 0, 0.5, 0)
            SliderProgress.Size = UDim2.fromScale(newPosition, 1)
        else
            -- Smooth tween when not dragging
            TweenService:Create(SliderDot, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(newPosition, 0, 0.5, 0)
            }):Play()
            
            TweenService:Create(SliderProgress, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.fromScale(newPosition, 1)
            }):Play()
        end
        
        if not ignore then
            return Config.Callback(self.Value)
        end
    end

    local function updateSliderFromInput(inputPosition)
        if Dragging then
            local barPosition = SliderBar.AbsolutePosition
            local barSize = SliderBar.AbsoluteSize
            local relativeX = (inputPosition.X - barPosition.X) / barSize.X
            local clampedPosition = math.clamp(relativeX, 0, 1)
            local newValue = Config.Min + (Config.Max - Config.Min) * clampedPosition
            Slider:Set(newValue)
        end
    end

    AddConnection(SliderBar.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            updateSliderFromInput(input.Position)
        end
    end)

    AddConnection(SliderDot.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DraggingDot = true
            updateSliderFromInput(input.Position)
        end
    end)

    AddConnection(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = false
            DraggingDot = false
        end
    end)

    AddConnection(UserInputService.InputChanged, function(input)
        if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSliderFromInput(input.Position)
        end
    end)

    Slider:Set(Config.Default, Config.IgnoreFirst)

    Library.Flags[Idx] = Slider
    return Slider
end

return Element
end)() end,
    [15] = function()local wax,script,require=ImportGlobals(15)local ImportGlobals return (function(...)local Tools = require(script.Parent.Parent.tools)
local Components = script.Parent.Parent.components

local Create = Tools.Create
local AddConnection = Tools.AddConnection
local Element = {}
Element.__index = Element
Element.__type = "Textbox"

function Element:New(Config)
    assert(Config, "Textbox - Missing Config table")
    assert(Config.Title, "Textbox - Missing Title")
    Config.Description = Config.Description or nil
    Config.PlaceHolder = Config.PlaceHolder or ""
    Config.Default = Config.Default or ""
    Config.TextDisappear = Config.TextDisappear or false
    Config.Callback = Config.Callback or function() end

    local Textbox = {
        Value = Config.Default or "",
        Callback = Config.Callback,
        Type = "Textbox",
    }

    local TextboxFrame = require(Components.element)(Config.Title, Config.Description, self.Container)

    local textbox = Create("TextBox", {
        CursorPosition = -1,
        Font = Enum.Font.Gotham,
        PlaceholderText = Config.PlaceHolder,
        Text = Textbox.Value,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 30),
        Visible = true,
        Parent = TextboxFrame.Frame,
    }, {
        Create("UIPadding", {
            PaddingBottom = UDim.new(0, 0),
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 0),
            Archivable = true,
        }),
        Create("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            ThemeProps = { Color = "bordercolor" },
            Enabled = true,
            LineJoinMode = Enum.LineJoinMode.Round,
            Thickness = 1,
            Archivable = true,
        }),
        Create("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Archivable = true,
        }),
    })

    function Textbox:Set(value)
        textbox.Text = value
        Textbox.Value = value
        Config.Callback(value)
    end

    AddConnection(textbox.FocusLost, function()
        Textbox.Value = textbox.Text
        Config.Callback(Textbox.Value)
        if Config.TextDisappear then
            textbox.Text = ""
        end
    end)

    return Textbox
end

return Element

end)() end,
    [16] = function()local wax,script,require=ImportGlobals(16)local ImportGlobals return (function(...)local TweenService = game:GetService("TweenService")
local Tools = require(script.Parent.Parent.tools)
local Components = script.Parent.Parent.components

local Create = Tools.Create
local AddConnection = Tools.AddConnection

local Element = {}
Element.__index = Element
Element.__type = "Toggle"

function Element:New(Idx, Config)
    local Library = self.Library
    assert(Config.Title, "Toggle - Missing Title")
    Config.Description = Config.Description or nil
    Config.Default = Config.Default or false
    Config.IgnoreFirst = Config.IgnoreFirst or false

    local Toggle = {
        Value = Config.Default,
        Callback = Config.Callback or function(Value) end,
        IgnoreFirst = Config.IgnoreFirst,
        Type = "Toggle",
    }

    local ToggleFrame = require(Components.element)("        " .. Config.Title, Config.Description, self.Container)

    local box_frame = Create("Frame", {
        ThemeProps = {
            BackgroundColor3 = "togglebg",
        },
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 16, 0, 16),
        Visible = true,
        Parent = ToggleFrame.topbox,
    }, {
        Create("UICorner", {
            CornerRadius = UDim.new(0, 5),
            Archivable = true,
        }),
        Create("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            ThemeProps = {
                Color = "toggleborder",
            },
            Enabled = true,
            LineJoinMode = Enum.LineJoinMode.Round,
            Thickness = 1,
            Archivable = true,
        }),
        Create("ImageLabel", {
            Image = "http://www.roblox.com/asset/?id=6031094667",
            -- ImageColor3 = Color3.fromRGB(9, 9, 9),
            ThemeProps = {
                ImageColor3 = "maincolor"
            },
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 12, 0, 12),
            Visible = true,
        })
    })

    function Toggle:Set(Value, ignore)
        self.Value = Value
        TweenService:Create(box_frame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = self.Value and 0 or 1}):Play()
        if not ignore and (not self.IgnoreFirst or not self.FirstUpdate) then
            Library:Callback(Toggle.Callback, self.Value)
        end
        self.FirstUpdate = false
    end

    AddConnection(ToggleFrame.Frame.MouseButton1Click, function()
        Toggle:Set(not Toggle.Value)
    end)

    Toggle:Set(Toggle.Value, Config.IgnoreFirst)

    Library.Flags[Idx] = Toggle
    return Toggle
end

return Element

end)() end,
    [17] = function()local wax,script,require=ImportGlobals(17)local ImportGlobals return (function(...)local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local tools = { Signals = {} }

local themes = loadstring(game:HttpGet("https://raw.githubusercontent.com/Just3itx/3itx-UI-LIB/refs/heads/main/themes"))()

local currentTheme = themes.default
local themedObjects = {}

function tools.SetTheme(themeName)
	if themes[themeName] then
		currentTheme = themes[themeName]
		for _, item in pairs(themedObjects) do
			local obj = item.object
			local props = item.props
			for propName, themeKey in next, props do
				if currentTheme[themeKey] then
					obj[propName] = currentTheme[themeKey]
				end
			end
		end
	else
		warn("Theme not found: " .. themeName)
	end
end

function tools.GetPropsCurrentTheme()
	return currentTheme
end

function tools.AddTheme(themeName, themeProps)
	themes[themeName] = themeProps
end

function tools.isMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled
	-- return true
end

function tools.AddConnection(Signal, Function)
	-- if not Library:IsRunning() then return end
	local connection = Signal:Connect(Function)
	table.insert(tools.Signals, connection)
	return connection -- Return the connection so it can be disconnected later
end

function tools.Disconnect()
	for key = #tools.Signals, 1, -1 do
		local Connection = table.remove(tools.Signals, key)
		Connection:Disconnect()
	end
end

function tools.Create(Name, Properties, Children)
	local Object = Instance.new(Name)

	if Properties.ThemeProps then
		for propName, themeKey in next, Properties.ThemeProps do
			if currentTheme[themeKey] then
				Object[propName] = currentTheme[themeKey]
			end
		end
		table.insert(themedObjects, { object = Object, props = Properties.ThemeProps })
		Properties.ThemeProps = nil
	end

	for i, v in next, Properties or {} do
		Object[i] = v
	end
	for i, v in next, Children or {} do
		v.Parent = Object
	end
	return Object
end

function tools.AddScrollAnim(scrollbar)
	local visibleTween = TweenService:Create(scrollbar, TweenInfo.new(0.25), { ScrollBarImageTransparency = 0 })
	local invisibleTween = TweenService:Create(scrollbar, TweenInfo.new(0.25), { ScrollBarImageTransparency = 1 })
	local lastInteraction = tick()
	local delayTime = 0.6

	local function showScrollbar()
		visibleTween:Play()
	end

	local function hideScrollbar()
		if tick() - lastInteraction >= delayTime then
			invisibleTween:Play()
		end
	end

	tools.AddConnection(scrollbar.MouseEnter, function()
		lastInteraction = tick()
		showScrollbar()
	end)

	tools.AddConnection(scrollbar.MouseLeave, function()
		wait(delayTime)
		hideScrollbar()
	end)

	tools.AddConnection(scrollbar.InputChanged, function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			lastInteraction = tick()
			showScrollbar()
		end
	end)

	tools.AddConnection(scrollbar:GetPropertyChangedSignal("CanvasPosition"), function()
		lastInteraction = tick()
		showScrollbar()
	end)

	tools.AddConnection(UserInputService.InputChanged, function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			lastInteraction = tick()
			showScrollbar()
		end
	end)

	tools.AddConnection(RunService.RenderStepped, function()
		if tick() - lastInteraction >= delayTime then
			hideScrollbar()
		end
	end)
end

return tools

end)() end
} -- [RefId] = Closure

-- Holds the actual DOM data
local ObjectTree = {
    {
        1,
        2,
        {
            "MainModule"
        },
        {
            {
                2,
                1,
                {
                    "components"
                },
                {
                    {
                        6,
                        2,
                        {
                            "section"
                        }
                    },
                    {
                        3,
                        2,
                        {
                            "dialog"
                        }
                    },
                    {
                        5,
                        2,
                        {
                            "notif"
                        }
                    },
                    {
                        4,
                        2,
                        {
                            "element"
                        }
                    },
                    {
                        7,
                        2,
                        {
                            "tab"
                        }
                    }
                }
            },
            {
                8,
                2,
                {
                    "elements"
                },
                {
                    {
                        12,
                        2,
                        {
                            "dropdown"
                        }
                    },
                    {
                        10,
                        2,
                        {
                            "buttons"
                        }
                    },
                    {
                        16,
                        2,
                        {
                            "toggle"
                        }
                    },
                    {
                        11,
                        2,
                        {
                            "colorpicker"
                        }
                    },
                    {
                        9,
                        2,
                        {
                            "bind"
                        }
                    },
                    {
                        14,
                        2,
                        {
                            "slider"
                        }
                    },
                    {
                        13,
                        2,
                        {
                            "paragraph"
                        }
                    },
                    {
                        15,
                        2,
                        {
                            "textbox"
                        }
                    }
                }
            },
            {
                17,
                2,
                {
                    "tools"
                }
            }
        }
    }
}

-- Line offsets for debugging (only included when minifyTables is false)
local LineOffsets = {
    8,
    [3] = 454,
    [4] = 607,
    [5] = 733,
    [6] = 919,
    [7] = 1131,
    [8] = 1460,
    [9] = 1468,
    [10] = 1597,
    [11] = 1777,
    [12] = 2219,
    [13] = 2732,
    [14] = 2750,
    [15] = 2961,
    [16] = 3048,
    [17] = 3138
}

-- Misc AOT variable imports
local WaxVersion = "0.4.1"
local EnvName = "WaxRuntime"

-- ++++++++ RUNTIME IMPL BELOW ++++++++ --

-- Localizing certain libraries and built-ins for runtime efficiency
local string, task, setmetatable, error, next, table, unpack, coroutine, script, type, require, pcall, tostring, tonumber, _VERSION =
      string, task, setmetatable, error, next, table, unpack, coroutine, script, type, require, pcall, tostring, tonumber, _VERSION

local table_insert = table.insert
local table_remove = table.remove
local table_freeze = table.freeze or function(t) return t end -- lol

local coroutine_wrap = coroutine.wrap

local string_sub = string.sub
local string_match = string.match
local string_gmatch = string.gmatch

-- The Lune runtime has its own `task` impl, but it must be imported by its builtin
-- module path, "@lune/task"
if _VERSION and string_sub(_VERSION, 1, 4) == "Lune" then
    local RequireSuccess, LuneTaskLib = pcall(require, "@lune/task")
    if RequireSuccess and LuneTaskLib then
        task = LuneTaskLib
    end
end

local task_defer = task and task.defer

-- If we're not running on the Roblox engine, we won't have a `task` global
local Defer = task_defer or function(f, ...)
    coroutine_wrap(f)(...)
end

-- ClassName "IDs"
local ClassNameIdBindings = {
    [1] = "Folder",
    [2] = "ModuleScript",
    [3] = "Script",
    [4] = "LocalScript",
    [5] = "StringValue",
}

local RefBindings = {} -- [RefId] = RealObject

local ScriptClosures = {}
local ScriptClosureRefIds = {} -- [ScriptClosure] = RefId
local StoredModuleValues = {}
local ScriptsToRun = {}

-- wax.shared __index/__newindex
local SharedEnvironment = {}

-- We're creating 'fake' instance refs soley for traversal of the DOM for require() compatibility
-- It's meant to be as lazy as possible
local RefChildren = {} -- [Ref] = {ChildrenRef, ...}

-- Implemented instance methods
local InstanceMethods = {
    GetFullName = { {}, function(self)
        local Path = self.Name
        local ObjectPointer = self.Parent

        while ObjectPointer do
            Path = ObjectPointer.Name .. "." .. Path

            -- Move up the DOM (parent will be nil at the end, and this while loop will stop)
            ObjectPointer = ObjectPointer.Parent
        end

        return Path
    end},

    GetChildren = { {}, function(self)
        local ReturnArray = {}

        for Child in next, RefChildren[self] do
            table_insert(ReturnArray, Child)
        end

        return ReturnArray
    end},

    GetDescendants = { {}, function(self)
        local ReturnArray = {}

        for Child in next, RefChildren[self] do
            table_insert(ReturnArray, Child)

            for _, Descendant in next, Child:GetDescendants() do
                table_insert(ReturnArray, Descendant)
            end
        end

        return ReturnArray
    end},

    FindFirstChild = { {"string", "boolean?"}, function(self, name, recursive)
        local Children = RefChildren[self]

        for Child in next, Children do
            if Child.Name == name then
                return Child
            end
        end

        if recursive then
            for Child in next, Children do
                -- Yeah, Roblox follows this behavior- instead of searching the entire base of a
                -- ref first, the engine uses a direct recursive call
                return Child:FindFirstChild(name, true)
            end
        end
    end},

    FindFirstAncestor = { {"string"}, function(self, name)
        local RefPointer = self.Parent
        while RefPointer do
            if RefPointer.Name == name then
                return RefPointer
            end

            RefPointer = RefPointer.Parent
        end
    end},

    -- Just to implement for traversal usage
    WaitForChild = { {"string", "number?"}, function(self, name)
        return self:FindFirstChild(name)
    end},
}

-- "Proxies" to instance methods, with err checks etc
local InstanceMethodProxies = {}
for MethodName, MethodObject in next, InstanceMethods do
    local Types = MethodObject[1]
    local Method = MethodObject[2]

    local EvaluatedTypeInfo = {}
    for ArgIndex, TypeInfo in next, Types do
        local ExpectedType, IsOptional = string_match(TypeInfo, "^([^%?]+)(%??)")
        EvaluatedTypeInfo[ArgIndex] = {ExpectedType, IsOptional}
    end

    InstanceMethodProxies[MethodName] = function(self, ...)
        if not RefChildren[self] then
            error("Expected ':' not '.' calling member function " .. MethodName, 2)
        end

        local Args = {...}
        for ArgIndex, TypeInfo in next, EvaluatedTypeInfo do
            local RealArg = Args[ArgIndex]
            local RealArgType = type(RealArg)
            local ExpectedType, IsOptional = TypeInfo[1], TypeInfo[2]

            if RealArg == nil and not IsOptional then
                error("Argument " .. RealArg .. " missing or nil", 3)
            end

            if ExpectedType ~= "any" and RealArgType ~= ExpectedType and not (RealArgType == "nil" and IsOptional) then
                error("Argument " .. ArgIndex .. " expects type \"" .. ExpectedType .. "\", got \"" .. RealArgType .. "\"", 2)
            end
        end

        return Method(self, ...)
    end
end

local function CreateRef(className, name, parent)
    -- `name` and `parent` can also be set later by the init script if they're absent

    -- Extras
    local StringValue_Value

    -- Will be set to RefChildren later aswell
    local Children = setmetatable({}, {__mode = "k"})

    -- Err funcs
    local function InvalidMember(member)
        error(member .. " is not a valid (virtual) member of " .. className .. " \"" .. name .. "\"", 3)
    end
    local function ReadOnlyProperty(property)
        error("Unable to assign (virtual) property " .. property .. ". Property is read only", 3)
    end

    local Ref = {}
    local RefMetatable = {}

    RefMetatable.__metatable = false

    RefMetatable.__index = function(_, index)
        if index == "ClassName" then -- First check "properties"
            return className
        elseif index == "Name" then
            return name
        elseif index == "Parent" then
            return parent
        elseif className == "StringValue" and index == "Value" then
            -- Supporting StringValue.Value for Rojo .txt file conv
            return StringValue_Value
        else -- Lastly, check "methods"
            local InstanceMethod = InstanceMethodProxies[index]

            if InstanceMethod then
                return InstanceMethod
            end
        end

        -- Next we'll look thru child refs
        for Child in next, Children do
            if Child.Name == index then
                return Child
            end
        end

        -- At this point, no member was found; this is the same err format as Roblox
        InvalidMember(index)
    end

    RefMetatable.__newindex = function(_, index, value)
        -- __newindex is only for props fyi
        if index == "ClassName" then
            ReadOnlyProperty(index)
        elseif index == "Name" then
            name = value
        elseif index == "Parent" then
            -- We'll just ignore the process if it's trying to set itself
            if value == Ref then
                return
            end

            if parent ~= nil then
                -- Remove this ref from the CURRENT parent
                RefChildren[parent][Ref] = nil
            end

            parent = value

            if value ~= nil then
                -- And NOW we're setting the new parent
                RefChildren[value][Ref] = true
            end
        elseif className == "StringValue" and index == "Value" then
            -- Supporting StringValue.Value for Rojo .txt file conv
            StringValue_Value = value
        else
            -- Same err as __index when no member is found
            InvalidMember(index)
        end
    end

    RefMetatable.__tostring = function()
        return name
    end

    setmetatable(Ref, RefMetatable)

    RefChildren[Ref] = Children

    if parent ~= nil then
        RefChildren[parent][Ref] = true
    end

    return Ref
end

-- Create real ref DOM from object tree
local function CreateRefFromObject(object, parent)
    local RefId = object[1]
    local ClassNameId = object[2]
    local Properties = object[3] -- Optional
    local Children = object[4] -- Optional

    local ClassName = ClassNameIdBindings[ClassNameId]

    local Name = Properties and table_remove(Properties, 1) or ClassName

    local Ref = CreateRef(ClassName, Name, parent) -- 3rd arg may be nil if this is from root
    RefBindings[RefId] = Ref

    if Properties then
        for PropertyName, PropertyValue in next, Properties do
            Ref[PropertyName] = PropertyValue
        end
    end

    if Children then
        for _, ChildObject in next, Children do
            CreateRefFromObject(ChildObject, Ref)
        end
    end

    return Ref
end

local RealObjectRoot = CreateRef("Folder", "[" .. EnvName .. "]")
for _, Object in next, ObjectTree do
    CreateRefFromObject(Object, RealObjectRoot)
end

-- Now we'll set script closure refs and check if they should be ran as a BaseScript
for RefId, Closure in next, ClosureBindings do
    local Ref = RefBindings[RefId]

    ScriptClosures[Ref] = Closure
    ScriptClosureRefIds[Ref] = RefId

    local ClassName = Ref.ClassName
    if ClassName == "LocalScript" or ClassName == "Script" then
        table_insert(ScriptsToRun, Ref)
    end
end

local function LoadScript(scriptRef)
    local ScriptClassName = scriptRef.ClassName

    -- First we'll check for a cached module value (packed into a tbl)
    local StoredModuleValue = StoredModuleValues[scriptRef]
    if StoredModuleValue and ScriptClassName == "ModuleScript" then
        return unpack(StoredModuleValue)
    end

    local Closure = ScriptClosures[scriptRef]

    local function FormatError(originalErrorMessage)
        originalErrorMessage = tostring(originalErrorMessage)

        local VirtualFullName = scriptRef:GetFullName()

        -- Check for vanilla/Roblox format
        local OriginalErrorLine, BaseErrorMessage = string_match(originalErrorMessage, "[^:]+:(%d+): (.+)")

        if not OriginalErrorLine or not LineOffsets then
            return VirtualFullName .. ":*: " .. (BaseErrorMessage or originalErrorMessage)
        end

        OriginalErrorLine = tonumber(OriginalErrorLine)

        local RefId = ScriptClosureRefIds[scriptRef]
        local LineOffset = LineOffsets[RefId]

        local RealErrorLine = OriginalErrorLine - LineOffset + 1
        if RealErrorLine < 0 then
            RealErrorLine = "?"
        end

        return VirtualFullName .. ":" .. RealErrorLine .. ": " .. BaseErrorMessage
    end

    -- If it's a BaseScript, we'll just run it directly!
    if ScriptClassName == "LocalScript" or ScriptClassName == "Script" then
        local RunSuccess, ErrorMessage = pcall(Closure)
        if not RunSuccess then
            error(FormatError(ErrorMessage), 0)
        end
    else
        local PCallReturn = {pcall(Closure)}

        local RunSuccess = table_remove(PCallReturn, 1)
        if not RunSuccess then
            local ErrorMessage = table_remove(PCallReturn, 1)
            error(FormatError(ErrorMessage), 0)
        end

        StoredModuleValues[scriptRef] = PCallReturn
        return unpack(PCallReturn)
    end
end

-- We'll assign the actual func from the top of this output for flattening user globals at runtime
-- Returns (in a tuple order): wax, script, require
function ImportGlobals(refId)
    local ScriptRef = RefBindings[refId]

    local function RealCall(f, ...)
        local PCallReturn = {pcall(f, ...)}

        local CallSuccess = table_remove(PCallReturn, 1)
        if not CallSuccess then
            error(PCallReturn[1], 3)
        end

        return unpack(PCallReturn)
    end

    -- `wax.shared` index
    local WaxShared = table_freeze(setmetatable({}, {
        __index = SharedEnvironment,
        __newindex = function(_, index, value)
            SharedEnvironment[index] = value
        end,
        __len = function()
            return #SharedEnvironment
        end,
        __iter = function()
            return next, SharedEnvironment
        end,
    }))

    local Global_wax = table_freeze({
        -- From AOT variable imports
        version = WaxVersion,
        envname = EnvName,

        shared = WaxShared,

        -- "Real" globals instead of the env set ones
        script = script,
        require = require,
    })

    local Global_script = ScriptRef

    local function Global_require(module, ...)
        local ModuleArgType = type(module)

        local ErrorNonModuleScript = "Attempted to call require with a non-ModuleScript"
        local ErrorSelfRequire = "Attempted to call require with self"

        if ModuleArgType == "table" and RefChildren[module]  then
            if module.ClassName ~= "ModuleScript" then
                error(ErrorNonModuleScript, 2)
            elseif module == ScriptRef then
                error(ErrorSelfRequire, 2)
            end

            return LoadScript(module)
        elseif ModuleArgType == "string" and string_sub(module, 1, 1) ~= "@" then
            -- The control flow on this SUCKS

            if #module == 0 then
                error("Attempted to call require with empty string", 2)
            end

            local CurrentRefPointer = ScriptRef

            if string_sub(module, 1, 1) == "/" then
                CurrentRefPointer = RealObjectRoot
            elseif string_sub(module, 1, 2) == "./" then
                module = string_sub(module, 3)
            end

            local PreviousPathMatch
            for PathMatch in string_gmatch(module, "([^/]*)/?") do
                local RealIndex = PathMatch
                if PathMatch == ".." then
                    RealIndex = "Parent"
                end

                -- Don't advance dir if it's just another "/" either
                if RealIndex ~= "" then
                    local ResultRef = CurrentRefPointer:FindFirstChild(RealIndex)
                    if not ResultRef then
                        local CurrentRefParent = CurrentRefPointer.Parent
                        if CurrentRefParent then
                            ResultRef = CurrentRefParent:FindFirstChild(RealIndex)
                        end
                    end

                    if ResultRef then
                        CurrentRefPointer = ResultRef
                    elseif PathMatch ~= PreviousPathMatch and PathMatch ~= "init" and PathMatch ~= "init.server" and PathMatch ~= "init.client" then
                        error("Virtual script path \"" .. module .. "\" not found", 2)
                    end
                end

                -- For possible checks next cycle
                PreviousPathMatch = PathMatch
            end

            if CurrentRefPointer.ClassName ~= "ModuleScript" then
                error(ErrorNonModuleScript, 2)
            elseif CurrentRefPointer == ScriptRef then
                error(ErrorSelfRequire, 2)
            end

            return LoadScript(CurrentRefPointer)
        end

        return RealCall(require, module, ...)
    end

    -- Now, return flattened globals ready for direct runtime exec
    return Global_wax, Global_script, Global_require
end

for _, ScriptRef in next, ScriptsToRun do
    Defer(LoadScript, ScriptRef)
end

-- AoT adjustment: Load init module (MainModule behavior)
return LoadScript(RealObjectRoot:GetChildren()[1])
