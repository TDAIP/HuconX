local InputService = game:GetService('UserInputService');
local TextService = game:GetService('TextService');
local CoreGui = game:GetService('CoreGui');
local Teams = game:GetService('Teams');
local Players = game:GetService('Players');
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService');
local RenderStepped = RunService.RenderStepped;
local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse();

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);

local ScreenGui = Instance.new('ScreenGui');
ProtectGui(ScreenGui);

ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
ScreenGui.DisplayOrder = 2147483647;
ScreenGui.Parent = CoreGui;

local Toggles = {};
local Options = {};

getgenv().Toggles = Toggles;
getgenv().Options = Options;

--- ADDED ---
local UserInputService = game:GetService("UserInputService") -- For mobile detection
local GuiService = game:GetService("GuiService")

local Library = {
    Registry = {};
    RegistryMap = {};

    HudRegistry = {};

    -- Theme Colors (can be expanded for light/dark themes)
    Themes = {
        Dark = {
            FontColor = Color3.fromRGB(235, 235, 235),
            MainColor = Color3.fromRGB(32, 34, 37),         -- Buttons, dropdowns, non-primary backgrounds
            BackgroundColor = Color3.fromRGB(24, 25, 28),   -- Main window background, groupbox background
            AccentColor = Color3.fromRGB(90, 130, 255),     -- Highlights, selections
            OutlineColor = Color3.fromRGB(60, 60, 65),      -- Borders for elements
            RiskColor = Color3.fromRGB(240, 70, 70),
            Black = Color3.new(0, 0, 0),
            SubtleOutlineColor = Color3.fromRGB(45, 45, 50), -- Softer outline for less emphasis
            SurfaceColor = Color3.fromRGB(40, 42, 45),       -- Alternative background, e.g., inner of textbox
        },
        Light = { -- Placeholder, can be defined later
            FontColor = Color3.fromRGB(20, 20, 20),
            MainColor = Color3.fromRGB(240, 240, 240),
            BackgroundColor = Color3.fromRGB(250, 250, 250),
            AccentColor = Color3.fromRGB(0, 122, 255),
            OutlineColor = Color3.fromRGB(200, 200, 200),
            RiskColor = Color3.fromRGB(220, 50, 50),
            Black = Color3.new(0,0,0),
            SubtleOutlineColor = Color3.fromRGB(220, 220, 220),
            SurfaceColor = Color3.fromRGB(230, 230, 230),
        }
    };
    CurrentTheme = "Dark"; -- Default theme

    -- Getter for current theme colors
    GetColor = function(colorName)
        return Library.Themes[Library.CurrentTheme][colorName] or Color3.new(1,0,1) -- Magenta for missing color
    end,

    -- Overwrite old direct color access with new theme system
    FontColor = function() return Library.GetColor('FontColor') end,
    MainColor = function() return Library.GetColor('MainColor') end,
    BackgroundColor = function() return Library.GetColor('BackgroundColor') end,
    AccentColor = function() return Library.GetColor('AccentColor') end,
    OutlineColor = function() return Library.GetColor('OutlineColor') end,
    RiskColor = function() return Library.GetColor('RiskColor') end,
    Black = function() return Library.GetColor('Black') end,
    SubtleOutlineColor = function() return Library.GetColor('SubtleOutlineColor') end,
    SurfaceColor = function() return Library.GetColor('SurfaceColor') end,


    Fonts = {
        Default = Enum.Font.GothamSemibold, -- CHANGED: Default font
        Code = Enum.Font.Code,
        UI = Enum.Font.SourceSans,
        Title = Enum.Font.GothamBold,
    };
    Font = function() return Library.Fonts.Default end, -- Default font selection

    OpenedFrames = {};
    DependencyBoxes = {};

    Signals = {};
    ScreenGui = ScreenGui;

    --- ADDED ---
    IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled,
    CornerRadius = 6, -- Default corner radius for elements
    ShadowTransparency = 0.7,
    ShadowThickness = 2,
};

--- MODIFIED: Use GetColor for rainbow ---
Library.AccentColorDark = function() return Library:GetDarkerColor(Library.GetColor('AccentColor')) end;


local RainbowStep = 0
local Hue = 0

table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
    RainbowStep = RainbowStep + Delta

    if RainbowStep >= (1 / 60) then
        RainbowStep = 0

        Hue = Hue + (1 / 400);

        if Hue > 1 then
            Hue = 0;
        end;

        Library.CurrentRainbowHue = Hue;
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1);

        -- If a color is set to be "Rainbow", update it here.
        -- This requires elements registered with a "Rainbow" property to be handled in UpdateColorsUsingRegistry
        if Library.IsUpdatingRainbow then -- Add a flag to control this update
            Library:UpdateColorsUsingRegistry("Rainbow");
        end
    end
end))

local function GetPlayersString()
    local PlayerList = Players:GetPlayers();
    local Names = {};
    for i = 1, #PlayerList do
        Names[i] = PlayerList[i].Name;
    end;
    table.sort(Names, function(str1, str2) return str1 < str2 end);
    return Names;
end;

local function GetTeamsString()
    local TeamList = Teams:GetTeams();
    local Names = {};
    for i = 1, #TeamList do
        Names[i] = TeamList[i].Name;
    end;
    table.sort(Names, function(str1, str2) return str1 < str2 end);
    return Names;
end;

function Library:SafeCallback(f, ...)
    if (not f) then
        return;
    end;

    if not Library.NotifyOnError then -- Consider enabling this by default or making it a config
        return f(...);
    end;

    local success, event = pcall(f, ...);

    if not success then
        local _, i = event:find(":%d+: ");
        if not i then
            return Library:Notify("Error: " .. tostring(event), 5, "RiskColor"); -- ADDED: Notify type
        end;
        return Library:Notify("Error: " .. event:sub(i + 1), 5, "RiskColor"); -- ADDED: Notify type
    end;
end;

function Library:AttemptSave()
    if Library.SaveManager then
        Library.SaveManager:Save();
    end;
end;

function Library:Create(Class, Properties)
    local _Instance = Class;
    if type(Class) == 'string' then
        _Instance = Instance.new(Class);
    end;
    for Property, Value in next, Properties or {} do -- Ensure Properties is not nil
        if type(Value) == 'function' and Property:match("Color") then -- For theme colors
             _Instance[Property] = Value()
        else
            _Instance[Property] = Value;
        end
    end;
    return _Instance;
end;

--- ADDED: Helper to add UICorner ---
function Library:ApplyCorner(inst, radius)
    Library:Create('UICorner', {
        CornerRadius = UDim.new(0, radius or Library.CornerRadius),
        Parent = inst
    });
end

--- ADDED: Helper to add UIStroke with theme support ---
function Library:ApplyStroke(inst, colorName, thickness)
    local stroke = Library:Create('UIStroke', {
        Color = Library.GetColor(colorName or 'OutlineColor'),
        Thickness = thickness or 1,
        LineJoinMode = Enum.LineJoinMode.Miter, -- Consider Round for softer look
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = inst
    })
    Library:AddToRegistry(stroke, { Color = colorName or 'OutlineColor' })
    return stroke
end


function Library:ApplyTextStroke(Inst)
    -- TextStroke is often heavy. Consider an option to disable globally or per-element.
    -- Or use a very subtle dark color instead of pure black for softer look.
    Inst.TextStrokeTransparency = 0.8; -- CHANGED: Make it less prominent
    Library:Create('UIStroke', {
        Color = Color3.new(0.1, 0.1, 0.1), -- CHANGED
        Thickness = 1,
        LineJoinMode = Enum.LineJoinMode.Round, -- CHANGED
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, -- Ensures it respects TextStrokeTransparency
        Parent = Inst;
    });
end;

function Library:CreateLabel(Properties, IsHud)
    local _Instance = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font = Library.Font(), -- Use theme font
        TextColor3 = Library.FontColor(), -- Use theme color
        TextSize = Library.IsMobile and 16 or 14, -- Slightly larger on mobile
        TextStrokeTransparency = 1, -- Will be handled by ApplyTextStroke if desired
    });

    -- Library:ApplyTextStroke(_Instance); -- Consider making this optional via Properties

    Library:AddToRegistry(_Instance, {
        TextColor3 = 'FontColor';
        Font = function() return Library.Font() end; -- To update font if theme changes
    }, IsHud);

    return Library:Create(_Instance, Properties); -- Apply custom properties
end;

function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true;
    local Dragging = false
    local DragInput = nil
    local DragStart = nil
    local StartPosition = nil

    Instance.InputBegan:Connect(function(Input)
        if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Dragging then
            local ObjPos = Vector2.new(
                Input.Position.X - Instance.AbsolutePosition.X,
                Input.Position.Y - Instance.AbsolutePosition.Y
            );

            if ObjPos.Y > (Cutoff or (Library.IsMobile and 60 or 40)) then -- Larger cutoff for mobile
                return;
            end;

            Dragging = true
            DragInput = Input
            DragStart = Input.Position
            StartPosition = Instance.Position

            local moveConn
            local upConn

            moveConn = UserInputService.InputChanged:Connect(function(input)
                if input == DragInput and Dragging then
                    local डेल्टा = input.Position - DragStart
                    Instance.Position = UDim2.new(
                        StartPosition.X.Scale, StartPosition.X.Offset + डेल्टा.X,
                        StartPosition.Y.Scale, StartPosition.Y.Offset + डेल्टा.Y
                    )
                end
            end)

            upConn = UserInputService.InputEnded:Connect(function(input)
                if input == DragInput then
                    Dragging = false
                    if moveConn then moveConn:Disconnect() end
                    if upConn then upConn:Disconnect() end
                end
            end)
            Library:GiveSignal(moveConn)
            Library:GiveSignal(upConn)
        end;
    end)
end;

function Library:AddToolTip(InfoStr, HoverInstance)
    if not InfoStr or InfoStr == "" then return end -- Do not create empty tooltips

    local padding = Vector2.new(8, 6) -- Increased padding
    local textSize = Library.IsMobile and 14 or 13
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font(), textSize);

    local Tooltip = Library:Create('Frame', {
        Name = "Tooltip",
        BackgroundColor3 = Library.SurfaceColor(), -- CHANGED
        Size = UDim2.fromOffset(X + padding.X, Y + padding.Y),
        ZIndex = 2000, -- Ensure it's on top
        Parent = Library.ScreenGui,
        Visible = false,
        ClipsDescendants = true,
    })
    Library:ApplyCorner(Tooltip, 4)
    Library:ApplyStroke(Tooltip, 'OutlineColor', 1)


    local Label = Library:CreateLabel({
        Position = UDim2.fromScale(0.5, 0.5), -- Centered
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromScale(1, 1), -- Fill parent
        TextSize = textSize,
        Text = InfoStr,
        TextColor3 = Library.FontColor(),
        TextXAlignment = Enum.TextXAlignment.Center, -- CHANGED for potentially multi-line tooltips
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true, -- Important for multi-line
        ZIndex = Tooltip.ZIndex + 1,
        Parent = Tooltip,
    });
    -- No separate registry for Label color, it's part of the tooltip's theme.

    Library:AddToRegistry(Tooltip, {
        BackgroundColor3 = 'SurfaceColor';
    });
    -- Stroke is handled by ApplyStroke

    local IsHovering = false
    local TweenInfoShort = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() and HoverInstance ~= Library.CurrentHoveredWithTooltip then -- Allow tooltip if it's for an element inside an opened frame
            -- A more robust check might be needed if tooltips on elements within popups are desired
            return
        end
        Library.CurrentHoveredWithTooltip = HoverInstance

        IsHovering = true
        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 20) -- Slightly more offset
        Tooltip.Visible = true
        Tooltip.BackgroundTransparency = 1
        Label.TextTransparency = 1
        TweenService:Create(Tooltip, TweenInfoShort, {BackgroundTransparency = 0}):Play()
        TweenService:Create(Label, TweenInfoShort, {TextTransparency = 0}):Play()


        --[[
        -- Removed the while loop for performance, position update on mouse move is better
        while IsHovering and Tooltip.Visible and Tooltip.Parent do
            RunService.Heartbeat:Wait()
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 20)
        end
        --]]
    end)

    --- ADDED: Update tooltip position on mouse move for smoother experience ---
    local mouseMoveConn
    HoverInstance.MouseEnter:Connect(function()
        if not mouseMoveConn or not mouseMoveConn.Connected then
            mouseMoveConn = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    if IsHovering and Tooltip.Visible then
                        Tooltip.Position = UDim2.fromOffset(input.Position.X + 15, input.Position.Y + 20)
                    end
                end
            end)
            Library:GiveSignal(mouseMoveConn)
        end
    end)


    HoverInstance.MouseLeave:Connect(function()
        Library.CurrentHoveredWithTooltip = nil
        IsHovering = false
        -- Tween out
        local tween = TweenService:Create(Tooltip, TweenInfoShort, {BackgroundTransparency = 1})
        tween:Play()
        TweenService:Create(Label, TweenInfoShort, {TextTransparency = 1}):Play()
        tween.Completed:Connect(function()
            if not IsHovering then -- Ensure it wasn't re-hovered quickly
                Tooltip.Visible = false
            end
        end)
        -- No need to disconnect mouseMoveConn here, it's a general listener
    end)

    -- Cleanup when HoverInstance is destroyed
    Library:GiveSignal(HoverInstance.AncestryChanged:Connect(function(_, parent)
        if not parent and Tooltip and Tooltip.Parent then
            Tooltip:Destroy()
            -- if mouseMoveConn and mouseMoveConn.Connected then mouseMoveConn:Disconnect() end -- This might be too aggressive
        end
    end))
end


function Library:OnHighlight(HighlightInstance, InstanceToModify, PropertiesHover, PropertiesDefault)
    local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out) -- Softer tween

    HighlightInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() and HighlightInstance.Parent ~= Library.ScreenGui then return end -- Allow highlight on top-level frames like context menu
        local Reg = Library.RegistryMap[InstanceToModify];
        for Property, ColorNameOrVal in next, PropertiesHover do
            local targetColor = type(ColorNameOrVal) == 'string' and Library.GetColor(ColorNameOrVal) or ColorNameOrVal
            if InstanceToModify[Property] ~= targetColor then
                TweenService:Create(InstanceToModify, tweenInfo, {[Property] = targetColor}):Play()
            end
            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorNameOrVal; -- Update registry to reflect the "target" state
            end;
        end;
    end)

    HighlightInstance.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[InstanceToModify];
        for Property, ColorNameOrVal in next, PropertiesDefault do
            local targetColor = type(ColorNameOrVal) == 'string' and Library.GetColor(ColorNameOrVal) or ColorNameOrVal
             if InstanceToModify[Property] ~= targetColor then
                TweenService:Create(InstanceToModify, tweenInfo, {[Property] = targetColor}):Play()
            end
            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorNameOrVal;
            end;
        end;
    end)
