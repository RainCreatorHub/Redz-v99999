-- RZLike.lua - Biblioteca completa com Sections e elementos
-- Janela 480x350, sistema de Key 250x250, dragBar, tabBar e elementBar integrados

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function create(class, props)
    local obj = Instance.new(class)
    if props then for k,v in pairs(props) do obj[k] = v end end
    return obj
end

local DEFAULT = {
    WindowSize = UDim2.new(0, 480, 0, 350),
    WindowPos = UDim2.new(0.5, -240, 0.5, -175),
    KeySize = UDim2.new(0, 250, 0, 250),
    KeyPos = UDim2.new(0.5, -125, 0.5, -125),
    BackgroundColor = Color3.fromRGB(28,28,32),
    AccentColor = Color3.fromRGB(96,165,250),
    TextColor = Color3.fromRGB(230,230,235),
    Font = Enum.Font.Gotham,
}

local RZ = {}
RZ.__index = RZ

local function lerpColor(c1, c2, a)
    return c1:lerp(c2, a)
end

local function isNumeric(val)
    return type(val) == "number" or (type(val) == "string" and tonumber(val) ~= nil)
end

local function safePcall(func, ...)
    local ok, res = pcall(func, ...)
    if not ok then warn("[RZLike] Callback error:", res) end
    return ok, res
end

local function validateKey(keylist, key)
    if not keylist then return false end
    for _, v in ipairs(keylist) do
        if tostring(v) == tostring(key) then return true end
    end
    return false
end

local function clearChildren(frame)
    for _, c in ipairs(frame:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
            c:Destroy()
        end
    end
end

local function draggable(frame, dragBar)
    local dragging, dragInput, dragStart, startPos
    dragBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    dragBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function buildBaseWindow(opts)
    opts = opts or {}

    local screenGui = create("ScreenGui", {
        Name = "RZ_Window_" .. (opts.Title or "UI"),
        ResetOnSpawn = false,
        DisplayOrder = 9999,
        IgnoreGuiInset = true,
    })
    screenGui.Parent = PlayerGui

    local main = create("Frame", {
        Name = "WindowMain",
        Size = DEFAULT.WindowSize,
        Position = DEFAULT.WindowPos,
        BackgroundColor3 = DEFAULT.BackgroundColor,
        Parent = screenGui,
        ClipsDescendants = true,
        BorderSizePixel = 0,
    })
    create("UICorner", {Parent = main, CornerRadius = UDim.new(0, 10)})

    -- DragBar
    local dragBar = create("Frame", {
        Name = "DragBar",
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = Color3.fromRGB(45, 45, 50),
        Parent = main,
    })
    create("UICorner", {Parent = dragBar, CornerRadius = UDim.new(0, 8)})

    local dragLabel = create("TextLabel", {
        Text = opts.Title or "Window",
        TextColor3 = DEFAULT.TextColor,
        Font = DEFAULT.Font,
        TextSize = 16,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -52, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = dragBar,
    })

    local closeBtn = create("TextButton", {
        Text = "X",
        Size = UDim2.new(0, 34, 0, 24),
        Position = UDim2.new(1, -40, 0, 1),
        BackgroundColor3 = Color3.fromRGB(60, 60, 60),
        TextColor3 = DEFAULT.TextColor,
        Font = DEFAULT.Font,
        TextSize = 18,
        Parent = dragBar,
    })
    create("UICorner", {Parent = closeBtn, CornerRadius = UDim.new(0, 6)})
    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = not main.Visible
    end)

    draggable(main, dragBar)

    -- Container principal
    local container = create("Frame", {
        Name = "Container",
        Size = UDim2.new(1, 0, 1, -26),
        Position = UDim2.new(0, 0, 0, 26),
        BackgroundTransparency = 1,
        Parent = main,
    })

    -- TabBar (esquerda)
    local tabBar = create("Frame", {
        Name = "TabBar",
        Size = UDim2.new(0, 140, 1, 0),
        BackgroundTransparency = 1,
        Parent = container,
    })
    create("UIListLayout", {
        Parent = tabBar,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    })

    -- ContentArea (centro)
    local contentArea = create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -280, 1, 0),
        Position = UDim2.new(0, 140, 0, 0),
        BackgroundTransparency = 1,
        Parent = container,
    })
    local pages = create("Folder", {Name = "Pages", Parent = contentArea})

    -- ElementBar (direita)
    local elementBar = create("Frame", {
        Name = "ElementBar",
        Size = UDim2.new(0, 140, 1, 0),
        Position = UDim2.new(1, -140, 0, 0),
        BackgroundTransparency = 1,
        Parent = container,
    })
    create("UIListLayout", {
        Parent = elementBar,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    })

    -- Ícone titulo
    if opts.Icon then
        local icon = create("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 6, 0, 3),
            BackgroundTransparency = 1,
            Parent = dragBar,
        })
        if isNumeric(opts.Icon) then
            icon.Image = "rbxassetid://" .. tostring(opts.Icon)
        else
            icon.Image = tostring(opts.Icon)
        end
    end

    return {
        ScreenGui = screenGui,
        Main = main,
        DragBar = dragBar,
        TabBar = tabBar,
        ContentArea = contentArea,
        Pages = pages,
        ElementBar = elementBar,
        Options = opts,
    }
