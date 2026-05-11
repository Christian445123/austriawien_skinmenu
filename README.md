# austriawien_skinmenu

Skin-Menü für FiveM mit ESX-Framework.  
Zeigt den live GTA-Charakter in der Mitte während man Kleidung anpasst.

<img width="2563" height="963" alt="image" src="https://github.com/user-attachments/assets/1c2fa57a-6549-4933-aa8c-72938f7a454a" />

**Drop-in-Ersatz für `esx_skin`** – alle `esx_skin`-Events werden abgefangen, `esx_skin` muss **nicht** laufen.

---

## Changelog

### 2026-05-11 – v1.1.2
- **Fix:** Skin geht nach Clotheshop-Kauf nicht mehr verloren – `lastAppliedSkin`-Cache wird nach `esx_skin:save` sofort aktualisiert
- **Fix:** Spieler spawnt nicht mehr an falscher Position – `SetPlayerModel` sichert/restauriert Koordinaten und Heading
- **Neu:** Skin + Position werden alle 5–10 Sekunden in den Server-RAM-Cache geschrieben (kein DB-Write)
- **Neu:** Bei `quit` (F8) werden Skin und letzte Position zuverlässig in die Datenbank geschrieben
- **Neu:** `Config.RestoreLastPosition` – Spieler spawnt beim nächsten Login an seiner letzten Position
- **Optimierung:** `INSERT … ON DUPLICATE KEY UPDATE` sendet JSON-Blob nicht mehr doppelt → deutlich weniger DB-Last
- **Fix:** jobs_creator erkennt das Clothing-Script jetzt zuverlässig (Timing-Fix via `dependency`)

### 2026-05-08 – v1.1.0
- **Neu:** Augenfarbe (32 Farben) im Gesichts-Tab anpassbar – live Vorschau
- **Neu:** Kamera-Höhe per ▲/▼-Buttons anpassen
- **Neu:** Kamera-Zoom per +/−-Buttons anpassen
- **UI:** Kamera-Bar in drei Zeilen: DREHEN / HÖHE / ZOOM

### 2026-05-06 – v1.0.4
- **Neu:** `/awskin` nur noch für Admins – Ausnahme: erstes Mal (kein Skin in DB)
- **Neu:** Server-Callback `austriawien_skinmenu:canOpenMenu` prüft Berechtigung serverseitig
- **Fix:** Kamera startet immer von vorne
- **Fix:** Alle Equip-Slots zeigen vollständigen Inhalt

### 2026-05-06 – v1.0.3
- **Neu:** Kamera-Fokus per Zone – springt automatisch zu Kopf / Oberkörper / Hände / Beine / Schuhe
- **Neu:** Startbanner in Schwarz/Weiß/Rot

### 2026-05-06 – v1.0.2
- **Neu:** Drop-in-Ersatz für `esx_skin` – alle esx_skin NetEvents werden abgefangen

### 2026-05-06 – v1.0.1
- **Neu:** 3-Panel-Layout (links | Mitte transparent | rechts Garderobe)

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
2. In `server.cfg` eintragen (**vor** `jobs_creator`):
   ```
   ensure oxmysql
   ensure austriawien_skinmenu
   ensure jobs_creator
   ```
3. Die Datenbanktabelle wird **automatisch** beim Serverstart erstellt – kein SQL-Import nötig.
4. `esx_skin` aus der `server.cfg` **entfernen** oder auskommentieren.

---

## Konfiguration (`config.lua`)

```lua
Config.Debug               = false
Config.Command             = 'awskin'
Config.DatabaseTable       = 'austriawien_skins'
Config.AdminGroups         = { 'admin' }   -- darf /awskin jederzeit öffnen
Config.FreezeOnOpen        = true
Config.CameraFOV           = 45.0
Config.CameraDistance      = 2.2
Config.CameraHeight        = 0.5
Config.CameraSideOffset    = -0.3
Config.AutoLoadOnLogin     = true
Config.AllowedModels       = { 'mp_m_freemode_01', 'mp_f_freemode_01' }
Config.RestoreLastPosition = true   -- letzte Position beim Spawn wiederherstellen
```

### Berechtigungen `/awskin`

| Wer tippt `/awskin` | Ergebnis |
|---|---|
| Spieler **ohne** Skin in DB (erstes Mal) | Menü öffnet sich |
| Normaler Spieler mit bestehendem Skin | Zugriff verweigert |
| Spieler in `Config.AdminGroups` | Menü öffnet immer |
| Admin `/awskin [id]` | Öffnet Menü für Ziel-Spieler |

