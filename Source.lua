local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function create(class, props)
    local obj = Instance.new(class)
    if props then
        for k,v in pairs(props) do
            obj[k] = v
        end
    end
    return obj
end

local DEFAULT = {
    WindowSize = UDim2.new(0, 820, 0, 460),
    WindowPos = UDim2.new(0.5, -410, 0.5, -230),
    BackgroundColor = Color3.fromRGB(28,28,32),
    AccentColor = Color3.fromRGB(96,165,250),
    TextColor = Color3.fromRGB(230,230,235),
    Font = Enum.Font.Gotham,
}

local RZ = {}
RZ.__index = RZ

-- Função que cria a janela principal e retorna objeto com métodos MakeTab e Notification
function RZ:MakeWindow(options)
    options = options or {}
    local ScreenGui = create("ScreenGui", {Name = "RZWindow", ResetOnSpawn = false, DisplayOrder = 9999})
    ScreenGui.Parent = PlayerGui

    local Main = create("Frame", {
        Name = "Main",
        Size = DEFAULT.WindowSize,
        Position = DEFAULT.WindowPos,
        BackgroundColor3 = DEFAULT.BackgroundColor,
        BorderSizePixel = 0,
        Parent = ScreenGui,
        ClipsDescendants = true,
    })
    create("UICorner", {Parent = Main, CornerRadius = UDim.new(0, 10)})

    -- Dragging
    do
        local dragging, dragInput, dragStart, startPos
        Main.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = Main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        Main.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                Main.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    -- Title Bar
    local TitleBar = create("Frame", {Name = "TitleBar", Size = UDim2.new(1,0,0,38), BackgroundTransparency = 1, Parent = Main})
    local TitleLabel = create("TextLabel", {
        Text = options.Title or "Window",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -60, 0, 22),
        Font = DEFAULT.Font,
        TextSize = 20,
        TextColor3 = DEFAULT.TextColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TitleBar,
    })

    if options.SubTitle then
        local SubTitleLabel = create("TextLabel", {
            Text = options.SubTitle,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 24),
            Size = UDim2.new(1, -60, 0, 14),
            Font = DEFAULT.Font,
            TextSize = 14,
            TextColor3 = DEFAULT.TextColor:lerp(Color3.new(1,1,1), -0.5),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = TitleBar,
        })
    end

    -- Close Button
    local CloseBtn = create("TextButton", {
        Text = "X",
        Size = UDim2.new(0, 38, 0, 26),
        Position = UDim2.new(1, -46, 0, 6),
        BackgroundColor3 = Color3.fromRGB(40,40,45),
        TextColor3 = DEFAULT.TextColor,
        Font = DEFAULT.Font,
        TextSize = 18,
        Parent = TitleBar,
    })
    create("UICorner", {Parent = CloseBtn, CornerRadius = UDim.new(0,6)})
    CloseBtn.MouseButton1Click:Connect(function()
        Main.Visible = not Main.Visible
    end)

    -- Left bar tabs container
    local LeftBar = create("Frame", {
        Name = "LeftBar",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 200, 1, 0),
        Parent = Main,
    })
    local LeftLayout = create("UIListLayout", {Parent = LeftBar})
    LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
    LeftLayout.Padding = UDim.new(0, 8)
    LeftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    -- Content container
    local Content = create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -200, 1, 0),
        Position = UDim2.new(0, 200, 0, 0),
        BackgroundTransparency = 1,
        Parent = Main,
    })

    local Pages = create("Folder", {Name = "Pages", Parent = Content})

    local Window = {}
    Window._internal = {
        ScreenGui = ScreenGui,
        Main = Main,
        LeftBar = LeftBar,
        Content = Content,
        Pages = Pages,
        Tabs = {}
    }
    setmetatable(Window, self)

    -- Function para criar tabs
    function Window:MakeTab(opts)
        opts = opts or {}
        local tabName = opts.Name or ("Tab"..(#self._internal.Tabs + 1))
        -- Botão da tab na barra esquerda
        local Button = create("TextButton", {
            Name = "Tab_"..tabName,
            Text = tabName,
            Size = UDim2.new(1, -24, 0, 40),
            BackgroundColor3 = Color3.fromRGB(30,30,30),
            TextColor3 = DEFAULT.TextColor,
            Font = DEFAULT.Font,
            TextSize = 16,
            Parent = self._internal.LeftBar,
        })
        create("UICorner", {Parent = Button, CornerRadius = UDim.new(0, 8)})

        if opts.Desc then
            Button.ToolTip = opts.Desc
        end

        -- Página correspondente
        local Page = create("ScrollingFrame", {
            Name = "Page_"..tabName,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ScrollBarThickness = 6,
            Parent = self._internal.Pages,
            Visible = false,
        })
        local layout = create("UIListLayout", {Parent = Page})
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 10)

        local Tab = {
            _btn = Button,
            _page = Page,
            _layout = layout,
            _sections = {},
            _parent = self,
        }
        setmetatable(Tab, {__index = self})

        function Tab:AddSection(opts)
            opts = opts or {}
            local sec = create("Frame", {
                Name = "Section_"..(opts.Name or "Section"),
                Size = UDim2.new(1, -20, 0, 140),
                BackgroundColor3 = Color3.fromRGB(30,30,35),
                BorderSizePixel = 0,
                Parent = self._page,
                LayoutOrder = #self._sections + 1,
            })
            create("UICorner", {Parent = sec, CornerRadius = UDim.new(0,8)})

            local title = create("TextLabel", {
                Text = opts.Name or "Section",
                TextColor3 = DEFAULT.TextColor,
                Font = DEFAULT.Font,
                TextSize = 17,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 6),
                Size = UDim2.new(1, -20, 0, 24),
                Parent = sec,
            })

            local desc = nil
            if opts.Desc then
                desc = create("TextLabel", {
                    Text = opts.Desc,
                    TextColor3 = DEFAULT.TextColor:lerp(Color3.new(1,1,1), -0.6),
                    Font = DEFAULT.Font,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 32),
                    Size = UDim2.new(1, -20, 0, 26),
                    Parent = sec,
                })
            end

            local content = create("Frame", {
                Name = "Content",
                Position = UDim2.new(0, 10, 0, desc and 64 or 36),
                Size = UDim2.new(1, -20, 1, desc and -64 or -36),
                BackgroundTransparency = 1,
                Parent = sec,
            })
            local contentLayout = create("UIListLayout", {Parent = content})
            contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
            contentLayout.Padding = UDim.new(0, 8)

            table.insert(self._sections, content)

            -- Métodos AddX para esta seção
            local SectionAPI = {}

            -- Adiciona Label
            function SectionAPI:AddLabel(opts)
                local frame = create("Frame", {Size = UDim2.new(1,0,0,40), BackgroundTransparency = 1, Parent = content, LayoutOrder = #content:GetChildren()+1})
                local lbl = create("TextLabel", {
                    Text = (opts.Name or ""),
                    TextColor3 = DEFAULT.TextColor,
                    Font = DEFAULT.Font,
                    TextSize = 16,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 4, 0, 6),
                    Size = UDim2.new(1,-8,1,-12),
                    Parent = frame
                })
                if opts.Desc then
                    lbl.Text = opts.Name .. "\n" .. opts.Desc
                end
                return frame
            end

            -- Adiciona Paragraph
            function SectionAPI:AddParagraph(opts)
                local frame = create("Frame", {Size = UDim2.new(1,0,0,80), BackgroundTransparency = 1, Parent = content, LayoutOrder= #content:GetChildren()+1})
                local lbl = create("TextLabel", {
                    Text = ((opts.Name or "") .. "\n" .. (opts.Desc or "")),
                    TextWrapped = true,
                    TextColor3 = DEFAULT.TextColor,
                    Font = DEFAULT.Font,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 6, 0, 6),
                    Size = UDim2.new(1, -12, 1, -12),
                    Parent = frame,
                })
                return frame
            end

            -- Adiciona Button
            function SectionAPI:AddButton(opts)
                local btn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 36),
                    BackgroundColor3 = Color3.fromRGB(50,50,55),
                    TextColor3 = DEFAULT.TextColor,
                    Font = DEFAULT.Font,
                    TextSize = 15,
                    Text = opts.Name or "Button",
                    Parent = content,
                    LayoutOrder = #content:GetChildren()+1,
                })
                create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 6)})
                btn.MouseButton1Click:Connect(function()
                    if opts.Callback then pcall(opts.Callback) end
                end)
                return btn
            end

            -- Adiciona Toggle
            function SectionAPI:AddToggle(opts)
                local container = create("Frame", {Size = UDim2.new(1,0,0,38), BackgroundTransparency = 1, Parent = content, LayoutOrder = #content:GetChildren()+1})
                local label = create("TextLabel", {
                    Text = opts.Name or "Toggle",
                    Size = UDim2.new(0.7,0,1,0),
                    Position = UDim2.new(0, 4, 0, 0),
                    TextColor3 = DEFAULT.TextColor,
                    Font = DEFAULT.Font,
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Parent = container,
                })
                local toggle = create("TextButton", {
                    Text = "",
                    Size = UDim2.new(0, 46, 0, 25),
                    Position = UDim2.new(1,-52,0,6),
                    BackgroundColor3 = opts.Default and DEFAULT.AccentColor or Color3.fromRGB(70,70,70),
                    Parent = container,
                })
                create("UICorner", {Parent = toggle, CornerRadius = UDim.new(0,6)})

                local state = opts.Default and true or false

                toggle.MouseButton1Click:Connect(function()
                    if opts.Locked then return end
                    state = not state
                    toggle.BackgroundColor3 = state and DEFAULT.AccentColor or Color3.fromRGB(70,70,70)
                    if opts.Callback then pcall(opts.Callback, state) end
                end)

                if opts.Locked then
                    toggle.Active = false
                    toggle.AutoButtonColor = false
                    toggle.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                end

                if opts.Callback then
                    pcall(opts.Callback, state)
                end

                return toggle
            end

            -- Adiciona Dropdown
            function SectionAPI:AddDropdown(opts)
                local container = create("Frame", {Size = UDim2.new(1,0,0,40), BackgroundTransparency = 1, Parent = content, LayoutOrder = #content:GetChildren()+1})
                local label = create("TextLabel", {
                    Text = opts.Name or "Dropdown",
                    Size = UDim2.new(0.6, 0, 1, 0),
                    Position = UDim2.new(0, 4, 0, 0),
                    TextColor3 = DEFAULT.TextColor,
                    Font = DEFAULT.Font,
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Parent = container,
                })

                local current = opts.Default or (opts.Options and opts.Options[1]) or "Select"
                local btn = create("TextButton", {
                    Text = current,
                    Size = UDim2.new(0.37, 0, 0, 28),
                    Position = UDim2.new(1, -0.37, 0, 6),
                    BackgroundColor3 = Color3.fromRGB(45,45,50),
                    TextColor3 = DEFAULT.TextColor,
                    Font = DEFAULT.Font,
                    TextSize = 14,
                    Parent = container,
                })
                create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 6)})

                local list = create("Frame", {
                    Size = UDim2.new(0.37, 0, 0, 0),
                    Position = UDim2.new(1, -0.37, 0, 40),
                    BackgroundColor3 = Color3.fromRGB(40,40,45),
                    Parent = container,
                    ClipsDescendants = true,
                })
                create("UICorner", {Parent = list, CornerRadius = UDim.new(0, 6)})

                local layout = create("UIListLayout", {Parent = list})
                layout.Padding = UDim.new(0, 2)

                local open = false

                local function rebuild()
                    for _,c in ipairs(list:GetChildren()) do
                        if not c:IsA("UIListLayout") then
                            c:Destroy()
                        end
                    end
                    for i,opt in ipairs(opts.Options or {}) do
                        local optBtn = create("TextButton", {
                            Text = tostring(opt),
                            Size = UDim2.new(1, -8, 0, 28),
                            BackgroundTransparency = 1,
                            TextColor3 = DEFAULT.TextColor,
                            Font = DEFAULT.Font,
                            TextSize = 14,
                            Parent = list,
                            LayoutOrder = i,
                        })
                        optBtn.MouseButton1Click:Connect(function()
                            btn.Text = tostring(opt)
                            open = false
                            list:TweenSize(UDim2.new(0.37, 0, 0, 0), "Out", "Quad", 0.18, true)
                            if opts.Callback then pcall(opts.Callback, tostring(opt)) end
                        end)
                    end
                end
                rebuild()

                btn.MouseButton1Click:Connect(function()
                    open = not open
                    if open then
                        list:TweenSize(UDim2.new(0.37,0,0,#(opts.Options or {})*30), "Out", "Quad", 0.18, true)
                    else
                        list:TweenSize(UDim2.new(0.37,0,0,0), "Out", "Quad", 0.18, true)
                    end
                end)

                return btn
            end

            -- Adiciona ColorPicker
            function SectionAPI:AddColorPicker(opts)
                local container = create("Frame", {Size = UDim2.new(1,0,0,38), BackgroundTransparency = 1, Parent = content, LayoutOrder = #content:GetChildren()+1})
                local label = create("TextLabel", {
                    Text = opts.Name or "Color Picker",
                    Size = UDim2.new(0.6,0,1,0),
                    Position = UDim2.new(0,4,0,0),
                    TextColor3 = DEFAULT.TextColor,
                    Font = DEFAULT.Font,
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Parent = container,
                })
                local color = Color3.fromRGB(96,165,250)
                if opts.DefaultColor then color = opts.DefaultColor end
                local box = create("TextButton", {
                    Size = UDim2.new(0,28,0,28),
                    Position = UDim2.new(1,-32,0,5),
                    BackgroundColor3 = color,
                    Parent = container,
                })
                create("UICorner", {Parent = box, CornerRadius = UDim.new(0,6)})

                local picker = create("Frame", {
                    Size = UDim2.new(0, 160, 0, 96),
                    Position = UDim2.new(1,-160,0,38),
                    BackgroundColor3 = Color3.fromRGB(40,40,45),
                    Parent = container,
                    Visible = false,
                })
                create("UICorner", {Parent = picker, CornerRadius = UDim.new(0,6)})

                local hueBar = create("Frame", {
                    Size = UDim2.new(0.15, 0, 1, 0),
                    Position = UDim2.new(0, 8, 0, 8),
                    BackgroundColor3 = Color3.fromRGB(230, 0, 0),
                    Parent = picker,
                })

                local swatch = create("Frame", {
                    Size = UDim2.new(1, -32, 1, -16),
                    Position = UDim2.new(0.18, 8, 0, 8),
                    BackgroundColor3 = color,
                    Parent = picker,
                })
                create("UICorner",{Parent = swatch, CornerRadius = UDim.new(0,6)})

                local open = false
                box.MouseButton1Click:Connect(function()
                    open = not open
                    picker.Visible = open
                end)
                hueBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local conn
                        conn = UserInputService.InputChanged:Connect(function(i)
                            if i.UserInputType == Enum.UserInputType.MouseMovement then
                                local rel = math.clamp((i.Position.X - hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X, 0, 1)
                                local c = Color3.fromHSV(rel, 0.8, 0.9)
                                swatch.BackgroundColor3 = c
                                box.BackgroundColor3 = c
                                if opts.Callback then
                                    pcall(opts.Callback, c)
                                end
                            end
                        end)
                        local upconn
                        upconn = UserInputService.InputEnded:Connect(function(i)
                            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                                conn:Disconnect()
                                upconn:Disconnect()
                            end
                        end)
                    end
                end)
                if opts.Callback then
                    pcall(opts.Callback, color)
                end
                return box
            end

            -- Adiciona Bind
            function SectionAPI:AddBind(opts)
                local container = create("Frame", {Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Parent = content, LayoutOrder = #content:GetChildren()+1})
                local label = create("TextLabel", {
                    Text = opts.Name or "Bind",
                    Size = UDim2.new(0.6, 0, 1, 0),
                    Position = UDim2.new(0, 4, 0, 0),
                    TextColor3 = DEFAULT.TextColor,
                    Font = DEFAULT.Font,
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Parent = container,
                })
                local currentKey = opts.Key or "None"
                local btn = create("TextButton", {
                    Text = currentKey,
                    Size = UDim2.new(0.37, 0, 0, 28),
                    Position = UDim2.new(1, -0.37, 0, 5),
                    BackgroundColor3 = Color3.fromRGB(45,45,50),
                    TextColor3 = DEFAULT.TextColor,
                    Font = DEFAULT.Font,
                    TextSize = 14,
                    Parent = container,
                })
                create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 6)})

                local listening = false
                btn.MouseButton1Click:Connect(function()
                    listening = true
                    btn.Text = "..."
                end)

                UserInputService.InputBegan:Connect(function(input)
                    if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        btn.Text = input.KeyCode.Name
                        listening = false
                        if opts.Callback then
                            pcall(opts.Callback, input.KeyCode.Name)
                        end
                    elseif input.UserInputType == Enum.UserInputType.Keyboard then
                        if btn.Text ~= "None" and btn.Text ~= "..." and input.KeyCode.Name == btn.Text then
                            if opts.Callback then
                                pcall(opts.Callback, input.KeyCode.Name)
                            end
                        end
                    end
                end)
                return btn
            end

            -- Adiciona Slider
            function SectionAPI:AddSlider(opts)
                local container = create("Frame", {Size = UDim2.new(1,0,0,52), BackgroundTransparency = 1, Parent = content, LayoutOrder = #content:GetChildren()+1})

                local lbl = create("TextLabel", {
                    Text = (opts.Name or "Slider") .. " (" .. tostring(opts.Default or 0) .. ")",
                    Size = UDim2.new(1,0,0,18),
                    BackgroundTransparency = 1,
                    TextColor3 = DEFAULT.TextColor,
                    Font = DEFAULT.Font,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = container,
                })

                local barBg = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 16),
                    Position = UDim2.new(0, 0, 0, 30),
                    BackgroundColor3 = Color3.fromRGB(40,40,45),
                    Parent = container,
                })
                create("UICorner", {Parent = barBg, CornerRadius = UDim.new(0, 6)})

                local min = opts.Min or 0
                local max = opts.Max or 100
                local default = opts.Default or min

                local fill = create("Frame", {
                    Size = UDim2.new((default-min)/(max-min), 0, 1, 0),
                    BackgroundColor3 = DEFAULT.AccentColor,
                    Parent = barBg,
                })
                create("UICorner", {Parent = fill, CornerRadius = UDim.new(0,6)})

                local dragging = false

                barBg.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local posX = math.clamp(input.Position.X - barBg.AbsolutePosition.X,0 , barBg.AbsoluteSize.X)
                        local ratio = posX / barBg.AbsoluteSize.X
                        fill.Size = UDim2.new(ratio,0,1,0)
                        local val = math.floor(min + ratio*(max-min))
                        lbl.Text = (opts.Name or "Slider") .. " (" .. tostring(val) .. ")"
                        if opts.Callback then
                            pcall(opts.Callback, val)
                        end
                    end
                end)
                if opts.Callback then
                    pcall(opts.Callback, default)
                end
                return fill
            end

            -- Adiciona Textbox
            function SectionAPI:AddTextbox(opts)
                local container = create("Frame", {Size = UDim2.new(1,0,0,40), BackgroundTransparency = 1, Parent = content, LayoutOrder = #content:GetChildren()+1})

                local lbl = create("TextLabel", {
                    Text = opts.Name or "Textbox",
                    Size = UDim2.new(0.45, 0, 1, 0),
                    Position = UDim2.new(0, 4, 0, 0),
                    TextColor3 = DEFAULT.TextColor,
                    Font = DEFAULT.Font,
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Parent = container,
                })

                local box = create("TextBox", {
                    Size = UDim2.new(0.53, 0, 1, 0),
                    Position = UDim2.new(0.47, 0, 0, 0),
                    BackgroundColor3 = Color3.fromRGB(40,40,45),
                    TextColor3 = DEFAULT.TextColor,
                    Font = DEFAULT.Font,
                    TextSize = 14,
                    ClearTextOnFocus = false,
                    PlaceholderText = opts.Placeholder or "",
                    Parent = container,
                })
                create("UICorner", {Parent = box, CornerRadius = UDim.new(0,6)})
                box.FocusLost:Connect(function(enterPressed)
                    if enterPressed then
                        if opts.Callback then
                            pcall(opts.Callback, box.Text)
                        end
                    end
                end)
                return box
            end

            return SectionAPI
        end

        -- Função para ativar a tab atual, desativando outras
        function Tab:Activate()
            for _, t in ipairs(self._parent._internal.Tabs) do
                if t ~= self then
                    if t._btn then t._btn.BackgroundColor3 = Color3.fromRGB(30,30,30) end
                    if t._page then t._page.Visible = false end
                end
            end
            if self._btn then
                self._btn.BackgroundColor3 = DEFAULT.AccentColor
            end
            if self._page then
                self._page.Visible = true
            end
        end

        -- Conectar para ativar a tab ao clicar botão
        Button.MouseButton1Click:Connect(function()
            Tab:Activate()
        end)

        -- Ativa automaticamente a primeira tab criada
        if #self._internal.Tabs == 0 then
            Tab:Activate()
        end

        table.insert(self._internal.Tabs, Tab)
        return Tab
    end

    -- Notificação simples
    function Window:Notification(opts)
        opts = opts or {}
        local notif = create("Frame", {
            Size = UDim2.new(0, 280, 0, 80),
            Position = UDim2.new(0.5,-140,0,40),
            BackgroundColor3 = Color3.fromRGB(35,35,40),
            Parent = self._internal.ScreenGui,
            ZIndex = 50,
        })
        create("UICorner", {Parent = notif, CornerRadius = UDim.new(0,8)})

        local title = create("TextLabel", {
            Text = opts.Title or "Notificação",
            Font = DEFAULT.Font,
            TextSize = 18,
            TextColor3 = DEFAULT.AccentColor,
            BackgroundTransparency = 1,
            Size = UDim2.new(1,-20,0,24),
            Position = UDim2.new(0,10,0,8),
            Parent = notif,
        })

        local desc = create("TextLabel", {
            Text = opts.Desc or "",
            Font = DEFAULT.Font,
            TextSize = 14,
            TextColor3 = DEFAULT.TextColor,
            BackgroundTransparency = 1,
            Size = UDim2.new(1,-20,0,36),
            Position = UDim2.new(0,10,0,32),
            TextWrapped = true,
            Parent = notif,
        })

        coroutine.wrap(function()
            local duration = opts.Duration or 5
            wait(duration)
            if notif and notif.Parent then
                local tween = TweenService:Create(notif, TweenInfo.new(0.3), {BackgroundTransparency = 1, Position = notif.Position + UDim2.new(0,0,-50)})
                tween:Play()
                tween.Completed:Wait()
                notif:Destroy()
            end
        end)()

        return notif
    end

    return Window
end

return setmetatable({}, {__index = RZ})
