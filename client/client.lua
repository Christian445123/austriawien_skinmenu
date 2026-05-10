local ESX         = nil
local isMenuOpen  = false
local cam         = nil
local camAngle    = 0.0
local camDist     = nil  -- aktuelle Zoom-Distanz (nil = Config.CameraDistance)
local camHeight   = nil  -- aktuelle Kamerahöhe   (nil = Config.CameraHeight)
local camLookAt   = 0.5  -- aktueller LookAt-Offset
local savedSkin   = {}
local currentSkin = {}

-- ─── Debug-Helper ────────────────────────────────────────────────────────────
-- Debug-Ausgaben in der F8-Konsole (lokal) UND in der Serverkonsole.
local function dbg(msg, ...)
    if Config.Debug then
        local formatted = ('^3[AWskin CLIENT]^7 ' .. tostring(msg)):format(...)
        print(formatted)  -- F8-Konsole (lokal sichtbar)
        TriggerServerEvent('austriawien_skinmenu:debugLog', formatted)
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
    { id = 'shoes',       type = 'component', index = 6,  label = 'Schuhe',      icon = '👟', zone = 'shoes' },
    { id = 'watch',       type = 'prop',      index = 6,  label = 'Uhr',         icon = '⌚', zone = 'hands' },
    { id = 'bracelet',    type = 'prop',      index = 7,  label = 'Armband',     icon = '📿', zone = 'hands' },
}

-- Lookup-Tabelle für schnellen Zugriff
local SLOT_MAP = {}
for _, s in ipairs(SLOTS) do
    SLOT_MAP[s.id] = s
end

-- ─── Skin-Cache ───────────────────────────────────────────────────────────────
-- HeadBlend, Overlays und Gesichtszüge können NICHT direkt aus dem Ped gelesen
-- werden. Daher cachen wir den zuletzt angewendeten Skin als Referenz.
local lastAppliedSkin = nil

-- ─── Format-Erkennung ─────────────────────────────────────────────────────────
-- ESX/Skinchanger Flat-Format hat 'sex', 'mom', 'torso_1' auf Root-Ebene.
-- Unser AWskin-Format hat 'components', 'props', 'face'.
local function isEsxFlatFormat(skin)
    if type(skin) ~= 'table' then return false end
    return skin.components == nil and skin.face == nil and skin.props == nil
        and (skin.sex ~= nil or skin.torso_1 ~= nil or skin.mom ~= nil or skin.hair ~= nil)
end

