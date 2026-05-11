/* ═══════════════════════════════════════════════════════════════════════════
   AustriaWien Garderobe – app.js
   ══════════════════════════════════════════════════════════════════════════ */

'use strict';

// ─── GTA V Haarfarben-Palette (64 Farben, Index 0-63) ────────────────────────
// Exakte Hex-Werte aus dem offiziellen GTA V / RAGE-MP Wiki.
// Jeder Index entspricht 1:1 dem Parameter von SetPedHairColor / SetPedHairTint.
const HAIR_COLORS = [
    '#1c1f21', // 0  Sehr dunkel fast Schwarz
    '#272a2c', // 1  Dunkel Schwarz-Braun
    '#312e2c', // 2  Dunkles Dunkelbraun
    '#35261c', // 3  Dunkelbraun
    '#4b321f', // 4  Braun
    '#5c3b24', // 5  Mittelbraun
    '#6d4c35', // 6  Warmes Mittelbraun
    '#6b503b', // 7  Hellbraun-Braun
    '#765c45', // 8  Helleres Braun
    '#7f684e', // 9  Sandiges Braun
    '#99815d', // 10 Helles Braun
    '#a79369', // 11 Blondes Braun
    '#af9c70', // 12 Dunkelblond
    '#bba063', // 13 Dunkelblond warm
    '#d6b97b', // 14 Mittelblond
    '#dac38e', // 15 Hellblond
    '#9f7f59', // 16 Kupferbraun
    '#845039', // 17 Rotbraun
    '#682b1f', // 18 Dunkelrot-Braun
    '#61120c', // 19 Dunkelrot
    '#640f0a', // 20 Tief-Rot-Dunkel
    '#7c140f', // 21 Tiefrot
    '#a02e19', // 22 Rot
    '#b64b28', // 23 Helles Rot-Orange
    '#a2502f', // 24 Orange-Rot
    '#aa4e2b', // 25 Dunkel-Orange
    '#626262', // 26 Dunkelgrau
    '#808080', // 27 Grau
    '#aaaaaa', // 28 Hellgrau
    '#c5c5c5', // 29 Sehr hellgrau
    '#463955', // 30 Dunkel-Lila
    '#5a3f6b', // 31 Lila
    '#763c76', // 32 Helles Lila
    '#ed74e3', // 33 Pink-Lila
    '#eb4b93', // 34 Pink
    '#f299bc', // 35 Hellpink
    '#04959e', // 36 Türkis
    '#025f86', // 37 Dunkelblau
    '#023974', // 38 Tief-Dunkelblau
    '#3fa16a', // 39 Grün
    '#217c61', // 40 Dunkelgrün
    '#185c55', // 41 Dunkel Türkis-Grün
    '#b6c034', // 42 Gelbgrün
    '#70a90b', // 43 Olivgrün
    '#439d13', // 44 Hellgrün
    '#dcb857', // 45 Helles Gold
    '#e5b103', // 46 Gold
    '#e69102', // 47 Dunkelgold / Orange-Gold
    '#f28831', // 48 Orange
    '#fb8057', // 49 Helles Orange
    '#e28b58', // 50 Sandorange
    '#d1593c', // 51 Orange-Rot
    '#ce3120', // 52 Kräftiges Rot
    '#ad0903', // 53 Dunkelrot
    '#880302', // 54 Sehr dunkelrot
    '#1f1814', // 55 Sehr dunkel (fast Schwarz, warm)
    '#291f19', // 56 Dunkelbraun-Schwarz
    '#2e221b', // 57 Dunkelbraun 2
    '#37291e', // 58 Dunkelbraun 3
    '#2e2218', // 59 Dunkelbraun 4
    '#231b15', // 60 Dunkelbraun 5
    '#020202', // 61 Tiefschwarz
    '#706c66', // 62 Grau-Braun
    '#9d7a50', // 63 Mittleres Braun-Blond
];

// ─── GTA V Irisfarben-Palette (30 Farben, Index 0-29) ───────────────────────
// Quelle: FiveM Native-Dokumentation _SET_PED_EYE_COLOR.
// Indices 0-13: natürliche Farben. Indices 14-29: Spezial/Exotic-Muster.
const EYE_COLORS = [
    '#0d0d0d', // 0  Schwarz
    '#a8d8c5', // 1  Sehr helles Blau-Grün
    '#1e3a6e', // 2  Dunkelblau
    '#6b3a20', // 3  Braun
    '#3d1a00', // 4  Dunkelbraun
    '#a07040', // 5  Hellbraun
    '#2060b0', // 6  Blau
    '#5aabe0', // 7  Hellblau
    '#f0a0b8', // 8  Pink
    '#c8b400', // 9  Gelb
    '#7020b0', // 10 Lila
    '#141414', // 11 Schwarz (Variante)
    '#1a4d20', // 12 Dunkelgrün
    '#c8a060', // 13 Hellbraun (sandig)
    '#a09810', // 14 Gelb-Schwarz Muster
    '#c8c8c8', // 15 Helles Spiralmuster
    '#c00020', // 16 Leuchtendes Rot
    '#783090', // 17 Halb Blau / Halb Rot
    '#486090', // 18 Halb Schwarz / Halb Hellblau
    '#d0b0b0', // 19 Weiß / Rotes Muster
    '#3a8040', // 20 Grüne Schlange
    '#b03030', // 21 Rote Schlange
    '#203870', // 22 Dunkelblaue Schlange
    '#a08200', // 23 Dunkles Gelb
    '#e8d400', // 24 Leuchtendes Gelb
    '#050505', // 25 Alles Schwarz
    '#a01010', // 26 Rote kleine Pupille
    '#1e2e60', // 27 Teufel Blau-Schwarz
    '#f0f0f0', // 28 Weiße kleine Pupille
    '#d0e0f0', // 29 Milchig / Glasig
];

