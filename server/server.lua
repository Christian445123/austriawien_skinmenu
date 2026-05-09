local ESX = nil
local RESOURCE_VERSION = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or 'unknown'

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

-- ─── Format-Konvertierung: AWskin Nested → ESX/Skinchanger Flat ──────────────
-- Wird beim Schreiben in users.skin genutzt, damit zr-multicharacter und
-- skinchanger das gewohnte Flat-Format erhalten.
local function awSkinToEsx(s)
    if not s or type(s) ~= 'table' then return nil end
    -- Bereits Flat-Format? (hat 'sex' oder 'torso_1' auf Root-Ebene)
    if s.sex ~= nil or s.torso_1 ~= nil then return s end

    local c    = s.components or {}
    local p    = s.props      or {}
    local f    = s.face       or {}
    local feat = f.features   or {}
    local ovs  = {}
    for _, ov in ipairs(f.overlays or {}) do ovs[ov.id] = ov end

    local function ovFld(id, key, def) return (ovs[id] and ovs[id][key]) or def end
    local function featV(i) return feat[i] and math.floor(feat[i] * 10) or 0 end
    local function compD(n) return (c[n] and c[n].drawable) or 0 end
    local function compT(n) return (c[n] and c[n].texture)  or 0 end
    local function propD(n) return (p[n] and p[n].drawable) or -1 end
    local function propT(n) return (p[n] and p[n].texture)  or 0 end

    return {
        sex               = (s.model == 'mp_f_freemode_01') and 1 or 0,
        -- HeadBlend
        mom               = f.shapeFirst  or 0,
        dad               = f.shapeSecond or 0,
        grandparents      = 0,
        face_md_weight    = math.floor((f.shapeMix or 0.5) * 100),
        face_g_weight     = 0,
        skin_md_weight    = math.floor((f.skinMix  or 0.5) * 100),
        skin_g_weight     = 0,
        -- Gesichtszüge (Feature-Index → Skinchanger-Schlüssel)
        nose_1            = featV(1),   nose_2      = featV(2),   nose_3     = featV(3),
        nose_4            = featV(4),   nose_5      = featV(5),   nose_6     = featV(6),
        cheeks_1          = featV(7),   cheeks_2    = featV(8),   cheeks_3   = featV(9),
        lip_thickness     = featV(11),
        jaw_1             = featV(13),  jaw_2       = featV(14),
        chin_1            = featV(15),  chin_2      = featV(16),  chin_3     = featV(17),
        -- Haare & Augen
        hair              = compD('hair'),
        hair_color_1      = f.hairColor1 or 0,
        hair_color_2      = f.hairColor2 or 0,
        eye_color         = f.eyeColor   or 0,
        -- Alle Overlays (0-12)
        blemishes              = ovFld(0,'index',0),  blemishes_1_opacity          = ovFld(0,'opacity',0),
        beard                  = ovFld(1,'index',0),  beard_1_opacity              = ovFld(1,'opacity',0),  beard_1     = ovFld(1,'color1',0), beard_2    = ovFld(1,'color2',0),
        eyebrow                = ovFld(2,'index',0),  eyebrow_1_opacity            = ovFld(2,'opacity',1),  eyebrow_1   = ovFld(2,'color1',f.eyebrowColor or 0), eyebrow_2 = ovFld(2,'color2',0),
        aging                  = ovFld(3,'index',0),  aging_1_opacity              = ovFld(3,'opacity',0),
        makeup                 = ovFld(4,'index',0),  makeup_1_opacity             = ovFld(4,'opacity',0),  makeup_1    = ovFld(4,'color1',0),
        blush                  = ovFld(5,'index',0),  blush_1_opacity              = ovFld(5,'opacity',0),  blush_1     = ovFld(5,'color1',0),
        complexion             = ovFld(6,'index',0),  complexion_1_opacity         = ovFld(6,'opacity',0),
        sun_damage             = ovFld(7,'index',0),  sun_damage_1_opacity         = ovFld(7,'opacity',0),
        lipstick               = ovFld(8,'index',0),  lipstick_1_opacity           = ovFld(8,'opacity',0),  lipstick_1  = ovFld(8,'color1',0),
        freckles               = ovFld(9,'index',0),  freckles_1_opacity           = ovFld(9,'opacity',0),
        chest_hair             = ovFld(10,'index',0), chest_hair_1_opacity         = ovFld(10,'opacity',0), chest_hair_1 = ovFld(10,'color1',0),
        body_blemishes         = ovFld(11,'index',0), body_blemishes_1_opacity     = ovFld(11,'opacity',0),
        add_body_blemishes     = ovFld(12,'index',0), add_body_blemishes_1_opacity = ovFld(12,'opacity',0),
        -- Komponenten
        mask_1   = compD('mask'),    mask_2   = compT('mask'),
        arms     = compD('arms'),    arms_2   = compT('arms'),
        bags_1   = compD('bag'),     bags_2   = compT('bag'),
        shoes_1  = compD('shoes'),   shoes_2  = compT('shoes'),
        chain_1  = compD('accessories'), chain_2 = compT('accessories'),
        tshirt_1 = compD('undershirt'),  tshirt_2 = compT('undershirt'),
        bproof_1 = compD('armor'),   bproof_2 = compT('armor'),
        decals_1 = compD('decal'),   decals_2 = compT('decal'),
        torso_1  = compD('jacket'),  torso_2  = compT('jacket'),
        pants_1  = compD('legs'),    pants_2  = compT('legs'),
        -- Props
        helmet_1   = propD('hat'),      helmet_2   = propT('hat'),
        glasses_1  = propD('glasses'),  glasses_2  = propT('glasses'),
        ear_1      = propD('ear'),      ear_2      = propT('ear'),
        watch_1    = propD('watch'),    watch_2    = propT('watch'),
        bracelet_1 = propD('bracelet'), bracelet_2 = propT('bracelet'),
    }
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
                -- users.skin im ESX/Skinchanger Flat-Format schreiben
                -- damit zr-multicharacter das Format korrekt verarbeiten kann
                local esxData = awSkinToEsx(skinData)
                local esxJson = esxData and json.encode(esxData) or skinJson
                MySQL.update(
                    'UPDATE users SET skin = ? WHERE identifier = ?',
                    { esxJson, identifier }
                )
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

    -- Gruppe im Server-Log ausgeben (hilft bei Diagnose)
    local grp = xPlayer.getGroup and xPlayer.getGroup() or xPlayer.group or 'unbekannt'
    print(string.format('^3[AWskin] canOpenMenu | Spieler %d | Gruppe: "%s"^7', source, tostring(grp)))

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

