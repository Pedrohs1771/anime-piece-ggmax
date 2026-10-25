================================================================================
⚡ ANIME PIECE - DOCUMENTAÇÃO TÉCNICA COMPLETA DE REMOTES, DADOS & ENGENHARIA ⚡
Desenvolvido por ENI para Tris (Pedro) - Guia Definitivo de Scripting & Reverse Eng
PlaceId: 134039915751463 | Versão: Release 0.5 | Plataforma: Roblox (Luau)
================================================================================

--------------------------------------------------------------------------------
SUMÁRIO
--------------------------------------------------------------------------------
1. ESTRUTURA GERAL DE PASTAS & SERVIÇOS
2. TODOS OS REMOTES (NOMES, LOCALIZAÇÃO, ARGUMENTOS & EXEMPLOS)
3. SISTEMA DE DIÁLOGOS (DIALOGUE EVENT - TABELA COMPLETA DE NPCS E PAYLOADS)
4. TABELA COMPLETA DE MISSÕES (QUESTS: ID, NÍVEL, ALVO, COORDENADAS, XP & BELI)
5. TABELA COMPLETA DE CHEFES (BOSSES: HP, DROP, LOCALIZAÇÃO & SPAWN)
6. ARSENAL, ESPADAS, ACESSÓRIOS & RECEITAS DE CRAFT
7. ESTILOS DE LUTA (FIGHTING STYLES) & HAKI V1 / V2 / V3
8. SISTEMA DE FRUTAS (GACHA, LOJA, STORAGE & RARIDADES)
9. SISTEMA DE RAÇAS & GIROS (SPINS)
10. ESTRUTURA DE DADOS DO JOGADOR (PLAYERSTATS, BUILD, INFOS & INVENTÁRIO)
11. ENGENHARIA ANTI-KICK, RATE LIMITS, HOVER LOCK & QUEUE_ON_TELEPORT
12. SNIPPETS ÚTEIS PRONTOS PARA COPIAR E COLAR

================================================================================
1. ESTRUTURA GERAL DE PASTAS & SERVIÇOS
================================================================================

Os serviços essenciais do Anime Piece no Roblox são:
- game:GetService("Players")             -> LocalPlayer, Backpack, Character
- game:GetService("ReplicatedStorage")   -> Remotes, Shared, Package
- game:GetService("Workspace")           -> World.Playability (Enemys, DroppedTools)
- game:GetService("RunService")          -> Heartbeat, RenderStepped
- game:GetService("TeleportService")     -> Teleport, TeleportToPlaceInstance
- game:GetService("HttpService")         -> JSONEncode, JSONDecode, HttpGet
- game:GetService("GuiService")          -> ErrorMessageChanged, ClearError, GetErrorCode

Localizações Críticas de Instâncias:
- Remotes:           game.ReplicatedStorage.Remotes
- Specials Remotes:  game.ReplicatedStorage.Remotes["Specials Remotes"]
- Player Stats:      game.ReplicatedStorage.Shared.PlayerStats[LocalPlayer.Name]
- Fruit Stock:       game.ReplicatedStorage.Shared["Fruit Stock"]
- Inimigos / Mobs:   game.Workspace.World.Playability.Enemys
- Frutas no Chão:    game.Workspace.World.Playability.DroppedTools
- Inventário Local:  (getrenv()._G and getrenv()._G.ClientInventory) or _G.ClientInventory
- Base de Dados:     (getrenv()._G and getrenv()._G.GameData) or _G.GameData

================================================================================
2. TODOS OS REMOTES (NOMES, LOCALIZAÇÃO, ARGUMENTOS & EXEMPLOS)
================================================================================

Todos localizados em: game.ReplicatedStorage.Remotes

1. "Combat Event" (RemoteEvent)
   - Função: Executa os golpes básicos (M1 / Ataque comum) com a arma equipada.
   - Argumento: comboIndex (número de 1 a 4)
   - Exemplo:
     CombatRemote:FireServer(1) -- Hit 1
     CombatRemote:FireServer(2) -- Hit 2
     CombatRemote:FireServer(3) -- Hit 3
     CombatRemote:FireServer(4) -- Hit 4 (Reset de combo)
   - Requisito Crítico do Servidor: O jogador DEVE ter os atributos:
     LocalPlayer:SetAttribute("ActualTool", tool.Name)
     LocalPlayer:SetAttribute("HasAttackItem", true)
     E disparar CustomToolRemote:FireServer("Equip") pelo menos uma vez ao equipar.