// ─── Gesichtszug-Namen ────────────────────────────────────────────────────────
const FACE_FEATURE_NAMES = [
    'Nasenbreite','Nasenspitze Höhe','Nasenspitze Länge','Nasenbein Höhe',
    'Nasenspitze Senkung','Nasenknick','Augenbrauenhöhe','Augenbrauenneigung',
    'Wangenbein Höhe','Wangenbein Breite','Wangenbreite','Augenöffnung',
    'Lippendicke','Kieferbreite','Kieferlänge','Kinnhöhe',
    'Kinnlänge','Kinnbreite','Kinngrübchen','Halsdicke'
];

// ─── GTA V Overlay-Definitionen (alle 13 Overlays) ───────────────────────────
// colorType: 0=kein Farbwähler, 1=Haarfarbe, 2=Make-Up-Farbe
const OVERLAYS = [
    { id: 0,  idxId: 'ov-blemishes-idx',       opId: 'ov-blemishes-op',       colorType: 0, colorEl: null             },
    { id: 1,  idxId: 'ov-beard-idx',            opId: 'ov-beard-op',            colorType: 1, colorEl: 'beard-colors'   },
    { id: 2,  idxId: 'ov-eyebrow-idx',          opId: 'ov-eyebrow-op',          colorType: 1, colorEl: 'eyebrow-colors' },
    { id: 3,  idxId: 'ov-aging-idx',            opId: 'ov-aging-op',            colorType: 0, colorEl: null             },
    { id: 4,  idxId: 'ov-makeup-idx',           opId: 'ov-makeup-op',           colorType: 2, colorEl: 'makeup-colors'  },
    { id: 5,  idxId: 'ov-blush-idx',            opId: 'ov-blush-op',            colorType: 2, colorEl: 'blush-colors'   },
    { id: 6,  idxId: 'ov-complexion-idx',       opId: 'ov-complexion-op',       colorType: 0, colorEl: null             },
    { id: 7,  idxId: 'ov-sundamage-idx',        opId: 'ov-sundamage-op',        colorType: 0, colorEl: null             },
    { id: 8,  idxId: 'ov-lipstick-idx',         opId: 'ov-lipstick-op',         colorType: 2, colorEl: 'lipstick-colors'},
    { id: 9,  idxId: 'ov-freckles-idx',         opId: 'ov-freckles-op',         colorType: 0, colorEl: null             },
    { id: 10, idxId: 'ov-chesthair-idx',        opId: 'ov-chesthair-op',        colorType: 1, colorEl: 'chesthair-colors'},
    { id: 11, idxId: 'ov-bodyblemishes-idx',    opId: 'ov-bodyblemishes-op',    colorType: 0, colorEl: null             },
    { id: 12, idxId: 'ov-addbodyblemishes-idx', opId: 'ov-addbodyblemishes-op', colorType: 0, colorEl: null             },
];

// ─── Make-Up Farbpalette (colorType 2) ───────────────────────────────────────
// Quelle: RAGE-MP Wiki „Makeup Colors" – exakte RGB-Werte aus den Spieldaten.
// 64 Einträge (Index 0–63), identisch mit GTA V _GET_MAKEUP_RGB_COLOR.
const MAKEUP_COLORS = [
    '#992532', // 0  Dunkles Rot
    '#c8395d', // 1  Leuchtendes Pink-Rot
    '#bd516c', // 2  Pink-Rot
    '#b8637a', // 3  Altrosa
    '#a6526b', // 4  Dunkles Altrosa
    '#b1434c', // 5  Koralle-Rot
    '#7f3133', // 6  Dunkelrot
    '#a4645d', // 7  Rötliches Braun
    '#c18779', // 8  Salmon
    '#cba096', // 9  Helles Salmon
    '#c6918f', // 10 Zartes Pink
    '#ab6f63', // 11 Mittelbraun-Rot
    '#b06050', // 12 Koralle
    '#a84c33', // 13 Dunkle Koralle
    '#b47178', // 14 Mauve
    '#ca7f92', // 15 Helles Mauve
    '#ed9cbe', // 16 Helles Pink
    '#e775a4', // 17 Pink
    '#de3e81', // 18 Kräftiges Pink
    '#b34c6e', // 19 Dunkles Pink
    '#712739', // 20 Dunkles Weinrot
    '#4f1f2a', // 21 Sehr dunkles Weinrot
    '#aa222f', // 22 Mittleres Rot
    '#de2034', // 23 Leuchtendes Rot
    '#cf0813', // 24 Knallrot
    '#e55470', // 25 Rosa-Rot
    '#dc3fb5', // 26 Magenta
    '#c227b2', // 27 Dunkles Magenta
    '#a01ca9', // 28 Lila-Magenta
    '#6e1875', // 29 Dunkles Lila
    '#731465', // 30 Tiefes Lila
    '#56165c', // 31 Sehr dunkles Lila
    '#6d1a9d', // 32 Blau-Lila
    '#1b3771', // 33 Dunkelblau
    '#1d4ea7', // 34 Königsblau
    '#1e74bb', // 35 Blau
    '#21a3ce', // 36 Hellblau
    '#25c2d2', // 37 Türkis
    '#23cca5', // 38 Blau-Grün
    '#27c07d', // 39 Mintgrün
    '#1b9c32', // 40 Grün
    '#148604', // 41 Dunkelgrün
    '#70d041', // 42 Hellgrün
    '#c5ea34', // 43 Gelbgrün
    '#e1e32f', // 44 Grüngelb
    '#ffdd26', // 45 Gelb
    '#fac026', // 46 Dunkelgelb
    '#f78a27', // 47 Orange
    '#fe5910', // 48 Orange-Rot
    '#be6e19', // 49 Dunkelorange
    '#f7c97f', // 50 Hellgelb
    '#fbe5c0', // 51 Crème
    '#f5f5f5', // 52 Weiß
    '#b3b4b3', // 53 Hellgrau
    '#919191', // 54 Grau
    '#564e4e', // 55 Dunkelgrau
    '#180e0e', // 56 Fast Schwarz
    '#58969e', // 57 Stahlblau
    '#4d6f8c', // 58 Schieferblau
    '#1a2b55', // 59 Marineblau
    '#a07e6b', // 60 Hellbraun
    '#826355', // 61 Mittelbraun
    '#6d5346', // 62 Dunkelbraun
    '#3e2d27', // 63 Sehr dunkles Braun
];

