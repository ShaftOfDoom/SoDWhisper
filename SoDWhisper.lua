-- AddOn nameSpace
local SoDWhisper = LibStub("AceAddon-3.0"):NewAddon("SoDWhisper", "AceConsole-3.0", "AceHook-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceBucket-3.0", "LibWho-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("SoDWhisper")
SoDWhisper.L = L
local LSM = LibStub("LibSharedMedia-3.0")
SoDWhisper.LSM = LSM

-- UpValue
local type = _G.type
local time = _G.time
local date = _G.date
local select = _G.select
local pairs = _G.pairs
local string_find = _G.string.find
local string_format = _G.string.format
local string_match = _G.string.match
local string_sub = _G.string.sub
local string_gsub = _G.string.gsub
local string_split = _G.string.split
local table_insert = _G.table.insert
local table_remove = _G.table.remove
local wipe = _G.wipe


																					-- https://wowpedia.fandom.com/wiki/World_of_Warcraft_API#Friends
-- gameAccountInfo = C_BattleNet.GetGameAccountInfoByID(id)
                -- = C_BattleNet.GetGameAccountInfoByGUID(guid)
                -- = C_BattleNet.GetFriendGameAccountInfo(friendIndex, accountIndex)   https://wowpedia.fandom.com/wiki/API_C_BattleNet.GetGameAccountInfoByID

-- accountInfo = C_BattleNet.GetAccountInfoByID(id [, wowAccountGUID])
            -- = C_BattleNet.GetAccountInfoByGUID(guid)
            -- = C_BattleNet.GetFriendAccountInfo(friendIndex [, wowAccountGUID])      https://wowpedia.fandom.com/wiki/API_C_BattleNet.GetAccountInfoByID


-- LSM Register
LSM:Register("sound", "SoDW_IM", "Interface\\AddOns\\SoDWhisper\\MediaFiles\\Sound-SoDW_IM.ogg")

-- Constants
local BN_WHO = 11								-- Timer for who update for BN toons
local OTHER_WHO = -5								-- Timer for who update for other players
local LINK_TYPES = {							-- HyperLink information
	item = true, enchant = true, 
	spell = true, quest = true, 
	unit = true, talent = true, 
	achievement = true, glyph = true
}
SoDWhisper.LINK_TYPES = LINK_TYPES

-- Frames
local Frame_ChangeDisplayName					-- Frame for Change Display Name
local Frame_Log									-- Frame for Log (View Message History)

-- Tables
local ChatHistoryTB = {} 						-- Temp Build Chat History (SoDWhisper:GetChatHistory)
local LogFChatHistoryTB = {}					-- Temp LogFrame Build Chat History (SoDWhisper:ShowLogFrame)
local LocalClassesTB = {}						-- Class types
local LocalCitiesTB = {}						-- Major cities
local NoBattleNetTB = {}						-- Caught players with no Battle-tags
local ConnectedRealmsTB	= {}					-- Connected realms or only the player's realm

-- High Variables
SoDWhisper.player = {}							-- Information about self
SoDWhisper.lastSender = nil						-- Last incoming/outgoing whisper player (EditboxPlugin)
SoDWhisper.lastSenderPath = nil					-- Last incoming/outgoing path for player (EditboxPlugin)
SoDWhisper.sessionStart = 0						-- Start time for timeFrame1
SoDWhisper.timeframe = 1						-- Selected timeFrame

-- Variables
local dbg, dbr, db								-- SoDWhisper.db.global, SoDWhisper.db.factionrealm, SoDWhisper.db.profile
local guildTimer, guildRosterEvent				-- Timer & Event for Guild update
local onlineGuildNum							-- On-line guild members count
local onlineBNFriends							-- On-line BN friends count
local onlineRegFriends							-- On-line regular friends count

local defaults = {
	profile = {
		modules = {
			['*'] = true,
		},
		-- Appearance
		entriesShow = 15,						-- Number of entries shown in panels
		msgMaxHeight = 199,						-- Maximum Massage panel height for scrolling
		bgColor = {0,0,0,1},					-- Background colour
		bgTexture = "Solid",					-- Background texture
		borderColor = {.5,.5,.5,1},				-- Border colour
		borderTexture = "Blizzard Tooltip",		-- Border texture
		frameLevelCF = 10,						-- Frame level for Create Frames function
		frameStrataCF = "2HIGH",				-- Frame strata for Create Frames function
		colorIncoming = {1,.5,1},				-- Incoming whisper colour
		colorOutgoing = {.73,.73,1},			-- Outgoing whisper colour
		fontFace = "Arial Narrow",				-- Font face
		fontSize = 15,							-- Font size
		timeFormat = "3%H:%M",					-- TimeStamp format
		timeColor = {.5,.5,.5,.5},				-- TimeStamp colour
		-- Name
		realIDName = "FIRST",					-- RealID display format
		colorClassT = true,						-- Colour toon name by class
		colorClassBN = true,					-- Colour BN name by class
		-- Sound
		enableSound = true,						-- Sound enable/disable
		soundChannel = "1Master",				-- Outgoing sound channel
		otherWhispSound = "SoDW_IM",			-- Sound for other whispers
		guildWhispSound = "SoDW_IM",			-- Sound for guild whispers
		friendWhispSound = "SoDW_IM",			-- Sound for friend whispers
		-- History
		historyDays = 7,						-- Number of days to store history
		historyMax = 150,						-- Maximum number of messages to keep per player
		historyMin = 0,							-- Minimum number of messages to always keep per player
		-- Misc
		BTNotify = true,						-- Notify RealID players that have no Battle-tag
		combatUpdate = true,					-- Update in combat
		inputSticky = true,						-- Enter key sticky
		ignoreDBM = true,						-- Ignore incoming DBM replies
	},
	factionrealm = {
		chatHistory = {},
	},
	global = {
		chatHistory = {},
		--tempCityList = {},
	},
}

--**********************************************************************************************************************************************************
-------------------------------------------------------------------- Tools
--**********************************************************************************************************************************************************

local function LF_GetStatusicon(name, path, size)
	if not name or not path or not path.chatHistory[name] or not path.chatHistory[name].status then return "" end
	local t
	if string_find(path.chatHistory[name].status, "<AFK>") then
		t = "|TInterface\\FriendsFrame\\StatusIcon-Away:"..size.."|t"
	elseif string_find(path.chatHistory[name].status, "<DND>") then
		t = "|TInterface\\FriendsFrame\\StatusIcon-DnD:"..size.."|t"
	end
	if string_find(path.chatHistory[name].status, "<M>") then
		t = t and "|TInterface\\ChatFrame\\UI-ChatIcon-ArmoryChat:"..size.."|t"..t or "|TInterface\\ChatFrame\\UI-ChatIcon-ArmoryChat:"..size.."|t"
	end
	return t or ""
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

local function LF_GetGameIcon(client, size)
	if not client then return "" end
	if client == _G.BNET_CLIENT_SC2 then
		return "|TInterface\\FriendsFrame\\Battlenet-Sc2icon:"..size.."|t"
	elseif client == _G.BNET_CLIENT_D3 then
		return "|TInterface\\FriendsFrame\\Battlenet-D3icon:"..size.."|t"
	elseif client == _G.BNET_CLIENT_WTCG then
		return "|TInterface\\FriendsFrame\\Battlenet-WTCGicon:"..size.."|t"
	elseif client == _G.BNET_CLIENT_HEROES then
		return "|TInterface\\FriendsFrame\\Battlenet-HotSicon:"..size.."|t"
	elseif client == _G.BNET_CLIENT_OVERWATCH then
		return "|TInterface\\FriendsFrame\\Battlenet-Overwatchicon:"..size.."|t"
	else
		return "|TInterface\\FriendsFrame\\Battlenet-Battleneticon:"..size.."|t"
	end
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:GetDisplayNameForTooltip(name, path, isBN, needToon, isEditBox, size)
	local plr = path.chatHistory[name]
	if isBN then
		if not needToon then
			if not isEditBox then
				return (plr.online and LF_GetStatusicon(name, path, size).."|c0000FAF6"..plr.displayName.."|r") or "|c00585858"..plr.displayName.."|r"
			else
				return (plr.online and LF_GetStatusicon(name, path, size).."|c0000FAF6["..plr.displayName.."]|r") or "|c00585858["..plr.displayName.."]|r"
			end
		else
			if not plr.online then 
				return "|c00585858-|r" 
			end
			-- if (plr.displayName == "Narilka") then
				-- print(plr.client)
				-- print(plr.online)
				-- print(plr.toon)
				-- print(plr.realm)
			-- end
			if plr.toon and plr.client and plr.client == _G.BNET_CLIENT_WOW then
				local temp, _ = string_split("-", plr.toon)
				return SoDWhisper:FormatPlayerName(temp, name, path, true)
			else
				return ( (plr.client and isEditBox) and LF_GetGameIcon(plr.client, size) ) or "-"
			end
		end
	end
	return ( plr.online and LF_GetStatusicon(name, path, size)..SoDWhisper:FormatPlayerName(plr.displayName, name, path) ) or "|c00585858"..plr.displayName.."|r"
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:GetColoredLevel(level, online, BT, isEditBox)
	if not level then 
		return ( isEditBox and "" ) or ( online and "-" ) or "|c00585858-|r"
	end
	if not online then 
		if isEditBox then 
			return ( BT and "" ) or "|c00585858"..level..": |r" 
		else
			return ( BT and "|c00585858-|r" ) or "|c00585858"..level.."|r" 
		end
	end
	local color = _G.GetQuestDifficultyColor(level)
	return ( isEditBox and "|cff"..string_format("%02x%02x%02x", color.r*255, color.g*255, color.b*255)..level.."|r"..": " ) or "|cff"..string_format("%02x%02x%02x", color.r*255, color.g*255, color.b*255)..level.."|r"
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:GetZoneColor(zone, online)
	if not zone or zone == "" or zone == " " then 
		return ( online and "-" ) or "|c00585858-|r"
	end
	return ( LocalCitiesTB[zone] and "|c0000FF00"..zone.."|r" ) or "|c00FFFF00"..zone.."|r"
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:GetRealmForTooltip(name, isLDB, size, path)
	if not path.chatHistory[name].online then return "|c00585858-|r" end
	if not dbg.chatHistory[name] then
		local _, realmName = string_split("-", name)
		return ( SoDWhisper.player.faction == "Horde" and "|c00FF0000"..realmName.."|r" ) or ( SoDWhisper.player.faction == "Alliance" and "|c000099FF"..realmName.."|r" ) or realmName
	end
	
	local dbgH = dbg.chatHistory[name]
	if isLDB and dbgH.client ~= _G.BNET_CLIENT_WOW then 
		return LF_GetGameIcon(dbgH.client, size) 
	end
	if dbgH.realm then
		if dbgH.toon and dbgH.faction then
			return ( dbgH.faction == "Horde" and "|c00FF0000"..dbgH.realm.."|r" ) or ( dbgH.faction == "Alliance" and "|c000099FF"..dbgH.realm.."|r" ) or dbgH.realm
		else
			return dbgH.realm
		end
	end
	return "-"
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:FormatPlayerName(snd, plr, path, toon)
	if not snd then return end
	if not db.colorClassBN and path == dbg and snd ~= SoDWhisper.player.name and not toon then
		return "|c0000FAF6["..snd.."]|r"
	end
	
	local class
	if SoDWhisper.player.name == snd then 
		class = SoDWhisper.player.class
	elseif path.chatHistory[plr] and path.chatHistory[plr].class then
		class = path.chatHistory[plr].class
	end
	if not db.colorClassT or not class then 
		if path == dbg and snd ~= SoDWhisper.player.name and not toon then
			return "|c0000FAF6"..snd.."|r"
		end
		return "|cffffff00"..snd.."|r" 
	end
	
	local classColorTable = _G.RAID_CLASS_COLORS[class]
	if not classColorTable then
		if path == dbg and snd ~= SoDWhisper.player.name and not toon then
			return "|c0000FAF6"..snd.."|r"
		end
		return "|cffffff00"..snd.."|r"
	end
	return string_format("\124cff%.2x%.2x%.2x", classColorTable.r*255, classColorTable.g*255, classColorTable.b*255)..snd.."\124r" -- the format from whisp
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:GetOnlineCount()
	return (onlineRegFriends or 0) + (onlineBNFriends or 0), onlineGuildNum or 0
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:GetConnectedAnsOrName(name)
	local shortName, realm = string_split("-", name)
 	if ConnectedRealmsTB[realm] then
		return true, shortName
	end
	
	if realm then 
		shortName = shortName.."-"..string_sub(realm, 1, 3) 
	end
    return false, shortName
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Compare BattleTag 
function SoDWhisper:CompareBattleTag(incBT)
	if not incBT then return nil, nil, nil end
		
	for i = 1, _G.BNGetNumFriends() do		
		--presIDT, plrT, battletagT = BNGetFriendInfo(i)
		--accountInfo = BNGetFriendInfo(i)
		local acc = C_BattleNet.GetFriendAccountInfo(i)
		
		--print("incBT: "..tostring(incBT))
		--print("BattleTag: "..tostring(acc.battleTag))
		--print("AccountName: "..tostring(acc.accountName))
		--print("---")
		if acc.battleTag and acc.battleTag == incBT then
			return acc.bnetAccountID, acc.accountName, acc.battleTag
		elseif acc.accountName == incBT then
			return acc.bnetAccountID, acc.accountName, acc.battleTag
		end
	end
	return nil, nil, nil
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

local function LF_GetSetupClass(class)
	if not class then return nil end
	if LocalClassesTB[class] then
		class = LocalClassesTB[class]
	end
	return class
end

--**********************************************************************************************************************************************************
------------------------------------------------------------------ Who Query
--**********************************************************************************************************************************************************

local function LF_WhoUpdateServer(name, force, minutes)
	if not force then
		if dbr.chatHistory[name].timeWho > (time() - (minutes * 60)) then return end
	end
	if minutes == OTHER_WHO then return end --stop who backlog
	
	local sendName, realmName = string_split("-", name) 
	if realmName ~= SoDWhisper.player.realm then
		sendName = name 
	end
	
	local wholib = SoDWhisper
	dbr.chatHistory[name].timeWho = time()
	wholib:UserInfo(sendName, {queue = wholib.WHOLIB_QUEUE_QUIET, timeout = 0, flags = wholib.WHOLIB_FLAG_ALWAYS_CALLBACK, callback = 'ReturnedWhoData'})
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Get Who Data
function SoDWhisper:ReturnedWhoData(plrinfo)
	if not plrinfo then return end
	if not string_find(plrinfo.Name,"-") then 
		plrinfo.Name = plrinfo.Name.."-"..SoDWhisper.player.realm 
	end
	if not dbr.chatHistory[plrinfo.Name] then return end
	
	local dbrH = dbr.chatHistory[plrinfo.Name]
	dbrH.timeWho = time()
	if plrinfo.Online == true then
		dbrH.class, dbrH.online, dbrH.zone, dbrH.level, dbrH.guild = LF_GetSetupClass(plrinfo.Class), true, plrinfo.Zone, plrinfo.Level, plrinfo.Guild
		if plrinfo.Guild and dbrH.BT and dbg.chatHistory[dbrH.BT] then
			dbg.chatHistory[dbrH.BT].guild = plrinfo.Guild
		end
	elseif plrinfo.Online == false then
		dbrH.online, dbrH.zone = false, nil
	end
	
	-- LDB/Minimap Update
	SoDWhisper:SendMessage("SoDWhisper_MESSAGE")
end

--**********************************************************************************************************************************************************
------------------------------------------------------------ Update Other & Call
--**********************************************************************************************************************************************************

local function LF_SetupOtherToonEntry(plr, GUID, setup)
	local classType = ( GUID and LF_GetSetupClass(select(2, _G.GetPlayerInfoByGUID(GUID))) ) or LF_GetSetupClass(select(2, _G.UnitClass(plr)))
		
	local isConnected, toondisName = SoDWhisper:GetConnectedAnsOrName(plr)
	if not dbr.chatHistory[plr] then
		dbr.chatHistory[plr] = {message = {}, time = {}, incoming = {}, tells = 0, name = toondisName, displayName = toondisName, class = classType, online = true, timeWho = time()}
		
		if isConnected then 
			LF_WhoUpdateServer(plr, true, OTHER_WHO) 
		end
	elseif isConnected then 
		if GUID then 
			dbr.chatHistory[plr].online = true 
		end
		if not dbr.chatHistory[plr].typeGuild then
			local ttime, systime = time(), dbr.chatHistory[plr].time[#dbr.chatHistory[plr].time]
			
			if ( (SoDWhisper.timeframe == 1 and systime < SoDWhisper.sessionStart) or (SoDWhisper.timeframe == 2 and ttime - systime > 3600) or (SoDWhisper.timeframe == 3 and ttime - systime > 86400) or (SoDWhisper.timeframe == 4 and ttime - systime > 604800) ) then
			else 
				LF_WhoUpdateServer(plr, setup, OTHER_WHO) 
			end
		end
	elseif classType then
		dbr.chatHistory[plr].online, dbr.chatHistory[plr].level = true, _G.UnitLevel(plr)
	else
		dbr.chatHistory[plr].online = false
	end
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:UpdateOtherToons(setup)
	if not db.combatUpdate and _G.UnitAffectingCombat("player") and not setup then return end
	for i,v in pairs(dbr.chatHistory) do
		if v.time[1] and not v.typeBNtoon and not v.typeGuild and not v.typeRegFriend then
			LF_SetupOtherToonEntry(i, nil, setup)
		end
	end
end

--**********************************************************************************************************************************************************
---------------------------------------------------- Update Guild/Regular Friends & Call
--**********************************************************************************************************************************************************

local function LF_SetupGuildOrFriendEntry(index, isGuild, setup)
	local plr, levelNum, zoneName, isOnline, statusType, classType, isMobile
	
	if isGuild then
		plr, _, _, levelNum, _, zoneName, _, _, isOnline, statusType, classType, _, _, isMobile = GetGuildRosterInfo(index)
		if not plr then return end -- Some how one of these can be nil
		if not isOnline and not isMobile then
			if dbr.chatHistory[plr] then 
				dbr.chatHistory[plr].typeGuild = true
				if dbr.chatHistory[plr].online then
					dbr.chatHistory[plr].online, dbr.chatHistory[plr].status, dbr.chatHistory[plr].zone = false, nil, nil
				end
			end
			return
		end
	else
		--plr, levelNum, classType, zoneName, isOnline, statusType = GetFriendInfo(index)
		local tempInfo = C_FriendList.GetFriendInfoByIndex(index)
		plr, levelNum, classType, zoneName, isOnline, statusType = tempInfo.name, tempInfo.level, tempInfo.className, tempInfo.area, tempInfo.connected, tempInfo.afk --tempInfo.dnd --tempInfo.mobile
		if not plr then return end -- Some how one of these can be nil
		if not string_find(plr,"-") then 
			plr = plr.."-"..SoDWhisper.player.realm 
		end
		if not isOnline then
			if dbr.chatHistory[plr] then 
				dbr.chatHistory[plr].typeRegFriend = true
				if dbr.chatHistory[plr].online then 
					dbr.chatHistory[plr].online, dbr.chatHistory[plr].status, dbr.chatHistory[plr].zone = false, nil, nil
				end
			end
			return
		end
	end
	
	classType = LF_GetSetupClass(classType)
	statusType = statusType == 1 and "<AFK>" or statusType == 2 and "<DND>" or nil 
	if isMobile then 
		statusType = statusType and "<M>"..statusType or "<M>" 
	end
	
	if not dbr.chatHistory[plr] then
		local toondisName, _ = string_split("-", plr)
		dbr.chatHistory[plr] = {message = {}, time = {}, incoming = {}, tells = 0, name = toondisName, displayName = toondisName, timeWho = time()}
		setup = true
	end
	dbr.chatHistory[plr].online, dbr.chatHistory[plr].zone, dbr.chatHistory[plr].level, dbr.chatHistory[plr].status, dbr.chatHistory[plr].class = true, zoneName, levelNum, statusType, classType
	if isGuild then 
		dbr.chatHistory[plr].typeGuild = true
		dbr.chatHistory[plr].guild = SoDWhisper.player.guild
	else 
		dbr.chatHistory[plr].typeRegFriend = true 
		LF_WhoUpdateServer(plr, setup, BN_WHO) -- Get guild info
	end
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:GuildPlayerUpdate()
	if _G.IsInGuild() then 
		SoDWhisper:UpdateGuild()
	else
		for i, v in pairs(dbr.chatHistory) do
			if v.typeGuild then v.typeGuild = false end
		end
		if guildTimer then
			SoDWhisper:CancelTimer(guildTimer)
			guildTimer = nil
			SoDWhisper:UnregisterBucket(guildRosterEvent)
			guildRosterEvent = nil
		end
		onlineGuildNum = 0
		SoDWhisper:SendMessage("SoDWhisper_MESSAGE")
	end
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:UpdateGuild(setup)
	if not db.combatUpdate and _G.UnitAffectingCombat("player") and not setup then return end
	if _G.IsInGuild() then
		if not guildTimer then
			guildRosterEvent = SoDWhisper:RegisterBucketEvent({"GUILD_ROSTER_UPDATE"}, 5, SoDWhisper.UpdateGuild)
			C_GuildInfo.GuildRoster()
			guildTimer = SoDWhisper:ScheduleRepeatingTimer("GuildRosterUpdater", 35)
		end
		
		SoDWhisper.player.guild = _G.GetGuildInfo("player")
		for i, v in pairs(dbr.chatHistory) do
			if v.typeGuild then v.typeGuild = false end
		end
		
		local numAll
		numAll, _, onlineGuildNum  = _G.GetNumGuildMembers()
		for i = 1, numAll do
			LF_SetupGuildOrFriendEntry(i, true)
		end
		
		if not setup then 
			SoDWhisper:SendMessage("SoDWhisper_MESSAGE") 
		end
	end
end

function SoDWhisper:GuildRosterUpdater()
	C_GuildInfo.GuildRoster()
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:UpdateRegFriends(setup)
	if not db.combatUpdate and _G.UnitAffectingCombat("player") and not setup then return end
	for i,v in pairs(dbr.chatHistory) do
		if v.typeRegFriend then v.typeRegFriend = false end
	end
	
	local numAll
	numAll = C_FriendList.GetNumFriends()
    for i = 1, numAll do 
      LF_SetupGuildOrFriendEntry(i, nil, setup)
    end
	
	if not setup then 
		SoDWhisper:SendMessage("SoDWhisper_MESSAGE") 
	end
end

--**********************************************************************************************************************************************************
------------------------------------------------------ Update Battle-Net Friends & Call
--**********************************************************************************************************************************************************

local function LF_SetupBNEntry(BNETID, returnT, setup, index)
	local presID, plr, battleTag, isBattletagFriend, clientType, isOnline, isAFK, isDND, disName, noBattletag, statusType, toonName, realmName, factionT, classType, zoneName, levelNum
	
	if BNETID then 
		--presID, plr, battleTag, isBattletagFriend, _, _, clientType, isOnline, _, isAFK, isDND = BNGetFriendInfoByID(BNETID)
		local acc = C_BattleNet.GetAccountInfoByID(BNETID)
		local game = acc.gameAccountInfo
		presID, plr, battleTag, isBattletagFriend, clientType, isOnline, isAFK, isDND = acc.bnetAccountID, acc.accountName, acc.battleTag, acc.isBattleTagFriend, game.clientProgram, game.isOnline, acc.isAFK, acc.isDND
		toonName, realmName, factionT, classType, zoneName, levelNum = game.characterName, game.realmName, game.factionName, game.className, game.areaName, game.characterLevel
	else 
		--presID, plr, battleTag, isBattletagFriend, _, _, clientType, isOnline, _, isAFK, isDND = BNGetFriendInfo(index) 
		local acc = C_BattleNet.GetFriendAccountInfo(index)
		local game = acc.gameAccountInfo
		presID, plr, battleTag, isBattletagFriend, clientType, isOnline, isAFK, isDND = acc.bnetAccountID, acc.accountName, acc.battleTag, acc.isBattleTagFriend, game.clientProgram, game.isOnline, acc.isAFK, acc.isDND
		toonName, realmName, factionT, classType, zoneName, levelNum = game.characterName, game.realmName, game.factionName, game.className, game.areaName, game.characterLevel
	end
	if not plr then return end
	
	if not isBattletagFriend then
		disName = ( db.realIDName == "FIRST" and string_gsub(plr, "|Kf", "|Kg") ) or ( db.realIDName == "LAST" and string_gsub(plr, "|Kf", "|Ks") ) or plr
		if not battleTag then 
			battleTag, noBattletag = plr, true
		end
	else 
		if not battleTag then return end -- Some how this can be nil, very rare!!
		disName, _ = string_split("#", battleTag) 
	end
	
	-- Fix RealID names, Crash, and self on different player login
	if setup and dbg.chatHistory[battleTag] then
		if not dbg.chatHistory[battleTag].changed then 
			dbg.chatHistory[battleTag].displayName = disName 
		end
	end
	
	if not isOnline then
		if dbg.chatHistory[battleTag] then 
			dbg.chatHistory[battleTag].delCheck = true
			if dbg.chatHistory[battleTag].online then 
				dbg.chatHistory[battleTag].online, dbg.chatHistory[battleTag].status, dbg.chatHistory[battleTag].zone, dbg.chatHistory[battleTag].guild, dbg.chatHistory[battleTag].faction, 
						dbg.chatHistory[battleTag].realm, dbg.chatHistory[battleTag].toon, dbg.chatHistory[battleTag].class, dbg.chatHistory[battleTag].level = 
						false, nil, nil, nil, nil, nil, nil, nil, nil
			end
		end
		return
	end
	
	statusType = isAFK and "<AFK>" or isDND and "<DND>" or nil 
	
	if not dbg.chatHistory[battleTag] then 
		dbg.chatHistory[battleTag] = {message = {}, time = {}, incoming = {}, tells = 0} 
	end
	local dbgH = dbg.chatHistory[battleTag]
	dbgH.name, dbgH.pID, dbgH.client, dbgH.online, dbgH.status, dbgH.BT, dbgH.delCheck = disName, presID, clientType, isOnline, statusType, battleTag, true
	if not dbgH.changed then 
		dbgH.displayName = disName 
	end
	
	
	--local found
	--for i = 1, C_BattleNet.GetFriendGameAccountInfo(index or BNGetFriendIndex(presID)) do
		--local _, toonName, clientToonType, realmName, _, factionT, _, classType, _, zoneName, levelNum = C_BattleNet.GetFriendGameAccountInfo(index or BNGetFriendIndex(presID), i)
		--local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(index or BNGetFriendIndex(presID), i)
		--local toonName, clientToonType, realmName, factionT, classType, zoneName, levelNum = gameAccountInfo.characterName, gameAccountInfo.clientProgram, gameAccountInfo.realmName, gameAccountInfo.factionName, gameAccountInfo.className, gameAccountInfo.areaName, gameAccountInfo.characterLevel
		
		--if toonName and clientToonType == BNET_CLIENT_WOW then
		if toonName and clientType == _G.BNET_CLIENT_WOW then
			classType = LF_GetSetupClass(classType)
			if realmName then toonName = toonName.."-"..realmName end 
			
			--if not found then 
				dbgH.toon, dbgH.client, dbgH.realm, dbgH.faction, dbgH.class, dbgH.zone, dbgH.level = toonName, clientType, realmName, factionT, classType, zoneName, levelNum 
			--end
			
			-- Setup Character of BN account
			if factionT == SoDWhisper.player.faction then
				local isConnected, toondisName = SoDWhisper:GetConnectedAnsOrName(toonName)
				if isConnected or dbr.chatHistory[toonName] then 
					if not dbr.chatHistory[toonName] then
						dbr.chatHistory[toonName] = {message = {}, time = {}, incoming = {}, tells = 0, name = toondisName, displayName = toondisName, timeWho = time()}		
						setup = true
					end
					
					local dbrH = dbr.chatHistory[toonName]
					dbrH.BT, dbrH.online, dbrH.zone, dbrH.level, dbrH.typeBNtoon, dbrH.class = battleTag, isOnline, zoneName, levelNum, true, classType
					if not dbrH.typeGuild then 
						dbrH.status = statusType 
					end
					if dbrH.message[1] and dbg.chatHistory[battleTag] then
						for j=1, #dbrH.message do
							table_insert(dbgH.message, dbrH.message[j])
							table_insert(dbgH.incoming, dbrH.incoming[j])
							table_insert(dbgH.time, dbrH.time[j])
						end
						dbgH.tells = dbgH.tells + dbrH.tells
						dbrH.message, dbrH.incoming, dbrH.time, dbrH.tells = {}, {}, {}, 0
					end
					
					if isConnected and not found and not dbr.chatHistory[toonName].typeGuild then 
						--LF_WhoUpdateServer(toonName, setup, BN_WHO) 
					elseif isConnected and not found then 
						dbgH.guild = dbr.chatHistory[toonName].guild 
					end
				end
			end
			--found = true
		end
	--end
	--if not found then 
	--	dbgH.toon, dbgH.realm, dbgH.faction, dbgH.class, dbgH.zone, dbgH.level = nil, nil, nil, nil, nil, nil 
	--end
	if returnT then return battleTag, noBattletag end
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:UpdateBNDisconnected()
	for i,v in pairs(dbr.chatHistory) do
		if v.typeBNtoon or v.BT then 
			v.typeBNtoon, v.BT = false, nil
		end
	end
	for i,v in pairs(dbg.chatHistory) do
		if v.online then 
			v.online, v.status, v.zone, v.guild, v.faction, v.realm, v.toon, v.class, v.level = false, nil, nil, nil, nil, nil, nil, nil, nil
		end
	end
	onlineBNFriends = 0
	SoDWhisper:SendMessage("SoDWhisper_MESSAGE")
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:UpdateBNConnected()
	SoDWhisper:UpdateBNFriends(true)
	SoDWhisper:SendMessage("SoDWhisper_MESSAGE")
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:UpdateBNFriends(setup)
	if not db.combatUpdate and _G.UnitAffectingCombat("player") and not setup or not _G.BNFeaturesEnabledAndConnected() then return end
	for i,v in pairs(dbr.chatHistory) do
		if v.typeBNtoon or v.BT then 
			v.typeBNtoon, v.BT = false, nil
		end
	end
	if not setup then
		for i,v in pairs(dbg.chatHistory) do
			v.delCheck = false
		end
	end
	
	local numAll
	numAll, onlineBNFriends = _G.BNGetNumFriends()
	for i = 1, numAll do
		LF_SetupBNEntry(nil, nil, setup, i)
	end
	
	if not setup then
		for i,v in pairs(dbg.chatHistory) do
			if not v.delCheck and v.online then 
				v.online, v.status, v.zone, v.guild, v.faction, v.realm, v.toon, v.class, v.level = false, nil, nil, nil, nil, nil, nil, nil, nil
			end
		end
		SoDWhisper:SendMessage("SoDWhisper_MESSAGE")
	end
end

--**********************************************************************************************************************************************************
--------------------------------------------------------- Incoming/Outgoing & Calls
--**********************************************************************************************************************************************************

local function LF_UpdateChatHistory(msg, plr, incoming, BNETID, GUID)
	if not plr then return end
	
	-- Check for spam & cut off spaces after message
	if db.ignoreDBM and (string_sub(msg, 1,18) == "<Deadly Boss Mods>" or string_sub(msg, 1,5) == "<DBM>") then return end
	msg = string_gsub(msg, "%s+$", "")
	
	-- Check for realmName
	if not BNETID and not string_find(plr, "-") then 
		plr = plr.."-"..SoDWhisper.player.realm 
	end
	local battleTag, noBattletag, add, path, name
	
	-- Check if toon is a BN friend
	if not BNETID and dbr.chatHistory[plr] and dbr.chatHistory[plr].BT and _G.BNFeaturesEnabledAndConnected() then
		BNETID = SoDWhisper:CompareBattleTag(dbr.chatHistory[plr].BT)
		if not BNETID then
			dbr.chatHistory[plr].BT = nil
			dbr.typeBNtoon = false
		end
	end

	if BNETID then 
		battleTag, noBattletag = LF_SetupBNEntry(BNETID, true)
		path, name = dbg, battleTag
	else 
		if not dbr.chatHistory[plr] then
			LF_SetupOtherToonEntry(plr, GUID) 
		else
			add = true
		end
		path, name = dbr, plr
	end
	
	-- Set up tells for BN or for reg toon
	path.chatHistory[name].tells = ( not incoming and 0 ) or path.chatHistory[name].tells + 1
	
	-- Sound
	if incoming and db.enableSound then 
		local channel = string_gsub(db.soundChannel, "^%d", "")
		
		if path == dbg or path.chatHistory[name].typeBNtoon or path.chatHistory[name].typeRegFriend then
			local sound = LSM:Fetch('sound', db.friendWhispSound)
			_G.PlaySoundFile(sound, channel)
		elseif path.chatHistory[name].typeGuild then
			local sound = LSM:Fetch('sound', db.guildWhispSound)
			_G.PlaySoundFile(sound, channel)
		else
			local sound = LSM:Fetch('sound', db.otherWhispSound)
			_G.PlaySoundFile(sound, channel)
		end
	end
		
	-- LDB/Minimap assignment
	SoDWhisper.lastSender, SoDWhisper.lastSenderPath = name, path
	
	-- Insert message
	table_insert(path.chatHistory[name].message, msg)
	table_insert(path.chatHistory[name].time, time())
	table_insert(path.chatHistory[name].incoming, incoming)
	
	-- Call after time insert so who updates correctly
	if add then 
		LF_SetupOtherToonEntry(plr, GUID) 
	end
	
	-- Update modules
	SoDWhisper:SendMessage("SoDWhisper_MESSAGE") 
	SoDWhisper:SendMessage("SoDWhisper_UPDATE_EDITBOX")
	
	-- Report No battleTag
	if db.BTNotify and noBattletag and not NoBattleNetTB[battleTag] then
		NoBattleNetTB[battleTag] = true
		_G.BNSendWhisper(BNETID, L["SoDWhisper: Please Set Up A BattleTag At Battle.net"])
	end
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:ChatEventIncoming(msg, plr, _, _, _, _, _, _, _, _, _, GUID) 
	LF_UpdateChatHistory(msg, plr, true, nil, GUID)
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:ChatEventOutgoing(msg, plr, _, _, _, _, _, _, _, _, _, GUID) 
	LF_UpdateChatHistory(msg, plr, false, nil, GUID)
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:BNChatEventIncoming(msg, plr, _, _, _, _, _, _, _, _, _, _, presID)
	LF_UpdateChatHistory(msg, plr, true, presID)
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:BNChatEventOutgoing(msg, plr, _, _, _, _, _, _, _, _, _, _, presID)
	LF_UpdateChatHistory(msg, plr, false, presID)
end

--**********************************************************************************************************************************************************
--------------------------------------------------------------- Skin Frames
--**********************************************************************************************************************************************************

function SoDWhisper:SkinMyFrame(f, isLogFrame, isDisplayFrame)
	local fontT = LSM:Fetch("font", db.fontFace)
	local fontS = db.fontSize
	
	if f and not isLogFrame and not isDisplayFrame then
		f:SetFrameStrata(string_gsub(db.frameStrataCF, "^%d", ""))
		f:SetFrameLevel(db.frameLevelCF)
		
		f.sChild:SetFont(fontT, fontS)
		f.fontString:SetFont(fontT, fontS)
		
		local bg = LSM:Fetch("background", db.bgTexture, "Blizzard Tooltip")
		local ed = LSM:Fetch("border", db.borderTexture, "Blizzard Tooltip")
		f:SetBackdrop({
				bgFile = bg, tile = true, tileSize = 16,
				edgeFile = ed, edgeSize = 16,
				insets = {left = 3, right = 3, top = 3, bottom = 3},
		})
		local c,d = db.bgColor, db.borderColor
		f:SetBackdropColor(c[1], c[2], c[3], c[4])
		f:SetBackdropBorderColor(d[1], d[2], d[3], d[4])
	end
	
	if isLogFrame and Frame_Log then
		f = Frame_Log
		f.titleText:SetFont(fontT, 14)
		f.smf:SetFont(fontT, fontS)
		f.editBox:SetFont(fontT, fontS)
		f.fontString:SetFont(fontT, fontS)
		f.searchBox:SetFont(fontT, 14)
	end
	
	if isDisplayFrame and Frame_ChangeDisplayName then
		f = Frame_ChangeDisplayName
		f.titleText:SetFont(fontT, 14)
		f.titleSubText:SetFont(fontT, 14)
		f.inputBox:SetFont(fontT, 14)
	end
end

--**********************************************************************************************************************************************************
--------------------------------------------------------------- Build Chat History
--**********************************************************************************************************************************************************

-- Returns the hex value of the rgb
local function LF_HexColor(r, g, b)
	if type(r) == "table" then
		r, g, b = r[1], r[2], r[3]
	end
	return string_format("%02x%02x%02x", 255*r, 255*g, 255*b)
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Color the text
local function LF_Colorise(text, hexcolor)
	text = string_gsub(text, "(|c.-|H.-|r)", "|r%1|cff"..hexcolor)
	return "|cff"..hexcolor..text.."|r"
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

local function LF_FormatTimeStamp(t)
	if db.timeFormat == "1" then return "" end
	t = ( t < time() - 86400 and date("%d/%m-"..string_gsub(db.timeFormat, "^%d", ""), t) ) or date(string_gsub(db.timeFormat, "^%d", ""), t)
	return LF_Colorise("["..t.."]", LF_HexColor(db.timeColor)).." "
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Returns the combined messages (little code from Whisp)
local function LF_GetChatHistory(plr, entryMax, path, newToOld)
	if not path.chatHistory[plr] then return "" end
	local msg = ""
	if path.chatHistory[plr] then
		local pathH = path.chatHistory[plr]
		local n = #pathH.message
		
		local tempFTS, tempFPN, tempHex, tempColorMessage
		-- Generate conversation
		for i= (n > entryMax and n - entryMax + 1) or 1, n  do
			tempFTS = LF_FormatTimeStamp(pathH.time[i])
			tempFPN = SoDWhisper:FormatPlayerName( ( pathH.incoming[i] and pathH.displayName ) or SoDWhisper.player.name, plr, path)
			tempHex = LF_HexColor(pathH.incoming[i] and db.colorIncoming or db.colorOutgoing)
			tempColorMessage = LF_Colorise(pathH.message[i], tempHex)
			table_insert(ChatHistoryTB, tempFTS..tempFPN..": "..tempColorMessage)
		end
		
		-- Sort output
		for i = (newToOld and 1) or #ChatHistoryTB, (newToOld and #ChatHistoryTB) or 1, (newToOld and 1) or -1 do
			msg = msg..ChatHistoryTB[i]
			if (newToOld and i < #ChatHistoryTB) or (not newToOld and i > 1) then 
				msg = msg.."\n"
			end
		end
		wipe(ChatHistoryTB)
	end
	return msg
end

--**********************************************************************************************************************************************************
-------------------------------------------------------------- Create Reg Frames
--**********************************************************************************************************************************************************

function SoDWhisper:CreateMyFrame(name, width)
	local CreateFrame = _G.CreateFrame
	local fontT = LSM:Fetch("font", db.fontFace)
	local fontS = db.fontSize
	local bg = LSM:Fetch("background", db.bgTexture, "Blizzard Tooltip")
	local ed = LSM:Fetch("border", db.borderTexture, "Blizzard Tooltip")
	local c,d = db.bgColor, db.borderColor
	
	---------------------------------------------------- Frame1
	local f = CreateFrame("Frame", "SODW_CF_"..name.."FRAME1", _G.UIParent, "backdropTemplate")
	f:SetFrameStrata(string_gsub(db.frameStrataCF, "^%d", ""))
	f:SetFrameLevel(db.frameLevelCF)
	f:SetSize(width, 20)
	f:SetMinResize(200, 20)
	f.backdropInfo = {
			bgFile = bg, tile = true, tileSize = 16,
			edgeFile = ed, edgeSize = 16,
			insets = {left = 3, right = 3, top = 3, bottom = 3},
	}
	f:ApplyBackdrop()
	f:SetBackdropColor(c[1], c[2], c[3], c[4])
	f:SetBackdropBorderColor(d[1], d[2], d[3], d[4])
	
	---------------------------------------------------- ScrollFrame
	f.scroll = CreateFrame("ScrollFrame", "SODW_CF_"..name.."_SCROLL", f)
	f.scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -9)
	f.scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
	
	---------------------------------------------------- Slider
	f.slider = CreateFrame("Slider", "SODW_CF_"..name.."_SLIDER", f.scroll)
	f.slider:SetOrientation("VERTICAL")
	f.slider:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, 0)
	f.slider:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 0)
	f.slider:SetMinMaxValues(0, 1)
	f.slider:SetValueStep(1)
	f.slider:SetWidth(10)
	
	local texture = f.slider:CreateTexture(nil, "OVERLAY")
    texture:SetTexture("Interface\\AddOns\\SoDWhisper\\MediaFiles\\Icon-Scroll_Bar")
    texture:SetSize(20, 20)
	f.slider:SetThumbTexture(texture)
	
	f.slider:SetScript("OnValueChanged", function(self, value) 
			f.scroll:SetVerticalScroll(value)
	end)
	
	---------------------------------------------------- ScrollChild (EditBox)
	f.sChild = CreateFrame("EditBox", "SODW_CF_"..name.."_SCHILD", f)
	f.sChild:SetFrameLevel(f:GetFrameLevel() + 1)
	f.sChild:SetSize(10, 10)
	f.sChild:SetTextInsets(0, 1, 0, 1)
	f.sChild:SetMultiLine(true)
	f.sChild:SetAutoFocus(false)
	f.sChild:EnableMouse(false)
	f.sChild:SetFont(fontT, fontS)
	f.scroll:SetScrollChild(f.sChild)
	
	---------------------------------------------------- FontString (Measuring)
	f.fontString = f:CreateFontString("SODW_CF_"..name.."_FONTSTRING", "ARTWORK", "ChatFontNormal")
	f.fontString:SetJustifyH("LEFT")
	f.fontString:SetJustifyV("TOP")
	f.fontString:SetNonSpaceWrap(true)
	f.fontString:SetFont(fontT, fontS)
	
	----------------------------------------------------
	f:Hide()
	return f
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:UpdateMyFrame(f, plr, path, direction, ignore)
	local text = LF_GetChatHistory(plr, db.entriesShow, path, direction)
	f.fontString:SetText(text)
	f.sChild:SetText(text)
	
	local width = f.scroll:GetWidth() - 1
	f.fontString:SetWidth(width)
	f.sChild:SetWidth(width)
	
	local height = f.fontString:GetHeight() + 19 + 1
	f:SetHeight(height)
	
	local maxheight = db.msgMaxHeight
	local scale = f:GetScale()
	local topside = f:GetTop()
	local bottomside = f:GetBottom()
	local screensize = _G.UIParent:GetHeight() / scale
	local tipsize = (topside - bottomside)

	if bottomside < 0 or topside > screensize or (maxheight and tipsize > maxheight) then
		local shrink = (bottomside < 0 and (5 - bottomside) or 0) + (topside > screensize and (topside - screensize + 5) or 0)
		local fHeight = tipsize - shrink
		
		if maxheight and tipsize - shrink > maxheight then
			shrink = tipsize - maxheight
			fHeight = tipsize - shrink
		end
		f:SetHeight(fHeight)
		f.slider:SetMinMaxValues(0, shrink)
		f.slider:SetValue(( direction and shrink ) or 0)
		f.slider:Show()
		f.enableMouseWheel = true
	else
		f.slider:SetValue(0)
		f.slider:Hide()
		f.enableMouseWheel = false
	end
	
	f.fontString:SetText("")
	
	-- Update tells on event
	if not ignore and path.chatHistory[plr].tells > 0 then
		path.chatHistory[plr].tells = 0
		SoDWhisper:SendMessage("SoDWhisper_MESSAGE")
	end