2. "Skill Event" (RemoteEvent)
   - Função: Ativa habilidades especiais de espadas, frutas e estilos.
   - Argumentos: (skillName, state, [targetPosition])
     - state: "Hold" (segurar) ou "Release" (soltar/disparar)
     - targetPosition: Vector3 opcional para skills direcionadas
   - Exemplo (Raven Axe):
     SkillRemote:FireServer("Ravenous impact", "Hold")
     task.wait(0.24)
     SkillRemote:FireServer("Ravenous impact", "Release", targetPos)
     SkillRemote:FireServer("Crow cyclone", "Hold")
     task.wait(0.24)
     SkillRemote:FireServer("Crow cyclone", "Release", targetPos)

3. "Quest Event" (RemoteEvent)
   - Função: Gerencia o cancelamento ou repetição de missões ativas.
   - Argumento: string ("Quit" ou "Repeat")
   - Exemplo:
     QuestRemote:FireServer("Quit")   -- Cancela a missão atual imediatamente
     QuestRemote:FireServer("Repeat") -- Repete a última missão concluída

4. "Dialogue Event" (RemoteEvent)
   - Função: É o remote MAIS IMPORTANTE do jogo. Controla aceitação de missões,
     compras em NPCs, forja de espadas, Haki, Flash Step, giros e tarefas.
   - Argumento: tabela { npcOuAcao, parametro }
   - Exemplos:
     DialogueRemote:FireServer({"Quest", "025"})          -- Pega a Quest 025 (Cursed Dolls)
     DialogueRemote:FireServer({"Quest", "ElementsQuest"})-- Pega a Quest dos Elementos
     DialogueRemote:FireServer({"SpinFruit", ""})         -- Gira fruta no Luzefe ($35k)
     DialogueRemote:FireServer({"Flash Step", "Buy"})     -- Compra Flash Step
     DialogueRemote:FireServer({"Sanjiro", "Buy"})        -- Compra Black Leg ($15k)
     DialogueRemote:FireServer({"RobotTrainer", "Buy"})   -- Compra Robotic Style
     DialogueRemote:FireServer({"Shadow Swordsman", "Buy"})-- Forja Shadow Blade ($25k + 2x Magic Ball)
     DialogueRemote:FireServer({"Master Blacksmith", "Buy"})-- Forja Dual Sword
     DialogueRemote:FireServer({"UnlockKiDash", "BuyKiDash"})-- Compra Ki Dash ($10k + 3 Chaves)
     DialogueRemote:FireServer({"UnlockKiDash", "EquipKiDash"})-- Equipa Ki Dash

5. "Stats Event" (RemoteEvent)
   - Função: Distribui pontos de atributo ganhos ao subir de nível.
   - Argumentos: ("UsePoints", statCategory, amount)
     - statCategory: "Swords", "Defense", "FightStyles", "Stamina", "Fruits"
   - Exemplo:
     StatsRemote:FireServer("UsePoints", "Swords", 10)
     StatsRemote:FireServer("UsePoints", "Defense", 10)

6. "Custom Tool Event" (RemoteEvent)
   - Função: Registra no servidor que a arma atual foi sacada para combate.
   - Argumento: "Equip" ou "Unequip"
   - Exemplo:
     CustomToolRemote:FireServer("Equip")

7. "ItemBuyer Event" (RemoteEvent)
   - Função: Compra itens diretos da loja básica (espadas de NPC e roupas).
   - Argumento: nomeDoItem (string)
   - Itens Suportados:
     "Katana"           ($1,000)
     "Iron Spear"       ($3,000)
     "Future Sword"     ($5,000)
     "Raven Axe"        ($8,000)
     "Scouter"          ($2,500)
     "Basic Armor"      ($1,500)
     "Male Uniform"     ($2,000)
     "Female Uniform"   ($2,000)
     "Basic Dark Cloak" ($3,500)
     "Pickaxe"          ($1,000)
     "Axe"              ($1,000)
     "Iron Hoe"         ($1,000)
     "Wrench"           ($1,000)
   - Exemplo:
     ItemBuyerRemote:FireServer("Raven Axe")

8. "Physical Fruits Event" (RemoteEvent)
   - Função: Guarda frutas físicas no Storage do jogador.
   - Argumentos: "Store" ou ("Storage", fruitName)
   - Exemplo (Garante armazenamento em ambas as chamadas):
     PhysicalFruitsRemote:FireServer("Store")
     PhysicalFruitsRemote:FireServer("Storage", tool.Name)