end


function RZ:MakeWindow(options)
    options = options or {}
    local winObj = buildBaseWindow(options)
    local authenticated = not options.KeySystem

    local modal, keyCard, keyInput, statusLabel, getKeyBtn

    -- === Key System modal ===
    if options.KeySystem then
        modal = create("Frame", {
            Name = "KeyModal",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.5,
            Parent = winObj.ScreenGui,
        })
        keyCard = create("Frame", {
            Name = "KeyCard",
            Size = DEFAULT.KeySize,
            Position = DEFAULT.KeyPos,
            BackgroundColor3 = Color3.fromRGB(36, 36, 40),
            Parent = modal,
        })
        create("UICorner", {Parent = keyCard, CornerRadius = UDim.new(0, 8)})

        local title = create("TextLabel", {
            Text = options.KeySettings and options.KeySettings.Title or "Chave Necessária",
            TextColor3 = DEFAULT.TextColor,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -24, 0, 36),
            Position = UDim2.new(0, 12, 0, 8),
            Font = DEFAULT.Font,
            TextSize = 18,
            Parent = keyCard,
        })
        local descLabel = create("TextLabel", {
            Text = options.KeySettings and options.KeySettings.Desc or "Insira a chave para continuar.",
            TextColor3 = DEFAULT.TextColor,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -24, 0, 48),
            Position = UDim2.new(0, 12, 0, 44),
            Font = DEFAULT.Font,
            TextSize = 14,
            TextWrapped = true,
            Parent = keyCard,
        })
        keyInput = create("TextBox", {
            PlaceholderText = "Digite a chave aqui...",
            Size = UDim2.new(1, -24, 0, 36),
            Position = UDim2.new(0, 12, 0, 100),
            BackgroundColor3 = Color3.fromRGB(50, 50, 55),
            TextColor3 = DEFAULT.TextColor,
            Font = DEFAULT.Font,
            TextSize = 16,
            Parent = keyCard,
        })
        create("UICorner", {Parent = keyInput, CornerRadius = UDim.new(0, 6)})

        local submitBtn = create("TextButton", {
            Text = "Enviar",
            Size = UDim2.new(0, 100, 0, 30),
            Position = UDim2.new(1, -112, 1, -40),
            BackgroundColor3 = DEFAULT.AccentColor,
            TextColor3 = Color3.new(1, 1, 1),
            Font = DEFAULT.Font,
            TextSize = 14,
            Parent = keyCard,
        })
        create("UICorner", {Parent = submitBtn, CornerRadius = UDim.new(0, 6)})

        statusLabel = create("TextLabel", {
            Text = "",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -24, 0, 18),
            Position = UDim2.new(0, 12, 1, -42),
            TextColor3 = Color3.fromRGB(255, 120, 120),
            Font = DEFAULT.Font,
            TextSize = 14,
            Parent = keyCard,
        })

        local function checkKey(key)
            return validateKey(options.KeySettings.Key, key)
        end

        submitBtn.MouseButton1Click:Connect(function()
            local enteredKey = keyInput.Text
            if checkKey(enteredKey) then
                statusLabel.Text = "Chave válida! Acessando..."
                authenticated = true
                TweenService:Create(modal, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
                wait(0.25)
                modal:Destroy()
            else
                statusLabel.Text = "Chave inválida."
            end
        end)

        if options.KeySettings and options.KeySettings.Url then
            getKeyBtn = create("TextButton", {
                Text = "Obter chave",
                Size = UDim2.new(0, 100, 0, 30),
                Position = UDim2.new(1, -228, 1, -40),
                BackgroundColor3 = Color3.fromRGB(70, 70, 75),
                TextColor3 = DEFAULT.TextColor,
                Font = DEFAULT.Font,
                TextSize = 14,
                Parent = keyCard,
            })
            create("UICorner", {Parent = getKeyBtn, CornerRadius = UDim.new(0, 6)})

            getKeyBtn.MouseButton1Click:Connect(function()
                if not HttpService.HttpEnabled then
                    statusLabel.Text = "HttpService desabilitado."
                    return
                end
                local ok, res = pcall(function()
                    return game:HttpGet(options.KeySettings.Url)
                end)
                if ok and res then
                    local keys = {}
                    for line in res:gmatch("[^\r\n]+") do
                        table.insert(keys, line)
                    end
                    options.KeySettings.Key = options.KeySettings.Key or {}
                    for _, k in ipairs(keys) do
                        table.insert(options.KeySettings.Key, k)
                    end
                    statusLabel.Text = "Chaves obtidas com sucesso!"
                else
                    statusLabel.Text = "Falha ao obter chaves."
                end
            end)
        end
    end

    -- API WINDOW
    local Window = {}
    Window._internal = winObj
    Window._tabs = {}

    --- Criação de Tabs
    function Window:MakeTab(tabOptions)
        tabOptions = tabOptions or {}

        if options.KeySystem then
            while true do
                if not winObj.ScreenGui or not winObj.ScreenGui.Parent then break end
                if not winObj.ScreenGui:FindFirstChild("KeyModal") then break end
                wait(0.1)
            end
        end

        local btn = create("TextButton", {
            Name = "TabBtn_"..(tabOptions.Name or "Tab"),
            Text = tabOptions.Name or "Tab",
            Size = UDim2.new(1, -24, 0, 36),
            BackgroundColor3 = Color3.fromRGB(35,35,40),
            TextColor3 = DEFAULT.TextColor,
            Font = DEFAULT.Font,
            TextSize = 15,
            Parent = winObj.TabBar,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 8)})
        -- seta ↓ ao lado do texto
        btn.Text = btn.Text .. "  ↓"

        if tabOptions.Desc then btn.ToolTip = tabOptions.Desc end
        if tabOptions.Icon then
            local icon = create("ImageLabel", {
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(0, 4, 0, 9),
                BackgroundTransparency = 1,
                Parent = btn,
            })
            if isNumeric(tabOptions.Icon) then
                icon.Image = "rbxassetid://"..tostring(tabOptions.Icon)
            else
                icon.Image = tostring(tabOptions.Icon)
            end
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Text = "     " .. btn.Text
        end

        local page = create("ScrollingFrame", {
            Name = "Page_"..(tabOptions.Name or "Page"),
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ScrollBarThickness = 6,
            Parent = winObj.Pages,
            Visible = false,
            CanvasSize = UDim2.new(0, 0, 0, 0),
        })
        local layout = create("UIListLayout", {Parent = page})
        layout.Padding = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder

        local Tab = {
            Name = tabOptions.Name,
            _btn = btn,
            _page = page,
            _layout = layout,
            _sections = {},
            _parentWindow = Window,
        }
        setmetatable(Tab, {__index = Tab})

        function Tab:Activate()
            for _, t in ipairs(self._parentWindow._tabs) do
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

        --- Sections e elementos ---
        function Tab:AddSection(sectionOpts)
            sectionOpts = sectionOpts or {}

            local section = create("Frame", {
                Name = "Section_"..(sectionOpts.Name or "Section"),
                Size = UDim2.new(1, -16, 0, 140),
                BackgroundColor3 = Color3.fromRGB(26,26,30),
                Parent = page,
                LayoutOrder = #page:GetChildren() + 1,
                BorderSizePixel = 0,
            })
            create("UICorner", {Parent = section, CornerRadius = UDim.new(0,6)})

            local title = create("TextLabel", {
                Text = sectionOpts.Name or "Section",
                BackgroundTransparency = 1,
                Position = UDim2.new(0,8,0,6),
                Size = UDim2.new(1,-16,0,22),
                TextColor3 = DEFAULT.TextColor,
                Font = DEFAULT.Font,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = section,
            })

            local descLbl
            if sectionOpts.Desc then
                descLbl = create("TextLabel", {
                    Text = sectionOpts.Desc,
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

            local contentPosY = descLbl and 62 or 36
            local contentHeight = descLbl and -62 or -36
            local content = create("Frame", {
                Name = "Content",
                Position = UDim2.new(0,8,0,contentPosY),
                Size = UDim2.new(1,-16,1,contentHeight),
                BackgroundTransparency = 1,
                Parent = section,
            })
            local contentLayout = create("UIListLayout", {Parent = content})
            contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
            contentLayout.Padding = UDim.new(0,6)

            table.insert(self._sections, content)

            local SectionAPI = {}

            -- Label
            function SectionAPI:AddLabel(opts)
                opts = opts or {}
                local frame = create("Frame", {
                    Size = UDim2.new(1,0,0,40),
                    BackgroundTransparency = 1,
                    LayoutOrder = #content:GetChildren() + 1,
                    Parent = content,
                })
                local lbl = create("TextLabel", {
                    Text = opts.Name or "",
                    TextColor3 = DEFAULT.TextColor,
                    Font = DEFAULT.Font,
                    TextSize = 16,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0,6,0,6),
                    Size = UDim2.new(1,-12,1,-12),
                    Parent = frame,
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
                    LayoutOrder = #content:GetChildren() + 1,
                    Parent = content,
                })
                local lbl = create("TextLabel", {
                    Text = ((opts.Name or "") .. "\n" .. (opts.Desc or "")),
                    TextWrapped = true,
                    TextColor3 = DEFAULT.TextColor,
                    Font = DEFAULT.Font,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0,6,0,6),
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
                    LayoutOrder = #content:GetChildren() + 1,
                    Parent = content,
                })
                create("UICorner", {Parent = btn, CornerRadius = UDim.new(0,6)})
                btn.MouseButton1Click:Connect(function()
                    safePcall(opts.Callback)
                end)
                return btn
            end

            -- Toggle
            function SectionAPI:AddToggle(opts)
                opts = opts or {}
                local container = create("Frame", {
                    Size = UDim2.new(1,0,0,38),
                    BackgroundTransparency = 1,
                    LayoutOrder = #content:GetChildren() + 1,
                    Parent = content,
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
                    Size = UDim2.new(0,46,0,25),
                    Position = UDim2.new(1,-52,0,6),
                    BackgroundColor3 = opts.Default and DEFAULT.AccentColor or Color3.fromRGB(70,70,70),
                    Parent = container,
                })
                create("UICorner", {Parent = tog, CornerRadius = UDim.new(0,6)})
                local state = opts.Default or false
                tog.MouseButton1Click:Connect(function()
                    if opts.Locked then return end
                    state = not state
                    tog.BackgroundColor3 = state and DEFAULT.AccentColor or Color3.fromRGB(70,70,70)
                    safePcall(opts.Callback, state)
                end)
                if opts.Locked then
                    tog.Active = false
                    tog.AutoButtonColor = false
                    tog.BackgroundColor3 = Color3.fromRGB(100,100,100)
                end
                safePcall(opts.Callback, state)
                return tog
            end

            -- Dropdown
            function SectionAPI:AddDropdown(opts)
                opts = opts or {}
                local container = create("Frame", {
                    Size = UDim2.new(1,0,0,40),
                    BackgroundTransparency = 1,
                    LayoutOrder = #content:GetChildren() + 1,
                    Parent = content,
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

                local currentSelection = opts.Default or (opts.Options and opts.Options[1]) or "Select"
                local btn = create("TextButton", {
                    Text = currentSelection,
                    Size = UDim2.new(0.37,0,0,28),
                    Position = UDim2.new(1,-0.37,0,6),
                    BackgroundColor3 = Color3.fromRGB(45,45,50),
                    TextColor3 = DEFAULT.TextColor,
                    Font = DEFAULT.Font,
                    TextSize = 14,
                    Parent = container,
                })
                create("UICorner", {Parent = btn, CornerRadius = UDim.new(0,6)})

                local listFrame = create("Frame", {
                    Size = UDim2.new(0.37,0,0,0),
                    Position = UDim2.new(1,-0.37,0,38),
                    BackgroundColor3 = Color3.fromRGB(40,40,45),
                    Parent = container,
                    ClipsDescendants = true,
                })
                create("UICorner", {Parent = listFrame, CornerRadius = UDim.new(0,6)})

                local listLayout = create("UIListLayout", {Parent = listFrame})
                listLayout.Padding = UDim.new(0,4)

                local open = false

                local function rebuild()
                    clearChildren(listFrame)
                    for i,opt in ipairs(opts.Options or {}) do
                        local optBtn = create("TextButton", {
                            Text = tostring(opt),
                            Size = UDim2.new(1, -8, 0, 28),
                            BackgroundTransparency = 1,
                            TextColor3 = DEFAULT.TextColor,
                            Font = DEFAULT.Font,
                            TextSize = 14,
                            Parent = listFrame,
                            LayoutOrder = i,
                        })
                        optBtn.MouseButton1Click:Connect(function()
                            btn.Text = tostring(opt)
                            open = false
                            listFrame:TweenSize(UDim2.new(0.37,0,0,0),"Out","Quad",0.18,true)
                            safePcall(opts.Callback, tostring(opt))
                        end)
                    end
                end

                btn.MouseButton1Click:Connect(function()
                    open = not open
                    if open then
                        rebuild()
                        listFrame:TweenSize(UDim2.new(0.37, 0, 0, (#(opts.Options or {}) * 30)), "Out", "Quad", 0.18, true)
                    else
                        listFrame:TweenSize(UDim2.new(0.37, 0, 0, 0), "Out", "Quad", 0.18, true)
                    end
                end)

                rebuild()
                return btn
            end

            -- ColorPicker
            function SectionAPI:AddColorPicker(opts)
                opts = opts or {}
                local container = create("Frame", {
                    Size = UDim2.new(1,0,0,38),
                    BackgroundTransparency = 1,
                    LayoutOrder = #content:GetChildren() + 1,
                    Parent = content,
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

                local defaultColor = opts.DefaultColor or Color3.fromRGB(96,165,250)
                local box = create("TextButton", {
                    Size = UDim2.new(0, 28, 0, 28),
                    Position = UDim2.new(1, -32, 0, 5),
                    BackgroundColor3 = defaultColor,
                    Parent = container,
                })
                create("UICorner", {Parent = box, CornerRadius = UDim.new(0,6)})

                local picker = create("Frame", {
                    Size = UDim2.new(0,160, 0, 96),
                    Position = UDim2.new(1,-160,0,38),
                    BackgroundColor3 = Color3.fromRGB(40,40,45),
                    Parent = container,
                    Visible = false,
                })
                create("UICorner", {Parent = picker, CornerRadius = UDim.new(0,6)})

                local hueBar = create("Frame", {
                    Size = UDim2.new(0.15,0,1,0),
                    Position = UDim2.new(0,8,0,8),
                    BackgroundColor3 = Color3.fromRGB(230,0,0),
                    Parent = picker,
                })

                local swatch = create("Frame", {
                    Size = UDim2.new(1,-32,1,-16),
                    Position = UDim2.new(0.18,8,0,8),
                    BackgroundColor3 = defaultColor,
                    Parent = picker,
                })
                create("UICorner", {Parent = swatch, CornerRadius = UDim.new(0,6)})

                local open = false
                box.MouseButton1Click:Connect(function()
                    open = not open
                    picker.Visible = open
                end)

                hueBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local moveConn
                        local upConn
                        local function updateColor(pos)
                            local rel = math.clamp((pos.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
                            local c = Color3.fromHSV(rel, 0.8, 0.9)
                            swatch.BackgroundColor3 = c
                            box.BackgroundColor3 = c
                            safePcall(opts.Callback, c)
                        end

                        updateColor(input.Position)

                        moveConn = UserInputService.InputChanged:Connect(function(move)
                            if move.UserInputType == Enum.UserInputType.MouseMovement then
                                updateColor(move.Position)
                            end
                        end)

                        upConn = UserInputService.InputEnded:Connect(function(endInput)
                            if endInput.UserInputType == Enum.UserInputType.MouseButton1 then
                                moveConn:Disconnect()
                                upConn:Disconnect()
                            end
                        end)
                    end
                end)

                safePcall(opts.Callback, defaultColor)
                return box
            end

            -- Bind
            function SectionAPI:AddBind(opts)
                opts = opts or {}
                local container = create("Frame", {
                    Size = UDim2.new(1,0,0,38),
                    BackgroundTransparency = 1,
                    LayoutOrder = #content:GetChildren() + 1,
                    Parent = content,
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
                        local keyName = input.KeyCode.Name
                        if opts.Avaibles and type(opts.Avaibles) == "table" then
                            local allowed = false
                            for _, v in ipairs(opts.Avaibles) do
                                if v == keyName then allowed = true break end
                            end
                            if not allowed then return end
                        end
                        btn.Text = keyName
                        listening = false
                        safePcall(opts.Callback, keyName)
                    elseif input.UserInputType == Enum.UserInputType.Keyboard then
                        if btn.Text ~= "None" and btn.Text ~= "..." and input.KeyCode.Name == btn.Text then
                            safePcall(opts.Callback, input.KeyCode.Name)
                        end
                    end
                end)

                return btn
            end

            -- Slider
            function SectionAPI:AddSlider(opts)
                opts = opts or {}

                local container = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 52),
                    BackgroundTransparency = 1,
                    LayoutOrder = #content:GetChildren() + 1,
                    Parent = content,
                })

                local lbl = create("TextLabel", {
                    Text = (opts.Name or "Slider") .. " (" .. tostring(opts.Default or opts.Min or 0) .. ")",
                    Size = UDim2.new(1, 0, 0, 18),
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
                    BackgroundColor3 = Color3.fromRGB(40, 40, 45),
                    Parent = container,
                })
                create("UICorner", {Parent = barBg, CornerRadius = UDim.new(0, 6)})

                local minVal = opts.Min or 0
                local maxVal = opts.Max or 100
                local defaultVal = opts.Default or minVal
                local increment = opts.Increment or 1

                local fillBar = create("Frame", {
                    Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0),
                    BackgroundColor3 = DEFAULT.AccentColor,
                    Parent = barBg,
                })
                create("UICorner", {Parent = fillBar, CornerRadius = UDim.new(0, 6)})

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
                        fillBar.Size = UDim2.new(ratio, 0, 1, 0)
                        local val = minVal + math.floor(((maxVal - minVal) * ratio) / increment + 0.5) * increment
                        val = math.clamp(val, minVal, maxVal)
                        lbl.Text = (opts.Name or "Slider") .. " (" .. tostring(val) .. ")"
                        safePcall(opts.Callback, val)
                    end
                end)

                safePcall(opts.Callback, defaultVal)
                return fillBar
            end

            -- Textbox
            function SectionAPI:AddTextbox(opts)
                opts = opts or {}
                local container = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 40),
                    BackgroundTransparency = 1,
                    LayoutOrder = #content:GetChildren() + 1,
                    Parent = content,
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
                    BackgroundColor3 = Color3.fromRGB(40, 40, 45),
                    TextColor3 = DEFAULT.TextColor,
                    Font = DEFAULT.Font,
                    TextSize = 14,
                    ClearTextOnFocus = false,
                    PlaceholderText = opts.Placeholder or "",
                    Parent = container,
                })
                create("UICorner", {Parent = box, CornerRadius = UDim.new(0, 6)})

                box.FocusLost:Connect(function(enterPressed)
                    if enterPressed then
                        safePcall(opts.Callback, box.Text)
                    end
                end)

                return box
            end

            return SectionAPI
        end

        table.insert(self._tabs, Tab)
        if #self._tabs == 1 then Tab:Activate() end
        return Tab
    end

    function Window:Destroy()
        if winObj.ScreenGui and winObj.ScreenGui.Parent then
            winObj.ScreenGui:Destroy()
        end
    end

    function Window:Notification(opts)
        opts = opts or {}
        local notif = create("Frame", {
            Size = UDim2.new(0, 280, 0, 80),
            Position = UDim2.new(0.5, -140, 0, 40),
            BackgroundColor3 = Color3.fromRGB(35, 35, 40),
            Parent = self._internal.ScreenGui,
            ZIndex = 50,
        })
        create("UICorner", {Parent = notif, CornerRadius = UDim.new(0, 8)})

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
                local tween = TweenService:Create(notif, TweenInfo.new(0.3), {
                    BackgroundTransparency = 1,
                    Position = notif.Position + UDim2.new(0, 0, -0.1, 0),
                })
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