end;

function Library:MouseIsOverOpenedFrame()
    for Frame, _ in next, Library.OpenedFrames do
        if Frame and Frame.Parent and Frame.Visible then -- Check if frame is valid
            local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
            if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
            and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then
                return true;
            end;
        end
    end;
    return false -- ADDED: Explicit false return
end;

function Library:IsMouseOverFrame(Frame)
    if Frame and Frame.Parent and Frame.Visible then -- Check if frame is valid
        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
        if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
            and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then
            return true;
        end;
    end
    return false -- ADDED: Explicit false return
end;

function Library:UpdateDependencyBoxes()
    for _, Depbox in next, Library.DependencyBoxes do
        if Depbox and typeof(Depbox.Update) == 'function' then -- Check if Depbox is valid
            Depbox:Update();
        end
    end;
end;

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    if MaxA - MinA == 0 then return MinB end -- Avoid division by zero
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB;
end;

function Library:GetTextBounds(Text, FontEnum, Size, Resolution)
    local PlainText = Text:gsub("<[^>]->", "") -- Strip RichText tags for accurate bounds
    local RenderResolution = Resolution or GuiService:GetGuiInset() + (typeof(workspace.CurrentCamera) == "Instance" and workspace.CurrentCamera.ViewportSize or Vector2.new(1920,1080))
    local Bounds = TextService:GetTextSize(PlainText, Size, FontEnum, RenderResolution)
    return Bounds.X, Bounds.Y
end

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color);
    return Color3.fromHSV(H, S * 0.95, V * 0.8); -- Slightly desaturate and darken
end;


function Library:AddToRegistry(Instance, Properties, IsHud)
    if Library.RegistryMap[Instance] then return end -- Already registered

    local Data = {
        Instance = Instance;
        Properties = Properties; -- Properties here should be names of colors in Library.Themes.Dark/Light or function
        IsHud = IsHud or false;
        -- ADDED: Store original properties for theme switching / rainbow
        OriginalProperties = {};
        IsRainbow = false;
    };

    for prop, colorName_Or_Func in pairs(Properties) do
        if type(colorName_Or_Func) == 'string' and string.lower(colorName_Or_Func) == "rainbow" then
            Data.IsRainbow = true
            Library.IsUpdatingRainbow = true -- Signal that rainbow updates are needed
            -- Store the actual color property that should be rainbow, e.g. "BackgroundColor3"
            Data.RainbowProperty = prop
            Data.OriginalProperties[prop] = Instance[prop] -- Store current color before rainbow
        elseif type(colorName_Or_Func) == 'function' then
             Data.OriginalProperties[prop] = Instance[prop] -- Store for reset if needed
        else
            Data.OriginalProperties[prop] = Instance[prop]
        end
    end

    table.insert(Library.Registry, Data);
    Library.RegistryMap[Instance] = Data;

    if IsHud then
        table.insert(Library.HudRegistry, Data);
    end;

    -- Apply initial theme colors
    self:UpdateInstanceColors(Data)
end;

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance];
    if Data then
        for i = #Library.Registry, 1, -1 do
            if Library.Registry[i] == Data then
                table.remove(Library.Registry, i);
                break; -- Found and removed
            end;
        end;
        if Data.IsHud then
            for i = #Library.HudRegistry, 1, -1 do
                if Library.HudRegistry[i] == Data then
                    table.remove(Library.HudRegistry, i);
                    break;
                end;
            end;
        end
        Library.RegistryMap[Instance] = nil;
    end;
end;

--- ADDED: Update a single registered instance's colors (e.g., on theme change or hover)
function Library:UpdateInstanceColors(ObjectData)
    local instance = ObjectData.Instance
    if not instance or not instance.Parent then -- Check if instance is destroyed
        self:RemoveFromRegistry(instance)
        return
    end

    if ObjectData.IsRainbow and ObjectData.RainbowProperty then
        instance[ObjectData.RainbowProperty] = Library.CurrentRainbowColor or Library.GetColor('AccentColor')
        -- Do not process other properties if it's rainbow for that specific prop
        -- If other props need themed colors, they should be handled carefully
    else
        for Property, ColorNameOrFunc in next, ObjectData.Properties do
            if type(ColorNameOrFunc) == 'string' then
                if string.lower(ColorNameOrFunc) == "rainbow" then
                    -- This case should be handled by the IsRainbow flag above
                    -- but as a fallback, apply current rainbow color
                    instance[Property] = Library.CurrentRainbowColor or Library.GetColor('AccentColor')
                else
                    instance[Property] = Library.GetColor(ColorNameOrFunc);
                end
            elseif type(ColorNameOrFunc) == 'function' then
                instance[Property] = ColorNameOrFunc() -- e.g. Library.FontColor()
            end
        end;
    end
end


--- MODIFIED: UpdateColorsUsingRegistry now can target specific update types ---
function Library:UpdateColorsUsingRegistry(updateType)
    -- updateType can be "All", "Rainbow", or a specific theme name
    local themeChanged = updateType and updateType ~= "Rainbow" and updateType ~= "All"

    for Idx = #Library.Registry, 1, -1 do -- Iterate backwards for safe removal
        local ObjectData = Library.Registry[Idx]
        if not ObjectData.Instance or not ObjectData.Instance.Parent then
            self:RemoveFromRegistry(ObjectData.Instance) -- Auto-cleanup destroyed instances
            continue
        end

        if updateType == "Rainbow" then
            if ObjectData.IsRainbow and ObjectData.RainbowProperty then
                 ObjectData.Instance[ObjectData.RainbowProperty] = Library.CurrentRainbowColor or Library.GetColor('AccentColor')
            end
        else -- "All" or theme change
            self:UpdateInstanceColors(ObjectData)
        end
    end;
end;

--- ADDED: Function to change theme ---
function Library:SetTheme(themeName)
    if Library.Themes[themeName] then
        Library.CurrentTheme = themeName;
        -- Update all registered UI elements to the new theme colors
        Library:UpdateColorsUsingRegistry(themeName);
        -- Update AccentColorDark as it depends on AccentColor
        -- Library.AccentColorDark = Library:GetDarkerColor(Library.GetColor('AccentColor'));
        -- This is now a function, so it will update automatically.

        -- Fire an event if scripts need to react to theme changes
        if Library.OnThemeChanged then
            Library.OnThemeChanged(themeName)
        end
    else
        warn("Theme not found:", themeName)
    end
end


function Library:GiveSignal(Signal)
    if Signal and typeof(Signal) == "RBXScriptConnection" then -- Basic check
        table.insert(Library.Signals, Signal)
    end
end

function Library:Unload()
    if Library.Unloading then return end
    Library.Unloading = true

    for Idx = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Idx)
        if Connection and Connection.Connected then -- Check if connected before disconnecting
            Connection:Disconnect()
        end
    end
    Library.Signals = {} -- Clear the table

    if Library.OnUnload then
        Library.OnUnload()
    end

    if ScreenGui and ScreenGui.Parent then -- Check before destroying
        ScreenGui:Destroy()
    end
    ScreenGui = nil -- Help GC

    -- Clear registries
    Library.Registry = {}
    Library.RegistryMap = {}
    Library.HudRegistry = {}
    Library.OpenedFrames = {}
    Library.DependencyBoxes = {}

    getgenv().Library = nil -- Allow GC of the library itself if no other strong refs
    getgenv().Toggles = nil
    getgenv().Options = nil
    print("UI Library Unloaded.")
end

function Library:OnUnload(Callback)
    Library.OnUnload = Callback
end

if ScreenGui then -- Check if ScreenGui exists (it should)
    Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
        if Library.RegistryMap[Instance] then
            Library:RemoveFromRegistry(Instance);
        end;
    end))
end