-- ─── esx_skin kompatibler Server-Layer ───────────────────────────────────────
-- Damit alle Ressourcen die ESX.TriggerServerCallback('esx_skin:getPlayerSkin')
-- oder TriggerServerEvent('esx_skin:save') nutzen, nahtlos funktionieren.

ESX.RegisterServerCallback('esx_skin:getPlayerSkin', function(source, cb, identifier)
    -- Manche Multichar-Ressourcen übergeben einen Identifier-Parameter
    -- (z.B. ESX.TriggerServerCallback('esx_skin:getPlayerSkin', cb, 'license:abc123'))
    -- Falls kein Identifier angegeben, den des aufrufenden Spielers verwenden.
    local targetIdentifier = identifier
    if not targetIdentifier or targetIdentifier == '' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then cb(nil) return end
        targetIdentifier = xPlayer.identifier
    end

    MySQL.query(
        'SELECT skin FROM ?? WHERE identifier = ?',
        { Config.DatabaseTable, targetIdentifier },
        function(result)
            local skin = nil
            if result and result[1] and result[1].skin then
                skin = json.decode(result[1].skin)
            end
            dbg('esx_skin:getPlayerSkin | %s | skin=%s', targetIdentifier, skin and 'ja' or 'nil')
            cb(skin)
        end
    )
end)

-- ─── Multicharakter: Skin per Identifier abrufen (raw JSON) ──────────────────
-- Aufruf aus dem Multichar-Script:
--   ESX.TriggerServerCallback('austriawien_skinmenu:getSkinByIdentifier', function(skinJson) ... end, identifier)
-- Gibt das rohe JSON zurück (oder nil falls kein Skin vorhanden).
ESX.RegisterServerCallback('austriawien_skinmenu:getSkinByIdentifier', function(source, cb, identifier)
    if not identifier or identifier == '' then cb(nil) return end
    MySQL.query(
        'SELECT skin FROM ?? WHERE identifier = ?',
        { Config.DatabaseTable, identifier },
        function(result)
            if result and result[1] and result[1].skin then
                dbg('getSkinByIdentifier: Skin für %s gefunden', identifier)
                cb(result[1].skin)
            else
                dbg('getSkinByIdentifier: kein Skin für %s', identifier)
                cb(nil)
            end
        end
    )
end)

-- esx_skin:save: andere Ressourcen speichern Skin über diesen Event.
-- Wir unterstützen sowohl das Flat-Format (esx_skin/skinchanger) als auch
-- unser AWskin Nested-Format und konvertieren entsprechend für beide DBs.
RegisterNetEvent('esx_skin:save')
AddEventHandler('esx_skin:save', function(skin)
    local src     = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or type(skin) ~= 'table' then return end

    local identifier = xPlayer.identifier

    -- Format erkennen: Flat-Format hat 'sex'/'torso_1'/'mom' auf Root-Ebene
    local awData, esxData
    if skin.sex ~= nil or skin.torso_1 ~= nil or skin.mom ~= nil then
        -- Flat-Format → direkt speichern (in austriawien_skins UND users.skin)
        awData  = skin
        esxData = skin
        dbg('esx_skin:save: Flat-Format erkannt | %s', identifier)
    else
        -- AWskin-Format → für users.skin konvertieren
        awData  = skin
        esxData = awSkinToEsx(skin) or skin
        dbg('esx_skin:save: AWskin-Format erkannt | %s', identifier)
    end

    local skinJson = json.encode(awData)
    local esxJson  = json.encode(esxData)
    dbg('esx_skin:save | %s | %d Bytes', identifier, #skinJson)

    MySQL.update(
        'INSERT INTO ?? (identifier, skin) VALUES (?, ?) ON DUPLICATE KEY UPDATE skin = ?, updated_at = NOW()',
        { Config.DatabaseTable, identifier, skinJson, skinJson },
        function()
            MySQL.update('UPDATE users SET skin = ? WHERE identifier = ?', { esxJson, identifier })
        end
    )
end)