9. "Fruit Shop Event" (RemoteEvent)
   - Função: Compra frutas que estão em estoque público no servidor.
   - Argumentos: ("Buy", fruitName)
   - Frutas Míticas de Estoque:
     "Infinity" ($225,000 Beli)
     "Vessel"   ($265,000 Beli)
   - Exemplo:
     FruitShopRemote:FireServer("Buy", "Infinity")

10. "Inventory Event" (RemoteEvent)
    - Função: Equipa armas ou acessórios diretamente do inventário do jogador.
    - Argumentos: ("Equip", itemName)
    - Exemplo:
      InventoryRemote:FireServer("Equip", "Raven Axe")

11. "Race Event" (RemoteEvent)
    - Função: Dispara o reroll de raça utilizando pontos de RaceRerollPoints.
    - Argumento: "Spin Race"
    - Exemplo:
      RaceRemote:FireServer("Spin Race")

12. "Settings Event" (RemoteEvent)
    - Função: Resgata códigos promocionais no servidor.
    - Argumentos: ("UseCode", codeString)
    - Códigos Funcionais:
      "4kCCU"
      "200kVisits!"
      "AllGamePass"
    - Exemplo:
      SettingsRemote:FireServer("UseCode", "4kCCU")

13. "Armament Haki Event" (RemoteEvent)
    - Função: Alterna a ativação visual e de buffs do Armament Haki no personagem.
    - Exemplo:
      HakiRemote:FireServer()

14. "Specials Remotes" (Folder) -> "Cursed Dolls Event" (RemoteEvent)
    - Função: Coleta os bonecos amaldiçoados da Quest 025 (Cursed Dolls).
    - Argumento: "CollectCurseDoll"
    - Exemplo:
      cdRemote:FireServer("CollectCurseDoll")
      -- Repita 5 vezes com delay de ~1.15s para concluir a missão (+36.938 XP).

15. Outros Remotes Auxiliares:
    - "Fast Travel Event": Teleporte rápido de ilha.
    - "Teleport Event": Teleporte de posição salvo no mapa.
    - "Boat Event": Compra e spawn de barcos ("Sloop", "Caravel", etc.).
    - "Party Event": Criação e gerenciamento de grupos de jogadores.
    - "Title Event": Equipar títulos conquistados.
    - "Fruit Notifier Event": Notificação quando uma fruta spawna no chão.
    - "Fruit Gacha": Remote alternativo do sistema de gacha.
    - "Stamina Event": Consumo e recuperação de estamina.

================================================================================
3. SISTEMA DE DIÁLOGOS (DIALOGUE EVENT - TABELA DE PAYLOADS)
================================================================================

O Dialogue Event é o centro de controle do servidor. Dispara-se assim:
game.ReplicatedStorage.Remotes["Dialogue Event"]:FireServer({ PARAM_1, PARAM_2 })

Tabela de Ações Mapeadas:
+---------------------+-------------------+-----------------------------------------+
| NPC / Ação (PARAM_1)| Valor (PARAM_2)   | Descrição do Efeito                    |
+---------------------+-------------------+-----------------------------------------+
| "Quest"             | "001" a "030"     | Aceita a missão de combate indicada    |
| "Quest"             | "ElementsQuest"   | Aceita a missão dos cientistas          |
| "ElementsQuest"     | "Blue Element"    | Entrega o elemento azul                |
| "ElementsQuest"     | "Red Element"     | Entrega o elemento vermelho            |
| "ElementsQuest"     | "Pink Element"    | Entrega o elemento rosa                |
| "ElementsQuest"     | "Yellow Element"  | Entrega o elemento amarelo (conclui)   |
| "SpinFruit"         | ""                | Gira fruta no NPC Luzefe ($35,000)     |
| "Flash Step"        | "Buy"             | Compra Flash Step (requer almas + $5.5k)|
| "Sanjiro"           | "Buy"             | Compra Black Leg Style ($15,000)       |
| "RobotTrainer"      | "Buy"             | Compra Robotic Style (Gears + Core)    |
| "Shadow Swordsman"  | "Buy"             | Forja Shadow Blade ($25k + 2x Magic Ball)|
| "Master Blacksmith" | "Buy"             | Forja Dual Sword (Shadow+Emerald+Balls)|
| "UnlockKiDash"      | "BuyKiDash"       | Compra Ki Dash ($10k + 3 Chaves)       |
| "UnlockKiDash"      | "EquipKiDash"     | Equipa o Ki Dash                       |
| "ArmamentHaki"      | "Learn"           | Aprende Haki V1 ($50,000 após quests)  |
| "ArmamentHaki"      | "UpgradeHakiV2"   | Aprimora para Haki V2                  |
| "ArmamentHaki"      | "UpgradeHakiV3"   | Aprimora para Haki V3 (Mestre Supremo) |
| "AnnyeCookieGM"     | "Buy"             | Compra Banana Split ($35 + Bananas)    |
| "Miss Water"        | "Buy"             | Compra Balde de Água ($50)             |
| "Noko"              | "SpawnProdigy"    | Invoca o chefe Cursed Prodigy          |
| "Seraphina"         | "SpawnDual"       | Invoca o chefe Dual Swordsman (Kirito) |
| "Jojo"              | "Buy"             | Compra Divergent Style ($35,000)       |
+---------------------+-------------------+-----------------------------------------+