local BaseAddons = {};
do
    local Funcs = {};
    --[[
        ADDON COMPONENTS (ColorPicker, KeyPicker)
        These will need significant styling updates.
        For now, focus on the main window and primary elements.
        The structure is complex, so changes here will be iterative.
    --]]

    -- Placeholder for ColorPicker and KeyPicker redesign
    -- For now, ensure they use themed colors where possible.

    function Funcs:AddColorPicker(Idx, Info)
        local ParentObject = self -- Assuming self is a Toggle or Label that has TextLabel
        local AnchorElement = ParentObject and ParentObject.TextLabel

        assert(Info.Default, 'AddColorPicker: Missing default value.');
        assert(AnchorElement, "AddColorPicker: ParentObject.TextLabel is nil. Cannot anchor ColorPicker display.")

        local ColorPicker = {
            Value = Info.Default;
            Transparency = Info.Transparency or 0;
            Type = 'ColorPicker';
            Title = type(Info.Title) == 'string' and Info.Title or 'Color picker',
            Callback = Info.Callback or function(Color) end;
            OriginalAnchorSizeX = AnchorElement.Size.X.Offset, -- Store original size
        };

        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color);
            ColorPicker.Hue = H; ColorPicker.Sat = S; ColorPicker.Vib = V;
        end;
        ColorPicker:SetHSVFromRGB(ColorPicker.Value);

        local displayFrameSize = Library.IsMobile and 20 or 14
        local displayFrameTotalWidth = displayFrameSize + 8 -- size + padding

        -- Adjust anchor element size if it's a TextLabel part of a Toggle/Label with UIListLayout
        if AnchorElement and AnchorElement:FindFirstChildOfClass("UIListLayout") then
             -- AnchorElement.Size = UDim2.new(AnchorElement.Size.X.Scale, AnchorElement.Size.X.Offset - displayFrameTotalWidth, AnchorElement.Size.Y.Scale, AnchorElement.Size.Y.Offset)
        end


        local DisplayFrame = Library:Create('Frame', {
            Name = "ColorPickerDisplay",
            BackgroundColor3 = ColorPicker.Value,
            Size = UDim2.fromOffset(displayFrameSize, displayFrameSize),
            ZIndex = AnchorElement.ZIndex + 1,
            Parent = AnchorElement, -- Parent to the TextLabel of the toggle/label
        });
        Library:ApplyCorner(DisplayFrame, Library.CornerRadius / 2);
        Library:ApplyStroke(DisplayFrame, function() return Library:GetDarkerColor(ColorPicker.Value) end, 1); -- Dynamic border

        -- Make DisplayFrame's border update when color changes
        Library:AddToRegistry(DisplayFrame, {
             BorderColor3 = function() return Library:GetDarkerColor(ColorPicker.Value) end
        })


        local CheckerFrame = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.fromScale(1,1), -- Fill DisplayFrame
            ZIndex = DisplayFrame.ZIndex -1, -- Behind color, but above parent background
            Image = 'http://www.roblox.com/asset/?id=12977615774'; -- Checkerboard
            ImageTransparency = 0.3,
            ScaleType = Enum.ScaleType.Tile,
            TileSize = UDim2.fromOffset(6,6),
            Visible = not not Info.Transparency,
            Parent = DisplayFrame;
        });
        Library:ApplyCorner(CheckerFrame, Library.CornerRadius / 2);


        local pickerWidth = Library.IsMobile and 260 or 230
        local pickerHeight = Info.Transparency and (Library.IsMobile and 300 or 271) or (Library.IsMobile and 280 or 253)

        local PickerFrameOuter = Library:Create('Frame', {
            Name = 'ColorPickerPopup';
            BackgroundColor3 = Library.Black(), -- Shadow/border
            Position = UDim2.fromOffset(0,0), -- Will be updated
            Size = UDim2.fromOffset(pickerWidth, pickerHeight),
            Visible = false;
            ZIndex = 1000; -- High ZIndex for popup
            Parent = ScreenGui,
        });
        Library:ApplyCorner(PickerFrameOuter, Library.CornerRadius);

        DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            if PickerFrameOuter.Visible then -- Only update if visible
                local screenWidth = ScreenGui.AbsoluteSize.X
                local screenHeight = ScreenGui.AbsoluteSize.Y
                local xPos = DisplayFrame.AbsolutePosition.X
                local yPos = DisplayFrame.AbsolutePosition.Y + DisplayFrame.AbsoluteSize.Y + 5

                -- Adjust if going off-screen
                if xPos + pickerWidth > screenWidth then
                    xPos = screenWidth - pickerWidth - 5
                end
                if yPos + pickerHeight > screenHeight then
                    yPos = DisplayFrame.AbsolutePosition.Y - pickerHeight - 5
                end
                PickerFrameOuter.Position = UDim2.fromOffset(math.max(5, xPos), math.max(5, yPos));
            end
        end)
        ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() -- Also update on screen resize
             if PickerFrameOuter.Visible then
                DisplayFrame.AbsolutePosition = DisplayFrame.AbsolutePosition -- Trigger update
             end
        end)


        local PickerFrameInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor(),
            Size = UDim2.fromScale(1,1), -- Fill outer
            ZIndex = PickerFrameOuter.ZIndex + 1,
            Parent = PickerFrameOuter;
        });
        Library:ApplyCorner(PickerFrameInner, Library.CornerRadius); -- Apply to inner for seamless look
        Library:ApplyStroke(PickerFrameInner, 'OutlineColor');
        Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = 'BackgroundColor', BorderColor3 = 'OutlineColor' });


        local Highlight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor(),
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 3), -- Thicker highlight
            ZIndex = PickerFrameInner.ZIndex + 1,
            Parent = PickerFrameInner;
        });
        Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor' });
        -- No corner for top highlight bar, or very slight if desired

        local padding = 8
        local svMapSize = pickerWidth - (padding * 2) - 15 - (padding) -- width - L/R pad - huebar - pad
        svMapSize = math.min(svMapSize, pickerHeight - (padding*3) - 20 - (Info.Transparency and 20 or 0) - 3) -- height - T/B pad - title - hex/rgb - (transparency slider) - top highlight
        svMapSize = math.max(100, svMapSize) -- Minimum size

        local hueSelectorWidth = 15

        local SatVibMapOuter = Library:Create('Frame', {
            Position = UDim2.new(0, padding, 0, padding + 3 + 14 + padding/2), -- Below title
            Size = UDim2.fromOffset(svMapSize, svMapSize),
            ZIndex = PickerFrameInner.ZIndex + 1,
            Parent = PickerFrameInner;
        });
        Library:ApplyCorner(SatVibMapOuter);
        Library:ApplyStroke(SatVibMapOuter, 'SubtleOutlineColor'); -- Softer border

        local SatVibMapInner = Library:Create('Frame', { -- Used for BG color
            BackgroundColor3 = Library.BackgroundColor(),
            Size = UDim2.fromScale(1,1),
            ZIndex = SatVibMapOuter.ZIndex + 1,
            ClipsDescendants = true,
            Parent = SatVibMapOuter;
        });
        Library:ApplyCorner(SatVibMapInner); -- Match outer corner
        Library:AddToRegistry(SatVibMapInner, { BackgroundColor3 = 'BackgroundColor'});


        local SatVibMap = Library:Create('ImageLabel', { -- Color gradient
            Name = "SVMap",
            Size = UDim2.fromScale(1,1),
            ZIndex = SatVibMapInner.ZIndex + 1,
            Image = 'rbxassetid://4155801252', -- Saturation/Value gradient
            Parent = SatVibMapInner;
        });
        -- SatVibMap.BackgroundColor3 will be set to current Hue

        local CursorOuter = Library:Create('ImageLabel', {
            Name = "SVCursorOuter",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(10, 10), -- Larger cursor
            BackgroundTransparency = 1,
            Image = 'rbxassetid://9619665977', -- Circle image
            ImageColor3 = Library.Black(),
            ZIndex = SatVibMap.ZIndex + 2,
            Parent = SatVibMap;
        });

        local CursorInner = Library:Create('ImageLabel', {
            Name = "SVCursorInner",
            AnchorPoint = Vector2.new(0.5,0.5),
            Position = UDim2.fromScale(0.5,0.5),
            Size = UDim2.fromOffset(6, 6), -- Smaller inner circle
            BackgroundTransparency = 1,
            Image = 'rbxassetid://9619665977',
            ZIndex = CursorOuter.ZIndex + 1,
            Parent = CursorOuter;
        });
        -- CursorInner.ImageColor3 will be set dynamically


        local HueSelectorOuter = Library:Create('Frame', {
            Position = UDim2.new(0, SatVibMapOuter.Position.X.Offset + svMapSize + padding, 0, SatVibMapOuter.Position.Y.Offset),
            Size = UDim2.fromOffset(hueSelectorWidth, svMapSize),
            ZIndex = PickerFrameInner.ZIndex + 1,
            Parent = PickerFrameInner;
        });
        Library:ApplyCorner(HueSelectorOuter);
        Library:ApplyStroke(HueSelectorOuter, 'SubtleOutlineColor');

        local HueSelectorInner = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1,1,1), -- White background for gradient
            Size = UDim2.fromScale(1,1),
            ZIndex = HueSelectorOuter.ZIndex +1,
            ClipsDescendants = true,
            Parent = HueSelectorOuter;
        });
        Library:ApplyCorner(HueSelectorInner);

        local hueGradient = Instance.new("UIGradient")
        hueGradient.Rotation = 90
        local colors = {}
        for i = 0, 1, 0.05 do table.insert(colors, ColorSequenceKeypoint.new(i, Color3.fromHSV(i,1,1))) end
        hueGradient.Color = ColorSequence.new(colors)
        hueGradient.Parent = HueSelectorInner

        local HueCursor = Library:Create('Frame', {
            Name = "HueCursor",
            BackgroundColor3 = Library.FontColor(), -- Contrasting color
            AnchorPoint = Vector2.new(0.5, 0.5), -- Center on line
            BorderColor3 = Library.Black(),
            BorderSizePixel = 1,
            Size = UDim2.new(1, 4, 0, 3), -- Wider, thinner line, offset by 2 for border
            ZIndex = HueSelectorInner.ZIndex + 1,
            Parent = HueSelectorInner;
        });
        Library:ApplyCorner(HueCursor, 1);


        local inputHeight = 22
        local inputYPos = SatVibMapOuter.Position.Y.Offset + svMapSize + padding

        local HueBoxOuter = Library:Create('Frame', {
            Position = UDim2.new(0, padding, 0, inputYPos),
            Size = UDim2.new(0.5, -(padding/2 + 2), 0, inputHeight), -- Half width minus some padding
            ZIndex = PickerFrameInner.ZIndex + 1,
            Parent = PickerFrameInner;
        });
        Library:ApplyCorner(HueBoxOuter); Library:ApplyStroke(HueBoxOuter, 'SubtleOutlineColor');

        local HueBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.SurfaceColor(),
            Size = UDim2.fromScale(1,1), ZIndex = HueBoxOuter.ZIndex + 1, Parent = HueBoxOuter, ClipsDescendants = true,
        });
        Library:ApplyCorner(HueBoxInner); Library:AddToRegistry(HueBoxInner, { BackgroundColor3 = 'SurfaceColor' });

        local HueBox = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 5, 0, 0); Size = UDim2.new(1, -10, 1, 0);
            Font = Library.Fonts.Code, PlaceholderColor3 = Library.GetColor('FontColor'), PlaceholderText = 'HEX',
            Text = '', TextColor3 = Library.FontColor(), TextSize = 13, ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = HueBoxInner.ZIndex + 1, Parent = HueBoxInner;
        });
        Library:AddToRegistry(HueBox, { TextColor3 = 'FontColor', PlaceholderColor3 = 'FontColor' });


        local RgbBoxOuter = Library:Create(HueBoxOuter:Clone(), {
            Position = UDim2.new(0.5, padding/2 + 2, 0, inputYPos), -- Other half
            Parent = PickerFrameInner
        });
        local RgbBoxInner = Library:Create(HueBoxInner:Clone(), { Parent = RgbBoxOuter });
        local RgbBox = Library:Create(HueBox:Clone(), { PlaceholderText = 'R,G,B', Parent = RgbBoxInner });


        if Info.Transparency then
            inputYPos = inputYPos + inputHeight + padding/2
            local TransparencySliderOuter = Library:Create('Frame', {
                Name = "TransparencySlider",
                Position = UDim2.new(0, padding, 0, inputYPos),
                Size = UDim2.new(1, -padding*2, 0, 15),
                ZIndex = PickerFrameInner.ZIndex + 1, Parent = PickerFrameInner
            })
            Library:ApplyCorner(TransparencySliderOuter); Library:ApplyStroke(TransparencySliderOuter, 'SubtleOutlineColor');

            TransparencyBoxInner = Library:Create('Frame', {
                BackgroundColor3 = ColorPicker.Value, Size = UDim2.fromScale(1,1),
                ZIndex = TransparencySliderOuter.ZIndex + 1, Parent = TransparencySliderOuter, ClipsDescendants = true,
            });
            Library:ApplyCorner(TransparencyBoxInner);
            Library:AddToRegistry(TransparencyBoxInner, { BorderColor3 = 'OutlineColor' });

            Library:Create('ImageLabel', { -- Checkerboard for transparency slider
                BackgroundTransparency = 1; Size = UDim2.fromScale(1,1);
                Image = 'http://www.roblox.com/asset/?id=12978095818'; -- Alpha gradient
                ZIndex = TransparencyBoxInner.ZIndex + 1; Parent = TransparencyBoxInner;
            });

            TransparencyCursor = Library:Create('Frame', {
                BackgroundColor3 = Library.FontColor(), AnchorPoint = Vector2.new(0.5, 0.5),
                BorderColor3 = Library.Black(), BorderSizePixel = 1,
                Size = UDim2.new(0, 3, 1, 4), ZIndex = TransparencyBoxInner.ZIndex + 2, Parent = TransparencyBoxInner;
            });
            Library:ApplyCorner(TransparencyCursor, 1);
        end;


        local DisplayLabel = Library:CreateLabel({ -- Title of the color picker
            Size = UDim2.new(1, -padding*2, 0, 14), Position = UDim2.new(0, padding, 0, padding/2 + 3),
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
            TextSize = 14, Font = Library.Fonts.Title,
            Text = ColorPicker.Title, ZIndex = PickerFrameInner.ZIndex + 1, Parent = PickerFrameInner;
        });

        -- Context Menu (Simplified for now, can be expanded)
        local ContextMenu = {} -- Keep existing context menu logic, adjust styling later
        -- ... (ContextMenu implementation - will need styling pass) ...
        -- For now, ensure it uses themed colors for BackgroundColor3, BorderColor3, TextColor3

        -- Ensure all context menu elements use Library.GetColor and are registered
        -- Example: ContextMenu.Inner BackgroundColor3 = Library.BackgroundColor()
        -- And Library:AddToRegistry(ContextMenu.Inner, {BackgroundColor3 = 'BackgroundColor', ...})

        -- Functions (Display, OnChanged, Show, Hide, SetValue, etc.)
        function ColorPicker:Display()
            local newColor = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)
            local changed = (ColorPicker.Value ~= newColor or (Info.Transparency and DisplayFrame.BackgroundTransparency ~= ColorPicker.Transparency))
            ColorPicker.Value = newColor

            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1); -- Full saturation for SV map background
            CursorInner.ImageColor3 = ColorPicker.Value -- Or a contrasting color: Color3.fromHSV(0,0, ColorPicker.Vib < 0.5 and 1 or 0)
            CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0);
            HueCursor.Position = UDim2.fromOffset(HueSelectorInner.AbsoluteSize.X / 2, ColorPicker.Hue * svMapSize); -- Centered

            DisplayFrame.BackgroundColor3 = ColorPicker.Value;
            DisplayFrame.BackgroundTransparency = Info.Transparency and ColorPicker.Transparency or 0;
            -- DisplayFrame border is auto-updated via registry

            if TransparencyBoxInner then
                TransparencyBoxInner.BackgroundColor3 = ColorPicker.Value; -- So gradient shows correctly
                TransparencyCursor.Position = UDim2.fromScale(1 - ColorPicker.Transparency, 0.5);
            end;

            if not HueBox:IsFocused() then HueBox.Text = '#' .. ColorPicker.Value:ToHex() end
            if not RgbBox:IsFocused() then RgbBox.Text = string.format("%d,%d,%d", math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255)) end

            if changed then
                Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value, ColorPicker.Transparency);
                Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value, ColorPicker.Transparency);
            end
        end;
        ColorPicker.Display() -- Initial display

        function ColorPicker:OnChanged(Func) ColorPicker.Changed = Func; Func(ColorPicker.Value, ColorPicker.Transparency) end;

        function ColorPicker:Show()
            for Frame, _ in next, Library.OpenedFrames do -- Close other pickers/dropdowns
                if Frame and Frame.Parent and Frame.Name ~= PickerFrameOuter.Name and (Frame.Name == 'ColorPickerPopup' or Frame.Name == 'DropdownList') then
                    Frame.Visible = false; Library.OpenedFrames[Frame] = nil;
                end;
            end;
            PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + DisplayFrame.AbsoluteSize.Y + 5) -- Recalculate position
            DisplayFrame.ZOrder = DisplayFrame.ZOrder -- Trigger position update
            PickerFrameOuter.Visible = true;
            Library.OpenedFrames[PickerFrameOuter] = PickerFrameOuter; -- Use instance as value for easier check
            ColorPicker:Display() -- Refresh display when shown
        end;

        function ColorPicker:Hide() PickerFrameOuter.Visible = false; Library.OpenedFrames[PickerFrameOuter] = nil; end;
        
        function ColorPicker:SetValueRGB(color, transparency)
            ColorPicker:SetHSVFromRGB(color)
            if Info.Transparency and transparency ~= nil then ColorPicker.Transparency = transparency end
            ColorPicker:Display()
        end
        -- ... other SetValue functions ...

        -- Input Handlers for SVMap, HueSlider, TransparencySlider
        local function createDragHandler(target, onDrag, onRelease)
            local dragging = false
            target.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    onDrag(input.Position) -- Initial drag on click
                    local moveConn, endConn
                    moveConn = UserInputService.InputChanged:Connect(function(subInput)
                        if dragging and (subInput.UserInputType == Enum.UserInputType.MouseMovement or subInput.UserInputType == Enum.UserInputType.Touch) then
                           onDrag(subInput.Position)
                        end
                    end)
                    endConn = UserInputService.InputEnded:Connect(function(subInput)
                        if dragging and (subInput.UserInputType == Enum.UserInputType.MouseButton1 or subInput.UserInputType == Enum.UserInputType.Touch) then
                            dragging = false
                            moveConn:Disconnect()
                            endConn:Disconnect()
                            if onRelease then onRelease() end
                        end
                    end)
                    Library:GiveSignal(moveConn); Library:GiveSignal(endConn)
                end
            end)
        end

        createDragHandler(SatVibMap, function(mousePos)
            local relativePos = SatVibMap.AbsolutePosition
            local relativeSize = SatVibMap.AbsoluteSize
            local s = math.clamp((mousePos.X - relativePos.X) / relativeSize.X, 0, 1)
            local v = 1 - math.clamp((mousePos.Y - relativePos.Y) / relativeSize.Y, 0, 1)
            ColorPicker.Sat, ColorPicker.Vib = s, v
            ColorPicker:Display()
        end, Library.AttemptSave)

        createDragHandler(HueSelectorInner, function(mousePos)
            local relativePos = HueSelectorInner.AbsolutePosition
            local relativeSize = HueSelectorInner.AbsoluteSize
            ColorPicker.Hue = math.clamp((mousePos.Y - relativePos.Y) / relativeSize.Y, 0, 1)
            ColorPicker:Display()
        end, Library.AttemptSave)

        if Info.Transparency and TransparencyBoxInner then
            createDragHandler(TransparencyBoxInner, function(mousePos)
                local relativePos = TransparencyBoxInner.AbsolutePosition
                local relativeSize = TransparencyBoxInner.AbsoluteSize
                ColorPicker.Transparency = 1 - math.clamp((mousePos.X - relativePos.X) / relativeSize.X, 0, 1)
                ColorPicker:Display()
            end, Library.AttemptSave)
        end

        -- HEX/RGB Input
        HueBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local success, color = pcall(Color3.fromHex, HueBox.Text)
                if success then ColorPicker:SetValueRGB(color)
                else HueBox.Text = '#' .. ColorPicker.Value:ToHex() end -- Revert on bad input
            else HueBox.Text = '#' .. ColorPicker.Value:ToHex() end -- Revert if focus lost without enter
            Library:AttemptSave()
        end)
        RgbBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local r,g,b = RgbBox.Text:match("(%d+)[,%s]+(%d+)[,%s]+(%d+)")
                if r and g and b then ColorPicker:SetValueRGB(Color3.fromRGB(tonumber(r),tonumber(g),tonumber(b)))
                else RgbBox.Text = string.format("%d,%d,%d", math.floor(ColorPicker.Value.R*255), math.floor(ColorPicker.Value.G*255), math.floor(ColorPicker.Value.B*255)) end
            else RgbBox.Text = string.format("%d,%d,%d", math.floor(ColorPicker.Value.R*255), math.floor(ColorPicker.Value.G*255), math.floor(ColorPicker.Value.B*255)) end
            Library:AttemptSave()
        end)


        DisplayFrame.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                if PickerFrameOuter.Visible then ColorPicker:Hide()
                else
                    -- ContextMenu:Hide() -- Assuming ContextMenu exists and has Hide method
                    ColorPicker:Show()
                end;
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                -- ContextMenu:Show()
                ColorPicker:Hide()
            end
        end);

        -- Global click to hide picker
        Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and PickerFrameOuter.Visible then
                if not Library:IsMouseOverFrame(PickerFrameOuter) and not Library:IsMouseOverFrame(DisplayFrame) then
                    ColorPicker:Hide();
                end;
                -- Similar logic for ContextMenu
            end;
        end))

        ColorPicker.DisplayFrame = DisplayFrame
        Options[Idx] = ColorPicker;
        return self;
    end;

    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObject = self -- Assuming self is a Toggle or Label that has TextLabel
        local AnchorElement = ParentObject and ParentObject.TextLabel

        assert(Info.Default, 'AddKeyPicker: Missing default value.');
        assert(AnchorElement, "AddKeyPicker: ParentObject.TextLabel is nil. Cannot anchor KeyPicker display.")


        local KeyPicker = {
            Value = typeof(Info.Default) == "EnumItem" and Info.Default.Name or Info.Default, -- Store as string
            Toggled = false,
            Mode = Info.Mode or 'Toggle',
            Type = 'KeyPicker',
            Callback = Info.Callback or function() end,
            ChangedCallback = Info.ChangedCallback or function() end,
            SyncToggleState = Info.SyncToggleState or false,
            IsPickingKey = false,
        };
        if KeyPicker.SyncToggleState then Info.Modes = {'Toggle'}; KeyPicker.Mode = 'Toggle' end

        local keyDisplayWidth = Library.IsMobile and 60 or 40
        local keyDisplayHeight = Library.IsMobile and 20 or 15

        -- Adjust anchor element size
        if AnchorElement and AnchorElement:FindFirstChildOfClass("UIListLayout") then
            -- AnchorElement.Size = UDim2.new(AnchorElement.Size.X.Scale, AnchorElement.Size.X.Offset - (keyDisplayWidth + 4), AnchorElement.Size.Y.Scale, AnchorElement.Size.Y.Offset)
        end

        local PickOuter = Library:Create('Frame', { -- Clickable area
            Name = "KeyPickerDisplayOuter",
            BackgroundColor3 = Library.SurfaceColor(),
            Size = UDim2.fromOffset(keyDisplayWidth, keyDisplayHeight),
            ZIndex = AnchorElement.ZIndex + 1,
            Parent = AnchorElement,
        });
        Library:ApplyCorner(PickOuter, Library.CornerRadius / 2);
        Library:ApplyStroke(PickOuter, 'OutlineColor');
        Library:AddToRegistry(PickOuter, {BackgroundColor3 = 'SurfaceColor', BorderColor3 = 'OutlineColor'});

        local DisplayLabel = Library:CreateLabel({
            Name = "KeyPickerDisplayLabel",
            Size = UDim2.fromScale(1,1),
            TextSize = Library.IsMobile and 13 or 11,
            Font = Library.Fonts.Code,
            Text = KeyPicker.Value,
            TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = PickOuter.ZIndex + 1,
            Parent = PickOuter,
        });
        Library:OnHighlight(PickOuter, PickOuter, {BackgroundColor3 = 'AccentColor'}, {BackgroundColor3 = 'SurfaceColor'})


        local ModeSelectOuter = Library:Create('Frame', { -- Mode dropdown
            Name = "KeyPickerModeSelect",
            BackgroundColor3 = Library.BackgroundColor(),
            Size = UDim2.fromOffset(Library.IsMobile and 100 or 80, 0), -- Height based on content
            Visible = false,
            ZIndex = 1000, Parent = ScreenGui,
        });
        Library:ApplyCorner(ModeSelectOuter);
        Library:ApplyStroke(ModeSelectOuter, 'OutlineColor');
        Library:AddToRegistry(ModeSelectOuter, {BackgroundColor3 = 'BackgroundColor', BorderColor3 = 'OutlineColor'});
        local modeListLayout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0,2), Parent = ModeSelectOuter
        });
        Library:Create("UIPadding", {PaddingTop = UDim.new(0,2), PaddingBottom = UDim.new(0,2), Parent = ModeSelectOuter})


        local ContainerLabel = Library:CreateLabel({ -- For Keybinds list
            Name = "KeybindListLabel", TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 18), TextSize = 13,
            Visible = false, ZIndex = 110, Parent = Library.KeybindContainer;
        }, true); -- IsHud = true

        local Modes = Info.Modes or { 'Always', 'Toggle', 'Hold' };
        local ModeButtons = {};

        local function UpdateModeListSize()
            local numModes = #Modes
            local itemHeight = Library.IsMobile and 22 or 18
            ModeSelectOuter.Size = UDim2.fromOffset(ModeSelectOuter.Size.X.Offset, numModes * itemHeight + (numModes-1)*modeListLayout.Padding.Offset + 4)
        end

        for _, ModeName in ipairs(Modes) do
            local ModeButtonFrame = Library:Create("TextButton", {
                Name = ModeName .. "Button",
                Size = UDim2.new(1, -4, 0, Library.IsMobile and 20 or 16), LayoutOrder = #ModeButtons + 1,
                Position = UDim2.new(0,2,0,0), BackgroundTransparency = 1,
                Font = Library.Font(), Text = ModeName, TextSize = Library.IsMobile and 14 or 12,
                TextColor3 = Library.FontColor(), ZIndex = ModeSelectOuter.ZIndex + 1,
                Parent = ModeSelectOuter,
            })
            Library:ApplyCorner(ModeButtonFrame, 3)
            Library:AddToRegistry(ModeButtonFrame, {TextColor3 = 'FontColor'}) -- Register for theme changes

            ModeButtons[ModeName] = ModeButtonFrame

            ModeButtonFrame.MouseEnter:Connect(function() ModeButtonFrame.BackgroundTransparency = 0.8; ModeButtonFrame.BackgroundColor3 = Library.SurfaceColor() end)
            ModeButtonFrame.MouseLeave:Connect(function() ModeButtonFrame.BackgroundTransparency = 1 end)

            ModeButtonFrame.MouseButton1Click:Connect(function()
                KeyPicker.Mode = ModeName;
                for name, btn in pairs(ModeButtons) do
                    btn.TextColor3 = (name == ModeName) and Library.AccentColor() or Library.FontColor()
                    local reg = Library.RegistryMap[btn]
                    if reg then reg.Properties.TextColor3 = (name == ModeName) and 'AccentColor' or 'FontColor' end
                end
                ModeSelectOuter.Visible = false;
                Library:AttemptSave();
                KeyPicker:Update(); -- Update keybind list display
            end)

            if ModeName == KeyPicker.Mode then -- Select initial mode
                ModeButtonFrame.TextColor3 = Library.AccentColor()
                local reg = Library.RegistryMap[ModeButtonFrame]
                if reg then reg.Properties.TextColor3 = 'AccentColor' end
            end
        end
        UpdateModeListSize()


        function KeyPicker:Update() -- Updates the [Key] Name (Mode) display in keybind list
            if Info.NoUI then return end;
            local State = KeyPicker:GetState();
            ContainerLabel.Text = string.format('[%s] %s (%s)', KeyPicker.Value, Info.Text or "Unnamed Keybind", KeyPicker.Mode);
            ContainerLabel.Visible = true;
            ContainerLabel.TextColor3 = State and Library.AccentColor() or Library.FontColor();
            local reg = Library.RegistryMap[ContainerLabel]
            if reg then reg.Properties.TextColor3 = State and 'AccentColor' or 'FontColor' end;
            
            -- Resize KeybindFrame (this might be better handled by KeybindFrame itself observing its children)
            if Library.KeybindContainer and Library.KeybindFrame then
                 task.wait() -- Wait for layout to update
                 local ySize = Library.KeybindContainer.UIListLayout.AbsoluteContentSize.Y
                 local xSize = 0
                 for _, childLabel in ipairs(Library.KeybindContainer:GetChildren()) do
                     if childLabel:IsA("TextLabel") and childLabel.Visible then
                         xSize = math.max(xSize, childLabel.TextBounds.X + 10) -- Add padding
                     end
                 end
                 Library.KeybindFrame.Size = UDim2.new(0, math.max(xSize, Library.IsMobile and 180 or 210), 0, ySize + 23)
            end
        end;

        function KeyPicker:GetState()
            if KeyPicker.Mode == 'Always' then return true;
            elseif KeyPicker.Mode == 'Hold' then
                if KeyPicker.Value == 'None' or KeyPicker.Value == "" then return false; end
                if KeyPicker.Value == 'MB1' then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                elseif KeyPicker.Value == 'MB2' then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                else
                    local success, keyCodeEnum = pcall(function() return Enum.KeyCode[KeyPicker.Value] end)
                    return success and keyCodeEnum and UserInputService:IsKeyDown(keyCodeEnum) or false;
                end;
            else return KeyPicker.Toggled; end;
        end;

        function KeyPicker:SetValue(keyName, keyMode) -- Expects keyName as string, keyMode as string
            keyName = typeof(keyName) == "EnumItem" and keyName.Name or tostring(keyName)
            DisplayLabel.Text = keyName;
            KeyPicker.Value = keyName;
            if keyMode and ModeButtons[keyMode] then
                ModeButtons[keyMode].MouseButton1Click:Fire() -- Simulate click to select mode
            end
            KeyPicker:Update();
        end;
        function KeyPicker:OnClick(cb) KeyPicker.Clicked = cb end
        function KeyPicker:OnChanged(cb) KeyPicker.Changed = cb; if cb then cb(KeyPicker.Value) end end -- Fire immediately

        if ParentObject.Addons then table.insert(ParentObject.Addons, KeyPicker) end

        function KeyPicker:DoClick() -- When the keybind is activated
            if ParentObject.Type == 'Toggle' and KeyPicker.SyncToggleState then
                ParentObject:SetValue(not ParentObject.Value) -- Toggle the parent
            end
            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)
        end

        PickOuter.InputBegan:Connect(function(Input) -- Click on [KEY] display
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                if KeyPicker.IsPickingKey then return end
                KeyPicker.IsPickingKey = true;
                DisplayLabel.Text = '...';
                local oldTextColor = DisplayLabel.TextColor3
                DisplayLabel.TextColor3 = Library.RiskColor()

                local inputConn
                inputConn = UserInputService.InputBegan:Connect(function(keyInput)
                    if not KeyPicker.IsPickingKey then if inputConn then inputConn:Disconnect() end; return end
                    
                    local keyName = "None"
                    local keyValue = nil
                    if keyInput.UserInputType == Enum.UserInputType.Keyboard then
                        keyName = keyInput.KeyCode.Name; keyValue = keyInput.KeyCode;
                    elseif keyInput.UserInputType == Enum.UserInputType.MouseButton1 then
                        keyName = 'MB1'; keyValue = Enum.UserInputType.MouseButton1;
                    elseif keyInput.UserInputType == Enum.UserInputType.MouseButton2 then
                        keyName = 'MB2'; keyValue = Enum.UserInputType.MouseButton2;
                    end;

                    if keyName ~= "None" and keyInput.KeyCode ~= Enum.KeyCode.Unknown then -- Ignore unknown like focus loss
                        KeyPicker.IsPickingKey = false;
                        if inputConn then inputConn:Disconnect() end;

                        DisplayLabel.Text = keyName;
                        DisplayLabel.TextColor3 = oldTextColor
                        KeyPicker.Value = keyName;

                        Library:SafeCallback(KeyPicker.ChangedCallback, keyValue)
                        Library:SafeCallback(KeyPicker.Changed, KeyPicker.Value) -- Pass string name
                        Library:AttemptSave();
                        KeyPicker:Update()
                    end
                end);
                Library:GiveSignal(inputConn)
                -- Timeout for picking
                task.delay(5, function()
                    if KeyPicker.IsPickingKey then
                        KeyPicker.IsPickingKey = false
                        if inputConn and inputConn.Connected then inputConn:Disconnect() end
                        DisplayLabel.Text = KeyPicker.Value -- Revert to old key
                        DisplayLabel.TextColor3 = oldTextColor
                    end
                end)

            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then -- Right click for mode
                local absPos = PickOuter.AbsolutePosition
                local absSize = PickOuter.AbsoluteSize
                ModeSelectOuter.Position = UDim2.fromOffset(absPos.X + absSize.X + 5, absPos.Y)
                -- Adjust if off screen
                if ModeSelectOuter.Position.X.Offset + ModeSelectOuter.AbsoluteSize.X > ScreenGui.AbsoluteSize.X then
                    ModeSelectOuter.Position = UDim2.fromOffset(absPos.X - ModeSelectOuter.AbsoluteSize.X - 5, absPos.Y)
                end
                ModeSelectOuter.Visible = not ModeSelectOuter.Visible
                if ModeSelectOuter.Visible then Library.OpenedFrames[ModeSelectOuter] = ModeSelectOuter
                else Library.OpenedFrames[ModeSelectOuter] = nil end
            end;
        end);

        -- Global listener for key presses to activate keybinds
        Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input)
            if KeyPicker.IsPickingKey then return end;
            if KeyPicker.Mode == 'Toggle' then
                local activeKeyName = ""
                if Input.UserInputType == Enum.UserInputType.Keyboard then activeKeyName = Input.KeyCode.Name
                elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then activeKeyName = "MB1"
                elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then activeKeyName = "MB2"
                end
                if activeKeyName == KeyPicker.Value and KeyPicker.Value ~= "None" and KeyPicker.Value ~= "" then
                    KeyPicker.Toggled = not KeyPicker.Toggled;
                    KeyPicker:DoClick()
                end
            end;
            KeyPicker:Update(); -- Update visual state (e.g. for Hold mode if it was just pressed)
        end))
        Library:GiveSignal(UserInputService.InputEnded:Connect(function(Input) -- For Hold mode release
            if KeyPicker.IsPickingKey then return end;
            if KeyPicker.Mode == 'Hold' then KeyPicker:Update() end
        end))
        
        -- Hide ModeSelect when clicking elsewhere
        Library:GiveSignal(UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and ModeSelectOuter.Visible then
                if not Library:IsMouseOverFrame(ModeSelectOuter) and not Library:IsMouseOverFrame(PickOuter) then
                    ModeSelectOuter.Visible = false
                    Library.OpenedFrames[ModeSelectOuter] = nil
                end
            end
        end))

        KeyPicker:Update(); -- Initial update for keybind list
        Options[Idx] = KeyPicker;
        return self;
    end;


    BaseAddons.__index = Funcs;
    BaseAddons.__namecall = function(Self, Method, ...) -- Support : syntax
        local func = Funcs[Method]
        if func then
            return func(Self, ...)
        else
            error("Attempt to call nil method '" .. tostring(Method) .. "' on BaseAddons.")
        end
    end;
