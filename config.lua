Config = {}

-- ─── Debug ────────────────────────────────────────────────────────────────────
-- true  → alle Logs in die F8-Konsole (Client) und Server-Konsole schreiben
-- false → kein Output (für Produktion)
Config.Debug = false

-- ─── Befehle ──────────────────────────────────────────────────────────────────
-- /awskin          → eigenes Skin-Menü öffnen
-- /awskin [id]     → Skin-Menü für anderen Spieler öffnen (Admin)
Config.Command = 'awskin'

-- ─── Datenbank ────────────────────────────────────────────────────────────────
Config.DatabaseTable = 'austriawien_skins'

-- ─── Admin-Gruppen, die /awskin [id] auf andere Spieler anwenden dürfen ───────
Config.AdminGroups = { 'admin'}

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

-- ─── Erlaubte Models ──────────────────────────────────────────────────────────
Config.AllowedModels = {
    'mp_m_freemode_01',
    'mp_f_freemode_01'
}