local InputService = game:GetService('UserInputService');
local TextService = game:GetService('TextService');
local CoreGui = game:GetService('CoreGui');
local Teams = game:GetService('Teams');
local Players = game:GetService('Players');
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService');
local RenderStepped = RunService.RenderStepped;
local Heartbeat = RunService.Heartbeat; -- Added for smoother animations sometimes
local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse(); -- Mouse might be deprecated for some uses, but ok for quick X,Y

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);

local ScreenGui = Instance.new('ScreenGui');
ProtectGui(ScreenGui);

ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
ScreenGui.DisplayOrder = 2147483647;
ScreenGui.Parent = CoreGui;
ScreenGui.Name = "VTUI_MainScreenGui" -- Give it a name for easier debugging

local Toggles = {};
local Options = {};

getgenv().Toggles = Toggles;
getgenv().Options = Options;

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Library = {
    Registry = {};
    RegistryMap = {};
    HudRegistry = {};

    Themes = {
        Dark = {
            FontColor = Color3.fromRGB(235, 235, 235),
            MainColor = Color3.fromRGB(47, 49, 54),    -- Slightly lighter than discord's channel list
            BackgroundColor = Color3.fromRGB(30, 31, 34), -- Darker, main app background
            AccentColor = Color3.fromRGB(88, 101, 242), -- Discord Blurple
            OutlineColor = Color3.fromRGB(70, 70, 75),
            RiskColor = Color3.fromRGB(240, 70, 70),
            SuccessColor = Color3.fromRGB(67, 181, 129), -- Discord Green
            WarningColor = Color3.fromRGB(250, 166, 26), -- Discord Yellow
            Black = Color3.fromRGB(10,10,10), -- Not pure black for softer shadows/strokes
            SubtleOutlineColor = Color3.fromRGB(54, 57, 63), -- For less important borders
            SurfaceColor = Color3.fromRGB(40, 42, 45),   -- Input fields, dropdown lists bg
            DisabledColor = Color3.fromRGB(150,150,150),
            DisabledBackgroundColor = Color3.fromRGB(60,60,60),
            ScrollBar = Color3.fromRGB(32,34,37)
        },
        Light = {
            FontColor = Color3.fromRGB(30, 30, 30),
            MainColor = Color3.fromRGB(235, 235, 235),
            BackgroundColor = Color3.fromRGB(255, 255, 255),
            AccentColor = Color3.fromRGB(0, 122, 255),
            OutlineColor = Color3.fromRGB(180, 180, 180),
            RiskColor = Color3.fromRGB(220, 50, 50),
            SuccessColor = Color3.fromRGB(50, 170, 100),
            WarningColor = Color3.fromRGB(230, 150, 0),
            Black = Color3.fromRGB(240,240,240), -- For light theme, "black" stroke is actually light gray
            SubtleOutlineColor = Color3.fromRGB(210, 210, 210),
            SurfaceColor = Color3.fromRGB(245, 245, 245),
            DisabledColor = Color3.fromRGB(100,100,100),
            DisabledBackgroundColor = Color3.fromRGB(200,200,200),
            ScrollBar = Color3.fromRGB(200,200,200)
        }
    };
    CurrentTheme = "Dark";

    GetColor = function(colorName)
        local color = Library.Themes[Library.CurrentTheme][colorName]
        if not color then
            warn("VTUI: Color '"..tostring(colorName).."' not found in theme '"..Library.CurrentTheme.."'")
            return Color3.new(1,0,1) -- Magenta for missing color
        end
        return color
    end,

    FontColor = function() return Library.GetColor('FontColor') end,
    MainColor = function() return Library.GetColor('MainColor') end,
    BackgroundColor = function() return Library.GetColor('BackgroundColor') end,
    AccentColor = function() return Library.GetColor('AccentColor') end,
    OutlineColor = function() return Library.GetColor('OutlineColor') end,
    RiskColor = function() return Library.GetColor('RiskColor') end,
    SuccessColor = function() return Library.GetColor('SuccessColor') end,
    WarningColor = function() return Library.GetColor('WarningColor') end,
    Black = function() return Library.GetColor('Black') end,
    SubtleOutlineColor = function() return Library.GetColor('SubtleOutlineColor') end,
    SurfaceColor = function() return Library.GetColor('SurfaceColor') end,
    DisabledColor = function() return Library.GetColor('DisabledColor') end,
    DisabledBackgroundColor = function() return Library.GetColor('DisabledBackgroundColor') end,
    ScrollBarColor = function() return Library.GetColor('ScrollBar') end,

    Fonts = {
        Default = Enum.Font.GothamSemibold,
        Code = Enum.Font.Code,
        UI = Enum.Font.SourceSans, -- Using SourceSans as a common UI font
        Title = Enum.Font.GothamBold,
        Bold = Enum.Font.GothamBold,
    };
    Font = function(fontType) return Library.Fonts[fontType or "Default"] end,

    OpenedFrames = {}; -- Stores currently open popups like color pickers, dropdown lists
    DependencyBoxes = {};
    Signals = {};
    ScreenGui = ScreenGui;

    IsMobile = UserInputService.TouchEnabled, -- Simplified mobile check
    CornerRadius = 6,
    ShadowTransparency = 0.85, -- Softer shadow
    ShadowThickness = 1, -- Thinner shadow line
    DefaultTooltipDelay = 0.3, -- Seconds
    
    CursorImage = "rbxassetid://YOUR_CURSOR_IMAGE_ID", -- REPLACE THIS! (e.g., a small triangle or arrow)
    DropdownArrowImage = "rbxassetid://YOUR_DROPDOWN_ARROW_ID", -- REPLACE THIS! (e.g., a chevron icon)
    CheckmarkImage = "rbxassetid://YOUR_CHECKMARK_IMAGE_ID", -- REPLACE THIS! (for selected dropdown items)
};

Library.AccentColorDark = function() return Library:GetDarkerColor(Library.GetColor('AccentColor')) end;

local RainbowStep = 0
local Hue = 0
Library.IsUpdatingRainbow = false -- Initialize

table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
    RainbowStep = RainbowStep + Delta
    if RainbowStep >= (1 / 30) then -- Update rate for rainbow (can be adjusted)
        RainbowStep = 0
        Hue = Hue + (1 / 300); -- Speed of rainbow
        if Hue > 1 then Hue = 0 end;
        Library.CurrentRainbowHue = Hue;
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.9, 1); -- Saturation, Value
        if Library.IsUpdatingRainbow then
            Library:UpdateColorsUsingRegistry("Rainbow");
        end
    end
end))

local function GetPlayersString()
    local PlayerList = Players:GetPlayers(); local Names = {};
    for i = 1, #PlayerList do Names[i] = PlayerList[i].Name end;
    table.sort(Names); return Names;
end;

local function GetTeamsString()
    local TeamList = Teams:GetTeams(); local Names = {};
    for i = 1, #TeamList do Names[i] = TeamList[i].Name end;
    table.sort(Names); return Names;
end;

function Library:SafeCallback(f, ...)
    if not f then return end;
    if not Library.NotifyOnError then return f(...) end;
    local success, resultOrError = pcall(f, ...);
    if not success then
        local _, i = tostring(resultOrError):find(":%d+: ");
        local errMsg = i and resultOrError:sub(i + 1) or tostring(resultOrError)
        Library:Notify("Error: " .. errMsg, 7, "RiskColor");
    end;
    return resultOrError -- Return result if successful
end;

function Library:AttemptSave() if Library.SaveManager then Library.SaveManager:Save() end end;

function Library:Create(Class, Properties)
    local inst = typeof(Class) == 'string' and Instance.new(Class) or Class;
    for prop, val in pairs(Properties or {}) do
        if type(val) == 'function' and string.match(prop, "Color") then inst[prop] = val()
        else inst[prop] = val end
    end;
    return inst;
end;

function Library:ApplyCorner(inst, radius)
    if not inst:FindFirstChildWhichIsA("UICorner") then -- Avoid duplicates
        Library:Create('UICorner', { CornerRadius = UDim.new(0, radius or Library.CornerRadius), Parent = inst });
    end
end

function Library:ApplyStroke(inst, colorNameOrFunc, thickness, transparency)
    local existingStroke = inst:FindFirstChild(inst.Name .. "_Stroke")
    if existingStroke then existingStroke:Destroy() end -- Remove old one if recreating

    local stroke = Library:Create('UIStroke', {
        Name = inst.Name .. "_Stroke", -- Unique name for potential re-application
        Color = typeof(colorNameOrFunc) == 'function' and colorNameOrFunc() or Library.GetColor(colorNameOrFunc or 'OutlineColor'),
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        LineJoinMode = Enum.LineJoinMode.Round,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = inst
    })
    -- Register only if colorName is a string (theme color name)
    if typeof(colorNameOrFunc) == 'string' then
        Library:AddToRegistry(stroke, { Color = colorNameOrFunc })
    elseif typeof(colorNameOrFunc) == 'function' then
         Library:AddToRegistry(stroke, { Color = colorNameOrFunc }) -- For dynamic colors like GetDarkerColor
    end
    return stroke
end

function Library:ApplyTextStroke(Inst, color, thickness)
    Inst.TextStrokeTransparency = 0; -- Ensure it's visible
    Library:Create('UIStroke', {
        Color = color or Color3.new(0.1,0.1,0.1,0.5), -- Semi-transparent dark
        Thickness = thickness or 0.5, -- Very subtle
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border, -- For Text, Border works for stroke
        Parent = Inst;
    });
end;

function Library:CreateLabel(Properties, IsHud)
    local defaultFontSize = Library.IsMobile and 15 or 14
    local _Instance = Library:Create('TextLabel', {
        Name = Properties and Properties.Name or "VTUILabel",
        BackgroundTransparency = 1,
        Font = Library.Font(Properties and Properties.FontType), -- Allow specifying font type
        TextColor3 = Library.FontColor(),
        TextSize = Properties and Properties.TextSize or defaultFontSize,
        TextStrokeTransparency = 1, -- Handled by ApplyTextStroke if needed
        ClipsDescendants = true,
    });
    -- if Properties.ApplyGlobalTextStroke then Library:ApplyTextStroke(_Instance) end -- Make it opt-in

    Library:AddToRegistry(_Instance, { TextColor3 = 'FontColor', Font = function() return Library.Font(Properties and Properties.FontType) end }, IsHud);
    return Library:Create(_Instance, Properties);
