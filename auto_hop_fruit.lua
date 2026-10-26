-- ====================================================================
-- 🍎 ENI AUTO HOP FRUIT v9.0 - ANIME PIECE (GGMAX FRUIT SNIPER)
-- Filtro Exclusivo: Frutas ÉPICAS, LENDÁRIAS e MÍTICAS (Ignora Common/Rare)
-- Anti-Same-Server Tracking (Roblox API + Cursor Pagination + Cache JSON/Memória)
-- Coleta de DroppedTools no Mapa + Gira Luzefe se sem CD + Compra Mítica
-- ====================================================================

repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

getgenv().ENI_FruitHopConfig = getgenv().ENI_FruitHopConfig or {
    Enabled             = true,
    WebhookUrl          = "",       -- Cole seu Webhook do Discord aqui
    MinRarity           = "Epic",   -- "Epic", "Legendary", "Mythical"
    SpinFruitBeforeHop  = true,     -- Gira fruta no Luzefe ($35k) antes de pular se sem cooldown
    BuyMythicInStock    = true,     -- Compra Infinity / Vessel se estiver em estoque no servidor
    WaitBeforeHop       = 2.5,      -- Segundos para escanear o servidor antes de pular
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

-- Dicionário estrito de Raridade das Frutas em Anime Piece
local FRUIT_RARITIES = {
    -- Common (IGNORAR)
    ["Copy"] = "Common",
    ["Copy Fruit"] = "Common",
    ["Kilo"] = "Common",
    ["Kilo Fruit"] = "Common",
    ["Warrior"] = "Common",
    ["Warrior Fruit"] = "Common",

    -- Rare (IGNORAR)
    ["Bomb"] = "Rare",
    ["Bomb Fruit"] = "Rare",

    -- Epic (COLETAR!)
    ["Flame"] = "Epic",
    ["Flame Fruit"] = "Epic",
    ["Emperor"] = "Epic",
    ["Emperor Fruit"] = "Epic",

    -- Legendary (COLETAR!)
    ["Scarlet"] = "Legendary",
    ["Scarlet Fruit"] = "Legendary",
    ["Quake"] = "Legendary",
    ["Quake Fruit"] = "Legendary",
    ["Beast"] = "Legendary",
    ["Beast Fruit"] = "Legendary",

    -- Mythic / Mythical (COLETAR!)
    ["Infinity"] = "Mythical",
    ["Infinity Fruit"] = "Mythical",
    ["Vessel"] = "Mythical",
    ["Vessel Fruit"] = "Mythical",
}

local RARITY_TIERS = {
    ["Common"]    = 1,
    ["Rare"]      = 2,
    ["Epic"]      = 3,
    ["Legendary"] = 4,
    ["Mythical"]  = 5,
}

local function getFruitRarity(rawName)
    if not rawName then return "Common" end
    local clean = tostring(rawName):gsub("%[.*%]", ""):gsub("Tool", ""):gsub("^%s+", ""):gsub("%s+$", "")

    -- Checagem direta
    if FRUIT_RARITIES[clean] then return FRUIT_RARITIES[clean] end

    -- Checagem parcial por nome da fruta
    for fName, rar in pairs(FRUIT_RARITIES) do
        if string.find(clean:lower(), fName:lower()) then
            return rar
        end
    end

    -- Consulta GameData se disponível
    local renv = getrenv and getrenv() or _G
    local gd = (renv._G and renv._G.GameData) or _G.GameData
    local itemsData = gd and gd["Items Data"]
    if itemsData and itemsData[clean] and itemsData[clean].Rarity then
        return itemsData[clean].Rarity
    end

    return "Unknown"
end

local function isAllowedFruit(fruitName)
    local minRar = getgenv().ENI_FruitHopConfig.MinRarity or "Epic"
    local minVal = RARITY_TIERS[minRar] or 3

    local fruitRar = getFruitRarity(fruitName)
    local fruitVal = RARITY_TIERS[fruitRar] or 0

    -- Se for épica, lendária ou mítica (tier >= 3)
    if fruitVal >= minVal then
        return true, fruitRar
    end

    -- Se for desconhecida mas tem cara de fruta épica/nova, aceita para não perder item raro
    if fruitRar == "Unknown" and string.find(fruitName:lower(), "fruit") then
        local isIgnored = false
        for _, ign in ipairs({"Copy", "Kilo", "Warrior", "Bomb"}) do
            if string.find(fruitName:lower(), ign:lower()) then
                isIgnored = true
                break
            end
        end
        if not isIgnored then
            return true, "Epic+"
        end
    end

    return false, fruitRar
end

-- ====================================================================
-- SISTEMA ANTI-MESMO-SERVIDOR (TRACKING DE JOB-IDS VISITADOS)
-- ====================================================================
local visitedFile = "AnimePiece_VisitedServers.json"
local VisitedServerIds = {}

local function loadVisitedServers()
    if readfile and isfile and isfile(visitedFile) then
        local ok, res = pcall(function()
            return HttpService:JSONDecode(readfile(visitedFile))
        end)
        if ok and type(res) == "table" then
            VisitedServerIds = res
            return
        end
    end
    -- Fallback via getgenv
    if not getgenv().ENI_VisitedServers then
        getgenv().ENI_VisitedServers = {}
    end
    VisitedServerIds = getgenv().ENI_VisitedServers
end

local function saveVisitedServers()
    -- Limita o histórico a 200 servidores para não acumular lixo
    while #VisitedServerIds > 200 do
        table.remove(VisitedServerIds, 1)
    end
    if writefile then
        pcall(function()
            writefile(visitedFile, HttpService:JSONEncode(VisitedServerIds))
        end)
    end
    getgenv().ENI_VisitedServers = VisitedServerIds
end

local function markCurrentServerVisited()
    loadVisitedServers()
    local cId = tostring(game.JobId)
    if cId and cId ~= "" then
        local found = false
        for _, id in ipairs(VisitedServerIds) do
            if id == cId then found = true break end
        end
        if not found then
            table.insert(VisitedServerIds, cId)
            saveVisitedServers()
        end
    end
end

markCurrentServerVisited()

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

local function sendFruitWebhook(title, fruitName, rarity)
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
                    color = (rarity == "Mythical" and 16711680) or (rarity == "Legendary" and 16753920) or 10040319,
                    fields = {
                        {name = "👤 Conta", value = "`" .. LocalPlayer.Name .. "`", inline = true},
                        {name = "🍎 Fruta", value = "`" .. tostring(fruitName) .. "`", inline = true},
                        {name = "⭐ Raridade", value = "`" .. tostring(rarity or "Epic+") .. "`", inline = true},
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
Frame.Size = UDim2.new(0, 360, 0, 105)
Frame.Position = UDim2.new(0.5, -180, 0, 22)
Frame.BackgroundColor3 = Color3.fromRGB(16, 13, 28)
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)
local Stroke = Instance.new("UIStroke", Frame)
Stroke.Color = Color3.fromRGB(255, 170, 0)
Stroke.Thickness = 2

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -16, 0, 24)
Title.Position = UDim2.new(0, 8, 0, 4)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextColor3 = Color3.fromRGB(255, 195, 40)
Title.Text = "🍎 ENI FRUIT SNIPER v9.0 (ÉPICA+ | NO SAME-SERVER)"
Title.Parent = Frame

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -16, 0, 38)
Status.Position = UDim2.new(0, 8, 0, 28)
Status.BackgroundTransparency = 1
Status.Font = Enum.Font.GothamMedium
Status.TextSize = 12
Status.TextColor3 = Color3.fromRGB(0, 240, 255)
Status.Text = "Verificando servidores e escaneando frutas..."
Status.TextWrapped = true
Status.Parent = Frame

