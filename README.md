# austriawien_skinmenu

Drag-&-Drop Skin-Menü für FiveM mit ESX-Framework.  
Zeigt den live GTA-Charakter in der Mitte während man Kleidung anpasst.

**Drop-in-Ersatz für `esx_skin`** – alle `esx_skin`-Events werden von dieser Resource abgefangen, `esx_skin` muss **nicht** laufen.

---

## Changelog

### 2026-05-06 – Kamera & Banner
- **Neu:** Kamera-Fokus per Zone – Kamera springt automatisch zu Kopf / Oberkörper / Hände / Beine / Schuhe wenn der entsprechende Slot ausgewählt wird
- **Neu:** `shoes`-Slot hat eigene Zone (`shoes`) mit noch tieferer Kameraposition als `legs`
- **Neu:** Startbanner in Schwarz/Weiß/Rot (Zeilen 1–3 + 7–8 Rot, Zeilen 4–6 Weiß)
- **Entfernt:** Versionscheck via HTTP (`PerformHttpRequest`) – Banner erscheint jetzt sofort beim `onResourceStart`
- **Fix:** `fxmanifest.lua` enthält keine `html/img/**/*.png`-Glob-Wildcards mehr (Warnungen entfernt)

### 2026-05-06 – esx_skin Kompatibilität & CSS
- **Neu:** Drop-in-Ersatz für `esx_skin` – alle esx_skin NetEvents (`esx_skin:openSaveableMenu`, `esx_skin:openMenu`, `esx_skin:playerRegistered`, …) werden abgefangen
- **Neu:** `ESX.RegisterServerCallback('esx_skin:getPlayerSkin')` und `RegisterNetEvent('esx_skin:save')` auf dem Server registriert
- **Neu:** Schwarz/Weiß/Rot-Theme (CSS-Variablen: `--gold: #e63030`, `--bg-deep: #0a0a0a`)
- **Neu:** Halbdurchsichtige Panels (`backdrop-filter: blur(8px)`) – Charakter im Hintergrund sichtbar
- **Neu:** ASCII-Banner beim Serverstart
- **Fix:** Kamera zeigt jetzt auf den Charakter (nicht mehr weg)

### 2026-05-06 – Overhaul
- **Bugfix:** Drag-&-Drop war komplett defekt wegen dupliziertem HTML in `index.html`
- **Neu:** Linkes Panel als Körperzonen-Avatar (KOPF / OBERKÖRPER / HÄNDE / UNTERKÖRPER / SCHUHE)
- **Neu:** Body-Zonen als großflächige Drop-Targets; falsche Zone = Schüttel-Animation
- **Entfernt:** EUP-Integration entfernt (kein Bedarf)
- **Neu:** `Config.LicenseKey` – hardcoded, kein Keymaster

### 2026-05-06 – Basis
- **Bugfix:** `MySQL.query` → `MySQL.update` in `saveSkin`
- **Neu:** 3-Panel-Layout (links | Mitte transparent | rechts Garderobe)
- **Neu:** `Config.CameraSideOffset` – zentriert den Charakter im transparenten Mittelbereich
- **Neu:** `zr_player_created()` / `zr_custom_spawn_menu` Hooks in `zr-identity`

---

## Voraussetzungen

