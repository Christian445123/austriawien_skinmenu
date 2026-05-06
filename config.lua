Config = {}

-- ─── Debug ────────────────────────────────────────────────────────────────────
-- true  → alle Logs in die F8-Konsole (Client) und Server-Konsole schreiben
-- false → kein Output (für Produktion)
Config.Debug = true

-- ─── Befehle ──────────────────────────────────────────────────────────────────
-- /awskin          → eigenes Skin-Menü öffnen
-- /awskin [id]     → Skin-Menü für anderen Spieler öffnen (Admin)
Config.Command = 'awskin'

-- ─── Datenbank ────────────────────────────────────────────────────────────────
Config.DatabaseTable = 'austriawien_skins'

-- ─── Admin-Gruppen, die /awskin [id] auf andere Spieler anwenden dürfen ───────
Config.AdminGroups = { 'admin', 'superadmin', 'god' }

-- ─── Charakter einfrieren wenn Menü offen ────────────────────────────────────
Config.FreezeOnOpen = true

-- ─── Kamera ───────────────────────────────────────────────────────────────────
Config.CameraFOV      = 45.0
Config.CameraDistance = 2.2
Config.CameraHeight   = 0.5

-- ─── Skin beim Einloggen laden ────────────────────────────────────────────────
Config.AutoLoadOnLogin = true

-- ─── Erstes Login → Menü automatisch öffnen ───────────────────────────────────
Config.FirstTimeSetup = true

-- ─── Erlaubte Models ──────────────────────────────────────────────────────────
Config.AllowedModels = {
    'mp_m_freemode_01',
    'mp_f_freemode_01'
}

-- ─── Vorschau-Bilder ──────────────────────────────────────────────────────────
-- Bilder werden aus html/img/{slotId}/{drawableId}.png geladen.
-- Lege z.B. html/img/jacket/0.png, html/img/jacket/1.png usw. ab.
-- Fehlt ein Bild, wird automatisch das Emoji-Icon als Fallback angezeigt.
-- Du kannst hier den Basis-Pfad anpassen (relativ zu html/).
Config.ImageBasePath = 'img'

-- Unterstützte Bildformate, die der Browser nacheinander versucht zu laden.
-- Erste Übereinstimmung gewinnt.
Config.ImageFormats = { 'png', 'jpg', 'webp' }