local StopBtn = Instance.new("TextButton")
StopBtn.Size = UDim2.new(1, -24, 0, 26)
StopBtn.Position = UDim2.new(0, 12, 0, 70)
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
        local isFruit = (itemsData and itemsData[tool.Name] and itemsData[tool.Name].Category == "Fruits") or string.find(tool.Name, "Fruit")
        if isFruit then
            local allowed, rar = isAllowedFruit(tool.Name)
            if allowed then
                if not hasStoredFruit(tool.Name) then
                    Status.Text = string.format("📦 Guardando %s [%s] no Storage...", tool.Name, rar)
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
                    sendFruitWebhook("🍎 Fruta Rara Coletada & Guardada!", tool.Name, rar)
                else
                    Status.Text = "✅ Já possui no Storage: " .. tool.Name
                end
            else
                Status.Text = string.format("⏩ Ignorando %s (%s - Abaixo de Épica)", tool.Name, rar)
            end
        end
    end
    return storedAny
end

-- ====================================================================
-- HOPPER INTELIGENTE COM PAGINAÇÃO CURSOR & ZERO SERVIDORES REPETIDOS
-- ====================================================================
local function hopToNextServer()
    if not getgenv().ENI_FruitHopConfig.Enabled then return end
    loadVisitedServers()

    local placeId = tostring(game.PlaceId)
    local currentJobId = tostring(game.JobId)
    Status.Text = "🌐 Buscando servidor novo (sem repetições)..."

    local cursor = ""
    local maxPages = 4
    local targetServerId = nil

    for page = 1, maxPages do
        if not getgenv().ENI_FruitHopConfig.Enabled then return end
        local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
        if cursor ~= "" then
            url = url .. "&cursor=" .. cursor
        end

        local success, res = pcall(function()
            return game:HttpGet(url)
        end)

        if success and res and res ~= "" then
            local data = nil
            pcall(function() data = HttpService:JSONDecode(res) end)

            if data and data.data then
                for _, srv in ipairs(data.data) do
                    local sId = tostring(srv.id)
                    local playing = tonumber(srv.playing) or 0
                    local maxP = tonumber(srv.maxPlayers) or 12

                    if sId ~= currentJobId and playing > 0 and playing < (maxP - 1) then
                        local alreadyVisited = false
                        for _, vId in ipairs(VisitedServerIds) do
                            if vId == sId then
                                alreadyVisited = true
                                break
                            end
                        end

                        if not alreadyVisited then
                            targetServerId = sId
                            break
                        end
                    end
                end

                if targetServerId then break end
                cursor = (data.nextPageCursor and data.nextPageCursor ~= "null" and data.nextPageCursor) or ""
                if cursor == "" then break end
            else
                break
            end
        else
            break
        end
        task.wait(0.25)
    end

    -- Se todos os servidores encontrados já foram visitados recentemente, limpa os mais velhos do cache
    if not targetServerId then
        Status.Text = "🔄 Ciclo de servidores completo! Resetando cache antigo..."
        if #VisitedServerIds > 5 then
            for i = 1, math.floor(#VisitedServerIds / 2) do
                table.remove(VisitedServerIds, 1)
            end
            saveVisitedServers()
        end
        -- Tenta um servidor aleatório disponível
        pcall(function()
            local raw = game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Desc&limit=100")
            local d = HttpService:JSONDecode(raw)
            if d and d.data then
                for _, srv in ipairs(d.data) do
                    if tostring(srv.id) ~= currentJobId and (srv.playing or 0) < (srv.maxPlayers or 12) - 1 then
                        targetServerId = tostring(srv.id)
                        break
                    end
                end
            end
        end)
    end

    if targetServerId then
        table.insert(VisitedServerIds, targetServerId)
        saveVisitedServers()
        Status.Text = "🚀 Conectando a servidor inédito: " .. string.sub(targetServerId, 1, 8)
        pcall(function()
            TeleportService:TeleportToPlaceInstance(tonumber(placeId), targetServerId, LocalPlayer)
        end)
        task.wait(4.0)
    else
        Status.Text = "⚠️ Nenhum servidor novo encontrado. Teleportando padrão..."
        pcall(function()
            TeleportService:Teleport(tonumber(placeId), LocalPlayer)
        end)
        task.wait(4.0)
    end
end

-- ====================================================================
-- LOOP PRINCIPAL DO FRUIT SNIPER
-- ====================================================================
task.spawn(function()
    task.wait(1.5)
    local ps = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PlayerStats"):WaitForChild(LocalPlayer.Name)

    while getgenv().ENI_FruitHopConfig.Enabled do
        -- 1. Procura frutas dropadas/spawnadas no mapa (filtrando ÉPICA PRA CIMA)
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
                    local allowed, rarity = isAllowedFruit(fLabel)

                    if allowed then
                        Status.Text = string.format("🧲 Fruta encontrada: %s [%s]! Coletando...", tostring(fLabel), rarity)
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
                    else
                        Status.Text = string.format("🚫 Ignorando fruta fraca no mapa: %s (%s)", tostring(fLabel), rarity)
                        task.wait(0.2)
                    end
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
                            sendFruitWebhook("🔥 Fruta Mítica Comprada na Loja!", m, "Mythical")
                            task.wait(0.5)
                        end
                    end
                end
            end
        end

        storeAllBackpackFruits()
        Status.Text = string.format("⏳ Aguardando %.1fs para pular de servidor...", getgenv().ENI_FruitHopConfig.WaitBeforeHop)
        task.wait(getgenv().ENI_FruitHopConfig.WaitBeforeHop)
        hopToNextServer()
        task.wait(3.5)
    end
end)
