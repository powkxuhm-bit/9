-- ==========================================
-- Portal Gun (Rick and Morty style) + Cooldown
-- ==========================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local portalA_pos = nil
local portalB_pos = nil
local portalA_model = nil
local portalB_model = nil

-- Переменная для защиты от бешеного телепорта (кулдаун)
local canTeleport = true
local TELEPORT_COOLDOWN = 1.2 -- Время задержки в секундах перед следующим использованием

-- 1. Создаем инструмент "Портальная пушка" в инвентаре
local backpack = player:WaitForChild("Backpack")
local tool = Instance.new("Tool")
tool.Name = "Portal Gun"
tool.RequiresHandle = true

local handle = Instance.new("Part")
handle.Name = "Handle"
handle.Size = Vector3.new(0.8, 0.8, 2.5)
handle.BrickColor = BrickColor.new("Bright green")
handle.Material = Enum.Material.Neon
handle.Shape = Enum.PartType.Block
handle.Parent = tool

local screen = Instance.new("Part")
screen.Size = Vector3.new(0.4, 0.4, 0.4)
screen.Position = handle.Position + Vector3.new(0, 0.5, 0)
screen.BrickColor = BrickColor.new("Cyan")
screen.Material = Enum.Material.Glass
screen.Parent = tool

tool.Parent = backpack

-- 2. Функция создания каноничного зеленого портала
local function createRickPortal(position, colorType)
    local model = Instance.new("Model")
    model.Name = "Portal_" .. colorType
    model.Parent = Workspace

    local portalPart = Instance.new("Part")
    portalPart.Size = Vector3.new(0.5, 6, 4)
    portalPart.Position = position + Vector3.new(0, 3, 0)
    portalPart.Anchored = true
    portalPart.CanCollide = false
    portalPart.Material = Enum.Material.Neon
    
    if colorType == "A" then
        portalPart.Color = Color3.fromRGB(50, 255, 100)
    else
        portalPart.Color = Color3.fromRGB(30, 200, 80)
    end
    
    portalPart.Transparency = 0.2
    portalPart.Shape = Enum.PartType.Cylinder
    portalPart.Orientation = Vector3.new(0, 0, 90)
    portalPart.Parent = model

    local light = Instance.new("PointLight")
    light.Color = portalPart.Color
    light.Range = 12
    light.Brightness = 5
    light.Parent = portalPart

    task.spawn(function()
        while model and model.Parent do
            portalPart.CFrame = portalPart.CFrame * CFrame.Angles(0.05, 0, 0)
            task.wait(0.03)
        end
    end)

    return model, portalPart
end

-- 3. Стрельба с помощью пушки
local isEquipped = false
tool.Equipped:Connect(function() isEquipped = true end)
tool.Unequipped:Connect(function() isEquipped = false end)

local portalStep = 1

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not isEquipped then return end
    
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        local touchPos = input.Position
        local ray = camera:ViewportPointToRay(touchPos.X, touchPos.Y)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {player.Character}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        
        local raycastResult = Workspace:Raycast(ray.Origin, ray.Direction * 600, raycastParams)
        
        if raycastResult then
            local hitPosition = raycastResult.Position
            
            if portalStep == 1 then
                if portalA_model then portalA_model:Destroy() end
                portalA_pos = hitPosition
                local m, _ = createRickPortal(portalA_pos, "A")
                portalA_model = m
                portalStep = 2
                print("[Портальная пушка]: Портал 1 создан!")
            else
                if portalB_model then portalB_model:Destroy() end
                portalB_pos = hitPosition
                local m, _ = createRickPortal(portalB_pos, "B")
                portalB_model = m
                portalStep = 1
                print("[Портальная пушка]: Портал 2 создан!")
            end
        end
    end
end)

-- 4. Телепортация с защитой от бесконечного цикла (кулдауном)
RunService.RenderStepped:Connect(function()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local rootPart = char.HumanoidRootPart
    
    if portalA_pos and portalB_pos and canTeleport then
        if (rootPart.Position - portalA_pos).Magnitude < 4 then
            canTeleport = false
            rootPart.CFrame = CFrame.new(portalB_pos + Vector3.new(0, 3, 0))
            task.wait(TELEPORT_COOLDOWN)
            canTeleport = true
        elseif (rootPart.Position - portalB_pos).Magnitude < 4 then
            canTeleport = false
            rootPart.CFrame = CFrame.new(portalA_pos + Vector3.new(0, 3, 0))
            task.wait(TELEPORT_COOLDOWN)
            canTeleport = true
        end
    end
end)

print("=== Портальная пушка с защитой от зацикливания готова! ===")