-- ─── ESX/Skinchanger Flat-Format → AWskin Nested Format ──────────────────────
-- Konvertiert das esx_skin / skinchanger Flat-Format in unser AWskin-Format.
-- Unterstützt dabei alle GTA V Overlays (0-12) und Gesichtszüge.
local function esxSkinToAW(s)
    if not s or type(s) ~= 'table' then return nil end
    if not isEsxFlatFormat(s) then return s end  -- bereits unser Format

    local result = {
        model = ((s.sex or 0) == 1) and 'mp_f_freemode_01' or 'mp_m_freemode_01',
        components = {
            mask        = { drawable = s.mask_1        or 0, texture = s.mask_2        or 0 },
            arms        = { drawable = s.arms          or 0, texture = s.arms_2        or 0 },
            bag         = { drawable = s.bags_1        or 0, texture = s.bags_2        or 0 },
            shoes       = { drawable = s.shoes_1       or 0, texture = s.shoes_2       or 0 },
            accessories = { drawable = s.chain_1       or 0, texture = s.chain_2       or 0 },
            undershirt  = { drawable = s.tshirt_1      or 0, texture = s.tshirt_2      or 0 },
            armor       = { drawable = s.bproof_1      or 0, texture = s.bproof_2      or 0 },
            decal       = { drawable = s.decals_1      or 0, texture = s.decals_2      or 0 },
            jacket      = { drawable = s.torso_1       or 0, texture = s.torso_2       or 0 },
            legs        = { drawable = s.pants_1       or 0, texture = s.pants_2       or 0 },
            hair        = { drawable = s.hair          or 0, texture = 0               },
        },
        props = {
            hat      = { drawable = s.helmet_1   ~= nil and s.helmet_1   or -1, texture = s.helmet_2   or 0 },
            glasses  = { drawable = s.glasses_1  ~= nil and s.glasses_1  or -1, texture = s.glasses_2  or 0 },
            ear      = { drawable = s.ear_1      ~= nil and s.ear_1      or -1, texture = s.ear_2      or 0 },
            watch    = { drawable = s.watch_1    ~= nil and s.watch_1    or -1, texture = s.watch_2    or 0 },
            bracelet = { drawable = s.bracelet_1 ~= nil and s.bracelet_1 or -1, texture = s.bracelet_2 or 0 },
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
            -- Gesichtszüge: Skinchanger speichert Werte in -10..10, GTA V braucht -1.0..1.0
            features = {
                (s.nose_1        or 0) / 10,  -- feature 0: Nasenbreite
                (s.nose_2        or 0) / 10,  -- feature 1: Nasenspitze Höhe
                (s.nose_3        or 0) / 10,  -- feature 2: Nasenspitze Länge
                (s.nose_4        or 0) / 10,  -- feature 3: Nasenbein Höhe
                (s.nose_5        or 0) / 10,  -- feature 4: Nasenspitze Senkung
                (s.nose_6        or 0) / 10,  -- feature 5: Nasenknick
                (s.cheeks_1      or 0) / 10,  -- feature 6: Wangenbein Höhe
                (s.cheeks_2      or 0) / 10,  -- feature 7: Wangenbein Breite
                (s.cheeks_3      or 0) / 10,  -- feature 8: Wangenbreite
                0,                            -- feature 9: (nicht in skinchanger)
                (s.lip_thickness or 0) / 10,  -- feature 10: Lippendicke
                0,                            -- feature 11: Augenöffnung
                (s.jaw_1         or 0) / 10,  -- feature 12: Kieferbreite
                (s.jaw_2         or 0) / 10,  -- feature 13: Kieferlänge
                (s.chin_1        or 0) / 10,  -- feature 14: Kinnhöhe
                (s.chin_2        or 0) / 10,  -- feature 15: Kinnlänge
                (s.chin_3        or 0) / 10,  -- feature 16: Kinnbreite
                0, 0, 0                        -- feature 17-19: (nicht in skinchanger)
            },
            -- Alle 13 GTA V Overlays (0=Hautunreinheiten bis 12=Zusatzmakel)
            overlays = {
                { id=0,  index=s.blemishes          or 0, opacity=s.blemishes_1_opacity          or 0 },
                { id=1,  index=s.beard              or 0, opacity=s.beard_1_opacity              or 0, colorType=1, color1=s.beard_1          or 0, color2=s.beard_2          or 0 },
                { id=2,  index=s.eyebrow            or 0, opacity=s.eyebrow_1_opacity            or 1, colorType=1, color1=s.eyebrow_1        or 0, color2=s.eyebrow_2        or 0 },
                { id=3,  index=s.aging              or 0, opacity=s.aging_1_opacity              or 0 },
                { id=4,  index=s.makeup             or 0, opacity=s.makeup_1_opacity             or 0, colorType=2, color1=s.makeup_1         or 0, color2=0 },
                { id=5,  index=s.blush              or 0, opacity=s.blush_1_opacity              or 0, colorType=2, color1=s.blush_1          or 0, color2=0 },
                { id=6,  index=s.complexion         or 0, opacity=s.complexion_1_opacity         or 0 },
                { id=7,  index=s.sun_damage         or 0, opacity=s.sun_damage_1_opacity         or 0 },
                { id=8,  index=s.lipstick           or 0, opacity=s.lipstick_1_opacity           or 0, colorType=2, color1=s.lipstick_1       or 0, color2=0 },
                { id=9,  index=s.freckles           or 0, opacity=s.freckles_1_opacity           or 0 },
                { id=10, index=s.chest_hair         or 0, opacity=s.chest_hair_1_opacity         or 0, colorType=1, color1=s.chest_hair_1     or 0, color2=0 },
                { id=11, index=s.body_blemishes     or 0, opacity=s.body_blemishes_1_opacity     or 0 },
                { id=12, index=s.add_body_blemishes or 0, opacity=s.add_body_blemishes_1_opacity or 0 },
            },
        }
    }
    return result
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

    -- Face-Daten: aus Cache lesen, da HeadBlend/Overlays/Gesichtszüge nicht nativ
    -- aus dem Ped auslesbar sind. lastAppliedSkin hält immer den zuletzt gesetzten Skin.
    if lastAppliedSkin and lastAppliedSkin.face then
        skin.face = lastAppliedSkin.face
    else
        dbg('readCurrentSkin: WARNUNG – kein Face-Cache (lastAppliedSkin=nil), Standardwerte werden verwendet!')
        skin.face = {
            hairColor1   = GetPedHairColor(ped),
            hairColor2   = GetPedHairHighlightColor(ped),
            eyeColor     = GetPedEyeColor(ped),
            shapeFirst   = 0,  shapeSecond = 0,  shapeMix = 0.5,
            skinFirst    = 0,  skinSecond  = 0,  skinMix  = 0.5,
            eyebrowColor = 0,
            features     = {},
            overlays     = {
                { id=0,  index=0, opacity=0 },
                { id=1,  index=0, opacity=0, colorType=1, color1=0, color2=0 },
                { id=2,  index=0, opacity=1, colorType=1, color1=0, color2=0 },
                { id=3,  index=0, opacity=0 },
                { id=4,  index=0, opacity=0, colorType=2, color1=0, color2=0 },
                { id=5,  index=0, opacity=0, colorType=2, color1=0, color2=0 },
                { id=6,  index=0, opacity=0 },
                { id=7,  index=0, opacity=0 },
                { id=8,  index=0, opacity=0, colorType=2, color1=0, color2=0 },
                { id=9,  index=0, opacity=0 },
                { id=10, index=0, opacity=0, colorType=1, color1=0, color2=0 },
                { id=11, index=0, opacity=0 },
                { id=12, index=0, opacity=0 },
            },
        }
    end

    -- Modell (Geschlecht)
    local modelHash = GetEntityModel(ped)
    if modelHash == GetHashKey('mp_f_freemode_01') then
        skin.model = 'mp_f_freemode_01'
    else
        skin.model = 'mp_m_freemode_01'
    end

    return skin