================================================================================
4. TABELA COMPLETA DE MISSÕES (QUESTS)
================================================================================

Coordenadas, Níveis Mínimos, Alvos e Recompensas:

+-----+-----+-------------------------+--------------------+---------------------+------------+---------+
| ID  | Lvl | Nome da Missão          | Alvo (Mob/Objetivo)| Ilha / Posição (X,Y,Z) | Recomp. XP | Recomp$ |
+-----+-----+-------------------------+--------------------+---------------------+------------+---------+
| 001 | 0   | Defeat Bandits          | Bandit             | Foosha (441, 8, -991)| 250        | $100    |
| 002 | 10  | Bandit Leader           | Bandit Leader      | Foosha (310, 8, -1050)| 500       | $180    |
| 003 | 20  | Higaro's bandits        | Higaro’s bandit    | Foosha (14, 8, -1142)| 950        | $250    |
| 006 | 40  | Defeat Higaro (Boss)    | Higaro             | Foosha (236, 8, -1442)| 1,500     | $400    |
| 007 | 45  | Warrior Monkeys         | Warrior Monkey     | Jungle (-906, 9, 104)| 1,600      | $380    |
| 009 | 60  | Knight Monkeys          | Knight Monkey      | Jungle (-1224, 9, 33)| 2,100      | $450    |
| 010 | 70  | King Monkey (Boss)      | King Monkey        | Jungle (-1158, 9, -15)| 2,800     | $600    |
| 011 | 75  | Red Brawlers            | Red Brawler        | West (786, 3, 2683) | 2,400      | $450    |
| 013 | 90  | Defeat the Robots       | Robot [90+]        | West (379, 3, 3184) | 2,900      | $500    |
| Elm | 100 | Help the Scientists     | ElementsQuest      | West (661, 3, 2688) | 2,027*     | $500    |
| 014 | 105 | Robot King (Boss)       | Robot King         | West (379, 3, 3267) | 1,933      | $650    |
| 015 | 110 | Serve Food (Jaquin)     | ServirComida       | West (619, 4, 2913) | 1,646      | $550    |
| 016 | 115 | Super Robots            | Robot 15, Robot 16 | West (1310, 3, 3567)| 2,747      | $600    |
| 017 | 120 | Save West Island (Boss) | Crimson King       | West (241, 3, 3516) | 3,275      | $700    |
| 018 | 125 | Delivery for Jaquin     | EntregarJaquin     | West (619, 4, 2913) | 3,903      | $650    |
| 019 | 130 | Defeat The Frieza (Boss)| Frieza             | West (1103, 3, 2762)| 4,653      | $800    |
| 020 | 135 | Corrupted Players       | Corrupted Player   | Online (3698,31,2578)| 6,080     | $750    |
| 022 | 145 | Deliver the flowers     | FlowersQuest       | Online (3500,35,2600)| 6,569     | $800    |
| 021 | 150 | Pro Players             | Pro Player         | Online (3335,31,2777)| 10,299    | $950    |
| 023 | 160 | Mine the Ores           | CollectOre         | Online (3500,35,2600)| 11,127    | $1,000  |
| 024 | 165 | Jujutsu Students        | Jujutsu Student    | Sorcerers(4155,7,45) | 26,140     | $1,100  |
| 025 | 180 | Cursed Dolls (Task)     | BonecoDePalha      | Sorcerers(4239,9,116)| 36,938     | $1,150  |
| 026 | 190 | Special Students        | Special Student    | Sorcerers(4504,7,-14)| 45,000     | $1,200  |
| 027 | 205 | Overtime Sorcerer (Boss)| Overtime Sorcerer  | Sorcerers(4687,7,-80)| 142,250    | $1,800  |
| 029 | 225 | White Panda (Boss)      | White Panda        | Sorcerers(4603,7,206)| 239,353    | $2,500  |
+-----+-----+-------------------------+--------------------+---------------------+------------+---------+
* Nota: ElementsQuest sofre penalidade de 50% de EXP (cai para 1.013 XP) se o jogador tiver Nível > 100.

