--[[
    SimpleMobileUI Library
    Version: 1.0.1
    Description: A compact and functional UI library for Roblox mobile exploits.
]]

local Library = {}
Library.Name = "SimpleMobileUI"
Library.Version = "1.0.1"
Library.Author = "AI & You"

--// Configuration
local Config = {
    WindowSize = UDim2.new(0, 280, 0, 350),
    MinimizedSize = UDim2.new(0, 280, 0, 35),
    HeaderHeight = 35,
    TabButtonContainerHeight = 30, -- Chiều cao khu vực chứa nút tab
    Padding = 5,
    ElementHeight = 25,
    AccentColor = Color3.fromRGB(0, 122, 204),
    BackgroundColor = Color3.fromRGB(30, 30, 30),
    HeaderColor = Color3.fromRGB(45, 45, 45),
    TextColor = Color3.fromRGB(220, 220, 220),
    ElementBackgroundColor = Color3.fromRGB(60, 60, 60),
    Font = Enum.Font.GothamSemibold,
    TextSize = 14,
}

--// Helper Functions
local function Create(instanceType)
    return function(properties)
        local obj = Instance.new(instanceType)
        for prop, value in pairs(properties) do
            obj[prop] = value
        end
        return obj
    end
end

local ScreenGui = Create("ScreenGui")
local Frame = Create("Frame")
local TextLabel = Create("TextLabel")
local TextButton = Create("TextButton")
local TextBox = Create("TextBox")
local ScrollingFrame = Create("ScrollingFrame")
local UIListLayout = Create("UIListLayout")
local UIPadding = Create("UIPadding")
local UICorner = Create("UICorner")
local UIStroke = Create("UIStroke")

local function MakeDraggable(guiObject, dragHandle)
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging and dragStart then
                local delta = input.Position - dragStart
                guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
end

