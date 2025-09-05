-- RZLike.lua
-- Biblioteca inspirada na RedZ Library v2 (simplificada)
-- Use em LocalScript (coloque em StarterPlayerScripts/StarterGui conforme necessário)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local RZ = {}
RZ.__index = RZ

-- Configuração default de aparência (fácil de mexer)
local DEFAULT = {
    WindowSize = UDim2.new(0, 780, 0, 420),
    WindowPos = UDim2.new(0.5, -390, 0.5, -210),
    BackgroundColor = Color3.fromRGB(30, 30, 35),
    AccentColor = Color3.fromRGB(96, 165, 250),
    TextColor = Color3.fromRGB(235, 235, 240),
    Font = Enum.Font.Gotham,
}

-- Helpers
local function create(class, props)
    local obj = Instance.new(class)
    if props then
        for k,v in pairs(props) do
            obj[k] = v
        end
    end
    return obj
end

local function clearChildren(frame)
    for _,c in ipairs(frame:GetChildren()) do
        c:Destroy()
    end
end

-- Create base UI
function RZ.new(title)
    local self = setmetatable({}, RZ)
    self.title = title or "RZ-Like Library"
    self.tabs = {} -- list of tabs

    -- ScreenGui
    local screenGui = create("ScreenGui", {Name = ("RZLib_%s"):format(self.title), ResetOnSpawn = false, DisplayOrder = 999})
    screenGui.Parent = PlayerGui

    -- Main window
    local main = create("Frame", {
        Name = "MainWindow",
        Size = DEFAULT.WindowSize,
        Position = DEFAULT.WindowPos,
        AnchorPoint = Vector2.new(0,0),
        BackgroundColor3 = DEFAULT.BackgroundColor,
        BorderSizePixel = 0,
        Parent = screenGui,
        ClipsDescendants = true,
    })

    local uiCorner = create("UICorner", {CornerRadius = UDim.new(0,8), Parent = main})
    local titleBar = create("Frame", {
        Name = "TitleBar", Size = UDim2.new(1,0,0,34), BackgroundTransparency = 1, Parent = main
    })
    local titleLabel = create("TextLabel", {
        Name = "TitleLabel",
        Text = self.title,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        TextColor3 = DEFAULT.TextColor,
        Font = DEFAULT.Font,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar,
    })

    local closeBtn = create("TextButton", {
        Name = "Close",
        Text = "X",
        Size = UDim2.new(0, 28, 0, 24),
        Position = UDim2.new(1, -36, 0, 6),
        BackgroundTransparency = 0.6,
        BackgroundColor3 = Color3.fromRGB(45,45,50),
        TextColor3 = DEFAULT.TextColor,
        Font = DEFAULT.Font,
        TextSize = 16,
        Parent = titleBar,
    })
    create("UICorner",{Parent = closeBtn, CornerRadius = UDim.new(0,6)})

    -- Container for tabs and contents
    local container = create("Frame", {Name = "Container", Size = UDim2.new(1,0,1,-34), Position = UDim2.new(0,0,0,34), BackgroundTransparency = 1, Parent = main})
    local leftBar = create("Frame", {Name = "LeftBar", Size = UDim2.new(0, 180, 1,0), BackgroundTransparency = 1, Parent = container})
    local leftList = create("UIListLayout", {Parent = leftBar})
    leftList.Padding = UDim.new(0,8)
    leftList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local contentArea = create("Frame", {Name="ContentArea", Size = UDim2.new(1, -180, 1,0), Position = UDim2.new(0, 180, 0, 0), BackgroundTransparency = 1, Parent = container})
    local contentList = create("Frame", {Name="Pages", Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Parent = contentArea})

    -- Store refs
    self._gui = screenGui
    self._main = main
    self._leftBar = leftBar
    self._content = contentList
    self._tabsButtons = {}
    self._activeTab = nil

    -- Closing behaviour
    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = not main.Visible
    end)

    -- Dragging window
    local dragging, dragInput, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    return self
end

