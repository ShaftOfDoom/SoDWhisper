local L = LibStub("AceLocale-3.0"):NewLocale("SoDWhisper", "enUS", true)

-- Addon Description
L["Track Whispers And Social Information"] = true

------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------- SoDWhisper Main Options ---------------------------------------------------------------------
-- Timestamps Table
L["HH:MM:SS (24-hour)"] = true
L["HH:MM (24-hour)"] = true
L["HH:MM:SS AM (12-hour)"] = true
L["HH:MM:SS (12-hour)"] = true
L["HH:MM AM (12-hour)"] = true
L["HH:MM (12-hour)"] = true
L["MM:SS"] = true
L["None"] = true

-- Sound Output Table
L["Master sound"] = true
L["SFX sound"] = true
L["Ambience sound"] = true
L["Music sound"] = true

-- RealID Name Table
L["First name"] = true
L["Last name"] = true
L["Full name"] = true

-- Frame Strata Table
L["DIALOG"] = true
L["HIGH"] = true
L["MEDIUM"] = true
L["LOW"] = true

-- General Header
L["General Settings"] = true

-- Hints Group
L["Hints"] = true
-- LDB/Minimap Subgroup
L["Ctrl"] = true
L["Shift"] = true
L["Alt"] = true
L["Left Click"] = true
L["Right Click"] = true
L["Middle Click"] = true
L["LDB/Minimap Icon"] = true
L["Whisper player of missed message"] = true
L["Open options"] = true
L["Player Names"] = true
L["Reply to player"] = true
L["Reply to BattleNet character if applicable"] = true
L["Invite player to group"] = true
L["Open Chat History Log Frame for player"] = true
L["Open Change Display Name Frame for player"] = true
L["DELETE player history"] = true
L["Group Title"] = true
L["Toggle between Timeframe and Online"] = true
L["Toggle showing BattleNet App players that are away"] = true
L["DELETE history for group (ex. All of Guild)"] = true
-- Editbox Subgroup
L["Player Title"] = true
L["Page Icon"] = true
L["Player Name"] = true
L["Group Icon"] = true
L["Add Icon"] = true
L["Add player to friends"] = true
L["Ignore Icon"] = true
L["Ignore or stop ignoring player"] = true
L["Location Icon"] = true
L["Display information about player"] = true

-- Appearance Group
L["Appearance"] = true
L["Entries"] = true
L["Entries Shown"] = true
L["The number of entries to show in the message panels."] = true
L["Max Message Height"] = true
L["Max height of message panels before scrolling enables."] = true
L["Texture"] = true
L["Background Color"] = true
L["Background"] = true
L["Change the background texture (For some textures the background color needs to be set to white)."] = true
L["Border Color"] = true
L["Border Style"] = true
L["Change the border style of the panel."] = true
L["Frame Level"] = true
L["Level the frame appears on within the strata."] = true
L["Frame Strata"] = true
L["Strata the frame appears on."] = true
L["Text"] = true
L["Color Outgoing"] = true
L["Set the color of outgoing messages."] = true
L["Color Incoming"] = true
L["Set the color of incoming messages."] = true
L["Font"] = true
L["Font Size"] = true
L["Timestamp"] = true
L["Timestamp Color"] = true
L["Timestamp Format"] = true

-- Names Group
L["Names"] = true
L["RealID Display"] = true
L["Select the display for realID names."] = true
L["Color By Class"] = true
L["Character Names"] = true
L["Color character names by class."] = true
L["BattleNet Names"] = true
L["Color BattleNet names by character class when possible."] = true

-- Sounds Group
L["Sounds"] = true
L["Use Sound for incoming messages."] = true
L["Channel Output"] = true
L["Channel for sound to play through."] = true
L["Custom Sounds"] = true
L["Other Whisper"] = true
L["Sound for whispers that are not from guild or friends."] = true
L["Guild Whisper"] = true
L["Sound for guild whispers."] = true
L["Friend Whisper"] = true
L["Sound for friend whispers."] = true