// ─── Ressourcen-Name ──────────────────────────────────────────────────────────
const RESOURCE_NAME = 'austriawien_skinmenu';

// ─── Zustand ──────────────────────────────────────────────────────────────────
const state = {
    open:            false,
    dirty:           false,   // true wenn Änderungen noch nicht gespeichert
    skin:            { components: {}, props: {}, face: {} },
    maxValues:       {},
    slotDefs:        [],
    selectedSlot:    null,
    selectedCat:     null,
    hairColor1:      0,
    hairColor2:      0,
    eyeColor:        0,
    eyebrowColor:    0,
    gender:          'mp_m_freemode_01',
    imageBasePath:   'img',
    imageFormats:    ['png'],
    // Overlay-Werte (keyed by overlay id) – wird beim openMenu gesetzt
    overlayValues:   {},
    faceData: {
        shapeFirst: 0, shapeSecond: 0, shapeMix: 0.5,
        skinFirst: 0,  skinSecond: 0,  skinMix:  0.5,
        features:  new Array(20).fill(0),
        overlays:  []
    }
};

// ─── Vorschau-Bild Hilfsfunktionen ───────────────────────────────────────────
/**
 * Gibt den Pfad zum lokalen Vorschaubild zurück.
 * Ordner: html/img/{slotId}/{drawableId}.{format}
 */
function imagePath(slotId, drawableId, format) {
    return `${state.imageBasePath}/${slotId}/${drawableId}.${format}`;
}

/**
 * Lädt das beste verfügbare Bild für eine Slot+Drawable Kombination.
 * Gibt ein <img>-Element zurück – bei Fehler wird es ausgeblendet.
 */
function createPreviewImage(slotId, drawableId, fallbackIcon) {
    const formats = state.imageFormats.slice().map(f => imagePath(slotId, drawableId, f));
    const allPaths = [...formats];

    const img = document.createElement('img');
    img.className = 'item-card-img';
    img.alt = '';

    function tryNext() {
        if (!allPaths.length) {
            img.style.display = 'none';
            const parent = img.parentElement;
            if (parent) {
                const icon = parent.querySelector('.item-card-icon');
                if (icon) icon.style.display = 'flex';
            }
            return;
        }
        img.src = allPaths.shift();
    }

    img.addEventListener('error', tryNext, { once: false });
    img.addEventListener('load', () => {
        img.removeEventListener('error', tryNext);
        const parent = img.parentElement;
        if (parent) {
            const icon = parent.querySelector('.item-card-icon');
            if (icon) icon.style.display = 'none';
        }
    }, { once: true });

    tryNext();
    return img;
}


// ─── NUI-Callback ─────────────────────────────────────────────────────────────
async function nuiCallback(event, data = {}) {
    try {
        const resp = await fetch(`https://${RESOURCE_NAME}/${event}`, {
            method:  'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body:    JSON.stringify(data)
        });
        return await resp.json();
    } catch (_) {
        return {};
    }
}

// ─── Hilfsfunktionen ──────────────────────────────────────────────────────────
function slotById(id) {
    return state.slotDefs.find(s => s.id === id);
}

function currentDrawable(id) {
    const slot = slotById(id);
    if (!slot) return 0;
    if (slot.type === 'component') return (state.skin.components[id] || {}).drawable ?? 0;
    return (state.skin.props[id] || {}).drawable ?? -1;
}

function currentTexture(id) {
    const slot = slotById(id);
    if (!slot) return 0;
    if (slot.type === 'component') return (state.skin.components[id] || {}).texture ?? 0;
    return (state.skin.props[id] || {}).texture ?? 0;
}

function setDrawable(id, val) {
    const slot = slotById(id);
    if (!slot) return;
    if (slot.type === 'component') {
        if (!state.skin.components[id]) state.skin.components[id] = { drawable: 0, texture: 0 };
        state.skin.components[id].drawable = val;
    } else {
        if (!state.skin.props[id]) state.skin.props[id] = { drawable: -1, texture: 0 };
        state.skin.props[id].drawable = val;
    }
}

function setTexture(id, val) {
    const slot = slotById(id);
    if (!slot) return;
    if (slot.type === 'component') {
        if (!state.skin.components[id]) state.skin.components[id] = { drawable: 0, texture: 0 };
        state.skin.components[id].texture = val;
    } else {
        if (!state.skin.props[id]) state.skin.props[id] = { drawable: -1, texture: 0 };
        state.skin.props[id].texture = val;
    }
}

function isProp(id) {
    const s = slotById(id);
    return s && s.type === 'prop';
}

