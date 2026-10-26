-- ====================================================================
-- 🤖 ENI KAITAN GGMAX v8.0 - AUTO FARM LEVEL MAX + $1M BELI + GRAB ALL
-- Script 100% Automático (Kaitan) para Farmar Contas do 0 ao 245 Max
-- Level 0 -> 84 (Combate) | Level 85 -> 245 Max + $1,000,000 (ElementsQuest 0 Kick)
-- Pega Espadas, Estilos, Haki, Raça Mítica, Frutas + Auto Rejoin + Webhook
-- ====================================================================

repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

-- Registra queue_on_teleport para auto-reexecutar o Kaitan em caso de kick ou teleporte
local qot = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
if qot and not getgenv().ENI_KaitanQueued then
    getgenv().ENI_KaitanQueued = true
    pcall(function()
        qot([[
            repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Pedrohs1771/anime-piece-ggmax/main/kaitan_ggmax.lua"))()
        ]])
    end)
end

getgenv().GGMAX_Kaitan = getgenv().GGMAX_Kaitan or {
    WebhookUrl         = "",            -- Cole seu Webhook do Discord aqui
    TargetLevel        = 245,           -- Level Máximo do jogo (245)
    TargetMoney        = 1000000,       -- Dinheiro Máximo ($1,000,000 Cap) antes de notificar no Webhook
    GrabAllShopSwords  = true,          -- Katana, Future Sword, Iron Spear, Raven Axe
    GrabAllToolsPoses  = true,          -- Axe, Iron Hoe, Wrench, Pickaxe + Todas as Poses
    GrabAllAccessories = true,          -- Scouter, Uniforms, Basic Dark Cloak
    UnlockFlashStep    = true,          -- Farma as Souls e compra Flash Step
    UnlockBlackLeg     = true,          -- Compra Black Leg ($15k)
    UnlockRoboticStyle = true,          -- Farma 45x Gear + 5x Core e compra Robotic Style
    UnlockShadowBlade  = true,          -- Farma 2x Magic Ball e compra Shadow Blade
    UnlockHaki         = true,          -- Compra Armament Haki V1 / V2 / V3
    SpinTopRace        = true,          -- Gira Raça até Infernal / Curse / Fighter / Gamer
    BuyMythicStock     = true,          -- Compra Infinity ($225k) ou Vessel ($265k) se na loja
    AutoSpinFruit      = true,          -- Gira fruta no Luzefe a cada 1h e guarda no Storage
    AutoGrabMapFruits  = true,          -- Pega frutas no chão e guarda no Storage
    AutoRejoinOnKick   = true,          -- Reentra sozinho se cair ou tomar kick
}

-- Sincroniza configurações com o motor do ENI Hub v7.0
getgenv().ENI_Config = {
    TurboTaskFarm      = true,
    AutoFarmCombat     = true,
    AutoSkills         = true,
    AutoStats          = true,
    AutoHaki           = true,
    AutoRejoin         = getgenv().GGMAX_Kaitan.AutoRejoinOnKick,
    HoverHeight        = 5.8,
    PreferredType      = "Swords",
    GrabShopSwords     = getgenv().GGMAX_Kaitan.GrabAllShopSwords,
    GrabToolsPoses     = getgenv().GGMAX_Kaitan.GrabAllToolsPoses,
    GrabAccessories    = getgenv().GGMAX_Kaitan.GrabAllAccessories,
    FarmFlashStep      = getgenv().GGMAX_Kaitan.UnlockFlashStep,
    FarmBlackLeg       = getgenv().GGMAX_Kaitan.UnlockBlackLeg,
    FarmRoboticStyle   = getgenv().GGMAX_Kaitan.UnlockRoboticStyle,
    FarmShadowBlade    = getgenv().GGMAX_Kaitan.UnlockShadowBlade,
    FarmDivergentStyle = true,
    FarmArmamentHaki   = getgenv().GGMAX_Kaitan.UnlockHaki,
    AutoSpinTopRace    = getgenv().GGMAX_Kaitan.SpinTopRace,
    AutoGrabDrops      = getgenv().GGMAX_Kaitan.AutoGrabMapFruits,
    AutoStoreFruits    = true,
    AutoSpinFruit      = getgenv().GGMAX_Kaitan.AutoSpinFruit,
    AutoBuyMythicStock = getgenv().GGMAX_Kaitan.BuyMythicStock,
    AutoHopFruit       = false,
    AutoChest          = false,
    WebhookUrl         = getgenv().GGMAX_Kaitan.WebhookUrl,
    AutoSendWebhook    = true,
    TargetMoneyGGMAX   = getgenv().GGMAX_Kaitan.TargetMoney,
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/Pedrohs1771/anime-piece-ggmax/main/eni_hub.lua"))()