end

-- ─── Appearance auf beliebigen Ped anwenden (kein Modellwechsel) ─────────────
-- Wird intern von applySkin UND von Multicharakter-Previews genutzt.
local function applyAppearanceToPed(ped, skin)
    -- Flat-Format (esx_skin/skinchanger) automatisch konvertieren
    if isEsxFlatFormat(skin) then
        skin = esxSkinToAW(skin)
        if not skin then return end
    end

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
        -- HeadBlend ZUERST setzen.
        SetPedHeadBlendData(ped,
            f.shapeFirst  or 0, f.shapeSecond or 0, 0,
            f.skinFirst   or 0, f.skinSecond  or 0, 0,
            f.shapeMix    or 0.5, f.skinMix   or 0.5, 0.0, false
        )
        -- Haarfarbe sofort setzen …
        SetPedHairColor(ped, f.hairColor1 or 0, f.hairColor2 or 0)
        SetPedEyeColor(ped, f.eyeColor or 0)
        -- … und nochmals nach einem Frame, da SetPedHeadBlendData nicht synchron ist
        -- und der erste Aufruf manchmal nicht greift.
        local _ped2, _h1, _h2, _eye = ped, f.hairColor1 or 0, f.hairColor2 or 0, f.eyeColor or 0
        CreateThread(function()
            Wait(0)
            if DoesEntityExist(_ped2) then
                SetPedHairColor(_ped2, _h1, _h2)
                SetPedEyeColor(_ped2, _eye)
            end
        end)
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
        -- Augenbrauenfarbe wiederherstellen (separat gespeichert)
        if f.eyebrowColor then
            SetPedHeadOverlayColor(ped, 2, 1, f.eyebrowColor, 0)
        end
    end
end

-- ─── Skin anwenden (Spieler-Ped inkl. Modellwechsel) ─────────────────────────
local function applySkin(skin)
    local ped = PlayerPedId()

    -- Modell wechseln falls nötig (Wait() ist ok – läuft immer in Citizen-Thread)
    if skin.model then
        local targetHash = GetHashKey(skin.model)
        if GetEntityModel(ped) ~= targetHash then
            local valid = false
            for _, m in ipairs(Config.AllowedModels) do
                if m == skin.model then valid = true; break end
            end
            if valid then
                dbg('applySkin: Modellwechsel → %s', skin.model)
                RequestModel(targetHash)
                local t = 0
                while not HasModelLoaded(targetHash) and t < 50 do
                    Wait(100); t = t + 1
                end
                if HasModelLoaded(targetHash) then
                    SetPlayerModel(PlayerId(), targetHash)
                    SetModelAsNoLongerNeeded(targetHash)
                    ped = PlayerPedId()
                end
            end
        end
    end

    applyAppearanceToPed(ped, skin)
    -- Skin cachen damit openSkinMenu und readCurrentSkin die Face-Daten verwenden können
    lastAppliedSkin = skin
    dbg('applySkin: Skin angewendet und gecacht')
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
    -- Negatives Vorzeichen: GTA Heading läuft im Uhrzeigersinn (90° = Westen, nicht Osten)
    -- -heading stellt die Kamera immer vor den Charakter (Vorderseite sichtbar)
    camAngle  = -GetEntityHeading(ped)
    -- Zone-Zoom zurücksetzen: Menü startet immer mit Standard-Distanz
    camDist   = nil
    camHeight = nil
    camLookAt = 0.5

    -- Seitwärts-Versatz: rechtwinklig zur Blickrichtung der Kamera
    local sideOffset = Config.CameraSideOffset or -0.3  -- negativ = leicht nach rechts versetzen
    local sinA = math.sin(math.rad(camAngle))
    local cosA = math.cos(math.rad(camAngle))

    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    local x = pos.x + Config.CameraDistance * sinA + sideOffset * cosA
    local y = pos.y + Config.CameraDistance * cosA - sideOffset * sinA
    SetCamCoord(cam, x, y, pos.z + Config.CameraHeight)
    PointCamAtCoord(cam, pos.x, pos.y, pos.z + 0.5)
    SetCamFov(cam, Config.CameraFOV)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, false)