// Farbe für Item-Karte (deterministisch aus ID)
function cardColor(catId, drawableId) {
    let hash = 0;
    for (let i = 0; i < catId.length; i++) hash = (hash * 31 + catId.charCodeAt(i)) & 0xffff;
    const hue = (hash + drawableId * 23) % 360;
    return `hsl(${hue}, 50%, 35%)`;
}

// ─── Slot-Anzeige aktualisieren ───────────────────────────────────────────────
function refreshSlotDisplay(id) {
    const el = document.getElementById(`val-${id}`);
    if (!el) return;
    const draw = currentDrawable(id);
    el.textContent = (isProp(id) && draw === -1) ? '–' : draw;

    const slot = document.getElementById(`eqslot-${id}`);
    if (slot) {
        slot.classList.toggle('equipped', !(isProp(id) && draw === -1));
    }
}

function refreshAllSlots() {
    state.slotDefs.forEach(s => refreshSlotDisplay(s.id));
}

// ─── Textur-Bar ───────────────────────────────────────────────────────────────
function updateTextureBar() {
    const id = state.selectedCat;
    if (!id || id === 'face') {
        document.getElementById('tex-value').textContent = '–';
        document.getElementById('tex-max').textContent   = '';
        document.getElementById('btn-tex-prev').disabled = true;
        document.getElementById('btn-tex-next').disabled = true;
        return;
    }
    const tex  = currentTexture(id);
    const maxT = (state.maxValues[id] || {}).maxTexture ?? 0;
    document.getElementById('tex-value').textContent = tex;
    document.getElementById('tex-max').textContent   = `/ ${maxT}`;
    document.getElementById('btn-tex-prev').disabled = tex <= 0;
    document.getElementById('btn-tex-next').disabled = tex >= maxT;
}

// ─── Items-Grid befüllen ──────────────────────────────────────────────────────
function buildItemsGrid(catId) {
    const grid   = document.getElementById('items-grid');
    const slot   = slotById(catId);
    if (!slot) return;

    const maxDraw = (state.maxValues[catId] || {}).maxDrawable ?? 0;
    const curDraw = currentDrawable(catId);

    grid.innerHTML = '';

    // Für Props: Extra-Karte "Nichts anlegen" (drawable = -1)
    if (slot.type === 'prop') {
        const none = document.createElement('div');
        none.className  = 'item-card' + (curDraw === -1 ? ' active' : '');
        none.dataset.id = catId;
        none.dataset.drawable = -1;
        none.innerHTML  = `<div class="item-card-icon" style="display:flex">✕</div>
                           <div class="item-card-id">–</div>
                           <div class="item-card-label">Nichts</div>`;
        attachCardEvents(none);
        grid.appendChild(none);
    }

    for (let d = 0; d <= maxDraw; d++) {
        const card = document.createElement('div');
        card.className  = 'item-card' + (d === curDraw ? ' active' : '');
        card.dataset.id = catId;
        card.dataset.drawable = d;

        // Platzhalter-Icon (wird ausgeblendet sobald ein Bild geladen wurde)
        const iconEl = document.createElement('div');
        iconEl.className   = 'item-card-icon';
        iconEl.style.display = 'flex';
        iconEl.textContent = slot.icon;

        const idEl = document.createElement('div');
        idEl.className   = 'item-card-id';
        idEl.textContent = d;

        const labelEl = document.createElement('div');
        labelEl.className   = 'item-card-label';
        labelEl.textContent = slot.label;

        const colorBar = document.createElement('div');
        colorBar.className = 'item-card-color';
        colorBar.style.background = cardColor(catId, d);

        // Vorschaubild (aus html/img/{slotId}/{d}.png o.ä.)
        const imgEl = createPreviewImage(catId, d, slot.icon);

        card.appendChild(imgEl);
        card.appendChild(iconEl);
        card.appendChild(idEl);
        card.appendChild(labelEl);
        card.appendChild(colorBar);

        attachCardEvents(card);
        grid.appendChild(card);
    }
}

// ─── Karten-Events (Klick) ────────────────────────────────────────────────────
function attachCardEvents(card) {
    card.addEventListener('click', () => applyDrawable(card.dataset.id, parseInt(card.dataset.drawable)));
}

// ─── Kleidung anwenden ────────────────────────────────────────────────────────
async function applyDrawable(slotId, drawableId) {
    const tex = (drawableId === -1) ? 0 : currentTexture(slotId);
    setDrawable(slotId, drawableId);
    markDirty();

    const result = await nuiCallback('updateSlot', {
        id: slotId, drawable: drawableId, texture: tex
    });

    // Maximale Texturen für dieses Drawable vom Client holen
    const maxTex = result.maxTexture ?? 0;
    if (!state.maxValues[slotId]) state.maxValues[slotId] = {};
    state.maxValues[slotId].maxTexture = maxTex;

    // Texture auf 0 resetzen wenn nötig
    if (currentTexture(slotId) > maxTex) {
        setTexture(slotId, 0);
    }

    refreshSlotDisplay(slotId);
    updateTextureBar();

    // Grid-Karten aktiven Zustand neu setzen
    document.querySelectorAll(`#items-grid .item-card[data-id="${slotId}"]`).forEach(c => {
        c.classList.toggle('active', parseInt(c.dataset.drawable) === drawableId);
    });
}

async function applyTexture(slotId, texId) {
    const draw = currentDrawable(slotId);
    setTexture(slotId, texId);
    markDirty();

    await nuiCallback('updateSlot', { id: slotId, drawable: draw, texture: texId });
    refreshSlotDisplay(slotId);
    updateTextureBar();
}