### Kamera

| Buttons | Funktion | Schrittweite | Bereich |
|---|---|---|---|
| ◀ DREHEN ▶ | Charakter drehen | 20° | 360° |
| ▲ HÖHE ▼ | Kamera hoch/runter | 0.15 | −1.2 – 1.8 |
| − ZOOM + | Näher/weiter ran | 0.25 | 0.6 – 5.0 |

> **Tipp:** `CameraSideOffset` zwischen `-0.6` und `0.0` anpassen damit der Charakter im transparenten Mittelpanel zentriert ist.

---

## Speicherung & Position

- **Alle 5–10 Sek.** wird Skin + aktuelle Position in den Server-RAM-Cache geschrieben (kein DB-Write)
- **Bei Disconnect / `quit`** (F8 → `quit`) werden Skin und Position sofort in die Datenbank geschrieben
- **Beim nächsten Spawn** wird der Spieler automatisch an seiner letzten Position gesetzt (steuerbar über `Config.RestoreLastPosition`)
- **Clotheshop:** Nach einem Kauf wird der Cache sofort aktualisiert – der Skin geht nicht verloren

---

## Integration mit jobs_creator

In `jobs_creator/fxmanifest.lua` muss folgende Zeile vorhanden sein:

```lua
dependency 'austriawien_skinmenu'
```

Das stellt sicher dass `austriawien_skinmenu` vor `jobs_creator` startet und `GetResourceState('esx_skin')` korrekt `'started'` zurückgibt. Außerdem muss in `current_config.json` eingestellt sein:

```json
"externalScriptsNames": {
    "esx_skin": "austriawien_skinmenu"
},
"modules": {
    "outfits": "austriawien_skinmenu"
}
```

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

---

## Gesichts-Editor

| Abschnitt | Inhalt |
|---|---|
| Geschlecht | Männlich / Weiblich umschalten |
| Gesichtsform | Head-Blend Shape (Form 1+2 + Mix) |
| Hautfarbe | Head-Blend Skin (Haut 1+2 + Mix) |
| Haarfarbe | 64 Farb-Chips Primär + Strähnen |
| Augenfarbe | 32 Farb-Chips, live Vorschau |
| Bart & Augenbrauen | Stil + Stärke per Slider |
| Gesichtszüge | 20 Morph-Slider (Nase, Kiefer, Wangen, …) |

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

Fehlt ein Bild → Emoji-Icon als Fallback.

---

## Layout-Übersicht

```
┌─────────────────┬──────────────────────────┬─────────────────┐
│  CHARAKTER      │                          │  GARDEROBE      │
│  ┌─ KOPF ─────┐ │   Transparent –          │                 │
│  │ Hut Haare  │ │   Charakter live         │  Kategorie-Tabs │
│  │ Brille Ohr │ │   sichtbar (3D)          │  Item-Karten    │
│  │ Maske      │ │                          │  Textur-Slider  │
│  ├─ OBERKÖRPER┤ │                          │  Gesicht-Editor │
│  │ Jacke Hemd │ │                          │                 │
│  │ Arme Weste │ │                          │  [VERWERFEN]    │
│  │ Acc. Tasche│ │                          │  [SPEICHERN]    │
│  │ Abzeichen  │ │                          │                 │
│  ├─ HÄNDE ────┤ │                          │                 │
│  │ Uhr Armbd. │ │                          │                 │
│  ├─ UNTERKÖRP.┤ │                          │                 │
│  │ Hose       │ │                          │                 │
│  ├─ SCHUHE ───┤ │                          │                 │
│  │ Schuhe     │ │                          │                 │
│  └────────────┘ │                          │                 │
│  [◄ DREHEN ►]   │                          │                 │
│  [▲ HÖHE   ▼]   │                          │                 │
│  [− ZOOM   +]   │                          │                 │
└─────────────────┴──────────────────────────┴─────────────────┘
       280 px              transparent               370 px
```

**Bedienung:**
- Klick auf Item-Karte (rechts) → Kleidung wird sofort angelegt
- Klick auf Equip-Slot (links) → Garderobe springt zur Kategorie, Kamera zoomt auf Zone
- **X / ESC** → Änderungen automatisch speichern und Menü schließen
- **SPEICHERN** → Skin explizit in Datenbank schreiben
- **VERWERFEN** → Alle Änderungen rückgängig und Original-Skin wiederherstellen

---

## Admin-Befehle

