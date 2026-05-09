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
-- ─── Lizenz-Prüfung über API ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
local licenseValid = false

local function getServerIp()
    -- sv_publicIp aus server.cfg (z.B. "sv_publicIp 135.181.218.116")
    local pub = GetConvar('sv_publicIp', '')
    if pub ~= '' and pub:match('%d+%.%d+%.%d+%.%d+') then
        return pub
    end
    -- Fallback: ersten IPv4-Teil aus sv_endpoints extrahieren
    local ep = GetConvar('sv_endpoints', '')
    local ip = ep:match('(%d+%.%d+%.%d+%.%d+)')
    -- 0.0.0.0 bedeutet "alle Interfaces" – in diesem Fall keine IP senden
    if ip and ip ~= '0.0.0.0' then return ip end
    return ''
end

local function stopResourceWithError(reason)
    print('^1')
    print('^1  ################################################################')
    print('^1  ##  LIZENZ-FEHLER: ' .. tostring(reason))
    print('^1  ##  Die Resource wird gestoppt.')
    print('^1  ################################################################^7')
    -- ExecuteCommand wird vom Server-Prozess selbst ausgeführt und stoppt zuverlässig
    ExecuteCommand('stop ' .. GetCurrentResourceName())
end

Citizen.CreateThread(function()
    Citizen.Wait(1000)  -- warten bis Config geladen ist

    -- ServerSecrets wird aus server_secrets.lua geladen (server_script, vor dieser Datei)
    if type(ServerSecrets) ~= 'table' then
        print('^1[AWskin] FEHLER: server/server_secrets.lua nicht geladen! Bitte ensure prüfen.^7')
        licenseValid = true
        return
    end

    local apiUrl    = ServerSecrets.LicenseApiUrl       or ''
    local apiSecret = ServerSecrets.LicenseApiSecret    or ''
    local resName   = ServerSecrets.LicenseResourceName or GetCurrentResourceName()
    local licKey    = ServerSecrets.LicenseKey          or ''
    local serverIp  = getServerIp()

    -- Kein Lizenzserver konfiguriert – überspringen
    if apiUrl == '' then
        print('^3[AWskin] Kein Lizenzserver konfiguriert – überspringe API-Prüfung.^7')
        licenseValid = true
        return
    end

    -- ─── Lizenz prüfen ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    local licDone = false
    PerformHttpRequest(
        apiUrl .. '/api/check_license.php',
        function(statusCode, body, headers)
            licDone = true
            if statusCode == 0 or statusCode >= 500 then
                -- Server nicht erreichbar: Offline-Toleranz (verhindert Ausfall bei kurzzeitigem Serverausfall)
                print('^3[AWskin] Lizenzserver nicht erreichbar (HTTP ' .. tostring(statusCode) .. ') – Offline-Toleranz aktiv.^7')
                licenseValid = true
                return
            end
            local resp = body and json.decode(body)
            if not resp then
                local preview = body and body:sub(1, 300) or '(leer)'
                print('^1[AWskin] Ungültige API-Antwort (HTTP ' .. tostring(statusCode) .. ')^7')
                print('^1[AWskin] Body: ' .. preview .. '^7')
                -- Ungültige Antwort = Lizenz nicht bestätigt → stoppen
                licenseValid = false
                return
            end
            if resp.valid == true then
                licenseValid = true
                print('^2[AWskin] Lizenz gültig: ' .. tostring(resp.message or 'OK') .. '^7')
            else
                licenseValid = false
                print('^1[AWskin] Lizenz abgelehnt: ' .. tostring(resp.message or 'Unbekannter Fehler') .. '^7')
            end
        end,
        'POST',
        'license_key=' .. licKey .. '&server_ip=' .. serverIp .. '&resource_name=' .. resName .. '&api_secret=' .. apiSecret,
        { ['Content-Type'] = 'application/x-www-form-urlencoded' }
    )

    -- Auf Antwort warten (max. 10 Sekunden)
    local waited = 0
    while not licDone and waited < 10000 do
        Citizen.Wait(250)
        waited = waited + 250
    end
    if not licDone then
        print('^3[AWskin] Lizenzserver Timeout – Offline-Toleranz aktiv.^7')
        licenseValid = true
    end

    if not licenseValid then
        stopResourceWithError('Lizenz abgelehnt für Key: ' .. tostring(licKey))
        return
    end

    -- ─── Version prüfen (nur Info, kein Stop) ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    PerformHttpRequest(
        apiUrl .. '/api/check_version.php?' ..
            'resource_name=' .. resName .. '&current_version=' .. RESOURCE_VERSION .. '&api_secret=' .. apiSecret,
        function(statusCode, body, headers)
            if statusCode ~= 200 or not body then return end
            local resp = json.decode(body)
            if not resp or resp.up_to_date then return end
            print('^3')
            print('^3  ┌─────────────────────────────────────────────────────────────────────────────────────')
            print('^3  │  UPDATE VERFÜGBAR: v' .. tostring(resp.latest_version or '?') .. ' (Aktuell: v' .. RESOURCE_VERSION .. ')')
            if resp.changelog and resp.changelog ~= '' then
                print('^3  │  ' .. tostring(resp.changelog))
            end
            print('^3  └─────────────────────────────────────────────────────────────────────────────────────^7')
        end,
        'GET',
        '',
        {}
    )
end)

