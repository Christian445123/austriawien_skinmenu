local ESX = nil

-- ─── ESX holen ───────────────────────────────────────────────────────────────
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- ─── Debug-Helper ────────────────────────────────────────────────────────────
local function dbg(msg, ...)
    if Config.Debug then
        print(('^3[AWskin SERVER]^7 ' .. tostring(msg)):format(...))
    end
end

-- ─── Lizenz-Prüfung beim Ressourcenstart ─────────────────────────────────────
-- Gültiger Schlüssel (hier vom Script-Autor festgelegt)
local VALID_LICENSE_KEY = 'AW-SKIN-2026-MIDCORE'

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    if not Config.CheckLicense then
        print('^2[AWskin] Resource gestartet. ^3(Lizenz-Pruefung deaktiviert)^7')
        return
    end

    local key = Config.LicenseKey or ''
    if key ~= VALID_LICENSE_KEY then
        print('^1')
        print('^1  ╔══════════════════════════════════════════════════════════╗')
        print('^1  ║        AUSTRIAWIEN SKINMENU  –  UNGUELTIGE LIZENZ       ║')
        print('^1  ╠══════════════════════════════════════════════════════════╣')
        print('^1  ║  Der eingetragene Schluessel ist nicht gueltig.         ║')
        print('^1  ║                                                         ║')
        print('^1  ║  Trage den korrekten Schluessel in config.lua ein:      ║')
        print('^1  ║    Config.LicenseKey = "AW-SKIN-2026-MIDCORE"           ║')
        print('^1  ║                                                         ║')
        print('^1  ║  Pruefung deaktivieren (fuer Entwicklung):              ║')
        print('^1  ║    Config.CheckLicense = false                          ║')
        print('^1  ╚══════════════════════════════════════════════════════════╝')
        print('^1  Die Resource wird in 5 Sekunden gestoppt...^7')
        Wait(5000)
        StopResource(GetCurrentResourceName())
        return
    end

    print('^2[AWskin] Lizenz OK. Resource gestartet.^7')
end)


            Wait(5000)
            StopResource(GetCurrentResourceName())
        end
    end, 'GET', '', { ['Content-Type'] = 'application/json' })
end)

-- ─── EUP-Bild-Scanner ────────────────────────────────────────────────────────
local eupManifest = {}

local function scanEUPResource(resName)
    local resPath = GetResourcePath(resName)
    if not resPath or resPath == '' then
        dbg('EUP scan: Resource "%s" nicht gefunden', resName)
        return {}
    end

    local found  = {}
    local imgDir = resPath .. '/img'

    -- Prüfen ob Ordner existiert
    local probe = io.open(imgDir .. '/.', 'r')
    if not probe then
        dbg('EUP scan: "%s/img" nicht gefunden, übersprungen', resName)
        return {}
    end
    io.close(probe)

    -- Windows: dir /b /s listet alle Dateien rekursiv
    local cmd    = ('dir /b /s "%s" /a:-d 2>nul'):format(imgDir)
    local handle = io.popen(cmd)
    if not handle then return {} end

    for line in handle:lines() do
        -- Beispiel-Zeile: C:\server\resources\eup-stream\img\jacket\0.png
        local slot, file = line:match('\\([^\\]+)\\([^\\]+%.%a+)$')
        if slot and file then
            local ext = file:match('%.(%a+)$')
            local id  = tonumber(file:match('^(%d+)'))
            if id and ext and (ext == 'png' or ext == 'jpg' or ext == 'webp') then
                if not found[slot] then found[slot] = {} end
                found[slot][#found[slot] + 1] = id
            end
        end
    end
    handle:close()
    dbg('EUP scan "%s": %d Slots mit Bildern', resName, #found)
    return found
end

CreateThread(function()
    Wait(2000)  -- Warten bis alle Resources gestartet sind
    eupManifest = {}
    for _, resName in ipairs(Config.EUPResources or {}) do
        eupManifest[resName] = scanEUPResource(resName)
    end
    dbg('EUP Manifest fertig (%d Ressourcen gescannt)', #(Config.EUPResources or {}))
end)

-- ─── EUP Manifest an Client senden ───────────────────────────────────────────
RegisterNetEvent('austriawien_skinmenu:getEUPManifest')
AddEventHandler('austriawien_skinmenu:getEUPManifest', function()
    TriggerClientEvent('austriawien_skinmenu:eupManifest', source, eupManifest)
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