| Befehl | Beschreibung |
|---|---|
| `/awskin` | Eigenes Skin-Menü öffnen (Admin oder erstes Mal) |
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
│   ├── server.lua
│   └── server_secrets.lua
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

### jobs_creator meldet „Couldn't find any clothing script"
**Ursache:** `austriawien_skinmenu` startet nach `jobs_creator`.  
**Lösung:** `dependency 'austriawien_skinmenu'` in `jobs_creator/fxmanifest.lua` eintragen.

### Charakter steht nicht in der Mitte
**Ursache:** `CameraSideOffset` muss je nach Auflösung angepasst werden.  
**Lösung:**
```lua
Config.CameraSideOffset = -0.3   -- zwischen -0.6 und 0.0 testen
```


<img width="2563" height="963" alt="image" src="https://github.com/user-attachments/assets/1c2fa57a-6549-4933-aa8c-72938f7a454a" />

**Drop-in-Ersatz für `esx_skin`** – alle `esx_skin`-Events werden von dieser Resource abgefangen, `esx_skin` muss **nicht** laufen.

---

## Changelog

### 2026-05-08 – v1.1.0
- **Neu:** Augenfarbe (32 Farben) im Gesichts-Tab anpassbar – live Vorschau
- **Neu:** Kamera-Höhe per ▲/▼-Buttons anpassen (Schritte 0.15, Bereich −1.2–1.8)
- **Neu:** Kamera-Zoom per +/−-Buttons anpassen (Schritte 0.25, Bereich 0.6–5.0)
- **UI:** Kamera-Bar in drei Zeilen: DREHEN / HÖHE / ZOOM
- **UI:** Zoom-Faktor von 1.25 auf 0.85 reduziert (kleinere Darstellung)

### 2026-05-06 – v1.0.4
- **Neu:** `/awskin` nur noch für Admins (`admin`-Gruppe) – Ausnahme: erstes Mal (kein Skin in DB) darf jeder Spieler öffnen
- **Neu:** Server-Callback `austriawien_skinmenu:canOpenMenu` prüft Berechtigung serverseitig (nicht manipulierbar)
- **Fix:** Kamera startet immer von vorne – GTA Heading-Vorzeichen korrigiert (`-GetEntityHeading`)
- **Fix:** Alle Equip-Slots zeigen vollständigen Inhalt (kein `overflow:hidden` auf Body-Zonen mehr)
- **Fix:** Slot-IDs in `index.html` korrigiert (vorher Emojis als IDs → Klick auf Slots funktioniert jetzt)
- **Entfernt:** Drag & Drop komplett entfernt – Klick auf Item-Karte legt Kleidung sofort an
- **CSS:** Equip-Slot Breite 58 → 66 px, Label mit `text-overflow: ellipsis`, `equipped`-Rahmen Rot statt Grün

### 2026-05-06 – v1.0.3
- **Neu:** Kamera-Fokus per Zone – Kamera springt automatisch zu Kopf / Oberkörper / Hände / Beine / Schuhe
- **Neu:** `shoes`-Slot hat eigene Zone mit tieferer Kameraposition als `legs`
- **Neu:** Startbanner in Schwarz/Weiß/Rot
- **Entfernt:** Versionscheck via HTTP
- **Fix:** `fxmanifest.lua` ohne `img`-Glob-Wildcards (keine Warnungen mehr)

### 2026-05-06 – v1.0.2
- **Neu:** Drop-in-Ersatz für `esx_skin` – alle esx_skin NetEvents werden abgefangen
- **Neu:** Schwarz/Weiß/Rot-Theme, halbdurchsichtige Panels
- **Neu:** ASCII-Banner beim Serverstart