end

--**********************************************************************************************************************************************************
---------------------------------------------------------------- Log Window
--**********************************************************************************************************************************************************

local function LF_CreateLogFrame()
	local CreateFrame = _G.CreateFrame
	local fontT = LSM:Fetch('font', db.fontFace)
	local fontS = db.fontSize
	
	---------------------------------------------------- Frame1
	local f = CreateFrame("Frame", "SODW_LF_FRAME1", _G.UIParent, "backdropTemplate")
	Frame_Log = f
	f:SetPoint("CENTER", _G.UIParent, "CENTER")
	f:SetFrameStrata("HIGH")
	f:SetFrameLevel(20)
	f:SetSize(800, 510)
	f:EnableMouse(true)
	f:SetClampedToScreen(true)
	
	f:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
			insets = {left = 3, right = 3, top = 3, bottom = 3},
	})
	f:SetBackdropColor(0, 0, 0, 1)
	f:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
	
	---------------------------------------------------- Move Frame
	--local titleRegion = f:CreateTitleRegion()
	
	local titleRegion = CreateFrame('Frame', 'dragframesodwhisper', f, "backdropTemplate")
	titleRegion:SetFrameLevel(f:GetFrameLevel() + 1)
	titleRegion:EnableMouse(true)
	titleRegion:SetMovable(true)
	titleRegion:RegisterForDrag("LeftButton")
	titleRegion:SetClampedToScreen(true)
	
	-- titleRegion:SetBackdrop{
			-- bgFile='Interface\\DialogFrame\\UI-DialogBox-Background' ,
			-- edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',
			-- tile = true,
			-- insets = {left = 11, right = 12, top = 12, bottom = 11},
			-- tileSize = 32,
			-- edgeSize = 32,
		-- }
	
	Frame_Log.titleRegion = titleRegion
	titleRegion:SetPoint("BOTTOMLEFT", f, -5, -2)
	titleRegion:SetPoint("TOPRIGHT", f, 5, 2)
	
	titleRegion:SetScript('OnDragStart', function() 
				f:SetMovable(true) 
				f:StartMoving()
	end)
	titleRegion:SetScript('OnDragStop', function() 
				f:StopMovingOrSizing() 
				f:SetMovable(false) 
	end)
	
	---------------------------------------------------- Title Text
	local titleText = f:CreateFontString("SODW_LF_TITLETEXT", "ARTWORK", "ChatFontNormal")
	Frame_Log.titleText = titleText
	titleText:SetPoint("TOP", f, "TOP", 0, -15)
	titleText:SetJustifyV("TOP")
	titleText:SetFont(fontT, 14)

	---------------------------------------------------- Close Button
	local closeBn = CreateFrame("Button", nil, f, "UIPanelCloseButton", "backdropTemplate")
	closeBn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -3, -3)
	closeBn:SetFrameLevel(f:GetFrameLevel() + 2)
	Frame_Log.closeBn = closeBn
	
	closeBn:SetScript("OnMouseDown", function(self)
			self:GetParent().smf:Clear()
			self:GetParent():Hide()
	end)
	
	---------------------------------------------------- Frame2
	local f2 = CreateFrame("Frame", "SODW_LF_FRAME2", f, "backdropTemplate")
	Frame_Log.f2 = f2
	f2:SetFrameLevel(f:GetFrameLevel() + 4)
	f2:SetPoint("CENTER", f, "CENTER")
	f2:SetSize(725, 425) 
	f2:EnableMouse(true)
	
	f2:SetBackdrop({
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
			insets = {left = 3, right = 3, top = 3, bottom = 3},
	})
	f2:SetBackdropColor(0, 0, 0, 1)
	f2:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
	
	---------------------------------------------------- ScrollingMessageFrame
	local smf = CreateFrame("ScrollingMessageFrame", "SODW_LF_SMF", f, "backdropTemplate")
	Frame_Log.smf = smf
	smf:SetPoint("CENTER", f2, "CENTER")
	smf:SetFrameLevel(f2:GetFrameLevel() + 1)
	smf:SetSize(705, 405)
	smf:SetHyperlinksEnabled(true)
	smf:SetFont(fontT, fontS)
	smf:SetFading(false)
	smf:SetMaxLines(999)
	smf:SetJustifyH("LEFT")
    smf:EnableMouse(true)
    smf:EnableMouseWheel(true)
	smf:SetTextCopyable(true)
	
	smf:SetScript("OnHyperlinkEnter", function(_, link)
			local t = string_match(link, "^([^:]+)")
			if t and LINK_TYPES[t] then
				_G.GameTooltip:SetOwner(_G.UIParent, "ANCHOR_CURSOR")
				_G.GameTooltip:SetHyperlink(link)
				_G.GameTooltip:Show()
			end
	end)
	smf:SetScript("OnHyperlinkLeave", _G.GameTooltip_Hide)
	smf:SetScript("OnHyperlinkClick", _G.ChatFrame_OnHyperlinkShow)
	
	smf:SetScript("OnMouseWheel", function(self, delta)
			if delta > 0 and not self:AtTop() then
				if _G.IsControlKeyDown() then
					while not self:AtTop() do
						self:ScrollUp()
					end
				elseif _G.IsShiftKeyDown() then
					self:PageUp()
				else
					self:ScrollUp()
					self:ScrollUp()
					self:ScrollUp()
				end
			elseif delta < 0 and not self:AtBottom() then
				if _G.IsControlKeyDown() then
					self:ScrollToBottom()
				elseif _G.IsShiftKeyDown() then
					self:PageDown()
				else
					self:ScrollDown()
					self:ScrollDown()
					self:ScrollDown()
				end
			end
			if _G.GameTooltip:IsShown() then
				_G.GameTooltip_Hide()
			end
	end)
	smf:SetScript("OnShow", function(self)
		local f = self:GetParent()
		if f.noMessage or self:GetMaxLines(maxLines) == self:GetNumVisibleLines() then
			f.slider:Hide()
		else
			f.slider:Show()
		end
		--f.editBox:SetText("")
		--f.editBox:ClearFocus()
		--f.editBox:Hide()
	end)
	
	---------------------------------------------------- Slider
	local slider = CreateFrame("Slider", "SODW_LF_SLIDER", f, "backdropTemplate")
	Frame_Log.slider = slider
	slider:SetOrientation("VERTICAL")
	slider:SetPoint("TOPRIGHT", f2, "TOPRIGHT", -4, 0)
	slider:SetPoint("BOTTOMRIGHT", f2, "BOTTOMRIGHT", -4, 0)
	slider:SetFrameLevel(smf:GetFrameLevel() + 1)
	slider:SetMinMaxValues(0, 20)
	slider:SetValueStep(1)
	slider:SetWidth(10)
	
	bnTexture = slider:CreateTexture(nil, "OVERLAY")
    bnTexture:SetTexture("Interface\\AddOns\\SoDWhisper\\MediaFiles\\Icon-Scroll_Bar")
    bnTexture:SetSize(20, 20)
	slider:SetThumbTexture(bnTexture)
	
	---------------------------------------------------- Text View EditBox (copy functionality)	
	-- local f3 = CreateFrame("Frame", "SODW_LF_FRAME3", f, "backdropTemplate")
	-- Frame_Log.f3 = f3
	-- f3:SetFrameLevel(f2:GetFrameLevel() + 5)
	-- f3:SetPoint("BOTTOM", f2, "BOTTOM", 0, 10)
	-- f3:SetSize(705, 405)
	
	-- local fontString = f3:CreateFontString("SODW_LF_EditBox_FONTSTRING", "ARTWORK", "ChatFontNormal")
	-- Frame_Log.fontString = fontString
	-- fontString:SetJustifyH("LEFT")
	-- fontString:SetJustifyV("TOP")
	-- fontString:SetNonSpaceWrap(true)
	-- fontString:SetFont(fontT, fontS)
	-- fontString:SetWidth(705)
	
	-- local scroll = CreateFrame("ScrollFrame", "SODW_LF_EditBox_SCROLL", f, "backdropTemplate")
	-- Frame_Log.scroll = scroll
	-- scroll:SetFrameLevel(f3:GetFrameLevel() + 1)
	-- scroll:SetPoint("TOPLEFT", f3, "TOPLEFT", 0, 0)
	-- scroll:SetPoint("BOTTOM", f3, "BOTTOM", 0, 0)
	
	-- local editBox = CreateFrame("EditBox", "SODW_LF_EDITBOX", f, "backdropTemplate")
	-- Frame_Log.editBox = editBox
	-- editBox:SetFrameLevel(scroll:GetFrameLevel() + 1)
	-- editBox:SetWidth(705)
	-- editBox:SetTextInsets(0, 0, 0, 0)
	-- editBox:SetMultiLine(true)
	-- editBox:SetAutoFocus(false)
	-- editBox:SetFont(fontT, fontS)
	-- editBox:SetJustifyH("LEFT")
	-- editBox:SetJustifyV("BOTTOM")
	-- scroll:SetScrollChild(editBox)
	
	-- editBox:SetScript("OnEscapePressed", function(self) 
			-- self:ClearFocus()
	-- end)
	
	-- ---------------------------------------------------- EditBox Button
	-- local editBoxBn = CreateFrame("Button", nil, f, "backdropTemplate")
	-- Frame_Log.editBoxBn = editBoxBn
	-- editBoxBn:SetFrameLevel(f2:GetFrameLevel() - 1)
	-- editBoxBn:SetPoint("TOPRIGHT", f2, "BOTTOMRIGHT", -10, 4)
	-- editBoxBn:SetSize(75, 28)
	-- editBoxBn:SetNormalFontObject("GameFontNormal")
	-- editBoxBn:SetText(L["Copy"])
	
	-- local bnTexture = editBoxBn:CreateTexture()
	-- bnTexture:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab")
	-- bnTexture:SetTexCoord(0,1,0,.55)
	-- bnTexture:SetAllPoints()	
	-- editBoxBn:SetNormalTexture(bnTexture)
	
	-- bnTexture = editBoxBn:CreateTexture()
	-- bnTexture:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-InActiveTab")
	-- bnTexture:SetTexCoord(0,1,0,.85)
	-- bnTexture:SetAllPoints()
	-- editBoxBn:SetDisabledTexture(bnTexture)
	
	-- editBoxBn:SetScript("OnMouseDown", function(self)
			-- local f = self:GetParent()
			-- if f.noMessage then return end
			-- local msg = ""
			-- local maxNum = 0
			-- local tempMaxLines = f.smf:GetMaxLines()
			-- local tempNumVisibleLines = f.smf:GetNumVisibleLines()
			-- local tempScrollOffset = f.smf:GetScrollOffset()
			
			-- if tempScrollOffset == 0 then
				-- maxNum = tempNumVisibleLines + (tempScrollOffset - tempMaxLines) - 1
				-- for i = tempMaxLines, maxNum + tempScrollOffset, -1 do
					-- print(i)
					-- if select(1, f.smf:GetMessageInfo(i)) then
						-- print(select(1, f.smf:GetMessageInfo(i)))
						-- msg = select(1, f.smf:GetMessageInfo(i))..msg
						-- if i > maxNum then
							-- msg = "\n"..msg
						-- end
					-- end
				-- end
			-- else
				-- print("here")
				-- maxNum = tempNumVisibleLines + (tempScrollOffset - tempMaxLines) - 1
				-- for i = tempMaxLines, maxNum + tempScrollOffset, -1 do
					-- print(i)
					-- if select(1, f.smf:GetMessageInfo(i)) then
						-- print(select(1, f.smf:GetMessageInfo(i)))
						-- msg = select(1, f.smf:GetMessageInfo(i))..msg
						-- if i > maxNum then
							-- msg = "\n"..msg
						-- end
					-- end
				-- end
			-- end
			-- -- if f.smf:GetNumLinesDisplayed() then
				-- -- print("GetNumLinesDisplayed: "..f.smf:GetNumLinesDisplayed())
			-- -- else
				-- -- print("GetNumLinesDisplayed: nil")
			-- -- end
			-- print("GetPagingScrollAmount: "..f.smf:GetPagingScrollAmount())
			-- print("IsTextCopyable: "..tostring(f.smf:IsTextCopyable()))
			-- print("CalculateNumVisibleLines: "..f.smf:CalculateNumVisibleLines())
			-- print("AtBottom: "..tostring(f.smf:AtBottom()))
			-- print("AtTop: "..tostring(f.smf:AtTop()))
			-- print("GetScrollOffset: "..tempScrollOffset)
			-- print("GetMaxScrollRange: "..f.smf:GetMaxScrollRange())
			-- print("var maxNum: "..maxNum)
			-- print("Get the maximum number of lines the frame can display")
			-- print("GetMaxLines: "..tempMaxLines)
			-- print("GetNumMessages: "..f.smf:GetNumMessages())
			-- print("GetNumVisibleLines: "..tempNumVisibleLines)
			-- print("-----")
			-- msg = string_gsub(msg, "|c[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]", "")
			-- msg = string_gsub(msg, "|r", "")
			-- f.editBox:SetText(msg)
			
			-- f.fontString:SetText(msg)
			-- f.f3:SetHeight(f.fontString:GetHeight())
			
			-- f.slider:Hide()
			-- f.smf:Hide()
			-- f.smfBn:SetButtonState("DISABLED", lock)
			-- f.smfBn:SetAlpha(.5)
			-- f.editBoxBn:SetButtonState("NORMAL", unlock)
			-- f.editBoxBn:SetAlpha(1)
			-- f.editBox:Show()
	-- end)
	
	---------------------------------------------------- ScrollMessageFrame Button
	local smfBn = CreateFrame("Button", nil, f, "backdropTemplate")
	Frame_Log.smfBn = smfBn
	smfBn:SetFrameLevel(f2:GetFrameLevel() - 1)
	smfBn:SetPoint("RIGHT", editBoxBn, "LEFT", 6, 0)
	smfBn:SetSize(75, 28)
	smfBn:SetNormalFontObject("GameFontNormal")
	smfBn:SetText(L["View"])
	
	local bnTexture = smfBn:CreateTexture()
	bnTexture:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab")
	bnTexture:SetTexCoord(0,1,0,.55)
	bnTexture:SetAllPoints()
	smfBn:SetNormalTexture(bnTexture)
	
	bnTexture = smfBn:CreateTexture()
	bnTexture:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-InActiveTab")
	bnTexture:SetTexCoord(0,1,0,.85)
	bnTexture:SetAllPoints()
	smfBn:SetDisabledTexture(bnTexture)
	
	smfBn:SetScript("OnMouseDown", function(self)
			local f = self:GetParent()
			--f.editBox:ClearFocus()
			--f.editBox:SetText("")
			--f.editBox:Hide()
			f.smf:Show()
			--f.editBoxBn:SetAlpha(.5)
			--f.editBoxBn:SetButtonState("DISABLED", lock)
			f.smfBn:SetAlpha(1)
			f.smfBn:SetButtonState("NORMAL", unlock)
	end)
	
	local searchBox = CreateFrame("EditBox", "SODW_LF_SEARCH", f, "backdropTemplate")
	Frame_Log.searchBox = searchBox
	searchBox:SetPoint("TOPLEFT", f2, "BOTTOMLEFT", 0, -3)
	searchBox:SetFrameLevel(f2:GetFrameLevel() + 1)
	searchBox:SetSize(300, 30)
	searchBox:SetTextInsets(10, 10, 0, 0)
	searchBox:SetAutoFocus(false)
	searchBox:SetFont(fontT, 14)
	
	searchBox:SetBackdrop({
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
			insets = {left = 3, right = 3, top = 3, bottom = 3},
	})
	searchBox:SetBackdropColor(0, 0, 0, 1)
	searchBox:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
	
	searchBox:SetScript("OnEscapePressed", function(self)
			self:ClearFocus()
	end)
	f.searchBox:SetScript("OnEditFocusGained", function(self)
			local text = self:GetText()
			if text == L["Search:"] then
				self:SetText("")
				self:SetFocus()
			end
	end)
	
	local clearBn = CreateFrame("Button", nil, f, "backdropTemplate")
	clearBn:SetFrameLevel(f2:GetFrameLevel() + 1)
	Frame_Log.clearBn = clearBn
	clearBn:SetPoint("LEFT", searchBox, "RIGHT", 0, 0)
	clearBn:SetSize(75, 28.4)
	clearBn:SetNormalFontObject("GameFontNormal")
	clearBn:SetText(L["Reset"])
	
	local bnTexture = clearBn:CreateTexture()
	bnTexture:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
	bnTexture:SetTexCoord(0, 0.625, 0, 0.6875)
	bnTexture:SetAllPoints()	
	clearBn:SetNormalTexture(bnTexture)
	
	bnTexture = clearBn:CreateTexture()
	bnTexture:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	bnTexture:SetTexCoord(0, 0.625, 0, 0.6875)
	bnTexture:SetAllPoints()
	clearBn:SetHighlightTexture(bnTexture)
	
	f:Hide()
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:ShowLogFrame(plr, path, filter)
	if not plr or not path or not path.chatHistory[plr] or not path.chatHistory[plr].message[1] then return end
	local f = Frame_Log
	f:Hide()
	f.smf:Clear()
	f.titleText:SetText("|c0000FAF6SoDWhisper|r")
	f.closeBn:SetButtonState("NORMAL", unlock)
	
	if filter and filter == "" then
		filter = nil
	end
	local pathH = path.chatHistory[plr]
	local n = #pathH.message
	
	local tempFTS, tempFPN, tempHex, tempColorMessage
	for i=1, n do
		tempFTS = LF_FormatTimeStamp(pathH.time[i])
		tempFPN = SoDWhisper:FormatPlayerName( ( pathH.incoming[i] and pathH.displayName ) or SoDWhisper.player.name, plr, path)
		tempHex = LF_HexColor(pathH.incoming[i] and db.colorIncoming or db.colorOutgoing)
		tempColorMessage = tempFTS..tempFPN..": "..LF_Colorise(pathH.message[i], tempHex)
		if filter then
			if string_find(tempColorMessage, filter) then
				table_insert(LogFChatHistoryTB, tempColorMessage)
			end
		else
			table_insert(LogFChatHistoryTB, tempColorMessage)
		end
	end
	
	if #LogFChatHistoryTB > 0 then
		f.noMessage = false
		f.smf:SetMaxLines(#LogFChatHistoryTB)
		for i = 1, #LogFChatHistoryTB do
			f.smf:AddMessage(LogFChatHistoryTB[i])
		end
		wipe(LogFChatHistoryTB)
	else
		f.noMessage = true
	end
	
	f.searchBox:SetScript("OnEnterPressed", function(self) 
			local text = self:GetText()
			SoDWhisper:ShowLogFrame(plr, path, text)
	end)
	
	f.clearBn:SetScript("OnMouseDown", function(self)
			f.searchBox:SetText(L["Search:"])
			SoDWhisper:ShowLogFrame(plr, path)
	end)
	
	if not filter then
		f.searchBox:SetText(L["Search:"])
	end
	--f.editBoxBn:SetAlpha(.5)
	--f.editBoxBn:SetButtonState("DISABLED", lock)
	f.smfBn:SetAlpha(1)
	f.smfBn:SetButtonState("NORMAL", lock)
	f:Show()
	f.smf:Show()
	if f.noMessage or f.smf:GetMaxLines(maxLines) == f.smf:GetNumVisibleLines() then
		f.slider:Hide()
	else
		f.slider:Show()
	end
end

--**********************************************************************************************************************************************************
---------------------------------------------------------- Change Player Name Frame
--**********************************************************************************************************************************************************

local function LF_ChangePlayerName()
	local CreateFrame = _G.CreateFrame
	local fontT = LSM:Fetch('font', db.fontFace)
	
	---------------------------------------------------- Frame1
	local f = CreateFrame("Frame", "SODW_CPN_FRAME1", _G.UIParent, "backdropTemplate")
	Frame_ChangeDisplayName = f
	f:SetPoint("CENTER", _G.UIParent, "CENTER")
	f:SetFrameStrata("HIGH")
	f:SetFrameLevel(27)
	f:SetSize(300, 135)  
	f:EnableMouse(true)
	f:SetClampedToScreen(true)
	
	f:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
			insets = {left = 3, right = 3, top = 3, bottom = 3},
	})
	f:SetBackdropColor(0, 0, 0, 1)
	f:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
	
	---------------------------------------------------- Move Frame
	local titleRegion = CreateFrame('Frame', 'dragframesodwhisper', f, "backdropTemplate")
	titleRegion:SetFrameLevel(f:GetFrameLevel() + 2)
	titleRegion:EnableMouse(true)
	titleRegion:SetMovable(true)
	titleRegion:RegisterForDrag("LeftButton")
	titleRegion:SetClampedToScreen(true)
	
	-- titleRegion:SetBackdrop{
			-- bgFile='Interface\\DialogFrame\\UI-DialogBox-Background' ,
			-- edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',
			-- tile = true,
			-- insets = {left = 11, right = 12, top = 12, bottom = 11},
			-- tileSize = 32,
			-- edgeSize = 32,
		-- }
	
	Frame_ChangeDisplayName.titleRegion = titleRegion
	
	titleRegion:SetPoint("BOTTOMLEFT", f, -5, -2)
	titleRegion:SetPoint("TOPRIGHT", f, 5, 2)
	
	titleRegion:SetScript('OnDragStart', function() 
				f:SetMovable(true) 
				f:StartMoving()
	end)
	titleRegion:SetScript('OnDragStop', function() 
				f:StopMovingOrSizing() 
				f:SetMovable(false) 
	end)
	
	---------------------------------------------------- Title Text
	local titleText = f:CreateFontString("SODW_CPN_TITLETEXT", "ARTWORK", "ChatFontNormal")
	Frame_ChangeDisplayName.titleText = titleText
	titleText:SetPoint("TOP", f, "TOP", 0, -15)
	titleText:SetJustifyV("TOP")
	titleText:SetFont(fontT, 14)

	---------------------------------------------------- InputBox
	local inputBox = CreateFrame("EditBox", "SODW_CPN_INPUTBOX", f, "backdropTemplate")
	Frame_ChangeDisplayName.inputBox = inputBox
	inputBox:SetPoint("CENTER", f, "CENTER", 0, -10)
	inputBox:SetFrameLevel(f:GetFrameLevel() + 3)
	inputBox:SetSize(225, 30)
	inputBox:SetMaxLetters(12)
	inputBox:SetTextInsets(10, 10, 0, 0)
	inputBox:SetAutoFocus(false)
	inputBox:SetJustifyH("LEFT")
	inputBox:SetFont(fontT, 14)

	inputBox:SetBackdrop({
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
			insets = {left = 3, right = 3, top = 3, bottom = 3},
	})
	inputBox:SetBackdropColor(0, 0, 0, 1)
	inputBox:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
	
	inputBox:SetScript("OnEscapePressed", function(self) 
			self:ClearFocus()
	end)
	
	---------------------------------------------------- Title SubText
	local titleSubText = f:CreateFontString("SODW_CPN_TITLESUBTEXT", "ARTWORK", "ChatFontNormal")
	Frame_ChangeDisplayName.titleSubText = titleSubText
	titleSubText:SetPoint("BOTTOM", inputBox, "TOP", 0, 8)
	titleSubText:SetJustifyV("BOTTOM")
	titleSubText:SetFont(fontT, 14)
	
	---------------------------------------------------- Enter Button
	local enterBn = CreateFrame("Button", nil, f, "backdropTemplate")
	Frame_ChangeDisplayName.enterBn = enterBn
	enterBn:SetPoint("TOPLEFT", inputBox, "BOTTOMLEFT", 0, -4)
	enterBn:SetSize(85, 28)
	enterBn:SetNormalFontObject("GameFontNormal")
	enterBn:SetText(L["Enter"])
	enterBn:SetFrameLevel(f:GetFrameLevel() + 3)
	
	local bnTexture = enterBn:CreateTexture()
	bnTexture:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
	bnTexture:SetTexCoord(0, 0.625, 0, 0.6875)
	bnTexture:SetAllPoints()	
	enterBn:SetNormalTexture(bnTexture)
	
	bnTexture = enterBn:CreateTexture()
	bnTexture:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	bnTexture:SetTexCoord(0, 0.625, 0, 0.6875)
	bnTexture:SetAllPoints()
	enterBn:SetHighlightTexture(bnTexture)
	
	---------------------------------------------------- Reset Button
	local resetBn = CreateFrame("Button", nil, f, "backdropTemplate")
	Frame_ChangeDisplayName.resetBn = resetBn
	resetBn:SetPoint("TOPRIGHT", inputBox, "BOTTOMRIGHT", 0, -4)
	resetBn:SetSize(85, 28)
	resetBn:SetNormalFontObject("GameFontNormal")
	resetBn:SetText(L["Reset"])
	resetBn:SetFrameLevel(f:GetFrameLevel() + 3)
	
	bnTexture = resetBn:CreateTexture()
	bnTexture:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
	bnTexture:SetTexCoord(0, 0.625, 0, 0.6875)
	bnTexture:SetAllPoints()	
	resetBn:SetNormalTexture(bnTexture)
	
	bnTexture = resetBn:CreateTexture()
	bnTexture:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	bnTexture:SetTexCoord(0, 0.625, 0, 0.6875)
	bnTexture:SetAllPoints()
	resetBn:SetHighlightTexture(bnTexture)
	
	---------------------------------------------------- Close Button
	local closeBn = CreateFrame("Button", nil, f, "UIPanelCloseButton", "backdropTemplate")
	Frame_ChangeDisplayName.closeBn = closeBn
	closeBn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -3, -3)
	closeBn:SetFrameLevel(f:GetFrameLevel() + 3)
	
	closeBn:SetScript("OnMouseDown", function(self)
			self:GetParent().inputBox:SetText("")
			self:GetParent():Hide()
	end)
		
	f:Hide()
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:UpdateChangePlayerName(plr, path)
	local f = Frame_ChangeDisplayName
	f.titleText:SetText("|c0000FAF6SoDWhisper|r")
	f.titleSubText:SetText(L["Display Name For:"].." "..path.chatHistory[plr].name)
	
	f.closeBn:SetButtonState("NORMAL", unlock)
	f:Show()
	
	f.enterBn:SetScript("OnMouseDown", function()
			local text = f.inputBox:GetText()
			if string.len(text) < 13 and string.len(text) > 0 then
				path.chatHistory[plr].displayName = text
				path.chatHistory[plr].changed = true
				f.inputBox:SetText("")
				f:Hide()
				SoDWhisper:SendMessage("SoDWhisper_MESSAGE")
			else 
				print("|cff20ff20SoDWhisper|r: "..L["Must be 1 - 12 characters in length"])
			end
	end)
	f.resetBn:SetScript("OnMouseDown", function() 
			f.inputBox:SetText("")
			path.chatHistory[plr].displayName = path.chatHistory[plr].name
			path.chatHistory[plr].changed = nil		
			f:Hide()
			SoDWhisper:SendMessage("SoDWhisper_MESSAGE")
	end)
