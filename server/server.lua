local ESX = nil

-- ─── ESX holen ───────────────────────────────────────────────────────────────
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- ─── Debug-Helper ────────────────────────────────────────────────────────────
local function dbg(msg, ...)
    if Config.Debug then
        print(('^3[AWskin SERVER]^7 ' .. tostring(msg)):format(...))
    end
end

-- Client-Debug-Meldungen in der Serverkonsole ausgeben
RegisterNetEvent('austriawien_skinmenu:debugLog')
AddEventHandler('austriawien_skinmenu:debugLog', function(msg)
    if Config.Debug then
        print(tostring(msg))
    end
end)

-- ─── Lizenz-Prüfung beim Ressourcenstart ─────────────────────────────────────
local VALID_LICENSE_KEY = 'AW-SKIN-2026-MIDCORE'
local licenseValid = false

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    local key = Config.LicenseKey or ''
    if key ~= VALID_LICENSE_KEY then
        print('^1')
        print('^1  ################################################################')
        print('^1  ##                                                            ##')
        print('^1  ##   !!!!!!!!!   A C H T U N G   !!!!!!!!!                   ##')
        print('^1  ##                                                            ##')
        print('^1  ##   DER LIZENZSCHLUESSEL STIMMT NICHT UEBEREIN!             ##')
        print('^1  ##                                                            ##')
        print('^1  ##   Eingetragen : "' .. tostring(key) .. '"')
        print('^1  ##   Erwartet    : gültiger AW-SKIN Schluessel               ##')
        print('^1  ##                                                            ##')
        print('^1  ##   Trage den korrekten Schluessel in config.lua ein:       ##')
        print('^1  ##     Config.LicenseKey = "DEIN-SCHLUESSEL"                 ##')
        print('^1  ##                                                            ##')
        print('^1  ##   Die Resource wird in 5 Sekunden gestoppt!               ##')
        print('^1  ##                                                            ##')
        print('^1  ################################################################')
        print('^1')
        licenseValid = false
    else
        licenseValid = true
        print('^2[AWskin] Lizenz OK. Resource gestartet.^7')
    end
end)

-- Wird auf Modul-Ebene gestartet – zuverlässiger als Thread in einem Event-Handler
Citizen.CreateThread(function()
    Citizen.Wait(500) -- warten bis onResourceStart ausgeführt wurde
    if not licenseValid then
        Citizen.Wait(5000)
        print('^1  ################################################################')
        print('^1  ##   STOPPE RESOURCE: ' .. GetCurrentResourceName())
        print('^1  ################################################################')
        print('^7')
        StopResource(GetCurrentResourceName())
        ExecuteCommand('stop ' .. GetCurrentResourceName())
    end
end)

-- ─── Admin-Prüfung ───────────────────────────────────────────────────────────
local function isAdmin(xPlayer)
    local group = xPlayer.getGroup()
    for _, g in ipairs(Config.AdminGroups) do
        if group == g then return true end
    end
    return false
end