end

local function updateCameraPos()
    if not cam or not DoesCamExist(cam) then return end
    local ped        = PlayerPedId()
    local pos        = GetEntityCoords(ped)
    local dist       = camDist   or Config.CameraDistance
    local height     = camHeight or Config.CameraHeight
    local lookAt     = camLookAt or 0.5
    local sideOffset = Config.CameraSideOffset or -0.3
    local sinA       = math.sin(math.rad(camAngle))
    local cosA       = math.cos(math.rad(camAngle))
    local x          = pos.x + dist * sinA + sideOffset * cosA
    local y          = pos.y + dist * cosA - sideOffset * sinA
    SetCamCoord(cam, x, y, pos.z + height)
    PointCamAtCoord(cam, pos.x, pos.y, pos.z + lookAt)
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
    local pos = GetEntityCoords(ped)
    dbg('Menü öffnen | Ped=%d | Pos=%.1f,%.1f,%.1f', ped, pos.x, pos.y, pos.z)
    savedSkin    = readCurrentSkin()
    currentSkin  = readCurrentSkin()
    isMenuOpen   = true

    -- HeadBlend nur neu setzen wenn Cache vorhanden – verhindert visuellen Reset
    -- des Gesichts wenn lastAppliedSkin nil ist (z.B. Skin durch andere Ressource gesetzt).
    -- WICHTIG: Ohne diese Prüfung würden alle face-Werte auf 0 gesetzt → falsches Gesicht!
    if lastAppliedSkin and lastAppliedSkin.face then
        local f = lastAppliedSkin.face
        SetPedHeadBlendData(ped,
            f.shapeFirst  or 0, f.shapeSecond or 0, 0,
            f.skinFirst   or 0, f.skinSecond  or 0, 0,
            f.shapeMix    or 0.5, f.skinMix   or 0.5, 0.0, false
        )
        dbg('openSkinMenu: HeadBlend aus Cache initialisiert (shapeFirst=%d skinFirst=%d shapeMix=%.2f)',
            f.shapeFirst or 0, f.skinFirst or 0, f.shapeMix or 0.5)
    else
        dbg('openSkinMenu: WARNUNG – kein lastAppliedSkin-Cache, HeadBlend NICHT neu gesetzt (Gesicht bleibt wie es ist)')
    end

    if Config.FreezeOnOpen then
        FreezeEntityPosition(ped, true)
        dbg('Ped eingefroren')
    end
    -- Charakter still stehen lassen: alle laufenden Tasks sofort abbrechen
    -- und danach TaskStandStill setzen, damit GTA V keine Idle-Animationen startet.
    ClearPedTasksImmediately(ped)
    TaskStandStill(ped, -1)
    DisplayHud(false)
    DisplayRadar(false)
    createCamera()
    SetNuiFocus(true, true)

    -- Charakter-Name aus ESX-Daten lesen
    local charName   = 'Unbekannt'
    local charGender = (currentSkin.model == 'mp_f_freemode_01') and 'Weiblich' or 'Männlich'
    local playerData = ESX and ESX.GetPlayerData and ESX.GetPlayerData() or nil
    if playerData then
        if playerData.firstName and playerData.lastName then
            charName = playerData.firstName .. ' ' .. playerData.lastName
        elseif playerData.name then
            charName = playerData.name
        end
    end

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
        imageFormats  = Config.ImageFormats  or { 'png' },
        charName      = charName,
        charGender    = charGender
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
        dbg('Originalskin wird wiederhergestellt')
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

-- Kamera-Fokus pro Zone anpassen
-- Werte direkt aus skinchanger/config.lua (camOffset / zoomOffset)
local ZONE_CAM = {
    head   = { height = 0.65, lookAt = 0.65, dist = 1.6  },
    face   = { height = 0.65, lookAt = 0.65, dist = 1.6  },
    torso  = { height = 0.15, lookAt = 0.15, dist = 1.75 },
    hands  = { height = 0.05, lookAt = 0.05, dist = 1.75 },
    legs   = { height = 0, lookAt = 0, dist = 1.8  },
    shoes  = { height = -0.8, lookAt = -0.8, dist = 1.0  },
}

local function setCameraZone(zone)
    if not cam or not DoesCamExist(cam) then return end
    local cfg    = ZONE_CAM[zone] or ZONE_CAM['torso']
    -- Werte merken, damit updateCameraPos (Drehen) denselben Zoom behält
    camDist      = cfg.dist
    camHeight    = cfg.height
    camLookAt    = cfg.lookAt
    updateCameraPos()
    SetCamFov(cam, Config.CameraFOV)
end