end

--**********************************************************************************************************************************************************
-------------------------------------------------------------- Initialisation Functions
--**********************************************************************************************************************************************************

function SoDWhisper:UpdateUsedMedia(event, mediatype, key)
    if mediatype == "font" then
        if key == db.fontFace then
			SoDWhisper:SkinMyFrame(nil, true, true)
			SoDWhisper:SendMessage("SoDWhisper_SKIN")
		end
    elseif mediatype == "background" then
        if key == db.bgTexture then 
			SoDWhisper:SendMessage("SoDWhisper_SKIN")
		end
    elseif mediatype == "border" then
        if key == db.borderTexture then 
			SoDWhisper:SendMessage("SoDWhisper_SKIN")
		end
    end
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:OnInitialize()
	SoDWhisper.db = LibStub("AceDB-3.0"):New("SoDWhisperDB", defaults, true)
	db = SoDWhisper.db.profile
	
	SoDWhisper.db.RegisterCallback(SoDWhisper, "OnProfileChanged", "OnProfileChanged")
	SoDWhisper.db.RegisterCallback(SoDWhisper, "OnProfileCopied", "OnProfileChanged")
	SoDWhisper.db.RegisterCallback(SoDWhisper, "OnProfileReset", "OnProfileChanged")
	
	LSM.RegisterCallback(SoDWhisper, "LibSharedMedia_Registered", "UpdateUsedMedia")
	
	-- Setup OnDemand Option Load for Bliz -- Pointers from MSBT Thanks
	local frame = CreateFrame("Frame")
	frame.name = "SoDWhisper"
	
	local button = CreateFrame("Button", nil, frame, "OptionsButtonTemplate")
	button:SetPoint("CENTER")
	button:SetText("/sodwhisper")
	button:SetScript("OnClick", function()
			InterfaceOptionsFrameCancel_OnClick()
			HideUIPanel(GameMenuFrame)
			SoDWhisper:SetupOptions()
	end)
	
	InterfaceOptions_AddCategory(frame)
	
	SoDWhisper:RegisterChatCommand("sodwhisper", SoDWhisper.SetupOptions)
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

