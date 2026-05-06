/* ═══════════════════════════════════════════════════════════════════════════
   AustriaWien Garderobe – app.js
   ══════════════════════════════════════════════════════════════════════════ */

'use strict';

// ─── GTA V Haarfarben-Palette (64 Farben) ────────────────────────────────────
const HAIR_COLORS = [
    '#1a1a1a','#2c2c2c','#3d2b1f','#5c3d2e','#7a5c40','#a07040',
    '#c8a060','#e8c88a','#f0e0b0','#f8f0d0','#d4a030','#c89020',
    '#b07020','#885010','#603010','#401808','#800000','#a01010',
    '#c02020','#e04040','#ff6060','#ff8080','#ffb0b0','#ffe0e0',
    '#800080','#a020a0','#c040c0','#e060e0','#ff80ff','#ffb0ff',
    '#000080','#002080','#004080','#0060a0','#0080c0','#00a0e0',
    '#00c0ff','#60d0ff','#b0e8ff','#e0f4ff','#008000','#009020',
    '#00a840','#40c060','#80d880','#b0ecb0','#e8f8e8','#ffffff',
    '#f0f0f0','#d0d0d0','#a8a8a8','#808080','#585858','#383838',
    '#282828','#181818','#101010','#080808','#c0a880','#a08060',
    '#806040','#604020','#402010','#200c04'
];

// ─── Gesichtszug-Namen ────────────────────────────────────────────────────────
const FACE_FEATURE_NAMES = [
    'Nasenbreite','Nasenspitze Höhe','Nasenspitze Länge','Nasenbein Höhe',
    'Nasenspitze Senkung','Nasenknick','Augenbrauenhöhe','Augenbrauenneigung',
    'Wangenbein Höhe','Wangenbein Breite','Wangenbreite','Augenöffnung',
    'Lippendicke','Kieferbreite','Kieferlänge','Kinnhöhe',
    'Kinnlänge','Kinnbreite','Kinngrübchen','Halsdicke'
];

// ─── Ressourcen-Name ──────────────────────────────────────────────────────────
const RESOURCE_NAME = 'austriawien_skinmenu';

