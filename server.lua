local resourceName = GetCurrentResourceName()
local banFile = Config.Ban.StorageFile or "bans.json"
local bans = {}
local banIndex = {}
local sessionTokens = {}
local lastDetection = {}

math.randomseed(os.time())

local function debugPrint(message)
    if Config.Debug then
        print(("^3[ANT-DUMPER]^7 %s"):format(message))
    end
end

local function rebuildBanIndex()
    banIndex = {}

    for primaryIdentifier, ban in pairs(bans) do
        banIndex[primaryIdentifier] = primaryIdentifier

        if type(ban.identifiers) == "table" then
            for _, identifier in ipairs(ban.identifiers) do
                banIndex[identifier] = primaryIdentifier
            end
        end
    end
end

local function loadBans()
    local content = LoadResourceFile(resourceName, banFile)

    if not content or content == "" then
        bans = {}
        rebuildBanIndex()
        return
    end

    local ok, decoded = pcall(json.decode, content)

    if ok and type(decoded) == "table" then
        bans = decoded
        rebuildBanIndex()
        return
    end

    bans = {}
    rebuildBanIndex()
    print(("^1[ANT-DUMPER]^7 O arquivo %s está inválido e foi ignorado."):format(banFile))
end

local function saveBans()
    SaveResourceFile(resourceName, banFile, json.encode(bans), -1)
    rebuildBanIndex()
end

local function createToken(source)
    return ("%s:%s:%s:%s"):format(
        source,
        os.time(),
        math.random(100000, 999999),
        GetGameTimer()
    )
end

local function hasBypass(source)
    local ace = Config.BypassAce
    return type(ace) == "string" and ace ~= "" and IsPlayerAceAllowed(source, ace)
end

local function findBanByIdentifier(identifier)
    local primaryIdentifier = identifier and banIndex[identifier]

    if not primaryIdentifier then
        return nil, nil
    end

    return bans[primaryIdentifier], primaryIdentifier
end

local function findSourceBan(source)
    for _, identifier in ipairs(FrameworkBridge.GetIdentifiers(source)) do
        local ban, primaryIdentifier = findBanByIdentifier(identifier)

        if ban then
            return ban, primaryIdentifier
        end
    end

    return findBanByIdentifier(FrameworkBridge.GetPrimaryIdentifier(source))
end

local function sendWebhook(data)
    local webhook = Config.Webhook or {}
    local url = tostring(webhook.Url or "")

    if url == "" then
        return
    end

    local fields = {
        { name = "Jogador", value = ("%s (`%s`)"):format(data.playerName, data.source), inline = true },
        { name = "ID do personagem", value = tostring(data.characterId), inline = true },
        { name = "Framework", value = tostring(data.framework), inline = true },
        { name = "Identificador principal", value = ("`%s`"):format(data.primaryIdentifier), inline = false },
        { name = "Motivo", value = tostring(data.reason), inline = false }
    }

    local payload = {
        username = webhook.Username or "ANT-DUMPER",
        avatar_url = webhook.AvatarUrl or "",
        embeds = {
            {
                title = "Ferramentas de inspeção detectadas",
                color = webhook.Color or 16754176,
                fields = fields,
                footer = { text = os.date("%d/%m/%Y às %H:%M:%S") }
            }
        }
    }

    PerformHttpRequest(url, function(statusCode)
        if Config.Debug then
            debugPrint(("Webhook respondeu com status %s."):format(statusCode))
        end
    end, "POST", json.encode(payload), { ["Content-Type"] = "application/json" })
end

local function addBan(source, reason)
    local identifier = FrameworkBridge.GetPrimaryIdentifier(source)
    local characterId = FrameworkBridge.GetCharacterId(source)

    bans[identifier] = {
        name = FrameworkBridge.GetPlayerName(source),
        characterId = characterId,
        framework = FrameworkBridge.GetName(),
        reason = reason,
        bannedAt = os.time(),
        identifiers = FrameworkBridge.GetIdentifiers(source)
    }

    saveBans()
    FrameworkBridge.TryNativeBan(source, characterId)

    return identifier, characterId
end

RegisterNetEvent("antidumper:server:requestConfiguration", function()
    local source = source
    local enabled = Config.Detection.Enabled == true and not hasBypass(source)
    local token = createToken(source)

    sessionTokens[source] = token
    TriggerClientEvent("antidumper:client:configure", source, enabled, token)
end)

RegisterNetEvent("antidumper:server:detected", function(token)
    local source = source

    if Config.Detection.Enabled ~= true or hasBypass(source) then
        return
    end

    if type(token) ~= "string" or sessionTokens[source] ~= token then
        debugPrint(("Token inválido recebido do source %s."):format(source))
        return
    end

    local currentTime = os.time()
    local cooldown = tonumber(Config.Detection.CooldownSeconds) or 10

    if lastDetection[source] and currentTime - lastDetection[source] < cooldown then
        return
    end

    lastDetection[source] = currentTime

    local playerName = FrameworkBridge.GetPlayerName(source)
    local characterId = FrameworkBridge.GetCharacterId(source)
    local primaryIdentifier = FrameworkBridge.GetPrimaryIdentifier(source)
    local reason = Config.Punishment.BanReason

    if Config.Punishment.Ban then
        primaryIdentifier, characterId = addBan(source, reason)
    end

    print((
        "^1[ANT-DUMPER]^7 Detecção: %s | source: %s | ID: %s | framework: %s | identifier: %s"
    ):format(playerName, source, characterId, FrameworkBridge.GetName(), primaryIdentifier))

    sendWebhook({
        playerName = playerName,
        source = source,
        characterId = characterId,
        framework = FrameworkBridge.GetName(),
        primaryIdentifier = primaryIdentifier,
        reason = reason
    })

    if Config.Punishment.Kick then
        FrameworkBridge.Kick(source, Config.Punishment.KickMessage)
    end
end)

AddEventHandler("playerConnecting", function(_, _, deferrals)
    if not Config.Ban.CheckOnConnect then
        return
    end

    local source = source
    deferrals.defer()
    Wait(0)

    local ban = findSourceBan(source)

    if ban then
        local reason = ban.reason or Config.Punishment.BanReason
        deferrals.done(("Você está banido deste servidor.\nMotivo: %s"):format(reason))
        return
    end

    deferrals.done()
end)

AddEventHandler("playerDropped", function()
    local source = source
    sessionTokens[source] = nil
    lastDetection[source] = nil
end)

RegisterCommand("antidumper_unban", function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(source, "antidumper.admin") then
        return
    end

    local identifier = args[1]
    local _, primaryIdentifier = findBanByIdentifier(identifier)

    if not identifier or not primaryIdentifier then
        print("^1[ANT-DUMPER]^7 Uso: antidumper_unban license:IDENTIFICADOR")
        return
    end

    bans[primaryIdentifier] = nil
    saveBans()
    print(("^2[ANT-DUMPER]^7 Ban removido: %s"):format(primaryIdentifier))
end, false)

exports("IsIdentifierBanned", function(identifier)
    local ban = findBanByIdentifier(identifier)
    return ban ~= nil, ban
end)

exports("UnbanIdentifier", function(identifier)
    local _, primaryIdentifier = findBanByIdentifier(identifier)

    if not primaryIdentifier then
        return false
    end

    bans[primaryIdentifier] = nil
    saveBans()
    return true
end)

exports("GetBans", function()
    return bans
end)

loadBans()