end;

function Library:MakeDraggable(InstanceToDrag, DragHandle, CutoffY)
    DragHandle.Active = true; -- The handle is what receives input
    local Dragging = false
    local DragInput = nil
    local DragStartMouse = nil
    local StartPosition = nil

    DragHandle.InputBegan:Connect(function(Input)
        if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Dragging then
            local relativeMouseY = Input.Position.Y - DragHandle.AbsolutePosition.Y
            if CutoffY and relativeMouseY > CutoffY then return end

            Dragging = true
            DragInput = Input
            DragStartMouse = Input.Position
            StartPosition = InstanceToDrag.Position -- Drag the parent instance

            local moveConn, upConn
            moveConn = UserInputService.InputChanged:Connect(function(inputChanged)
                if inputChanged == DragInput and Dragging then
                    local delta = inputChanged.Position - DragStartMouse
                    InstanceToDrag.Position = UDim2.new(
                        StartPosition.X.Scale, StartPosition.X.Offset + delta.X,
                        StartPosition.Y.Scale, StartPosition.Y.Offset + delta.Y
                    )
                end
            end)
            upConn = UserInputService.InputEnded:Connect(function(inputEnded)
                if inputEnded == DragInput then
                    Dragging = false
                    if moveConn and moveConn.Connected then moveConn:Disconnect() end
                    if upConn and upConn.Connected then upConn:Disconnect() end
                end
            end)
            Library:GiveSignal(moveConn); Library:GiveSignal(upConn)
        end
    end)
end;

function Library:AddToolTip(InfoStr, HoverInstance, Delay)
    if not InfoStr or InfoStr == "" then return end
    Delay = Delay or Library.DefaultTooltipDelay

    local padding = Vector2.new(10, 8)
    local textSize = Library.IsMobile and 14 or 13
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font("UI"), textSize);

    local Tooltip = Library:Create('Frame', {
        Name = "Tooltip", BackgroundColor3 = Library.SurfaceColor(),
        Size = UDim2.fromOffset(X + padding.X, Y + padding.Y),
        ZIndex = 2000, Parent = Library.ScreenGui, Visible = false, ClipsDescendants = true,
    })
    Library:ApplyCorner(Tooltip, 4); Library:ApplyStroke(Tooltip, 'OutlineColor', 1);
    Library:AddToRegistry(Tooltip, { BackgroundColor3 = 'SurfaceColor' });

    local Label = Library:CreateLabel({
        Position = UDim2.fromScale(0.5,0.5), AnchorPoint = Vector2.new(0.5,0.5), Size = UDim2.fromScale(1,1),
        TextSize = textSize, Text = InfoStr, TextWrapped = true, FontType = "UI",
        TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = Tooltip.ZIndex + 1, Parent = Tooltip,
    });

    local IsHovering = false; local HoverStartTime = 0
    local TweenInfoShort = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local MouseMoveConn = nil

    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() and HoverInstance.Parent ~= Library.ScreenGui then return end
        IsHovering = true; HoverStartTime = tick()
        
        task.delay(Delay, function() -- Show after delay
            if IsHovering and Tooltip and Tooltip.Parent then -- Still hovering
                Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 20)
                Tooltip.Visible = true; Tooltip.BackgroundTransparency = 1; Label.TextTransparency = 1
                TweenService:Create(Tooltip, TweenInfoShort, {BackgroundTransparency = 0}):Play()
                TweenService:Create(Label, TweenInfoShort, {TextTransparency = 0}):Play()

                if not MouseMoveConn or not MouseMoveConn.Connected then
                    MouseMoveConn = UserInputService.InputChanged:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                            if IsHovering and Tooltip.Visible then
                                Tooltip.Position = UDim2.fromOffset(input.Position.X + 15, input.Position.Y + 20)
                            end
                        end
                    end)
                    Library:GiveSignal(MouseMoveConn)
                end
            end
        end)
    end)

    HoverInstance.MouseLeave:Connect(function()
        IsHovering = false
        if Tooltip and Tooltip.Parent and Tooltip.Visible then
            local tween = TweenService:Create(Tooltip, TweenInfoShort, {BackgroundTransparency = 1})
            tween:Play(); TweenService:Create(Label, TweenInfoShort, {TextTransparency = 1}):Play()
            tween.Completed:Once(function() if not IsHovering then Tooltip.Visible = false end end)
        end
        -- Do not disconnect MouseMoveConn here, let it be cleaned up by GiveSignal on Unload
    end)
    Library:GiveSignal(HoverInstance.AncestryChanged:Connect(function(_, parent)
        if not parent and Tooltip and Tooltip.Parent then Tooltip:Destroy() end
    end))
end

function Library:OnHighlight(HighlightInstance, InstanceToModify, PropertiesHover, PropertiesDefault)
    local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    HighlightInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() and HighlightInstance.Parent ~= Library.ScreenGui and not HighlightInstance:IsDescendantOf(Library.ScreenGui) then return end
        local Reg = Library.RegistryMap[InstanceToModify];
        for Prop, ColorNameOrVal in pairs(PropertiesHover) do
            local targetColor = typeof(ColorNameOrVal) == 'string' and Library.GetColor(ColorNameOrVal) or ColorNameOrVal
            if InstanceToModify[Prop] ~= targetColor then
                TweenService:Create(InstanceToModify, tweenInfo, {[Prop] = targetColor}):Play()
            end
            if Reg and Reg.Properties and Reg.Properties[Prop] then Reg.Properties[Prop] = ColorNameOrVal end;
        end;
    end)
    HighlightInstance.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[InstanceToModify];
        for Prop, ColorNameOrVal in pairs(PropertiesDefault) do
            local targetColor = typeof(ColorNameOrVal) == 'string' and Library.GetColor(ColorNameOrVal) or ColorNameOrVal
             if InstanceToModify[Prop] ~= targetColor then
                TweenService:Create(InstanceToModify, tweenInfo, {[Prop] = targetColor}):Play()
            end
            if Reg and Reg.Properties and Reg.Properties[Prop] then Reg.Properties[Prop] = ColorNameOrVal end;
        end;
    end)
end;

function Library:MouseIsOverOpenedFrame()
    for Frame, _ in pairs(Library.OpenedFrames) do
        if Frame and Frame.Parent and Frame.Visible then
            local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
            if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then return true end
        end
    end; return false
end;

function Library:IsMouseOverFrame(Frame)
    if Frame and Frame.Parent and Frame.Visible then
        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
        if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then return true end
    end; return false
end;

function Library:UpdateDependencyBoxes()
    for _, Depbox in ipairs(Library.DependencyBoxes) do
        if Depbox and typeof(Depbox.Update) == 'function' then Depbox:Update() end
    end
end;

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    if MaxA - MinA == 0 then return MinB end
    return MinB + (MaxB - MinB) * ((Value - MinA) / (MaxA - MinA))
end;

function Library:GetTextBounds(Text, FontEnum, Size, Resolution)
    local PlainText = Text:gsub("<[^>]->", "")
    local RenderResolution = Resolution or GuiService:GetGuiInset() + (typeof(workspace.CurrentCamera) == "Instance" and workspace.CurrentCamera.ViewportSize or Vector2.new(1920,1080))
    local Bounds = TextService:GetTextSize(PlainText, Size, FontEnum, RenderResolution)
    return Bounds.X, Bounds.Y
end

function Library:GetDarkerColor(Color, factor) factor = factor or 0.7
    local H, S, V = Color3.toHSV(Color); return Color3.fromHSV(H, S, V * factor)
end;
function Library:GetLighterColor(Color, factor) factor = factor or 1.3
    local H, S, V = Color3.toHSV(Color); return Color3.fromHSV(H, S, math.min(1, V * factor))
end;

function Library:AddToRegistry(Instance, Properties, IsHud)
    if Library.RegistryMap[Instance] then return end
    local Data = { Instance = Instance, Properties = Properties, IsHud = IsHud or false, OriginalProperties = {}, IsRainbow = false };
    for prop, colorNameOrFunc in pairs(Properties) do
        if type(colorNameOrFunc) == 'string' and string.lower(colorNameOrFunc) == "rainbow" then
            Data.IsRainbow = true; Library.IsUpdatingRainbow = true; Data.RainbowProperty = prop;
            Data.OriginalProperties[prop] = Instance[prop]
        elseif typeof(colorNameOrFunc) == 'function' or typeof(colorNameOrFunc) == 'string' then
            Data.OriginalProperties[prop] = Instance[prop]
        end
    end
    table.insert(Library.Registry, Data); Library.RegistryMap[Instance] = Data;
    if IsHud then table.insert(Library.HudRegistry, Data) end;
    self:UpdateInstanceColors(Data)
end;

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance];
    if Data then
        for i = #Library.Registry, 1, -1 do if Library.Registry[i] == Data then table.remove(Library.Registry, i); break end end;
        if Data.IsHud then for i = #Library.HudRegistry, 1, -1 do if Library.HudRegistry[i] == Data then table.remove(Library.HudRegistry, i); break end end end
        Library.RegistryMap[Instance] = nil;
    end;
end;

function Library:UpdateInstanceColors(ObjectData)
    local instance = ObjectData.Instance
    if not instance or not instance.Parent then self:RemoveFromRegistry(instance); return end
    if ObjectData.IsRainbow and ObjectData.RainbowProperty then
        instance[ObjectData.RainbowProperty] = Library.CurrentRainbowColor or Library.GetColor('AccentColor')
    else
        for Property, ColorNameOrFunc in pairs(ObjectData.Properties) do
            if type(ColorNameOrFunc) == 'string' then
                if string.lower(ColorNameOrFunc) == "rainbow" then instance[Property] = Library.CurrentRainbowColor or Library.GetColor('AccentColor')
                else instance[Property] = Library.GetColor(ColorNameOrFunc) end
            elseif type(ColorNameOrFunc) == 'function' then instance[Property] = ColorNameOrFunc() end
        end
    end
