-- Pardona's ToolTips - slash commands /ptt and /pardonastooltips.
--   (no argument)  open the options
--   reset          reset all settings
--   debug          print what the game lets the addon read (diagnostics)
--   minimap        show or hide the shared Pardona minimap button (lib-pardona)
--   help           list the commands

local _, ns = ...
local L = ns.L

local function PrintHelp()
    ns.Print(L.HELP_HEADER)
    ns.Print(L.HELP_OPEN)
    ns.Print(L.HELP_RESET)
    ns.Print(L.HELP_DEBUG)
    ns.Print(L.HELP_MINIMAP)
    ns.Print(L.HELP_HELP)
end

SLASH_PARDONASTOOLTIPS1 = "/ptt"
SLASH_PARDONASTOOLTIPS2 = "/pardonastooltips"
SlashCmdList.PARDONASTOOLTIPS = function(msg)
    if not ns.db then return end
    local command = (type(msg) == "string" and msg or ""):lower():match("^%s*(%S*)") or ""
    if command == "" then
        ns.Options.Open()
    elseif command == "reset" then
        ns.Options.ResetAll()
    elseif command == "debug" then
        ns.Debug.Run()
    elseif command == "minimap" then
        if not ns.Pardona.ToggleMinimap() then ns.Print(L.LIB_NOT_LOADED) end
    elseif command == "help" then
        PrintHelp()
    else
        ns.Print(L.UNKNOWN_COMMAND:format(command))
    end
end
