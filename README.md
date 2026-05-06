# austriawien_skinmenu

Drag-&-Drop Skin-Menü für FiveM mit ESX-Framework.  
Zeigt den live GTA-Charakter in der Mitte während man Kleidung anpasst.

---

## Changelog

### 2026-05-06
- **Bugfix:** `MySQL.query` → `MySQL.update` in `saveSkin` (server.lua:84 – `attempt to compare number with table`)
- **Layout:** Menü ist kein Vollbild mehr – Panels haben `height: 82vh / max-height: 740px` und abgerundete Ecken
- **Timing:** Skin-Menü öffnet jetzt erst **nach** der Charakter-Erstellung, nicht mehr währenddessen
- **Neu:** `Config.IdentityResource` – Auswahl zwischen `'zr-identity'`, `'esx_identity'` oder `''`
- **Neu:** `zr_custom_spawn_menu` in `zr-identity` triggert `austriawien_skinmenu:charCreated` → Skin-Menü öffnet automatisch nach „Create character"
- **Neu:** 3-Panel-Layout (links Slots | Mitte transparent/live Charakter | rechts Garderobe)
- **Neu:** `Config.CameraSideOffset` – zentriert den Charakter im transparenten Mittelbereich
- **Neu:** README erstellt

---

## Voraussetzungen