// ─── Kategorie wechseln ───────────────────────────────────────────────────────
function selectCategory(catId) {
    state.selectedCat = catId;

    // Tab-Buttons updaten
    document.querySelectorAll('.cat-btn').forEach(b => {
        b.classList.toggle('active', b.dataset.cat === catId);
    });

    // Equip-Slots updaten (aktiv-State)
    document.querySelectorAll('.equip-slot').forEach(s => {
        s.classList.toggle('active', s.dataset.slot === catId);
    });

    // Kamera-Fokus: Zone an Lua melden
    const slot = state.slotDefs.find(s => s.id === catId);
    const zone = slot ? slot.zone : (catId === 'face' ? 'head' : 'torso');
    nuiCallback('focusZone', { zone });

    if (catId === 'face') {
        document.getElementById('view-items').classList.remove('active');
        document.getElementById('view-face').classList.add('active');
    } else {
        document.getElementById('view-face').classList.remove('active');
        document.getElementById('view-items').classList.add('active');
        buildItemsGrid(catId);
        updateTextureBar();
    }
}

// ─── Kategorien-Navigation aufbauen ──────────────────────────────────────────
function buildCategoryNav() {
    const nav = document.getElementById('category-nav');
    nav.innerHTML = '';

    // Normale Slot-Kategorien
    state.slotDefs.forEach(s => {
        const btn = document.createElement('button');
        btn.className    = 'cat-btn';
        btn.dataset.cat  = s.id;
        btn.innerHTML    = `${s.icon} ${s.label}`;
        btn.addEventListener('click', () => selectCategory(s.id));
        nav.appendChild(btn);
    });

    // Gesicht-Tab am Ende
    const faceBtn = document.createElement('button');
    faceBtn.className   = 'cat-btn';
    faceBtn.dataset.cat = 'face';
    faceBtn.innerHTML   = '😊 Gesicht';
    faceBtn.addEventListener('click', () => selectCategory('face'));
    nav.appendChild(faceBtn);
}

// ─── Klick auf Equip-Slots ────────────────────────────────────────────
function setupEquipSlotDropTargets() {
    document.querySelectorAll('.equip-slot').forEach(slot => {
        slot.addEventListener('click', () => selectCategory(slot.dataset.slot));
    });
}

// ─── Textur-Buttons ───────────────────────────────────────────────────────────
document.getElementById('btn-tex-prev').addEventListener('click', () => {
    if (!state.selectedCat || state.selectedCat === 'face') return;
    const cur = currentTexture(state.selectedCat);
    if (cur > 0) applyTexture(state.selectedCat, cur - 1);
});
document.getElementById('btn-tex-next').addEventListener('click', () => {
    if (!state.selectedCat || state.selectedCat === 'face') return;
    const cur = currentTexture(state.selectedCat);
    const max = (state.maxValues[state.selectedCat] || {}).maxTexture ?? 0;
    if (cur < max) applyTexture(state.selectedCat, cur + 1);
});

// ─── Kamera-Buttons ───────────────────────────────────────────────────────────
document.getElementById('btn-rotate-left').addEventListener('click',   () => nuiCallback('rotateCamera',    { direction: 'left'  }));
document.getElementById('btn-rotate-right').addEventListener('click',  () => nuiCallback('rotateCamera',    { direction: 'right' }));
document.getElementById('btn-cam-up').addEventListener('click',        () => nuiCallback('camHeightChange', { direction: 'up'    }));
document.getElementById('btn-cam-down').addEventListener('click',      () => nuiCallback('camHeightChange', { direction: 'down'  }));
document.getElementById('btn-cam-zoom-in').addEventListener('click',   () => nuiCallback('zoomCamera',      { direction: 'in'   }));
document.getElementById('btn-cam-zoom-out').addEventListener('click',  () => nuiCallback('zoomCamera',      { direction: 'out'  }));

// ─── Ungespeicherte-Änderungen Tracking ─────────────────────────────────────
function markDirty() { state.dirty = true; }

// Zeigt Bestätigungsdialog wenn Änderungen nicht gespeichert wurden.
// Wenn kein dirty: direkt schließen.
function confirmClose() {
    if (!state.dirty) {
        nuiCallback('cancel', {});
        closeMenu();
        return;
    }
    document.getElementById('unsaved-backdrop').classList.remove('hidden');
}

document.getElementById('btn-unsaved-stay').addEventListener('click', () => {
    document.getElementById('unsaved-backdrop').classList.add('hidden');
});
document.getElementById('btn-unsaved-leave').addEventListener('click', () => {
    document.getElementById('unsaved-backdrop').classList.add('hidden');
    nuiCallback('cancel', {});
    closeMenu();
});

// ─── Speichern / Abbrechen ────────────────────────────────────────────────────
document.getElementById('btn-save').addEventListener('click', () => {
    // Overlays aus overlayValues zusammenbauen
    const overlaysArr = OVERLAYS.map(ov => {
        const v = state.overlayValues[ov.id] || { index: 0, opacity: (ov.id === 2 ? 1.0 : 0.0), color1: 0, color2: 0 };
        const entry = { id: ov.id, index: v.index, opacity: v.opacity };
        if (ov.colorType > 0) {
            entry.colorType = ov.colorType;
            entry.color1    = v.color1 || 0;
            entry.color2    = v.color2 || 0;
        }
        return entry;
    });

    const skinToSave = {
        components: state.skin.components,
        props:      state.skin.props,
        model:      state.gender,
        face: {
            shapeFirst:   state.faceData.shapeFirst,
            shapeSecond:  state.faceData.shapeSecond,
            shapeMix:     state.faceData.shapeMix,
            skinFirst:    state.faceData.skinFirst,
            skinSecond:   state.faceData.skinSecond,
            skinMix:      state.faceData.skinMix,
            features:     state.faceData.features,
            hairColor1:   state.hairColor1,
            hairColor2:   state.hairColor2,
            eyeColor:     state.eyeColor,
            eyebrowColor: state.eyebrowColor,
            overlays:     overlaysArr
        }
    };
    nuiCallback('save', { skin: skinToSave });
    state.dirty = false;
    closeMenu();
});

