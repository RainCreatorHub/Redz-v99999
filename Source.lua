-- RZLikeComplete.lua
-- Biblioteca Mega Completa Inspirada na RedZ
-- Janela 480x350, Key System 250x250 (modal)
-- Use em LocalScript, com require(ModuleScript)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function create(class, props)
    local obj = Instance.new(class)
    if props then
        for k,v in pairs(props) do obj[k] = v end
    end
    return obj
end

local DEFAULT = {
    WindowSize = UDim2.new(0, 480, 0, 350),        -- Janela principal
    WindowPos = UDim2.new(0.5, -240, 0.5, -175),
    KeySize = UDim2.new(0, 250, 0, 250),           -- Modal key system
    KeyPos = UDim2.new(0.5, -125, 0.5, -125),

    BackgroundColor = Color3.fromRGB(28,28,32),
    AccentColor = Color3.fromRGB(96,165,250),
    TextColor = Color3.fromRGB(230,230,235),
    Font = Enum.Font.Gotham,
}

local RZ = {}
RZ.__index = RZ

local function isNumeric(n)
    return type(n) == "number" or (type(n) == "string" and tonumber(n) ~= nil)
end

local function hexToColor3(hex)
    -- Parses "#RRGGBB" strings to Color3
    if type(hex) ~= "string" then return nil end
    if not hex:match("^#%x%x%x%x%x%x$") then return nil end
    local r = tonumber("0x"..hex:sub(2,3))
    local g = tonumber("0x"..hex:sub(4,5))
    local b = tonumber("0x"..hex:sub(6,7))
    return Color3.fromRGB(r,g,b)
end

local function lerpColor(c1,c2,a)
    return c1:lerp(c2,a)
end

local function clearChildren(frame)
    for _,c in ipairs(frame:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
            c:Destroy()
        end
    end
end

local function waitForInput(actionName, inputTypes, filter)
    -- Helper for input awaits (if needed)
    -- Currently unused, but potential extension
end

-- Criar janela base e components principais
local function buildBaseWindow(opts)
    opts = opts or {}
    local screenGui = create("ScreenGui", {
        Name = "RZ_Window_"..tostring(opts.Title or "UI"),
        ResetOnSpawn = false,
        DisplayOrder = 9999,
        IgnoreGuiInset = true
    })
    screenGui.Parent = PlayerGui

    local main = create("Frame", {
        Name = "MainWindow",
        Size = DEFAULT.WindowSize,
        Position = DEFAULT.WindowPos,
        BackgroundColor3 = DEFAULT.BackgroundColor,
        BorderSizePixel = 0,
        Parent = screenGui,
        ClipsDescendants = true,
    })
    create("UICorner", {Parent = main, CornerRadius = UDim.new(0,10)})

    -- Barra de título
    local titleBar = create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1,0,0,38),
        BackgroundTransparency = 1,
        Parent = main,
    })
    local titleLabel = create("TextLabel", {
        Name = "Title",
        Text = opts.Title or "Window",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        TextColor3 = DEFAULT.TextColor,
        Font = DEFAULT.Font,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar,
    })
    local subLabel = create("TextLabel", {
        Name = "SubTitle",
        Text = opts.SubTitle or "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 12, 0, 18),
        TextColor3 = lerpColor(DEFAULT.TextColor, Color3.new(1,1,1), -0.6),
        Font = DEFAULT.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar,
    })

    local closeBtn = create("TextButton", {
        Name = "CloseBtn",
        Text = "X",
        Size = UDim2.new(0, 34, 0, 26),
        Position = UDim2.new(1, -46, 0, 6),
        BackgroundColor3 = Color3.fromRGB(40,40,45),
        TextColor3 = DEFAULT.TextColor,
        Font = DEFAULT.Font,
        TextSize = 16,
        Parent = titleBar,
    })
    create("UICorner", {Parent = closeBtn, CornerRadius = UDim.new(0,6)})
    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = not main.Visible
    end)

    -- Barra esquerda para abas (tabs)
    local leftBar = create("Frame", {
        Name = "LeftBar",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 160, 1, 0),
        Parent = main,
    })
    local leftLayout = create("UIListLayout", {
        Parent = leftBar,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    })

    -- Área de conteúdo das pages
    local contentArea = create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -160, 1, 0),
        Position = UDim2.new(0, 160, 0, 0),
        BackgroundTransparency = 1,
        Parent = main,
    })

    local pages = create("Folder", {Name = "Pages", Parent = contentArea})

    -- Ícone no título se fornecido
    if opts.Icon then
        local icon = create("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0,28,0,28),
            Position = UDim2.new(0,8,0,5),
            BackgroundTransparency = 1,
            Parent = titleBar,
        })
        if isNumeric(opts.Icon) then
            icon.Image = "rbxassetid://" .. tostring(opts.Icon)
        else
            icon.Image = tostring(opts.Icon)
        end
    end

    -- Funcionalidade de arrastar a janela
    do
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
            if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    return {
        ScreenGui = screenGui,
        Main = main,
        LeftBar = leftBar,
        Pages = pages,
        TitleLabel = titleLabel,
        SubLabel = subLabel,
        Options = opts,
    }
