-- ====================================================================
-- 🍎 ENI AUTO HOP FRUIT v8.0 - ANIME PIECE (GGMAX FRUIT SNIPER)
-- Pega Frutas no Mapa (BasePart Handle / Model) + Gira no Luzefe (5.8s Roll)
-- Compra Mítica na Loja + Guarda tudo no Storage + Auto Farm Money p/ Giro
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
Title.Text = "🍎 ENI AUTO HOP FRUIT v8.0 (GGMAX)"
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

local function hasStoredFruit(fruitName)
    local renv = getrenv and getrenv() or _G
    local inv = (renv._G and renv._G.ClientInventory) or _G.ClientInventory
    if inv and inv.Items and inv.Items.Fruits then
        for _, it in pairs(inv.Items.Fruits) do
            if it.Name == fruitName and (it.Amount or 1) >= 1 then
                return true
            end
        end
    end
    return false
end

local function storeAllBackpackFruits()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not (char and hum) then return false end

    local renv = getrenv and getrenv() or _G
    local gd = (renv._G and renv._G.GameData) or _G.GameData
    local itemsData = gd and gd["Items Data"]
    local storedAny = false

    local candidates = {}
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") then table.insert(candidates, t) end
    end
    for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if t:IsA("Tool") then table.insert(candidates, t) end
    end

    for _, tool in ipairs(candidates) do
        if (itemsData and itemsData[tool.Name] and itemsData[tool.Name].Category == "Fruits") or string.find(tool.Name, "Fruit") then
            if not hasStoredFruit(tool.Name) then
                Status.Text = "📦 Guardando no Storage: " .. tool.Name
                if tool.Parent ~= char then
                    hum:EquipTool(tool)
                    local tWait = os.clock()
                    while tool.Parent ~= char and os.clock() - tWait < 0.8 do
                        task.wait(0.05)
                    end
                end
                task.wait(0.25)
                pcall(function() LocalPlayer:SetAttribute("ActualTool", tool.Name) end)
                pcall(function() PhysicalFruitsRemote:FireServer("Storage", tool.Name) end)
                task.wait(0.6)
                storedAny = true
                sendFruitWebhook("🍎 Fruta Coletada & Guardada!", tool.Name)
            else
                Status.Text = "✅ Já possui no Storage: " .. tool.Name
            end
        end
    end
    return storedAny
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
        -- 1. Procura frutas dropadas/spawnadas no mapa (aguarda replicação de servidor até pegar 100% e guardar!)
        local droppedFolder = Workspace:FindFirstChild("World")
            and Workspace.World:FindFirstChild("Playability")
            and Workspace.World.Playability:FindFirstChild("DroppedTools")

        if droppedFolder then
            for _, drop in ipairs(droppedFolder:GetChildren()) do
                if not getgenv().ENI_FruitHopConfig.Enabled then break end
                local handle = (drop:IsA("BasePart") and drop)
                    or drop:FindFirstChild("Handle")
                    or drop:FindFirstChildWhichIsA("BasePart", true)
                local prompt = drop:FindFirstChildWhichIsA("ProximityPrompt", true)
                if handle then
                    local fLabel = (prompt and prompt.ObjectText ~= "" and prompt.ObjectText) or drop.Name
                    Status.Text = "🧲 Pegando fruta no mapa: " .. tostring(fLabel)
                    local t0 = os.clock()
                    while drop and drop.Parent == droppedFolder and os.clock() - t0 < 6.0 and getgenv().ENI_FruitHopConfig.Enabled do
                        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if not hrp then break end
                        hrp.CFrame = handle.CFrame * CFrame.new(0, 3.5, 0)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        task.wait(0.25)
                        if prompt then
                            pcall(function()
                                prompt.HoldDuration = 0
                                prompt.MaxActivationDistance = 30
                                prompt.RequiresLineOfSight = false
                                prompt.Enabled = true
                            end)
                            if fireproximityprompt then pcall(fireproximityprompt, prompt) end
                            pcall(function()
                                prompt:InputHoldBegin()
                                task.wait(0.05)
                                prompt:InputHoldEnd()
                            end)
                        end
                        if firetouchinterest then
                            pcall(firetouchinterest, hrp, handle, 0)
                            pcall(firetouchinterest, hrp, handle, 1)
                        end
                        task.wait(0.22)
                    end
                    task.wait(0.4)
                    storeAllBackpackFruits()
                    task.wait(0.35)
                    storeAllBackpackFruits()
                end
            end
        end

        -- 2. Gira fruta no Luzefe (Foosha: 250.28, 10.5, -1201.5) se sem cooldown
        if getgenv().ENI_FruitHopConfig.SpinFruitBeforeHop then
            local cd = ps.Infos:FindFirstChild("LastFruitTimeSpin")
            local lvl = ps.Infos.Level.Value
            local reqMoney = math.max(540, (lvl - 49) * 540)
            if lvl >= 50 and (not cd or cd.Value <= 0) then
                -- Se faltar dinheiro e for lvl >= 100, farma o valor rapidinho no ElementsQuest antes de girar!
                if ps.Infos.Money.Value < reqMoney and lvl >= 100 then
                    local QuestRemote = Remotes:FindFirstChild("Quest Event")
                    while getgenv().ENI_FruitHopConfig.Enabled and ps.Infos.Money.Value < reqMoney do
                        Status.Text = string.format("💰 Farmando $ p/ Giro (%d / %d)...", ps.Infos.Money.Value, reqMoney)
                        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hrp and (hrp.Position - Vector3.new(660.7, 5, 2687.1)).Magnitude > 250 then
                            hrp.CFrame = CFrame.new(660.7, 5, 2687.1)
                        end
                        if QuestRemote and ps.Quest.QuestId.Value ~= "None" and ps.Quest.QuestId.Value ~= "ElementsQuest" then
                            QuestRemote:FireServer("Quit")
                            task.wait(0.06)
                        end
                        DialogueRemote:FireServer({"Quest", "ElementsQuest"})
                        task.wait(0.06)
                        for _, el in ipairs({"Blue Element", "Red Element", "Pink Element", "Yellow Element"}) do
                            DialogueRemote:FireServer({"ElementsQuest", el})
                            task.wait(0.06)
                        end
                    end
                end
                if ps.Infos.Money.Value >= reqMoney then
                    local luzefeCFrame = CFrame.new(250.28, 10.5, -1201.5)
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        Status.Text = "🎰 Teleportando ao Luzefe e girando (5.8s)..."
                        hrp.CFrame = luzefeCFrame
                        task.wait(0.65)
                        DialogueRemote:FireServer({"SpinFruit", ""})
                        local t0 = os.clock()
                        while os.clock() - t0 < 5.8 do
                            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                LocalPlayer.Character.HumanoidRootPart.CFrame = luzefeCFrame
                            end
                            task.wait(0.2)
                        end
                        storeAllBackpackFruits()
                    end
                end
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