document.getElementById('btn-cancel').addEventListener('click', () => confirmClose());
document.getElementById('btn-close').addEventListener('click',  () => confirmClose());

// ESC schließt ebenfalls
document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && state.open) {
        // Wenn das Modal gerade offen ist: Modal schließen, nicht das Menü
        const backdrop = document.getElementById('unsaved-backdrop');
        if (!backdrop.classList.contains('hidden')) {
            backdrop.classList.add('hidden');
            return;
        }
        confirmClose();
    }
});

// ─── Menü öffnen / schließen ─────────────────────────────────────────────────
function openMenu(data) {
    state.open          = true;
    state.dirty         = false;  // Frischer Start – noch keine Änderungen
    state.skin          = data.skin          || { components: {}, props: {}, face: {} };
    state.maxValues     = data.maxValues     || {};
    state.slotDefs      = data.slotDefs      || [];
    state.imageBasePath = data.imageBasePath || 'img';
    state.imageFormats  = data.imageFormats  || ['png'];

    if (state.skin.face) {
        const f = state.skin.face;
        state.hairColor1   = f.hairColor1   ?? 0;
        state.hairColor2   = f.hairColor2   ?? 0;
        state.eyeColor     = f.eyeColor     ?? 0;
        state.eyebrowColor = f.eyebrowColor ?? 0;
        state.faceData     = {
            shapeFirst:  f.shapeFirst  ?? 0,
            shapeSecond: f.shapeSecond ?? 0,
            shapeMix:    f.shapeMix    ?? 0.5,
            skinFirst:   f.skinFirst   ?? 0,
            skinSecond:  f.skinSecond  ?? 0,
            skinMix:     f.skinMix     ?? 0.5,
            features:    f.features    ?? new Array(20).fill(0),
            overlays:    f.overlays    ?? []
        };
        // Overlay-Werte aus dem geladenen Skin initialisieren
        initOverlayValues(f.overlays ?? []);
    } else {
        initOverlayValues([]);
    }

    state.gender = (state.skin && state.skin.model) ? state.skin.model : 'mp_m_freemode_01';

    // Charakterinfo anzeigen
    const charName   = data.charName   || '\u2014';
    const charGender = data.charGender || (state.gender === 'mp_f_freemode_01' ? 'Weiblich' : 'M\u00e4nnlich');
    const nameEl   = document.getElementById('char-info-name');
    const genderEl = document.getElementById('char-info-gender');
    if (nameEl)   nameEl.textContent   = charName;
    if (genderEl) genderEl.textContent = charGender;

    buildCategoryNav();
    refreshAllSlots();
    setupEquipSlotDropTargets();
    buildGenderButtons();
    buildHairColorPalettes();
    buildEyeColorPalette();
    buildAllOverlays();
    buildFaceFeatureSliders();
    syncFaceSliders();

    // Erste Kategorie vorauswählen
    if (state.slotDefs.length > 0) selectCategory(state.slotDefs[0].id);

    document.getElementById('app').classList.remove('hidden');
}

function closeMenu() {
    state.open = false;
    document.getElementById('app').classList.add('hidden');
}

// ─── Gesichts-Slider ─────────────────────────────────────────────────────────
function syncFaceSliders() {
    const fd = state.faceData;
    setSlider('face-shapeFirst',  fd.shapeFirst,  v => v,           v => String(v));
    setSlider('face-shapeSecond', fd.shapeSecond, v => v,           v => String(v));
    setSlider('face-shapeMix',    fd.shapeMix,    v => Math.round(v * 100), v => (v / 100).toFixed(2));
    setSlider('face-skinFirst',   fd.skinFirst,   v => v,           v => String(v));
    setSlider('face-skinSecond',  fd.skinSecond,  v => v,           v => String(v));
    setSlider('face-skinMix',     fd.skinMix,     v => Math.round(v * 100), v => (v / 100).toFixed(2));
}

function setSlider(id, value, toSlider, toLabel) {
    const el  = document.getElementById(id);
    const lbl = document.getElementById(`${id}-val`);
    if (!el || !lbl) return;
    el.value   = toSlider(value);
    lbl.textContent = toLabel(toSlider(value));
}

// Head-Blend-Slider Events
['face-shapeFirst','face-shapeSecond','face-skinFirst','face-skinSecond'].forEach(id => {
    const el = document.getElementById(id);
    if (!el) return;
    el.addEventListener('input', () => {
        const key = id.replace('face-', '');
        const v   = parseInt(el.value);
        state.faceData[key] = v;
        document.getElementById(`${id}-val`).textContent = v;
        sendHeadBlend();
    });
});

['face-shapeMix','face-skinMix'].forEach(id => {
    const el = document.getElementById(id);
    if (!el) return;
    el.addEventListener('input', () => {
        const key = id.replace('face-', '');
        const v   = parseInt(el.value) / 100;
        state.faceData[key] = v;
        document.getElementById(`${id}-val`).textContent = v.toFixed(2);
        sendHeadBlend();
    });
});

function sendHeadBlend() {
    markDirty();
    nuiCallback('setHeadBlend', state.faceData);
}

