-- ====================================================================
-- ⚡ ENI HUB v6.0 - ANIME PIECE (GGMAX ULTIMATE EDITION)
-- HUD Completa com Abas | Turbo Farm Anti-Kick | Seletor de Itens
-- Auto Hop Fruit | Auto Rejoin | Discord Webhook Formatado p/ GGMAX
-- Desenvolvido por ENI para o Tris ⚡
-- ====================================================================

repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CombatRemote = Remotes:WaitForChild("Combat Event")
local SkillRemote = Remotes:WaitForChild("Skill Event")
local QuestRemote = Remotes:WaitForChild("Quest Event")
local DialogueRemote = Remotes:WaitForChild("Dialogue Event")
local StatsRemote = Remotes:WaitForChild("Stats Event")
local CustomToolRemote = Remotes:WaitForChild("Custom Tool Event")
local ItemBuyerRemote = Remotes:WaitForChild("ItemBuyer Event")
local PhysicalFruitsRemote = Remotes:WaitForChild("Physical Fruits Event")
local InventoryRemote = Remotes:WaitForChild("Inventory Event")
local FruitShopRemote = Remotes:FindFirstChild("Fruit Shop Event")
local RaceRemote = Remotes:FindFirstChild("Race Event")
local SettingsRemote = Remotes:FindFirstChild("Settings Event")
local HakiRemote = Remotes:FindFirstChild("Armament Haki Event")
local SpecialsFolder = Remotes:FindFirstChild("Specials Remotes")

-- Encerra instância anterior com segurança
getgenv().ENI_LoopId = "STOPPED"
if getgenv().ENI_HubCleanup then
    pcall(getgenv().ENI_HubCleanup)
end

local HubId = tostring(math.random(1000000, 9999999))
getgenv().ENI_HubId = HubId
getgenv().ENI_LoopId = HubId

-- ====================================================================
-- CONFIGURAÇÃO COMPLETA (SALVA EM GETGENV PARA PERSISTIR)
-- ====================================================================
getgenv().ENI_Config = getgenv().ENI_Config or {
    -- Aba 1: Auto Farm
    TurboTaskFarm = true,       -- Farm Turbo (ElementsQuest 100% livre de kick)
    AutoFarmCombat = true,      -- Farm de Combate (Level 0->85 ou Mobs/Bosses)
    AutoSkills = true,          -- Usa Z, X, C, V automaticamente
    AutoStats = true,           -- Upa Swords -> Defense -> FightStyles -> Stamina
    AutoHaki = true,            -- Mantém Armament Haki ligado
    AutoRejoin = true,          -- Reentra automaticamente se desconectar/kickar
    HoverHeight = 5.8,
    PreferredType = "Swords",   -- "Swords", "FightStyles", "Fruits"

    -- Aba 2: Seletor de Itens / Espadas / Estilos para Pegar
    GrabShopSwords = true,      -- Katana, Future Sword, Iron Spear, Raven Axe
    GrabToolsPoses = true,      -- Axe, Iron Hoe, Wrench, Pickaxe, Poses
    GrabAccessories = true,     -- Scouter, Uniforms, Dark Cloak
    FarmFlashStep = true,       -- Farma Souls nos Bandits/Higaro e compra Flash Step
    FarmBlackLeg = true,        -- Compra Black Leg no Sanjiro
    FarmRoboticStyle = false,   -- Farma 45x Robotic Gear + 5x Core e compra Robotic Style
    FarmShadowBlade = false,    -- Farma 2x Magic Ball no Old Fighter e compra Shadow Blade
    FarmDivergentStyle = false, -- Compra Divergent Style no Jojo
    FarmArmamentHaki = true,    -- Compra Armament Haki V1 / V2 / V3
    AutoSpinTopRace = true,     -- Gira Raça até pegar Infernal / Curse / Fighter / Gamer

    -- Aba 3: Frutas & Server Hop
    AutoGrabDrops = true,       -- Teleporta e pega frutas dropadas no mapa
    AutoStoreFruits = true,     -- Guarda todas as frutas da mochila no Storage
    AutoSpinFruit = true,       -- Gira fruta no Luzefe ($35k) quando sem cooldown
    AutoBuyMythicStock = true,  -- Compra Infinity / Vessel se estiver na loja
    AutoHopFruit = false,       -- Procura fruta no mapa + gira e pula de servidor

    -- Aba 4: Baús & Webhook GGMAX
    AutoChest = false,          -- Coleta todos os baús do mapa
    WebhookUrl = "",            -- URL do Webhook do Discord
    AutoSendWebhook = false,    -- Envia relatório automático ao bater meta (Lvl 245)
    TargetMoneyGGMAX = 500000,  -- Meta de dinheiro para notificar conta pronta
}

-- ====================================================================
-- 1. FILA DE PACOTES LOCK-FREE ANTI-KICK & AUTO-REJOIN
-- ====================================================================
getgenv().ENI_LastM1Fire = getgenv().ENI_LastM1Fire or 0

-- Fila matemática por reserva de timestamp: NUNCA trava e NUNCA passa de ~4.5 pacotes/s
local function safeFireRemote(remote, ...)
    if not remote or getgenv().ENI_HubId ~= HubId then return false end
    local now = os.clock()
    local nextTime = math.max(now, (getgenv().ENI_NextPacketTime or 0) + 0.22)
    getgenv().ENI_NextPacketTime = nextTime
    if nextTime > now then
        task.wait(nextTime - now)
    end
    if getgenv().ENI_HubId ~= HubId then return false end
    pcall(remote.FireServer, remote, ...)
    return true
end

local function safeFireCombat(comboIndex)
    local now = os.clock()
    if now - getgenv().ENI_LastM1Fire >= 0.42 and now - (getgenv().ENI_NextPacketTime or 0) >= 0.18 then
        getgenv().ENI_LastM1Fire = now
        getgenv().ENI_NextPacketTime = now
        pcall(CombatRemote.FireServer, CombatRemote, comboIndex)
        return true
    end
    return false
end

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end)
end)

-- Auto-Rejoin ao tomar Kick / Desconexão
local function triggerRejoin()
    if not getgenv().ENI_Config.AutoRejoin or getgenv().ENI_Rejoining then return end
    getgenv().ENI_Rejoining = true
    task.spawn(function()
        while getgenv().ENI_Config.AutoRejoin do
            pcall(function()
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            end)
            task.wait(2.5)
        end
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
end)