end;

local BaseGroupbox = {};
do
    local Funcs = {};
    --[[
        GROUPBOX AND COMPONENTS (Label, Button, Divider, Input, Toggle, Slider, Dropdown)
        These are the core of the UI content.
        Focus on applying UICorner, modernizing borders/backgrounds, and ensuring responsive sizes.
    --]]

    function Funcs:AddBlank(Size)
        local Groupbox = self;
        Library:Create('Frame', {
            Name = "BlankSpace", BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, Size); ZIndex = 1; Parent = Groupbox.Container;
        });
        return self -- Allow chaining
    end;

    function Funcs:AddLabel(Text, DoesWrap)
        local Label = { ParentGroupbox = self }; -- Store ref to parent groupbox
        local textLabelSize = Library.IsMobile and 15 or 14

        local TextLabel = Library:CreateLabel({
            Name = "InfoLabel",
            Size = UDim2.new(1, DoesWrap and -8 or -4, 0, textLabelSize + (DoesWrap and 2 or 0)), -- More space for wrapped
            TextSize = textLabelSize, Text = Text or "Label", TextWrapped = DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClipsDescendants = not DoesWrap, -- Only clip if not wrapping (for addons)
            ZIndex = 5; Parent = self.Container;
        });
        Library:ApplyCorner(TextLabel, 3) -- Subtle corner if it has addons

        if DoesWrap then
            TextLabel.TextYAlignment = Enum.TextYAlignment.Top -- Better for wrapped
            local function updateWrapHeight()
                local _, Y = Library:GetTextBounds(TextLabel.Text, TextLabel.Font, TextLabel.TextSize, Vector2.new(TextLabel.AbsoluteSize.X, math.huge))
                TextLabel.Size = UDim2.new(TextLabel.Size.X.Scale, TextLabel.Size.X.Offset, 0, math.max(textLabelSize, Y) + 2)
                self:Resize() -- Resize groupbox
            end
            TextLabel:GetPropertyChangedSignal("Text"):Connect(updateWrapHeight)
            TextLabel:GetPropertyChangedSignal("AbsoluteSize"):Once(updateWrapHeight) -- Initial size set
            task.spawn(updateWrapHeight)
        else
            Library:Create('UIListLayout', { -- For addons like color picker
                Padding = UDim.new(0, 4); FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right; VerticalAlignment = Enum.VerticalAlignment.Center;
                SortOrder = Enum.SortOrder.LayoutOrder; Parent = TextLabel;
            });
        end

        Label.TextLabel = TextLabel;
        Label.Container = self.Container; -- This is Groupbox.Container

        function Label:SetText(newText)
            TextLabel.Text = newText
            -- Height update for wrapped label is handled by its own listener
            if not DoesWrap then self.ParentGroupbox:Resize() end
        end

        if (not DoesWrap) then setmetatable(Label, BaseAddons) end;

        self:AddBlank(Library.IsMobile and 6 or 4); self:Resize();
        return Label;
    end;

    function Funcs:AddButton(...)
        local Button = { ParentGroupbox = self };
        -- ... (ProcessButtonParams remains the same) ...
        local function ProcessButtonParams(Class, Obj, ...)
            local Props = select(1, ...)
            if type(Props) == 'table' then
                Obj.Text = Props.Text or "Button"
                Obj.Func = Props.Func
                Obj.DoubleClick = Props.DoubleClick
                Obj.Tooltip = Props.Tooltip
                Obj.Icon = Props.Icon -- ADDED: Icon support
            else
                Obj.Text = select(1, ...) or "Button"
                Obj.Func = select(2, ...)
            end
            assert(type(Obj.Func) == 'function', 'AddButton: `Func` callback is missing or not a function. Text: ' .. Obj.Text);
        end
        ProcessButtonParams('Button', Button, ...)

        local buttonHeight = Library.IsMobile and 30 or 22

        local Outer = Library:Create('TextButton', { -- CHANGED to TextButton for better click handling
            Name = "ButtonOuter", AutoButtonColor = false, -- We handle visual states
            BackgroundColor3 = Library.MainColor(),
            Size = UDim2.new(1, -4, 0, buttonHeight), ZIndex = 5,
            Text = "", -- Text will be on an inner label for more control
            Parent = self.Container,
        });
        Library:ApplyCorner(Outer);
        Library:ApplyStroke(Outer, 'OutlineColor');
        Library:AddToRegistry(Outer, {BackgroundColor3 = 'MainColor', BorderColor3 = 'OutlineColor'});

        local Label = Library:CreateLabel({
            Name = "ButtonLabel",
            Size = UDim2.new(1, Button.Icon and -20 or 0, 1, 0), -- Make space for icon
            Position = UDim2.new(Button.Icon and 0.05 or 0, Button.Icon and 5 or 0, 0,0),
            TextSize = Library.IsMobile and 15 or 13, Font = Library.Fonts.UI,
            Text = Button.Text, ZIndex = Outer.ZIndex + 1, Parent = Outer;
        });
        -- Label's color is managed by TextColor3 of Outer if desired, or separately

        if Button.Icon then
            local IconImage = Library:Create("ImageLabel", {
                Name = "ButtonIcon", Size = UDim2.fromOffset(buttonHeight*0.6, buttonHeight*0.6),
                AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 5, 0.5, 0),
                BackgroundTransparency = 1, Image = Button.Icon,
                ImageColor3 = Library.FontColor(), -- Icon color matches font
                ZIndex = Outer.ZIndex + 1, Parent = Outer
            })
            Library:AddToRegistry(IconImage, {ImageColor3 = 'FontColor'})
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Position = UDim2.new(0, buttonHeight*0.6 + 10, 0, 0)
            Label.Size = UDim2.new(1, -(buttonHeight*0.6 + 15), 1, 0)
        end


        -- Hover/Press Effects
        local defaultColor = Library.MainColor()
        local hoverColor = Library.AccentColor()
        local pressColor = Library.AccentColorDark()

        Outer.MouseEnter:Connect(function() TweenService:Create(Outer, TweenInfo.new(0.1), {BackgroundColor3 = hoverColor}):Play() end)
        Outer.MouseLeave:Connect(function() TweenService:Create(Outer, TweenInfo.new(0.1), {BackgroundColor3 = defaultColor}):Play() end)
        Outer.MouseButton1Down:Connect(function() Outer.BackgroundColor3 = pressColor end)
        Outer.MouseButton1Up:Connect(function() Outer.BackgroundColor3 = Outer.MouseEnter and hoverColor or defaultColor end) -- Return to hover or default


        -- InitEvents (DoubleClick logic can be kept, simplified click)
        local lastClickTime = 0
        Outer.MouseButton1Click:Connect(function()
            if Library:MouseIsOverOpenedFrame() then return end -- Prevent clicks when a popup is open

            if Button.DoubleClick then
                if tick() - lastClickTime < 0.3 then -- Double click threshold
                    lastClickTime = 0 -- Reset
                    Library:SafeCallback(Button.Func)
                else
                    lastClickTime = tick()
                    -- TODO: Visual cue for "waiting for second click" or "are you sure?"
                    local originalText = Label.Text
                    Label.Text = "Confirm?"
                    local tempColor = Label.TextColor3
                    Label.TextColor3 = Library.RiskColor()
                    task.delay(1.5, function()
                        if Label and Label.Parent and Label.Text == "Confirm?" then -- Check if still relevant
                            Label.Text = originalText
                            Label.TextColor3 = tempColor
                        end
                    end)
                end
                return
            end
            Library:SafeCallback(Button.Func);
        end)


        Button.Outer = Outer; Button.Label = Label;
        Button.AddTooltip = function(selfBtn, tooltipText) if type(tooltipText) == 'string' then Library:AddToolTip(tooltipText, selfBtn.Outer) end return selfBtn end
        Button.AddButton = nil -- Remove AddButton for now, simplify or redesign later

        if type(Button.Tooltip) == 'string' then Button:AddTooltip(Button.Tooltip) end

        self:AddBlank(Library.IsMobile and 8 or 5); self:Resize();
        return Button;
    end;
    
    -- ... (AddDivider, AddInput, AddToggle, AddSlider, AddDropdown, AddDependencyBox will be updated iteratively) ...
    -- For now, ensure they use themed colors and UICorner where appropriate.
    -- Example for AddDivider:
    function Funcs:AddDivider()
        local Groupbox = self;
        self:AddBlank(Library.IsMobile and 6 or 3);
        local DividerLine = Library:Create('Frame', {
            Name = "Divider",
            BackgroundColor3 = Library.OutlineColor(),
            Size = UDim2.new(1, -8, 0, 1.5), -- Thinner, more subtle
            Position = UDim2.new(0,4,0,0),
            ZIndex = 5; Parent = Groupbox.Container;
        });
        Library:ApplyCorner(DividerLine, 1); -- Very slight roundness
        Library:AddToRegistry(DividerLine, { BackgroundColor3 = 'OutlineColor' });
        self:AddBlank(Library.IsMobile and 8 or 4); self:Resize();
        return self
    end;

    function Funcs:AddInput(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')
        local Textbox = { Value = Info.Default or '', Numeric = Info.Numeric or false, Finished = Info.Finished or false, Type = 'Input', Callback = Info.Callback or function() end };
        local Groupbox = self;

        local inputHeight = Library.IsMobile and 28 or 20
        local labelTextSize = Library.IsMobile and 14 or 12
        local boxTextSize = Library.IsMobile and 14 or 13

        if Info.Text and Info.Text ~= "" then -- Optional label
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, labelTextSize + 2), TextSize = labelTextSize,
                Text = Info.Text, TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Bottom, ZIndex = 5, Parent = Groupbox.Container;
            });
            Groupbox:AddBlank(1);
        end

        local TextBoxOuter = Library:Create('Frame', { -- Just for highlight and border
            Name = "InputOuter", BackgroundColor3 = Library.SurfaceColor(),
            Size = UDim2.new(1, -4, 0, inputHeight), ZIndex = 5, Parent = Groupbox.Container;
        });
        Library:ApplyCorner(TextBoxOuter);
        Library:ApplyStroke(TextBoxOuter, 'SubtleOutlineColor');
        Library:AddToRegistry(TextBoxOuter, {BackgroundColor3 = 'SurfaceColor', BorderColor3 = 'SubtleOutlineColor'});
        Library:OnHighlight(TextBoxOuter, TextBoxOuter, {BorderColor3 = 'AccentColor'}, {BorderColor3 = 'SubtleOutlineColor'});
        if type(Info.Tooltip) == 'string' then Library:AddToolTip(Info.Tooltip, TextBoxOuter) end

        local Box = Library:Create('TextBox', {
            Name = "InputBox", BackgroundTransparency = 1,
            Size = UDim2.new(1, -10, 1, -4), Position = UDim2.new(0,5,0,2), -- Padding inside outer
            Font = Library.Fonts.UI, PlaceholderColor3 = Library.GetColor('FontColor'),
            PlaceholderText = Info.Placeholder or '', Text = Info.Default or '',
            TextColor3 = Library.FontColor(), TextSize = boxTextSize, ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = TextBoxOuter.ZIndex + 1, Parent = TextBoxOuter;
        });
        Box.PlaceholderColor3 = Color3.new(Box.PlaceholderColor3.R, Box.PlaceholderColor3.G, Box.PlaceholderColor3.B, 0.6) -- Make placeholder less prominent
        Library:AddToRegistry(Box, {TextColor3 = 'FontColor', PlaceholderColor3 = function() local c = Library.GetColor('FontColor'); return Color3.new(c.R,c.G,c.B,0.6) end});
        -- ApplyTextStroke can be added if desired

        -- ... (Existing SetValue, FocusLost/TextChanged logic) ...
        -- Ensure Update function for scrolling text is still present and working
        -- The scrolling text logic (from nicemike40) is good, keep it.
        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then Text = Text:sub(1, Info.MaxLength) end;
            if Textbox.Numeric then
                if (not tonumber(Text)) and Text:len() > 0 and Text ~= "-" and Text ~= "." and not Text:match("^[-%d%.]+$") then Text = Textbox.Value end -- Allow partial numeric input
            end
            Textbox.Value = Text; Box.Text = Text;
            Library:SafeCallback(Textbox.Callback, Textbox.Value);
            Library:SafeCallback(Textbox.Changed, Textbox.Value);
        end;
        if Textbox.Finished then Box.FocusLost:Connect(function(enter) if enter then Textbox:SetValue(Box.Text); Library:AttemptSave() end end)
        else Box:GetPropertyChangedSignal('Text'):Connect(function() Textbox:SetValue(Box.Text); Library:AttemptSave() end) end;
        -- Text scrolling update function (keep existing)
        local function UpdateScroll()
            local PADDING = 2; local reveal = TextBoxOuter.AbsoluteSize.X - 10; -- Account for padding in Box
            if not Box:IsFocused() or Box.TextBounds.X <= reveal - 2 * PADDING then
                Box.TextXAlignment = Enum.TextXAlignment.Left
            else
                Box.TextXAlignment = Enum.TextXAlignment.Right -- Simpler scroll: just align right when overflowing
            end
        end
        task.spawn(UpdateScroll); Box:GetPropertyChangedSignal('Text'):Connect(UpdateScroll); Box:GetPropertyChangedSignal('CursorPosition'):Connect(UpdateScroll);
        Box.FocusLost:Connect(UpdateScroll); Box.Focused:Connect(UpdateScroll);


        function Textbox:OnChanged(Func) Textbox.Changed = Func; Func(Textbox.Value); end;
        Groupbox:AddBlank(Library.IsMobile and 8 or 5); Groupbox:Resize();
        Options[Idx] = Textbox;
        return Textbox;
    end;


    function Funcs:AddToggle(Idx, Info)
        assert(Info.Text, 'AddToggle: Missing `Text` string.')
        local toggleHeight = Library.IsMobile and 26 or 20
        local switchWidth = Library.IsMobile and 36 or 30
        local switchHeight = Library.IsMobile and 20 or 14
        local knobSize = switchHeight - (Library.IsMobile and 6 or 4)

        local Toggle = {
            Value = Info.Default or false, Type = 'Toggle',
            Callback = Info.Callback or function() end, Addons = {}, Risky = Info.Risky,
            ParentGroupbox = self,
        };

        local ToggleFrame = Library:Create('Frame', { -- Main container for label and switch
            Name = "ToggleFrame", BackgroundTransparency = 1,
            Size = UDim2.new(1, -4, 0, toggleHeight), ZIndex = 5, Parent = self.Container,
        });
        local listLayout = Library:Create('UIListLayout', { -- Layout for label and switch
            FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.SpaceBetween,
            Parent = ToggleFrame
        });

        local ToggleLabel = Library:CreateLabel({
            Name = "ToggleLabel",
            Size = UDim2.new(1, -(switchWidth + 10), 1, 0), -- Fill available space, leave room for switch + padding
            TextSize = Library.IsMobile and 15 or 14, Text = Info.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = ToggleFrame.ZIndex + 1, Parent = ToggleFrame,
            LayoutOrder = 1,
        });
        if Toggle.Risky then
            ToggleLabel.TextColor3 = Library.RiskColor()
            Library:AddToRegistry(ToggleLabel, {TextColor3 = 'RiskColor'})
        end
        -- For addons on the label (like color picker for the toggle text color itself)
        Library:Create('UIListLayout', { Padding = UDim.new(0,4), FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Parent = ToggleLabel})


        local SwitchTrack = Library:Create('Frame', { -- The switch track
            Name = "SwitchTrack",
            Size = UDim2.fromOffset(switchWidth, switchHeight), LayoutOrder = 2,
            BackgroundColor3 = Library.SurfaceColor(), ZIndex = ToggleFrame.ZIndex + 1, Parent = ToggleFrame,
        });
        Library:ApplyCorner(SwitchTrack, switchHeight / 2); -- Pill shape
        Library:ApplyStroke(SwitchTrack, 'SubtleOutlineColor');
        Library:AddToRegistry(SwitchTrack, {BackgroundColor3 = 'SurfaceColor', BorderColor3 = 'SubtleOutlineColor'});

        local SwitchKnob = Library:Create('Frame', { -- The switch knob
            Name = "SwitchKnob",
            Size = UDim2.fromOffset(knobSize, knobSize), AnchorPoint = Vector2.new(0.5,0.5),
            Position = UDim2.new(0, knobSize/2 + (switchHeight-knobSize)/2, 0.5, 0), -- Initial position (off)
            BackgroundColor3 = Library.FontColor(), ZIndex = SwitchTrack.ZIndex + 1, Parent = SwitchTrack,
        });
        Library:ApplyCorner(SwitchKnob, knobSize/2); -- Circular knob
        Library:ApplyStroke(SwitchKnob, 'OutlineColor', 0.5);
        Library:AddToRegistry(SwitchKnob, {BackgroundColor3 = 'FontColor', BorderColor3 = 'OutlineColor'});

        local ToggleRegion = Library:Create('TextButton', { -- Clickable region covering both
            Name = "ToggleClickRegion", BackgroundTransparency = 1, Text = "",
            Size = UDim2.fromScale(1,1), ZIndex = SwitchTrack.ZIndex + 2, Parent = ToggleFrame,
        });

        function Toggle:Display()
            local targetKnobPos = Toggle.Value and UDim2.new(1, -(knobSize/2 + (switchHeight-knobSize)/2), 0.5, 0) or UDim2.new(0, knobSize/2 + (switchHeight-knobSize)/2, 0.5, 0)
            local targetTrackColor = Toggle.Value and Library.AccentColor() or Library.SurfaceColor()
            local tweenInfoSwitch = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

            TweenService:Create(SwitchKnob, tweenInfoSwitch, {Position = targetKnobPos}):Play()
            TweenService:Create(SwitchTrack, tweenInfoSwitch, {BackgroundColor3 = targetTrackColor}):Play()

            -- Update registry for track color if it's based on toggle state
            local trackReg = Library.RegistryMap[SwitchTrack]
            if trackReg then
                trackReg.Properties.BackgroundColor3 = Toggle.Value and 'AccentColor' or 'SurfaceColor'
            end
        end;

        function Toggle:OnChanged(Func) Toggle.Changed = Func; if Func then Func(Toggle.Value) end end;
        function Toggle:SetValue(Bool, SkipCallbacks)
            Bool = not not Bool;
            if Toggle.Value == Bool then return end -- No change
            Toggle.Value = Bool;
            Toggle:Display();
            for _, Addon in ipairs(Toggle.Addons) do
                if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then Addon.Toggled = Bool; Addon:Update() end
            end
            if not SkipCallbacks then
                Library:SafeCallback(Toggle.Callback, Toggle.Value);
                Library:SafeCallback(Toggle.Changed, Toggle.Value);
            end
            Library:UpdateDependencyBoxes();
        end;

        ToggleRegion.MouseButton1Click:Connect(function()
            if Library:MouseIsOverOpenedFrame() then return end
            Toggle:SetValue(not Toggle.Value)
            Library:AttemptSave();
        end);
        if type(Info.Tooltip) == 'string' then Library:AddToolTip(Info.Tooltip, ToggleRegion) end

        Toggle:Display(); -- Initial state
        self:AddBlank(Info.BlankSize or (Library.IsMobile and 6 or 4) + 2); self:Resize();

        Toggle.TextLabel = ToggleLabel; -- For addons like ColorPicker
        Toggle.Container = self.Container;
        setmetatable(Toggle, BaseAddons);
        Toggles[Idx] = Toggle;
        Library:UpdateDependencyBoxes();
        return Toggle;
    end;


    BaseGroupbox.__index = Funcs;
    BaseGroupbox.__namecall = function(Self, Method, ...)
        local func = Funcs[Method]
        if func then return func(Self, ...)
        else error("Attempt to call nil method '" .. tostring(Method) .. "' on BaseGroupbox.") end
    end;