RegisterNUICallback('focusZone', function(data, cb)
    setCameraZone(data.zone or 'torso')
    cb({})
end)

-- Kamera drehen
RegisterNUICallback('rotateCamera', function(data, cb)
    camAngle = camAngle + (data.direction == 'left' and -20.0 or 20.0)
    updateCameraPos()
    cb({})
end)

-- Kamera zoomen
RegisterNUICallback('zoomCamera', function(data, cb)
    local dist = camDist or Config.CameraDistance
    if data.direction == 'in' then
        dist = math.max(0.6, dist - 0.25)
    else
        dist = math.min(5.0, dist + 0.25)
    end
    camDist = dist
    updateCameraPos()
    cb({})
end)

-- Kamera-Höhe anpassen
RegisterNUICallback('camHeightChange', function(data, cb)
    local h  = camHeight or Config.CameraHeight
    local la = camLookAt or 0.5
    if data.direction == 'up' then
        h  = math.min(1.8, h  + 0.15)
        la = math.min(1.8, la + 0.15)
    else
        h  = math.max(-1.2, h  - 0.15)
        la = math.max(-1.2, la - 0.15)
    end
    camHeight = h
    camLookAt = la
    updateCameraPos()
    cb({})
end)

-- Haarfarbe setzen
RegisterNUICallback('setHairColor', function(data, cb)
    SetPedHairColor(PlayerPedId(), data.color1 or 0, data.color2 or 0)
    cb({})
end)

-- Augenfarbe setzen
RegisterNUICallback('setEyeColor', function(data, cb)
    SetPedEyeColor(PlayerPedId(), data.index or 0)
    cb({})
end)

-- Geschlecht / Modell wechseln
RegisterNUICallback('setGender', function(data, cb)
    local model = tostring(data.model or '')
    local valid = false
    for _, m in ipairs(Config.AllowedModels) do
        if m == model then valid = true; break end
    end
    if not valid then
        dbg('setGender: ungültiges Modell "%s"', model)
        cb({ ok = false })
        return
    end

    local targetHash = GetHashKey(model)
    if GetEntityModel(PlayerPedId()) == targetHash then
        cb({ ok = true, maxValues = getMaxValues() })
        return
    end

    dbg('setGender: lade Modell "%s"', model)
    RequestModel(targetHash)
    local t = 0
    while not HasModelLoaded(targetHash) and t < 100 do
        Wait(100)
        t = t + 1
    end

    if not HasModelLoaded(targetHash) then
        dbg('setGender: Modell konnte nicht geladen werden')
        cb({ ok = false })
        return
    end

    SetPlayerModel(PlayerId(), targetHash)
    SetModelAsNoLongerNeeded(targetHash)

    local ped = PlayerPedId()
    -- Standardkomponenten für das neue Modell setzen (sonst erscheint der Ped nackt/kaputt)
    SetPedDefaultComponentVariation(ped)

    -- Gesichtsmerkmale und Overlays auf neuem Modell wiederherstellen
    if lastAppliedSkin and lastAppliedSkin.face then
        local f = lastAppliedSkin.face
        SetPedHeadBlendData(ped,
            f.shapeFirst  or 0, f.shapeSecond or 0, 0,
            f.skinFirst   or 0, f.skinSecond  or 0, 0,
            f.shapeMix    or 0.5, f.skinMix   or 0.5, 0.0, false
        )
        SetPedHairColor(ped, f.hairColor1 or 0, f.hairColor2 or 0)
        SetPedEyeColor(ped, f.eyeColor or 0)
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
        if f.eyebrowColor then
            SetPedHeadOverlayColor(ped, 2, 1, f.eyebrowColor, 0)
        end
        dbg('setGender: Gesicht auf neuem Modell (%s) wiederhergestellt', model)
    else
        dbg('setGender: kein Face-Cache – Gesicht bleibt Standard des neuen Modells')
    end

    if Config.FreezeOnOpen and isMenuOpen then
        FreezeEntityPosition(ped, true)
    end
    -- NUI-Fokus nach dem Modellwechsel neu setzen (SetPlayerModel kann ihn zurücksetzen)
    SetNuiFocus(true, true)
    updateCameraPos()

    dbg('setGender: Modell gewechselt zu "%s"', model)
    cb({ ok = true, maxValues = getMaxValues() })
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
    -- Cache sofort mit dem gespeicherten Skin aktualisieren.
    -- Ohne dieses Update hätte das nächste Menüöffnen noch die alten
    -- Haarfarben / Face-Daten im Cache (lastAppliedSkin), da closeSkinMenu(false)
    -- applySkin() NICHT aufruft.
    if data.skin then
        local skinToCache = data.skin
        if isEsxFlatFormat(skinToCache) then
            skinToCache = esxSkinToAW(skinToCache)
        end
        if skinToCache then
            lastAppliedSkin = skinToCache
            lastSkin        = skinToCache
            dbg('save: Cache aktualisiert | hairColor1=%d hairColor2=%d eyeColor=%d',
                skinToCache.face and skinToCache.face.hairColor1 or -1,
                skinToCache.face and skinToCache.face.hairColor2 or -1,
                skinToCache.face and skinToCache.face.eyeColor   or -1
            )
        end
    end
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
    if ESX == nil then
        TriggerEvent('chat:addMessage', { color = {231,76,60}, args = { '[Garderobe]', 'Bitte warte kurz, ESX lädt noch...' } })
        return
    end
    if args[1] then
        -- /awskin [id] → Admin-Aktion, Prüfung läuft serverseitig
        local targetId = tonumber(args[1])
        if targetId then
            dbg('Befehl: öffne Menü für Spieler %d (Admin)', targetId)
            TriggerServerEvent('austriawien_skinmenu:adminOpenForTarget', targetId)
        else
            dbg('Befehl: ungültige ID "%s"', tostring(args[1]))
            TriggerEvent('chat:addMessage', { color = {231,76,60}, args = { '[Garderobe]', 'Ungültige Spieler-ID.' } })
        end
    else
        -- /awskin (eigenes Menü) → Server prüft: Admin ODER erstes Mal
        ESX.TriggerServerCallback('austriawien_skinmenu:canOpenMenu', function(allowed)
            if allowed then
                dbg('Befehl: eigenes Menü öffnen (Zugriff gewährt)')
                openSkinMenu()
            else
                dbg('Befehl: Zugriff verweigert (kein Admin)')
                TriggerEvent('chat:addMessage', { color = {231,76,60}, args = { '[Garderobe]', 'Kein Zugriff. Nur Admins können das Menü öffnen.' } })
            end
        end)
    end
end, false)