end

function RZ:MakeWindow(options)
    options = options or {}
    local winObj = buildBaseWindow(options)

    local authenticated = not options.KeySystem

    -- Modal Key System 250x250
    local modal, card, input, status

    if options.KeySystem then
        modal = create("Frame", {
            Name = "KeyModal",
            Size = UDim2.new(1,0,1,0),
            BackgroundColor3 = Color3.fromRGB(0,0,0),
            BackgroundTransparency = 0.5,
            Parent = winObj.ScreenGui,
        })
        card = create("Frame", {
            Name = "KeyCard",
            Size = DEFAULT.KeySize,
            Position = DEFAULT.KeyPos,
            BackgroundColor3 = Color3.fromRGB(36,36,40),
            Parent = modal,
        })
        create("UICorner",{Parent=card, CornerRadius = UDim.new(0,8)})

        local title = create("TextLabel", {
            Text = options.KeySettings and options.KeySettings.Title or "Chave Necessária",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -24, 0, 36),
            Position = UDim2.new(0,12,0,8),
            TextColor3 = DEFAULT.TextColor,
            Font = DEFAULT.Font,
            TextSize = 18,
            Parent = card,
        })

        local descLabel = create("TextLabel", {
            Text = options.KeySettings and options.KeySettings.Desc or "Insira a chave",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -24, 0, 48),
            Position = UDim2.new(0,12,0,44),
            TextColor3 = DEFAULT.TextColor,
            Font = DEFAULT.Font,
            TextSize = 14,
            TextWrapped = true,
            Parent = card,
        })

        input = create("TextBox", {
            Text = "",
            PlaceholderText = "Chave...",
            Size = UDim2.new(1, -24, 0, 36),
            Position = UDim2.new(0,12,0,100),
            BackgroundColor3 = Color3.fromRGB(50,50,55),
            TextColor3 = DEFAULT.TextColor,
            Font = DEFAULT.Font,
            TextSize = 16,
            Parent = card,
        })
        create("UICorner",{Parent=input, CornerRadius = UDim.new(0,6)})

        local btn = create("TextButton", {
            Text = "Enviar",
            Size = UDim2.new(0,100,0,30),
            Position = UDim2.new(1, -112, 1, -40),
            BackgroundColor3 = DEFAULT.AccentColor,
            TextColor3 = Color3.new(1,1,1),
            Font = DEFAULT.Font,
            TextSize = 14,
            Parent = card,
        })
        create("UICorner",{Parent=btn, CornerRadius = UDim.new(0,6)})

        status = create("TextLabel", {
            Text = "",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -24, 0, 18),
            Position = UDim2.new(0, 12, 1, -42),
            TextColor3 = Color3.fromRGB(255, 120, 120),
            Font = DEFAULT.Font,
            TextSize = 14,
            Parent = card,
        })

        local function validateKey(k)
            if not options.KeySettings or not options.KeySettings.Key then return false end
            for _,v in ipairs(options.KeySettings.Key) do
                if tostring(v) == tostring(k) then return true end
            end
            return false
        end

        btn.MouseButton1Click:Connect(function()
            local v = input.Text
            if validateKey(v) then
                status.Text = "Chave válida. Acessando..."
                authenticated = true
                TweenService:Create(modal, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
                wait(0.25)
                modal:Destroy()
            else
                status.Text = "Chave inválida."
            end
        end)

        if options.KeySettings and options.KeySettings.Url then
            local urlBtn = create("TextButton", {
                Text = "Obter chave",
                Size = UDim2.new(0, 100, 0, 30),
                Position = UDim2.new(1, -228, 1, -40),
                BackgroundColor3 = Color3.fromRGB(70, 70, 75),
                TextColor3 = DEFAULT.TextColor,
                Font = DEFAULT.Font,
                TextSize = 14,
                Parent = card,
            })
            create("UICorner",{Parent=urlBtn, CornerRadius = UDim.new(0,6)})

            urlBtn.MouseButton1Click:Connect(function()
                if not HttpService.HttpEnabled then
                    status.Text = "HttpService desativado."
                    return
                end
                local ok, res = pcall(function()
                    return game:HttpGet(options.KeySettings.Url)
                end)
                if ok and res then
                    local list = {}
                    for line in res:gmatch("[^\r\n]+") do table.insert(list, line) end
                    options.KeySettings.Key = options.KeySettings.Key or {}
                    for _,k in ipairs(list) do
                        table.insert(options.KeySettings.Key, k)
                    end
                    status.Text = "Chaves adicionadas."
                else
                    status.Text = "Falha ao obter chave."
                end
            end)
        end
    end

    -- OBJETO WINDOW (exposto API)
    local Window = {}
    Window._internal = winObj
    Window._tabs = {}

    -- Criar nova tab
    function Window:MakeTab(tabOptions)
        tabOptions = tabOptions or {}
        if options.KeySystem then
            -- Bloqueia até modal fechar (autorizado)
            while true do
                if not winObj.ScreenGui or not winObj.ScreenGui.Parent then break end
                local mod = winObj.ScreenGui:FindFirstChild("KeyModal")
                if not mod then break end
                wait(0.1)
            end
        end

        local btn = create("TextButton", {
            Name = "TabBtn_"..(tabOptions.Name or "Tab"),
            Text = tabOptions.Name or "Tab",
            Size = UDim2.new(1, -24, 0, 40),
            BackgroundColor3 = Color3.fromRGB(35,35,40),
            TextColor3 = DEFAULT.TextColor,
            Font = DEFAULT.Font,
            TextSize = 15,
            Parent = winObj.LeftBar,
        })
        create("UICorner",{Parent=btn, CornerRadius = UDim.new(0,8)})
        if tabOptions.Desc then btn.ToolTip = tabOptions.Desc end
        if tabOptions.Icon then
            local img = create("ImageLabel", {
                Size = UDim2.new(0,20,0,20),
                Position = UDim2.new(0,6,0,10),
                BackgroundTransparency = 1,
                Parent = btn,
            })
            if isNumeric(tabOptions.Icon) then
                img.Image = "rbxassetid://"..tostring(tabOptions.Icon)
            else
                img.Image = tostring(tabOptions.Icon)
            end
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Text = "   "..btn.Text
        end

        local page = create("ScrollingFrame", {
            Name = "Page_"..(tabOptions.Name or "Page"),
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,1,0),
            ScrollBarThickness = 6,
            Parent = winObj.Pages,
            Visible = false,
            CanvasSize = UDim2.new(0,0,0,0)
        })
        local layout = create("UIListLayout", {Parent = page})
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0,10)

        local Tab = {
            Name = tabOptions.Name,
            _btn = btn,
            _page = page,
            _layout = layout,
            _sections = {},
            _parent = Window,
        }

        -- Ativa a aba e desativa as outras
        function Tab:Activate()
            for _, t in ipairs(self._parent._tabs) do
                if t ~= self then
                    t._btn.BackgroundColor3 = Color3.fromRGB(35,35,40)
                    t._page.Visible = false
                end
            end
            self._btn.BackgroundColor3 = DEFAULT.AccentColor
            self._page.Visible = true
        end

        btn.MouseButton1Click:Connect(function()
            Tab:Activate()
        end)

        -- Cria seções dentro da tab
        function Tab:AddSection(sectionOptions)
            sectionOptions = sectionOptions or {}
            local section = create("Frame", {
                Name = "Section_"..(sectionOptions.Name or "Section"),
                Size = UDim2.new(1, -16, 0, 140),
                BackgroundColor3 = Color3.fromRGB(26,26,30),
                Parent = page,
                LayoutOrder = #page:GetChildren() + 1,
            })
            create("UICorner", {Parent = section, CornerRadius = UDim.new(0,6)})
            local header = create("TextLabel", {
                Text = sectionOptions.Name or "Section",
                BackgroundTransparency = 1,
                Position = UDim2.new(0,8,0,6),
                Size = UDim2.new(1,-16,0,22),
                TextColor3 = DEFAULT.TextColor,
                Font = DEFAULT.Font,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = section,
            })
            local desc = nil
            if sectionOptions.Desc then
                desc = create("TextLabel", {
                    Text = sectionOptions.Desc,
                    TextColor3 = lerpColor(DEFAULT.TextColor, Color3.new(1,1,1), -0.6),
                    Font = DEFAULT.Font,
                    TextSize = 13,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0,8,0,32),
                    Size = UDim2.new(1,-16,0,26),
                    TextWrapped = true,
                    Parent = section,
                })
            end

            local content = create("Frame", {
                Name = "Content",
                Position = UDim2.new(0,8,0, desc and 62 or 36),
                Size = UDim2.new(1,-16,1, desc and -62 or -36),
                BackgroundTransparency = 1,
                Parent = section,
            })
            local contentLayout = create("UIListLayout", {Parent=content})
            contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
            contentLayout.Padding = UDim.new(0,6)

            table.insert(self._sections, content)

            local SectionAPI = {}
            local contentParent = content

            -- === Elementos ===

            -- Label
            function SectionAPI:AddLabel(opts)
                opts = opts or {}
                local frame = create("Frame", {
                    Size = UDim2.new(1,0,0,40),
                    BackgroundTransparency = 1,
                    LayoutOrder = #contentParent:GetChildren() + 1,
                    Parent = contentParent
                })
                local lbl = create("TextLabel", {
                    Text = opts.Name or "",
                    TextColor3 = DEFAULT.TextColor,
                    Font = DEFAULT.Font,
                    TextSize = 16,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 6, 0, 6),
                    Size = UDim2.new(1, -12, 1, -12),
                    Parent = frame
                })
                if opts.Desc then
                    lbl.Text = (opts.Name or "") .. "\n" .. opts.Desc
                    lbl.TextWrapped = true
                end
                return frame
            end

            -- Paragraph
            function SectionAPI:AddParagraph(opts)
                opts = opts or {}
                local frame = create("Frame", {
                    Size = UDim2.new(1,0,0,80),
                    BackgroundTransparency = 1,
                    LayoutOrder = #contentParent:GetChildren() + 1,
                    Parent = contentParent
                })
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

            -- Button
            function SectionAPI:AddButton(opts)
                opts = opts or {}
                local btn = create("TextButton", {
                    Text = opts.Name or "Button",
                    Size = UDim2.new(1,0,0,36),
                    BackgroundColor3 = Color3.fromRGB(50,50,55),
                    TextColor3 = DEFAULT.TextColor,
                    Font = DEFAULT.Font,
                    TextSize = 15,
                    LayoutOrder = #contentParent:GetChildren() + 1,
                    Parent = contentParent,
                })
                create("UICorner", {Parent = btn, CornerRadius = UDim.new(0,6)})
                btn.MouseButton1Click:Connect(function()
                    if opts.Callback then pcall(opts.Callback) end
                end)
                return btn
            end

            -- Toggle
            function SectionAPI:AddToggle(opts)
                opts = opts or {}
                local container = create("Frame", {
                    Size = UDim2.new(1,0,0,38),
                    BackgroundTransparency = 1,
                    LayoutOrder = #contentParent:GetChildren() + 1,
                    Parent = contentParent,
                })
                local lbl = create("TextLabel", {
                    Text = opts.Name or "Toggle",
                    Size = UDim2.new(0.7,0,1,0),
                    Position = UDim2.new(0,6,0,0),
                    TextColor3 = DEFAULT.TextColor,
                    Font = DEFAULT.Font,
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Parent = container,
                })
                local tog = create("TextButton", {
                    Text = "",
                    Size = UDim2.new(0, 46, 0, 25),
                    Position = UDim2.new(1,-52,0,6),
                    BackgroundColor3 = opts.Default and DEFAULT.AccentColor or Color3.fromRGB(70,70,70),
                    Parent = container,
                })
                create("UICorner", {Parent = tog, CornerRadius = UDim.new(0,6)})

                local state = opts.Default and true or false

                tog.MouseButton1Click:Connect(function()
                    if opts.Locked then return end
                    state = not state
                    tog.BackgroundColor3 = state and DEFAULT.AccentColor or Color3.fromRGB(70,70,70)
                    if opts.Callback then pcall(opts.Callback, state) end
                end)

                if opts.Locked then
                    tog.Active = false
                    tog.AutoButtonColor = false
                    tog.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                end

                if opts.Callback then
                    pcall(opts.Callback, state)
                end

                return tog
            end

            -- Dropdown
            function SectionAPI:AddDropdown(opts)
                opts = opts or {}
                local container = create("Frame", {
                    Size = UDim2.new(1,0,0,40),
                    BackgroundTransparency = 1,
                    LayoutOrder = #contentParent:GetChildren() + 1,
                    Parent = contentParent,
                })
                local lbl = create("TextLabel", {
                    Text = opts.Name or "Dropdown",
                    Size = UDim2.new(0.6,0,1,0),
                    Position = UDim2.new(0,6,0,0),
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
                    Size = UDim2.new(0.37,0,0,28),
                    Position = UDim2.new(1,-0.37,0,6),
                    BackgroundColor3 = Color3.fromRGB(45,45,50),
                    TextColor3 = DEFAULT.TextColor,
                    Font = DEFAULT.Font,
                    TextSize = 14,
                    Parent = container,
                })
                create("UICorner", {Parent = btn, CornerRadius = UDim.new(0,6)})

                local list = create("Frame", {
                    Size = UDim2.new(0.37,0,0,0),
                    Position = UDim2.new(1,-0.37,0,38),
                    BackgroundColor3 = Color3.fromRGB(40,40,45),
                    Parent = container,
                    ClipsDescendants = true,
                })
                create("UICorner", {Parent = list, CornerRadius = UDim.new(0,6)})

                local layout = create("UIListLayout", {Parent = list})
                layout.Padding = UDim.new(0,4)

                local open = false

                local function rebuild()
                    for _,c in ipairs(list:GetChildren()) do
                        if not c:IsA("UIListLayout") then c:Destroy() end
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
                            list:TweenSize(UDim2.new(0.37,0,0,0), "Out", "Quad", 0.18, true)
                            if opts.Callback then pcall(opts.Callback, tostring(opt)) end
                        end)
                    end
                    local totalHeight = (#(opts.Options or {}) * 30)
                    if not open then totalHeight = 0 end
                    list:TweenSize(UDim2.new(0.37, 0, 0, totalHeight), "Out", "Quad", 0.18, true)
                end
                rebuild()

                btn.MouseButton1Click:Connect(function()
                    open = not open
                    rebuild()
                end)

                return btn
            end

            -- ColorPicker
            function SectionAPI:AddColorPicker(opts)
                opts = opts or {}
                local container = create("Frame", {
                    Size = UDim2.new(1,0,0,38),
                    BackgroundTransparency = 1,
                    LayoutOrder = #contentParent:GetChildren() + 1,
                    Parent = contentParent,
                })
                local lbl = create("TextLabel", {
                    Text = opts.Name or "Color Picker",
                    Size = UDim2.new(0.6,0,1,0),
                    Position = UDim2.new(0,6,0,0),
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

            -- Bind
            function SectionAPI:AddBind(opts)
                opts = opts or {}
                local container = create("Frame", {
                    Size = UDim2.new(1,0,0,38),
                    BackgroundTransparency = 1,
                    LayoutOrder = #contentParent:GetChildren() + 1,
                    Parent = contentParent,
                })
                local lbl = create("TextLabel", {
                    Text = opts.Name or "Bind",
                    Size = UDim2.new(0.6,0,1,0),
                    Position = UDim2.new(0,6,0,0),
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
                    Size = UDim2.new(0.37,0,0,28),
                    Position = UDim2.new(1,-0.37,0,5),
                    BackgroundColor3 = Color3.fromRGB(45,45,50),
                    TextColor3 = DEFAULT.TextColor,
                    Font = DEFAULT.Font,
                    TextSize = 14,
                    Parent = container,
                })
                create("UICorner", {Parent = btn, CornerRadius = UDim.new(0,6)})

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

            -- Slider
            function SectionAPI:AddSlider(opts)
                opts = opts or {}

                local container = create("Frame", {
                    Size = UDim2.new(1,0,0,52),
                    BackgroundTransparency = 1,
                    LayoutOrder = #contentParent:GetChildren() + 1,
                    Parent = contentParent,
                })

                local lbl = create("TextLabel", {
                    Text = (opts.Name or "Slider") .. " (" .. tostring(opts.Default or opts.Min or 0) .. ")",
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
                local increment = opts.Increment or 1

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
                        local posX = math.clamp(input.Position.X - barBg.AbsolutePosition.X, 0, barBg.AbsoluteSize.X)
                        local ratio = posX / barBg.AbsoluteSize.X
                        fill.Size = UDim2.new(ratio, 0, 1, 0)
                        local val = min + math.floor(((max-min) * ratio)/increment + 0.5) * increment
                        val = math.clamp(val, min, max)
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

            -- Textbox
            function SectionAPI:AddTextbox(opts)
                opts = opts or {}
                local container = create("Frame", {
                    Size = UDim2.new(1,0,0,40),
                    BackgroundTransparency = 1,
                    LayoutOrder = #contentParent:GetChildren() + 1,
                    Parent = contentParent,
                })

                local lbl = create("TextLabel", {
                    Text = opts.Name or "Textbox",
                    Size = UDim2.new(0.45, 0, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
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
                    if enterPressed and opts.Callback then
                        pcall(opts.Callback, box.Text)
                    end
                end)

                return box
            end

            return SectionAPI
        end

        table.insert(Window._tabs, Tab)
        Tab:Activate()
        return Tab
    end

    function Window:Destroy()
        if winObj.ScreenGui and winObj.ScreenGui.Parent then
            winObj.ScreenGui:Destroy()
        end
    end

    -- Notificação simples com fade out
    function Window:Notification(opts)
        opts = opts or {}
        local notif = create("Frame", {
            Size = UDim2.new(0, 280, 0, 80),
            Position = UDim2.new(0.5, -140, 0, 40),
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
            Size = UDim2.new(1, -20, 0, 24),
            Position = UDim2.new(0, 10, 0, 8),
            Parent = notif,
        })

        local desc = create("TextLabel", {
            Text = opts.Desc or "",
            Font = DEFAULT.Font,
            TextSize = 14,
            TextColor3 = DEFAULT.TextColor,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -20, 0, 36),
            Position = UDim2.new(0, 10, 0, 32),
            TextWrapped = true,
            Parent = notif,
        })

        coroutine.wrap(function()
            local duration = opts.Duration or 5
            wait(duration)
            if notif and notif.Parent then
                local tween = TweenService:Create(notif, TweenInfo.new(0.3), {BackgroundTransparency = 1, Position = notif.Position + UDim2.new(0, 0, -0.1, 0)})
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