// ─── Gesichtszug-Slider aufbauen ──────────────────────────────────────────────
function buildFaceFeatureSliders() {
    const container = document.getElementById('face-features-list');
    container.innerHTML = '';
    const features = state.faceData.features || [];
    FACE_FEATURE_NAMES.forEach((name, i) => {
        const initVal = features[i] ?? 0;
        const row = document.createElement('div');
        row.className = 'face-row';
        row.innerHTML = `
            <label>${name}</label>
            <input type="range" min="-100" max="100" value="${Math.round(initVal * 100)}"
                   class="face-slider" id="ff-${i}">
            <span class="face-slider-val" id="ff-${i}-val">${initVal.toFixed(2)}</span>`;
        container.appendChild(row);

        const el = row.querySelector(`#ff-${i}`);
        el.addEventListener('input', () => {
            const v = parseInt(el.value) / 100;
            state.faceData.features[i] = v;
            document.getElementById(`ff-${i}-val`).textContent = v.toFixed(2);
            markDirty();
            nuiCallback('setFaceFeature', { featureId: i, value: v });
        });
    });
}

// ─── Overlay-System ───────────────────────────────────────────────────────────
// Initialisiert state.overlayValues aus dem geladenen Skin
function initOverlayValues(overlaysArray) {
    // Defaults für alle Overlays setzen
    OVERLAYS.forEach(ov => {
        state.overlayValues[ov.id] = {
            index:   0,
            opacity: (ov.id === 2) ? 1.0 : 0.0,  // Augenbrauen standardmäßig sichtbar
            color1:  0,
            color2:  0
        };
    });
    // Werte aus dem geladenen Skin überschreiben
    (overlaysArray || []).forEach(ov => {
        if (state.overlayValues[ov.id] !== undefined) {
            state.overlayValues[ov.id] = {
                index:   ov.index   ?? 0,
                opacity: ov.opacity ?? (ov.id === 2 ? 1.0 : 0.0),
                color1:  ov.color1  ?? 0,
                color2:  ov.color2  ?? 0
            };
        }
    });
    // Augenbrauenfarbe mit eyebrowColor synchronisieren
    if (state.overlayValues[2]) {
        state.overlayValues[2].color1 = state.eyebrowColor ?? 0;
    }
}

// Sendet ein Overlay an die Lua-Seite
function sendOverlay(ovDef) {
    markDirty();
    const v = state.overlayValues[ovDef.id] || { index: 0, opacity: 0, color1: 0, color2: 0 };
    const data = {
        overlayId: ovDef.id,
        index:     v.index,
        opacity:   v.opacity
    };
    if (ovDef.colorType > 0) {
        data.colorType = ovDef.colorType;
        data.color1    = v.color1;
        data.color2    = v.color2;
    }
    nuiCallback('setHeadOverlay', data);
}

// Baut eine Farbpalette auf (Haar- oder Make-Up-Farben)
function buildOverlayColorPalette(containerId, ovDef) {
    const el = document.getElementById(containerId);
    if (!el) return;
    el.innerHTML = '';
    const palette = (ovDef.colorType === 2) ? MAKEUP_COLORS : HAIR_COLORS;
    const curColor = (state.overlayValues[ovDef.id] || {}).color1 ?? 0;
    palette.forEach((hex, i) => {
        const chip = document.createElement('div');
        chip.className = 'hair-color-chip' + (i === curColor ? ' active' : '');
        chip.style.background = hex;
        chip.title = `Farbe ${i}`;
        chip.addEventListener('click', () => {
            if (!state.overlayValues[ovDef.id]) state.overlayValues[ovDef.id] = { index: 0, opacity: 0, color1: 0, color2: 0 };
            state.overlayValues[ovDef.id].color1 = i;
            // Augenbrauenfarbe auch in state.eyebrowColor spiegeln
            if (ovDef.id === 2) state.eyebrowColor = i;
            el.querySelectorAll('.hair-color-chip').forEach((c, j) => c.classList.toggle('active', j === i));
            sendOverlay(ovDef);
        });
        el.appendChild(chip);
    });
}

// Richtet die Slider für ein Overlay ein (nur einmal beim Seitenload)
function setupOverlayListeners(ovDef) {
    const elIdx = document.getElementById(ovDef.idxId);
    const elOp  = document.getElementById(ovDef.opId);
    if (!elIdx || !elOp) return;

    const idxValEl = document.getElementById(`${ovDef.idxId}-val`);
    const opValEl  = document.getElementById(`${ovDef.opId}-val`);

    elIdx.addEventListener('input', () => {
        const idx = parseInt(elIdx.value);
        if (!state.overlayValues[ovDef.id]) state.overlayValues[ovDef.id] = { index: 0, opacity: 0, color1: 0, color2: 0 };
        state.overlayValues[ovDef.id].index = idx;
        if (idxValEl) idxValEl.textContent = idx;
        sendOverlay(ovDef);
    });
    elOp.addEventListener('input', () => {
        const op = parseInt(elOp.value) / 100;
        if (!state.overlayValues[ovDef.id]) state.overlayValues[ovDef.id] = { index: 0, opacity: 0, color1: 0, color2: 0 };
        state.overlayValues[ovDef.id].opacity = op;
        if (opValEl) opValEl.textContent = op.toFixed(1);
        sendOverlay(ovDef);
    });
}