-- Creates a tab (button on left + page in content)
function RZ:createTab(name)
    local tab = {name = name, sections = {}}
    table.insert(self.tabs, tab)

    -- Button on left
    local btn = create("TextButton", {
        Name = "Tab_"..name,
        Text = name,
        Size = UDim2.new(1, -20, 0, 36),
        BackgroundColor3 = Color3.fromRGB(35,35,40),
        TextColor3 = DEFAULT.TextColor,
        Font = DEFAULT.Font,
        TextSize = 16,
        Parent = self._leftBar,
    })
    create("UICorner",{Parent = btn, CornerRadius = UDim.new(0,6)})

    -- Page frame
    local page = create("ScrollingFrame", {
        Name = "Page_"..name,
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,1,0),
        CanvasSize = UDim2.new(0,0),
        ScrollBarThickness = 6,
        Parent = self._content,
    })
    local layout = create("UIListLayout", {Parent = page})
    layout.Padding = UDim.new(0,8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    page:GetPropertyChangedSignal("CanvasSize"):Connect(function()
        -- noop
    end)

    -- Activation
    local function activate()
        -- hide other pages
        for _,child in ipairs(self._content:GetChildren()) do
            if child:IsA("ScrollingFrame") then
                child.Visible = false
            end
        end
        page.Visible = true
        self._activeTab = tab
        -- style active btn
        for _,b in ipairs(self._leftBar:GetChildren()) do
            if b:IsA("TextButton") then
                b.BackgroundColor3 = Color3.fromRGB(35,35,40)
            end
        end
        btn.BackgroundColor3 = DEFAULT.AccentColor
    end
    btn.MouseButton1Click:Connect(activate)

    -- default activate if first tab
    if #self._tabsButtons == 0 then
        activate()
    end

    table.insert(self._tabsButtons, btn)
    tab._page = page
    tab._pageLayout = layout

    -- Methods to add sections/elements
    function tab:addSection(title)
        local section = create("Frame", {
            Name = "Section_"..title,
            Size = UDim2.new(1, -16, 0, 140),
            BackgroundColor3 = Color3.fromRGB(26,26,30),
            Parent = page,
            LayoutOrder = #tab.sections + 1,
        })
        create("UICorner", {Parent = section, CornerRadius = UDim.new(0,6)})
        local header = create("TextLabel", {
            Name = "SecTitle", Text = title, BackgroundTransparency = 1,
            Position = UDim2.new(0,8,0,6), Size = UDim2.new(1,-16,0,22),
            TextColor3 = DEFAULT.TextColor, Font = DEFAULT.Font, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left,
            Parent = section
        })
        local content = create("Frame", {Name = "Content", Size = UDim2.new(1,-16,1,-36), Position = UDim2.new(0,8,0,36), BackgroundTransparency = 1, Parent = section})
        local contentLayout = create("UIListLayout", {Parent = content})
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        contentLayout.Padding = UDim.new(0,6)

        local sect = {
            frame = section,
            content = content,
            layout = contentLayout,
        }
        table.insert(tab.sections, sect)

        -- API to add elements
        function sect:addButton(text, callback)
            local btn = create("TextButton", {
                Name = "Button_"..text,
                Text = text,
                Size = UDim2.new(1,0,0,32),
                BackgroundColor3 = Color3.fromRGB(45,45,50),
                TextColor3 = DEFAULT.TextColor,
                Font = DEFAULT.Font,
                TextSize = 15,
                Parent = content,
            })
            create("UICorner", {Parent = btn, CornerRadius = UDim.new(0,6)})
            btn.MouseButton1Click:Connect(function()
                pcall(callback)
            end)
            return btn
        end

        function sect:addToggle(text, default, callback)
            local container = create("Frame", {Size = UDim2.new(1,0,0,32), BackgroundTransparency = 1, Parent = content})
            local label = create("TextLabel", {
                Text = text, BackgroundTransparency = 1, Size = UDim2.new(0.7,0,1,0),
                TextColor3 = DEFAULT.TextColor, Font = DEFAULT.Font, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Parent = container
            })
            local toggle = create("TextButton", {
                Text = "",
                Size = UDim2.new(0,46,0,24),
                Position = UDim2.new(1,-46,0,4),
                BackgroundColor3 = default and DEFAULT.AccentColor or Color3.fromRGB(60,60,65),
                Parent = container
            })
            create("UICorner", {Parent = toggle, CornerRadius = UDim.new(0,6)})
            local state = default and true or false
            toggle.MouseButton1Click:Connect(function()
                state = not state
                toggle.BackgroundColor3 = state and DEFAULT.AccentColor or Color3.fromRGB(60,60,65)
                pcall(callback, state)
            end)
            -- initial callback
            pcall(callback, state)
            return toggle
        end

        function sect:addSlider(text, min, max, default, callback)
            min = min or 0
            max = max or 100
            default = default or min
            local container = create("Frame", {Size = UDim2.new(1,0,0,48), BackgroundTransparency = 1, Parent = content})
            local label = create("TextLabel", {
                Text = text.. " ("..tostring(default)..")",
                BackgroundTransparency = 1, Size = UDim2.new(1,0,0,18),
                TextColor3 = DEFAULT.TextColor, Font = DEFAULT.Font, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = container
            })
            local barBg = create("Frame", {Size = UDim2.new(1,0,0,16), Position = UDim2.new(0,0,0,26), BackgroundColor3 = Color3.fromRGB(50,50,55), Parent = container})
            create("UICorner",{Parent=barBg, CornerRadius = UDim.new(0,6)})
            local fill = create("Frame", {Size = UDim2.new((default-min)/(max-min),0,1,0), BackgroundColor3 = DEFAULT.AccentColor, Parent = barBg})
            create("UICorner",{Parent=fill, CornerRadius = UDim.new(0,6)})

            local dragging = false
            barBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local absX = math.clamp(input.Position.X - barBg.AbsolutePosition.X, 0, barBg.AbsoluteSize.X)
                    local ratio = absX / barBg.AbsoluteSize.X
                    fill.Size = UDim2.new(ratio,0,1,0)
                    local value = math.floor(min + (max-min) * ratio)
                    label.Text = text.." ("..tostring(value)..")"
                    pcall(callback, value)
                end
            end)
            -- initial callback
            pcall(callback, default)
            return fill
        end

        function sect:addDropdown(text, options, callback)
            options = options or {}
            local container = create("Frame", {Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1, Parent = content})
            local label = create("TextLabel", {
                Text = text, BackgroundTransparency = 1, Size = UDim2.new(0.6,0,1,0),
                TextColor3 = DEFAULT.TextColor, Font = DEFAULT.Font, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Parent = container
            })
            local box = create("TextButton", {
                Text = options[1] or "Select",
                Size = UDim2.new(0.37,0,0,28),
                Position = UDim2.new(1, -0.37, 0, 4),
                BackgroundColor3 = Color3.fromRGB(45,45,50),
                TextColor3 = DEFAULT.TextColor,
                Font = DEFAULT.Font,
                TextSize = 14,
                Parent = container
            })
            create("UICorner",{Parent = box, CornerRadius = UDim.new(0,6)})
            local list = create("Frame", {Size = UDim2.new(0.37,0,0,0), Position = UDim2.new(1, -0.37, 0, 40), BackgroundColor3 = Color3.fromRGB(40,40,45), Parent = container, ClipsDescendants = true})
            create("UICorner",{Parent = list, CornerRadius = UDim.new(0,6)})
            local listLayout = create("UIListLayout", {Parent = list})
            listLayout.Padding = UDim.new(0,2)

            local open = false
            local function rebuildOptions()
                clearChildren(list)
                for i,opt in ipairs(options) do
                    local optBtn = create("TextButton", {
                        Text = tostring(opt),
                        Size = UDim2.new(1, -8, 0, 26),
                        Position = UDim2.new(0,4,0,0),
                        BackgroundTransparency = 1,
                        TextColor3 = DEFAULT.TextColor,
                        Font = DEFAULT.Font,
                        TextSize = 14,
                        Parent = list
                    })
                    optBtn.MouseButton1Click:Connect(function()
                        box.Text = tostring(opt)
                        pcall(callback, opt)
                        open = false
                        list:TweenSize(UDim2.new(0.37,0,0,0),"Out","Quad",0.18,true)
                    end)
                end
                local total = #options * 28
                list.Size = UDim2.new(0.37,0,0,total)
                if not open then
                    list.Size = UDim2.new(0.37,0,0,0)
                end
            end
            rebuildOptions()
            box.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    list:TweenSize(UDim2.new(0.37,0,0,#options * 28),"Out","Quad",0.18,true)
                else
                    list:TweenSize(UDim2.new(0.37,0,0,0),"Out","Quad",0.18,true)
                end
            end)
            return box
        end

        function sect:addBind(text, defaultKey, callback)
            local container = create("Frame", {Size = UDim2.new(1,0,0,32), BackgroundTransparency = 1, Parent = content})
            local label = create("TextLabel", {
                Text = text, BackgroundTransparency = 1, Size = UDim2.new(0.6,0,1,0),
                TextColor3 = DEFAULT.TextColor, Font = DEFAULT.Font, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Parent = container
            })
            local keyBtn = create("TextButton", {
                Text = defaultKey and tostring(defaultKey) or "None",
                Size = UDim2.new(0.37,0,0,24),
                Position = UDim2.new(1, -0.37, 0, 4),
                BackgroundColor3 = Color3.fromRGB(45,45,50),
                TextColor3 = DEFAULT.TextColor,
                Font = DEFAULT.Font,
                TextSize = 14,
                Parent = container
            })
            create("UICorner",{Parent = keyBtn, CornerRadius = UDim.new(0,6)})
            local listening = false
            keyBtn.MouseButton1Click:Connect(function()
                listening = true
                keyBtn.Text = "..."
            end)
            UserInputService.InputBegan:Connect(function(input, gpe)
                if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    listening = false
                    keyBtn.Text = input.KeyCode.Name
                    if callback then
                        pcall(callback, input.KeyCode)
                    end
                else
                    -- fire normal
                    if input.UserInputType == Enum.UserInputType.Keyboard and keyBtn.Text ~= "None" and keyBtn.Text ~= "..." then
                        if input.KeyCode.Name == keyBtn.Text then
                            pcall(callback)
                        end
                    end
                end
            end)
            return keyBtn
        end

        function sect:addColorPicker(text, defaultColor, callback)
            defaultColor = defaultColor or Color3.fromRGB(255,255,255)
            local container = create("Frame", {Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1, Parent = content})
            local label = create("TextLabel", {
                Text = text, BackgroundTransparency = 1, Size = UDim2.new(0.6,0,1,0),
                TextColor3 = DEFAULT.TextColor, Font = DEFAULT.Font, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Parent = container
            })
            local colorBox = create("TextButton", {
                Text = "",
                Size = UDim2.new(0,28,0,28),
                Position = UDim2.new(1, -34, 0, 4),
                BackgroundColor3 = defaultColor,
                Parent = container
            })
            create("UICorner",{Parent = colorBox, CornerRadius = UDim.new(0,6)})

            -- Simple toggle color sampler (cycle hue)
            local open = false
            local picker = create("Frame", {Size = UDim2.new(0,160,0,96), Position = UDim2.new(1,-160,0,40), BackgroundColor3 = Color3.fromRGB(40,40,45), Parent = container, Visible = false})
            create("UICorner",{Parent = picker, CornerRadius = UDim.new(0,6)})
            local hueBar = create("Frame", {Size = UDim2.new(0.2,0,1,0), BackgroundColor3 = Color3.fromRGB(230,0,0), Position = UDim2.new(0,8,0,8), Parent = picker})
            local swatch = create("Frame", {Size = UDim2.new(0,0,0,0), Position = UDim2.new(0.22,8,0,8), BackgroundColor3 = defaultColor, Parent = picker})
            local swatchCorner = create("UICorner",{Parent=swatch, CornerRadius = UDim.new(0,6)})
            swatch.Size = UDim2.new(1, -32, 1, -16)

            colorBox.MouseButton1Click:Connect(function()
                open = not open
                picker.Visible = open
            end)

            -- Very simple color change: clicking hue bar picks a color gradient
            hueBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    local function updateColor(pos)
                        local rel = math.clamp((pos.X - hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X, 0, 1)
                        local c = Color3.fromHSV(rel, 0.8, 0.9)
                        swatch.BackgroundColor3 = c
                        colorBox.BackgroundColor3 = c
                        pcall(callback, c)
                    end
                    local conn
                    conn = UserInputService.InputChanged:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseMovement then
                            updateColor(i.Position)
                        end
                    end)
                    local upConn
                    upConn = UserInputService.InputEnded:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton1 then
                            conn:Disconnect()
                            upConn:Disconnect()
                        end
                    end)
                end
            end)
            -- initial callback
            pcall(callback, defaultColor)
            return colorBox
        end

        return sect
    end

    return tab
end

-- Convenience: destroy library UI
function RZ:Destroy()
    if self._gui and self._gui.Parent then
        self._gui:Destroy()
    end
end

return RZ