-- ─── Skin-Cache (In-Memory) ─────────────────────────────────────────────────
-- Hält den zuletzt bekannten Skin jedes Spielers im Speicher.
-- Wird beim Laden/Speichern aktualisiert und bei Spieler-Disconnect für
-- die automatische Speicherung (Autosave) genutzt.
local skinCache = {}

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

-- ─── ESX Flat-Format → AWskin Nested Format (server-seitig) ─────────────────
-- Spiegelversion der client.lua esxSkinToAW. Konvertiert skinchanger/esx_skin
-- Flat-Skins in unser AWskin-Format damit immer konsistent in der DB steht.
local function esxFlatToAW(s)
    if type(s) ~= 'table' then return s end
    -- Bereits AWskin-Format (hat components oder face oder props)
    if s.components ~= nil or s.face ~= nil or s.props ~= nil then
        if not s.model then
            s.model = (tonumber(s.sex) == 1) and 'mp_f_freemode_01' or 'mp_m_freemode_01'
        end
        return s
    end
    -- Kein erkennbares Flat-Format → unverändert zurück
    if s.sex == nil and s.torso_1 == nil and s.mom == nil and s.hair == nil then
        return s
    end
    return {
        model = ((tonumber(s.sex) or 0) == 1) and 'mp_f_freemode_01' or 'mp_m_freemode_01',
        components = {
            mask        = { drawable = s.mask_1    or 0, texture = s.mask_2    or 0 },
            arms        = { drawable = s.arms      or 0, texture = s.arms_2    or 0 },
            bag         = { drawable = s.bags_1    or 0, texture = s.bags_2    or 0 },
            shoes       = { drawable = s.shoes_1   or 0, texture = s.shoes_2   or 0 },
            accessories = { drawable = s.chain_1   or 0, texture = s.chain_2   or 0 },
            undershirt  = { drawable = s.tshirt_1  or 0, texture = s.tshirt_2  or 0 },
            armor       = { drawable = s.bproof_1  or 0, texture = s.bproof_2  or 0 },
            decal       = { drawable = s.decals_1  or 0, texture = s.decals_2  or 0 },
            jacket      = { drawable = s.torso_1   or 0, texture = s.torso_2   or 0 },
            legs        = { drawable = s.pants_1   or 0, texture = s.pants_2   or 0 },
            hair        = { drawable = s.hair      or 0, texture = 0 },
        },
        props = {
            hat      = { drawable = (s.helmet_1   ~= nil) and s.helmet_1   or -1, texture = s.helmet_2   or 0 },
            glasses  = { drawable = (s.glasses_1  ~= nil) and s.glasses_1  or -1, texture = s.glasses_2  or 0 },
            ear      = { drawable = (s.ear_1      ~= nil) and s.ear_1      or -1, texture = s.ear_2      or 0 },
            watch    = { drawable = (s.watch_1    ~= nil) and s.watch_1    or -1, texture = s.watch_2    or 0 },
            bracelet = { drawable = (s.bracelet_1 ~= nil) and s.bracelet_1 or -1, texture = s.bracelet_2 or 0 },
        },
        face = {
            hairColor1   = s.hair_color_1    or 0,
            hairColor2   = s.hair_color_2    or 0,
            eyeColor     = s.eye_color       or 0,
            shapeFirst   = s.mom             or 0,
            shapeSecond  = s.dad             or 0,
            shapeMix     = (s.face_md_weight or 50) / 100,
            skinFirst    = s.mom             or 0,
            skinSecond   = s.dad             or 0,
            skinMix      = (s.skin_md_weight or 50) / 100,
            eyebrowColor = s.eyebrow_1       or 0,
            features = {
                (s.nose_1        or 0)/10, (s.nose_2   or 0)/10, (s.nose_3 or 0)/10,
                (s.nose_4        or 0)/10, (s.nose_5   or 0)/10, (s.nose_6 or 0)/10,
                (s.cheeks_1      or 0)/10, (s.cheeks_2 or 0)/10, (s.cheeks_3 or 0)/10,
                0, (s.lip_thickness or 0)/10, 0,
                (s.jaw_1         or 0)/10, (s.jaw_2    or 0)/10,
                (s.chin_1        or 0)/10, (s.chin_2   or 0)/10, (s.chin_3  or 0)/10,
                0, 0, 0
            },
            overlays = {
                { id=0,  index=s.blemishes          or 0, opacity=s.blemishes_1_opacity          or 0 },
                { id=1,  index=s.beard              or 0, opacity=s.beard_1_opacity              or 0, colorType=1, color1=s.beard_1      or 0, color2=s.beard_2    or 0 },
                { id=2,  index=s.eyebrow            or 0, opacity=s.eyebrow_1_opacity            or 1, colorType=1, color1=s.eyebrow_1    or 0, color2=s.eyebrow_2  or 0 },
                { id=3,  index=s.aging              or 0, opacity=s.aging_1_opacity              or 0 },
                { id=4,  index=s.makeup             or 0, opacity=s.makeup_1_opacity             or 0, colorType=2, color1=s.makeup_1     or 0, color2=0 },
                { id=5,  index=s.blush              or 0, opacity=s.blush_1_opacity              or 0, colorType=2, color1=s.blush_1      or 0, color2=0 },
                { id=6,  index=s.complexion         or 0, opacity=s.complexion_1_opacity         or 0 },
                { id=7,  index=s.sun_damage         or 0, opacity=s.sun_damage_1_opacity         or 0 },
                { id=8,  index=s.lipstick           or 0, opacity=s.lipstick_1_opacity           or 0, colorType=2, color1=s.lipstick_1   or 0, color2=0 },
                { id=9,  index=s.freckles           or 0, opacity=s.freckles_1_opacity           or 0 },
                { id=10, index=s.chest_hair         or 0, opacity=s.chest_hair_1_opacity         or 0, colorType=1, color1=s.chest_hair_1 or 0, color2=0 },
                { id=11, index=s.body_blemishes     or 0, opacity=s.body_blemishes_1_opacity     or 0 },
                { id=12, index=s.add_body_blemishes or 0, opacity=s.add_body_blemishes_1_opacity or 0 },
            },
        }
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
-- Wenn der Skin bereits im Cache ist (vorgeladen über esx:playerLoaded),
-- wird er sofort ohne DB-Abfrage gesendet → kein visueller Flicker beim Spawn.
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

    -- Cache-Treffer → sofort senden (keine Wartezeit)
    if skinCache[identifier] then
        dbg('loadSkin: aus Cache | %s (%d Bytes)', identifier, #skinCache[identifier])
        TriggerClientEvent('austriawien_skinmenu:applySkin', src, skinCache[identifier], false)
        return
    end

    MySQL.query(
        'SELECT skin FROM ?? WHERE identifier = ?',
        { Config.DatabaseTable, identifier },
        function(result)
            if result and result[1] then
                dbg('Skin gefunden für %s (%d Bytes)', identifier, #result[1].skin)
                skinCache[identifier] = result[1].skin
                TriggerClientEvent('austriawien_skinmenu:applySkin', src, result[1].skin, false)
            else
                dbg('KEIN Skin in DB für %s → First-Time-Setup', identifier)
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

    -- Format sicherstellen: immer AWskin-Format in austriawien_skins
    local awSkin = esxFlatToAW(skinData)
    local skinJson = json.encode(awSkin)
    dbg('saveSkin | identifier=%s | json-länge=%d', identifier, #skinJson)

    -- Cache sofort aktualisieren
    skinCache[identifier] = skinJson

    MySQL.update(
        'INSERT INTO ?? (identifier, skin) VALUES (?, ?) ON DUPLICATE KEY UPDATE skin = ?, updated_at = NOW()',
        { Config.DatabaseTable, identifier, skinJson, skinJson },
        function(affectedRows)
            dbg('saveSkin: affectedRows=%d', affectedRows or 0)
            if affectedRows and affectedRows > 0 then
                -- users.skin im ESX/Skinchanger Flat-Format schreiben
                local esxData = awSkinToEsx(awSkin)
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
-- Immer in AWskin-Format konvertieren für österreichische_skins, Flat für users.skin.
RegisterNetEvent('esx_skin:save')
AddEventHandler('esx_skin:save', function(skin)
    local src     = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or type(skin) ~= 'table' then return end

    local identifier = xPlayer.identifier
    -- Immer zu AWskin-Format normalisieren (egal ob flat oder nicht)
    local awData  = esxFlatToAW(skin)
    local esxData = awSkinToEsx(awData) or skin

    local skinJson = json.encode(awData)
    local esxJson  = json.encode(esxData)
    dbg('esx_skin:save | %s | %d Bytes', identifier, #skinJson)

    skinCache[identifier] = skinJson
    MySQL.update(
        'INSERT INTO ?? (identifier, skin) VALUES (?, ?) ON DUPLICATE KEY UPDATE skin = ?, updated_at = NOW()',
        { Config.DatabaseTable, identifier, skinJson, skinJson },
        function()
            MySQL.update('UPDATE users SET skin = ? WHERE identifier = ?', { esxJson, identifier })
        end
    )
end)

-- ─── Skin vorladen (esx:playerLoaded) ─────────────────────────────────────────
-- Wird serverseitig beim Charakter-Login ausgelöst. Skin wird sofort aus der
-- DB in den Cache geladen, damit loadSkin auf Spawn ohne DB-Wartezeit antworten kann.
AddEventHandler('esx:playerLoaded', function(xPlayer)
    -- ESX übergibt je nach Version entweder das xPlayer-Objekt oder die Source-ID (Zahl)
    if type(xPlayer) == 'number' then
        xPlayer = ESX.GetPlayerFromId(xPlayer)
    end
    local identifier = xPlayer and xPlayer.identifier
    if not identifier then return end
    MySQL.query(
        'SELECT skin FROM ?? WHERE identifier = ?',
        { Config.DatabaseTable, identifier },
        function(result)
            if result and result[1] then
                skinCache[identifier] = result[1].skin
                dbg('esx:playerLoaded: Skin für %s vorgeladen', identifier)
            end
        end
    )
end)

-- ─── Autosave bei Spieler-Disconnect ─────────────────────────────────────────
-- Der Client sendet seinen aktuellen Skin kurz vor dem Disconnect.
-- Als Fallback schreibt playerDropped den Cache in die DB.
RegisterNetEvent('austriawien_skinmenu:autoSave')
AddEventHandler('austriawien_skinmenu:autoSave', function(skinData)
    local src     = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or type(skinData) ~= 'table' then return end

    local identifier = xPlayer.identifier
    local awSkin   = esxFlatToAW(skinData)
    local skinJson = json.encode(awSkin)
    local esxData  = awSkinToEsx(awSkin)
    local esxJson  = esxData and json.encode(esxData) or skinJson

    skinCache[identifier] = skinJson
    dbg('autoSave | %s | %d Bytes', identifier, #skinJson)

    MySQL.update(
        'INSERT INTO ?? (identifier, skin) VALUES (?, ?) ON DUPLICATE KEY UPDATE skin = ?, updated_at = NOW()',
        { Config.DatabaseTable, identifier, skinJson, skinJson },
        function()
            MySQL.update('UPDATE users SET skin = ? WHERE identifier = ?', { esxJson, identifier })
        end
    )
end)

-- Fallback: playerDropped → Cache in DB schreiben falls kein autoSave empfangen
AddEventHandler('playerDropped', function()
    local src        = source
    local identifier = nil
    -- GetPlayerIdentifier ist immer verfügbar, auch wenn ESX den Spieler schon entfernt hat
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and (id:find('^license:') or id:find('^steam:')) then
            identifier = id
            break
        end
    end
    if not identifier then return end

    local cached = skinCache[identifier]
    skinCache[identifier] = nil  -- Speicher freigeben
    if cached then
        dbg('playerDropped: Skin-Cache für %s in DB schreiben', identifier)
        MySQL.update(
            'INSERT INTO ?? (identifier, skin) VALUES (?, ?) ON DUPLICATE KEY UPDATE skin = ?, updated_at = NOW()',
            { Config.DatabaseTable, identifier, cached, cached },
            function()
                local awSkin  = json.decode(cached)
                local esxData = awSkin and awSkinToEsx(awSkin)
                if esxData then
                    MySQL.update('UPDATE users SET skin = ? WHERE identifier = ?',
                        { json.encode(esxData), identifier })
                end
            end
        )
    end
end)
