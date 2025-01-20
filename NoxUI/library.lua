-- Tạo thư viện UI
local NoxUI = {}
NoxUI.__index = NoxUI

function NoxUI:CreateMenu(config)
    -- Tạo menu chính
    local Menu = {}
    setmetatable(Menu, NoxUI)

    -- Tạo ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NoxUI_Screen"
    ScreenGui.Parent = game.CoreGui

    -- **Main Frame**
    local MainFrame = Instance.new("Frame")
    MainFrame.Parent = ScreenGui
    MainFrame.Size = UDim2.new(0, 400, 0, 500)
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
    MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Visible = true

    -- **Header**
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Parent = MainFrame
    Header.Size = UDim2.new(1, 0, 0, 40)
    Header.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Parent = Header
    Title.Size = UDim2.new(1, -50, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.Text = config.Title or "NoxUI For Mobile"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 18
    Title.TextXAlignment = Enum.TextXAlignment.Left

    -- **Close Button**
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Parent = Header
    CloseButton.Size = UDim2.new(0, 40, 1, 0)
    CloseButton.Position = UDim2.new(1, -50, 0, 0)
    CloseButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    CloseButton.Font = Enum.Font.Gotham
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 18

    -- **Menu Container (Tabs)**
    local TabContainer = Instance.new("Frame")
    TabContainer.Parent = MainFrame
    TabContainer.Size = UDim2.new(1, 0, 1, -40)
    TabContainer.Position = UDim2.new(0, 0, 0, 40)
    TabContainer.BackgroundTransparency = 1

    -- **Tab Logic**
    local Tabs = {}
    function Menu:AddTab(config)
        local Tab = {}
        local TabButton = Instance.new("TextButton")
        TabButton.Name = config.Title
        TabButton.Parent = TabContainer
        TabButton.Size = UDim2.new(0, 100, 0, 40)
        TabButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        TabButton.Font = Enum.Font.Gotham
        TabButton.Text = config.Title
        TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabButton.TextSize = 14

        TabButton.MouseButton1Click:Connect(function()
            for _, child in pairs(TabContainer:GetChildren()) do
                if child:IsA("Frame") then
                    child.Visible = false
                end
            end
            if not Tab.Content then
                Tab.Content = Instance.new("Frame")
                Tab.Content.Parent = MainFrame
                Tab.Content.Size = UDim2.new(1, 0, 1, -80)
                Tab.Content.Position = UDim2.new(0, 0, 0, 80)
                Tab.Content.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            end
            Tab.Content.Visible = true
        end)

        Tabs[config.Title] = Tab
        return Tab
    end

    -- **Close Menu Function**
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    return Menu
end

-- Hàm tạo Button trong Tab
function NoxUI:AddButton(tab, title, description, callback)
    local Button = Instance.new("TextButton")
    Button.Name = title
    Button.Parent = tab.Content
    Button.Size = UDim2.new(1, -10, 0, 40)
    Button.Position = UDim2.new(0, 5, 0, (tab.Content:GetChildren() and #tab.Content:GetChildren() or 0) * 45)
    Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    Button.Font = Enum.Font.Gotham
    Button.Text = title
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 14

    Button.MouseButton1Click:Connect(function()
        callback(description)
    end)
end

-- **Trả về thư viện NoxUI**
return NoxUI
