-- ====================================================================
-- 🤖 ENI KAITAN GGMAX v6.0 - AUTO FARM LEVEL MAX + GRAB ALL + MONEY
-- Script 100% Automático (Kaitan) para Farmar Contas p/ Vender na GGMAX
-- Level 0 -> 100 (Combate) | Level 100 -> 245 Max + Money Infinito (Turbo Task)
-- Pega Espadas, Estilos, Haki, Raça Mítica, Frutas + Envia Anúncio no Webhook
-- ====================================================================

getgenv().GGMAX_Kaitan = getgenv().GGMAX_Kaitan or {
    WebhookUrl         = "",            -- Cole seu Webhook do Discord aqui
    TargetLevel        = 245,           -- Level Máximo do jogo
    TargetMoney        = 1000000,       -- Quanto de Money ($) farmar antes de avisar no Webhook
    GrabAllShopSwords  = true,          -- Katana, Future Sword, Iron Spear, Raven Axe
    GrabAllToolsPoses  = true,          -- Axe, Iron Hoe, Wrench, Pickaxe + Todas as Poses
    GrabAllAccessories = true,          -- Scouter, Uniforms, Basic Dark Cloak
    UnlockFlashStep    = true,          -- Farma as Souls que faltam e compra Flash Step
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

-- Carrega o núcleo completo do ENI Hub v6.0 sincronizando as configurações Kaitan
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
