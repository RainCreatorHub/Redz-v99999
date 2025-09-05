-- RZLike.lua - Biblioteca UI completa estilo RedZ
-- Janela 480x350, key system 250x250
-- Use como ModuleScript e require no seu LocalScript

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

local function isNumeric(value)
    return type(value) == "number" or (type(value) == "string" and tonumber(value) ~= nil)
end

local function lerpColor(c1, c2, a)
    return c1:lerp(c2, a)
end

local function safePcall(func, ...)
    local ok, res = pcall(func, ...)
    if not ok then warn("RZLike: Callback error:", res) end
    return ok, res
end

local function clearChildren(frame)
    for _, child in ipairs(frame:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
end

local function validateKey(keyList, key)
    if not keyList then return false end
    for _, v in ipairs(keyList) do
        if tostring(v) == tostring(key) then
            return true
        end
    end
    return false
end

local function isKeyAllowed(allowedList, key)
    if not allowedList then return true end
    for _, v in ipairs(allowedList) do
        if v == key then
            return true
        end
    end
    return false
end

-- Construção básica da janela principal
local function buildBaseWindow(options)
    options = options or {}

    local screenGui = create("ScreenGui", {
        Name = "RZ_Window_" .. (options.Title or "UI"),
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

    -- Title bar
    local titleBar = create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        Parent = main,
    })
    local titleLabel = create("TextLabel", {
        Name = "TitleLabel",
        Text = options.Title or "Window",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -60, 0, 22),
        TextColor3 = DEFAULT.TextColor,
        Font = DEFAULT.Font,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar,
    })
    local subLabel = create("TextLabel", {
        Name = "SubLabel",
        Text = options.SubTitle or "",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 24),
        Size = UDim2.new(1, -60, 0, 14),
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
    create("UICorner", {Parent = closeBtn, CornerRadius = UDim.new(0, 6)})

    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = not main.Visible
    end)

    if options.Icon then
        local icon = create("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 28, 0, 28),
            Position = UDim2.new(0, 8, 0, 5),
            BackgroundTransparency = 1,
            Parent = titleBar,
        })
        if isNumeric(options.Icon) then
            icon.Image = "rbxassetid://"..tostring(options.Icon)
        else
            icon.Image = tostring(options.Icon)
        end
    end

    -- Draggable window
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
    end

    --- Left bar for tabs ---
    local leftBar = create("Frame", {
        Name = "LeftBar",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 160, 1, 0),
        Parent = main,
    })
    local leftLayout = create("UIListLayout", {
        Parent = leftBar,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0,6),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    })

    --- Content pages ---
    local contentArea = create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -160, 1, 0),
        Position = UDim2.new(0, 160, 0, 0),
        BackgroundTransparency = 1,
        Parent = main,
    })
    local pagesFolder = create("Folder", {Name = "Pages", Parent = contentArea})

    -- Return refs for API
    return {
        ScreenGui = screenGui,
        Main = main,
        LeftBar = leftBar,
        Pages = pagesFolder,
        TitleLabel = titleLabel,
        SubLabel = subLabel,
        Options = options,
    }
end

