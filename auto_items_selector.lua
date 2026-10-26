-- ====================================================================
-- 🗡️ ENI AUTO ITEMS & CRAFTS SELECTOR v8.0 - ANIME PIECE (GGMAX)
-- Escolha exatamente quais Espadas, Estilos, Haki, Acessórios e Raça
-- você quer que o script farme os materiais (Souls, Gears, Cores, etc.) e compre!
-- ====================================================================

repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

-- Registra queue_on_teleport para auto-reexecutar em caso de kick/rejoin
local qot = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
if qot and not getgenv().ENI_ItemsQueued then
    getgenv().ENI_ItemsQueued = true
    pcall(function()
        qot([[
            repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Pedrohs1771/anime-piece-ggmax/main/auto_items_selector.lua"))()
        ]])
    end)
end

getgenv().ENI_ItemsSelector = getgenv().ENI_ItemsSelector or {
    GrabShopSwords     = true,  -- Katana, Future Sword, Iron Spear, Raven Axe
    GrabToolsPoses     = true,  -- Axe, Iron Hoe, Wrench, Pickaxe, Todas as Poses
    GrabAccessories    = true,  -- Scouter, Uniforms, Basic Dark Cloak
    FarmFlashStep      = true,  -- Farma 15x Bandit Soul, 15x Higaro Bandit Soul, 5x Higaro Soul e compra Flash Step
    FarmBlackLeg       = true,  -- Compra Black Leg ($15,000)
    FarmRoboticStyle   = true,  -- Farma 45x Robotic Gear + 5x Robotic Core e compra Robotic Style
    FarmShadowBlade    = true,  -- Farma 2x Magic Ball (Old Fighter) e compra Shadow Blade
    FarmDivergentStyle = true,  -- Compra Divergent Style ($35,000)
    FarmArmamentHaki   = true,  -- Desbloqueia Armament Haki V1 / V2 / V3
    AutoSpinTopRace    = true,  -- Gira Raça até pegar Infernal / Curse / Fighter / Gamer
    WebhookUrl         = "",    -- Opcional: Webhook para notificar
}

getgenv().ENI_Config = {
    TurboTaskFarm      = false, -- Foca no combate dos mobs que dropam os materiais selecionados!
    AutoFarmCombat     = true,
    AutoSkills         = true,
    AutoStats          = true,
    AutoHaki           = true,
    AutoRejoin         = true,
    HoverHeight        = 5.8,
    PreferredType      = "Swords",
    GrabShopSwords     = getgenv().ENI_ItemsSelector.GrabShopSwords,
    GrabToolsPoses     = getgenv().ENI_ItemsSelector.GrabToolsPoses,
    GrabAccessories    = getgenv().ENI_ItemsSelector.GrabAccessories,
    FarmFlashStep      = getgenv().ENI_ItemsSelector.FarmFlashStep,
    FarmBlackLeg       = getgenv().ENI_ItemsSelector.FarmBlackLeg,
    FarmRoboticStyle   = getgenv().ENI_ItemsSelector.FarmRoboticStyle,
    FarmShadowBlade    = getgenv().ENI_ItemsSelector.FarmShadowBlade,
    FarmDivergentStyle = getgenv().ENI_ItemsSelector.FarmDivergentStyle,
    FarmArmamentHaki   = getgenv().ENI_ItemsSelector.FarmArmamentHaki,
    AutoSpinTopRace    = getgenv().ENI_ItemsSelector.AutoSpinTopRace,
    AutoGrabDrops      = true,
    AutoStoreFruits    = true,
    AutoSpinFruit      = true,
    AutoBuyMythicStock = true,
    AutoHopFruit       = false,
    AutoChest          = false,
    WebhookUrl         = getgenv().ENI_ItemsSelector.WebhookUrl,
    AutoSendWebhook    = false,
    TargetMoneyGGMAX   = 500000,
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/Pedrohs1771/anime-piece-ggmax/main/eni_hub.lua"))()