### 2026-05-06 – v1.0.1
- **Neu:** 3-Panel-Layout (links | Mitte transparent | rechts Garderobe)
- **Neu:** `Config.CameraSideOffset`, `zr_player_created()` Hook
- **Fix:** `MySQL.query` → `MySQL.update` in `saveSkin`

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
Config.Debug            = false
Config.Command          = 'awskin'
Config.DatabaseTable    = 'austriawien_skins'
Config.AdminGroups      = { 'admin' }   -- darf /awskin jederzeit öffnen
Config.FreezeOnOpen     = true
Config.CameraFOV        = 45.0
Config.CameraDistance   = 2.2
Config.CameraHeight     = 0.5
Config.CameraSideOffset = -0.3
Config.AutoLoadOnLogin  = true
Config.AllowedModels    = { 'mp_m_freemode_01', 'mp_f_freemode_01' }
```

### Berechtigungen `/awskin`

| Wer tippt `/awskin` | Ergebnis |
|---|---|
| Spieler **ohne** Skin in DB (erstes Mal) | Menü öffnet sich |
| Normaler Spieler mit bestehendem Skin | Zugriff verweigert |
| Spieler in `Config.AdminGroups` | Menü öffnet immer |
| Admin `/awskin [id]` | Öffnet Menü für Ziel-Spieler |

### Kamera
Die Kamera fokussiert automatisch auf die aktive Zone beim Slot-Wechsel und startet **immer von vorne**.  
Über die drei Kamera-Button-Reihen im linken Panel lässt sich die Kamera vollständig steuern:

| Buttons | Funktion | Schrittweite | Bereich |
|---|---|---|---|
| ◀ DREHEN ▶ | Charakter drehen | 20° | 360° |
| ▲ HÖHE ▼ | Kamera hoch/runter | 0.15 | −1.2 – 1.8 |
| − ZOOM + | Näher/weiter ran | 0.25 | 0.6 – 5.0 |

Automatischer Zonen-Fokus beim Slot-Klick:

| Zone | Kamera springt auf |
|---|---|
| `head` / `face` | Gesicht |
| `torso` / `hands` | Oberkörper |
| `legs` | Knie / Unterschenkel |
| `shoes` | Füße / Schuhe |

> **Tipp:** `CameraSideOffset` zwischen `-0.6` und `0.0` anpassen damit der Charakter im transparenten Mittelpanel zentriert ist.

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

## Gesichts-Editor

Der Gesichts-Tab (rechtes Panel) enthält folgende Abschnitte:

| Abschnitt | Inhalt |
|---|---|
| Geschlecht | Männlich / Weiblich umschalten |
| Gesichtsform | Head-Blend Shape (Form 1+2 + Mix) |
| Hautfarbe | Head-Blend Skin (Haut 1+2 + Mix) |
| Haarfarbe | 64 Farb-Chips Primär + Strähnen |
| Augenfarbe | 32 Farb-Chips, live Vorschau |
| Bart & Augenbrauen | Stil + Stärke per Slider |
| Gesichtszüge | 20 Morph-Slider (Nase, Kiefer, Wangen, …) |

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

Fehlt ein Bild → Emoji-Icon als Fallback. Bilder müssen **nicht** in `fxmanifest.lua` eingetragen werden.

---

## Layout-Übersicht

```
┌─────────────────┬──────────────────────────┬─────────────────┐
│  CHARAKTER      │                          │  GARDEROBE      │
│  ┌─ KOPF ─────┐ │   Transparent –          │                 │
│  │ Hut Haare  │ │   Charakter live         │  Kategorie-Tabs │
│  │ Brille Ohr │ │   sichtbar (3D)          │  Item-Karten    │
│  │ Maske      │ │                          │  Textur-Slider  │
│  ├─ OBERKÖRPER┤ │                          │  Gesicht-Editor │
│  │ Jacke Hemd │ │                          │                 │
│  │ Arme Weste │ │                          │  [ABBRECHEN]    │
│  │ Acc. Tasche│ │                          │  [SPEICHERN]    │
│  │ Abzeichen  │ │                          │                 │
│  ├─ HÄNDE ────┤ │                          │                 │
│  │ Uhr Armbd. │ │                          │                 │
│  ├─ UNTERKÖRP.┤ │                          │                 │
│  │ Hose       │ │                          │                 │
│  ├─ SCHUHE ───┤ │                          │                 │
│  │ Schuhe     │ │                          │                 │
│  └────────────┘ │                          │                 │
│  [◄ DREHEN ►]   │                          │                 │
│  [▲ HÖHE   ▼]   │                          │                 │
│  [− ZOOM   +]   │                          │                 │
└─────────────────┴──────────────────────────┴─────────────────┘
       280 px              transparent               370 px
```

**Bedienung:**
- Klick auf Item-Karte (rechts) → Kleidung wird sofort angelegt
- Klick auf einen Equip-Slot (links) → Garderobe springt zur Kategorie, Kamera zoomt auf die Zone
- Kamera-Buttons: Drehen, Höhe anpassen, Zoom steuern
- **SPEICHERN** → Skin in Datenbank schreiben
- **ABBRECHEN** → Alle Änderungen rückgängig

---

## Admin-Befehle

| Befehl | Beschreibung |
|---|---|
| `/awskin` | Eigenes Skin-Menü öffnen (Admin oder erstes Mal) |
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

