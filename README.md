# austriawien_skinmenu

Drag-&-Drop Skin-Menü für FiveM mit ESX-Framework.  
Zeigt den live GTA-Charakter in der Mitte während man Kleidung anpasst.

---

## Changelog

### 2026-05-06 (Overhaul)
- **Bugfix:** Drag-&-Drop war komplett defekt wegen dupliziertem HTML in `index.html` – `index.html` vollständig neu geschrieben
- **Neu:** Linkes Panel jetzt als **Körperzonen-Avatar** (KOPF / OBERKÖRPER / HÄNDE / UNTERKÖRPER / SCHUHE) statt scrollbarer Slot-Liste
- **Drag-Drop:** Body-Zonen sind großflächige Drop-Targets; falsche Zone = Schüttel-Animation
- **Neu:** `Config.LicenseKey` – Resource startet nicht ohne gültigen Schlüssel
- **Neu:** `Config.EUPResources` – automatischer EUP-Bild-Scanner (`img/`-Ordner externer Resources)
- **Neu:** EUP-Bilder werden als `cfx-nui-{resource}/img/{slot}/{id}.png` nachgeladen wenn kein lokales Bild vorhanden
- **Bugfix:** `zr_player_created()` Hook: `Wait(1500)` in `CreateThread` damit das Identity-NUI sich schließt bevor das Skin-Menü erscheint
- **Neu:** Kamera-Buttons jetzt im linken Panel unten (statt Mitte)

### 2026-05-06 (Basis)
- **Bugfix:** `MySQL.query` → `MySQL.update` in `saveSkin` (`attempt to compare number with table`)
- **Layout:** Menü ist kein Vollbild mehr – `height: 82vh; top: 50%; transform: translateY(-50%)`
- **Timing:** Skin-Menü öffnet erst nach der Charakter-Erstellung
- **Neu:** `Config.IdentityResource` – Auswahl zwischen `'zr-identity'`, `'esx_identity'` oder `''`
- **Neu:** `zr_player_created()` Hook in `zr-identity/zr-config/zr-build-c.lua`
- **Neu:** 3-Panel-Layout (links | Mitte transparent | rechts Garderobe)
- **Neu:** `Config.CameraSideOffset` – zentriert den Charakter im transparenten Mittelbereich

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

### Lizenz ⚠️
```lua
Config.LicenseKey = 'ABCD-1234-EFGH-5678'
```
Ohne gültigen Schlüssel stoppt die Resource beim Start automatisch.  
Schlüssel auf [keymaster.fivem.net](https://keymaster.fivem.net) registrieren und hier eintragen.

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

Der primäre Hook ist in `zr-identity/zr-config/zr-build-c.lua` (client-seitig, zuverlässiger als Server→Client):

```lua
function zr_player_created()
    CreateThread(function()
        Wait(1500)  -- Warten bis das Identity-NUI sich vollständig schließt
        TriggerEvent('austriawien_skinmenu:charCreated')
    end)
end
```

`TriggerEvent` ist ein **lokaler** Client-Event – kein `RegisterNetEvent` nötig.  
Die `Wait(1500)` verhindert, dass das Skin-Menü erscheint bevor das Identity-NUI weg ist.

> **Hinweis:** Der Server-Hook über `zr-build-s.lua` (`TriggerClientEvent`) erfordert `RegisterNetEvent` auf dem Client und ist daher weniger zuverlässig. Der Client-Hook ist die bevorzugte Lösung.

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

## EUP-Bilder aus externen Resources

Wenn EUP-Packs als separate FiveM-Resources vorhanden sind, kann das Skin-Menü deren Vorschaubilder automatisch einbinden.

**1. `config.lua` anpassen:**
```lua
Config.EUPResources = { 'eup-stream', 'eup-sp' }
```

**2. EUP-Resource: Bilder unter `img/` ablegen:**
```
eup-stream/img/jacket/0.png
eup-stream/img/jacket/1.png
eup-stream/img/legs/0.png
```

**3. `fxmanifest.lua` der EUP-Resource: Bilder als Files registrieren:**
```lua
files {
    'img/**/*.png',
    'img/**/*.jpg',
    'img/**/*.webp'
}
```

Der Server scannt beim Start alle angegebenen Resources automatisch und baut ein Manifest. Der Browser lädt Bilder dann per `cfx-nui-{resource}/img/{slot}/{id}.png`. Lokale Bilder in `html/img/` haben immer Vorrang.

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
- Item aus der Garderobe (rechts) **auf eine Körperzone** (links) ziehen → Kleidung wird angelegt
- Item auf eine **falsche Zone** fallen lassen → Schüttel-Animation als Feedback
- Klick auf einen Slot → Garderobe springt zur passenden Kategorie
- Kamera-Buttons (unten links) drehen den Charakter in Echtzeit
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
**Ursache 1:** `Config.IdentityResource` nicht oder falsch gesetzt.  
**Ursache 2 (zr-identity):** `TriggerClientEvent` vom Server braucht `RegisterNetEvent` auf dem Client – ohne das wird der Event ignoriert.  
**Lösung:** `zr_player_created()` in `zr-identity/zr-config/zr-build-c.lua` überschreiben:
```lua
function zr_player_created()
    CreateThread(function()
        Wait(1500)
        TriggerEvent('austriawien_skinmenu:charCreated')
    end)
end
```

---

### Resource startet nicht / stoppt sofort
**Ursache:** `Config.LicenseKey` ist leer.  
**Lösung:** Schlüssel auf keymaster.fivem.net registrieren und in `config.lua` eintragen:
```lua
Config.LicenseKey = 'DEIN-SCHLUESSEL-HIER'
```

---

### Drag-&-Drop funktioniert nicht
**Ursache:** Item auf einen falschen Zonen-Typ fallen gelassen (z.B. Schuh-Item auf KOPF-Zone).  
**Erkennung:** Die Zone zeigt eine Schüttel-Animation wenn der Typ nicht passt.  
**Lösung:** Item auf die passende Körperzone fallen lassen (Hose → UNTERKÖRPER, Jacke → OBERKÖRPER usw.)

---

### EUP-Bilder werden nicht angezeigt
**Ursache 1:** `Config.EUPResources` ist leer oder Resource-Name falsch.  
**Ursache 2:** Die EUP-Resource hat keine `files`-Einträge im `fxmanifest.lua`.  
**Lösung:** Im `fxmanifest.lua` der EUP-Resource eintragen:
```lua
files { 'img/**/*.png', 'img/**/*.jpg', 'img/**/*.webp' }
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