-- ====================================================================
-- 2. DADOS DE QUESTS, ILHAS E MATERIAIS DE DROP
-- ====================================================================
local CombatQuests = {
    {id = "001", lvl = 0,   mobs = {"Bandit"},                   boss = false, island = "Foosha",          pos = Vector3.new(440.9, 8.3, -991.5)},
    {id = "003", lvl = 20,  mobs = {"Higaro’s bandit"},          boss = false, island = "Foosha",          pos = Vector3.new(13.7, 7.9, -1142.1)},
    {id = "006", lvl = 40,  mobs = {"Higaro"},                   boss = true,  island = "Foosha",          pos = Vector3.new(235.6, 7.9, -1442.3)},
    {id = "007", lvl = 45,  mobs = {"Warrior Monkey"},           boss = false, island = "JungleIsland",    pos = Vector3.new(-905.7, 9.2, 104.0)},
    {id = "009", lvl = 60,  mobs = {"Knight Monkey"},            boss = false, island = "JungleIsland",    pos = Vector3.new(-1224.4, 9.4, 32.6)},
    {id = "010", lvl = 70,  mobs = {"King Monkey"},              boss = true,  island = "JungleIsland",    pos = Vector3.new(-1158.0, 9.2, -14.8)},
    {id = "011", lvl = 75,  mobs = {"Red Brawler"},              boss = false, island = "WestIsland",      pos = Vector3.new(785.6, 3.1, 2682.9)},
    {id = "013", lvl = 90,  mobs = {"Robot"},                    boss = false, island = "WestIsland",      pos = Vector3.new(379.2, 3.2, 3183.6)},
    {id = "014", lvl = 105, mobs = {"Robot King"},               boss = true,  island = "WestIsland",      pos = Vector3.new(379.2, 3.2, 3266.6)},
    {id = "016", lvl = 115, mobs = {"Robot 15", "Robot 16"},     boss = true,  island = "WestIsland",      pos = Vector3.new(1309.8, 2.8, 3566.8)},
    {id = "017", lvl = 120, mobs = {"Crimson King"},             boss = true,  island = "WestIsland",      pos = Vector3.new(240.7, 2.8, 3515.5)},
    {id = "019", lvl = 130, mobs = {"Frieza"},                   boss = true,  island = "WestIsland",      pos = Vector3.new(1103.1, 2.9, 2762.2)},
    {id = "020", lvl = 135, mobs = {"Corrupted Player"},         boss = false, island = "OnlineIsland",    pos = Vector3.new(3697.9, 30.6, 2578.0)},
    {id = "021", lvl = 150, mobs = {"Pro Player"},               boss = false, island = "OnlineIsland",    pos = Vector3.new(3335.0, 30.6, 2777.0)},
    {id = "024", lvl = 165, mobs = {"Jujutsu Student"},          boss = false, island = "SorcerersIsland", pos = Vector3.new(4154.9, 6.8, 44.7)},
    {id = "026", lvl = 190, mobs = {"Special Student"},          boss = false, island = "SorcerersIsland", pos = Vector3.new(4504.3, 6.8, -14.4)},
    {id = "027", lvl = 205, mobs = {"Overtime Sorcerer"},        boss = true,  island = "SorcerersIsland", pos = Vector3.new(4687.0, 6.9, -79.7)},
    {id = "029", lvl = 225, mobs = {"White Panda"},              boss = true,  island = "SorcerersIsland", pos = Vector3.new(4603.3, 6.8, 205.7)},
}

local QuestById = {}
for _, q in ipairs(CombatQuests) do QuestById[q.id] = q end

local IslandPositions = {
    ["Starter Island (Foosha)"] = Vector3.new(270, 15, -1010),
    ["Jungle Island"]           = Vector3.new(-905, 15, 104),
    ["West Island"]             = Vector3.new(535, 10, 2900),
    ["Online Island"]           = Vector3.new(3500, 35, 2600),
    ["Sorcerers Island"]        = Vector3.new(4155, 15, 45),
    ["Good House"]              = Vector3.new(2793, 18, -2675),
}

-- ====================================================================
-- 3. FUNÇÕES AUXILIARES DE LEITURA E INVENTÁRIO
-- ====================================================================
local function getPlayerStatsFolder()
    local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
    local psFolder = sharedFolder and sharedFolder:FindFirstChild("PlayerStats")
    return psFolder and psFolder:FindFirstChild(LocalPlayer.Name)
end

local function getGameData()
    local renv = getrenv and getrenv() or _G
    return (renv._G and renv._G.GameData) or _G.GameData
end

local function getClientInventory()
    local renv = getrenv and getrenv() or _G
    return (renv._G and renv._G.ClientInventory) or _G.ClientInventory
end

local function hasInventoryItem(itemName, category, minAmount)
    minAmount = minAmount or 1
    local inv = getClientInventory()
    if inv and inv.Items and inv.Items[category] then
        for _, it in pairs(inv.Items[category]) do
            if it.Name == itemName and (it.Amount or 1) >= minAmount then
                return true, (it.Amount or 1)
            end
        end
    end
    return false, 0
end

local function getFormattedInventorySummary()
    local ps = getPlayerStatsFolder()
    local inv = getClientInventory()
    local fruits, swords, accs, styles = {}, {}, {}, {}

    if inv and inv.Items then
        for _, f in pairs(inv.Items.Fruits or {}) do
            table.insert(fruits, f.Name .. " (x" .. tostring(f.Amount or 1) .. ")")
        end
        for _, s in pairs(inv.Items.Swords or {}) do
            table.insert(swords, s.Name)
        end
        for _, a in pairs(inv.Items.Acessories or {}) do
            table.insert(accs, a.Name)
        end
    end
    if ps and ps:FindFirstChild("Unlockeds") and ps.Unlockeds:FindFirstChild("FightingStyles") then
        for _, st in ipairs(ps.Unlockeds.FightingStyles:GetChildren()) do
            table.insert(styles, st.Name)
        end
    end

    return {
        fruits = #fruits > 0 and table.concat(fruits, ", ") or "Nenhuma no Storage",
        swords = #swords > 0 and table.concat(swords, ", ") or "Katana",
        accs   = #accs > 0 and table.concat(accs, ", ") or "Nenhum",
        styles = #styles > 0 and table.concat(styles, ", ") or "Melee",
    }
end

