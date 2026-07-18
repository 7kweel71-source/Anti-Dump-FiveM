FrameworkBridge = {}

local selectedFramework = "standalone"
local QBCore = nil

local function resourceList(key, fallback)
    local configured = Config.ResourceNames and Config.ResourceNames[key]

    if type(configured) == "table" and #configured > 0 then
        return configured
    end

    return fallback
end

local RESOURCES = {
    qbcore = resourceList("QBCore", { "qb-core" }),
    qbox = resourceList("QBox", { "qbx_core" }),
    creative = resourceList("Creative", { "vrp", "vRP", "creative", "Creative" }),
    vrp = resourceList("VRP", { "vrp", "vRP" })
}

local function isStarted(resourceName)
    local state = GetResourceState(resourceName)
    return state == "started" or state == "starting"
end

local function firstStarted(resources)
    for _, resourceName in ipairs(resources) do
        if isStarted(resourceName) then
            return resourceName
        end
    end

    return nil
end

local function debugPrint(message)
    if Config.Debug then
        print(("^3[ANT-DUMPER]^7 %s"):format(message))
    end
end

local function normalizeFramework(value)
    value = tostring(value or "auto"):lower()

    local aliases = {
        ["qb-core"] = "qbcore",
        ["qbx"] = "qbox",
        ["qbx_core"] = "qbox",
        ["v-rp"] = "vrp"
    }

    return aliases[value] or value
end

local function detectFramework()
    local configured = normalizeFramework(Config.Framework)

    if configured ~= "auto" then
        return configured
    end

    if firstStarted(RESOURCES.qbox) then
        return "qbox"
    end

    if firstStarted(RESOURCES.qbcore) then
        return "qbcore"
    end

    if firstStarted(RESOURCES.vrp) then
        return "vrp"
    end

    return "standalone"
end

local function callExport(resourceNames, methodNames, ...)
    local arguments = { ... }

    for _, resourceName in ipairs(resourceNames) do
        if isStarted(resourceName) then
            for _, methodName in ipairs(methodNames) do
                local ok, result = pcall(function()
                    local resourceExports = exports[resourceName]
                    local method = resourceExports[methodName]
                    return method(resourceExports, table.unpack(arguments))
                end)

                if ok and result ~= nil then
                    return result
                end
            end
        end
    end

    return nil
end

local function initialize()
    selectedFramework = detectFramework()
    QBCore = nil

    if selectedFramework == "qbcore" then
        local resourceName = firstStarted(RESOURCES.qbcore)

        if resourceName then
            local ok, result = pcall(function()
                return exports[resourceName]:GetCoreObject()
            end)

            if ok then
                QBCore = result
            else
                debugPrint("Não foi possível obter o objeto do QBCore; usando identificadores nativos.")
            end
        end
    end

    print(("^2[ANT-DUMPER]^7 Framework selecionado: ^5%s^7"):format(selectedFramework))
end

local function getIdentifier(source, identifierType)
    local prefix = identifierType .. ":"

    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        if identifier:sub(1, #prefix) == prefix then
            return identifier
        end
    end

    return nil
end

local function getQBoxPlayer(source)
    local resourceName = firstStarted(RESOURCES.qbox)

    if not resourceName then
        return nil
    end

    local ok, player = pcall(function()
        return exports[resourceName]:GetPlayer(source)
    end)

    return ok and player or nil
end

function FrameworkBridge.GetName()
    return selectedFramework
end

function FrameworkBridge.GetCharacterId(source)
    if selectedFramework == "qbox" then
        local player = getQBoxPlayer(source)

        if player and player.PlayerData then
            return player.PlayerData.citizenid or player.PlayerData.cid or player.PlayerData.source
        end
    elseif selectedFramework == "qbcore" and QBCore then
        local player = QBCore.Functions.GetPlayer(source)

        if player and player.PlayerData then
            return player.PlayerData.citizenid or player.PlayerData.cid or player.PlayerData.source
        end
    elseif selectedFramework == "creative" then
        local passport = callExport(
            RESOURCES.creative,
            { "Passport", "passport", "GetUserId", "getUserId", "UserId" },
            source
        )

        if passport then
            return passport
        end
    elseif selectedFramework == "vrp" then
        local userId = callExport(
            RESOURCES.vrp,
            { "getUserId", "GetUserId", "Passport", "passport", "UserId" },
            source
        )

        if userId then
            return userId
        end
    end

    local license = getIdentifier(source, "license")
    return license and license:gsub("license:", "") or source
end

function FrameworkBridge.GetPlayerName(source)
    local player = nil

    if selectedFramework == "qbox" then
        player = getQBoxPlayer(source)
    elseif selectedFramework == "qbcore" and QBCore then
        player = QBCore.Functions.GetPlayer(source)
    end

    if player and player.PlayerData and player.PlayerData.charinfo then
        local charinfo = player.PlayerData.charinfo
        local fullName = ((charinfo.firstname or "") .. " " .. (charinfo.lastname or "")):gsub("^%s*(.-)%s*$", "%1")

        if fullName ~= "" then
            return fullName
        end
    end

    return GetPlayerName(source) or ("Jogador %s"):format(source)
end

function FrameworkBridge.GetPrimaryIdentifier(source)
    return getIdentifier(source, "license")
        or getIdentifier(source, "license2")
        or getIdentifier(source, "fivem")
        or getIdentifier(source, "discord")
        or ("source:%s"):format(source)
end

function FrameworkBridge.GetIdentifiers(source)
    local identifiers = {}

    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        identifiers[#identifiers + 1] = identifier
    end

    return identifiers
end

function FrameworkBridge.TryNativeBan(source, characterId)
    if not Config.Ban.TryNativeFrameworkBan then
        return false
    end

    if selectedFramework == "creative" then
        callExport(
            RESOURCES.creative,
            { "SetBanned", "setBanned", "Ban", "ban" },
            characterId,
            true
        )

        return true
    end

    if selectedFramework == "vrp" then
        callExport(
            RESOURCES.vrp,
            { "setBanned", "SetBanned", "ban", "Ban" },
            characterId,
            true
        )

        return true
    end

    return false
end

function FrameworkBridge.Kick(source, reason)
    DropPlayer(source, reason)
end

initialize()

AddEventHandler("onResourceStart", function(resourceName)
    for _, resources in pairs(RESOURCES) do
        for _, configuredName in ipairs(resources) do
            if resourceName == configuredName then
                SetTimeout(250, initialize)
                return
            end
        end
    end
end)
