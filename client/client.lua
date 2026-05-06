local ESX         = nil
local isMenuOpen  = false
local cam         = nil
local camAngle    = 0.0
local savedSkin   = {}
local currentSkin = {}

-- ─── Debug-Helper ────────────────────────────────────────────────────────────
-- Debug-Ausgaben im FiveM-Client-Log (F8-Konsole)
local function dbg(msg, ...)
    if Config.Debug then
        print(('^3[AWskin CLIENT]^7 ' .. tostring(msg)):format(...))
    end
end

-- ─── ESX holen ───────────────────────────────────────────────────────────────
CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Wait(0)
    end
end)

-- ─── Komponenten-Definitionen ─────────────────────────────────────────────────
-- type 'component' → SetPedComponentVariation
-- type 'prop'      → SetPedPropIndex
local SLOTS = {
    -- Props (Accessoires)
    { id = 'hat',         type = 'prop',      index = 0,  label = 'Hut',         icon = '🎩', zone = 'head'  },
    { id = 'glasses',     type = 'prop',      index = 1,  label = 'Brille',      icon = '👓', zone = 'head'  },
    { id = 'ear',         type = 'prop',      index = 2,  label = 'Ohr',         icon = '💎', zone = 'head'  },
    -- Kleidung Komponenten
    { id = 'hair',        type = 'component', index = 2,  label = 'Haare',       icon = '💇', zone = 'head'  },
    { id = 'mask',        type = 'component', index = 1,  label = 'Maske',       icon = '🎭', zone = 'face'  },
    { id = 'jacket',      type = 'component', index = 11, label = 'Jacke',       icon = '🧥', zone = 'torso' },
    { id = 'undershirt',  type = 'component', index = 8,  label = 'Unterhemd',   icon = '👕', zone = 'torso' },
    { id = 'arms',        type = 'component', index = 3,  label = 'Arme',        icon = '💪', zone = 'torso' },
    { id = 'armor',       type = 'component', index = 9,  label = 'Weste',       icon = '🦺', zone = 'torso' },
    { id = 'accessories', type = 'component', index = 7,  label = 'Accessoire',  icon = '🧣', zone = 'torso' },
    { id = 'decal',       type = 'component', index = 10, label = 'Abzeichen',   icon = '🏷',  zone = 'torso' },
    { id = 'bag',         type = 'component', index = 5,  label = 'Tasche',      icon = '🎒', zone = 'torso' },
    { id = 'legs',        type = 'component', index = 4,  label = 'Hose',        icon = '👖', zone = 'legs'  },
    { id = 'shoes',       type = 'component', index = 6,  label = 'Schuhe',      icon = '👟', zone = 'legs'  },
    { id = 'watch',       type = 'prop',      index = 6,  label = 'Uhr',         icon = '⌚', zone = 'hands' },
    { id = 'bracelet',    type = 'prop',      index = 7,  label = 'Armband',     icon = '📿', zone = 'hands' },
}

-- Lookup-Tabelle für schnellen Zugriff
local SLOT_MAP = {}
for _, s in ipairs(SLOTS) do
    SLOT_MAP[s.id] = s
end

-- ─── Skin lesen ──────────────────────────────────────────────────────────────
local function readCurrentSkin()
    local ped  = PlayerPedId()
    local skin = { components = {}, props = {}, face = {} }

    for _, slot in ipairs(SLOTS) do
        if slot.type == 'component' then
            skin.components[slot.id] = {
                drawable = GetPedDrawableVariation(ped, slot.index),
                texture  = GetPedTextureVariation(ped,  slot.index)
            }
        else
            skin.props[slot.id] = {
                drawable = GetPedPropIndex(ped, slot.index),
                texture  = GetPedPropTextureIndex(ped, slot.index)
            }
        end
    end

    -- Haarfarben
    skin.face.hairColor1   = GetPedHairColor(ped)
    skin.face.hairColor2   = GetPedHairHighlightColor(ped)
    skin.face.shapeFirst   = 0
    skin.face.shapeSecond  = 0
    skin.face.shapeMix     = 0.5
    skin.face.skinFirst    = 0
    skin.face.skinSecond   = 0
    skin.face.skinMix      = 0.5
    skin.face.features     = {}
    skin.face.overlays     = {}

    return skin
end