-- ====================================================================
-- 4. DISCORD WEBHOOK EXPORTER (FORMATO ANÚNCIO GGMAX)
-- ====================================================================
local function sendGGMAXWebhook(customTitle)
    local url = getgenv().ENI_Config.WebhookUrl
    if not url or url == "" or not string.find(url, "http") then
        return false, "Webhook URL vazia ou inválida!"
    end

    local ps = getPlayerStatsFolder()
    if not ps then return false, "PlayerStats não encontrado" end

    local summary = getFormattedInventorySummary()
    local lvl = ps.Infos.Level.Value
    local money = ps.Infos.Money.Value
    local race = ps.Build.ActualRace.Value
    local eqFruit = ps.Build.ActualFruit.Value
    local eqSword = ps.Build.ActualSword.Value
    local eqStyle = ps.Build.ActualFightingStyle.Value
    local flashStep = ps.Build["Flash Step"].Value and "✅ Sim" or "❌ Não"
    local haki = ps.Build.ArmamentHaki.Value and ("✅ V" .. tostring(ps.Build.HakiLevel.Value)) or "❌ Não"

    local ggmaxTemplate = string.format(
        "🔥 CONTA ANIME PIECE LEVEL %d (MAX) 🔥\n" ..
        "⭐ Level: %d / 245\n" ..
        "💰 Money (Beli): $%d\n" ..
        "🧬 Raça: %s (%d Spins restantes)\n" ..
        "🍎 Fruta Equipada: %s\n" ..
        "📦 Frutas no Inventário: %s\n" ..
        "🗡️ Espadas: %s\n" ..
        "🥊 Estilos de Luta: %s\n" ..
        "⚡ Flash Step: %s | 🛡️ Haki: %s\n" ..
        "👑 Acessórios: %s",
        lvl, lvl, money, race, ps.Stats.RaceRerollPoints.Value,
        eqFruit, summary.fruits, summary.swords, summary.styles,
        flashStep, haki, summary.accs
    )

    local payload = {
        username = "⚡ ENI Hub — GGMAX Account Monitor",
        embeds = {{
            title = customTitle or ("✅ Conta Pronta para GGMAX — " .. LocalPlayer.Name),
            color = 9055202,
            fields = {
                {name = "👤 Conta (Username)", value = "`" .. LocalPlayer.Name .. "`", inline = true},
                {name = "⭐ Level", value = "`" .. tostring(lvl) .. " / 245`", inline = true},
                {name = "💰 Dinheiro", value = "`$" .. tostring(money) .. "`", inline = true},
                {name = "🧬 Raça & Spins", value = "`" .. race .. " (" .. tostring(ps.Stats.RaceRerollPoints.Value) .. " Spins)`", inline = true},
                {name = "🍎 Fruta Equipada", value = "`" .. eqFruit .. "`", inline = true},
                {name = "🗡️ Arma / Estilo", value = "`" .. eqSword .. " / " .. eqStyle .. "`", inline = true},
                {name = "📦 Frutas Guardadas (Storage)", value = "```" .. summary.fruits .. "```", inline = false},
                {name = "⚔️ Espadas Desbloqueadas", value = "```" .. summary.swords .. "```", inline = false},
                {name = "📋 Descrição Pronta p/ Copiar na GGMAX", value = "```" .. ggmaxTemplate .. "```", inline = false}
            },
            footer = {text = "ENI Hub v6.0 • GGMAX Automated Farming Suite"}
        }}
    }

    local reqFunc = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if reqFunc then
        local ok, err = pcall(function()
            reqFunc({
                Url = url,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(payload)
            })
        end)
        return ok, ok and "Webhook enviado com sucesso!" or tostring(err)
    end
    return false, "Executor não suporta http_request"
end

