local ESX = nil
local RESOURCE_VERSION = '1.0.3'

-- ─── ESX holen ───────────────────────────────────────────────────────────────
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- ─── Startbanner ─────────────────────────────────────────────────────────────
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    local R = '^7'
    local T = '^1'
    local D = '^8'
    local G = '^2'
    local W = '^7'   -- Weiß
    print(R)
    print(T .. "        d8888                   888            d8b        888       888 d8b" .. R)
    print(T .. "       d88888                   888            Y8P        888   o   888 Y8P" .. R)
    print(T .. "      d88P888                   888                       888  d8b  888    " .. R)
    print(W .. "     d88P 888 888  888 .d8888b  888888 888d888 888  8888b 888 d888b 888 888  .d88b.  88888b." .. R)
    print(W .. "    d88P  888 888  888 88K      888    888P    888     88b 888d8P888888 888 d8P  Y8b 888  88b" .. R)
    print(W .. "   d88P   888 888  888  Y8888b. 888    888     888 .d888888 8888P Y88888 888 88888888 888  888" .. R)
    print(T .. "  d8888888888 Y88b 888      X88 Y88b.  888     888 888  888 888P   Y8888 888 Y8b.     888  888" .. R)
    print(T .. " d88P     888   Y88888  88888P   Y888  888     888  Y888888 888P    Y888 888   Y8888  888  888" .. R)
    print(R)
    print(D .. " ##########################################################################" .. R)
    print(D .. " ##                                                                      ##" .. R)
    print(D .. " ##  ^7Skin Menu        " .. T .. "AustriaWien" .. D .. "       by GamingDevelopment    ##" .. R)
    print(D .. " ##  ^7Version  " .. G .. RESOURCE_VERSION .. D .. "                                              ##" .. R)
    print(D .. " ##                                                                      ##" .. R)
    print(D .. " ##########################################################################" .. R)
    print(R)
end)

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
-- ─── Berechtigungs-Callback für /awskin (eigenes Menü) ──────────────────────
ESX.RegisterServerCallback('austriawien_skinmenu:canOpenMenu', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(false) return end

    -- Admins dürfen immer
    if isAdmin(xPlayer) then cb(true) return end

    -- Erstes Mal (kein Skin in DB) → ebenfalls erlaubt
    MySQL.query(
        'SELECT 1 FROM ?? WHERE identifier = ? LIMIT 1',
        { Config.DatabaseTable, xPlayer.identifier },
        function(rows)
            cb(not rows or #rows == 0)
        end
    )
end)
-- ─── Admin öffnet Menü für anderen Spieler ───────────────────────────────────

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

-- ─── esx_skin kompatibler Server-Layer ───────────────────────────────────────
-- Damit alle Ressourcen die ESX.TriggerServerCallback('esx_skin:getPlayerSkin')
-- oder TriggerServerEvent('esx_skin:save') nutzen, nahtlos funktionieren.

ESX.RegisterServerCallback('esx_skin:getPlayerSkin', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(nil, nil) return end

    local identifier = xPlayer.identifier
    MySQL.query(
        'SELECT skin FROM ?? WHERE identifier = ?',
        { Config.DatabaseTable, identifier },
        function(result)
            local skin = nil
            if result and result[1] and result[1].skin then
                skin = json.decode(result[1].skin)
            end
            dbg('esx_skin:getPlayerSkin | %s | skin=%s', identifier, skin and 'ja' or 'nil')
            cb(skin, nil)
        end
    )
end)

-- esx_skin:save: andere Ressourcen speichern Skin über diesen Event.
-- Wir leiten in unser eigenes Save-System weiter.
RegisterNetEvent('esx_skin:save')
AddEventHandler('esx_skin:save', function(skin)
    local src     = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or type(skin) ~= 'table' then return end

    local identifier = xPlayer.identifier
    local skinJson   = json.encode(skin)
    dbg('esx_skin:save abgefangen | %s | %d Bytes', identifier, #skinJson)

    MySQL.update(
        'INSERT INTO ?? (identifier, skin) VALUES (?, ?) ON DUPLICATE KEY UPDATE skin = ?, updated_at = NOW()',
        { Config.DatabaseTable, identifier, skinJson, skinJson }
    )
end)