-- ─── Skin anwenden ───────────────────────────────────────────────────────────
local function applySkin(skin)
    local ped = PlayerPedId()

    if skin.components then
        for id, data in pairs(skin.components) do
            local slot = SLOT_MAP[id]
            if slot and slot.type == 'component' then
                local maxTex = math.max(0, GetNumberOfPedTextureVariations(ped, slot.index, data.drawable) - 1)
                SetPedComponentVariation(ped, slot.index, data.drawable, math.min(data.texture, maxTex), 0)
            end
        end
    end

    if skin.props then
        for id, data in pairs(skin.props) do
            local slot = SLOT_MAP[id]
            if slot and slot.type == 'prop' then
                if data.drawable == -1 then
                    ClearPedProp(ped, slot.index)
                else
                    local maxTex = math.max(0, GetNumberOfPedPropTextureVariations(ped, slot.index, data.drawable) - 1)
                    SetPedPropIndex(ped, slot.index, data.drawable, math.min(data.texture, maxTex), true)
                end
            end
        end
    end

    if skin.face then
        local f = skin.face
        SetPedHairColor(ped, f.hairColor1 or 0, f.hairColor2 or 0)
        SetPedHeadBlendData(ped,
            f.shapeFirst  or 0, f.shapeSecond or 0, 0,
            f.skinFirst   or 0, f.skinSecond  or 0, 0,
            f.shapeMix    or 0.5, f.skinMix   or 0.5, 0.0, false
        )
        if f.features then
            for i, val in ipairs(f.features) do
                SetPedFaceFeature(ped, i - 1, val)
            end
        end
        if f.overlays then
            for _, ov in ipairs(f.overlays) do
                SetPedHeadOverlay(ped, ov.id, ov.index, ov.opacity)
                if ov.colorType and ov.colorType > 0 then
                    SetPedHeadOverlayColor(ped, ov.id, ov.colorType, ov.color1 or 0, ov.color2 or 0)
                end
            end
        end
    end
end

-- ─── Max-Werte ermitteln ─────────────────────────────────────────────────────
local function getMaxValues()
    local ped  = PlayerPedId()
    local maxV = {}

    for _, slot in ipairs(SLOTS) do
        if slot.type == 'component' then
            local maxDraw = math.max(0, GetNumberOfPedDrawableVariations(ped, slot.index) - 1)
            local curDraw = GetPedDrawableVariation(ped, slot.index)
            local maxTex  = math.max(0, GetNumberOfPedTextureVariations(ped, slot.index, curDraw) - 1)
            maxV[slot.id] = { maxDrawable = maxDraw, maxTexture = maxTex }
        else
            local maxDraw = math.max(0, GetNumberOfPedPropDrawableVariations(ped, slot.index) - 1)
            local curDraw = GetPedPropIndex(ped, slot.index)
            local maxTex  = 0
            if curDraw >= 0 then
                maxTex = math.max(0, GetNumberOfPedPropTextureVariations(ped, slot.index, curDraw) - 1)
            end
            maxV[slot.id] = { maxDrawable = maxDraw, maxTexture = maxTex }
        end
    end

    return maxV
end

-- ─── Kamera ──────────────────────────────────────────────────────────────────
-- Die UI hat ein linkes Panel (280px) und ein rechtes Panel (360px).
-- Der transparente Mittelteil liegt leicht links von der Bildschirmmitte.
-- Mit einem kleinen Seitenversatz (CameraSideOffset) zentrieren wir den
-- Charakter visuell im transparenten Bereich.
local function createCamera()
    local ped     = PlayerPedId()
    local pos     = GetEntityCoords(ped)
    camAngle      = GetEntityHeading(ped)

    -- Seitwärts-Versatz: rechtwinklig zur Blickrichtung der Kamera
    local sideOffset = Config.CameraSideOffset or -0.3  -- negativ = leicht nach rechts versetzen
    local sinA = math.sin(math.rad(camAngle))
    local cosA = math.cos(math.rad(camAngle))

    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    local x = pos.x + Config.CameraDistance * -sinA + sideOffset * cosA
    local y = pos.y + Config.CameraDistance * -cosA - sideOffset * sinA
    SetCamCoord(cam, x, y, pos.z + Config.CameraHeight)
    PointCamAtCoord(cam, pos.x, pos.y, pos.z + 0.5)
    SetCamFov(cam, Config.CameraFOV)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, false)
end

local function updateCameraPos()
    if not cam or not DoesCamExist(cam) then return end
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local x = pos.x + Config.CameraDistance * -math.sin(math.rad(camAngle))
    local y = pos.y + Config.CameraDistance * -math.cos(math.rad(camAngle))
    SetCamCoord(cam, x, y, pos.z + Config.CameraHeight)
    PointCamAtCoord(cam, pos.x, pos.y, pos.z + 0.5)
end

local function destroyCamera()
    if cam and DoesCamExist(cam) then
        SetCamActive(cam, false)
        DestroyCam(cam, false)
        RenderScriptCams(false, true, 500, true, false)
        cam = nil
    end
end

