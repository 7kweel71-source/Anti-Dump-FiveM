local sessionToken = nil
local detectionEnabled = false

local function requestConfiguration()
    TriggerServerEvent("antidumper:server:requestConfiguration")
end

RegisterNetEvent("antidumper:client:configure", function(enabled, token)
    detectionEnabled = enabled == true
    sessionToken = token

    SendNUIMessage({
        action = "configure",
        enabled = detectionEnabled
    })
end)

RegisterNUICallback("loadNuis", function(_, cb)
    cb({ ok = true })

    if not detectionEnabled or not sessionToken then
        return
    end

    TriggerServerEvent("antidumper:server:detected", sessionToken)
end)

AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    CreateThread(function()
        Wait(750)
        requestConfiguration()
    end)
end)

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", requestConfiguration)
RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
    detectionEnabled = false
    sessionToken = nil
    SendNUIMessage({ action = "configure", enabled = false })
end)

RegisterNetEvent("qbx_core:client:playerLoggedOut", function()
    detectionEnabled = false
    sessionToken = nil
    SendNUIMessage({ action = "configure", enabled = false })
end)
