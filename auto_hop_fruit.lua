-- ====================================================================
-- 🍎 ENI AUTO HOP FRUIT v7.0 - ANIME PIECE (GGMAX FRUIT SNIPER)
-- Pega Frutas no Mapa + Gira no Luzefe + Compra Mítica na Loja
-- Guarda tudo no Storage + Envia Webhook Discord + Server Hop Automático
-- ====================================================================

repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

getgenv().ENI_FruitHopConfig = getgenv().ENI_FruitHopConfig or {
    Enabled             = true,
    WebhookUrl          = "",       -- Cole seu Webhook do Discord aqui
    SpinFruitBeforeHop  = true,     -- Gira fruta no Luzefe ($35k) antes de pular se sem cooldown
    BuyMythicInStock    = true,     -- Compra Infinity / Vessel se estiver em estoque no servidor
    GrabChestsBeforeHop = false,    -- Se true, pega 2-3 baús rápidos antes de pular
    WaitBeforeHop       = 3.5,      -- Segundos para escanear o servidor antes de pular
    AutoReExecOnHop     = true,     -- Usa queue_on_teleport para continuar após o hop
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DialogueRemote = Remotes:WaitForChild("Dialogue Event")
local PhysicalFruitsRemote = Remotes:WaitForChild("Physical Fruits Event")
local FruitShopRemote = Remotes:FindFirstChild("Fruit Shop Event")

-- Auto-Rejoin com tripla camada anti-kick se der erro de conexão
local function triggerRejoin()
    pcall(function()
        if GuiService.ClearError then GuiService:ClearError() end
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

pcall(function()
    GuiService.ErrorMessageChanged:Connect(triggerRejoin)
    local po = CoreGui:WaitForChild("RobloxPromptGui", 5) and CoreGui.RobloxPromptGui:WaitForChild("promptOverlay", 5)
    if po then
        po.ChildAdded:Connect(function(c)
            if c.Name == "ErrorPrompt" then triggerRejoin() end
        end)
    end
    RunService.Heartbeat:Connect(function()
        if GuiService.GetErrorCode and GuiService:GetErrorCode().Value > 0 then
            triggerRejoin()
        end
    end)
end)

-- Registra queue_on_teleport para continuar automaticamente no próximo servidor
local qot = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
if qot and getgenv().ENI_FruitHopConfig.AutoReExecOnHop and not getgenv().ENI_HopQueued then
    getgenv().ENI_HopQueued = true
    pcall(function()
        qot([[
            repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Pedrohs1771/anime-piece-ggmax/main/auto_hop_fruit.lua"))()
        ]])
    end)
end

local function sendFruitWebhook(title, fruitName)
    local url = getgenv().ENI_FruitHopConfig.WebhookUrl
    if not url or url == "" or not string.find(url, "http") then return end
    local reqFunc = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if not reqFunc then return end
    pcall(function()
        reqFunc({
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                username = "🍎 ENI Fruit Sniper — GGMAX",
                embeds = {{
                    title = title,
                    color = 16753920,
                    fields = {
                        {name = "👤 Conta", value = "`" .. LocalPlayer.Name .. "`", inline = true},
                        {name = "🍎 Fruta", value = "`" .. tostring(fruitName) .. "`", inline = true},
                        {name = "🌐 JobId", value = "`" .. tostring(game.JobId) .. "`", inline = false},
                    }
                }}
            })
        })
    end)
end

-- Mini HUD de Status do Fruit Hopper
local uiParent = (gethui and gethui()) or CoreGui
if uiParent:FindFirstChild("ENI_FruitHop_HUD") then
    uiParent.ENI_FruitHop_HUD:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ENI_FruitHop_HUD"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = uiParent

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 340, 0, 95)
Frame.Position = UDim2.new(0.5, -170, 0, 22)
Frame.BackgroundColor3 = Color3.fromRGB(16, 13, 28)
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)
local Stroke = Instance.new("UIStroke", Frame)
Stroke.Color = Color3.fromRGB(255, 170, 0)
Stroke.Thickness = 2

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -16, 0, 26)
Title.Position = UDim2.new(0, 8, 0, 4)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextColor3 = Color3.fromRGB(255, 195, 40)
Title.Text = "🍎 ENI AUTO HOP FRUIT v7.0 (GGMAX)"
Title.Parent = Frame

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -16, 0, 30)
Status.Position = UDim2.new(0, 8, 0, 28)
Status.BackgroundTransparency = 1
Status.Font = Enum.Font.GothamMedium
Status.TextSize = 12
Status.TextColor3 = Color3.fromRGB(0, 240, 255)
Status.Text = "Escaneando frutas no servidor..."
Status.Parent = Frame

