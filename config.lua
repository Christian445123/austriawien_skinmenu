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
Config.CameraFOV        = 45.0
Config.CameraDistance   = 2.2
Config.CameraHeight     = 0.5
-- Seitwärts-Versatz damit der Charakter im transparenten Mittelbereich erscheint.
-- Negativ = Charakter verschiebt sich auf dem Bildschirm nach rechts (Mitte).
-- Feintuning je nach Monitor-Auflösung und Panel-Breiten.
Config.CameraSideOffset = -0.3

-- ─── Skin beim Einloggen laden ────────────────────────────────────────────────
Config.AutoLoadOnLogin = true

-- ─── Erstes Login → Menü automatisch öffnen ───────────────────────────────────
Config.FirstTimeSetup = true

-- ─── Identity-Resource ──────────────────────────────────────────────────────
-- Wähle welche Charakter-Erstellungs-Resource du verwendest.
-- Das Skin-Menü öffnet sich erst NACHDEM der Charakter erstellt wurde.
--
--   'esx_identity'  → Standard ESX Identity
--                     Wartet auf den Client-Event 'esx_identity:closeMenu'
--
--   'zr-identity'   → ZR Identity (zr-identity Resource)
--                     Wird über zr_custom_spawn_menu (Server→Client) getriggert
--
--   ''              → Kein Event – Menü öffnet direkt nach dem Spawn
Config.IdentityResource = 'zr-identity'

-- ─── Erlaubte Models ──────────────────────────────────────────────────────────
Config.AllowedModels = {
    'mp_m_freemode_01',
    'mp_f_freemode_01'
}

-- ─── Lizenz ──────────────────────────────────────────────────────────────────
-- Lizenzschlüssel – wird beim Ressourcenstart geprüft.
Config.LicenseKey = '' -- AW-SKIN-2026-MIDCORE
