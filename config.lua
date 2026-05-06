Config = {}

-- Befehl zum Öffnen des Skin-Menüs
Config.Command = 'skin'

-- Datenbankeinstellungen
-- Tabelle in der die Skins gespeichert werden
Config.DatabaseTable = 'austriawien_skins'

-- Soll der Charakter beim Öffnen eingefroren werden?
Config.FreezeOnOpen = true

-- Kamera-Einstellungen
Config.CameraFOV      = 45.0
Config.CameraDistance = 2.2
Config.CameraHeight   = 0.5

-- Skin beim Einloggen automatisch laden und anwenden
Config.AutoLoadOnLogin = true

-- Erste Einrichtung: Öffnet das Menü beim ersten Einloggen
Config.FirstTimeSetup = true

-- Erlaubte Models (leer = alle freemode erlaubt)
Config.AllowedModels = {
    'mp_m_freemode_01',
    'mp_f_freemode_01'
}