local function LF_UpdateOnLoad() -- One Time on Load
	local timeKept = (db.historyDays == 0 and SoDWhisper.sessionStart) or time() - (24*60*60 * db.historyDays)
	local maximum = db.historyMax
	local minimum = db.historyMin
	
	for i,v in pairs(dbr.chatHistory) do
		if v.sender then v.sender = nil end
		if v.time[1] then
			local t = v.time[#v.time]
			if t < timeKept and minimum == 0 and not v.changed then
				dbr.chatHistory[i] = nil
			else
				local j = 1
				while j <= #v.time do
					if (not v.time[j]) or (v.time[j] < timeKept and #v.time - j >= minimum) or (#v.time - j >= maximum) then
						table_remove(v.message,j)
						table_remove(v.time,j)
						table_remove(v.incoming,j)
					else
						j = j + 1
					end
				end
			end
		elseif not v.changed then 
			dbr.chatHistory[i] = nil 
		end
		if dbr.chatHistory[i] then
			v.online, v.status, v.zone, v.guild, v.typeGuild, v.typeBNtoon, v.typeRegFriend = false, nil, nil, nil, nil, nil, nil
		end
	end
	
	local UNKNOWN = _G.UNKNOWN
	for i,v in pairs(dbg.chatHistory) do
		if v.sender then v.sender = nil end
		if v.time[1] then
			local t = v.time[#v.time]
			if t < timeKept and minimum == 0 and not v.changed or i == UNKNOWN then
				dbg.chatHistory[i] = nil
			else
				local j = 1
				while j <= #v.time do
					if (not v.time[j]) or (v.time[j] < timeKept and #v.time - j >= minimum) or (#v.time - j >= maximum) then
						table_remove(v.message,j)
						table_remove(v.time,j)
						table_remove(v.incoming,j)
					else
						j = j + 1
					end
				end
			end
		elseif not v.changed then 
			dbg.chatHistory[i] = nil 
		end
		if dbg.chatHistory[i] then
			v.online, v.status, v.level, v.zone, v.guild, v.faction, v.realm, v.toon, v.class, v.delCheck = false, nil, nil, nil, nil, nil, nil, nil, nil, false
		end
	end
	
	SoDWhisper:UpdateGuild(true)
	SoDWhisper:UpdateBNFriends(true)	
	SoDWhisper:UpdateRegFriends(true)
	SoDWhisper:UpdateOtherToons(true)
	
	SoDWhisper:SendMessage("SoDWhisper_MESSAGE")
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:OnEnable()
	dbg = SoDWhisper.db.global
	dbr = SoDWhisper.db.factionrealm
	SoDWhisper.sessionStart = time() - 30

	-- Cache incoming and outgoing whispers
	SoDWhisper:RegisterEvent("CHAT_MSG_WHISPER", SoDWhisper.ChatEventIncoming)
	SoDWhisper:RegisterEvent("CHAT_MSG_WHISPER_INFORM", SoDWhisper.ChatEventOutgoing)
	SoDWhisper:RegisterEvent("CHAT_MSG_BN_WHISPER", SoDWhisper.BNChatEventIncoming)
	SoDWhisper:RegisterEvent("CHAT_MSG_BN_WHISPER_INFORM", SoDWhisper.BNChatEventOutgoing)
	
	SoDWhisper:RegisterBucketEvent({"PLAYER_GUILD_UPDATE"}, 4, SoDWhisper.GuildPlayerUpdate)
	SoDWhisper:RegisterBucketEvent({"FRIENDLIST_UPDATE"}, 4, SoDWhisper.UpdateRegFriends)
	SoDWhisper:RegisterBucketEvent({"BN_FRIEND_INFO_CHANGED", "BN_FRIEND_ACCOUNT_ONLINE", "BN_FRIEND_ACCOUNT_OFFLINE"}, 4, SoDWhisper.UpdateBNFriends)
	SoDWhisper:RegisterBucketEvent({"BN_DISCONNECTED"}, 4, SoDWhisper.UpdateBNDisconnected)
	SoDWhisper:RegisterBucketEvent({"BN_CONNECTED"}, 4, SoDWhisper.UpdateBNConnected)
	
	-- Schedules
	SoDWhisper:ScheduleRepeatingTimer("UpdateOtherToons", 30)
	
	-- Load Modules
	for i, v in SoDWhisper:IterateModules() do
		if db.modules[i] ~= false then v:Enable() end
	end
	
	local plrName, plrRealm = _G.UnitFullName("player")
	SoDWhisper.player = {name = plrName, realm = plrRealm, faction = _G.UnitFactionGroup("player"), class = select(2,_G.UnitClass("player"))}
	
	-- Get and set-up Connected Realm
	local tempConnectedRealms = _G.GetAutoCompleteRealms()
	if tempConnectedRealms then
		for i, v in pairs(tempConnectedRealms) do
			ConnectedRealmsTB[v] = true
		end
	else
		ConnectedRealmsTB[SoDWhisper.player.realm] = true
	end
	
	-- Get and set-up localized class names
	local tempLocalizedClasses = {}
	_G.FillLocalizedClassList(tempLocalizedClasses, true)
	for i, v in pairs(tempLocalizedClasses) do
		LocalClassesTB[v] = i
	end
	tempLocalizedClasses = {}
	_G.FillLocalizedClassList(tempLocalizedClasses, false)
	for i, v in pairs(tempLocalizedClasses) do
		LocalClassesTB[v] = i
	end
	
	-- Get Localized Capital Cities
	-- local tempx = 0
	-- while tempx < 20000 do 
		-- if C_Map.GetMapInfo(tempx) then
			-- for i, v in pairs(C_Map.GetMapInfo(tempx)) do
				-- if(i == "name") then
					-- dbg.tempCityList[tempx] = v
				-- end
			-- end
		-- end
		-- tempx = tempx + 1
	-- end
	LocalCitiesTB[C_Map.GetMapInfo(89).name] = true		-- Darnassus
	LocalCitiesTB[C_Map.GetMapInfo(103).name] = true	-- Exodar
	LocalCitiesTB[C_Map.GetMapInfo(87).name] = true		-- Ironforge
	LocalCitiesTB[C_Map.GetMapInfo(85).name] = true		-- Orgrimmar
	LocalCitiesTB[C_Map.GetMapInfo(84).name] = true		-- Stormwind City
	LocalCitiesTB[C_Map.GetMapInfo(110).name] = true	-- Silvermoon City
	LocalCitiesTB[C_Map.GetMapInfo(88).name] = true		-- Thunder Bluff
	LocalCitiesTB[C_Map.GetMapInfo(90).name] = true		-- Undercity
	LocalCitiesTB[C_Map.GetMapInfo(125).name] = true	-- Dalaran
	LocalCitiesTB[C_Map.GetMapInfo(111).name] = true	-- Shattrath City
	LocalCitiesTB[C_Map.GetMapInfo(940).name] = true	-- Vindicaar
	LocalCitiesTB[C_Map.GetMapInfo(971).name] = true	-- Telogrus Rift
	LocalCitiesTB[C_Map.GetMapInfo(1161).name] = true	-- Boralus
	LocalCitiesTB[C_Map.GetMapInfo(764).name] = true	-- Nighthold
	LocalCitiesTB[C_Map.GetMapInfo(652).name] = true	-- Thunder Totem
	LocalCitiesTB[C_Map.GetMapInfo(1163).name] = true	-- Dazar'alor
	LocalCitiesTB[C_Map.GetMapInfo(393).name] = true	-- Shrine of Seven Stars
	LocalCitiesTB[C_Map.GetMapInfo(391).name] = true	-- Shrine of Two Moons
	
	-- Create Frames
	LF_ChangePlayerName()
	LF_CreateLogFrame()
	
	-- Channel Sticky set-up
	if db.inputSticky then
		ChatTypeInfo["WHISPER"].sticky = 0
		ChatTypeInfo["BN_WHISPER"].sticky = 0
	end
	
	-- Localization notice
	local loadedL = _G.GetLocale()
	if loadedL == "ptBR" or loadedL == "frFR" or loadedL == "itIT" or loadedL == "koKR" or loadedL == "esMX" or loadedL == "ruRU" or loadedL == "zhCN" or loadedL == "esES" then
        print("|cff20ff20SoDWhisper|r: Help Translate at the Project Site!")
    end
	
	-- Set-up on load
	LF_UpdateOnLoad()
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:OnDisable()
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:OnProfileChanged()
	db = SoDWhisper.db.profile
	SoDWhisper:ProfileChanged()
	for k, v in SoDWhisper:IterateModules() do
		local set = db.modules[k]
		local status = v:IsEnabled()
		
		if set and status then
			v:OnSkinUpdate()
		elseif set and not status then
			SoDWhisper:EnableModule(k)
		elseif not set and status then
			SoDWhisper:DisableModule(k)
		end
		v:ProfileChanged()
	end
end