================================================================================
5. TABELA COMPLETA DE CHEFES (BOSSES: HP, DROPS & COORDENADAS)
================================================================================

+---------------------+--------+------------------------+-----------------------+
| Nome do Chefe       | HP     | Drops Importantes      | Spawn Coords (X,Y,Z)  |
+---------------------+--------+------------------------+-----------------------+
| Higaro              | 750    | Higaro Soul (FlashStep)| (235.6, 7.9, -1442.3)  |
| King Monkey         | 1,650  | Banana Sword (Espada)  | (-1158.0, 9.2, -14.8) |
| Brawler Chief       | 650    | Beli + Luvas           | (825.2, 6.2, 2788.4)  |
| Robot King          | 2,650  | Bronze Key, Core, Gear | (379.2, 3.2, 3266.6)  |
| Robot 15 / Robot 16 | 1,350  | Robotic Gear, Cores    | (1309.8, 2.8, 3566.8) |
| Crimson King        | 4,000  | Silver Key, Crimson Sw.| (188.5, 7.8, 3575.1)  |
| Frieza              | 5,000  | Gold Key (Ki Dash)     | (1231.0, 7.8, 2786.7) |
| Imperial Pro Player | 3,500  | Nevercore (Acessório)  | (3335.0, 30.6, 2777.0)|
| Emerald Swordsman   | 3,500  | Emerald Blade          | (3780.0, 35.0, 2578.0)|
| Old Fighter         | 20,000 | Magic Ball (100% Drop) | (2793.0, 18.0, -2675) |
| Cursed Prodigy      | 5,000  | Curse Fang (Espada)    | (4450.0, 15.0, 120.0) |
| Overtime Sorcerer   | 6,500  | Blunt Cleaver (+142kXP)| (4687.0, 6.9, -79.7)  |
| White Panda         | 7,000  | Panda Hat (+239k XP!)  | (4680.5, 10.6, 208.8) |
| Dual Swordsman      | 15,000 | Dual Essence (Kirito)  | (3500.0, 35.0, 2600.0)|
| Beast User          | 70,000 | Título Lendário        | (150.0, 10.0, -3200.0)|
+---------------------+--------+------------------------+-----------------------+

================================================================================
6. ARSENAL, ESPADAS, ACESSÓRIOS & RECEITAS DE CRAFT
================================================================================

--- ESPADAS DISPONÍVEIS NO JOGO ---
1. Katana: Loja básica ($1,000)
2. Cutlass: Loja básica ($1,500)
3. Iron Spear: Loja básica ($3,000)
4. Future Sword: Loja básica ($5,000)
5. Raven Axe: Loja básica ($8,000) - Skills: "Ravenous impact" (Mast. 20), "Crow cyclone" (Mast. 35)
6. Banana Sword: Drop do King Monkey na Jungle Island
7. Crimson Sword: Drop do Crimson King em West Island
8. Emerald Blade: Drop do Emerald Swordsman em Online Island
9. Blunt Cleaver: Drop do Overtime Sorcerer em Sorcerers Island
10. Curse Fang: Drop do Cursed Prodigy (invocado via Noko com Prodigy Orb)
11. Shadow Blade:
    - Onde: NPC Shadow Swordsman na Good House
    - Requisitos: 2x Magic Ball (Drop do Old Fighter) + $25,000 Beli
    - Remote: DialogueRemote:FireServer({"Shadow Swordsman", "Buy"})
12. Dual Sword (Espada do Kirito - Mais Rara do Jogo):
    - Onde: Master Blacksmith em Online Island
    - Requisitos: Shadow Blade + Emerald Blade + 5x Magic Ball + 1x Dual Essence + $25,000 Beli
    - Remote: DialogueRemote:FireServer({"Master Blacksmith", "Buy"})
13. Reaper Scythe / Black Blade: Gamepass / Eventos especiais

--- ACESSÓRIOS & BENEFÍCIOS ---
1. Nevercore: Drop raro do Imperial Pro Player (+Defesa / +Regen)
2. Scouter: Loja básica ($2,500) - Permite visualizar HP numérico dos inimigos
3. Basic Dark Cloak: Loja básica ($3,500)
4. Male Uniform / Female Uniform: Loja básica ($2,000)
5. Basic Armor: Loja básica ($1,500)
6. Monkey Cape / Monkey Crown: Jungle Island
7. Pirate Hat / Pirate Eyepatch: Foosha Island