-- History Group
L["History"] = true
L["Saved History Per Player"] = true
L["Days To Keep"] = true
L["Number of days messages will be kept per player (When set to 0, messages will be kept only for the session)."] = true
L["Maximum To Keep"] = true
L["Maximum number of messages to keep per player."] = true
L["Minimum To Always Keep"] = true
L["Minimum number of messages to always keep per player (*WARNING* If used, be sure to manually delete player history that you do not need)."] = true
L["Clear"] = true
L["Clears player and message history."] = true
L["Are you sure you want to clear the history?"] = true

-- Miscellaneous Group
L["Miscellaneous"] = true
L["BattleTag Notify"] = true
L["Automatic BattleTag notification to players that have never setup a BattleTag (Helps save their history)."] = true
L["Update In Combat"] = true
L["Update status in combat."] = true
L["Whisper Sticky"] = true
L["Do NOT allow the Enter Key to open Whispers (Keeps missed message count correct)."] = true
L["Ignore DBM"] = true
L["Ignore DBM auto reply whispers."] = true

-- In Option Code
L["Option table now loaded into memory"] = true

-- In Core Code
L["SoDWhisper: Please Set Up A BattleTag At Battle.net"] = true
L["Must be 1 - 12 characters in length"] = true
L["Copy"] = true
L["View"] = true
L["Search:"] = true
L["Enter"] = true
L["Reset"] = true
L["Display Name For:"] = true

------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------- SoDWhisper Module Options --------------------------------------------------------------------
L["Modules"] = true
L["Enable"] = true

------------------------------------------------------------- EditBoxPlugin
-- Appearance Group
L["Title Scale"] = true
L["Message Sort"] = true
L["Show entries from old to new on the message panel for the EditBox."] = true
L["Hide In Combat"] = true

-- Position Group
L["Position"] = true
L["Lock"] = true
L["Locks the panel."] = true
L["Grow Up"] = true
L["The panel will grow up from the set position."] = true
L["Anchor"] = true
L["Snap To Inputbox"] = true
L["Makes the panel stick to the inputbox."] = true
L["Snap Spacing"] = true
L["Space between inputbox and message history pane."] = true
L["Reset Position"] = true
L["Reset the position of the panel."] = true

-- In EditboxPlugin code
L["Editbox Plugin"] = true
L["This plugin will show your current conversation when you are sending a whisper to someone."] = true

------------------------------------------------------------- LDB/Minimap Plugin
-- Icon Group
L["Icon"] = true
L["Hide Minimap Icon"] = true
L["Broker2FuBar Options"] = true
L["Open the Broker2FuBar options panel."] = true
L["Change Icon"] = true
L["Change icon while there is an unchecked messages."] = true
L["Show Online Count"] = true
L["Show online count in LDB text (ex. 2Friends | 4Guild online)."] = true

-- Appearance Group
L["Max Tooltip Height"] = true
L["Max height of tooltip before scrolling enables."] = true
L["Tooltip Spacing"] = true
L["Space between tooltips."] = true
L["Format Tooltip"] = true
L["Set background and border of tooltip."] = true
L["Scale"] = true

-- Messages Group
L["Messages"] = true
L["Message history for the LDB/Minimap tooltip."] = true
L["Hide Message Panel"] = true
L["Hide message history panel and hover over missed message checking for LDB/Minimap tooltip."] = true
L["Panel Width"] = true
L["Panel Width of message history for LDB/Minimap tooltip."] = true
L["Show entries from old to new on the message panel for the LDB/Minimap Plugin."] = true

-- In LDB/Minimap Plugin code
L["LDB/Minimap Plugin"] = true
L["Session"] = true
L["Hour"] = true
L["Day"] = true
L["Week"] = true
L["All"] = true
L["Time"] = true
L["Name"] = true
L["Online"] = true
L["TimeframeTitle"] = "Timeframe"
L["Timeframe"] = true
L["Sort by"] = true
L["Other"] = true
L["Guild"] = true
L["Friends"] = true
L["Quickly view information from the minimap or type of LDB display."] = true