-- Admin hat diesen Client als Ziel ausgewählt
RegisterNetEvent('austriawien_skinmenu:openForTarget')
AddEventHandler('austriawien_skinmenu:openForTarget', function()
    openSkinMenu()
end)

-- ─── esx_skin kompatibler Event-Layer ────────────────────────────────────────
-- esx_skin läuft NICHT. Wir registrieren dieselben Event-Namen so dass alle
-- Ressourcen die esx_skin-Events nutzen automatisch mit unserem Menü arbeiten.

local skinLoaded = false
local lastSkin   = nil  -- Cache für esx_skin:getLastSkin Kompatibilität

-- ── Spieler-Login: Skin laden ─────────────────────────────────────────────
-- esx_identity / zr-identity triggern nach der Anmeldung 'esx_skin:playerRegistered'.
-- Wir laden hier unseren Skin aus der DB.
AddEventHandler('esx_skin:playerRegistered', function()
    dbg('esx_skin:playerRegistered empfangen')
    CreateThread(function()
        while ESX == nil or not ESX.PlayerLoaded do Wait(100) end
        if not skinLoaded then
            skinLoaded = true
            TriggerServerEvent('austriawien_skinmenu:loadSkin')
        end
    end)
end)

AddEventHandler('esx_skin:resetFirstSpawn', function()
    dbg('esx_skin:resetFirstSpawn → reset skinLoaded')
    skinLoaded = false
end)

-- Skin-Cache für andere Ressourcen (esx_skin Kompatibilität)
AddEventHandler('esx_skin:getLastSkin', function(cb) cb(lastSkin) end)
AddEventHandler('esx_skin:setLastSkin', function(skin) lastSkin = skin end)

-- ── Menü-Events: alle esx_skin Varianten abfangen ────────────────────────
-- Statt esx_skin's eigenem Menü öffnen wir unser AWskin-Menü.
-- CancelEvent() verhindert dass andere Handler (falls vorhanden) reagieren.

RegisterNetEvent('esx_skin:openSaveableMenu')
AddEventHandler('esx_skin:openSaveableMenu', function()
    CancelEvent()
    dbg('esx_skin:openSaveableMenu → AWskin-Menü öffnen')
    CreateThread(function() Wait(300); openSkinMenu() end)
end)

RegisterNetEvent('esx_skin:openMenu')
AddEventHandler('esx_skin:openMenu', function()
    CancelEvent()
    dbg('esx_skin:openMenu → AWskin-Menü öffnen')
    openSkinMenu()
end)

RegisterNetEvent('esx_skin:openRestrictedMenu')
AddEventHandler('esx_skin:openRestrictedMenu', function()
    CancelEvent()
    dbg('esx_skin:openRestrictedMenu → AWskin-Menü öffnen')
    openSkinMenu()
end)

RegisterNetEvent('esx_skin:openSaveableRestrictedMenu')
AddEventHandler('esx_skin:openSaveableRestrictedMenu', function()
    CancelEvent()
    dbg('esx_skin:openSaveableRestrictedMenu → AWskin-Menü öffnen')
    openSkinMenu()
end)