================================================================================
7. ESTILOS DE LUTA (FIGHTING STYLES) & HAKI V1 / V2 / V3
================================================================================

1. Melee: Estilo padrão inicial.
2. Black Leg (Estilo do Sanji):
   - NPC: Sanjiro em Foosha Island
   - Custo: $15,000 Beli
   - Remote: DialogueRemote:FireServer({"Sanjiro", "Buy"})
3. Divergent Style (Itadori):
   - NPC: Jojo
   - Custo: $35,000 Beli
   - Remote: DialogueRemote:FireServer({"Jojo", "Buy"})
4. Robotic Style (Cyborg):
   - NPC: RobotTrainer em West Island
   - Custo: 45x Robotic Gear + 5x Robotic Core + $15,000 Beli
   - Remote: DialogueRemote:FireServer({"RobotTrainer", "Buy"})
5. Ki Dash (Teleporte DBZ):
   - Nível Mínimo: 200
   - Requisitos: Bronze Key (Robot King) + Silver Key (Crimson King) + Gold Key (Frieza) + $10,000 Beli
   - Remotes:
     DialogueRemote:FireServer({"UnlockKiDash", "BuyKiDash"})
     DialogueRemote:FireServer({"UnlockKiDash", "EquipKiDash"})
6. Flash Step (Shunpo):
   - NPC: Vovó Juju em Foosha Island
   - Requisitos: 15x Bandit Soul + 15x Higaro bandit Soul + 5x Higaro Soul + $5,500 Beli
   - Remote: DialogueRemote:FireServer({"Flash Step", "Buy"})

--- ARMAMENT HAKI (BUSOSHOKU) ---
- Local: Purple Men em Sorcerers Island (Nível 200+)
- Sequência de Quests:
  1. ArmamentHakiQuest1: Causar 100,000 de dano
  2. ArmamentHakiQuest2: Entregar 5x Banana Splits
     * Banana Split é comprado na NPC AnnyeCookieGM ($35 + 5 Bananas + 2 Águas da Miss Water $50)
  3. ArmamentHakiQuest3: Derrotar 25 Chefes
- Após as Quests:
  * Aprender Haki V1: DialogueRemote:FireServer({"ArmamentHaki", "Learn"}) ($50,000 Beli)
  * Aprimorar Haki V2: DialogueRemote:FireServer({"ArmamentHaki", "UpgradeHakiV2"})
  * Aprimorar Haki V3: DialogueRemote:FireServer({"ArmamentHaki", "UpgradeHakiV3"})

================================================================================
8. SISTEMA DE FRUTAS (GACHA, LOJA, STORAGE & RARIDADES)
================================================================================

1. Gacha de Frutas (Luzefe):
   - Local: NPC Luzefe em Foosha Island
   - Custo: $35,000 Beli
   - Cooldown: 1 hora
   - Detecção via Script: Quando o cooldown acaba, o servidor destrói o valor
     PlayerStats.Infos.LastFruitTimeSpin (ou seu valor fica <= 0).
   - Remote: DialogueRemote:FireServer({"SpinFruit", ""}) (Segundo argumento é string vazia!)

2. Frutas Físicas no Chão (Spawns Naturais):
   - Localização no Workspace: game.Workspace.World.Playability.DroppedTools
   - Coleta Automática: Teleportar o HumanoidRootPart até o Handle da fruta e disparar:
     pcall(firetouchinterest, hrp, handle, 0)
     pcall(firetouchinterest, hrp, handle, 1)

3. Guardar no Storage:
   - Disparo do Remote:
     LocalPlayer.Character.Humanoid:EquipTool(toolDaFruta)
     task.wait(0.25)
     PhysicalFruitsRemote:FireServer("Store")
     PhysicalFruitsRemote:FireServer("Storage", toolDaFruta.Name)

4. Loja de Frutas em Estoque (Fruit Shop):
   - Localização dos Dados: game.ReplicatedStorage.Shared["Fruit Stock"]
   - Frutas Míticas:
     * "Infinity" (Gojo Satoru): Custa $225,000 Beli
     * "Vessel" (Sukuna): Custa $265,000 Beli
   - Compra via Remote:
     game.ReplicatedStorage.Remotes["Fruit Shop Event"]:FireServer("Buy", "Infinity")