end;

-- < Create other UI elements (Notification, Watermark, KeybindList) >
do
    -- NotificationArea (No visual changes needed yet, just ensure children are themed)
    Library.NotificationArea = Library:Create('Frame', {
        Name = "NotificationArea", BackgroundTransparency = 1,
        Position = UDim2.new(Library.IsMobile and 0.05 or 0, Library.IsMobile and 0 or 10, 0, Library.IsMobile and GuiService:GetGuiInset().Y + 10 or 40),
        Size = UDim2.new(Library.IsMobile and 0.9 or 0, Library.IsMobile and 0 or 300, 0, 200),
        ZIndex = 2000; Parent = ScreenGui;
    });
    Library:Create('UIListLayout', { Padding = UDim.new(0, 5), FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder, Parent = Library.NotificationArea });


    -- Watermark
    local WatermarkOuter = Library:Create('Frame', {
        Name = "Watermark", BackgroundColor3 = Library.BackgroundColor(),
        Position = UDim2.new(0, 10, 0, 10), -- Top-left default
        Size = UDim2.fromOffset(200, 25), -- Initial small size, will resize
        Visible = false, ZIndex = 1500; Parent = ScreenGui,
    });
    Library:ApplyCorner(WatermarkOuter);
    Library:ApplyStroke(WatermarkOuter, 'AccentColor', 1.5); -- Prominent accent border
    Library:AddToRegistry(WatermarkOuter, { BackgroundColor3 = 'BackgroundColor', BorderColor3 = 'AccentColor' });

    local WatermarkLabel = Library:CreateLabel({
        Name = "WatermarkLabel", Position = UDim2.new(0,5,0,0), Size = UDim2.new(1,-10,1,0),
        Font = Library.Fonts.Title, TextSize = Library.IsMobile and 14 or 13,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
        RichText = true, ZIndex = WatermarkOuter.ZIndex + 1; Parent = WatermarkOuter;
    });
    Library.Watermark = WatermarkOuter;
    Library.WatermarkText = WatermarkLabel;
    Library:MakeDraggable(Library.Watermark, Library.IsMobile and 40 or 25);


    -- Keybind List
    local keybindListWidth = Library.IsMobile and 0.8 or 0
    local keybindListOffsetWidth = Library.IsMobile and 0 or 220
    local KeybindOuter = Library:Create('Frame', {
        Name = "KeybindList", BackgroundColor3 = Library.BackgroundColor(),
        AnchorPoint = Library.IsMobile and Vector2.new(0.5,0) or Vector2.new(0,1), -- Center top on mobile, bottom-left on PC
        Position = Library.IsMobile and UDim2.new(0.5,0,0, GuiService:GetGuiInset().Y + 10) or UDim2.new(0,10,1,-10),
        Size = UDim2.new(keybindListWidth, keybindListOffsetWidth, 0, 20), -- Initial height, will grow
        Visible = false, ZIndex = 1600; Parent = ScreenGui,
    });
    Library:ApplyCorner(KeybindOuter);
    Library:ApplyStroke(KeybindOuter, 'OutlineColor');
    Library:AddToRegistry(KeybindOuter, {BackgroundColor3 = 'BackgroundColor', BorderColor3 = 'OutlineColor'}, true);

    local KeybindTitleHighlight = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor(), Size = UDim2.new(1,0,0,3),
        ZIndex = KeybindOuter.ZIndex + 1, Parent = KeybindOuter,
    });
    Library:ApplyCorner(KeybindTitleHighlight, Vector2.new(Library.CornerRadius,0)); -- Only top corners round
    Library:AddToRegistry(KeybindTitleHighlight, {BackgroundColor3 = 'AccentColor'}, true);

    local KeybindLabel = Library:CreateLabel({
        Name = "KeybindListTitle", Size = UDim2.new(1,-10,0,20), Position = UDim2.new(0,5,0,3),
        Font = Library.Fonts.Title, TextSize = Library.IsMobile and 15 or 14,
        Text = 'Keybinds', TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = KeybindOuter.ZIndex + 1, Parent = KeybindOuter;
    });

    local KeybindContainer = Library:Create('ScrollingFrame', { -- CHANGED to ScrollingFrame
        Name = "KeybindItemContainer", BackgroundTransparency = 1,
        Size = UDim2.new(1,0,1,-23), Position = UDim2.new(0,0,0,23),
        CanvasSize = UDim2.new(), ScrollBarThickness = Library.IsMobile and 6 or 4,
        ScrollBarImageColor3 = Library.AccentColor(),
        ZIndex = KeybindOuter.ZIndex; Parent = KeybindOuter;
    });
    Library:Create('UIListLayout', { Name = "UIListLayout", FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,3), Parent = KeybindContainer });
    Library:Create('UIPadding', { PaddingLeft = UDim.new(0,5), PaddingRight = UDim.new(0,5), Parent = KeybindContainer });
    Library:AddToRegistry(KeybindContainer, {ScrollBarImageColor3 = 'AccentColor'}, true)


    Library.KeybindFrame = KeybindOuter;
    Library.KeybindContainer = KeybindContainer;
    Library:MakeDraggable(KeybindOuter, Library.IsMobile and 40 or 20);

    -- Auto-resize KeybindFrame based on KeybindContainer content
    if KeybindContainer:FindFirstChild("UIListLayout") then
        KeybindContainer.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            local contentHeight = KeybindContainer.UIListLayout.AbsoluteContentSize.Y
            KeybindContainer.CanvasSize = UDim2.fromOffset(0, contentHeight)
            local maxHeight = ScreenGui.AbsoluteSize.Y * (Library.IsMobile and 0.4 or 0.3) -- Max 30-40% of screen height
            local newHeight = math.min(contentHeight + 23 + (Library.IsMobile and 5 or 0), maxHeight) -- Title + padding
            if KeybindOuter.Size.Y.Offset ~= newHeight then
                KeybindOuter.Size = UDim2.new(KeybindOuter.Size.X.Scale, KeybindOuter.Size.X.Offset, 0, newHeight)
            end
            KeybindOuter.Visible = contentHeight > 0 -- Show only if there are keybinds
        end)
    end