// ─── Zustand ──────────────────────────────────────────────────────────────────
const state = {
    open:            false,
    skin:            { components: {}, props: {}, face: {} },
    maxValues:       {},
    slotDefs:        [],
    selectedSlot:    null,   // id des aktiven Slots
    selectedCat:     null,   // id der aktiven Kategorie (= slot-id)
    hairColor1:      0,
    hairColor2:      0,
    imageBasePath:   'img',
    imageFormats:    ['png'],
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

// ─── Maus-basiertes Drag System (zuverlässig in FiveM CEF) ─────────────────────
const _drag = {
    active:   false,
    moved:    false,
    slotId:   null,
    drawable: null,
    startX:   0,
    startY:   0,
    srcCard:  null,
};

function _dragMove(e) {
    if (!_drag.active) return;
    if (!_drag.moved && (Math.abs(e.clientX - _drag.startX) > 4 || Math.abs(e.clientY - _drag.startY) > 4)) {
        _drag.moved = true;
    }
    if (_drag.moved) {
        const g = document.getElementById('drag-ghost');
        g.style.left = (e.clientX - 31) + 'px';
        g.style.top  = (e.clientY - 31) + 'px';
        // Drop-Target hervorheben
        const el = document.elementFromPoint(e.clientX, e.clientY);
        document.querySelectorAll('.equip-slot.drag-over, .body-zone.drag-over-zone').forEach(x =>
            x.classList.remove('drag-over', 'drag-over-zone')
        );
        if (el) {
            const slot = el.closest('.equip-slot');
            const zone = el.closest('.body-zone');
            if (slot) slot.classList.add('drag-over');
            else if (zone) zone.classList.add('drag-over-zone');
        }
    }
}

function _dragEnd(e) {
    document.removeEventListener('mousemove', _dragMove);
    document.removeEventListener('mouseup',   _dragEnd);

    const g = document.getElementById('drag-ghost');
    g.style.left = '-9999px';
    g.style.top  = '-9999px';

    document.querySelectorAll('.equip-slot.drag-over, .body-zone.drag-over-zone').forEach(x =>
        x.classList.remove('drag-over', 'drag-over-zone')
    );
    if (_drag.srcCard) _drag.srcCard.classList.remove('dragging');

    if (_drag.moved) {
        const el = document.elementFromPoint(e.clientX, e.clientY);
        if (el) {
            const slot = el.closest('.equip-slot');
            const zone = el.closest('.body-zone');
            if (slot) {
                const targetId = slot.dataset.slot;
                if (targetId === _drag.slotId) {
                    applyDrawable(targetId, _drag.drawable);
                } else {
                    slot.style.boxShadow = '0 0 10px rgba(231,76,60,.7)';
                    setTimeout(() => slot.style.boxShadow = '', 350);
                }
            } else if (zone) {
                const match = zone.querySelector(`.equip-slot[data-slot="${_drag.slotId}"]`);
                if (match) {
                    applyDrawable(_drag.slotId, _drag.drawable);
                } else {
                    zone.classList.add('reject');
                    setTimeout(() => zone.classList.remove('reject'), 400);
                }
            }
        }
    }

    _drag.active   = false;
    _drag.moved    = false;
    _drag.slotId   = null;
    _drag.drawable = null;
    _drag.srcCard  = null;
}

// ─── Karten-Events (Klick + Drag) ─────────────────────────────────────────────
function attachCardEvents(card) {
    // Klick → sofort anwenden (nur wenn nicht gezogen)
    card.addEventListener('click', () => {
        if (!_drag.moved) applyDrawable(card.dataset.id, parseInt(card.dataset.drawable));
    });

    // Drag per Maus starten
    card.addEventListener('mousedown', e => {
        if (e.button !== 0) return;
        _drag.active   = true;
        _drag.moved    = false;
        _drag.slotId   = card.dataset.id;
        _drag.drawable = parseInt(card.dataset.drawable);
        _drag.startX   = e.clientX;
        _drag.startY   = e.clientY;
        _drag.srcCard  = card;

        const g = document.getElementById('drag-ghost');
        g.textContent = slotById(card.dataset.id)?.icon ?? '?';
        g.style.left = '-9999px';
        g.style.top  = '-9999px';

        document.addEventListener('mousemove', _dragMove);
        document.addEventListener('mouseup',   _dragEnd);
    });
}

// ─── Kleidung anwenden ────────────────────────────────────────────────────────
async function applyDrawable(slotId, drawableId) {
    const tex = (drawableId === -1) ? 0 : currentTexture(slotId);
    setDrawable(slotId, drawableId);

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

// ─── Klick auf Equip-Slots (Drop wird durch _dragEnd behandelt) ──────────────
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
document.getElementById('btn-rotate-left').addEventListener('click',  () => nuiCallback('rotateCamera', { direction: 'left'  }));
document.getElementById('btn-rotate-right').addEventListener('click', () => nuiCallback('rotateCamera', { direction: 'right' }));

// ─── Speichern / Abbrechen ────────────────────────────────────────────────────
document.getElementById('btn-save').addEventListener('click', () => {
    const skinToSave = {
        components: state.skin.components,
        props:      state.skin.props,
        face: {
            ...state.faceData,
            hairColor1: state.hairColor1,
            hairColor2: state.hairColor2
        }
    };
    nuiCallback('save', { skin: skinToSave });
    closeMenu();
});

document.getElementById('btn-cancel').addEventListener('click', () => {
    nuiCallback('cancel', {});
    closeMenu();
});

document.getElementById('btn-close').addEventListener('click', () => {
    nuiCallback('cancel', {});
    closeMenu();
});

// ESC schließt ebenfalls
document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && state.open) {
        nuiCallback('cancel', {});
        closeMenu();
    }
});