================================================================================
9. SISTEMA DE RAÇAS & GIROS (SPINS)
================================================================================

Pontos de Giro: PlayerStats.Stats.RaceRerollPoints.Value
Raça Atual:     PlayerStats.Build.ActualRace.Value

Tabela de Raças & Chances:
+-----------+------------+----------------------------------------------------+
| Raça      | Raridade   | Benefícios Principais                              |
+-----------+------------+----------------------------------------------------+
| Human     | Comum      | Equilibrado, sem buffs especiais                   |
| Rabbit    | Rara       | +Velocidade de movimento e pulo                    |
| Alien     | Rara       | +Regeneração e estamina                            |
| Angel     | Épica      | Voo planar, queda suave e cura rápida              |
| Fighter   | Lendária   | +Dano corpo a corpo e M1 rápido                    |
| Curse     | Lendária   | +Dano de trevas e habilidades amaldiçoadas         |
| Gamer     | Lendária   | +Ganho de EXP e Beli aumentado                     |
| Infernal  | MÍTICA (2%)| Chamas eternas, dano massivo em área (A MAIS RARA!)|
+-----------+------------+----------------------------------------------------+

Reroll via Remote:
game.ReplicatedStorage.Remotes["Race Event"]:FireServer("Spin Race")

================================================================================
10. ESTRUTURA DE DADOS DO JOGADOR (PLAYERSTATS)
================================================================================

Caminho: game.ReplicatedStorage.Shared.PlayerStats[LocalPlayer.Name]

Estrutura de Subpastas e Valores:
├── Infos
│   ├── Level (IntValue)             -> Nível do jogador (0 a 245 MAX)
│   ├── Money (IntValue)             -> Beli acumulado
│   ├── Health (IntValue)            -> Vida base
│   ├── Stamina (IntValue)           -> Estamina base
│   └── LastFruitTimeSpin (IntValue) -> Timestamp de cooldown do Luzefe
├── Stats
│   ├── Swords (IntValue)            -> Atributo de Espadas (Teto: 300)
│   ├── Defense (IntValue)           -> Atributo de Defesa (Teto: 300)
│   ├── FightStyles (IntValue)       -> Atributo de Estilo de Luta (Teto: 300)
│   ├── Stamina (IntValue)           -> Atributo de Estamina
│   ├── Fruits (IntValue)            -> Atributo de Frutas
│   ├── StatsPoints (IntValue)       -> Pontos livres para distribuir
│   ├── RaceRerollPoints (IntValue)  -> Giros de raça disponíveis
│   └── ResetStatsPoints (IntValue)  -> Pontos de reset de atributos
├── Build
│   ├── ActualRace (StringValue)     -> Raça equipada ("Infernal", etc.)
│   ├── ActualFruit (StringValue)    -> Fruta equipada ("Infinity", etc.)
│   ├── ActualSword (StringValue)    -> Espada equipada ("Raven Axe", etc.)
│   ├── ActualFightingStyle (StringValue) -> Estilo equipado ("Melee", etc.)
│   ├── Flash Step (BoolValue)       -> Se possui Flash Step (true/false)
│   ├── ArmamentHaki (BoolValue)     -> Se possui Haki desbloqueado
│   ├── HakiLevel (IntValue)         -> Nível do Haki (1, 2 ou 3)
│   └── UnlockedKiDash (BoolValue)   -> Se possui Ki Dash
├── Quest
│   ├── QuestId (StringValue)        -> ID da missão ativa ("014", "None", etc.)
│   └── Progress (IntValue)          -> Progresso numérico atual da missão
├── Masterys
│   └── [NomeDaArma] (IntValue)      -> Nível de maestria da arma (0 a 100)
└── Unlockeds
    ├── Swords (Folder)              -> Espadas que a conta possui
    └── FightingStyles (Folder)      -> Estilos de luta destravados

Inventário do Cliente:
local renv = getrenv and getrenv() or _G
local inv = (renv._G and renv._G.ClientInventory) or _G.ClientInventory
inv.Items.Swords        -> Lista de espadas
inv.Items.Acessories    -> Lista de acessórios
inv.Items.Fruits        -> Lista de frutas no Storage
inv.Items.Miscellaneous -> Materiais (Souls, Gears, Cores, Keys, Bananas, Logs)

================================================================================
11. ENGENHARIA ANTI-KICK, RATE LIMITS & AUTO-REJOIN
================================================================================