--// Main Library Object
function Library:CreateWindow(title)
    local window = {}
    window.Tabs = {}
    window.Elements = {} -- Not directly used for elements, tabs hold their own elements
    window.CurrentTab = nil
    window.Minimized = false

    local sg = ScreenGui({
        Name = Library.Name .. "_ScreenGui",
        Parent = game:GetService("CoreGui"),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })

    window.Instance = Frame({
        Name = "MainWindow",
        Parent = sg,
        Size = Config.WindowSize,
        Position = UDim2.new(0.5, -Config.WindowSize.X.Offset / 2, 0.5, -Config.WindowSize.Y.Offset / 2),
        BackgroundColor3 = Config.BackgroundColor,
        BorderSizePixel = 0,
        Active = true,
        ClipsDescendants = true
    })
    UICorner({ CornerRadius = UDim.new(0, 6), Parent = window.Instance })
    UIStroke({ Color = Config.AccentColor, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = window.Instance })

    local header = Frame({
        Name = "Header",
        Parent = window.Instance,
        Size = UDim2.new(1, 0, 0, Config.HeaderHeight),
        BackgroundColor3 = Config.HeaderColor,
        BorderSizePixel = 0
    })

    local titleLabel = TextLabel({
        Name = "TitleLabel",
        Parent = header,
        Size = UDim2.new(1, -(Config.HeaderHeight - Config.Padding + 5), 1, 0),
        BackgroundTransparency = 1,
        Font = Config.Font,
        Text = title or "UI Library",
        TextColor3 = Config.TextColor,
        TextSize = Config.TextSize + 2,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 2
    })
    UIPadding({ PaddingLeft = UDim.new(0, 10), Parent = titleLabel })

    local minimizeButton = TextButton({
        Name = "MinimizeButton",
        Parent = header,
        Size = UDim2.new(0, Config.HeaderHeight - 10, 0, Config.HeaderHeight - 10),
        Position = UDim2.new(1, -(Config.HeaderHeight - 5) , 0.5, -(Config.HeaderHeight - 10)/2),
        BackgroundColor3 = Config.ElementBackgroundColor,
        Font = Config.Font,
        Text = "_",
        TextColor3 = Config.TextColor,
        TextSize = Config.TextSize + 4,
        ZIndex = 2
    })
    UICorner({ CornerRadius = UDim.new(0, 4), Parent = minimizeButton })

    local tabButtonsContainer = Frame({
        Name = "TabButtonsContainer",
        Parent = window.Instance,
        Size = UDim2.new(1, 0, 0, Config.TabButtonContainerHeight),
        Position = UDim2.new(0, 0, 0, Config.HeaderHeight),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 1
    })
    UIListLayout({
        Parent = tabButtonsContainer,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, Config.Padding)
    })
    UIPadding({
        Parent = tabButtonsContainer,
        PaddingLeft = UDim.new(0, Config.Padding),
        PaddingRight = UDim.new(0, Config.Padding),
    })

    local contentArea = Frame({
        Name = "ContentArea",
        Parent = window.Instance,
        Size = UDim2.new(1, -Config.Padding * 2, 1, -Config.HeaderHeight - Config.TabButtonContainerHeight - Config.Padding),
        Position = UDim2.new(0, Config.Padding, 0, Config.HeaderHeight + Config.TabButtonContainerHeight + Config.Padding / 2),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 1
    })

    MakeDraggable(window.Instance, header)

    minimizeButton.MouseButton1Click:Connect(function()
        window.Minimized = not window.Minimized
        if window.Minimized then
            minimizeButton.Text = "□"
            contentArea.Visible = false
            tabButtonsContainer.Visible = false
            window.Instance.Size = Config.MinimizedSize
            if window.Instance.AbsolutePosition.Y + Config.MinimizedSize.Y.Offset > sg.AbsoluteSize.Y then
                 window.Instance.Position = UDim2.new(window.Instance.Position.X.Scale, window.Instance.Position.X.Offset, 1, -Config.MinimizedSize.Y.Offset - 10)
            end
        else
            minimizeButton.Text = "_"
            contentArea.Visible = true
            tabButtonsContainer.Visible = true
            window.Instance.Size = Config.WindowSize
            if window.CurrentTab then window.CurrentTab.Container.Visible = true end
        end
    end)

    function window:CreateTab(tabName)
        local tab = {}
        tab.Name = tabName
        tab.ParentWindow = window
        tab.Elements = {}

        tab.Button = TextButton({
            Name = tabName .. "Button",
            Parent = tabButtonsContainer,
            Size = UDim2.new(0, 80, 0, Config.TabButtonContainerHeight - Config.Padding * 2),
            BackgroundColor3 = Config.ElementBackgroundColor,
            Font = Config.Font,
            Text = tabName,
            TextColor3 = Config.TextColor,
            TextSize = Config.TextSize,
            LayoutOrder = #window.Tabs + 1,
            ZIndex = 2
        })
        UICorner({ CornerRadius = UDim.new(0, 4), Parent = tab.Button })

        tab.Container = ScrollingFrame({
            Name = tabName .. "Content",
            Parent = contentArea,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
            CanvasSize = UDim2.new(0,0,0,0), -- UIListLayout will manage this
            ScrollBarThickness = 6,
            ScrollBarImageColor3 = Config.AccentColor,
            AutomaticCanvasSize = Enum.AutomaticSize.Y -- Crucial for automatic scrolling content size
        })
        UIListLayout({
            Parent = tab.Container,
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Stretch, -- Stretch elements to fill width
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, Config.Padding)
        })
        UIPadding({
            Parent = tab.Container,
            PaddingTop = UDim.new(0, Config.Padding),
            PaddingBottom = UDim.new(0, Config.Padding),
        })

        tab.Button.MouseButton1Click:Connect(function()
            if window.CurrentTab then
                window.CurrentTab.Container.Visible = false
                window.CurrentTab.Button.BackgroundColor3 = Config.ElementBackgroundColor
                window.CurrentTab.Button.TextColor3 = Config.TextColor
            end
            tab.Container.Visible = true
            tab.Button.BackgroundColor3 = Config.AccentColor
            tab.Button.TextColor3 = Config.BackgroundColor -- Example: Contrast color for selected tab button text
            window.CurrentTab = tab
        end)

        table.insert(window.Tabs, tab)
        if not window.CurrentTab then
            tab.Button:Invoke("MouseButton1Click") -- Simulate to select first tab
        end

        -- Element creation functions
        function tab:AddLabel(text)
            local label = TextLabel({
                Name = "Label", Parent = tab.Container,
                Size = UDim2.new(1, 0, 0, Config.ElementHeight), BackgroundTransparency = 1,
                Font = Config.Font, Text = text, TextColor3 = Config.TextColor, TextSize = Config.TextSize,
                TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = #tab.Elements + 1
            })
            table.insert(tab.Elements, label)
            return label
        end

        function tab:AddButton(text, callback)
            local button = TextButton({
                Name = "Button", Parent = tab.Container,
                Size = UDim2.new(1, 0, 0, Config.ElementHeight), BackgroundColor3 = Config.ElementBackgroundColor,
                Font = Config.Font, Text = text, TextColor3 = Config.TextColor, TextSize = Config.TextSize,
                LayoutOrder = #tab.Elements + 1
            })
            UICorner({ CornerRadius = UDim.new(0, 4), Parent = button })
            button.MouseButton1Click:Connect(callback or function() end)
            table.insert(tab.Elements, button)
            return button
        end

        function tab:AddToggle(text, defaultValue, callback)
            defaultValue = defaultValue or false
            local toggled = defaultValue
            local toggleFrame = Frame({
                Name = "ToggleFrame", Parent = tab.Container,
                Size = UDim2.new(1, 0, 0, Config.ElementHeight), BackgroundTransparency = 1,
                LayoutOrder = #tab.Elements + 1
            })
            local checkBox = TextButton({
                Name = "CheckBox", Parent = toggleFrame,
                Size = UDim2.new(0, Config.ElementHeight - 5, 0, Config.ElementHeight - 5),
                Position = UDim2.new(0,0,0.5, -(Config.ElementHeight-5)/2),
                BackgroundColor3 = Config.ElementBackgroundColor, Text = "", ZIndex = 2
            })
            UICorner({ CornerRadius = UDim.new(0, 4), Parent = checkBox })
            local checkMark = TextLabel({
                Name = "CheckMark", Parent = checkBox, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
                Font = Config.Font, Text = "✔", TextColor3 = Config.AccentColor, TextScaled = true, Visible = toggled, ZIndex = 3
            })
            local label = TextLabel({
                Name = "ToggleLabel", Parent = toggleFrame,
                Size = UDim2.new(1, -(Config.ElementHeight + Config.Padding), 1, 0),
                Position = UDim2.new(0, Config.ElementHeight + Config.Padding, 0, 0), BackgroundTransparency = 1,
                Font = Config.Font, Text = text, TextColor3 = Config.TextColor, TextSize = Config.TextSize,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            local function updateVisual() checkMark.Visible = toggled end
            updateVisual()
            checkBox.MouseButton1Click:Connect(function()
                toggled = not toggled
                updateVisual()
                if callback then coroutine.wrap(callback)(toggled) end
            end)
            table.insert(tab.Elements, toggleFrame)
            return { IsToggled = function() return toggled end, Set = function(val)
                toggled = val; updateVisual(); if callback then coroutine.wrap(callback)(toggled) end
            end}
        end

        function tab:AddSlider(text, min, max, defaultValue, callback, precise)
            defaultValue = defaultValue or min
            local value = defaultValue
            local sliderFrame = Frame({
                Name = "SliderFrame", Parent = tab.Container,
                Size = UDim2.new(1, 0, 0, Config.ElementHeight + 15), BackgroundTransparency = 1,
                LayoutOrder = #tab.Elements + 1
            })
            local label = TextLabel({
                Name = "SliderLabel", Parent = sliderFrame, Size = UDim2.new(0.65, -Config.Padding, 0, Config.ElementHeight),
                Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, Font = Config.Font, Text = text,
                TextColor3 = Config.TextColor, TextSize = Config.TextSize, TextXAlignment = Enum.TextXAlignment.Left
            })
            local valueLabel = TextLabel({
                Name = "ValueLabel", Parent = sliderFrame, Size = UDim2.new(0.35, 0, 0, Config.ElementHeight),
                Position = UDim2.new(0.65, Config.Padding, 0,0), BackgroundTransparency = 1, Font = Config.Font, Text = tostring(value),
                TextColor3 = Config.TextColor, TextSize = Config.TextSize, TextXAlignment = Enum.TextXAlignment.Right
            })
            local track = Frame({
                Name = "Track", Parent = sliderFrame, Size = UDim2.new(1, 0, 0, 5),
                Position = UDim2.new(0,0,0, Config.ElementHeight + 2), BackgroundColor3 = Config.ElementBackgroundColor, BorderSizePixel = 0
            })
            UICorner({ CornerRadius = UDim.new(0,3), Parent = track })
            local fill = Frame({
                Name = "Fill", Parent = track, Size = UDim2.new(math.max(0, (value - min) / math.max(1e-9, max - min)), 0, 1, 0), -- Avoid division by zero if min=max
                BackgroundColor3 = Config.AccentColor, BorderSizePixel = 0
            })
            UICorner({ CornerRadius = UDim.new(0,3), Parent = fill })
            local knob = TextButton({
                Name = "Knob", Parent = track, Size = UDim2.new(0, 12, 0, 12),
                Position = UDim2.new(fill.Size.X.Scale, -6, 0.5, -6), BackgroundColor3 = Config.AccentColor, Text = "", ZIndex = 2
            })
            UICorner({ CornerRadius = UDim.new(1,0), Parent = knob })
            local draggingSlider = false
            local function updateSliderVisual(currentVal, currentPercentage)
                fill.Size = UDim2.new(currentPercentage, 0, 1, 0)
                knob.Position = UDim2.new(currentPercentage, -knob.AbsoluteSize.X/2, 0.5, -knob.AbsoluteSize.Y/2)
                valueLabel.Text = tostring(currentVal)
            end
            local function calculateValue(inputPos)
                local relativeX = math.clamp(inputPos.X - track.AbsolutePosition.X, 0, track.AbsoluteSize.X)
                local percentage = relativeX / math.max(1, track.AbsoluteSize.X) -- Avoid division by zero if track size is 0
                local newValue = min + (max - min) * percentage
                if not precise then newValue = math.floor(newValue + 0.5)
                else newValue = tonumber(string.format("%.2f", newValue)) end
                return math.clamp(newValue, min, max), percentage
            end
            knob.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = true
                    local newV, newP = calculateValue(input.Position)
                    if value ~= newV then value = newV; if callback then coroutine.wrap(callback)(value) end end
                    updateSliderVisual(value, newP)
                end
            end)
            knob.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = false end
            end)
            game:GetService("UserInputService").InputChanged:Connect(function(input)
                if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local newV, newP = calculateValue(input.Position)
                    if value ~= newV then value = newV; if callback then coroutine.wrap(callback)(value) end end
                    updateSliderVisual(value, newP)
                end
            end)
             -- Initialize slider visual state
            local initialPercentage = math.max(0, (defaultValue - min) / math.max(1e-9, max - min))
            updateSliderVisual(defaultValue, initialPercentage)

            table.insert(tab.Elements, sliderFrame)
            return { GetValue = function() return value end, SetValue = function(newValue)
                newValue = math.clamp(newValue, min, max)
                if not precise then newValue = math.floor(newValue + 0.5)
                else newValue = tonumber(string.format("%.2f", newValue)) end
                value = newValue
                local percentage = math.max(0, (value - min) / math.max(1e-9, max - min))
                updateSliderVisual(value, percentage)
                if callback then coroutine.wrap(callback)(value) end
            end}
        end

        function tab:AddTextbox(placeholder, callbackOnEnter, callbackOnFocusLost)
            local textbox = TextBox({
                Name = "Textbox", Parent = tab.Container, Size = UDim2.new(1, 0, 0, Config.ElementHeight),
                BackgroundColor3 = Config.ElementBackgroundColor, Font = Config.Font, Text = "", PlaceholderText = placeholder or "Enter text...",
                PlaceholderColor3 = Color3.fromRGB(150,150,150), TextColor3 = Config.TextColor, TextSize = Config.TextSize,
                ClearTextOnFocus = false, LayoutOrder = #tab.Elements + 1, TextXAlignment = Enum.TextXAlignment.Left,
            })
            UIPadding({PaddingLeft = UDim.new(0,5), Parent = textbox})
            UICorner({ CornerRadius = UDim.new(0, 4), Parent = textbox })
            if callbackOnEnter then textbox.FocusLost:Connect(function(enterPressed) if enterPressed then coroutine.wrap(callbackOnEnter)(textbox.Text) end end) end
            if callbackOnFocusLost then textbox.FocusLost:Connect(function(enterPressed) if not enterPressed then coroutine.wrap(callbackOnFocusLost)(textbox.Text) end end) end
            table.insert(tab.Elements, textbox)
            return { GetText = function() return textbox.Text end, SetText = function(newText) textbox.Text = newText end, Instance = textbox }
        end
        
        function tab:AddDropdown(text, options, callback)
            options = options or {}
            local selectedOption = options[1] or "Select..."
            local isOpen = false

            -- This frame will contain the button and the options list. Its ZIndex will be raised when open.
            local dropdownWrapper = Frame({
                Name = "DropdownWrapper",
                Parent = tab.Container,
                Size = UDim2.new(1, 0, 0, Config.ElementHeight), -- Initial size
                BackgroundTransparency = 1,
                LayoutOrder = #tab.Elements + 1,
                ZIndex = 2 -- Default ZIndex
            })

            local mainButton = TextButton({
                Name = "MainButton", Parent = dropdownWrapper, Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Config.ElementBackgroundColor, Font = Config.Font, Text = text .. ": " .. selectedOption,
                TextColor3 = Config.TextColor, TextSize = Config.TextSize,
            })
            UICorner({ CornerRadius = UDim.new(0, 4), Parent = mainButton })
            
            local arrow = TextLabel({
                Name = "Arrow", Parent = mainButton, Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -20, 0, 0),
                BackgroundTransparency = 1, Font = Config.Font, Text = "▼", TextColor3 = Config.TextColor, TextSize = Config.TextSize - 2,
            })

            local optionsList = ScrollingFrame({
                Name = "OptionsList", Parent = dropdownWrapper, -- Parented to wrapper
                Size = UDim2.new(1, 0, 0, math.min(#options * (Config.ElementHeight + Config.Padding/2) + Config.Padding, 120)), -- Max height
                Position = UDim2.new(0, 0, 1, Config.Padding / 2), BackgroundColor3 = Config.ElementBackgroundColor,
                BorderSizePixel = 1, BorderColor3 = Config.AccentColor, Visible = false,
                CanvasSize = UDim2.new(0,0,0,0), ScrollBarThickness = 4, ClipsDescendants = true,
                ZIndex = 11, -- Higher ZIndex within the wrapper to be above mainButton if it ever overlaps (unlikely here)
                AutomaticCanvasSize = Enum.AutomaticSize.Y
            })
            UICorner({ CornerRadius = UDim.new(0, 4), Parent = optionsList })
            UIListLayout({ Parent = optionsList, Padding = UDim.new(0, Config.Padding / 2), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Stretch })
            UIPadding({ Parent = optionsList, Padding = UDim.new(0, Config.Padding / 2)})


            local clickOutsideConnection = nil
            local function closeDropdown()
                isOpen = false
                optionsList.Visible = false
                arrow.Text = "▼"
                dropdownWrapper.Size = UDim2.new(1, 0, 0, Config.ElementHeight) -- Reset size
                dropdownWrapper.ZIndex = 2 -- Reset ZIndex
                if clickOutsideConnection then
                    clickOutsideConnection:Disconnect()
                    clickOutsideConnection = nil
                end
            end

            local function openDropdown()
                isOpen = true
                optionsList.Visible = true
                arrow.Text = "▲"
                -- Adjust wrapper size to encompass the optionsList
                local listHeight = optionsList.AbsoluteSize.Y
                dropdownWrapper.Size = UDim2.new(1, 0, 0, Config.ElementHeight + Config.Padding/2 + listHeight)
                dropdownWrapper.ZIndex = 10 -- Bring to front

                -- Connect click outside logic ONLY when dropdown is open
                if clickOutsideConnection then clickOutsideConnection:Disconnect() end -- Should not happen but good practice
                clickOutsideConnection = game:GetService("UserInputService").InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        local mouseLocation = input.Position
                        -- Check if click is outside dropdownWrapper
                        local absPos = dropdownWrapper.AbsolutePosition
                        local absSize = dropdownWrapper.AbsoluteSize
                        if not (mouseLocation.X >= absPos.X and mouseLocation.X <= absPos.X + absSize.X and
                                mouseLocation.Y >= absPos.Y and mouseLocation.Y <= absPos.Y + absSize.Y) then
                            closeDropdown()
                        end
                    end
                end)
            end
            
            mainButton.MouseButton1Click:Connect(function()
                if isOpen then closeDropdown() else openDropdown() end
            end)

            for i, optionText in ipairs(options) do
                local optionButton = TextButton({
                    Name = "Option_" .. tostring(optionText), Parent = optionsList, Size = UDim2.new(1, 0, 0, Config.ElementHeight),
                    BackgroundColor3 = Config.ElementBackgroundColor, BackgroundTransparency = 0.2, Font = Config.Font,
                    Text = tostring(optionText), TextColor3 = Config.TextColor, TextSize = Config.TextSize, LayoutOrder = i
                })
                UICorner({ CornerRadius = UDim.new(0, 3), Parent = optionButton })
                optionButton.MouseEnter:Connect(function() optionButton.BackgroundTransparency = 0 end)
                optionButton.MouseLeave:Connect(function() optionButton.BackgroundTransparency = 0.2 end)
                optionButton.MouseButton1Click:Connect(function()
                    selectedOption = optionText
                    mainButton.Text = text .. ": " .. tostring(selectedOption)
                    closeDropdown()
                    if callback then coroutine.wrap(callback)(selectedOption) end
                end)
            end
            
            table.insert(tab.Elements, dropdownWrapper)
            return {
                GetSelected = function() return selectedOption end,
                SetSelected = function(optionToSet)
                    local found = false
                    for _, opt in ipairs(options) do
                        if opt == optionToSet then
                            selectedOption = opt; mainButton.Text = text .. ": " .. tostring(selectedOption); found = true; break
                        end
                    end
                    return found
                end,
                Instance = dropdownWrapper
            }
        end

        return tab
    end

    function window:Destroy()
        if sg and sg.Parent then sg:Destroy() end
        for k in pairs(window) do window[k] = nil end
        collectgarbage()
    end

    return window
end

--// Unload/Cleanup Previous UI (if any)
pcall(function()
    if game and game:GetService("CoreGui") then
        local oldGui = game:GetService("CoreGui"):FindFirstChild(Library.Name .. "_ScreenGui")
        if oldGui then oldGui:Destroy() end
    end
end)

return Library

--[[
-- ================= HOW TO USE =================
-- 1. Load the library:
-- local MyUI = loadstring(game:HttpGet("URL_TO_THIS_SCRIPT_RAW"))()

-- 2. Create a window:
local window = MyUI:CreateWindow("My Exploit Menu")

-- 3. Create tabs:
local mainTab = window:CreateTab("Main")
local visualsTab = window:CreateTab("Visuals")

-- 4. Add elements to tabs:
mainTab:AddLabel("Welcome!")
mainTab:AddButton("Cool Action", function() print("Action!") end)
local espToggle = mainTab:AddToggle("Enable ESP", false, function(state) print("ESP:", state) end)
local speedSlider = mainTab:AddSlider("Speed", 16, 100, 16, function(val) print("Speed:", val) end)
mainTab:AddTextbox("Enter Name", function(txt) print("Name:", txt) end)

local options = {"Red", "Green", "Blue"}
visualsTab:AddDropdown("Color", options, function(sel) print("Color:", sel) end)
visualsTab:AddButton("Destroy UI", function() window:Destroy() end)
]]