// ─── Menü öffnen / schließen ─────────────────────────────────────────────────
function openMenu(data) {
    state.open          = true;
    state.skin          = data.skin          || { components: {}, props: {}, face: {} };
    state.maxValues     = data.maxValues     || {};
    state.slotDefs      = data.slotDefs      || [];
    state.imageBasePath = data.imageBasePath || 'img';
    state.imageFormats  = data.imageFormats  || ['png'];

    if (state.skin.face) {
        const f = state.skin.face;
        state.hairColor1 = f.hairColor1 ?? 0;
        state.hairColor2 = f.hairColor2 ?? 0;
        state.faceData   = {
            shapeFirst:  f.shapeFirst  ?? 0,
            shapeSecond: f.shapeSecond ?? 0,
            shapeMix:    f.shapeMix    ?? 0.5,
            skinFirst:   f.skinFirst   ?? 0,
            skinSecond:  f.skinSecond  ?? 0,
            skinMix:     f.skinMix     ?? 0.5,
            features:    f.features    ?? new Array(20).fill(0),
            overlays:    f.overlays    ?? []
        };
    }

    buildCategoryNav();
    refreshAllSlots();
    setupEquipSlotDropTargets();
    buildHairColorPalettes();
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
    nuiCallback('setHeadBlend', state.faceData);
}

// ─── Bart & Augenbrauen ───────────────────────────────────────────────────────
function setupOverlaySlider(idxId, opId, overlayId) {
    const elIdx = document.getElementById(idxId);
    const elOp  = document.getElementById(opId);
    if (!elIdx || !elOp) return;

    const send = () => {
        nuiCallback('setHeadOverlay', {
            overlayId,
            index:   parseInt(elIdx.value),
            opacity: parseInt(elOp.value) / 100
        });
    };

    elIdx.addEventListener('input', () => {
        document.getElementById(`${idxId}-val`).textContent = elIdx.value;
        send();
    });
    elOp.addEventListener('input', () => {
        document.getElementById(`${opId}-val`).textContent = (parseInt(elOp.value) / 100).toFixed(1);
        send();
    });
}

setupOverlaySlider('ov-eyebrow-idx', 'ov-eyebrow-op', 2);
setupOverlaySlider('ov-beard-idx',   'ov-beard-op',   1);

// ─── Gesichtszug-Slider aufbauen ──────────────────────────────────────────────
function buildFaceFeatureSliders() {
    const container = document.getElementById('face-features-list');
    container.innerHTML = '';
    FACE_FEATURE_NAMES.forEach((name, i) => {
        const row = document.createElement('div');
        row.className = 'face-row';
        row.innerHTML = `
            <label>${name}</label>
            <input type="range" min="-100" max="100" value="0"
                   class="face-slider" id="ff-${i}">
            <span class="face-slider-val" id="ff-${i}-val">0.00</span>`;
        container.appendChild(row);

        const el = row.querySelector(`#ff-${i}`);
        el.addEventListener('input', () => {
            const v = parseInt(el.value) / 100;
            state.faceData.features[i] = v;
            document.getElementById(`ff-${i}-val`).textContent = v.toFixed(2);
            nuiCallback('setFaceFeature', { featureId: i, value: v });
        });
    });
}

// ─── Haarfarb-Paletten ────────────────────────────────────────────────────────
function buildHairColorPalettes() {
    buildColorPalette('hair-colors-primary',   state.hairColor1, i => {
        state.hairColor1 = i;
        nuiCallback('setHairColor', { color1: state.hairColor1, color2: state.hairColor2 });
        refreshPaletteSelection('hair-colors-primary', i);
    });
    buildColorPalette('hair-colors-secondary', state.hairColor2, i => {
        state.hairColor2 = i;
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