-- ─── Datenbank-Tabelle anlegen ───────────────────────────────────────────────
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `austriawien_skins` (
            `identifier` VARCHAR(60)  NOT NULL,
            `skin`       LONGTEXT     NOT NULL,
            `updated_at` TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

-- ─── Skin laden ──────────────────────────────────────────────────────────────
RegisterNetEvent('austriawien_skinmenu:loadSkin')
AddEventHandler('austriawien_skinmenu:loadSkin', function()
    local src     = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        dbg('loadSkin: kein Spieler für src=%d', src)
        return
    end

    local identifier = xPlayer.identifier
    dbg('loadSkin | src=%d | identifier=%s', src, identifier)

    MySQL.query(
        'SELECT skin FROM ?? WHERE identifier = ?',
        { Config.DatabaseTable, identifier },
        function(result)
            if result and result[1] then
                dbg('Skin gefunden für %s (%d Bytes)', identifier, #result[1].skin)
                -- firstLogin = false: Skin vorhanden
                TriggerClientEvent('austriawien_skinmenu:applySkin', src, result[1].skin, false)
            else
                dbg('KEIN Skin in DB für %s → First-Time-Setup', identifier)
                -- firstLogin = true: kein Eintrag → Menü beim Client öffnen
                TriggerClientEvent('austriawien_skinmenu:applySkin', src, '', true)
            end
        end
    )
end)

-- ─── Skin speichern ──────────────────────────────────────────────────────────
-- targetIdentifier = nil  → eigenen Skin speichern
-- targetIdentifier = str  → Admin speichert Skin für anderen Spieler (nur intern)
RegisterNetEvent('austriawien_skinmenu:saveSkin')
AddEventHandler('austriawien_skinmenu:saveSkin', function(skinData, targetIdentifier)
    local src     = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    -- Skin-Daten müssen ein Table sein
    if type(skinData) ~= 'table' then return end

    -- Ziel-Identifier bestimmen
    local identifier
    if targetIdentifier and type(targetIdentifier) == 'string' and targetIdentifier ~= '' then
        -- Admin speichert für anderen → Berechtigungsprüfung
        if not isAdmin(xPlayer) then
            TriggerClientEvent('chat:addMessage', src, {
                color = { 231, 76, 60 }, multiline = false,
                args  = { '[Garderobe]', 'Keine Berechtigung.' }
            })
            return
        end
        identifier = targetIdentifier
    else
        identifier = xPlayer.identifier
    end

    local skinJson = json.encode(skinData)
    dbg('saveSkin | identifier=%s | json-länge=%d', identifier, #skinJson)

    MySQL.update(
        'INSERT INTO ?? (identifier, skin) VALUES (?, ?) ON DUPLICATE KEY UPDATE skin = ?, updated_at = NOW()',
        { Config.DatabaseTable, identifier, skinJson, skinJson },
        function(affectedRows)
            dbg('saveSkin: affectedRows=%d', affectedRows or 0)
            if affectedRows and affectedRows > 0 then
                TriggerClientEvent('chat:addMessage', src, {
                    color  = { 52, 211, 153 },
                    multiline = false,
                    args   = { '[Garderobe]', 'Skin gespeichert.' }
                })
            end
        end
    )
end)

-- ─── Admin öffnet Menü für anderen Spieler ───────────────────────────────────
RegisterNetEvent('austriawien_skinmenu:adminOpenForTarget')
AddEventHandler('austriawien_skinmenu:adminOpenForTarget', function(targetServerId)
    local src     = source
    local xAdmin  = ESX.GetPlayerFromId(src)
    if not xAdmin then return end
    dbg('adminOpenForTarget | admin=%d | ziel=%d', src, targetServerId)

    if not isAdmin(xAdmin) then
        TriggerClientEvent('chat:addMessage', src, {
            color = { 231, 76, 60 }, multiline = false,
            args  = { '[Garderobe]', 'Keine Berechtigung.' }
        })
        return
    end

    local xTarget = ESX.GetPlayerFromId(targetServerId)
    if not xTarget then
        TriggerClientEvent('chat:addMessage', src, {
            color = { 231, 76, 60 }, multiline = false,
            args  = { '[Garderobe]', 'Spieler nicht gefunden.' }
        })
        return
    end

    TriggerClientEvent('austriawien_skinmenu:openForTarget', targetServerId)
    TriggerClientEvent('chat:addMessage', src, {
        color = { 52, 211, 153 }, multiline = false,
        args  = { '[Garderobe]', ('Skin-Menü für Spieler %d geöffnet.'):format(targetServerId) }
    })
end)

-- ─── Skin per Export abrufbar machen (für andere Ressourcen) ─────────────────
exports('getSkin', function(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return nil end

    local result = MySQL.query.await(
        'SELECT skin FROM ?? WHERE identifier = ?',
        { Config.DatabaseTable, xPlayer.identifier }
    )

    if result and result[1] then
        return json.decode(result[1].skin)
    end
    return nil
end)