// Synchronisiert den Slider-Wert aus state.overlayValues (bei jedem Menüöffnen)
function syncOverlaySlider(ovDef) {
    const elIdx = document.getElementById(ovDef.idxId);
    const elOp  = document.getElementById(ovDef.opId);
    if (!elIdx || !elOp) return;

    const v = state.overlayValues[ovDef.id] || { index: 0, opacity: (ovDef.id === 2 ? 1.0 : 0.0) };
    elIdx.value = v.index;
    elOp.value  = Math.round(v.opacity * 100);
    const idxValEl = document.getElementById(`${ovDef.idxId}-val`);
    const opValEl  = document.getElementById(`${ovDef.opId}-val`);
    if (idxValEl) idxValEl.textContent = v.index;
    if (opValEl)  opValEl.textContent  = v.opacity.toFixed(1);
}

// Hauptfunktion: Synchronisiert ALLE Overlay-Slider + baut Farbpaletten neu auf
function buildAllOverlays() {
    OVERLAYS.forEach(ovDef => {
        syncOverlaySlider(ovDef);
        if (ovDef.colorType > 0 && ovDef.colorEl) {
            buildOverlayColorPalette(ovDef.colorEl, ovDef);
        }
    });
}

// Einmalig beim Laden: Event-Listener für alle Overlay-Slider registrieren
OVERLAYS.forEach(ovDef => setupOverlayListeners(ovDef));

// ─── Geschlecht-Buttons ──────────────────────────────────────────────────────
function buildGenderButtons() {
    const male   = document.getElementById('btn-gender-male');
    const female = document.getElementById('btn-gender-female');
    if (!male || !female) return;
    male.classList.toggle('active',   state.gender === 'mp_m_freemode_01');
    female.classList.toggle('active', state.gender === 'mp_f_freemode_01');
}

async function applyGender(model) {
    if (model === state.gender) return;
    const male   = document.getElementById('btn-gender-male');
    const female = document.getElementById('btn-gender-female');
    if (male)   male.disabled   = true;
    if (female) female.disabled = true;

    const result = await nuiCallback('setGender', { model });

    if (male)   male.disabled   = false;
    if (female) female.disabled = false;

    if (result && result.ok) {
        markDirty();
        state.gender = model;
        buildGenderButtons();
        // Geschlechtsanzeige in Charakterinfo aktualisieren
        const genderEl = document.getElementById('char-info-gender');
        if (genderEl) genderEl.textContent = (model === 'mp_f_freemode_01') ? 'Weiblich' : 'Männlich';
        // Kleidungs-Werte zurücksetzen (neues Modell hat andere Varianten)
        state.skin.components = {};
        state.skin.props      = {};
        if (result.maxValues) state.maxValues = result.maxValues;
        refreshAllSlots();
        if (state.selectedCat && state.selectedCat !== 'face') {
            buildItemsGrid(state.selectedCat);
        }
        updateTextureBar();
    } else if (!result || !result.ok) {
        // Bei Fehler: Button-Zustand zurücksetzen
        buildGenderButtons();
    }
}

// ─── Haarfarb-Paletten ────────────────────────────────────────────────────────
function buildHairColorPalettes() {
    buildColorPalette('hair-colors-primary',   state.hairColor1, i => {
        state.hairColor1 = i;
        markDirty();
        nuiCallback('setHairColor', { color1: state.hairColor1, color2: state.hairColor2 });
        refreshPaletteSelection('hair-colors-primary', i);
    });
    buildColorPalette('hair-colors-secondary', state.hairColor2, i => {
        state.hairColor2 = i;
        markDirty();
        nuiCallback('setHairColor', { color1: state.hairColor1, color2: state.hairColor2 });
        refreshPaletteSelection('hair-colors-secondary', i);
    });
}

function buildColorPalette(containerId, activeIndex, onSelect) {
    const el = document.getElementById(containerId);
    if (!el) return;
    el.innerHTML = '';
    HAIR_COLORS.forEach((hex, i) => {
        const chip = document.createElement('div');
        chip.className  = 'hair-color-chip' + (i === activeIndex ? ' active' : '');
        chip.style.background = hex;
        chip.title      = `Farbe ${i}`;
        chip.addEventListener('click', () => onSelect(i));
        el.appendChild(chip);
    });
}

function refreshPaletteSelection(containerId, activeIndex) {
    const el = document.getElementById(containerId);
    if (!el) return;
    el.querySelectorAll('.hair-color-chip').forEach((c, i) => {
        c.classList.toggle('active', i === activeIndex);
    });
}

// ─── Augenfarb-Palette ────────────────────────────────────────────────────────
function buildEyeColorPalette() {
    const el = document.getElementById('eye-colors');
    if (!el) return;
    el.innerHTML = '';
    EYE_COLORS.forEach((hex, i) => {
        const chip = document.createElement('div');
        chip.className = 'hair-color-chip' + (i === state.eyeColor ? ' active' : '');
        chip.style.background = hex;
        chip.title = `Augenfarbe ${i}`;
        chip.addEventListener('click', () => {
            state.eyeColor = i;
            el.querySelectorAll('.hair-color-chip').forEach((c, j) => {
                c.classList.toggle('active', j === i);
            });
            markDirty();
            nuiCallback('setEyeColor', { index: i });
        });
        el.appendChild(chip);
    });
}

// ─── Geschlecht-Button Events ─────────────────────────────────────────────────
document.getElementById('btn-gender-male').addEventListener('click',   () => applyGender('mp_m_freemode_01'));
document.getElementById('btn-gender-female').addEventListener('click', () => applyGender('mp_f_freemode_01'));

// ─── Nachrichten vom Client empfangen ────────────────────────────────────────
window.addEventListener('message', e => {
    const data = e.data;
    if (!data || !data.type) return;

    switch (data.type) {
        case 'openMenu':
            openMenu(data);
            break;
    }
});