-- ====================================================================
-- 5. SERVER HOP AUTOMÁTICO (PARA FRUTAS / BOSSES)
-- ====================================================================
local function serverHop()
    pcall(function()
        local serversUrl = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
        local raw = game:HttpGet(serversUrl)
        local decoded = HttpService:JSONDecode(raw)
        if decoded and decoded.data then
            for _, srv in ipairs(decoded.data) do
                if type(srv) == "table" and srv.id ~= game.JobId and (srv.playing or 0) < (srv.maxPlayers or 12) - 1 then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
                    task.wait(3)
                end
            end
        end
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

-- ====================================================================
-- 6. FUNÇÕES DE COMBATE E DESBLOQUEIO SELETIVO DE ITENS
-- ====================================================================
local function findAliveMobForList(mobNames)
    local enemysFolder = Workspace:FindFirstChild("World")
        and Workspace.World:FindFirstChild("Playability")
        and Workspace.World.Playability:FindFirstChild("Enemys")
    if not enemysFolder then return nil end

    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local bestMob, bestDist = nil, math.huge

    for _, model in ipairs(enemysFolder:GetChildren()) do
        if model:IsA("Model") then
            local realName = model:GetAttribute("RealName") or model.Name
            local matches = false
            for _, targetName in ipairs(mobNames) do
                if realName == targetName or string.find(model.Name, targetName, 1, true) then
                    matches = true
                    break
                end
            end
            if matches then
                local hum = model:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local mhrp = model:FindFirstChild("HumanoidRootPart")
                    local pos = mhrp and mhrp.Position or model:GetPivot().Position
                    local dist = hrp and (hrp.Position - pos).Magnitude or 0
                    if mhrp then dist = dist - 10000 end
                    if dist < bestDist then
                        bestDist = dist
                        bestMob = model
                    end
                end
            end
        end
    end
    return bestMob
end

local function getBestQuestForLevel(level)
    local bestBossQuest, bestMobQuest = nil, nil
    for _, q in ipairs(CombatQuests) do
        if level >= q.lvl then
            if q.boss then bestBossQuest = q else bestMobQuest = q end
        end
    end
    if bestBossQuest and (not bestMobQuest or bestBossQuest.lvl >= bestMobQuest.lvl) then
        if findAliveMobForList(bestBossQuest.mobs) then
            return bestBossQuest
        end
    end
    return bestMobQuest or bestBossQuest or CombatQuests[1]
end

-- Retorna o mob específico caso o usuário tenha ativado farm de algum material que falta
local function getPriorityMaterialTarget()
    local ps = getPlayerStatsFolder()
    if not ps then return nil end

    -- 1. Flash Step: requer 15x Bandit Soul, 15x Higaro bandit Soul, 5x Higaro Soul
    if getgenv().ENI_Config.FarmFlashStep and not ps.Build["Flash Step"].Value then
        local hasBS = hasInventoryItem("Bandit Soul", "Miscellaneous", 15)
        if not hasBS then
            return {mobs = {"Bandit"}, pos = Vector3.new(440.9, 8.3, -991.5), reason = "Farmando Bandit Soul (Flash Step)"}
        end
        local hasHBS = hasInventoryItem("Higaro bandit Soul", "Miscellaneous", 15)
        if not hasHBS then
            return {mobs = {"Higaro’s bandit"}, pos = Vector3.new(13.7, 7.9, -1142.1), reason = "Farmando Higaro bandit Soul (Flash Step)"}
        end
        local hasHS = hasInventoryItem("Higaro Soul", "Miscellaneous", 5)
        if not hasHS then
            return {mobs = {"Higaro"}, pos = Vector3.new(235.6, 7.9, -1442.3), reason = "Farmando Higaro Soul (Flash Step)"}
        end
        if ps.Infos.Money.Value >= 5500 then
            safeFireRemote(DialogueRemote, {"Flash Step", "Buy"})
        end
    end

    -- 2. Robotic Style: requer 45x Robotic Gear + 5x Robotic Core + $15,000
    if getgenv().ENI_Config.FarmRoboticStyle and not ps.Unlockeds.FightingStyles:FindFirstChild("Robotic Style") then
        local hasGear = hasInventoryItem("Robotic Gear", "Miscellaneous", 45)
        if not hasGear then
            return {mobs = {"Robot"}, pos = Vector3.new(379.2, 3.2, 3183.6), reason = "Farmando 45x Robotic Gear"}
        end
        local hasCore = hasInventoryItem("Robotic Core", "Miscellaneous", 5)
        if not hasCore then
            return {mobs = {"Robot King"}, pos = Vector3.new(379.2, 3.2, 3266.6), reason = "Farmando 5x Robotic Core"}
        end
        if ps.Infos.Money.Value >= 15000 then
            safeFireRemote(DialogueRemote, {"RobotTrainer", "Buy"})
        end
    end

    -- 3. Shadow Blade: requer 2x Magic Ball (Old Fighter) + $25,000
    if getgenv().ENI_Config.FarmShadowBlade and not hasInventoryItem("Shadow Blade", "Swords", 1) then
        local hasMB = hasInventoryItem("Magic Ball", "Miscellaneous", 2)
        if not hasMB then
            local m = findAliveMobForList({"Old Fighter"})
            if m then
                return {mobs = {"Old Fighter"}, pos = m:GetPivot().Position, reason = "Farmando Magic Ball (Shadow Blade)"}
            end
        elseif ps.Infos.Money.Value >= 25000 then
            safeFireRemote(DialogueRemote, {"Shadow Swordsman", "Buy"})
        end
    end

    return nil
end

local lastEquipTime = 0
local function ensureWeaponEquipped()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local ps = getPlayerStatsFolder()
    if not (char and hum and ps) then return nil end

    local build = ps:FindFirstChild("Build")
    local swordName = build and build:FindFirstChild("ActualSword") and build.ActualSword.Value or "Katana"
    local styleName = build and build:FindFirstChild("ActualFightingStyle") and build.ActualFightingStyle.Value or "Melee"
    local fruitName = build and build:FindFirstChild("ActualFruit") and build.ActualFruit.Value or "None"

    local pref = getgenv().ENI_Config.PreferredType
    local desiredToolName = styleName
    if pref == "Swords" and swordName ~= "" and swordName ~= "None" then
        desiredToolName = swordName
    elseif pref == "Fruits" and fruitName ~= "" and fruitName ~= "None" then
        desiredToolName = fruitName
    end

    local currentTool = char:FindFirstChildOfClass("Tool")
    if not currentTool or currentTool.Name ~= desiredToolName then
        local bpTool = LocalPlayer.Backpack:FindFirstChild(desiredToolName)
            or LocalPlayer.Backpack:FindFirstChild(swordName)
            or LocalPlayer.Backpack:FindFirstChild(styleName)
            or LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bpTool then
            hum:EquipTool(bpTool)
            currentTool = bpTool
        end
    end

    if currentTool and (os.clock() - lastEquipTime > 2.0 or not LocalPlayer:GetAttribute("HasAttackItem")) then
        lastEquipTime = os.clock()
        LocalPlayer:SetAttribute("ActualTool", currentTool.Name)
        LocalPlayer:SetAttribute("HasAttackItem", true)
        safeFireRemote(CustomToolRemote, "Equip")
    end
    return currentTool
end

local lastSkillCycle = 0
local function fireWeaponSkills(toolName, targetPos)
    if not getgenv().ENI_Config.AutoSkills then return end
    if os.clock() - lastSkillCycle < 3.0 then return end
    lastSkillCycle = os.clock()

    local gd = getGameData()
    local ps = getPlayerStatsFolder()
    if not (gd and gd["AttackableItems Data"] and ps) then return end

    local masteryFolder = ps:FindFirstChild("Masterys")
    local myMastery = (masteryFolder and masteryFolder:FindFirstChild(toolName) and masteryFolder[toolName].Value) or 0

    local itemSkills = nil
    for _, catTable in pairs(gd["AttackableItems Data"]) do
        if typeof(catTable) == "table" and catTable[toolName] and catTable[toolName].Skills then
            itemSkills = catTable[toolName].Skills
            break
        end
    end

    if itemSkills then
        for skillName, skillData in pairs(itemSkills) do
            local reqMastery = (typeof(skillData) == "table" and skillData.Mastery) or 0
            if myMastery >= reqMastery then
                safeFireRemote(SkillRemote, skillName, "Hold")
                safeFireRemote(SkillRemote, skillName, "Release", targetPos)
            end
        end
    end
end

local function runSelectiveUnlocks()
    task.spawn(function()
        local cfg = getgenv().ENI_Config
        local ps = getPlayerStatsFolder()
        if not ps then return end

        if SettingsRemote then
            for _, code in ipairs({"4kCCU", "200kVisits!", "AllGamePass"}) do
                safeFireRemote(SettingsRemote, "UseCode", code)
            end
        end

        if cfg.GrabShopSwords then
            for _, s in ipairs({"Katana", "Future Sword", "Iron Spear", "Raven Axe"}) do
                if not hasInventoryItem(s, "Swords", 1) then
                    safeFireRemote(ItemBuyerRemote, s)
                end
            end
        end

        if cfg.GrabToolsPoses then
            for _, t in ipairs({
                "Axe", "Iron Hoe", "Wrench", "Pickaxe",
                "Starter Island Pose", "Jungle Island Pose", "West Island Pose",
                "Online Island Pose", "Sorcerers Island Pose", "Good House Pose"
            }) do
                if not hasInventoryItem(t, "Items", 1) then
                    safeFireRemote(ItemBuyerRemote, t)
                end
            end
            safeFireRemote(DialogueRemote, {"Navigation License", "Buyed"})
        end

        if cfg.GrabAccessories then
            for _, a in ipairs({"Scouter", "Male Uniform", "Female Uniform", "Basic Dark Cloak"}) do
                if not hasInventoryItem(a, "Acessories", 1) then
                    safeFireRemote(ItemBuyerRemote, a)
                end
            end
        end

        if cfg.FarmFlashStep and not ps.Build["Flash Step"].Value then
            safeFireRemote(DialogueRemote, {"Flash Step", "Buy"})
        end
        if cfg.FarmBlackLeg then
            safeFireRemote(DialogueRemote, {"Sanjiro", "Buy"})
        end
        if cfg.FarmRoboticStyle then
            safeFireRemote(DialogueRemote, {"RobotTrainer", "Buy"})
        end
        if cfg.FarmDivergentStyle then
            safeFireRemote(DialogueRemote, {"Jojo", "Buy"})
        end
        if cfg.FarmShadowBlade then
            safeFireRemote(DialogueRemote, {"Shadow Swordsman", "Buy"})
            safeFireRemote(DialogueRemote, {"Master Blacksmith", "Buy"})
        end
        if cfg.FarmArmamentHaki then
            safeFireRemote(DialogueRemote, {"ArmamentHaki", "Learn"})
            safeFireRemote(DialogueRemote, {"ArmamentHaki", "UpgradeHakiV2"})
            safeFireRemote(DialogueRemote, {"ArmamentHaki", "UpgradeHakiV3"})
        end

        if cfg.AutoSpinTopRace and RaceRemote then
            local topRaces = {Infernal = true, Curse = true, Fighter = true, Gamer = true}
            while ps.Stats.RaceRerollPoints.Value > 0 and not topRaces[ps.Build.ActualRace.Value] do
                safeFireRemote(RaceRemote, "Spin Race")
                task.wait(0.35)
            end
        end
    end)
end

-- ====================================================================
-- 7. INTERFACE GRÁFICA COMPLETA COM ABAS (HUD ENI HUB v6.0 GGMAX)
-- ====================================================================
local uiParent = (gethui and gethui()) or CoreGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ENI_AnimePiece_Hub_" .. HubId
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = uiParent

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 105, 0, 36)
ToggleBtn.Position = UDim2.new(0, 16, 0.45, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 16, 36)
ToggleBtn.TextColor3 = Color3.fromRGB(0, 240, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 13
ToggleBtn.Text = "⚡ ENI HUB v6"
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)
local ToggleStroke = Instance.new("UIStroke", ToggleBtn)
ToggleStroke.Color = Color3.fromRGB(145, 55, 255)
ToggleStroke.Thickness = 2

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 520, 0, 380)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(14, 12, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(130, 50, 240)
MainStroke.Thickness = 2

-- TopBar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 38)
TopBar.BackgroundColor3 = Color3.fromRGB(24, 18, 42)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 12)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -60, 1, 0)
TitleLabel.Position = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚡ ENI HUB v6.0 — Anime Piece (GGMAX Pro Suite)"
TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 26)
MinBtn.Position = UDim2.new(1, -36, 0, 6)
MinBtn.BackgroundColor3 = Color3.fromRGB(48, 34, 82)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 14
MinBtn.Parent = TopBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- Drag
local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

MinBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
ToggleBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

-- Status Panel
local StatusPanel = Instance.new("Frame")
StatusPanel.Size = UDim2.new(1, -24, 0, 56)
StatusPanel.Position = UDim2.new(0, 12, 0, 44)
StatusPanel.BackgroundColor3 = Color3.fromRGB(21, 17, 34)
StatusPanel.Parent = MainFrame
Instance.new("UICorner", StatusPanel).CornerRadius = UDim.new(0, 8)
local StatusStroke = Instance.new("UIStroke", StatusPanel)
StatusStroke.Color = Color3.fromRGB(0, 210, 255)
StatusStroke.Thickness = 1

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -16, 1, -6)
StatusText.Position = UDim2.new(0, 8, 0, 3)
StatusText.BackgroundTransparency = 1
StatusText.TextColor3 = Color3.fromRGB(0, 240, 255)
StatusText.Font = Enum.Font.GothamMedium
StatusText.TextSize = 11
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.TextYAlignment = Enum.TextYAlignment.Center
StatusText.Text = "Carregando telemetria da conta..."
StatusText.Parent = StatusPanel

-- Barra de Abas (Tabs)
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -24, 0, 32)
TabBar.Position = UDim2.new(0, 12, 0, 106)
TabBar.BackgroundTransparency = 1
TabBar.Parent = MainFrame

local TabLayout = Instance.new("UIListLayout", TabBar)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 6)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder

local PagesFolder = Instance.new("Folder", MainFrame)
local tabPages = {}
local tabButtons = {}

local function createTab(tabName, order)
    local btn = Instance.new("TextButton")
    btn.LayoutOrder = order
    btn.Size = UDim2.new(0.19, 0, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(28, 22, 46)
    btn.TextColor3 = Color3.fromRGB(200, 200, 225)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Text = tabName
    btn.Parent = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local page = Instance.new("ScrollingFrame")
    page.Name = tabName
    page.Size = UDim2.new(1, -24, 1, -150)
    page.Position = UDim2.new(0, 12, 0, 144)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 4
    page.Visible = (order == 1)
    page.CanvasSize = UDim2.new(0, 0, 0, 320)
    page.Parent = PagesFolder

    local grid = Instance.new("UIGridLayout", page)
    grid.CellSize = UDim2.new(0.485, 0, 0, 34)
    grid.CellPadding = UDim2.new(0.02, 0, 0, 7)
    grid.SortOrder = Enum.SortOrder.LayoutOrder

    tabPages[tabName] = page
    tabButtons[tabName] = btn

    btn.MouseButton1Click:Connect(function()
        for name, p in pairs(tabPages) do
            p.Visible = (name == tabName)
            tabButtons[name].BackgroundColor3 = (name == tabName) and Color3.fromRGB(95, 45, 180) or Color3.fromRGB(28, 22, 46)
            tabButtons[name].TextColor3 = (name == tabName) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 225)
        end
    end)

    if order == 1 then
        btn.BackgroundColor3 = Color3.fromRGB(95, 45, 180)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    return page
end

local PageFarm    = createTab("⚡ Farm", 1)
local PageItems   = createTab("🗡️ Itens", 2)
local PageFruits  = createTab("🍎 Frutas", 3)
local PageWebhook = createTab("📡 GGMAX", 4)
local PageTP      = createTab("🏝️ Teleportes", 5)