local StopBtn = Instance.new("TextButton")
StopBtn.Size = UDim2.new(1, -24, 0, 26)
StopBtn.Position = UDim2.new(0, 12, 0, 62)
StopBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 60)
StopBtn.Font = Enum.Font.GothamBold
StopBtn.TextSize = 12
StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StopBtn.Text = "⏹️ PARAR AUTO HOP"
StopBtn.Parent = Frame
Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(0, 6)

StopBtn.MouseButton1Click:Connect(function()
    getgenv().ENI_FruitHopConfig.Enabled = false
    StopBtn.Text = "🔴 AUTO HOP PAUSADO"
    StopBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
end)

local function storeAllBackpackFruits()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") and string.find(tool.Name, "Fruit") then
            Status.Text = "📦 Guardando no Storage: " .. tool.Name
            hum:EquipTool(tool)
            task.wait(0.25)
            pcall(function() PhysicalFruitsRemote:FireServer("Store") end)
            pcall(function() PhysicalFruitsRemote:FireServer("Storage", tool.Name) end)
            sendFruitWebhook("🍎 Fruta Coletada & Guardada!", tool.Name)
            task.wait(0.35)
        end
    end
end

local function hopToNextServer()
    if not getgenv().ENI_FruitHopConfig.Enabled then return end
    Status.Text = "🌐 Buscando novo servidor..."
    pcall(function()
        local raw = game:HttpGet("https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100")
        local data = HttpService:JSONDecode(raw)
        if data and data.data then
            for _, srv in ipairs(data.data) do
                if type(srv) == "table" and srv.id ~= game.JobId and (srv.playing or 0) < (srv.maxPlayers or 12) - 1 then
                    Status.Text = "🚀 Pulando para servidor: " .. string.sub(srv.id, 1, 8)
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
                    task.wait(3.5)
                end
            end
        end
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

task.spawn(function()
    task.wait(1.5)
    local ps = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PlayerStats"):WaitForChild(LocalPlayer.Name)

    while getgenv().ENI_FruitHopConfig.Enabled do
        -- 1. Procura frutas dropadas/spawnadas no mapa
        local droppedFolder = Workspace:FindFirstChild("World")
            and Workspace.World:FindFirstChild("Playability")
            and Workspace.World.Playability:FindFirstChild("DroppedTools")

        if droppedFolder then
            for _, drop in ipairs(droppedFolder:GetChildren()) do
                if not getgenv().ENI_FruitHopConfig.Enabled then break end
                local handle = drop:FindFirstChild("Handle") or drop:FindFirstChildWhichIsA("BasePart")
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if handle and hrp then
                    Status.Text = "🧲 Pegando fruta no mapa: " .. drop.Name
                    hrp.CFrame = handle.CFrame
                    if firetouchinterest then
                        pcall(firetouchinterest, hrp, handle, 0)
                        pcall(firetouchinterest, hrp, handle, 1)
                    end
                    task.wait(0.35)
                    storeAllBackpackFruits()
                end
            end
        end

        -- 2. Gira fruta no Luzefe se disponível
        if getgenv().ENI_FruitHopConfig.SpinFruitBeforeHop then
            local cd = ps.Infos:FindFirstChild("LastFruitTimeSpin")
            if ps.Infos.Level.Value >= 50 and ps.Infos.Money.Value >= 35000 and (not cd or cd.Value <= 0) then
                Status.Text = "🎰 Girando fruta no Luzefe..."
                DialogueRemote:FireServer({"SpinFruit", ""})
                task.wait(1.0)
                storeAllBackpackFruits()
            end
        end

        -- 3. Verifica se tem Infinity ou Vessel na Loja
        if getgenv().ENI_FruitHopConfig.BuyMythicInStock and FruitShopRemote then
            local stock = ReplicatedStorage.Shared:FindFirstChild("Fruit Stock")
            if stock then
                for _, m in ipairs({"Vessel", "Infinity"}) do
                    if stock:FindFirstChild(m) and ps.Build.ActualFruit.Value ~= m then
                        if (m == "Vessel" and ps.Infos.Money.Value >= 265000) or (m == "Infinity" and ps.Infos.Money.Value >= 225000) then
                            Status.Text = "🛒 Comprando Mítica em estoque: " .. m
                            FruitShopRemote:FireServer("Buy", m)
                            sendFruitWebhook("🔥 Fruta Mítica Comprada na Loja!", m)
                            task.wait(0.5)
                        end
                    end
                end
            end
        end

        storeAllBackpackFruits()
        Status.Text = string.format("⏳ Aguardando %.1fs para Server Hop...", getgenv().ENI_FruitHopConfig.WaitBeforeHop)
        task.wait(getgenv().ENI_FruitHopConfig.WaitBeforeHop)
        hopToNextServer()
        task.wait(3)
    end
end)