-- ── Unser Server antwortet auf loadSkin ──────────────────────────────────
RegisterNetEvent('austriawien_skinmenu:applySkin')
AddEventHandler('austriawien_skinmenu:applySkin', function(skinJson, firstLogin)
    dbg('applySkin | firstLogin=%s | len=%d', tostring(firstLogin), skinJson and #skinJson or 0)
    if firstLogin then
        dbg('Erster Login → Menü öffnen')
        CreateThread(function() Wait(300); openSkinMenu() end)
        return
    end
    if not skinJson or skinJson == '' then return end
    local skin = json.decode(skinJson)
    if skin then
        -- Format-Konvertierung: ESX/Skinchanger Flat-Format → AWskin
        -- (esxSkinToAW ist eine No-Op wenn bereits AWskin-Format)
        dbg('applySkin Event: Format=%s | Modell=%s | Face=%s | Komponenten=%s',
            isEsxFlatFormat(skin) and 'ESX-Flat' or 'AWskin',
            tostring(skin.model or skin.sex),
            skin.face and 'ja' or 'nein',
            skin.components and 'ja' or 'nein'
        )
        skin = esxSkinToAW(skin)
        lastSkin         = skin
        lastAppliedSkin  = skin
        dbg('applySkin Event: Skin gecacht | Modell=%s | shapeFirst=%d skinFirst=%d',
            tostring(skin.model),
            skin.face and skin.face.shapeFirst or -1,
            skin.face and skin.face.skinFirst  or -1
        )
        applySkin(skin)
    else
        dbg('FEHLER: json.decode fehlgeschlagen | JSON-Anfang: %s', tostring(skinJson and skinJson:sub(1, 80) or 'nil'))
    end
end)

-- ── esx:onPlayerSpawn: Skin immer aus Cache/DB laden um korrekte Kleidung zu garantieren
AddEventHandler('esx:onPlayerSpawn', function()
    dbg('esx:onPlayerSpawn | skinLoaded=%s', tostring(skinLoaded))
    skinLoaded = true
    TriggerServerEvent('austriawien_skinmenu:loadSkin')
end)

AddEventHandler('esx:playerLoaded', function()
    dbg('esx:playerLoaded → reset')
    skinLoaded = false
end)

-- ─── Periodischer Autosave (alle 2-5 Minuten) ────────────────────────────────
-- Speichert den aktuellen Skin regelmäßig damit Änderungen (z.B. nach dem
-- Kleidungskauf) nicht verloren gehen, selbst wenn der Spieler crasht.
CreateThread(function()
    while true do
        -- Zufälliges Intervall zwischen 120 und 300 Sekunden (2-5 Minuten)
        local interval = math.random(120, 300) * 1000
        Wait(interval)
        -- Nur wenn ESX geladen, kein Menü offen und ein Skin im Cache ist
        if ESX and not isMenuOpen and lastAppliedSkin and lastAppliedSkin.model then
            dbg('Periodischer Autosave (Intervall: %d Sek.)', interval / 1000)
            TriggerServerEvent('austriawien_skinmenu:autoSave', lastAppliedSkin)
        end
    end
end)

-- ─── Autosave bei Logout / Ressource-Stop ─────────────────────────────────────────
-- Schickt den aktuellen Skin-Status an den Server sobald der Spieler sich
-- ausloggt oder die Ressource neu gestartet wird.
local function autoSaveSkin()
    local skin = lastAppliedSkin
    if not skin or not skin.model then
        skin = readCurrentSkin()
    end
    if skin then
        dbg('autoSaveSkin: sende aktuellen Skin an Server')
        TriggerServerEvent('austriawien_skinmenu:autoSave', skin)
    end
end

-- ESX Logout-Event (zr-multicharacter / esx_identity)
AddEventHandler('esx:onPlayerLogout', function()
    dbg('esx:onPlayerLogout → autoSaveSkin')
    autoSaveSkin()
end)

-- Fallback: Ressource wird gestoppt / Spieler trennt Verbindung
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    dbg('onResourceStop → autoSaveSkin')
    autoSaveSkin()
end)