local itemOrder = 0
local function addToggle(page, label, configKey)
    itemOrder = itemOrder + 1
    local btn = Instance.new("TextButton")
    btn.LayoutOrder = itemOrder
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 11
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Parent = page
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

    local function refresh()
        local on = getgenv().ENI_Config[configKey]
        btn.Text = (on and "🟢 " or "🔴 ") .. label
        btn.BackgroundColor3 = on and Color3.fromRGB(36, 98, 66) or Color3.fromRGB(32, 27, 48)
    end
    btn.MouseButton1Click:Connect(function()
        getgenv().ENI_Config[configKey] = not getgenv().ENI_Config[configKey]
        refresh()
    end)
    refresh()
end

local function addAction(page, label, callback)
    itemOrder = itemOrder + 1
    local btn = Instance.new("TextButton")
    btn.LayoutOrder = itemOrder
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Text = label
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = Color3.fromRGB(75, 40, 140)
    btn.Parent = page
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    btn.MouseButton1Click:Connect(function()
        task.spawn(callback)
    end)
end

-- Populando Aba 1: Farm
addToggle(PageFarm, "⚡ Turbo Task Farm (XP/$)", "TurboTaskFarm")
addToggle(PageFarm, "⚔️ Auto Farm Combate", "AutoFarmCombat")
addToggle(PageFarm, "Auto Skills (Z/X/C/V)", "AutoSkills")
addToggle(PageFarm, "Auto Stats (Max 300)", "AutoStats")
addToggle(PageFarm, "Auto Armament Haki", "AutoHaki")
addToggle(PageFarm, "🛡️ Auto-Rejoin Anti-Kick", "AutoRejoin")
addToggle(PageFarm, "🧰 Auto Farm Baús", "AutoChest")
addAction(PageFarm, "🔄 Arma: Sword / Style / Fruit", function()
    local cur = getgenv().ENI_Config.PreferredType
    getgenv().ENI_Config.PreferredType = (cur == "Swords" and "FightStyles") or (cur == "FightStyles" and "Fruits") or "Swords"
end)

-- Populando Aba 2: Itens & Crafts (Escolhíveis)
addToggle(PageItems, "Pegar Espadas da Loja", "GrabShopSwords")
addToggle(PageItems, "Pegar Ferramentas & Poses", "GrabToolsPoses")
addToggle(PageItems, "Pegar Acessórios Loja", "GrabAccessories")
addToggle(PageItems, "Farmar & Comprar Flash Step", "FarmFlashStep")
addToggle(PageItems, "Comprar Black Leg (Sanjiro)", "FarmBlackLeg")
addToggle(PageItems, "Farmar Robotic Style", "FarmRoboticStyle")
addToggle(PageItems, "Farmar Shadow Blade", "FarmShadowBlade")
addToggle(PageItems, "Comprar Divergent Style", "FarmDivergentStyle")
addToggle(PageItems, "Desbloquear Haki V1/V2/V3", "FarmArmamentHaki")
addToggle(PageItems, "Girar Raça Top (Infernal/Curse)", "AutoSpinTopRace")
addAction(PageItems, "⚡ Executar Compras Selecionadas", runSelectiveUnlocks)
addAction(PageItems, "🎁 Resgatar Todos os Códigos", function()
    if SettingsRemote then
        for _, c in ipairs({"4kCCU", "200kVisits!", "AllGamePass"}) do
            safeFireRemote(SettingsRemote, "UseCode", c)
        end
    end
end)

-- Populando Aba 3: Frutas & Hop
addToggle(PageFruits, "🧲 Auto Pegar Frutas Mapa", "AutoGrabDrops")
addToggle(PageFruits, "📦 Auto Guardar no Storage", "AutoStoreFruits")
addToggle(PageFruits, "🎰 Auto Girar Fruta ($35k)", "AutoSpinFruit")
addToggle(PageFruits, "🛒 Auto Comprar Mítica Loja", "AutoBuyMythicStock")
addToggle(PageFruits, "🌐 Auto Server Hop Fruit", "AutoHopFruit")
addAction(PageFruits, "🎰 Girar Fruta Agora ($)", function()
    safeFireRemote(DialogueRemote, {"SpinFruit", ""})
end)
addAction(PageFruits, "🌐 Pular de Servidor Agora", serverHop)

-- Populando Aba 4: Webhook & GGMAX
local WebhookBox = Instance.new("TextBox")
WebhookBox.LayoutOrder = 1
WebhookBox.PlaceholderText = "Cole aqui a URL do Discord Webhook..."
WebhookBox.Text = getgenv().ENI_Config.WebhookUrl or ""
WebhookBox.Font = Enum.Font.Gotham
WebhookBox.TextSize = 11
WebhookBox.TextColor3 = Color3.fromRGB(255, 255, 255)
WebhookBox.BackgroundColor3 = Color3.fromRGB(28, 24, 44)
WebhookBox.ClearTextOnFocus = false
WebhookBox.Parent = PageWebhook
Instance.new("UICorner", WebhookBox).CornerRadius = UDim.new(0, 7)
WebhookBox.FocusLost:Connect(function()
    getgenv().ENI_Config.WebhookUrl = WebhookBox.Text
end)

addToggle(PageWebhook, "Auto Webhook Conta Pronta", "AutoSendWebhook")
addAction(PageWebhook, "📤 Enviar Relatório GGMAX Agora", function()
    sendGGMAXWebhook("📊 Relatório Manual de Conta GGMAX")
end)
addAction(PageWebhook, "📋 Copiar Anúncio GGMAX (Clipboard)", function()
    if setclipboard then
        local s = getFormattedInventorySummary()
        local ps = getPlayerStatsFolder()
        setclipboard(string.format(
            "CONTA ANIME PIECE LVL %d | Money: $%d | Raça: %s | Fruta: %s | Storage: %s | Espadas: %s",
            ps.Infos.Level.Value, ps.Infos.Money.Value, ps.Build.ActualRace.Value,
            ps.Build.ActualFruit.Value, s.fruits, s.swords
        ))
    end
end)

-- Populando Aba 5: Teleportes
for islandName, islandPos in pairs(IslandPositions) do
    addAction(PageTP, "🏝️ TP: " .. islandName, function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(islandPos) end
    end)
end

-- ====================================================================
-- 8. CONEXÃO STEPPED: HOVER, NOCLIP E GRAVIDADE ZERO
-- ====================================================================
local currentTargetPart = nil
local currentFarmState = "Iniciando..."