end

function Library:UpdateColorsUsingRegistry(updateType)
    for Idx = #Library.Registry, 1, -1 do
        local ObjectData = Library.Registry[Idx]
        if not ObjectData.Instance or not ObjectData.Instance.Parent then self:RemoveFromRegistry(ObjectData.Instance); continue end
        if updateType == "Rainbow" then
            if ObjectData.IsRainbow and ObjectData.RainbowProperty then ObjectData.Instance[ObjectData.RainbowProperty] = Library.CurrentRainbowColor or Library.GetColor('AccentColor') end
        else self:UpdateInstanceColors(ObjectData) end
    end
end;

function Library:SetTheme(themeName)
    if Library.Themes[themeName] then
        Library.CurrentTheme = themeName;
        Library:UpdateColorsUsingRegistry(themeName);
        if Library.OnThemeChanged then Library.OnThemeChanged(themeName) end
        -- Update custom cursor color if visible
        if Library.CustomCursorImageLabel and Library.CustomCursorImageLabel.Parent then
            Library.CustomCursorImageLabel.ImageColor3 = Library.AccentColor()
        end
    else warn("Theme not found:", themeName) end
end

function Library:GiveSignal(Signal) if Signal and typeof(Signal) == "RBXScriptConnection" then table.insert(Library.Signals, Signal) end end

function Library:Unload()
    if Library.Unloading then return end; Library.Unloading = true
    for Idx = #Library.Signals, 1, -1 do local C = table.remove(Library.Signals, Idx); if C and C.Connected then C:Disconnect() end end
    Library.Signals = {}
    if Library.OnUnload then Library.OnUnload() end
    if Library.CustomCursorImageLabel and Library.CustomCursorImageLabel.Parent then Library.CustomCursorImageLabel:Destroy() Library.CustomCursorImageLabel = nil end
    if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end; ScreenGui = nil
    Library.Registry = {}; Library.RegistryMap = {}; Library.HudRegistry = {}; Library.OpenedFrames = {}; Library.DependencyBoxes = {}
    getgenv().Library = nil; getgenv().Toggles = nil; getgenv().Options = nil
    print("VTUI Library Unloaded.")
end
function Library:OnUnload(Callback) Library.OnUnload = Callback end
if ScreenGui then Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(I) if Library.RegistryMap[I] then Library:RemoveFromRegistry(I) end end)) end

local BaseAddons = {}; do local F = {}; F.__index = F; function F.new() local self = setmetatable({},F); return self; end
    -- Addons (ColorPicker, KeyPicker) - These need significant UI overhaul still
    -- For now, focusing on the main structure and other components
    function F:AddColorPicker(Idx, Info) warn("ColorPicker not fully updated"); return self end;
    function F:AddKeyPicker(Idx, Info) warn("KeyPicker not fully updated"); return self end;
    BaseAddons = F;
end