end;

function Library:SetWatermarkVisibility(Bool) Library.Watermark.Visible = Bool end;
function Library:SetWatermark(Text)
    if not Text or Text == "" then Library:SetWatermarkVisibility(false); return end
    local textSize = Library.IsMobile and 14 or 13
    local X, Y = Library:GetTextBounds(Text, Library.WatermarkText.Font, textSize);
    Library:SetWatermarkVisibility(true);
    Library.WatermarkText.Text = Text;
    Library.Watermark.Size = UDim2.new(0, X + 20, 0, Y + 10); -- More padding
end;

--- MODIFIED: Notify function with type and better styling ---
function Library:Notify(Text, Time, TypeOrColor)
    -- TypeOrColor can be "AccentColor", "RiskColor", "FontColor" string, or a Color3 value
    local notifyColor = Library.AccentColor() -- Default
    if type(TypeOrColor) == "string" then
        notifyColor = Library.GetColor(TypeOrColor) or notifyColor
    elseif typeof(TypeOrColor) == "Color3" then
        notifyColor = TypeOrColor
    end

    local textSize = Library.IsMobile and 14 or 13
    local XSize, YSize = Library:GetTextBounds(Text, Library.Font(), textSize);
    YSize = math.max(YSize + (Library.IsMobile and 12 or 10), Library.IsMobile and 30 or 24) -- Min height
    XSize = math.max(XSize + (Library.IsMobile and 20 or 15), 100) -- Min width

    local NotifyOuter = Library:Create('Frame', {
        Name = "Notification", BackgroundColor3 = Library.BackgroundColor(),
        Size = UDim2.fromOffset(0, YSize), -- Initial width 0 for slide-in
        ClipsDescendants = true, ZIndex = Library.NotificationArea.ZIndex + 1,
        Parent = Library.NotificationArea,
    });
    Library:ApplyCorner(NotifyOuter, Library.CornerRadius -2);
    Library:ApplyStroke(NotifyOuter, 'OutlineColor');
    Library:AddToRegistry(NotifyOuter, {BackgroundColor3 = 'BackgroundColor', BorderColor3 = 'OutlineColor'}, true);

    local NotifyLabel = Library:CreateLabel({
        Name = "NotifyLabel", Position = UDim2.new(0, Library.IsMobile and 8 or 5, 0,0),
        Size = UDim2.new(1, -(Library.IsMobile and 16 or 10) -3, 1,0), -- Leave space for color bar + padding
        Text = Text, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
        TextSize = textSize, TextWrapped = true,
        ZIndex = NotifyOuter.ZIndex + 1, Parent = NotifyOuter;
    });

    local ColorBar = Library:Create('Frame', { -- Vertical color bar
        Name = "NotifyColorBar", BackgroundColor3 = notifyColor,
        Size = UDim2.new(0, Library.IsMobile and 4 or 3, 1,0), Position = UDim2.fromScale(0,0),
        ZIndex = NotifyOuter.ZIndex + 1, Parent = NotifyOuter,
    });
    Library:ApplyCorner(ColorBar, Vector2.new(Library.CornerRadius-2,0)); -- Round only left corners
    -- ColorBar color doesn't need to be in registry if it's set once

    local tweenInfoNotify = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    NotifyOuter:TweenSize(UDim2.fromOffset(XSize, YSize), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.3, true);

    task.delay(Time or (Library.IsMobile and 3 or 5), function()
        if NotifyOuter and NotifyOuter.Parent then
            NotifyOuter:TweenSize(UDim2.fromOffset(0, YSize), Enum.EasingDirection.In, Enum.EasingStyle.Quint, 0.3, true, function()
                if NotifyOuter and NotifyOuter.Parent then NotifyOuter:Destroy() end
            end);
        end
    end);