| Abhängigkeit | Hinweis |
|---|---|
| [ESX Framework](https://github.com/esx-framework/esx_core) | 1.9+ |
| [oxmysql](https://github.com/overextended/oxmysql) | beliebig |
| `zr-identity` oder `esx_identity` | optional, für Auto-Open nach Char-Erstellung |
| ~~`esx_skin`~~ | **nicht nötig** – wird vollständig ersetzt |

---

## Installation

1. Ordner `austriawien_skinmenu` in dein `resources/`-Verzeichnis legen
2. In `server.cfg` eintragen:
   ```
   ensure oxmysql
   ensure austriawien_skinmenu
   ```
3. Die Datenbanktabelle wird **automatisch** beim Serverstart erstellt – kein SQL-Import nötig.
4. `esx_skin` aus der `server.cfg` **entfernen** oder auskommentieren.

---

## Konfiguration (`config.lua`)

```lua
Config = {}
Config.Debug          = true
Config.Command        = 'awskin'
Config.DatabaseTable  = 'austriawien_skins'
Config.AdminGroups    = { 'admin', 'superadmin', 'god' }
Config.FreezeOnOpen   = true
Config.CameraFOV      = 45.0
Config.CameraDistance = 2.2
Config.CameraHeight   = 0.5
Config.CameraSideOffset = -0.3
Config.AutoLoadOnLogin  = true
Config.FirstTimeSetup   = true
Config.AllowedModels    = { 'mp_m_freemode_01', 'mp_f_freemode_01' }
Config.ImageBasePath    = 'img'
Config.ImageFormats     = { 'png', 'jpg', 'webp' }
Config.LicenseKey       = 'AW-SKIN-2026-MIDCORE'
```

### Kamera
Die Kamera fokussiert automatisch auf die aktive Zone beim Slot-Wechsel:

| Zone | Kamera springt auf |
|---|---|
| `head` / `face` | Gesicht (hoch, enger FOV) |
| `torso` / `hands` | Oberkörper (Standard) |
| `legs` | Knie / Unterschenkel |
| `shoes` | Füße / Schuhe |

> **Tipp:** `CameraSideOffset` zwischen `-0.6` und `0.0` anpassen damit der Charakter exakt im transparenten Mittelpanel landet.

---

## Integration mit zr-identity

### Client-Hook (`zr-identity/zr-config/zr-build-c.lua`)

```lua
function zr_player_created()
    CreateThread(function()
        Wait(1500)
        TriggerEvent('esx_skin:playerRegistered')
    end)
end
```

### Server-Hook (`zr-identity/zr-config/zr-build-s.lua`)

```lua
function zr_custom_spawn_menu(zr_source, zr_fdata)
    TriggerClientEvent('esx_skin:openSaveableMenu', zr_source)
end
```

Beide Hooks feuern `esx_skin`-Events – `austriawien_skinmenu` fängt diese ab, `esx_skin` selbst läuft nicht.

---

## Slots & Zonen

| Slot-ID | Typ | GTA-Index | Zone |
|---|---|---|---|
| `hat` | prop | 0 | head |
| `glasses` | prop | 1 | head |
| `ear` | prop | 2 | head |
| `hair` | component | 2 | head |
| `mask` | component | 1 | face |
| `jacket` | component | 11 | torso |
| `undershirt` | component | 8 | torso |
| `arms` | component | 3 | torso |
| `armor` | component | 9 | torso |
| `accessories` | component | 7 | torso |
| `decal` | component | 10 | torso |
| `bag` | component | 5 | torso |
| `watch` | prop | 6 | hands |
| `bracelet` | prop | 7 | hands |
| `legs` | component | 4 | legs |
| `shoes` | component | 6 | shoes |

---

## Vorschau-Bilder

Eigene Bilder unter `html/img/{slotId}/{drawableId}.{format}` ablegen:

```
html/img/jacket/0.png
html/img/shoes/0.webp
```

Fehlt ein Bild → Emoji-Icon als Fallback. Bilder müssen **nicht** in `fxmanifest.lua` eingetragen werden solange der Ordner nicht existiert.

---

## Layout-Übersicht

```
┌─────────────────┬──────────────────────────┬─────────────────┐
│  CHARAKTER      │                          │  GARDEROBE      │
│  ┌─ KOPF ─────┐ │   Transparent –          │                 │
│  │ Hut Haare  │ │   Charakter live         │  Kategorie-Tabs │
│  │ Brille …   │ │   sichtbar (3D)          │  Item-Karten    │
│  ├─ OBERKÖRPER┤ │                          │  Textur-Slider  │
│  │ Jacke Hemd │ │                          │  Gesicht-Editor │
│  │ Arme Weste │ │                          │                 │
│  ├─ HÄNDE ────┤ │                          │  [ABBRECHEN]    │
│  │ Uhr Armbd. │ │                          │  [SPEICHERN]    │
│  ├─ UNTERKÖRP.┤ │                          │                 │
│  │ Hose       │ │                          │                 │
│  ├─ SCHUHE ───┤ │                          │                 │
│  │ Schuhe     │ │                          │                 │
│  └────────────┘ │                          │                 │
│  [◄ DREHEN ►]   │                          │                 │
└─────────────────┴──────────────────────────┴─────────────────┘
       280 px              transparent               360 px
```

**Bedienung:**
- Item aus der Garderobe (rechts) auf eine Körperzone (links) ziehen → Kleidung wird angelegt
- Klick auf einen Slot → Garderobe springt zur Kategorie, Kamera zoomt automatisch auf die Zone
- Kamera-Buttons drehen den Charakter in Echtzeit
- **SPEICHERN** → Skin in Datenbank speichern
- **ABBRECHEN** → Alle Änderungen rückgängig

---

## Admin-Befehle

| Befehl | Beschreibung |
|---|---|
| `/awskin` | Eigenes Skin-Menü öffnen |
| `/awskin 42` | Skin-Menü von Spieler-ID 42 öffnen (nur Admins) |

---

## Datenbank

Tabelle wird automatisch erstellt:

```sql
CREATE TABLE IF NOT EXISTS `austriawien_skins` (
    `identifier` VARCHAR(60)  NOT NULL,
    `skin`       LONGTEXT     NOT NULL,
    `updated_at` TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

## Dateistruktur

```
austriawien_skinmenu/
├── fxmanifest.lua
├── config.lua
├── client/
│   └── client.lua
├── server/
│   └── server.lua
└── html/
    ├── index.html
    ├── css/
    │   └── style.css
    ├── js/
    │   └── app.js
    └── img/
        ├── jacket/        ← Vorschau-Bilder hier ablegen
        ├── legs/
        ├── shoes/
        └── ...
```

---

## Bekannte Fehler & Lösungen

### Skin-Menü erscheint während der Charakter-Erstellung
**Ursache:** `zr_player_created()` oder `zr_custom_spawn_menu` Hook fehlt.  
**Lösung:** Hooks wie oben unter *Integration mit zr-identity* eintragen.

### Skin wird nach Reconnect nicht geladen
**Ursache:** Race-Condition zwischen `esx:onPlayerSpawn` und `esx:playerLoaded`.  
**Lösung:** Bereits behoben – `skinLoaded`-Flag verhindert Doppel-Load.

### Kamera zeigt nicht auf die Schuhe
**Ursache:** Kamera-Zone-Werte passen nicht zur Charakter-Größe.  
**Lösung:** `ZONE_CAM` in `client.lua` anpassen – `shoes` hat `height = 0.10, lookAt = -0.05`.

### Charakter steht nicht in der Mitte
**Ursache:** `CameraSideOffset` muss je nach Auflösung angepasst werden.  
**Lösung:**
```lua
Config.CameraSideOffset = -0.3   -- zwischen -0.6 und 0.0 testen
```

