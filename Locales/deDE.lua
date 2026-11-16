-- Pardona's ToolTips - German strings. Overrides the English defaults on deDE clients.

if GetLocale() ~= "deDE" then return end

local _, ns = ...
local L = ns.L

L.TITLE = "Pardona's ToolTips"

-- Slash commands and chat output
L.HELP_HEADER       = "Befehle:"
L.HELP_OPEN         = "/ptt – Optionen öffnen"
L.HELP_RESET        = "/ptt reset – alle Einstellungen zurücksetzen"
L.HELP_HELP         = "/ptt help – diese Liste anzeigen"
L.RESET_DONE        = "Alle Einstellungen wurden zurückgesetzt."
L.UNKNOWN_COMMAND   = "Unbekannter Befehl „%s“. /ptt help zeigt alle Befehle."
L.OPEN_AFTER_COMBAT = "Die Optionen öffnen sich nach dem Kampf."
L.NO_SETTINGS_API   = "Das Optionsfenster ist in diesem Client nicht verfügbar."

-- Options: sections
L.SECTION_APPEARANCE = "Erscheinungsbild"
L.SECTION_GENERAL    = "Allgemein"

-- Options: position
L.POSITION            = "Position"
L.POSITION_TT         = "Wo Tooltips mit Standardanker erscheinen (zum Beispiel Einheiten in der Spielwelt). Tooltips von Taschenplätzen und Buttons bleiben an ihrem Platz."
L.POS_CURSOR          = "Mauszeiger"
L.POS_TOPLEFT         = "Oben links"
L.POS_TOPRIGHT        = "Oben rechts"
L.POS_BOTTOMLEFT      = "Unten links"
L.POS_BOTTOMRIGHT     = "Unten rechts"
L.POS_CENTER          = "Bildschirmmitte"
L.POS_BLIZZARD        = "Blizzard-Standard"
L.OFFSET              = "Randabstand"
L.OFFSET_TT           = "Abstand zum Bildschirmrand in Pixeln. Gilt nur für die Eck-Positionen."

-- Options: scale and fonts
L.SCALE               = "Skalierung"
L.SCALE_TT            = "Größe des Tooltips und der Vergleichs-Tooltips."
L.FONT                = "Schrift"
L.FONT_TT             = "Schriftart der Tooltips. Ist LibSharedMedia über ein anderes Addon vorhanden, stehen dessen Schriften ebenfalls zur Wahl."
L.FONT_FRIZ           = "Friz Quadrata"
L.FONT_ARIALN         = "Arial Narrow"
L.FONT_SKURRI         = "Skurri"
L.FONT_MORPHEUS       = "Morpheus"
L.FONT_SIZE_HEADER    = "Schriftgröße: Kopfzeile"
L.FONT_SIZE_HEADER_TT = "Schriftgröße der ersten Tooltip-Zeile (Name der Einheit oder des Gegenstands)."
L.FONT_SIZE_TEXT      = "Schriftgröße: Text"
L.FONT_SIZE_TEXT_TT   = "Schriftgröße der übrigen Tooltip-Zeilen. Kleine Zeilen werden zwei Punkt kleiner dargestellt."

-- Options: colors
L.COLOR_SET           = "Farb-Set"
L.COLOR_SET_TT        = "Hintergrund-, Rahmen- und Textfarben des Tooltips."
L.SET_BLIZZARD        = "Blizzard"
L.SET_DARK            = "Dunkel"
L.SET_CONTRAST        = "Hoher Kontrast"
L.SET_PARDONA         = "Pardona"
L.COLOR_BORDER        = "Rahmen einfärben"
L.COLOR_BORDER_TT     = "Färbt den Rahmen: Gegenstände nach Qualität, Spieler nach Klasse, NPCs nach Reaktion (feindlich, neutral, freundlich)."

-- Options: general
L.RESET               = "Einstellungen zurücksetzen"
L.RESET_BUTTON        = "Zurücksetzen"
L.RESET_TT            = "Setzt alle Einstellungen von Pardona's ToolTips auf die Standardwerte zurück."