end;


function Library:CreateWindow(...)
    local Arguments = { ... }
    local Config = { AnchorPoint = Vector2.zero }
    if type(Arguments[1]) == 'table' then Config = Arguments[1]
    else Config.Title = Arguments[1]; Config.AutoShow = Arguments[2] or false; end

    Config.Title = Config.Title or 'VTRIP UI'
    Config.TabPadding = Config.TabPadding or (Library.IsMobile and 2 or 4)
    Config.MenuFadeTime = Config.MenuFadeTime or 0.2
    Config.Size = Config.Size or (Library.IsMobile and UDim2.new(0.9, 0, 0.8, 0) or UDim2.fromOffset(550, 480)) -- Smaller default height on PC
    Config.Position = Config.Position or (Library.IsMobile and UDim2.fromScale(0.5,0.5) or UDim2.fromOffset(200, 150))
    Config.Center = Config.Center or Library.IsMobile -- Center by default on mobile
    if Config.Center then Config.AnchorPoint = Vector2.new(0.5,0.5); Config.Position = UDim2.fromScale(0.5,0.5) end


    local Window = { Tabs = {}, IsMinimized = false, OriginalSize = Config.Size, OriginalPosition = Config.Position};

    local Outer = Library:Create('Frame', {
        Name = "MainWindowOuter", AnchorPoint = Config.AnchorPoint,
        BackgroundColor3 = Library.BackgroundColor(), -- Use theme
        Position = Config.Position, Size = Config.Size,
        Visible = false, ZIndex = 1, Parent = ScreenGui;
    });
    Library:ApplyCorner(Outer, Library.CornerRadius + 2); -- Slightly larger corner for main window
    Library:ApplyStroke(Outer, 'AccentColor', 1.5); -- Use AccentColor for main window border
    Library:AddToRegistry(Outer, { BackgroundColor3 = 'BackgroundColor', BorderColor3 = 'AccentColor' });

    local titleHeight = Library.IsMobile and 35 or 28
    Library:MakeDraggable(Outer, titleHeight); -- Pass titleHeight as cutoff

    local WindowHeader = Library:Create("Frame", { -- Separate header for title and buttons
        Name = "WindowHeader", BackgroundTransparency = 1, -- Or Library.MainColor() if distinct header bg desired
        Size = UDim2.new(1,0,0,titleHeight), ZIndex = Outer.ZIndex + 1, Parent = Outer
    })

    local WindowLabel = Library:CreateLabel({
        Name = "WindowTitle", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5,0,0.5,0),
        Size = UDim2.new(1, - (titleHeight * 2 + 10) , 1, 0), -- Leave space for min/close buttons
        Text = Config.Title, Font = Library.Fonts.Title, TextSize = Library.IsMobile and 18 or 16,
        TextXAlignment = Enum.TextXAlignment.Center, RichText = true,
        ZIndex = WindowHeader.ZIndex + 1, Parent = WindowHeader;
    });

    --- ADDED: Minimize Button ---
    local MinimizeButton = Library:Create("TextButton", {
        Name = "MinimizeButton", Text = "_", Font = Library.Fonts.Bold, TextSize = Library.IsMobile and 24 or 20,
        TextColor3 = Library.FontColor(), BackgroundTransparency = 1,
        Size = UDim2.fromOffset(titleHeight * 0.8, titleHeight * 0.8), AnchorPoint = Vector2.new(1,0.5),
        Position = UDim2.new(1, -(titleHeight * 0.8 + 5), 0.5, 0), -- Position before close button
        ZIndex = WindowHeader.ZIndex + 1, Parent = WindowHeader,
    })
    Library:AddToRegistry(MinimizeButton, {TextColor3 = 'FontColor'})
    MinimizeButton.MouseEnter:Connect(function() MinimizeButton.TextColor3 = Library.AccentColor() end)
    MinimizeButton.MouseLeave:Connect(function() MinimizeButton.TextColor3 = Library.FontColor() end)


    --- ADDED: Close Button (or use Toggle logic if preferred) ---
    local CloseButton = Library:Create("TextButton", {
        Name = "CloseButton", Text = "X", Font = Library.Fonts.Bold, TextSize = Library.IsMobile and 20 or 16,
        TextColor3 = Library.FontColor(), BackgroundTransparency = 1,
        Size = UDim2.fromOffset(titleHeight * 0.8, titleHeight * 0.8), AnchorPoint = Vector2.new(1,0.5),
        Position = UDim2.new(1, -5, 0.5, 0),
        ZIndex = WindowHeader.ZIndex + 1, Parent = WindowHeader,
    })
    Library:AddToRegistry(CloseButton, {TextColor3 = 'FontColor'})
    CloseButton.MouseEnter:Connect(function() CloseButton.TextColor3 = Library.RiskColor() end)
    CloseButton.MouseLeave:Connect(function() CloseButton.TextColor3 = Library.FontColor() end)
    CloseButton.MouseButton1Click:Connect(function() Library:Toggle() end) -- Use existing toggle logic


    local MainContentArea = Library:Create('Frame', { -- Area below header
        Name = "MainContentArea", BackgroundColor3 = Library.BackgroundColor(),
        Position = UDim2.new(0,0,0,titleHeight), Size = UDim2.new(1,0,1,-titleHeight),
        ZIndex = Outer.ZIndex, Parent = Outer, ClipsDescendants = true
    })
    Library:AddToRegistry(MainContentArea, {BackgroundColor3 = 'BackgroundColor'})


    local MainSectionOuter = Library:Create('Frame', { -- Content within MainContentArea
        Name = "MainSectionOuter", BackgroundColor3 = Library.SurfaceColor(), -- Slightly different from main BG
        Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -16, 1, -8), -- Padding
        ZIndex = MainContentArea.ZIndex +1, Parent = MainContentArea;
    });
    Library:ApplyCorner(MainSectionOuter, Library.CornerRadius);
    Library:ApplyStroke(MainSectionOuter, 'SubtleOutlineColor');
    Library:AddToRegistry(MainSectionOuter, { BackgroundColor3 = 'SurfaceColor', BorderColor3 = 'SubtleOutlineColor' });


    local tabAreaHeight = Library.IsMobile and 30 or 25
    local TabArea = Library:Create('Frame', {
        Name = "TabArea", BackgroundTransparency = 1,
        Position = UDim2.new(0, 4, 0, 4), Size = UDim2.new(1, -8, 0, tabAreaHeight),
        ZIndex = MainSectionOuter.ZIndex + 1, Parent = MainSectionOuter;
    });

    local TabListLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, Config.TabPadding), FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center,
        -- HorizontalFlex = Enum.UIFlexAlignment.SpaceAround, -- Or Fill / SpaceBetween
        Parent = TabArea;
    });

    local TabContainer = Library:Create('Frame', { -- Holds the content of the active tab
        Name = "TabContentContainer", BackgroundColor3 = Library.BackgroundColor(), -- Match main content bg
        Position = UDim2.new(0, 4, 0, tabAreaHeight + 8), Size = UDim2.new(1, -8, 1, -(tabAreaHeight + 12)),
        ZIndex = MainSectionOuter.ZIndex + 1, Parent = MainSectionOuter, ClipsDescendants = true,
    });
    Library:ApplyCorner(TabContainer, Library.CornerRadius-2);
    Library:ApplyStroke(TabContainer, 'SubtleOutlineColor');
    Library:AddToRegistry(TabContainer, { BackgroundColor3 = 'BackgroundColor', BorderColor3 = 'SubtleOutlineColor' });


    function Window:SetWindowTitle(Title) WindowLabel.Text = Title end;

    --- MINIMIZE FUNCTIONALITY ---
    local MinimizedBar = nil -- Will be created on first minimize
    function Window:ToggleMinimize()
        self.IsMinimized = not self.IsMinimized
        if self.IsMinimized then
            self.OriginalSize = Outer.Size
            self.OriginalPosition = Outer.Position -- Store current position if dragged
            Outer.Size = UDim2.fromOffset(Library.IsMobile and 150 or 200, titleHeight) -- Minimized size
            Outer.Position = UDim2.new(self.OriginalPosition.X.Scale, self.OriginalPosition.X.Offset, self.OriginalPosition.Y.Scale, self.OriginalPosition.Y.Offset) -- Keep X, but ensure it's on screen
            MainContentArea.Visible = false
            MinimizeButton.Text = "□" -- Restore icon (placeholder)

            -- Ensure it stays on screen
            local screenW, screenH = ScreenGui.AbsoluteSize.X, ScreenGui.AbsoluteSize.Y
            local barW, barH = Outer.AbsoluteSize.X, Outer.AbsoluteSize.Y
            local currentX, currentY = Outer.AbsolutePosition.X, Outer.AbsolutePosition.Y
            Outer.Position = UDim2.fromOffset(
                math.clamp(currentX, 0, screenW - barW),
                math.clamp(currentY, 0, screenH - barH)
            )

        else -- Restore
            Outer.Size = self.OriginalSize
            Outer.Position = self.OriginalPosition
            MainContentArea.Visible = true
            MinimizeButton.Text = "_"
        end
        -- If using a separate MinimizedBar, you'd toggle its visibility and Outer's visibility here.
    end
    MinimizeButton.MouseButton1Click:Connect(function() Window:ToggleMinimize() end)


    function Window:AddTab(Name)
        local Tab = { Groupboxes = {}, Tabboxes = {}, ParentWindow = Window };
        local tabTextSize = Library.IsMobile and 14 or 13

        local TabButton = Library:Create('TextButton', { -- TextButton for better click handling
            Name = Name .. "TabButton", AutoButtonColor = false,
            BackgroundColor3 = Library.SurfaceColor(), -- Slightly different from tab area bg
            Size = UDim2.new(0,0,1,0), -- Width calculated by text, full height of TabArea
            Text = "", -- Label child will hold text
            ZIndex = TabArea.ZIndex + 1, Parent = TabArea;
        });
        Library:ApplyCorner(TabButton, Vector2.new(Library.CornerRadius-2, 0)); -- Round top corners
        Library:ApplyStroke(TabButton, 'SubtleOutlineColor', 1);
        Library:AddToRegistry(TabButton, { BackgroundColor3 = 'SurfaceColor', BorderColor3 = 'SubtleOutlineColor'});


        local TabButtonLabel = Library:CreateLabel({
            Name = "TabButtonLabel", Size = UDim2.new(1,-10,1,0), Position = UDim2.new(0,5,0,0),
            Text = Name, Font = Library.Fonts.UI, TextSize = tabTextSize,
            ZIndex = TabButton.ZIndex + 1, Parent = TabButton;
        });
        -- Calculate tab button width based on text
        task.wait() -- Wait for label to render to get TextBounds
        local textWidth = TabButtonLabel.TextBounds.X
        TabButton.Size = UDim2.new(0, textWidth + (Library.IsMobile and 20 or 16), 1, 0)


        local TabFrame = Library:Create('Frame', { -- Content frame for this tab
            Name = Name .. "TabContent", BackgroundTransparency = 1,
            Size = UDim2.fromScale(1,1), Visible = false,
            ZIndex = TabContainer.ZIndex + 1, Parent = TabContainer;
        });

        -- Determine layout: single column for mobile, dual for PC
        local SidePadding = Library.IsMobile and 4 or 8
        local ColumnPadding = Library.IsMobile and 0 or 8 -- No padding between columns on mobile (they stack)
        local numColumns = Library.IsMobile and 1 or 2
        
        local scrollFrameWidthScale = Library.IsMobile and 1 or (0.5 - (ColumnPadding / (2 * TabFrame.AbsoluteSize.X)))
        local scrollFrameWidthOffset = Library.IsMobile and -(SidePadding*2) or -(SidePadding + ColumnPadding/2)


        local LeftSide = Library:Create('ScrollingFrame', {
            Name = "LeftSideScroll", BackgroundTransparency = 1, BorderSizePixel = 0,
            Position = UDim2.new(0, SidePadding, 0, SidePadding),
            Size = UDim2.new(scrollFrameWidthScale, scrollFrameWidthOffset, 1, -(SidePadding*2)),
            CanvasSize = UDim2.new(), ScrollBarThickness = Library.IsMobile and 6 or 4, ScrollBarImageColor3 = Library.AccentColor(),
            ZIndex = TabFrame.ZIndex + 1, Parent = TabFrame;
        });
        Library:Create('UIListLayout', { Name="Layout", Padding = UDim.new(0, Library.IsMobile and 6 or 8), FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = LeftSide });
        Library:AddToRegistry(LeftSide, {ScrollBarImageColor3 = 'AccentColor'})

        local RightSide = nil
        if not Library.IsMobile then
            RightSide = Library:Create('ScrollingFrame', {
                Name = "RightSideScroll", BackgroundTransparency = 1, BorderSizePixel = 0,
                Position = UDim2.new(0.5, ColumnPadding/2, 0, SidePadding),
                Size = UDim2.new(scrollFrameWidthScale, scrollFrameWidthOffset, 1, -(SidePadding*2)),
                CanvasSize = UDim2.new(), ScrollBarThickness = 4, ScrollBarImageColor3 = Library.AccentColor(),
                ZIndex = TabFrame.ZIndex + 1, Parent = TabFrame;
            });
            Library:Create('UIListLayout', { Name="Layout", Padding = UDim.new(0,8), FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = RightSide });
            Library:AddToRegistry(RightSide, {ScrollBarImageColor3 = 'AccentColor'})
        end

        for _, Side in ipairs({LeftSide, RightSide}) do
            if Side and Side:FindFirstChild("Layout") then
                Side.Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                    Side.CanvasSize = UDim2.fromOffset(0, Side.Layout.AbsoluteContentSize.Y);
                end);
            end
        end;

        local defaultTabColor = Library.SurfaceColor()
        local activeTabColor = Library.BackgroundColor() -- Active tab matches content area

        function Tab:ShowTab()
            for _, otherTab in pairs(Window.Tabs) do otherTab:HideTab() end;
            TabButton.BackgroundColor3 = activeTabColor -- Active color
            TabFrame.Visible = true;
            -- Update registry for tab button color
            local reg = Library.RegistryMap[TabButton]
            if reg then reg.Properties.BackgroundColor3 = 'BackgroundColor' end
        end;
        function Tab:HideTab()
            TabButton.BackgroundColor3 = defaultTabColor -- Default color
            TabFrame.Visible = false;
            local reg = Library.RegistryMap[TabButton]
            if reg then reg.Properties.BackgroundColor3 = 'SurfaceColor' end
        end;

        TabButton.MouseButton1Click:Connect(function() if not TabFrame.Visible then Tab:ShowTab() end end)
        TabButton.MouseEnter:Connect(function() if not TabFrame.Visible then TabButton.BackgroundColor3 = Library.GetColor('AccentColor') end end)
        TabButton.MouseLeave:Connect(function() if not TabFrame.Visible then TabButton.BackgroundColor3 = defaultTabColor end end)


        function Tab:AddGroupbox(Info) -- Info = {Name = "Box Name", Side = 1 (left) or 2 (right)}
            local Groupbox = { ParentTab = Tab };
            local targetParent = (Library.IsMobile or Info.Side == 1) and LeftSide or RightSide
            if not targetParent then targetParent = LeftSide end -- Fallback if RightSide doesn't exist

            local groupboxPadding = Library.IsMobile and 6 or 8
            local groupboxTitleHeight = Library.IsMobile and 22 or 18

            local BoxOuter = Library:Create('Frame', {
                Name = Info.Name .. "GroupboxOuter", BackgroundColor3 = Library.BackgroundColor(), -- Matches tab content bg
                Size = UDim2.new(1,0,0,50), -- Initial height, will resize
                ZIndex = targetParent.ZIndex + 1, Parent = targetParent;
            });
            Library:ApplyCorner(BoxOuter, Library.CornerRadius - 2);
            Library:ApplyStroke(BoxOuter, 'SubtleOutlineColor');
            Library:AddToRegistry(BoxOuter, {BackgroundColor3 = 'BackgroundColor', BorderColor3 = 'SubtleOutlineColor'});


            local Highlight = Library:Create('Frame', { -- Title highlight bar
                BackgroundColor3 = Library.AccentColor(), Size = UDim2.new(1,0,0,3),
                ZIndex = BoxOuter.ZIndex + 1, Parent = BoxOuter;
            });
            Library:ApplyCorner(Highlight, Vector2.new(Library.CornerRadius-2, 0)); -- Top corners round
            Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor' });

            local GroupboxLabel = Library:CreateLabel({
                Name = "GroupboxTitle", Size = UDim2.new(1, -groupboxPadding*2, 0, groupboxTitleHeight),
                Position = UDim2.new(0, groupboxPadding, 0, 3), -- Below highlight
                Text = Info.Name, Font = Library.Fonts.UI, TextSize = Library.IsMobile and 15 or 14,
                TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = BoxOuter.ZIndex + 1, Parent = BoxOuter;
            });

            local Container = Library:Create('Frame', { -- Holds components
                Name = "GroupboxContent", BackgroundTransparency = 1,
                Position = UDim2.new(0, groupboxPadding, 0, groupboxTitleHeight + 3 + (Library.IsMobile and 3 or 2)), -- Below title + padding
                Size = UDim2.new(1, -groupboxPadding*2, 1, -(groupboxTitleHeight + 3 + (Library.IsMobile and 3 or 2) + groupboxPadding)), -- Fill remaining space
                ZIndex = BoxOuter.ZIndex, Parent = BoxOuter;
            });
            local layout = Library:Create('UIListLayout', { Name="Layout", FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, Library.IsMobile and 4 or 3), Parent = Container });

            function Groupbox:Resize()
                task.wait() -- Allow layout to update
                local contentHeight = layout.AbsoluteContentSize.Y
                local totalHeight = groupboxTitleHeight + 3 + (Library.IsMobile and 3 or 2) + contentHeight + groupboxPadding
                BoxOuter.Size = UDim2.new(1,0,0, totalHeight)
                -- Parent ScrollingFrame canvas size will update due to its own UIListLayout
            end;

            Groupbox.Container = Container;
            setmetatable(Groupbox, BaseGroupbox);
            Groupbox:AddBlank(1); Groupbox:Resize(); -- Initial blank and resize
            Tab.Groupboxes[Info.Name] = Groupbox;
            return Groupbox;
        end;
        function Tab:AddLeftGroupbox(Name) return Tab:AddGroupbox({Name = Name, Side = 1}) end;
        function Tab:AddRightGroupbox(Name)
            if Library.IsMobile then warn("AddRightGroupbox called on mobile, will add to left.") end
            return Tab:AddGroupbox({Name = Name, Side = Library.IsMobile and 1 or 2})
        end;
        
        -- Tab:AddTabbox (similar structure to AddGroupbox, but with inner tabs)
        -- This will be a more complex component to refactor, can do it later.
        -- For now, ensure it uses the new styling for its outer frame and buttons.
        function Tab:AddTabbox(Info)
            -- Placeholder: This needs significant refactoring for new style and responsiveness
            warn("Tab:AddTabbox is not fully modernized yet.")
            -- ... existing AddTabbox logic ...
            -- Key changes:
            -- - BoxOuter should use Library.BackgroundColor(), ApplyCorner, ApplyStroke
            -- - TabboxButtons and their children (Buttons for inner tabs) need styling updates
            -- - Ensure resizing logic considers new padding/styles
            local Tabbox = { Tabs = {}, ParentTab = Tab };
            -- ... create BoxOuter, BoxInner, Highlight, TabboxButtons ...
            -- Apply new styling to these base elements using Library.GetColor, Library:ApplyCorner, etc.
            -- The internal Tab:Show/Hide/Resize will need to be reviewed.
            -- For now, returning a basic structure:
            local tempBox = Tab:AddLeftGroupbox(Info.Name or "Tabbox") -- Temporary use groupbox
            tempBox.IsTabbox = true
            function tempBox:AddTab(tabName) -- Mock AddTab for Tabbox
                warn("Using mocked Tabbox:AddTab. Create elements directly in Groupbox '"..tempBox.Container.Parent.Name.."'")
                local MockInnerTab = { Container = tempBox.Container, ParentTabbox = tempBox }
                setmetatable(MockInnerTab, BaseGroupbox) -- Allow adding components to it
                return MockInnerTab
            end
            return tempBox
        end
        function Tab:AddLeftTabbox(Name) return Tab:AddTabbox({Name=Name, Side=1}) end
        function Tab:AddRightTabbox(Name) return Tab:AddTabbox({Name=Name, Side=2}) end


        Window.Tabs[Name] = Tab;
        if #TabArea:GetChildren() == 1 then Tab:ShowTab() end; -- Show first tab
        return Tab;
    end;


    local ModalElement = Library:Create('TextButton', {
        Name = "ModalBlocker", BackgroundTransparency = 1, Size = UDim2.fromScale(1,1),
        Visible = true, Text = '', Modal = false, ZIndex = 0, -- Low ZIndex, only blocks if Modal = true
        Parent = ScreenGui;
    });
    local TransparencyCache = {};
    local Toggled = false;
    local Fading = false;

    function Library:Toggle()
        if Fading or (Window and Window.IsMinimized) then return end; -- Don't toggle if minimized

        local FadeTime = Config.MenuFadeTime; Fading = true;
        Toggled = not Toggled; ModalElement.Modal = Toggled;

        if Toggled then Outer.Visible = true; end; -- Show before fade in

        -- Custom Cursor (ensure Drawing API is available)
        -- This part remains largely the same, but ensure Cursor.Color uses Library.AccentColor()
        if Toggled and syn and syn. vẽ then -- Check for syn.drawing or your specific drawing lib
            task.spawn(function()
                local State = UserInputService.MouseIconEnabled;
                local Cursor = syn.vẽ.new('Triangle'); Cursor.Thickness = 1; Cursor.Filled = true; Cursor.Visible = true;
                local CursorOutline = syn.vẽ.new('Triangle'); CursorOutline.Thickness = 1; CursorOutline.Filled = false; CursorOutline.Color = Color3.new(0,0,0); CursorOutline.Visible = true;
                while Toggled and ScreenGui.Parent and Outer.Visible do
                    UserInputService.MouseIconEnabled = false;
                    local mPos = UserInputService:GetMouseLocation();
                    Cursor.Color = Library.AccentColor(); -- Use themed color
                    Cursor.PointA = mPos; Cursor.PointB = mPos + Vector2.new(16,6); Cursor.PointC = mPos + Vector2.new(6,16);
                    CursorOutline.PointA = Cursor.PointA; CursorOutline.PointB = Cursor.PointB; CursorOutline.PointC = Cursor.PointC;
                    RenderStepped:Wait();
                end
                UserInputService.MouseIconEnabled = State;
                Cursor:Remove(); CursorOutline:Remove();
            end);
        elseif Toggled then -- Fallback if no drawing lib
            UserInputService.MouseIconEnabled = false -- Hide default cursor
        else
            UserInputService.MouseIconEnabled = true -- Restore default cursor
        end

        -- Fade animation (mostly unchanged, but ensure it respects new structure)
        for _, Desc in ipairs(Outer:GetDescendants()) do
            if Desc:IsA("GuiObject") then -- Only GuiObjects have transparency
                local Properties = {};
                if Desc:IsA('ImageLabel') or Desc:IsA("ImageButton") then table.insert(Properties, 'ImageTransparency'); table.insert(Properties, 'BackgroundTransparency');
                elseif Desc:IsA('TextLabel') or Desc:IsA('TextBox') or Desc:IsA("TextButton") then table.insert(Properties, 'TextTransparency'); table.insert(Properties, 'BackgroundTransparency'); -- TextButton also has BG
                elseif Desc:IsA('Frame') or Desc:IsA('ScrollingFrame') then table.insert(Properties, 'BackgroundTransparency');
                elseif Desc:IsA('UIStroke') then table.insert(Properties, 'Transparency'); end;

                local Cache = TransparencyCache[Desc]; if not Cache then Cache = {}; TransparencyCache[Desc] = Cache; end;
                for _, Prop in ipairs(Properties) do
                    if Cache[Prop] == nil then Cache[Prop] = Desc[Prop] end; -- Store original on first toggle
                    if Cache[Prop] == 1 and Toggled == false then continue end; -- Already fully transparent, don't tween to 1 again
                    
                    local targetTransparency = Toggled and Cache[Prop] or 1
                    if Desc[Prop] ~= targetTransparency then -- Only tween if different
                         TweenService:Create(Desc, TweenInfo.new(FadeTime, Enum.EasingStyle.Linear), { [Prop] = targetTransparency }):Play();
                    end
                end;
            end
        end;
        task.wait(FadeTime);
        if not Toggled then Outer.Visible = false end; -- Hide after fade out
        Fading = false;
    end

    Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input, Processed)
        if Processed then return end
        local toggleKey = Library.ToggleKeybind and Library.ToggleKeybind.Value
        if toggleKey and Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == toggleKey then
            task.spawn(Library.Toggle)
        elseif Input.KeyCode == Enum.KeyCode.RightControl or Input.KeyCode == Enum.KeyCode.Insert or (Input.KeyCode == Enum.KeyCode.RightShift and not GuiService:GetFocusedTextBox()) then -- Common toggle keys, avoid shift if typing
            task.spawn(Library.Toggle)
        end
    end))

    if Config.AutoShow then task.spawn(Library.Toggle) end
    Window.Holder = Outer;
    return Window;
end;

local function OnPlayerChange()
    local PlayerList = GetPlayersString();
    for _, OptValue in pairs(Options) do
        if OptValue and OptValue.Type == 'Dropdown' and OptValue.SpecialType == 'Player' then
            OptValue:SetValues(PlayerList); -- Assumes Dropdown has SetValues method
        end;
    end;
end;

Players.PlayerAdded:Connect(OnPlayerChange);
Players.PlayerRemoving:Connect(OnPlayerChange);

-- Initial theme setup
Library:SetTheme(Library.CurrentTheme) -- Apply default theme colors to everything on load

getgenv().Library = Library
return Library