local BaseGroupbox = {}; do local Funcs = {}; Funcs.__index = Funcs;
    function Funcs:AddBlank(Size) Library:Create('Frame', {Name="BlankSpace",BackgroundTransparency=1,Size=UDim2.new(1,0,0,Size or (Library.IsMobile and 4 or 2)),Parent=self.Container}); return self end

    function Funcs:AddLabel(Text, DoesWrap)
        local Label = { ParentGroupbox = self }; local textSize = Library.IsMobile and 15 or 14
        local TextLabel = Library:CreateLabel({ Name="InfoLabel", FontType="UI",
            Size = UDim2.new(1, DoesWrap and -8 or -4, 0, textSize + (DoesWrap and 4 or 0)), TextSize = textSize,
            Text = Text or "Label", TextWrapped = DoesWrap or false, TextXAlignment = Enum.TextXAlignment.Left,
            ClipsDescendants = not DoesWrap, Parent = self.Container });
        if DoesWrap then
            TextLabel.TextYAlignment = Enum.TextYAlignment.Top
            local function updateWrapHeight()
                local _, Y = Library:GetTextBounds(TextLabel.Text, TextLabel.Font, TextLabel.TextSize, Vector2.new(TextLabel.AbsoluteSize.X, math.huge))
                TextLabel.Size = UDim2.new(TextLabel.Size.X.Scale,TextLabel.Size.X.Offset,0,math.max(textSize,Y)+4); self:Resize()
            end
            TextLabel:GetPropertyChangedSignal("Text"):Connect(updateWrapHeight)
            task.defer(updateWrapHeight) -- Initial size
        else Library:Create('UIListLayout',{Padding=UDim.new(0,4),FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Right,VerticalAlignment=Enum.VerticalAlignment.Center,Parent=TextLabel}) end
        Label.TextLabel = TextLabel; Label.Container = self.Container;
        function Label:SetText(newText) TextLabel.Text=newText; if not DoesWrap then self.ParentGroupbox:Resize() end end
        if not DoesWrap then setmetatable(Label, BaseAddons) end;
        self:AddBlank(); self:Resize(); return Label;
    end;

    function Funcs:AddButton(...)
        local Button = { ParentGroupbox = self };
        local function PBP(C,O,...) local P=select(1,...); if type(P)=='table' then O.Text=P.Text or "Button";O.Func=P.Func;O.DoubleClick=P.DoubleClick;O.Tooltip=P.Tooltip;O.Icon=P.Icon;O.Disabled=P.Disabled else O.Text=select(1,...)or "Button";O.Func=select(2,...)end; assert(type(O.Func)=='function' or O.Disabled,"AddButton: Func missing. Text: "..O.Text) end
        PBP('Button',Button,...)
        local btnH = Library.IsMobile and 32 or 24; local iconSize = btnH*0.65

        local Outer = Library:Create('TextButton',{Name="ButtonOuter",AutoButtonColor=false,BackgroundColor3=Button.Disabled and Library.DisabledBackgroundColor() or Library.MainColor(),Size=UDim2.new(1,-4,0,btnH),Text="",Parent=self.Container});
        Library:ApplyCorner(Outer); Library:ApplyStroke(Outer, Button.Disabled and 'SubtleOutlineColor' or 'OutlineColor');
        Library:AddToRegistry(Outer, {BackgroundColor3=function() return Button.Disabled and Library.DisabledBackgroundColor() or Library.MainColor() end, BorderColor3=function() return Button.Disabled and 'SubtleOutlineColor' or 'OutlineColor' end});
        Button.Outer = Outer

        local Label = Library:CreateLabel({Name="ButtonLabel",FontType="UI", TextColor3 = Button.Disabled and Library.DisabledColor() or Library.FontColor(),
            Size=UDim2.new(1,Button.Icon and -(iconSize+10) or -10,1,-2),Position=UDim2.new(0,Button.Icon and iconSize+8 or 5,0,1),
            TextSize=Library.IsMobile and 15 or 13,Text=Button.Text,Parent=Outer});
        Library:AddToRegistry(Label, {TextColor3 = function() return Button.Disabled and Library.DisabledColor() or Library.FontColor() end})
        Button.Label = Label

        if Button.Icon then
            local IconImg = Library:Create("ImageLabel",{Name="ButtonIcon",Size=UDim2.fromOffset(iconSize,iconSize),AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,5,0.5,0),BackgroundTransparency=1,Image=Button.Icon,ImageColor3=Button.Disabled and Library.DisabledColor() or Library.FontColor(),Parent=Outer})
            Library:AddToRegistry(IconImg,{ImageColor3=function() return Button.Disabled and Library.DisabledColor() or Library.FontColor() end})
        end
        
        function Button:SetDisabled(disabled)
            Button.Disabled = disabled
            Outer.BackgroundColor3 = disabled and Library.DisabledBackgroundColor() or Library.MainColor()
            Outer:FindFirstChild(Outer.Name .. "_Stroke").Color = disabled and Library.SubtleOutlineColor() or Library.OutlineColor()
            Label.TextColor3 = disabled and Library.DisabledColor() or Library.FontColor()
            if Button.Icon and Outer:FindFirstChild("ButtonIcon") then Outer.ButtonIcon.ImageColor3 = disabled and Library.DisabledColor() or Library.FontColor() end
            Outer.Active = not disabled -- Disable interaction
        end

        if not Button.Disabled then
            local defaultC,hoverC,pressC = Library.MainColor(),Library:GetLighterColor(Library.MainColor(),1.15),Library:GetDarkerColor(Library.MainColor(),0.9)
            Outer.MouseEnter:Connect(function() if not Button.Disabled then TweenService:Create(Outer,TweenInfo.new(0.1),{BackgroundColor3=hoverC}):Play() end end)
            Outer.MouseLeave:Connect(function() if not Button.Disabled then TweenService:Create(Outer,TweenInfo.new(0.1),{BackgroundColor3=defaultC}):Play() end end)
            Outer.MouseButton1Down:Connect(function() if not Button.Disabled then Outer.BackgroundColor3=pressC end end)
            Outer.MouseButton1Up:Connect(function() if not Button.Disabled then Outer.BackgroundColor3 = Outer.MouseEnter and hoverC or defaultC end end)
            local lastClickTime = 0
            Outer.MouseButton1Click:Connect(function() if Button.Disabled or Library:MouseIsOverOpenedFrame() then return end
                if Button.DoubleClick then if tick()-lastClickTime<0.3 then lastClickTime=0;Library:SafeCallback(Button.Func) else lastClickTime=tick(); local oT=Label.Text;local oC=Label.TextColor3;Label.Text="Confirm?";Label.TextColor3=Library.RiskColor();task.delay(1.5,function()if Label and Label.Parent and Label.Text=="Confirm?" then Label.Text=oT;Label.TextColor3=oC end end)end;return end
                Library:SafeCallback(Button.Func)
            end)
        end
        if type(Button.Tooltip)=='string' then Library:AddToolTip(Button.Tooltip,Outer) end
        if Button.Disabled then Button:SetDisabled(true) end -- Apply initial disabled state

        self:AddBlank(); self:Resize(); return Button;
    end;

    function Funcs:AddDivider()
        self:AddBlank(Library.IsMobile and 5 or 2.5);
        local D = Library:Create('Frame',{Name="Divider",BackgroundColor3=Library.SubtleOutlineColor(),Size=UDim2.new(1,-8,0,1.5),Position=UDim2.new(0,4,0,0),Parent=self.Container});
        Library:ApplyCorner(D,0.75); Library:AddToRegistry(D,{BackgroundColor3='SubtleOutlineColor'});
        self:AddBlank(Library.IsMobile and 5 or 2.5); self:Resize(); return self
    end

    function Funcs:AddInput(Idx, Info)
        assert(Info.Text or Info.Placeholder, 'AddInput: Missing Text or Placeholder.')
        local Textbox={Value=Info.Default or "",Numeric=Info.Numeric or false,Finished=Info.Finished or false,Type='Input',Callback=Info.Callback or function()end, ParentGroupbox=self};
        local inputH=Library.IsMobile and 30 or 22; local lblSize=Library.IsMobile and 14 or 12; local boxSize=Library.IsMobile and 14 or 13;
        if Info.Text and Info.Text~="" then Library:CreateLabel({Size=UDim2.new(1,0,0,lblSize+2),TextSize=lblSize,Text=Info.Text,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Bottom,Parent=self.Container}); self:AddBlank(1) end
        local Outer=Library:Create('Frame',{Name="InputOuter",BackgroundColor3=Library.SurfaceColor(),Size=UDim2.new(1,-4,0,inputH),Parent=self.Container});
        Library:ApplyCorner(Outer);Library:ApplyStroke(Outer,'SubtleOutlineColor');Library:AddToRegistry(Outer,{BackgroundColor3='SurfaceColor',BorderColor3='SubtleOutlineColor'});
        Library:OnHighlight(Outer,Outer,{BorderColor3='AccentColor'},{BorderColor3='SubtleOutlineColor'});
        if type(Info.Tooltip)=='string' then Library:AddToolTip(Info.Tooltip,Outer) end
        local Box=Library:Create('TextBox',{Name="InputBox",BackgroundTransparency=1,Size=UDim2.new(1,-10,1,-4),Position=UDim2.new(0,5,0,2),Font=Library.Font("UI"),PlaceholderColor3=Library.GetColor('FontColor'),PlaceholderText=Info.Placeholder or '',Text=Info.Default or '',TextColor3=Library.FontColor(),TextSize=boxSize,ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left,Parent=Outer});
        Box.PlaceholderColor3 = Color3.new(Box.PlaceholderColor3.R,Box.PlaceholderColor3.G,Box.PlaceholderColor3.B,0.5)
        Library:AddToRegistry(Box,{TextColor3='FontColor',PlaceholderColor3=function()local c=Library.GetColor('FontColor');return Color3.new(c.R,c.G,c.B,0.5)end});
        function Textbox:SetValue(Txt,skipCb) Txt=tostring(Txt); if Info.MaxLength and #Txt>Info.MaxLength then Txt=Txt:sub(1,Info.MaxLength)end; if Textbox.Numeric and #Txt>0 and not tonumber(Txt) and Txt~="-"and Txt~="." and not Txt:match("^[-%d%.]*$") then Txt=Textbox.Value end; Textbox.Value=Txt;Box.Text=Txt; if not skipCb then Library:SafeCallback(Textbox.Callback,Textbox.Value);Library:SafeCallback(Textbox.Changed,Textbox.Value) end end
        if Textbox.Finished then Box.FocusLost:Connect(function(e)if e then Textbox:SetValue(Box.Text);Library:AttemptSave()end end) else Box:GetPropertyChangedSignal('Text'):Connect(function()Textbox:SetValue(Box.Text)Library:AttemptSave()end)end;
        local function UpdateScroll() local P=2;local R=Outer.AbsoluteSize.X-10; if not Box:IsFocused()or Box.TextBounds.X<=R-2*P then Box.TextXAlignment=Enum.TextXAlignment.Left else Box.TextXAlignment=Enum.TextXAlignment.Right end end
        task.defer(UpdateScroll);Box:GetPropertyChangedSignal('Text'):Connect(UpdateScroll);Box.FocusLost:Connect(UpdateScroll);Box.Focused:Connect(UpdateScroll);
        function Textbox:OnChanged(F)Textbox.Changed=F;if F then F(Textbox.Value)end end;Options[Idx]=Textbox;
        self:AddBlank(); self:Resize(); return Textbox;
    end

    function Funcs:AddToggle(Idx, Info)
        assert(Info.Text,'AddToggle: Missing Text.')
        local tH=Library.IsMobile and 28 or 22;local sW=Library.IsMobile and 40 or 34;local sH=Library.IsMobile and 20 or 16;local kS=sH-(Library.IsMobile and 6 or 4);
        local Toggle={Value=Info.Default or false,Type='Toggle',Callback=Info.Callback or function()end,Addons={},Risky=Info.Risky,ParentGroupbox=self};
        local TF=Library:Create('Frame',{Name="ToggleFrame",BackgroundTransparency=1,Size=UDim2.new(1,-4,0,tH),Parent=self.Container});
        Library:Create('UIListLayout',{FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,HorizontalAlignment=Enum.HorizontalAlignment.SpaceBetween,Parent=TF});
        local TL=Library:CreateLabel({Name="ToggleLabel",FontType="UI",Size=UDim2.new(0.85,-sW-10,1,0),TextSize=Library.IsMobile and 15 or 14,Text=Info.Text,TextXAlignment=Enum.TextXAlignment.Left,Parent=TF,LayoutOrder=1});
        if Toggle.Risky then TL.TextColor3=Library.RiskColor();Library:AddToRegistry(TL,{TextColor3='RiskColor'})end
        Library:Create('UIListLayout',{Padding=UDim.new(0,4),FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Right,Parent=TL});
        local ST=Library:Create('Frame',{Name="SwitchTrack",Size=UDim2.fromOffset(sW,sH),LayoutOrder=2,BackgroundColor3=Library.SurfaceColor(),Parent=TF});
        Library:ApplyCorner(ST,sH/2);Library:ApplyStroke(ST,'SubtleOutlineColor');Library:AddToRegistry(ST,{BackgroundColor3='SurfaceColor',BorderColor3='SubtleOutlineColor'});
        local SK=Library:Create('Frame',{Name="SwitchKnob",Size=UDim2.fromOffset(kS,kS),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0,kS/2+(sH-kS)/2,0.5,0),BackgroundColor3=Library.FontColor(),Parent=ST});
        Library:ApplyCorner(SK,kS/2);Library:ApplyStroke(SK,'OutlineColor',0.5);Library:AddToRegistry(SK,{BackgroundColor3='FontColor',BorderColor3='OutlineColor'});
        local TR=Library:Create('TextButton',{Name="ToggleClickRegion",BackgroundTransparency=1,Text="",Size=UDim2.fromScale(1,1),Parent=TF,ZIndex=ST.ZIndex+10}); -- Ensure TR is on top of everything in ToggleFrame
        function Toggle:Display() local tKP=Toggle.Value and UDim2.new(1,-(kS/2+(sH-kS)/2),0.5,0)or UDim2.new(0,kS/2+(sH-kS)/2,0.5,0);local tTC=Toggle.Value and Library.AccentColor()or Library.SurfaceColor();local twI=TweenInfo.new(0.15,Enum.EasingStyle.Quint,Enum.EasingDirection.Out);TweenService:Create(SK,twI,{Position=tKP}):Play();TweenService:Create(ST,twI,{BackgroundColor3=tTC}):Play();local sr=Library.RegistryMap[ST];if sr then sr.Properties.BackgroundColor3=Toggle.Value and 'AccentColor'or'SurfaceColor'end end;
        function Toggle:OnChanged(F)Toggle.Changed=F;if F then F(Toggle.Value)end end;
        function Toggle:SetValue(B,SC)B=not not B;if Toggle.Value==B then return end;Toggle.Value=B;Toggle:Display();for _,A in ipairs(Toggle.Addons)do if A.Type=='KeyPicker'and A.SyncToggleState then A.Toggled=B;A:Update()end end;if not SC then Library:SafeCallback(Toggle.Callback,Toggle.Value);Library:SafeCallback(Toggle.Changed,Toggle.Value)end;Library:UpdateDependencyBoxes()end;
        TR.MouseButton1Click:Connect(function()if Library:MouseIsOverOpenedFrame() then return end;Toggle:SetValue(not Toggle.Value);Library:AttemptSave()end);
        if type(Info.Tooltip)=='string'then Library:AddToolTip(Info.Tooltip,TR)end;
        Toggle:Display();self:AddBlank(Info.BlankSize or (Library.IsMobile and 5 or 3)+2);self:Resize();
        Toggle.TextLabel=TL;Toggle.Container=self.Container;setmetatable(Toggle,BaseAddons);Toggles[Idx]=Toggle;Library:UpdateDependencyBoxes();return Toggle
    end;

    function Funcs:AddSlider(Idx, Info)
        assert(Info.Text and Info.Min~=nil and Info.Max~=nil and Info.Default~=nil and Info.Rounding~=nil, "AddSlider: Missing required fields")
        local sliderHeight = Library.IsMobile and 30 or 16; local valueBoxWidth = Library.IsMobile and 55 or 45;
        local Slider = { Value=Info.Default,Min=Info.Min,Max=Info.Max,Rounding=Info.Rounding,Type='Slider',Callback=Info.Callback or function()end,Suffix=Info.Suffix or"", ParentGroupbox=self };
        local labelTextSize = Library.IsMobile and 14 or 12; local valueTextSize = Library.IsMobile and 13 or 11;

        local HeaderFrame = Library:Create("Frame", {BackgroundTransparency=1, Size=UDim2.new(1,0,0,labelTextSize+2), Parent=self.Container})
        Library:Create("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, HorizontalAlignment=Enum.HorizontalAlignment.SpaceBetween, VerticalAlignment=Enum.VerticalAlignment.Bottom, Parent=HeaderFrame})
        Library:CreateLabel({Name="SliderLabel", FontType="UI", Size=UDim2.new(0.7,0,1,0), TextSize=labelTextSize,Text=Info.Text,TextXAlignment=Enum.TextXAlignment.Left, Parent=HeaderFrame, LayoutOrder=1});
        local ValueDisplay = Library:CreateLabel({Name="SliderValueDisplay", FontType="Code", Size=UDim2.new(0.3,0,1,0), TextSize=labelTextSize, Text="", TextXAlignment=Enum.TextXAlignment.Right, Parent=HeaderFrame, LayoutOrder=2});
        self:AddBlank(Library.IsMobile and 2 or 1);

        local SliderArea = Library:Create("Frame", {Name="SliderArea", BackgroundTransparency=1, Size=UDim2.new(1, Info.Compact and 0 or - (valueBoxWidth + 5), 0, sliderHeight), Parent=self.Container})
        if not Info.Compact then
            Library:Create("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,5), VerticalAlignment=Enum.VerticalAlignment.Center, Parent=self.Container})
            SliderArea.LayoutOrder = 1
        end
        
        local TrackOuter = Library:Create('Frame',{Name="SliderTrackOuter", BackgroundColor3=Library.SurfaceColor(), Size=UDim2.new(1,0,1,0), Parent=SliderArea});
        Library:ApplyCorner(TrackOuter,sliderHeight/2);Library:ApplyStroke(TrackOuter,'SubtleOutlineColor');Library:AddToRegistry(TrackOuter,{BackgroundColor3='SurfaceColor',BorderColor3='SubtleOutlineColor'});
        
        local Fill = Library:Create('Frame',{Name="SliderFill", BackgroundColor3=Library.AccentColor(),Size=UDim2.new(0,0,1,0),Parent=TrackOuter});
        Library:ApplyCorner(Fill,sliderHeight/2);Library:AddToRegistry(Fill,{BackgroundColor3='AccentColor'});
        
        local Knob = Library:Create("Frame", {Name="SliderKnob", BackgroundColor3=Library.FontColor(), Size=UDim2.fromOffset(sliderHeight*0.8, sliderHeight*0.8), AnchorPoint=Vector2.new(0.5,0.5), ZIndex=TrackOuter.ZIndex+1, Parent=Fill})
        Library:ApplyCorner(Knob, sliderHeight*0.4); Library:ApplyStroke(Knob, "OutlineColor", 0.5); Library:AddToRegistry(Knob, {BackgroundColor3='FontColor', BorderColor3='OutlineColor'})

        local ValueInputBox = nil
        if not Info.Compact then
            ValueInputBox = Library:Create("TextBox",{Name="SliderValueInput", FontType="Code", TextColor3=Library.FontColor(), BackgroundColor3=Library.SurfaceColor(), Size=UDim2.fromOffset(valueBoxWidth, sliderHeight+4), TextSize=valueTextSize, TextXAlignment=Enum.TextXAlignment.Center, Parent=self.Container, LayoutOrder=2, ClearTextOnFocus=false})
            Library:ApplyCorner(ValueInputBox); Library:ApplyStroke(ValueInputBox, 'SubtleOutlineColor');
            Library:AddToRegistry(ValueInputBox, {TextColor3='FontColor', BackgroundColor3='SurfaceColor', BorderColor3='SubtleOutlineColor'})
            ValueInputBox.FocusLost:Connect(function(enterPressed)
                if enterPressed then local num=tonumber(ValueInputBox.Text); if num then Slider:SetValue(num) end end
                Slider:Display() -- Refresh to show formatted value
                Library:AttemptSave()
            end)
        end
        
        function Slider:RoundValue(val) return tonumber(string.format('%.'..Slider.Rounding..'f',val)) or val end
        function Slider:Display()
            local percent = (Slider.Value-Slider.Min)/(Slider.Max-Slider.Min)
            if Slider.Max-Slider.Min == 0 then percent = 0.5 end -- Handle min=max case
            percent = math.clamp(percent,0,1)
            Fill.Size=UDim2.new(percent,0,1,0)
            Knob.Position = UDim2.new(1,0,0.5,0) -- Position knob at the end of the fill
            local displayVal = Slider:RoundValue(Slider.Value)
            ValueDisplay.Text = tostring(displayVal) .. Slider.Suffix
            if ValueInputBox and not ValueInputBox:IsFocused() then ValueInputBox.Text = tostring(displayVal) end
        end
        function Slider:SetValue(val, skipCb)
            local oldVal = Slider.Value
            Slider.Value = math.clamp(self:RoundValue(val), Slider.Min, Slider.Max)
            Slider:Display()
            if not skipCb and Slider.Value ~= oldVal then Library:SafeCallback(Slider.Callback,Slider.Value); Library:SafeCallback(Slider.Changed,Slider.Value) end
        end
        function Slider:OnChanged(F) Slider.Changed=F; if F then F(Slider.Value) end end

        local dragging = false
        TrackOuter.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                local newX = math.clamp(input.Position.X - TrackOuter.AbsolutePosition.X, 0, TrackOuter.AbsoluteSize.X)
                local val = Slider.Min + (newX/TrackOuter.AbsoluteSize.X)*(Slider.Max-Slider.Min)
                Slider:SetValue(val)
                local moveConn,endConn
                moveConn=UserInputService.InputChanged:Connect(function(subInput) if dragging and (subInput.UserInputType==Enum.UserInputType.MouseMovement or subInput.UserInputType==Enum.UserInputType.Touch) then local nX=math.clamp(subInput.Position.X-TrackOuter.AbsolutePosition.X,0,TrackOuter.AbsoluteSize.X); local v=Slider.Min+(nX/TrackOuter.AbsoluteSize.X)*(Slider.Max-Slider.Min);Slider:SetValue(v)end end)
                endConn=UserInputService.InputEnded:Connect(function()dragging=false;moveConn:Disconnect();endConn:Disconnect();Library:AttemptSave()end)
                Library:GiveSignal(moveConn);Library:GiveSignal(endConn)
            end
        end)
        if type(Info.Tooltip)=='string'then Library:AddToolTip(Info.Tooltip,TrackOuter)end;
        Slider:Display();Options[Idx]=Slider;
        self:AddBlank(Info.BlankSize or (Library.IsMobile and 6 or 4)); self:Resize(); return Slider;
    end;

    function Funcs:AddDropdown(Idx, Info)
        if Info.SpecialType=='Player' then Info.Values=GetPlayersString();Info.AllowNull=true elseif Info.SpecialType=='Team'then Info.Values=GetTeamsString();Info.AllowNull=true end
        assert(Info.Values,'AddDropdown: Missing value list.');assert(Info.AllowNull or Info.Default,'AddDropdown: Missing default value.');
        local ddHeight = Library.IsMobile and 30 or 22; local itemHeight = Library.IsMobile and 28 or 20;
        local Dropdown={Values=Info.Values,Value=Info.Multi and {} or (Info.AllowNull and nil or Info.Values[1]),Multi=Info.Multi,Type='Dropdown',SpecialType=Info.SpecialType,Callback=Info.Callback or function()end, ParentGroupbox=self,IsOpen=false};
        local labelTextSize=Library.IsMobile and 14 or 12;

        if Info.Text and Info.Text~="" then Library:CreateLabel({Size=UDim2.new(1,0,0,labelTextSize+2),TextSize=labelTextSize,Text=Info.Text,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Bottom,Parent=self.Container});self:AddBlank(1)end
        
        local Outer=Library:Create('TextButton',{Name="DropdownOuter",AutoButtonColor=false,BackgroundColor3=Library.SurfaceColor(),Size=UDim2.new(1,-4,0,ddHeight),Text="",Parent=self.Container});
        Library:ApplyCorner(Outer);Library:ApplyStroke(Outer,'SubtleOutlineColor');Library:AddToRegistry(Outer,{BackgroundColor3='SurfaceColor',BorderColor3='SubtleOutlineColor'});
        Library:OnHighlight(Outer,Outer,{BorderColor3='AccentColor'},{BorderColor3='SubtleOutlineColor'});
        if type(Info.Tooltip)=='string'then Library:AddToolTip(Info.Tooltip,Outer)end

        local ItemListLabel=Library:CreateLabel({Name="DropdownSelectedItems",FontType="UI",Position=UDim2.new(0,Library.IsMobile and 8 or 5,0,0),Size=UDim2.new(1,-(Library.IsMobile and 28 or 22),1,0),TextSize=Library.IsMobile and 14 or 13,Text="--",TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,Parent=Outer});
        local Arrow=Library:Create('ImageLabel',{Name="DropdownArrow",AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-(Library.IsMobile and 8 or 5),0.5,0),Size=UDim2.fromOffset(Library.IsMobile and 16 or 12,Library.IsMobile and 16 or 12),BackgroundTransparency=1,Image=Library.DropdownArrowImage,ImageColor3=Library.FontColor(),Rotation=0,Parent=Outer});
        Library:AddToRegistry(Arrow,{ImageColor3='FontColor'});

        local MAX_ITEMS_VISIBLE = Library.IsMobile and 5 or 7;
        local searchBoxHeight = Library.IsMobile and 30 or 24;
        local ListOuter=Library:Create('Frame',{Name="DropdownList",BackgroundColor3=Library.SurfaceColor(),Size=UDim2.new(),Visible=false,ZIndex=1500,Parent=ScreenGui,ClipsDescendants=true}); -- Size set dynamically
        Library:ApplyCorner(ListOuter,Library.CornerRadius-2);Library:ApplyStroke(ListOuter,'OutlineColor');Library:AddToRegistry(ListOuter,{BackgroundColor3='SurfaceColor',BorderColor3='OutlineColor'});
        
        local SearchBox = nil; local ScrollingFramePaddingTop = 0;
        if Info.Searchable then
            ScrollingFramePaddingTop = searchBoxHeight + (Library.IsMobile and 3 or 2)
            SearchBox = Library:Create("TextBox", {Name="DropdownSearch", FontType="UI", BackgroundColor3=Library.BackgroundColor(), Size=UDim2.new(1, -8, 0, searchBoxHeight), Position=UDim2.new(0,4,0,Library.IsMobile and 3 or 2), TextColor3=Library.FontColor(), PlaceholderText="Search...", PlaceholderColor3=Color3.new(Library.FontColor().R,Library.FontColor().G,Library.FontColor().B,0.5), TextSize=Library.IsMobile and 14 or 12, Parent=ListOuter})
            Library:ApplyCorner(SearchBox, 3); Library:ApplyStroke(SearchBox, "SubtleOutlineColor");
            Library:AddToRegistry(SearchBox, {BackgroundColor3="BackgroundColor", BorderColor3="SubtleOutlineColor", TextColor3="FontColor", PlaceholderColor3=function()local c=Library.GetColor('FontColor');return Color3.new(c.R,c.G,c.B,0.5)end})
        end

        local Scrolling=Library:Create('ScrollingFrame',{Name="DropdownScroll",BackgroundTransparency=1,Position=UDim2.new(0,0,0,ScrollingFramePaddingTop),Size=UDim2.new(1,0,1,-ScrollingFramePaddingTop),CanvasSize=UDim2.new(),ScrollBarThickness=Library.IsMobile and 6 or 4,ScrollBarImageColor3=Library.ScrollBarColor(),Parent=ListOuter});
        Library:AddToRegistry(Scrolling,{ScrollBarImageColor3='ScrollBarColor'});
        local ListLayout=Library:Create('UIListLayout',{Padding=UDim.new(0,0),FillDirection=Enum.FillDirection.Vertical,Parent=Scrolling});

        local function UpdateItemListText()
            local str="--"
            if Dropdown.Multi then local t={};for v,_ in pairs(Dropdown.Value)do table.insert(t,tostring(v))end;if #t>0 then str=table.concat(t,", ")end
            elseif Dropdown.Value~=nil then str=tostring(Dropdown.Value) end
            ItemListLabel.Text=str
        end
        function Dropdown:BuildDropdownList(filterText)
            for _,c in ipairs(Scrolling:GetChildren())do if c~=ListLayout then c:Destroy()end end;
            local count=0; local currentValues = Info.Values
            if Info.SpecialType == 'Player' then currentValues = GetPlayersString() -- Refresh player list
            elseif Info.SpecialType == 'Team' then currentValues = GetTeamsString() end -- Refresh team list
            Dropdown.Values = currentValues -- Update stored values

            for _,val in ipairs(Dropdown.Values)do
                if filterText and filterText~="" and not string.find(string.lower(tostring(val)),string.lower(filterText)) then continue end
                count=count+1
                local ItemBtn=Library:Create('TextButton',{Name=tostring(val).."Item",AutoButtonColor=false,BackgroundColor3=Library.SurfaceColor(),Size=UDim2.new(1,0,0,itemHeight),Text="",Parent=Scrolling});
                local ItemLbl=Library:CreateLabel({Name="ItemLabel",FontType="UI",Position=UDim2.new(0,Library.IsMobile and 10 or 8,0,0),Size=UDim2.new(1,-(Library.IsMobile and 26 or 20),1,0),Text=tostring(val),TextXAlignment=Enum.TextXAlignment.Left,TextSize=Library.IsMobile and 14 or 13,Parent=ItemBtn});
                local isSelected = (Dropdown.Multi and Dropdown.Value[val]) or (not Dropdown.Multi and Dropdown.Value==val)
                if isSelected then ItemLbl.TextColor3=Library.AccentColor(); ItemLbl.Font=Library.Font("Bold") else ItemLbl.TextColor3=Library.FontColor(); ItemLbl.Font=Library.Font("UI") end
                Library:AddToRegistry(ItemBtn,{BackgroundColor3='SurfaceColor'}); Library:AddToRegistry(ItemLbl,{TextColor3=function() return isSelected and 'AccentColor' or 'FontColor' end, Font=function() return isSelected and Library.Font("Bold") or Library.Font("UI") end});
                
                if Dropdown.Multi and isSelected then -- Add checkmark for multi-select
                    local Check = Library:Create("ImageLabel", {Size=UDim2.fromOffset(itemHeight*0.6, itemHeight*0.6), Position=UDim2.new(1, -itemHeight*0.7, 0.5,0), AnchorPoint=Vector2.new(1,0.5), BackgroundTransparency=1, Image=Library.CheckmarkImage, ImageColor3=Library.AccentColor(), Parent=ItemBtn})
                    Library:AddToRegistry(Check, {ImageColor3='AccentColor'})
                end

                ItemBtn.MouseEnter:Connect(function()ItemBtn.BackgroundColor3=Library.BackgroundColor()end)
                ItemBtn.MouseLeave:Connect(function()ItemBtn.BackgroundColor3=Library.SurfaceColor()end)
                ItemBtn.MouseButton1Click:Connect(function()
                    if Dropdown.Multi then Dropdown.Value[val]=not Dropdown.Value[val] else Dropdown.Value=(Dropdown.Value==val and Info.AllowNull and nil or val) end
                    UpdateItemListText(); Dropdown:BuildDropdownList(filterText); -- Rebuild to update selection visuals
                    Library:SafeCallback(Dropdown.Callback,Dropdown.Value);Library:SafeCallback(Dropdown.Changed,Dropdown.Value);Library:AttemptSave();
                    if not Dropdown.Multi then Dropdown:CloseDropdown() end -- Close on select for single
                end)
            end
            local totalItemHeight = count*itemHeight; Scrolling.CanvasSize=UDim2.fromOffset(0,totalItemHeight);
            local listHeight = math.min(totalItemHeight,MAX_ITEMS_VISIBLE*itemHeight) + ScrollingFramePaddingTop + (Library.IsMobile and 8 or 4) -- Padding
            ListOuter.Size=UDim2.new(0,Outer.AbsoluteSize.X,0,listHeight)
            ListOuter.Position=UDim2.fromOffset(Outer.AbsolutePosition.X,Outer.AbsolutePosition.Y+Outer.AbsoluteSize.Y+2)
            -- Adjust if off screen
            if ListOuter.Position.Y.Offset + ListOuter.AbsoluteSize.Y > ScreenGui.AbsoluteSize.Y then ListOuter.Position = UDim2.fromOffset(Outer.AbsolutePosition.X, Outer.AbsolutePosition.Y - ListOuter.AbsoluteSize.Y - 2) end
            if ListOuter.Position.X.Offset + ListOuter.AbsoluteSize.X > ScreenGui.AbsoluteSize.X then ListOuter.Position = UDim2.new(ListOuter.Position.X.Scale, ScreenGui.AbsoluteSize.X - ListOuter.AbsoluteSize.X -5, ListOuter.Position.Y.Scale, ListOuter.Position.Y.Offset) end
            if ListOuter.Position.X.Offset < 5 then ListOuter.Position = UDim2.new(ListOuter.Position.X.Scale, 5, ListOuter.Position.Y.Scale, ListOuter.Position.Y.Offset) end
        end
        if SearchBox then SearchBox:GetPropertyChangedSignal("Text"):Connect(function() Dropdown:BuildDropdownList(SearchBox.Text) end) end
        
        function Dropdown:OpenDropdown() if Dropdown.IsOpen then return end; Dropdown.IsOpen=true;
            for frame,_ in pairs(Library.OpenedFrames)do if frame~=ListOuter and frame.Name=="DropdownList" then frame.Visible=false;Library.OpenedFrames[frame]=nil end end -- Close other dropdowns
            if SearchBox then SearchBox.Text = "" end; Dropdown:BuildDropdownList(); ListOuter.Visible=true; Library.OpenedFrames[ListOuter]=true;
            TweenService:Create(Arrow,TweenInfo.new(0.2),{Rotation=180}):Play(); Outer.BorderColor3=Library.AccentColor() end
        function Dropdown:CloseDropdown() if not Dropdown.IsOpen then return end; Dropdown.IsOpen=false;
            ListOuter.Visible=false;Library.OpenedFrames[ListOuter]=nil;
            TweenService:Create(Arrow,TweenInfo.new(0.2),{Rotation=0}):Play(); Outer.BorderColor3=Library.SubtleOutlineColor() end
        Outer.MouseButton1Click:Connect(function()if Dropdown.IsOpen then Dropdown:CloseDropdown()else Dropdown:OpenDropdown()end end)
        Library:GiveSignal(UserInputService.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 and Dropdown.IsOpen and not Library:IsMouseOverFrame(ListOuter)and not Library:IsMouseOverFrame(Outer)then Dropdown:CloseDropdown()end end))
        
        function Dropdown:OnChanged(F)Dropdown.Changed=F;if F then F(Dropdown.Value)end end
        function Dropdown:SetValue(V) local oldV=Dropdown.Value; if Dropdown.Multi then local nT={};for _,vInV in ipairs(V or {})do if table.find(Dropdown.Values,vInV)then nT[vInV]=true end end;Dropdown.Value=nT else if V==nil and Info.AllowNull then Dropdown.Value=nil elseif table.find(Dropdown.Values,V)then Dropdown.Value=V end end; UpdateItemListText(); if Dropdown.Value~=oldV then Library:SafeCallback(Dropdown.Callback,Dropdown.Value);Library:SafeCallback(Dropdown.Changed,Dropdown.Value)end end
        UpdateItemListText(); Options[Idx]=Dropdown;
        self:AddBlank(); self:Resize(); return Dropdown;
    end;


    function Funcs:AddDependencyBox() warn("DependencyBox needs update"); return self end;
    BaseGroupbox = Funcs;