local stepConn = RunService.Stepped:Connect(function()
    if getgenv().ENI_HubId ~= HubId then return end
    if getgenv().ENI_Config.AutoFarmCombat or getgenv().ENI_Config.AutoChest then
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and currentTargetPart and currentTargetPart.Parent then
                local tPos = currentTargetPart.Position
                local hoverPos = tPos + Vector3.new(0, getgenv().ENI_Config.HoverHeight, 0)
                hrp.CFrame = CFrame.new(hoverPos, tPos)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end
end)

-- ====================================================================
-- 9. LOOP PRINCIPAL INTELIGENTE (FARM + ITENS + FRUTAS + WEBHOOK)
-- ====================================================================
local comboHit = 1
local lastQuestFire = 0
local lastHakiCheck = 0
local lastGachaTry = 0
local lastUnlockCheck = 0
local webhookSentOnce = false

task.spawn(function()
    runSelectiveUnlocks()

    while getgenv().ENI_HubId == HubId do
        pcall(function()
            local ps = getPlayerStatsFolder()
            if not ps then return end

            local cfg = getgenv().ENI_Config
            local level = ps.Infos.Level.Value
            local money = ps.Infos.Money.Value
            local questId = ps.Quest.QuestId.Value
            local questProg = ps.Quest.Progress.Value
            local statsPoints = ps.Stats.StatsPoints.Value

            -- 1. AUTO-STATS
            if cfg.AutoStats and statsPoints >= 6 then
                if ps.Stats.Swords.Value < 300 then
                    safeFireRemote(StatsRemote, "UsePoints", "Swords", math.min(statsPoints, 300 - ps.Stats.Swords.Value))
                elseif ps.Stats.Defense.Value < 300 then
                    safeFireRemote(StatsRemote, "UsePoints", "Defense", math.min(statsPoints, 300 - ps.Stats.Defense.Value))
                elseif ps.Stats.FightStyles.Value < 300 then
                    safeFireRemote(StatsRemote, "UsePoints", "FightStyles", math.min(statsPoints, 300 - ps.Stats.FightStyles.Value))
                elseif ps.Stats.Stamina.Value < 300 then
                    safeFireRemote(StatsRemote, "UsePoints", "Stamina", math.min(statsPoints, 300 - ps.Stats.Stamina.Value))
                end
            end

            -- 2. CHECAGEM PERIÓDICA DE COMPRAS SELECIONADAS (A CADA 45s)
            if os.clock() - lastUnlockCheck > 45 then
                lastUnlockCheck = os.clock()
                runSelectiveUnlocks()
            end

            -- 3. AUTO-COMPRAR FRUTA MÍTICA NA LOJA (INFINITY / VESSEL)
            if cfg.AutoBuyMythicStock and FruitShopRemote then
                local stockFolder = ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("Fruit Stock")
                if stockFolder then
                    for _, mythic in ipairs({"Vessel", "Infinity", "Beast", "Quake"}) do
                        if stockFolder:FindFirstChild(mythic) and ps.Build.ActualFruit.Value ~= mythic then
                            if (mythic == "Vessel" and money >= 265000) or (mythic == "Infinity" and money >= 225000) then
                                safeFireRemote(FruitShopRemote, "Buy", mythic)
                            end
                        end
                    end
                end
            end

            -- 4. AUTO-PEGAR FRUTAS NO MAPA
            local foundMapFruit = false
            if cfg.AutoGrabDrops then
                local droppedFolder = Workspace:FindFirstChild("World")
                    and Workspace.World:FindFirstChild("Playability")
                    and Workspace.World.Playability:FindFirstChild("DroppedTools")
                if droppedFolder then
                    for _, drop in ipairs(droppedFolder:GetChildren()) do
                        local handle = drop:FindFirstChild("Handle") or drop:FindFirstChildWhichIsA("BasePart")
                        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if handle and hrp then
                            foundMapFruit = true
                            currentFarmState = "🍎 Coletando Fruta no Mapa: " .. drop.Name
                            hrp.CFrame = handle.CFrame
                            if firetouchinterest then
                                pcall(firetouchinterest, hrp, handle, 0)
                                pcall(firetouchinterest, hrp, handle, 1)
                            end
                            task.wait(0.2)
                        end
                    end
                end
            end

            -- 5. AUTO-GUARDAR FRUTAS NO STORAGE
            if cfg.AutoStoreFruits then
                local gd = getGameData()
                local itemsData = gd and gd["Items Data"]
                if itemsData and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
                        if tool:IsA("Tool") and itemsData[tool.Name] and itemsData[tool.Name].Category == "Fruits" then
                            LocalPlayer.Character.Humanoid:EquipTool(tool)
                            task.wait(0.25)
                            safeFireRemote(PhysicalFruitsRemote, "Storage", tool.Name)
                            if cfg.WebhookUrl ~= "" then
                                task.spawn(function()
                                    sendGGMAXWebhook("🍎 Nova Fruta Guardada: " .. tool.Name)
                                end)
                            end
                        end
                    end
                end
            end

            -- 6. AUTO-GIRAR FRUTA (LUZEFE)
            if cfg.AutoSpinFruit and level >= 50 and os.clock() - lastGachaTry > 20 then
                local spinCd = ps.Infos:FindFirstChild("LastFruitTimeSpin")
                if (not spinCd or spinCd.Value <= 0) and money >= 35000 then
                    lastGachaTry = os.clock()
                    safeFireRemote(DialogueRemote, {"SpinFruit", ""})
                end
            end

            -- 7. AUTO SERVER HOP FRUIT
            if cfg.AutoHopFruit and not foundMapFruit then
                currentFarmState = "🌐 Hop Fruit: Trocando de servidor..."
                task.wait(2)
                serverHop()
                return
            end

            -- 8. AUTO-WEBHOOK CONTA PRONTA GGMAX
            if cfg.AutoSendWebhook and not webhookSentOnce and level >= 245 and money >= cfg.TargetMoneyGGMAX then
                webhookSentOnce = true
                task.spawn(function()
                    sendGGMAXWebhook("🔥 CONTA LEVEL MAX (245) PRONTA PARA GGMAX!")
                end)
            end

            -- 9. AUTO-HAKI
            if cfg.AutoHaki and HakiRemote and ps.Build.ArmamentHaki.Value then
                if os.clock() - lastHakiCheck > 8 then
                    lastHakiCheck = os.clock()
                    local char = LocalPlayer.Character
                    if char and not char:GetAttribute("ArmamentHaki") then
                        safeFireRemote(HakiRemote)
                    end
                end
            end

            -- 10. AUTO-BAÚS
            if cfg.AutoChest then
                local chestsFolder = Workspace:FindFirstChild("World")
                    and Workspace.World:FindFirstChild("Playability")
                    and Workspace.World.Playability:FindFirstChild("Chests")
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if chestsFolder and hrp then
                    for _, chest in ipairs(chestsFolder:GetChildren()) do
                        local hitbox = chest:FindFirstChild("Hitbox")
                        if hitbox and hitbox:FindFirstChildOfClass("TouchTransmitter") then
                            currentFarmState = "🧰 Coletando Baú: " .. chest.Name
                            hrp.CFrame = hitbox.CFrame
                            if firetouchinterest then
                                pcall(firetouchinterest, hrp, hitbox, 0)
                                pcall(firetouchinterest, hrp, hitbox, 1)
                            end
                            task.wait(0.25)
                            break
                        end
                    end
                end
            end

            -- 11. PRIORIDADE DE MATERIAIS ESPECÍFICOS (SOULS / GEARS / MAGIC BALL)
            local matTarget = getPriorityMaterialTarget()
            if matTarget and cfg.AutoFarmCombat then
                local mob = findAliveMobForList(matTarget.mobs)
                if mob then
                    local mhrp = mob:FindFirstChild("HumanoidRootPart")
                    if not mhrp then
                        currentTargetPart = nil
                        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then hrp.CFrame = CFrame.new(mob:GetPivot().Position + Vector3.new(0, 12, 0)) end
                        currentFarmState = matTarget.reason .. " (Renderizando...)"
                    else
                        currentTargetPart = mhrp
                        currentFarmState = matTarget.reason .. " -> " .. mob.Name
                        local tool = ensureWeaponEquipped()
                        if safeFireCombat(comboHit) then
                            comboHit = (comboHit >= 4) and 1 or (comboHit + 1)
                            if comboHit == 1 then getgenv().ENI_LastM1Fire = os.clock() + 0.82 end
                        end
                        if tool then fireWeaponSkills(tool.Name, mhrp.Position) end
                    end
                else
                    currentTargetPart = nil
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp.Position - matTarget.pos).Magnitude > 50 then
                        hrp.CFrame = CFrame.new(matTarget.pos + Vector3.new(0, 10, 0))
                    end
                    currentFarmState = matTarget.reason .. " (Aguardando Respawn)"
                end

            -- 12. TURBO TASK FARM (100% DIALOGUE EVENT = ZERO KICK!)
            elseif cfg.TurboTaskFarm and level >= 100 then
                currentTargetPart = nil
                currentFarmState = "⚡ Turbo Task [ElementsQuest] (+2k XP / +$500)"
                if questId ~= "ElementsQuest" and questId ~= "None" then
                    safeFireRemote(QuestRemote, "Quit")
                end
                if ps.Quest.QuestId.Value == "None" then
                    safeFireRemote(DialogueRemote, {"Quest", "ElementsQuest"})
                end
                for _, el in ipairs({"Blue Element", "Red Element", "Pink Element", "Yellow Element"}) do
                    if getgenv().ENI_HubId ~= HubId or not getgenv().ENI_Config.TurboTaskFarm then break end
                    safeFireRemote(DialogueRemote, {"ElementsQuest", el})
                end

            -- 13. COMBAT AUTO-FARM (MOBS & BOSSES)
            elseif cfg.AutoFarmCombat then
                local targetQuest = getBestQuestForLevel(level)

                if LocalPlayer:GetAttribute("RepeatQuestUi") and questId == "None" then
                    safeFireRemote(QuestRemote, "Repeat")
                    LocalPlayer:SetAttribute("RepeatQuestUi", nil)
                    questId = ps.Quest.QuestId.Value
                end

                if questId ~= "None" and questId ~= targetQuest.id and os.clock() - lastQuestFire > 1.0 then
                    lastQuestFire = os.clock()
                    safeFireRemote(QuestRemote, "Quit")
                    questId = ps.Quest.QuestId.Value
                end

                if questId == "None" and os.clock() - lastQuestFire > 0.8 then
                    lastQuestFire = os.clock()
                    safeFireRemote(DialogueRemote, {"Quest", targetQuest.id})
                    questId = ps.Quest.QuestId.Value
                end

                local activeQuestObj = QuestById[questId] or targetQuest
                local mob = findAliveMobForList(activeQuestObj.mobs)

                if mob then
                    local mhrp = mob:FindFirstChild("HumanoidRootPart")
                    local mhum = mob:FindFirstChildOfClass("Humanoid")
                    if not mhrp then
                        currentTargetPart = nil
                        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then hrp.CFrame = CFrame.new(mob:GetPivot().Position + Vector3.new(0, 12, 0)) end
                        currentFarmState = "Carregando ilha (" .. activeQuestObj.island .. ")..."
                    else
                        currentTargetPart = mhrp
                        local hpStr = mhum and string.format("%d/%d", math.floor(mhum.Health), math.floor(mhum.MaxHealth)) or "?"
                        currentFarmState = string.format("Atacando: %s (%s)", mob.Name, hpStr)
                        local tool = ensureWeaponEquipped()
                        if safeFireCombat(comboHit) then
                            comboHit = (comboHit >= 4) and 1 or (comboHit + 1)
                            if comboHit == 1 then getgenv().ENI_LastM1Fire = os.clock() + 0.82 end
                        end
                        if tool then fireWeaponSkills(tool.Name, mhrp.Position) end
                    end
                else
                    currentTargetPart = nil
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp.Position - activeQuestObj.pos).Magnitude > 50 then
                        hrp.CFrame = CFrame.new(activeQuestObj.pos + Vector3.new(0, 10, 0))
                    end
                    currentFarmState = "Aguardando respawn: " .. table.concat(activeQuestObj.mobs, "/")
                end
            else
                currentTargetPart = nil
                currentFarmState = "Em espera"
            end

            StatusText.Text = string.format(
                "👤 %s | ⭐ Lvl: %d/245 | 💰 $%d | 🧬 %s | 🍎 %s\n📜 Quest: [%s] | 🎯 %s",
                LocalPlayer.Name, level, money, ps.Build.ActualRace.Value,
                ps.Build.ActualFruit.Value, tostring(questId), currentFarmState
            )
        end)
        task.wait(0.05)
    end
end)

getgenv().ENI_HubCleanup = function()
    getgenv().ENI_HubId = "STOPPED"
    getgenv().ENI_LoopId = "STOPPED"
    if stepConn then stepConn:Disconnect() end
    if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
end

print("[ENI Hub v6.0] GGMAX Ultimate Suite carregada com sucesso!")
