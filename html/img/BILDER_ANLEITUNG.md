# Vorschau-Bilder – Anleitung

## Ordnerstruktur

Lege Bilder in folgender Struktur ab:

```
html/img/
├── jacket/
│   ├── 0.png      ← Jacke Drawable 0
│   ├── 1.png
│   ├── 2.png
│   └── ...
├── legs/
│   ├── 0.png
│   └── ...
├── shoes/
│   ├── 0.png
│   └── ...
├── hat/
├── hair/
├── mask/
├── glasses/
├── ear/
├── undershirt/
├── arms/
├── armor/
├── accessories/
├── decal/
├── bag/
├── watch/
└── bracelet/
```

## Dateiname-Konvention

```
{slotId}/{drawableId}.{format}
```

**Beispiele:**
- `jacket/0.png`   → Jacke, Drawable 0
- `jacket/1.webp`  → Jacke, Drawable 1 (WebP)
- `hat/3.jpg`      → Hut, Drawable 3

## Unterstützte Formate

`png`, `jpg`, `webp` — Reihenfolge und Priorität in `config.lua` unter `Config.ImageFormats` einstellbar.

## Fehlt ein Bild?

Kein Problem. Das Menü zeigt dann automatisch das Emoji-Icon als Fallback.

## Empfohlene Bildgröße

**72 × 72 px** oder **128 × 128 px** (quadratisch, transparenter Hintergrund bei PNG)

## Bilder aus YMT/YDD-Packs extrahieren

1. **OpenIV** → Suche nach `mp_m_freemode_01` oder `mp_f_freemode_01` in den Update-Paketen
2. Kleidungs-Texturen liegen in `.ytd`-Dateien (z.B. `mp_m_freemode_01_p_hair_001_u.ytd`)
3. Exportiere als PNG und benenne nach obigem Schema um
4. Ablegen in den entsprechenden Ordner (z.B. `html/img/hair/0.png`)

Alternativ können Screenshots aus dem Spiel oder von Community-Ressourcen (z.B. FiveM Forums, GIMS Evo) verwendet werden.
