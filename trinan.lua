
loadstring(game:HttpGet("https://gist.githubusercontent.com/TDAIP/90c3427cd84e5e41ff5fef08bfd983f2/raw/8ab907a644d44e35403668d63c9e3bd665dd3488/inf_MinhTri.lua"))()

--esp glass
-- Kiểm tra xem executor có hỗ trợ Drawing API không
if not Drawing then
    warn("Executor không hỗ trợ Drawing API!")
    return
end

-- Tạo bảng chứa ESP
local ESPParts = {}

-- Hàm tạo ESP cho từng part
local function createESP(part)
    if part:IsA("BasePart") then
        local esp = Drawing.new("Square")
        esp.Color = Color3.fromRGB(255, 0, 0) -- Màu đỏ
        esp.Thickness = 2
        esp.Filled = false
        esp.Transparency = 1

        ESPParts[part] = esp
    end
end

-- Tìm tất cả parts trong workspace.Glasses.Wrong
local function setupESP()
    local folder = workspace:FindFirstChild("Glasses")
    if folder then
        local wrongFolder = folder:FindFirstChild("Wrong")
        if wrongFolder then
            for _, part in pairs(wrongFolder:GetChildren()) do
                createESP(part)
            end
        end
    end
end

-- Cập nhật ESP khi camera thay đổi
game:GetService("RunService").RenderStepped:Connect(function()
    local camera = workspace.CurrentCamera
    for part, esp in pairs(ESPParts) do
        if part and part:IsDescendantOf(workspace) then
            local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
            if onScreen then
                esp.Visible = true
                esp.Size = Vector2.new(5, 5)
                esp.Position = Vector2.new(screenPos.X, screenPos.Y)
            else
                esp.Visible = false
            end
        else
            esp:Remove()
            ESPParts[part] = nil
        end
    end
end)

-- Gọi hàm để tạo ESP
setupESP()













local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local lastQuestion = ""

-- Hàm tạo hiệu ứng fade-in
local function fadeIn(object, time)
    local tween = TweenService:Create(object, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.2})
    tween:Play()
end

-- Hàm tạo màn hình Loading với logo
local function createLoadingScreen()
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not PlayerGui then return end

    local LoadingGui = Instance.new("ScreenGui")
    LoadingGui.Name = "LoadingGui"
    LoadingGui.Parent = PlayerGui

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0.4, 0, 0.25, 0)
    Frame.Position = UDim2.new(0.3, 0, 0.375, 0)
    Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Frame.BackgroundTransparency = 1
    Frame.Parent = LoadingGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0.1, 0)
    UICorner.Parent = Frame

    local Logo = Instance.new("ImageLabel")
    Logo.Size = UDim2.new(0.6, 0, 0.6, 0)
    Logo.Position = UDim2.new(0.2, 0, 0.1, 0)
    Logo.BackgroundTransparency = 1
    Logo.Image = "rbxassetid://82547068171732" -- Logo RobMax
    Logo.Parent = Frame

    local LoadingLabel = Instance.new("TextLabel")
    LoadingLabel.Size = UDim2.new(1, 0, 0.3, 0)
    LoadingLabel.Position = UDim2.new(0, 0, 0.7, 0)
    LoadingLabel.BackgroundTransparency = 1
    LoadingLabel.TextScaled = true
    LoadingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    LoadingLabel.Font = Enum.Font.SourceSansBold
    LoadingLabel.Text = "Đang tải..."
    LoadingLabel.Parent = Frame

    fadeIn(Frame, 1) -- Hiệu ứng xuất hiện dần trong 1 giây

    task.wait(2)

    LoadingGui:Destroy()
end

-- Hàm tạo UI chính
local function createUI()
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not PlayerGui then return end

    local ScreenGui = PlayerGui:FindFirstChild("AnswerGui")
    if not ScreenGui then
        ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "AnswerGui"
        ScreenGui.Parent = PlayerGui
    end

    local Frame = ScreenGui:FindFirstChild("AnswerFrame")
    if not Frame then
        Frame = Instance.new("Frame")
        Frame.Name = "AnswerFrame"
        Frame.Size = UDim2.new(0.3, 0, 0.1, 0)
        Frame.Position = UDim2.new(0.35, 0, 0.05, 0)
        Frame.BackgroundTransparency = 1
        Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Frame.Parent = ScreenGui

        local UICorner = Instance.new("UICorner")
        UICorner.CornerRadius = UDim.new(0.2, 0)
        UICorner.Parent = Frame

        fadeIn(Frame, 1)
    end

    local AnswerLabel = Frame:FindFirstChild("AnswerLabel")
    if not AnswerLabel then
        AnswerLabel = Instance.new("TextLabel")
        AnswerLabel.Name = "AnswerLabel"
        AnswerLabel.Size = UDim2.new(1, 0, 1, 0)
        AnswerLabel.BackgroundTransparency = 1
        AnswerLabel.TextScaled = true
        AnswerLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        AnswerLabel.Font = Enum.Font.SourceSansBold
        AnswerLabel.TextStrokeTransparency = 0
        AnswerLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        AnswerLabel.Parent = Frame
    end

    return AnswerLabel
end

-- Hàm giải toán và ghi đáp án vào TypingText
local function solveMathProblem()
    local AnswerLabel = createUI()
    if not AnswerLabel then return end

    local questionText = workspace.Map.Functional.Screen.SurfaceGui.MainFrame.MainGameContainer.MainTxtContainer.QuestionText.Text
    if questionText == lastQuestion then return end
    lastQuestion = questionText

    local num1, operator, num2 = questionText:match("(%d+)%s*([%+%-/x])%s*(%d+)")
    num1, num2 = tonumber(num1), tonumber(num2)

    if num1 and operator and num2 then
        local result
        if operator == "+" then
            result = num1 + num2
        elseif operator == "-" then
            result = num1 - num2
        elseif operator == "x" then
            result = num1 * num2
        elseif operator == "/" then
            result = num1 / num2
        end

        if result then
            AnswerLabel.Text = "Đáp án: " .. result

            -- Ghi kết quả vào TypingText
            local typingText = workspace.Map.Functional.Screen.SurfaceGui.MainFrame.MainGameContainer.MainTxtContainer.TypingText
            if typingText then
                typingText.Text = tostring(result)
                typingText.TextColor3 = Color3.fromRGB(128, 128, 128) -- Đổi màu xám
            end
        end
    end
end

-- Hiển thị màn hình Loading trước khi chạy script
createLoadingScreen()

-- Lắng nghe thay đổi câu hỏi để cập nhật
workspace.Map.Functional.Screen.SurfaceGui.MainFrame.MainGameContainer.MainTxtContainer.QuestionText:GetPropertyChangedSignal("Text"):Connect(solveMathProblem)

-- Khi nhân vật chết, UI vẫn giữ nguyên
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    createUI()
end)