| Abhängigkeit | Mindestversion |
|---|---|
| [ESX Framework](https://github.com/esx-framework/esx_core) | 1.9+ |
| [oxmysql](https://github.com/overextended/oxmysql) | beliebig |
| `zr-identity` **oder** `esx_identity` | – |

---

## Installation

1. Ordner `austriawien_skinmenu` in dein `resources/`-Verzeichnis legen
2. In `server.cfg` eintragen:
   ```
   ensure oxmysql
   ensure austriawien_skinmenu
   ```
3. Die Datenbanktabelle wird **automatisch** beim Serverstart erstellt – kein SQL-Import nötig.

---

## Konfiguration (`config.lua`)

### Debug
```lua
Config.Debug = true   -- true = Logs in F8 + Server-Konsole | false = kein Output (Produktion)
```

### Befehl
```lua
Config.Command = 'awskin'
-- /awskin          → eigenes Skin-Menü öffnen
-- /awskin [id]     → Skin-Menü für anderen Spieler öffnen (nur Admins)
```

### Admin-Gruppen
```lua
Config.AdminGroups = { 'admin', 'superadmin', 'god' }
```
Nur Spieler in diesen Gruppen dürfen `/awskin [id]` auf andere Spieler anwenden.

### Identity-Resource
```lua
Config.IdentityResource = 'zr-identity'
```

| Wert | Beschreibung |
|---|---|
| `'zr-identity'` | ZR Identity – Menü öffnet wenn `zr_custom_spawn_menu` aufgerufen wird |
| `'esx_identity'` | Standard ESX Identity – Menü öffnet wenn `esx_identity:closeMenu` gefeuert wird |
| `''` | Kein Warten – Menü öffnet direkt nach dem ersten Spawn |

### Kamera
```lua
Config.CameraFOV        = 45.0   -- Sichtfeld
Config.CameraDistance   = 2.2    -- Abstand zum Charakter
Config.CameraHeight     = 0.5    -- Höhenversatz (0 = Hüfte, 0.5 = Brust, 1.0 = Kopf)
Config.CameraSideOffset = -0.3   -- Seitwärts-Versatz (negativ = Charakter nach rechts/Mitte)
```
> **Tipp:** `CameraSideOffset` je nach Monitor-Auflösung feintunen, damit der Charakter exakt im transparenten Mittelpanel landet.

### Sonstiges
```lua
Config.FreezeOnOpen    = true    -- Charakter einfrieren wenn Menü offen
Config.AutoLoadOnLogin = true    -- Skin automatisch beim Einloggen laden
Config.FirstTimeSetup  = true    -- Skin-Menü beim ersten Login automatisch öffnen
```

---

## Integration mit zr-identity

In `zr-identity/zr-config/zr-build-s.lua` ist `zr_custom_spawn_menu` bereits angepasst:

```lua
function zr_custom_spawn_menu(zr_source, zr_fdata)
    TriggerClientEvent('austriawien_skinmenu:charCreated', zr_source)
end
```

Diese Funktion wird von zr-identity aufgerufen **nachdem** der Spieler auf „Create character" geklickt hat. Das Skin-Menü erscheint dann erst zu diesem Zeitpunkt – nicht während der Charakter-Erstellung.

---

## Integration mit esx_identity

`Config.IdentityResource = 'esx_identity'` setzen – keine weiteren Änderungen nötig.  
Das Skin-Menü wartet automatisch auf den `esx_identity:closeMenu`-Event.

---

## Vorschau-Bilder

Eigene Kleidungsbilder werden aus `html/img/{slotId}/{drawableId}.{format}` geladen.

**Beispiel:**
```
html/img/jacket/0.png     ← Jacke Drawable 0
html/img/jacket/1.png     ← Jacke Drawable 1
html/img/shoes/0.webp     ← Schuhe Drawable 0
```

**Unterstützte Slot-IDs:**
`jacket`, `legs`, `shoes`, `hat`, `hair`, `mask`, `glasses`, `ear`,
`undershirt`, `arms`, `armor`, `accessories`, `decal`, `bag`, `watch`, `bracelet`

**Unterstützte Formate** (werden der Reihe nach versucht, erstes Treffer gewinnt):
```lua
Config.ImageFormats = { 'png', 'jpg', 'webp' }
```

Fehlt ein Bild, wird automatisch das Emoji-Icon als Fallback angezeigt.

**Empfohlene Bildgröße:** 72×72 px oder 128×128 px

---

## Layout-Übersicht

```
┌──────────────┬──────────────────────────┬─────────────────┐
│  CHARAKTER   │                          │  GARDEROBE      │
│              │   Transparent –          │                 │
│  Slot-Icons  │   Charakter live         │  Kategorie-Tabs │
│  (Drag-Ziel) │   sichtbar (3D)          │  Item-Karten    │
│              │                          │  Textur-Slider  │
│              │   [◄  DREHEN  ►]         │  Gesicht-Editor │
│              │                          │  [ABBRECHEN]    │
│              │                          │  [SPEICHERN]    │
└──────────────┴──────────────────────────┴─────────────────┘
    280 px           transparent                360 px
```

**Bedienung:**
- Item aus der Garderobe (rechts) **auf einen Slot** (links) ziehen → Kleidung wird angelegt
- Klick auf einen Slot → Garderobe springt zur passenden Kategorie
- Kamera-Buttons drehen den Charakter in Echtzeit
- **SPEICHERN** → Skin wird in der Datenbank gespeichert
- **ABBRECHEN** → Alle Änderungen werden rückgängig gemacht

---

## Admin-Befehle

| Befehl | Beschreibung |
|---|---|
| `/awskin` | Eigenes Skin-Menü öffnen |
| `/awskin 42` | Skin-Menü von Spieler mit Server-ID 42 öffnen (nur Admins) |

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

## Exports (für andere Resources)

```lua
-- Skin eines Spielers als Lua-Table abrufen (Server-seitig)
local skin = exports['austriawien_skinmenu']:getSkin(identifier)
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
        └── ...            ← (16 Slot-Ordner gesamt)
```

---

## Bekannte Fehler & Lösungen

### `attempt to compare number with table` (server.lua:84)
**Ursache:** `MySQL.query` gibt bei INSERT/UPDATE ein Tabellen-Objekt zurück, kein Plain-Number.  
**Lösung:** Bereits behoben – `saveSkin` verwendet jetzt `MySQL.update(...)` statt `MySQL.query(...)`.

---

### Skin-Menü erscheint während der Charakter-Erstellung
**Ursache:** `Config.IdentityResource` nicht oder falsch gesetzt.  
**Lösung:**
```lua
-- Für zr-identity:
Config.IdentityResource = 'zr-identity'

-- Für esx_identity:
Config.IdentityResource = 'esx_identity'
```
Außerdem sicherstellen dass `zr_custom_spawn_menu` in `zr-identity/zr-config/zr-build-s.lua` den Event triggert:
```lua
function zr_custom_spawn_menu(zr_source, zr_fdata)
    TriggerClientEvent('austriawien_skinmenu:charCreated', zr_source)
end
```

---

### Charakter steht nicht in der Mitte des transparenten Bereichs
**Ursache:** `CameraSideOffset` muss je nach Auflösung angepasst werden.  
**Lösung:** In `config.lua` den Wert schrittweise ändern:
```lua
Config.CameraSideOffset = -0.3   -- Standardwert, bei Bedarf zwischen -0.6 und 0.0 testen
```

---

### Skin wird nach Reconnect nicht geladen
**Ursache:** `esx:onPlayerSpawn` wird unter Umständen vor `esx:playerLoaded` gefeuert.  
**Lösung:** Bereits behoben – `skinLoaded`-Flag verhindert Doppel-Load. Bei Reconnect wird das Flag in `esx:playerLoaded` zurückgesetzt.