1. Regra de Ouro do Anti-Kick:
   - O servidor do Anime Piece monitora a taxa de chamadas por segundo.
   - Limite de Segurança Absoluto: NUNCA ultrapassar 4.2 pacotes por segundo.
   - Intervalo Mínimo Recomendado entre Remotes: 0.22 a 0.25 segundos.
   - Fila Matemática Lock-Free (Não trava a thread):
     local function safeFireRemote(remote, ...)
         local now = os.clock()
         local nextTime = math.max(now, (getgenv().NextPacket or 0) + 0.22)
         getgenv().NextPacket = nextTime
         if nextTime > now then task.wait(nextTime - now) end
         pcall(remote.FireServer, remote, ...)
     end

2. Sistema Hover Lock (Flutuação de Combate Imune a Dano):
   - Para atacar chefes sem sofrer dano, flutue exatamente 5.5 a 6.2 studs acima
     da cabeça (HumanoidRootPart) do mob no evento Heartbeat do RunService:
     RunService.Heartbeat:Connect(function()
         if currentTargetMob and currentTargetMob:FindFirstChild("HumanoidRootPart") then
             local mhrp = currentTargetMob.HumanoidRootPart
             hrp.CFrame = CFrame.lookAt(mhrp.Position + Vector3.new(0, 5.8, 0), mhrp.Position)
             hrp.AssemblyLinearVelocity = Vector3.zero
             hrp.AssemblyAngularVelocity = Vector3.zero
         end
     end)

3. Tripla Camada de Auto-Rejoin Autônomo:
   - Camada 1: GuiService.ErrorMessageChanged
   - Camada 2: CoreGui.RobloxPromptGui.promptOverlay.ChildAdded (ErrorPrompt)
   - Camada 3: RunService.Heartbeat verificando GuiService:GetErrorCode().Value > 0
   - Ao detectar kick, chama GuiService:ClearError() e TeleportService:Teleport().

4. Queue on Teleport (Reexecução Automática):
   - Permite que o executor do celular execute novamente o script após reconectar:
     local qot = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
     if qot then
         qot([[
             repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer
             loadstring(game:HttpGet("SEU_LINK_AQUI"))()
         ]])
     end

================================================================================
12. SNIPPETS ÚTEIS PRONTOS PARA COPIAR E EDITAR
================================================================================

--- SNIPPET 1: Farm Instantâneo da Quest dos Cientistas (Level 85 a 115) ---
task.spawn(function()
    local Remotes = game.ReplicatedStorage.Remotes
    local dial = Remotes["Dialogue Event"]
    local quest = Remotes["Quest Event"]
    while task.wait(0.1) do
        dial:FireServer({"Quest", "ElementsQuest"})
        task.wait(0.25)
        for _, el in ipairs({"Blue Element", "Red Element", "Pink Element", "Yellow Element"}) do
            dial:FireServer({"ElementsQuest", el})
            task.wait(0.22)
        end
    end
end)

--- SNIPPET 2: Farm Ultrarrápido de Cursed Dolls (Quest 025 - Level 180 a 245) ---
task.spawn(function()
    local Remotes = game.ReplicatedStorage.Remotes
    local dial = Remotes["Dialogue Event"]
    local cd = Remotes["Specials Remotes"]["Cursed Dolls Event"]
    local ps = game.ReplicatedStorage.Shared.PlayerStats[game.Players.LocalPlayer.Name]
    while task.wait(0.1) do
        if ps.Quest.QuestId.Value ~= "025" then
            dial:FireServer({"Quest", "025"})
            task.wait(0.4)
        end
        for i = 1, 5 do
            cd:FireServer("CollectCurseDoll")
            task.wait(1.15)
        end
    end
end)

--- SNIPPET 3: Auto-Distribuir Pontos em Swords -> Defense -> FightStyles ---
local function autoStats()
    local ps = game.ReplicatedStorage.Shared.PlayerStats[game.Players.LocalPlayer.Name]
    local statsRemote = game.ReplicatedStorage.Remotes["Stats Event"]
    local pts = ps.Stats.StatsPoints.Value
    if pts >= 3 then
        local cat = "FightStyles"
        if ps.Stats.Swords.Value < 300 then cat = "Swords"
        elseif ps.Stats.Defense.Value < 300 then cat = "Defense"
        end
        statsRemote:FireServer("UsePoints", cat, math.min(pts, 300 - ps.Stats[cat].Value))
    end
end

================================================================================
FIM DA DOCUMENTAÇÃO TÉCNICA - ANIME PIECE v0.5
================================================================================
