Config = {}

-- Frameworks disponíveis: "auto", "standalone", "qbcore", "qbox", "creative" e "vrp".
-- Em "auto", a ordem de detecção é: QBox > QBCore > vRP > Standalone.
-- Como Creative e vRP podem usar o mesmo nome de resource, selecione "creative"
-- manualmente caso queira que o nome apareça dessa forma nos logs.
Config.Framework = "auto"

Config.Debug = false

-- Ajuste somente se os resources do seu framework tiverem nomes personalizados.
Config.ResourceNames = {
    QBCore = { "qb-core" },
    QBox = { "qbx_core" },
    Creative = { "vrp", "vRP", "creative", "Creative" },
    VRP = { "vrp", "vRP" }
}

-- Jogadores com esta ACE não serão monitorados/punidos.
-- Para liberar um administrador: add_ace identifier.license:SUA_LICENSE antidumper.bypass allow
-- Use uma string vazia para desativar o bypass por ACE.
Config.BypassAce = "antidumper.bypass"

Config.Detection = {
    Enabled = true,

    -- Intervalo mínimo entre detecções aceitas para o mesmo jogador.
    CooldownSeconds = 10
}

Config.Punishment = {
    Ban = true,
    Kick = true,
    KickMessage = "Acesso não autorizado às ferramentas de inspeção detectado.",
    BanReason = "Tentativa de acessar/inspecionar a NUI do servidor."
}

Config.Ban = {
    -- O sistema interno funciona em qualquer framework e grava por identificador license.
    StorageFile = "bans.json",
    CheckOnConnect = true,

    -- Quando true, tenta também chamar uma função de ban nativa do vRP/Creative.
    -- O ban interno continua sendo salvo para manter compatibilidade entre frameworks.
    TryNativeFrameworkBan = false
}

Config.Webhook = {
    Url = "",
    Username = "ANT-DUMPER",
    AvatarUrl = "",
    Color = 16754176
}