function RZ:MakeWindow(options)
    options = options or {}
    local winObj = buildBaseWindow(options)
    local authenticated = not options.KeySystem

    local modal, keyCard, keyInput, statusLabel, getKeyButton

    if options.KeySystem then
        -- Modal key system (250x250)
        modal = create("Frame", {
            Name = "KeyModal",
            Size = UDim2.new(1,0,1,0),
            BackgroundColor3 = Color3.fromRGB(0,0,0),
            BackgroundTransparency = 0.5,
            Parent = winObj.ScreenGui,
        })
        keyCard = create("Frame", {
            Name = "KeyCard",
            Size = DEFAULT.KeySize,
            Position = DEFAULT.KeyPos,
            BackgroundColor3 = Color3.fromRGB(36,36,40),
            Parent = modal,
        })
        create("UICorner", {Parent = keyCard, CornerRadius = UDim.new(0,8)})

        local title = create("TextLabel", {
            Text = options.KeySettings and options.KeySettings.Title or "Chave Necessária",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -24, 0, 36),
            Position = UDim2.new(0, 12, 0, 8),
            TextColor3 = DEFAULT.TextColor,
            Font = DEFAULT.Font,
            TextSize = 18,
            Parent = keyCard,
        })
        local descLabel = create("TextLabel", {
            Text = options.KeySettings and options.KeySettings.Desc or "Insira a chave para continuar.",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -24, 0, 48),
            Position = UDim2.new(0, 12, 0, 44),
            TextColor3 = DEFAULT.TextColor,
            Font = DEFAULT.Font,
            TextSize = 14,
            TextWrapped = true,
            Parent = keyCard,
        })
        keyInput = create("TextBox", {
            Text = "",
            PlaceholderText = "Digite a chave aqui...",
            Size = UDim2.new(1, -24, 0, 36),
            Position = UDim2.new(0, 12, 0, 100),
            BackgroundColor3 = Color3.fromRGB(50,50,55),
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
            TextColor3 = Color3.new(1,1,1),
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
            local key = keyInput.Text
            if checkKey(key) then
                statusLabel.Text = "Chave válida, acessando..."
                authenticated = true
                TweenService:Create(modal, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
                wait(0.25)
                modal:Destroy()
            else
                statusLabel.Text = "Chave inválida."
            end
        end)

        -- Botão para buscar chave via URL se configurado
        if options.KeySettings and options.KeySettings.Url then
            getKeyButton = create("TextButton", {
                Text = "Obter chave",
                Size = UDim2.new(0, 100, 0, 30),
                Position = UDim2.new(1, -228, 1, -40),
                BackgroundColor3 = Color3.fromRGB(70,70,75),
                TextColor3 = DEFAULT.TextColor,
                Font = DEFAULT.Font,
                TextSize = 14,
                Parent = keyCard,
            })
            create("UICorner", {Parent = getKeyButton, CornerRadius = UDim.new(0, 6)})
            getKeyButton.MouseButton1Click:Connect(function()
                if not HttpService.HttpEnabled then
                    statusLabel.Text = "HttpService está desabilitado."
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
                    statusLabel.Text = "Chaves adicionadas com sucesso."
                else
                    statusLabel.Text = "Falha ao obter chaves."
                end
            end)
        end
    end

    -- O objeto janela com métodos expostos
    local Window = {}
    Window._internal = winObj
    Window._tabs = {}

    -- Cria uma aba/tab com propriedades (Name, Desc, Icon)
    function Window:MakeTab(tabOptions)
        tabOptions = tabOptions or {}

        -- Espera autenticação (se key system estiver ativado)
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
            Size = UDim2.new(1, -24, 0, 40),
            BackgroundColor3 = Color3.fromRGB(35,35,40),
            TextColor3 = DEFAULT.TextColor,
            Font = DEFAULT.Font,
            TextSize = 15,
            Parent = winObj.LeftBar,
        })
        create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 8)})
        if tabOptions.Desc then
            btn.ToolTip = tabOptions.Desc
        end
        if tabOptions.Icon then
            local icon = create("ImageLabel", {
                Size = UDim2.new(0, 20,0,20),
                Position = UDim2.new(0, 6,0,10),
                BackgroundTransparency = 1,
                Parent = btn,
            })
            if isNumeric(tabOptions.Icon) then
                icon.Image = "rbxassetid://"..tostring(tabOptions.Icon)
            else
                icon.Image = tostring(tabOptions.Icon)
            end
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Text = "   "..btn.Text
        end

        local page = create("ScrollingFrame", {
            Name = "Page_"..(tabOptions.Name or "Page"),
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ScrollBarThickness = 6,
            Parent = winObj.Pages,
            Visible = false,
            CanvasSize = UDim2.new(0,0,0,0),
        })
        local layout = create("UIListLayout", {Parent = page})
        layout.Padding = UDim.new(0, 10)
        layout.SortOrder = Enum.SortOrder.LayoutOrder

        -- Tab Object
        local Tab = {
            Name = tabOptions.Name,
            _btn = btn,
            _page = page,
            _layout = layout,
            _parentWindow = Window,
            _sections = {},
        }
        setmetatable(Tab, {__index = Tab})

        -- Método para ativar a aba e ocultar as outras
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

        -- Conectando evento click para ativar a aba
        btn.MouseButton1Click:Connect(function()
            Tab:Activate()
        end)

        -- Cria seção dentro da aba
        function Tab:AddSection(sectionOpts)
            sectionOpts = sectionOpts or {}
            local section = create("Frame", {
                Name = "Section_" .. (sectionOpts.Name or "Section"),
                Size = UDim2.new(1, -16, 0, 140),
                BackgroundColor3 = Color3.fromRGB(26,26,30),
                Parent = page,
                LayoutOrder = #page:GetChildren() + 1,
                BorderSizePixel = 0,
            })
            create("UICorner", {Parent = section, CornerRadius = UDim.new(0, 6)})

            local title = create("TextLabel", {
                Text = sectionOpts.Name or "Section",
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 8, 0, 6),
                Size = UDim2.new(1, -16, 0, 22),
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
                    Position = UDim2.new(0, 8, 0, 32),
                    Size = UDim2.new(1, -16, 0, 26),
                    TextWrapped = true,
                    Parent = section,
                })
            end

            local contentPosY = descLbl and 62 or 36
            local contentHeight = descLbl and -62 or -36
            local content = create("Frame", {
                Name = "Content",
                Position = UDim2.new(0, 8, 0, contentPosY),
                Size = UDim2.new(1, -16, 1, contentHeight),
                BackgroundTransparency = 1,
                Parent = section,
            })
            local contentLayout = create("UIListLayout", {Parent = content})
            contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
            contentLayout.Padding = UDim.new(0, 6)

            table.insert(self._sections, content)

            local Section = {}

            -- ==== Elementos ====

            function Section:AddLabel(opts)
                opts = opts or {}
                local frame = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 40),
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
                    Position = UDim2.new(0, 6, 0, 6),
                    Size = UDim2.new(1, -12, 1, -12),
                    Parent = frame,
                })
                if opts.Desc then
                    lbl.Text = (opts.Name or "") .. "\n" .. opts.Desc
                    lbl.TextWrapped = true
                end
                return frame
            end

            function Section:AddParagraph(opts)
                opts = opts or {}
                local frame = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 80),
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
                    Position = UDim2.new(0, 6, 0, 6),
                    Size = UDim2.new(1, -12, 1, -12),
                    Parent = frame,
                })
                return frame
            end

            function Section:AddButton(opts)
                opts = opts or {}
                local btn = create("TextButton", {
                    Text = opts.Name or "Button",
                    Size = UDim2.new(1, 0, 0, 36),
                    BackgroundColor3 = Color3.fromRGB(50,50,55),
                    TextColor3 = DEFAULT.TextColor,
                    Font = DEFAULT.Font,
                    TextSize = 15,
                    LayoutOrder = #content:GetChildren() + 1,
                    Parent = content,
                })
                create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 6)})
                btn.MouseButton1Click:Connect(function()
                    safePcall(opts.Callback)
                end)
                return btn
            end

            function Section:AddToggle(opts)
                opts = opts or {}
                local container = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 38),
                    BackgroundTransparency = 1,
                    LayoutOrder = #content:GetChildren() + 1,
                    Parent = content,
                })
                local lbl = create("TextLabel", {
                    Text = opts.Name or "Toggle",
                    Size = UDim2.new(0.7, 0, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
                    TextColor3 = DEFAULT.TextColor,
                    Font = DEFAULT.Font,
                    TextSize = 15,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Parent = container,
                })
                local toggleBtn = create("TextButton", {
                    Text = "",
                    Size = UDim2.new(0, 46, 0, 25),
                    Position = UDim2.new(1, -52, 0, 6),
                    BackgroundColor3 = opts.Default and DEFAULT.AccentColor or Color3.fromRGB(70, 70, 70),
                    Parent = container,
                })
                create("UICorner", {Parent = toggleBtn, CornerRadius = UDim.new(0, 6)})

                local state = opts.Default and true or false
                toggleBtn.MouseButton1Click:Connect(function()
                    if opts.Locked then return end
                    state = not state
                    toggleBtn.BackgroundColor3 = state and DEFAULT.AccentColor or Color3.fromRGB(70, 70, 70)
                    safePcall(opts.Callback, state)
                end)

                if opts.Locked then
                    toggleBtn.Active = false
                    toggleBtn.AutoButtonColor = false
                    toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                end

                safePcall(opts.Callback, state)
                return toggleBtn
            end

            function Section:AddDropdown(opts)
                opts = opts or {}
                local container = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 40),
                    BackgroundTransparency = 1,
                    LayoutOrder = #content:GetChildren() + 1,
                    Parent = content,
                })
                local label = create("TextLabel", {
                    Text = opts.Name or "Dropdown",
                    Size = UDim2.new(0.6, 0, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
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
                    Size = UDim2.new(0.37, 0, 0, 28),
                    Position = UDim2.new(1, -0.37, 0, 6),
                    BackgroundColor3 = Color3.fromRGB(45, 45, 50),
                    TextColor3 = DEFAULT.TextColor,
                    Font = DEFAULT.Font,
                    TextSize = 14,
                    Parent = container,
                })
                create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 6)})

                local optionsList = create("Frame", {
                    Size = UDim2.new(0.37, 0, 0, 0),
                    Position = UDim2.new(1, -0.37, 0, 38),
                    BackgroundColor3 = Color3.fromRGB(40, 40, 45),
                    Parent = container,
                    ClipsDescendants = true,
                })
                create("UICorner", {Parent = optionsList, CornerRadius = UDim.new(0, 6)})

                local listLayout = create("UIListLayout", {Parent = optionsList})
                listLayout.Padding = UDim.new(0, 4)

                local open = false

                local function rebuild()
                    clearChildren(optionsList)
                    for i, option in ipairs(opts.Options or {}) do
                        local optionBtn = create("TextButton", {
                            Text = tostring(option),
                            Size = UDim2.new(1, -8, 0, 28),
                            BackgroundTransparency = 1,
                            TextColor3 = DEFAULT.TextColor,
                            Font = DEFAULT.Font,
                            TextSize = 14,
                            Parent = optionsList,
                            LayoutOrder = i,
                        })
                        optionBtn.MouseButton1Click:Connect(function()
                            btn.Text = tostring(option)
                            open = false
                            optionsList:TweenSize(UDim2.new(0.37, 0, 0, 0), "Out", "Quad", 0.18, true)
                            safePcall(opts.Callback, tostring(option))
                        end)
                    end
                end

                btn.MouseButton1Click:Connect(function()
                    open = not open
                    if open then
                        optionsList:TweenSize(UDim2.new(0.37, 0, 0, (#(opts.Options or {}) * 30)), "Out", "Quad", 0.18, true)
                    else
                        optionsList:TweenSize(UDim2.new(0.37, 0, 0, 0), "Out", "Quad", 0.18, true)
                    end
                    if open then
                        rebuild()
                    end
                end)

                rebuild()
                return btn
            end

            function Section:AddColorPicker(opts)
                opts = opts or {}
                local container = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 38),
                    BackgroundTransparency = 1,
                    LayoutOrder = #content:GetChildren() + 1,
                    Parent = content,
                })
                local label = create("TextLabel", {
                    Text = opts.Name or "Color Picker",
                    Size = UDim2.new(0.6, 0, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
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
                create("UICorner", {Parent = box, CornerRadius = UDim.new(0, 6)})

                local picker = create("Frame", {
                    Size = UDim2.new(0, 160, 0, 96),
                    Position = UDim2.new(1, -160, 0, 38),
                    BackgroundColor3 = Color3.fromRGB(40, 40, 45),
                    Parent = container,
                    Visible = false,
                })
                create("UICorner", {Parent = picker, CornerRadius = UDim.new(0, 6)})

                local hueBar = create("Frame", {
                    Size = UDim2.new(0.15, 0, 1, 0),
                    Position = UDim2.new(0, 8, 0, 8),
                    BackgroundColor3 = Color3.fromRGB(230, 0, 0),
                    Parent = picker,
                })

                local swatch = create("Frame", {
                    Size = UDim2.new(1, -32, 1, -16),
                    Position = UDim2.new(0.18, 8, 0, 8),
                    BackgroundColor3 = defaultColor,
                    Parent = picker,
                })
                create("UICorner", {Parent = swatch, CornerRadius = UDim.new(0, 6)})

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

            function Section:AddBind(opts)
                opts = opts or {}
                local container = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 38),
                    BackgroundTransparency = 1,
                    LayoutOrder = #content:GetChildren() + 1,
                    Parent = content,
                })

                local label = create("TextLabel", {
                    Text = opts.Name or "Bind",
                    Size = UDim2.new(0.6, 0, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
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
                    BackgroundColor3 = Color3.fromRGB(45, 45, 50),
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
                        local keyName = input.KeyCode.Name
                        if opts.Avaibles and not isKeyAllowed(opts.Avaibles, keyName) then
                            -- tecla não permitida
                            return
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

            function Section:AddSlider(opts)
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

            function Section:AddTextbox(opts)
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

            return Section
        end

        table.insert(self._tabs, Tab)
        Tab:Activate()
        return Tab
    end

    -- Remove tudo (destroi a GUI)
    function Window:Destroy()
        if winObj.ScreenGui and winObj.ScreenGui.Parent then
            winObj.ScreenGui:Destroy()
        end
    end

    -- Função para criar notificações
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