-- ─── Menü öffnen / schließen ─────────────────────────────────────────────────
local function openSkinMenu()
    if isMenuOpen then
        dbg('openSkinMenu: bereits offen, abbruch')
        return
    end

    local ped = PlayerPedId()
    dbg('Menü öffnen | Ped=%d | Pos=%.1f,%.1f,%.1f', ped, table.unpack({ GetEntityCoords(ped) }))
    savedSkin    = readCurrentSkin()
    currentSkin  = readCurrentSkin()
    isMenuOpen   = true

    if Config.FreezeOnOpen then
        FreezeEntityPosition(ped, true)
        dbg('Ped eingefroren')
    end
    DisplayHud(false)
    DisplayRadar(false)
    createCamera()
    SetNuiFocus(true, true)

    -- Slot-Definitionen als vereinfachtes Array für JS aufbereiten
    local slotDefs = {}
    for _, s in ipairs(SLOTS) do
        slotDefs[#slotDefs + 1] = {
            id    = s.id,
            type  = s.type,
            label = s.label,
            icon  = s.icon,
            zone  = s.zone
        }
    end

    SendNUIMessage({
        type          = 'openMenu',
        skin          = currentSkin,
        maxValues     = getMaxValues(),
        slotDefs      = slotDefs,
        imageBasePath = Config.ImageBasePath or 'img',
        imageFormats  = Config.ImageFormats  or { 'png' }
    })
    dbg('NUI-Nachricht openMenu gesendet | %d Slots | %d maxValues', #slotDefs, (function() local n=0 for _ in pairs(getMaxValues()) do n=n+1 end return n end)())
end

local function closeSkinMenu(restore)
    if not isMenuOpen then
        dbg('closeSkinMenu: Menü war nicht offen')
        return
    end
    isMenuOpen = false
    dbg('Menü schließen | restore=%s', tostring(restore))

    if restore then
        dbg('Originalsk in wird wiederhergestellt')
        applySkin(savedSkin)
    end

    SetNuiFocus(false, false)
    DisplayHud(true)
    DisplayRadar(true)
    FreezeEntityPosition(PlayerPedId(), false)
    destroyCamera()
    dbg('Menü geschlossen')
end

-- ─── NUI Callbacks ───────────────────────────────────────────────────────────

-- Einzelne Komponente live aktualisieren
RegisterNUICallback('updateSlot', function(data, cb)
    local ped  = PlayerPedId()
    local slot = SLOT_MAP[data.id]
    if not slot then
        dbg('updateSlot: unbekannter Slot "%s"', tostring(data.id))
        cb({})
        return
    end
    dbg('updateSlot | slot=%s | drawable=%d | texture=%d', data.id, data.drawable, data.texture)

    if slot.type == 'component' then
        local maxTex = math.max(0, GetNumberOfPedTextureVariations(ped, slot.index, data.drawable) - 1)
        local tex    = math.min(data.texture, maxTex)
        SetPedComponentVariation(ped, slot.index, data.drawable, tex, 0)
        -- Antwort: wieviele Texturen gibt es für dieses Drawable?
        cb({ maxTexture = maxTex })
    else
        if data.drawable == -1 then
            ClearPedProp(ped, slot.index)
            cb({ maxTexture = 0 })
        else
            local maxTex = math.max(0, GetNumberOfPedPropTextureVariations(ped, slot.index, data.drawable) - 1)
            local tex    = math.min(data.texture, maxTex)
            SetPedPropIndex(ped, slot.index, data.drawable, tex, true)
            cb({ maxTexture = maxTex })
        end
    end
end)

-- Maximale Texturen für ein bestimmtes Drawable abfragen
RegisterNUICallback('getTextureCount', function(data, cb)
    local ped  = PlayerPedId()
    local slot = SLOT_MAP[data.id]
    if not slot then cb({ maxTexture = 0 }) return end

    local max = 0
    if slot.type == 'component' then
        max = math.max(0, GetNumberOfPedTextureVariations(ped, slot.index, data.drawable) - 1)
    else
        if data.drawable >= 0 then
            max = math.max(0, GetNumberOfPedPropTextureVariations(ped, slot.index, data.drawable) - 1)
        end
    end
    cb({ maxTexture = max })
end)

-- Kamera drehen
RegisterNUICallback('rotateCamera', function(data, cb)
    camAngle = camAngle + (data.direction == 'left' and -20.0 or 20.0)
    updateCameraPos()
    cb({})
end)

-- Haarfarbe setzen
RegisterNUICallback('setHairColor', function(data, cb)
    SetPedHairColor(PlayerPedId(), data.color1 or 0, data.color2 or 0)
    cb({})
end)

-- Gesichts-Feature-Slider
RegisterNUICallback('setFaceFeature', function(data, cb)
    SetPedFaceFeature(PlayerPedId(), data.featureId, data.value)
    cb({})
end)

-- Head-Blend (Gesichtsform / Hautfarbe)
RegisterNUICallback('setHeadBlend', function(data, cb)
    SetPedHeadBlendData(PlayerPedId(),
        data.shapeFirst  or 0, data.shapeSecond or 0, 0,
        data.skinFirst   or 0, data.skinSecond  or 0, 0,
        data.shapeMix    or 0.5, data.skinMix   or 0.5, 0.0, false
    )
    cb({})
end)

-- Kopf-Overlay (Bart, Augenbrauen, Make-Up, …)
RegisterNUICallback('setHeadOverlay', function(data, cb)
    SetPedHeadOverlay(PlayerPedId(), data.overlayId, data.index, data.opacity)
    if (data.colorType or 0) > 0 then
        SetPedHeadOverlayColor(PlayerPedId(), data.overlayId, data.colorType, data.color1 or 0, data.color2 or 0)
    end
    cb({})
end)

-- Speichern
RegisterNUICallback('save', function(data, cb)
    dbg('NUI save – sende Skin an Server')
    -- Skin für eigenen Charakter speichern
    TriggerServerEvent('austriawien_skinmenu:saveSkin', data.skin, nil)
    closeSkinMenu(false)
    cb({})
end)

-- Abbrechen
RegisterNUICallback('cancel', function(data, cb)
    dbg('NUI cancel – stelle Original-Skin wieder her')
    closeSkinMenu(true)
    cb({})
end)

-- ─── Slash-Befehl (/awskin oder /awskin [serverID]) ────────────────────────
RegisterCommand(Config.Command, function(source, args)
    if args[1] then
        local targetId = tonumber(args[1])
        if targetId then
            dbg('Befehl: öffne Menü für Spieler %d (Admin)', targetId)
            TriggerServerEvent('austriawien_skinmenu:adminOpenForTarget', targetId)
        else
            dbg('Befehl: ungültige ID "%s"', tostring(args[1]))
            TriggerEvent('chat:addMessage', { color = {231,76,60}, args = { '[Garderobe]', 'Ungültige Spieler-ID.' } })
        end
    else
        dbg('Befehl: eigenes Menü öffnen')
        openSkinMenu()
    end
end, false)

-- Admin hat diesen Client als Ziel ausgewählt
RegisterNetEvent('austriawien_skinmenu:openForTarget')
AddEventHandler('austriawien_skinmenu:openForTarget', function()
    openSkinMenu()
end)

-- ─── ESX Events ──────────────────────────────────────────────────────────────
local skinLoaded   = false  -- verhindert Doppel-Load innerhalb einer Session
local isFirstLogin = false  -- wird vom Server gesetzt wenn kein Skin in DB

RegisterNetEvent('austriawien_skinmenu:applySkin')
AddEventHandler('austriawien_skinmenu:applySkin', function(skinJson, firstLogin)
    dbg('applySkin empfangen | firstLogin=%s | json-länge=%d', tostring(firstLogin), skinJson and #skinJson or 0)

    if firstLogin then
        -- Erstes Login: Menü öffnen, sobald der Ped wirklich bereit ist
        if Config.FirstTimeSetup then
            dbg('Erster Login erkannt – warte auf Ped...')
            CreateThread(function()
                local deadline = GetGameTimer() + 10000
                repeat
                    Wait(200)
                until (IsScreenFadedIn() and not IsEntityDead(PlayerPedId())) or GetGameTimer() > deadline
                dbg('Ped bereit – öffne Skin-Menü (First-Time-Setup)')
                Wait(500)
                openSkinMenu()
            end)
        end
        return
    end

    if not skinJson or skinJson == '' then
        dbg('Leeres skinJson empfangen, ignoriere')
        return
    end

    local skin = json.decode(skinJson)
    if skin then
        dbg('Skin wird angewendet')
        applySkin(skin)
    else
        dbg('FEHLER: json.decode fehlgeschlagen!')
    end
end)

-- Skin nur beim tatsächlichen Spawn laden (Ped existiert hier bereits)
AddEventHandler('esx:onPlayerSpawn', function()
    dbg('esx:onPlayerSpawn | skinLoaded=%s', tostring(skinLoaded))
    if not skinLoaded then
        skinLoaded = true
        dbg('Sende loadSkin an Server')
        TriggerServerEvent('austriawien_skinmenu:loadSkin')
    else
        dbg('Skin bereits geladen, überspringe loadSkin')
    end
end)

-- Beim erneuten Joinen (Reconnect) Flag zurücksetzen
AddEventHandler('esx:playerLoaded', function()
    dbg('esx:playerLoaded – setze skinLoaded zurück')
    skinLoaded = false
end)
