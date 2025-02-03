
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