end;

do -- Create Other UI (Watermark, Keybinds, Notifications already updated in previous step)
    -- Ensure their ZIndex is high enough
    Library.NotificationArea.ZIndex = 2000
    Library.Watermark.ZIndex = 1500
    Library.KeybindFrame.ZIndex = 1600
end;

-- Window and Main Toggle Logic
function Library:CreateWindow(...)
    local Args={...};local Config={AnchorPoint=Vector2.zero};if type(Args[1])=='table'then Config=Args[1]else Config.Title=Args[1];Config.AutoShow=Args[2]or false end
    Config.Title=Config.Title or 'VTUI';Config.TabPadding=Config.TabPadding or(Library.IsMobile and 2 or 4);Config.MenuFadeTime=Config.MenuFadeTime or 0.2;
    Config.Size=Config.Size or(Library.IsMobile and UDim2.new(0.95,0,0.85,0)or UDim2.fromOffset(580,520)); -- Adjusted size
    Config.Position=Config.Position or(Library.IsMobile and UDim2.fromScale(0.5,0.5)or UDim2.fromOffset(200,150));
    Config.Center=Config.Center or Library.IsMobile;if Config.Center then Config.AnchorPoint=Vector2.new(0.5,0.5);Config.Position=UDim2.fromScale(0.5,0.5)end
    local Window={Tabs={},IsMinimized=false,OriginalSize=Config.Size,OriginalPosition=Config.Position,Holder=nil};

    local Outer=Library:Create('Frame',{Name="MainWindowOuter",AnchorPoint=Config.AnchorPoint,BackgroundColor3=Library.BackgroundColor(),Position=Config.Position,Size=Config.Size,Visible=false,ZIndex=100,Parent=ScreenGui});
    Library:ApplyCorner(Outer,Library.CornerRadius+2);Library:ApplyStroke(Outer,'AccentColor',1.5);Library:AddToRegistry(Outer,{BackgroundColor3='BackgroundColor',BorderColor3='AccentColor'});
    Window.Holder = Outer

    local titleH=Library.IsMobile and 40 or 32;
    local Header=Library:Create("Frame",{Name="WindowHeader",BackgroundColor3=Library.MainColor(),Size=UDim2.new(1,0,0,titleH),ZIndex=Outer.ZIndex+1,Parent=Outer});
    Library:ApplyCorner(Header,Vector2.new(Library.CornerRadius+2,0)); Library:AddToRegistry(Header,{BackgroundColor3='MainColor'});
    Library:MakeDraggable(Outer, Header, titleH);

    local TitleLbl=Library:CreateLabel({Name="WindowTitle",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.5,0),Size=UDim2.new(1,-(titleH*2+20),1,0),Text=Config.Title,FontType="Title",TextSize=Library.IsMobile and 18 or 16,Parent=Header});
    local MinBtn=Library:Create("TextButton",{Name="MinimizeButton",Text="_",FontType="Bold",TextSize=Library.IsMobile and 26 or 22,TextColor3=Library.FontColor(),BackgroundTransparency=1,Size=UDim2.fromOffset(titleH*0.8,titleH*0.8),AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-(titleH*0.8+10),0.5,0),Parent=Header});
    Library:AddToRegistry(MinBtn,{TextColor3='FontColor'});MinBtn.MouseEnter:Connect(function()MinBtn.TextColor3=Library.AccentColor()end);MinBtn.MouseLeave:Connect(function()MinBtn.TextColor3=Library.FontColor()end);
    local CloseBtn=Library:Create("TextButton",{Name="CloseButton",Text="X",FontType="Bold",TextSize=Library.IsMobile and 22 or 18,TextColor3=Library.FontColor(),BackgroundTransparency=1,Size=UDim2.fromOffset(titleH*0.8,titleH*0.8),AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-5,0.5,0),Parent=Header});
    Library:AddToRegistry(CloseBtn,{TextColor3='FontColor'});CloseBtn.MouseEnter:Connect(function()CloseBtn.TextColor3=Library.RiskColor()end);CloseBtn.MouseLeave:Connect(function()CloseBtn.TextColor3=Library.FontColor()end);CloseBtn.MouseButton1Click:Connect(function()Library:Toggle()end);

    local ContentArea=Library:Create('Frame',{Name="MainContentArea",BackgroundColor3=Library.BackgroundColor(),Position=UDim2.new(0,0,0,titleH),Size=UDim2.new(1,0,1,-titleH),ZIndex=Outer.ZIndex,Parent=Outer,ClipsDescendants=true});
    Library:AddToRegistry(ContentArea,{BackgroundColor3='BackgroundColor'});
    local SectionOuter=Library:Create('Frame',{Name="MainSectionOuter",BackgroundColor3=Library.SurfaceColor(),Position=UDim2.new(0,8,0,4),Size=UDim2.new(1,-16,1,-12),ZIndex=ContentArea.ZIndex+1,Parent=ContentArea});
    Library:ApplyCorner(SectionOuter,Library.CornerRadius);Library:ApplyStroke(SectionOuter,'SubtleOutlineColor');Library:AddToRegistry(SectionOuter,{BackgroundColor3='SurfaceColor',BorderColor3='SubtleOutlineColor'});
    local tabAreaH=Library.IsMobile and 32 or 28;
    local TabArea=Library:Create('Frame',{Name="TabArea",BackgroundTransparency=1,Position=UDim2.new(0,4,0,4),Size=UDim2.new(1,-8,0,tabAreaH),ZIndex=SectionOuter.ZIndex+1,Parent=SectionOuter});
    local TabListLayout=Library:Create('UIListLayout',{Padding=UDim.new(0,Config.TabPadding),FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,Parent=TabArea});
    local TabContainer=Library:Create('Frame',{Name="TabContentContainer",BackgroundColor3=Library.BackgroundColor(),Position=UDim2.new(0,4,0,tabAreaH+8),Size=UDim2.new(1,-8,1,-(tabAreaH+12)),ZIndex=SectionOuter.ZIndex+1,Parent=SectionOuter,ClipsDescendants=true});
    Library:ApplyCorner(TabContainer,Library.CornerRadius-2);Library:ApplyStroke(TabContainer,'SubtleOutlineColor');Library:AddToRegistry(TabContainer,{BackgroundColor3='BackgroundColor',BorderColor3='SubtleOutlineColor'});
    
    function Window:SetWindowTitle(T)TitleLbl.Text=T end;
    function Window:ToggleMinimize()self.IsMinimized=not self.IsMinimized;
        if self.IsMinimized then self.OriginalSize=Outer.Size;self.OriginalPosition=Outer.Position;Outer.Size=UDim2.fromOffset(Library.IsMobile and 180 or 220,titleH);ContentArea.Visible=false;MinBtn.Text="□";TitleLbl.TextXAlignment=Enum.TextXAlignment.Left;TitleLbl.Position=UDim2.new(0,10,0.5,0);TitleLbl.Size=UDim2.new(1,-(titleH*2+25),1,0);
            local sW,sH=ScreenGui.AbsoluteSize.X,ScreenGui.AbsoluteSize.Y;local bW,bH=Outer.AbsoluteSize.X,Outer.AbsoluteSize.Y;local cX,cY=Outer.AbsolutePosition.X,Outer.AbsolutePosition.Y;Outer.Position=UDim2.fromOffset(math.clamp(cX,0,sW-bW),math.clamp(cY,0,sH-bH))
        else Outer.Size=self.OriginalSize;Outer.Position=self.OriginalPosition;ContentArea.Visible=true;MinBtn.Text="_";TitleLbl.TextXAlignment=Enum.TextXAlignment.Center;TitleLbl.Position=UDim2.new(0.5,0,0.5,0);TitleLbl.Size=UDim2.new(1,-(titleH*2+20),1,0)end end
    MinBtn.MouseButton1Click:Connect(function()Window:ToggleMinimize()end);

    function Window:AddTab(Name)
        local Tab={Groupboxes={},Tabboxes={},ParentWindow=Window};local tabTxtSize=Library.IsMobile and 14 or 13;
        local TabBtn=Library:Create('TextButton',{Name=Name.."TabButton",AutoButtonColor=false,BackgroundColor3=Library.SurfaceColor(),Size=UDim2.new(0,0,1,0),Text="",ZIndex=TabArea.ZIndex+1,Parent=TabArea});
        Library:ApplyCorner(TabBtn,Vector2.new(Library.CornerRadius-2,0));Library:ApplyStroke(TabBtn,'SubtleOutlineColor',1);Library:AddToRegistry(TabBtn,{BackgroundColor3='SurfaceColor',BorderColor3='SubtleOutlineColor'});
        local TabBtnLbl=Library:CreateLabel({Name="TabButtonLabel",FontType="UI",Size=UDim2.new(1,-10,1,0),Position=UDim2.new(0,5,0,0),Text=Name,TextSize=tabTxtSize,ZIndex=TabBtn.ZIndex+1,Parent=TabBtn});
        task.defer(function() local tW=TabBtnLbl.TextBounds.X;TabBtn.Size=UDim2.new(0,tW+(Library.IsMobile and 20 or 16),1,0) end)
        local TabFrame=Library:Create('Frame',{Name=Name.."TabContent",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Visible=false,ZIndex=TabContainer.ZIndex+1,Parent=TabContainer});
        local sP=Library.IsMobile and 4 or 8;local cP=Library.IsMobile and 0 or 8;local nC=Library.IsMobile and 1 or 2;
        local sFS=Library.IsMobile and 1 or(0.5-(cP/(2*TabFrame.AbsoluteSize.X)));local sFO=Library.IsMobile and-(sP*2)or-(sP+cP/2);
        local LS=Library:Create('ScrollingFrame',{Name="LeftSideScroll",BackgroundTransparency=1,Position=UDim2.new(0,sP,0,sP),Size=UDim2.new(sFS,sFO,1,-(sP*2)),CanvasSize=UDim2.new(),ScrollBarThickness=Library.IsMobile and 6 or 4,ScrollBarImageColor3=Library.ScrollBarColor(),ZIndex=TabFrame.ZIndex+1,Parent=TabFrame});
        Library:Create('UIListLayout',{Name="Layout",Padding=UDim.new(0,Library.IsMobile and 6 or 8),FillDirection=Enum.FillDirection.Vertical,HorizontalAlignment=Enum.HorizontalAlignment.Center,Parent=LS});Library:AddToRegistry(LS,{ScrollBarImageColor3='ScrollBarColor'});
        local RS=nil;if not Library.IsMobile then RS=Library:Create('ScrollingFrame',{Name="RightSideScroll",BackgroundTransparency=1,Position=UDim2.new(0.5,cP/2,0,sP),Size=UDim2.new(sFS,sFO,1,-(sP*2)),CanvasSize=UDim2.new(),ScrollBarThickness=4,ScrollBarImageColor3=Library.ScrollBarColor(),ZIndex=TabFrame.ZIndex+1,Parent=TabFrame});Library:Create('UIListLayout',{Name="Layout",Padding=UDim.new(0,8),Parent=RS});Library:AddToRegistry(RS,{ScrollBarImageColor3='ScrollBarColor'})end
        for _,S in ipairs({LS,RS})do if S and S:FindFirstChild("Layout")then S.Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()S.CanvasSize=UDim2.fromOffset(0,S.Layout.AbsoluteContentSize.Y)end)end end;
        local defTabC=Library.SurfaceColor();local actTabC=Library.BackgroundColor();
        function Tab:ShowTab()for _,oT in pairs(Window.Tabs)do oT:HideTab()end;TabBtn.BackgroundColor3=actTabC;TabFrame.Visible=true;local r=Library.RegistryMap[TabBtn];if r then r.Properties.BackgroundColor3='BackgroundColor'end end;
        function Tab:HideTab()TabBtn.BackgroundColor3=defTabC;TabFrame.Visible=false;local r=Library.RegistryMap[TabBtn];if r then r.Properties.BackgroundColor3='SurfaceColor'end end;
        TabBtn.MouseButton1Click:Connect(function()if not TabFrame.Visible then Tab:ShowTab()end end);
        TabBtn.MouseEnter:Connect(function()if not TabFrame.Visible then TabBtn.BackgroundColor3=Library:GetLighterColor(defTabC,1.1)end end);TabBtn.MouseLeave:Connect(function()if not TabFrame.Visible then TabBtn.BackgroundColor3=defTabC end end);
        function Tab:AddGroupbox(Info) local GB={ParentTab=Tab};local tP=(Library.IsMobile or Info.Side==1)and LS or RS;if not tP then tP=LS end;local gP=Library.IsMobile and 6 or 8;local gTH=Library.IsMobile and 24 or 20;
            local BO=Library:Create('Frame',{Name=Info.Name.."GroupboxOuter",BackgroundColor3=Library.BackgroundColor(),Size=UDim2.new(1,0,0,50),ZIndex=tP.ZIndex+1,Parent=tP});
            Library:ApplyCorner(BO,Library.CornerRadius-2);Library:ApplyStroke(BO,'SubtleOutlineColor');Library:AddToRegistry(BO,{BackgroundColor3='BackgroundColor',BorderColor3='SubtleOutlineColor'});
            local HL=Library:Create('Frame',{BackgroundColor3=Library.AccentColor(),Size=UDim2.new(1,0,0,3),ZIndex=BO.ZIndex+1,Parent=BO});Library:ApplyCorner(HL,Vector2.new(Library.CornerRadius-2,0));Library:AddToRegistry(HL,{BackgroundColor3='AccentColor'});
            local GBL=Library:CreateLabel({Name="GroupboxTitle",FontType="UI",Size=UDim2.new(1,-gP*2,0,gTH),Position=UDim2.new(0,gP,0,3),Text=Info.Name,TextSize=Library.IsMobile and 15 or 14,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=BO.ZIndex+1,Parent=BO});
            local Cnt=Library:Create('Frame',{Name="GroupboxContent",BackgroundTransparency=1,Position=UDim2.new(0,gP,0,gTH+3+(Library.IsMobile and 3 or 2)),Size=UDim2.new(1,-gP*2,1,-(gTH+3+(Library.IsMobile and 3 or 2)+gP)),ZIndex=BO.ZIndex,Parent=BO});
            local Lyt=Library:Create('UIListLayout',{Name="Layout",FillDirection=Enum.FillDirection.Vertical,Padding=UDim.new(0,Library.IsMobile and 4 or 3),Parent=Cnt});
            function GB:Resize()task.defer(function()local cH=Lyt.AbsoluteContentSize.Y;local tH=gTH+3+(Library.IsMobile and 3 or 2)+cH+gP;BO.Size=UDim2.new(1,0,0,tH)end)end;
            GB.Container=Cnt;setmetatable(GB,BaseGroupbox);GB:AddBlank(1);GB:Resize();Tab.Groupboxes[Info.Name]=GB;return GB end;
        function Tab:AddLeftGroupbox(N)return Tab:AddGroupbox({Name=N,Side=1})end;function Tab:AddRightGroupbox(N)if Library.IsMobile then warn("AddRightGroupbox on mobile, adds to left.")end;return Tab:AddGroupbox({Name=N,Side=Library.IsMobile and 1 or 2})end;
        function Tab:AddTabbox(Info) warn("Tabbox needs full redesign"); local tB=Tab:AddLeftGroupbox(Info.Name or "Tabbox"); function tB:AddTab(tN) warn("Mocked Tabbox:AddTab"); local mIT={Container=tB.Container};setmetatable(mIT,BaseGroupbox);return mIT end;return tB end
        Window.Tabs[Name]=Tab;if #TabArea:GetChildren()==1 then Tab:ShowTab()end;return Tab
    end;

    local ModalEl=Library:Create('TextButton',{Name="ModalBlocker",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Visible=true,Text='',Modal=false,ZIndex=0,Parent=ScreenGui});
    local TCache={};local Toggled=false;local Fading=false;

    -- Create Custom Cursor ImageLabel (initially hidden)
    Library.CustomCursorImageLabel = Library:Create("ImageLabel", {
        Name = "VTUI_CustomCursor", Size = UDim2.fromOffset(20,20), -- Adjust size as needed
        BackgroundTransparency = 1, Image = Library.CursorImage, AnchorPoint = Vector2.new(0,0), -- Top-left anchor for mouse pos
        ImageColor3 = Library.AccentColor(), ZIndex = ScreenGui.DisplayOrder -1, -- Just below top
        Visible = false, Parent = ScreenGui
    })
    Library:AddToRegistry(Library.CustomCursorImageLabel, {ImageColor3 = 'AccentColor'})


    function Library:Toggle()
        if Fading or(Window and Window.IsMinimized)then return end;
        local FT=Config.MenuFadeTime;Fading=true;Toggled=not Toggled;ModalEl.Modal=Toggled;
        if Toggled then Outer.Visible=true;Library.CustomCursorImageLabel.Visible=true;UserInputService.MouseIconEnabled=false;
            Library.CursorUpdateConn = Library.CursorUpdateConn or RenderStepped:Connect(function()
                if Library.CustomCursorImageLabel and Library.CustomCursorImageLabel.Visible then
                    Library.CustomCursorImageLabel.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
                end
            end)
            Library:GiveSignal(Library.CursorUpdateConn) -- Ensure it's managed
        else UserInputService.MouseIconEnabled=true;Library.CustomCursorImageLabel.Visible=false;
            if Library.CursorUpdateConn and Library.CursorUpdateConn.Connected then
                -- Library.CursorUpdateConn:Disconnect() -- Don't disconnect, just hide cursor. Signal will be cleaned on Unload.
            end
        end;
        for _,D in ipairs(Outer:GetDescendants())do if D:IsA("GuiObject")then local P={};if D:IsA('ImageLabel')or D:IsA("ImageButton")then table.insert(P,'ImageTransparency');table.insert(P,'BackgroundTransparency')elseif D:IsA('TextLabel')or D:IsA('TextBox')or D:IsA("TextButton")then table.insert(P,'TextTransparency');table.insert(P,'BackgroundTransparency')elseif D:IsA('Frame')or D:IsA('ScrollingFrame')then table.insert(P,'BackgroundTransparency')elseif D:IsA('UIStroke')then table.insert(P,'Transparency')end;local C=TCache[D];if not C then C={};TCache[D]=C end;for _,Pr in ipairs(P)do if C[Pr]==nil then C[Pr]=D[Pr]end;if C[Pr]==1 and Toggled==false then continue end;local tT=Toggled and C[Pr]or 1;if D[Pr]~=tT then TweenService:Create(D,TweenInfo.new(FT,Enum.EasingStyle.Linear),{[Pr]=tT}):Play()end end end end;
        task.wait(FT);if not Toggled then Outer.Visible=false end;Fading=false
    end
    Library:GiveSignal(UserInputService.InputBegan:Connect(function(I,P)if P then return end;local tK=Library.ToggleKeybind and Library.ToggleKeybind.Value;if tK and I.UserInputType==Enum.UserInputType.Keyboard and I.KeyCode.Name==tK then task.spawn(Library.Toggle)elseif I.KeyCode==Enum.KeyCode.RightControl or I.KeyCode==Enum.KeyCode.Insert or(I.KeyCode==Enum.KeyCode.RightShift and not GuiService:GetFocusedTextBox())then task.spawn(Library.Toggle)end end))
    if Config.AutoShow then task.spawn(Library.Toggle)end;
    return Window;
end;

local function OnPlayerChange() local PL=GetPlayersString();for _,V in pairs(Options)do if V and V.Type=='Dropdown'and V.SpecialType=='Player'then V:SetValues(PL)end end end;
Players.PlayerAdded:Connect(OnPlayerChange);Players.PlayerRemoving:Connect(OnPlayerChange);
Library:SetTheme(Library.CurrentTheme)
getgenv().Library = Library
return Library