-- ─── Multicharakter-Kompatibilität ───────────────────────────────────────────
-- Export: Kleidung/Gesicht auf einen beliebigen Preview-Ped anwenden.
-- Unterstützt AWskin-Format UND ESX/Skinchanger Flat-Format.
-- Aufruf aus dem Multichar-Script:
--   exports['austriawien_skinmenu']:applyPedSkin(ped, skinDataTableOrJson)
exports('applyPedSkin', function(ped, skinData)
    if type(skinData) == 'string' then
        skinData = json.decode(skinData)
    end
    if type(skinData) ~= 'table' then return end
    if not DoesEntityExist(ped) then return end
    -- ESX/Skinchanger Flat-Format → AWskin konvertieren falls nötig
    skinData = esxSkinToAW(skinData)
    if not skinData then return end
    CreateThread(function()
        -- Falls das Ped-Modell noch nicht geladen ist, kurz warten
        if skinData.model then
            local targetHash = GetHashKey(skinData.model)
            if GetEntityModel(ped) ~= targetHash then
                RequestModel(targetHash)
                local t = 0
                while not HasModelLoaded(targetHash) and t < 20 do
                    Wait(100); t = t + 1
                end
            end
        end
        -- Standardkomponenten zurücksetzen (sauberer Ausgangszustand)
        SetPedDefaultComponentVariation(ped)
        Wait(0)
        applyAppearanceToPed(ped, skinData)
    end)
end)

-- skinchanger-kompatibler Export: loadSkin(skin, ped, cb)
-- Ermöglicht es Multichar-Scripts die auf exports['skinchanger']:loadSkin
-- konfiguriert sind, stattdessen unseren Resource-Namen zu nutzen.
exports('loadSkin', function(skin, ped, cb)
    if type(skin) == 'string' then
        skin = json.decode(skin)
    end
    if type(skin) ~= 'table' then
        if type(cb) == 'function' then cb() end
        return
    end
    local awSkin = esxSkinToAW(skin)
    if not awSkin then
        if type(cb) == 'function' then cb() end
        return
    end
    CreateThread(function()
        local isPed = type(ped) == 'number' and ped > 0 and DoesEntityExist(ped)
        if isPed then
            -- Preview-Ped in der Charakterauswahl
            if awSkin.model then
                local h = GetHashKey(awSkin.model)
                if GetEntityModel(ped) ~= h then
                    RequestModel(h)
                    local t = 0
                    while not HasModelLoaded(h) and t < 20 do Wait(100); t = t + 1 end
                end
            end
            SetPedDefaultComponentVariation(ped)
            Wait(0)
            applyAppearanceToPed(ped, awSkin)
        else
            applySkin(awSkin)
        end
        if type(cb) == 'function' then cb() end
    end)
end)

-- Netzwerk-Event: Andere Ressourcen können diesen Event triggern um einen
-- lokalen Ped mit einem gespeicherten Skin auszustatten.
-- Beispiel:  TriggerEvent('austriawien_skinmenu:applyExternalPedSkin', skinData, ped)
AddEventHandler('austriawien_skinmenu:applyExternalPedSkin', function(skinData, ped)
    if type(skinData) == 'string' then
        skinData = json.decode(skinData)
    end
    if skinData and ped and DoesEntityExist(ped) then
        CreateThread(function()
            applyAppearanceToPed(ped, skinData)
        end)
    end
end)

-- ─── skinchanger:loadSkin abfangen ───────────────────────────────────────────
-- zr-multicharacter (ESX) ruft skinchanger:loadSkin auf.
-- Signatur: (skin, [ped,] [callback])
-- Ped als 2. Argument: Preview-Ped in der Charakterauswahl.
-- Ohne Ped: Skin auf den Spieler-Ped anwenden (normaler Login).
AddEventHandler('skinchanger:loadSkin', function(skin, pedOrCb, cbOrNil)
    -- JSON-String → Tabelle dekodieren (ESX liefert users.skin als String)
    if type(skin) == 'string' and #skin > 2 then
        skin = json.decode(skin)
    end
    if type(skin) ~= 'table' then
        local cb = type(pedOrCb) == 'function' and pedOrCb or cbOrNil
        if type(cb) == 'function' then cb() end
        return
    end

    -- Erkennen ob 2. Parameter ein Ped-Handle oder ein Callback ist
    local targetPed, cb
    if type(pedOrCb) == 'number' and pedOrCb > 0 and DoesEntityExist(pedOrCb) then
        targetPed = pedOrCb
        cb        = cbOrNil
    else
        targetPed = nil
        cb        = type(pedOrCb) == 'function' and pedOrCb or cbOrNil
    end

    -- ESX/Skinchanger Flat-Format → AWskin konvertieren falls nötig
    local awSkin = esxSkinToAW(skin)
    if not awSkin then
        if type(cb) == 'function' then cb() end
        return
    end

    CreateThread(function()
        if targetPed and DoesEntityExist(targetPed) then
            -- Preview-Ped in der Charakterauswahl: Aussehen direkt anwenden
            dbg('skinchanger:loadSkin → Preview-Ped %d', targetPed)
            SetPedDefaultComponentVariation(targetPed)
            Wait(0)
            applyAppearanceToPed(targetPed, awSkin)
        else
            -- Spieler-Ped: normaler Skin-Apply inkl. Modellwechsel
            dbg('skinchanger:loadSkin → Spieler-Ped')
            applySkin(awSkin)
        end
        if type(cb) == 'function' then cb() end
    end)
end)
