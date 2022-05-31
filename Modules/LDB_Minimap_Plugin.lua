-- AddOn nameSpace
local SoDWhisper = LibStub("AceAddon-3.0"):GetAddon("SoDWhisper")
local L = SoDWhisper.L

local MODNAME = "LDB/Minimap_Plugin"
local mod = SoDWhisper:NewModule(MODNAME, "AceEvent-3.0")
local LibDBIcon = LibStub("LibDBIcon-1.0")
local LDB = LibStub("LibDataBroker-1.1")
local LibQTip = SoDWhisper.LibQTip
local LSM = SoDWhisper.LSM

-- UpValue
local _G = _G
local select = _G.select
local time = _G.time
local pairs = _G.pairs
local string_find = _G.string.find
local string_format = _G.string.format
local table_insert = _G.table.insert
local table_sort = _G.table.sort
local wipe = _G.wipe
local MouseIsOver = _G.MouseIsOver

-- Constants
local UI_PLUS = "|TInterface\\Buttons\\UI-PlusButton-Up:12:12:1:0|t"
local ICON_MISSED = "Interface\\AddOns\\SoDWhisper\\MediaFiles\\Icon-Missed_Status"
local ICON_NORMAL = "Interface\\AddOns\\SoDWhisper\\MediaFiles\\Icon-Normal_Status"
local TIME_FRAMES = {
	L["Session"], 
	L["Hour"], 
	L["Day"], 
	L["Week"], 
	L["All"]
}

-- Frames
local Frame_Messages							-- Frame for Messages
local Frame_GetLength							-- Frame for Measuring Length

-- Tables
local OtherTempTB = {}							-- Temp for others (mod:DisplayTooltip)
local GuildTempTB = {}							-- Temp for guild (mod:DisplayTooltip)
local RegFriendTempTB = {}						-- Temp for regular friends (mod:DisplayTooltip)
local BattleNetTempTB = {}						-- Temp for battle-net friends (mod:DisplayTooltip)
local MissedTempTB = {}							-- Temp for missed messages (mod:LastSenderUpdate)

-- Variables
local dbg, dbr, db								-- SoDWhisper.db.global, SoDWhisper.db.factionrealm, mod.db.profile
local lastsender, lastsenderpath
local toolTUP

local defaults = {
	profile = {
		-- Icon
		minimap = {
			hide = false,
		},
		changeIcon = true,						-- Change colour of icon on missed message 
		showOnlineCount = true,					-- Shows Friends and Guild on-line count on LDB text
		-- Appearance
		maxTTHeight = 300,						-- Maximum height of tool-tip
		tooltipSpacing = 6,						-- Space between tool-tips
		enableFormatTT = true,					-- Skin tool-tips enable
		scaleTT = .9,							-- Scale of message pane's title
		bgColorTT = {0,0,0,1},					-- Background color
		bgTextureTT = "Solid",					-- Background texture
		borderColorTT = {.5,.5,.5,1},			-- Border color
		borderTextureTT = "Blizzard Tooltip",	-- Border texture
		-- Messages
		enableMsgFrame = false,					-- Show or Hide message history pane
		msgSortDown = true,						-- Message entry sort for message history pane
		frameWidth = 500,						-- Width of the message history pane
		-- Saved Information
		tooltipTimeFrame = 1,					-- Show players by TimeFrame on tool-tip
		tooltipSort = false,					-- Sort method for players on tool-tip (time or name)
		tooltipOptions = true,					-- Show Title Tool-tip Options
		tooltipGuildTimeFrame = false,			-- TimeRrame or on-line for guild
		tooltipFriendsTimeFrame = false,		-- TimeFrame or on-line for friends
		noAppAway = 3,							-- Hide Battle-Net Application users that are away		
	}
}

--**********************************************************************************************************************************************************
----------------------------------------------------------------- Tool-tip Display (ugly coded, but what can ya do)
--**********************************************************************************************************************************************************

function mod:HideTooltip()
	if self.titleTT then
		if MouseIsOver(self.friendsTT) or MouseIsOver(self.guildTT) or MouseIsOver(self.otherTT) or MouseIsOver(self.titleTT) then return end
		Frame_Messages:Hide()
		
		self.titleTT:Hide()
		self.friendsTT:Hide()
		self.guildTT:Hide()
		self.otherTT:Hide()
		
		LibQTip:Release(self.titleTT)
		self.titleTT = nil
		LibQTip:Release(self.friendsTT)
		self.friendsTT = nil		
		LibQTip:Release(self.guildTT)
		self.guildTT = nil		
		LibQTip:Release(self.otherTT)
		self.otherTT = nil
	end
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

local function LF_DisplayTooltip()
	if not mod.titleTT then return end
	local otherTT = mod.otherTT
	local guildTT = mod.guildTT
	local friendsTT = mod.friendsTT
	local titleTT = mod.titleTT
	
	titleTT:Clear()
	otherTT:Clear()
	guildTT:Clear()
	friendsTT:Clear()
	
	if db.enableFormatTT then
		local bg = LSM:Fetch("background", db.bgTextureTT, "Blizzard Tooltip")
		local ed = LSM:Fetch("border", db.borderTextureTT, "Blizzard Tooltip")
		local c,d = db.bgColorTT, db.borderColorTT
		local scale = db.scaleTT
		
		otherTT:SetScale(scale)
		otherTT:SetBackdrop({bgFile = bg, tile = true, tileSize = 16, edgeFile = ed, edgeSize = 16, insets = {left = 3, right = 3, top = 3, bottom = 3}})
		otherTT:SetBackdropColor(c[1], c[2], c[3], c[4])
		otherTT:SetBackdropBorderColor(d[1], d[2], d[3], d[4])
		
		guildTT:SetScale(scale)
		guildTT:SetBackdrop({bgFile = bg, tile = true, tileSize = 16, edgeFile = ed, edgeSize = 16, insets = {left = 3, right = 3, top = 3, bottom = 3}})
		guildTT:SetBackdropColor(c[1], c[2], c[3], c[4])
		guildTT:SetBackdropBorderColor(d[1], d[2], d[3], d[4])
		
		friendsTT:SetScale(scale)
		friendsTT:SetBackdrop({bgFile = bg, tile = true, tileSize = 16, edgeFile = ed, edgeSize = 16, insets = {left = 3, right = 3, top = 3, bottom = 3}})
		friendsTT:SetBackdropColor(c[1], c[2], c[3], c[4])
		friendsTT:SetBackdropBorderColor(d[1], d[2], d[3], d[4])
		
		titleTT:SetScale(scale)
		titleTT:SetBackdrop({bgFile = bg, tile = true, tileSize = 16, edgeFile = ed, edgeSize = 16, insets = {left = 3, right = 3, top = 3, bottom = 3}})
		titleTT:SetBackdropColor(c[1], c[2], c[3], c[4])
		titleTT:SetBackdropBorderColor(d[1], d[2], d[3], d[4])
	end
	
	local ttime = time()
	local systime
	for i,v in pairs(dbr.chatHistory) do
		if v.message[1] and not v.typeBNtoon and not v.typeRegFriend and not v.typeGuild then
			systime = v.time[#v.time]
		
			if ((db.tooltipTimeFrame == 1 and systime < SoDWhisper.sessionStart) or (db.tooltipTimeFrame == 2 and ttime - systime > 3600) or (db.tooltipTimeFrame == 3 and ttime - systime > 86400) or (db.tooltipTimeFrame == 4 and ttime - systime > 604800)) then
			else 
				table_insert(OtherTempTB, {time = v.time[#v.time], plr = i, display = v.displayName}) 
			end
		end
		if v.typeGuild and (v.online or v.message[1]) then
			systime = v.time[#v.time]
			if not systime then systime = 1000000 end
			
			if not db.tooltipGuildTimeFrame and v.message[1] then
				if ((db.tooltipTimeFrame == 1 and systime < SoDWhisper.sessionStart) or (db.tooltipTimeFrame == 2 and ttime - systime > 3600) or (db.tooltipTimeFrame == 3 and ttime - systime > 86400) or (db.tooltipTimeFrame == 4 and ttime - systime > 604800)) then
				else 
					table_insert(GuildTempTB, {time = v.time[#v.time], plr = i, display = v.displayName}) 
				end
			elseif db.tooltipGuildTimeFrame and v.online then 
				table_insert(GuildTempTB, {time = systime, plr = i, display = v.displayName}) 
			end
		end
		if v.typeRegFriend and (v.online or v.message[1]) then
			systime = v.time[#v.time]
			if not systime then systime = 1000000 end
			
			if not db.tooltipFriendsTimeFrame and v.message[1] then
				if ((db.tooltipTimeFrame == 1 and systime < SoDWhisper.sessionStart) or (db.tooltipTimeFrame == 2 and ttime - systime > 3600) or (db.tooltipTimeFrame == 3 and ttime - systime > 86400) or (db.tooltipTimeFrame == 4 and ttime - systime > 604800)) then
				else 
					table_insert(RegFriendTempTB, {time = v.time[#v.time], plr = i, display = v.displayName}) 
				end
			elseif db.tooltipFriendsTimeFrame and v.online then 
				table_insert(RegFriendTempTB, {time = systime, plr = i, display = v.displayName}) 
			end
		end
	end
	
	for i,v in pairs(dbg.chatHistory) do
		if v.message[1] or v.online then
			systime = v.time[#v.time]
			if not systime then systime = 1000000 end
			
			if not db.tooltipFriendsTimeFrame and v.message[1] then
				if ((db.tooltipTimeFrame == 1 and systime < SoDWhisper.sessionStart) or (db.tooltipTimeFrame == 2 and ttime - systime > 3600) or (db.tooltipTimeFrame == 3 and ttime - systime > 86400) or (db.tooltipTimeFrame == 4 and ttime - systime > 604800)) then
				else 
					table_insert(BattleNetTempTB, {time = v.time[#v.time], plr = i, display = v.displayName})
				end
			elseif db.tooltipFriendsTimeFrame and v.online then 
				if db.noAppAway == 1 then
					table_insert(BattleNetTempTB, {time = systime, plr = i, display = v.displayName}) 
				elseif db.noAppAway == 2 and v.client == "App" and v.status and string_find(v.status, "<AFK>") then
					-- Nothing (don't store)
				elseif db.noAppAway == 3 and v.client == "App" then
					-- Nothing (don't store)
				else
					table_insert(BattleNetTempTB, {time = systime, plr = i, display = v.displayName}) 
				end
			end
		end
	end
	
	if not db.tooltipSort then
		table_sort(OtherTempTB, function(a,b) return a.display<b.display end)
		table_sort(GuildTempTB, function(a,b) return a.display<b.display end)
		table_sort(RegFriendTempTB, function(a,b) return a.display<b.display end)
		table_sort(BattleNetTempTB, function(a,b) return a.display<b.display end)
	else
		table_sort(OtherTempTB, function(a,b) return a.time>b.time end)
		table_sort(GuildTempTB, function(a,b) return a.time>b.time end)
		table_sort(RegFriendTempTB, function(a,b) return a.time>b.time end)
		table_sort(BattleNetTempTB, function(a,b) return a.time>b.time end)
	end
	
	if db.enableFormatTT then
		Frame_GetLength:SetScale(db.scaleTT)
	else
		Frame_GetLength:SetScale(_G.GameTooltip:GetScale())
	end
	Frame_GetLength.text:SetFontObject(_G.GameTooltipText)
	
	local BNsidesW, levelW, nameW, tellsW, zoneW = 0, 0, 0, 0, 0
	local len
	if OtherTempTB[1] or GuildTempTB[1] or RegFriendTempTB[1] or BattleNetTempTB[1] then
		Frame_GetLength.text:SetText("100")
		levelW = Frame_GetLength.text:GetStringWidth()
		for i,v in pairs(OtherTempTB) do
			Frame_GetLength.text:SetText(SoDWhisper:GetDisplayNameForTooltip(v.plr, dbr, nil, nil, nil, 0))
			len = Frame_GetLength.text:GetStringWidth()
			if nameW < len then nameW = len end
			Frame_GetLength.text:SetText(dbr.chatHistory[v.plr].tells)
			len = Frame_GetLength.text:GetStringWidth()
			if tellsW < len then tellsW = len end
			Frame_GetLength.text:SetText(dbr.chatHistory[v.plr].zone or "")
			len = Frame_GetLength.text:GetStringWidth()
			if zoneW < len then zoneW = len end
		end
		for i,v in pairs(GuildTempTB) do
			Frame_GetLength.text:SetText(SoDWhisper:GetDisplayNameForTooltip(v.plr, dbr, nil, nil, nil, 0))
			len = Frame_GetLength.text:GetStringWidth()
			if nameW < len then nameW = len end
			Frame_GetLength.text:SetText(dbr.chatHistory[v.plr].tells)
			len = Frame_GetLength.text:GetStringWidth()
			if tellsW < len then tellsW = len end
			Frame_GetLength.text:SetText(dbr.chatHistory[v.plr].zone or "")
			len = Frame_GetLength.text:GetStringWidth()
			if zoneW < len then zoneW = len end
		end
		for i,v in pairs(RegFriendTempTB) do
			Frame_GetLength.text:SetText(SoDWhisper:GetDisplayNameForTooltip(v.plr, dbr, nil, nil, nil, 0))
			len = Frame_GetLength.text:GetStringWidth()
			if nameW < len then nameW = len end
			Frame_GetLength.text:SetText(dbr.chatHistory[v.plr].tells)
			len = Frame_GetLength.text:GetStringWidth()
			if tellsW < len then tellsW = len end
			Frame_GetLength.text:SetText(dbr.chatHistory[v.plr].zone or "")
			len = Frame_GetLength.text:GetStringWidth()
			if zoneW < len then zoneW = len end
			Frame_GetLength.text:SetText(SoDWhisper:GetRealmForTooltip(v.plr, true, 0, dbr))
			len = Frame_GetLength.text:GetStringWidth()
			if BNsidesW < len then BNsidesW = len end
		end
		for i,v in pairs(BattleNetTempTB) do
			Frame_GetLength.text:SetText(SoDWhisper:GetDisplayNameForTooltip(v.plr, dbg, true, true))
			len = Frame_GetLength.text:GetStringWidth()
			if BNsidesW < len then BNsidesW = len end
			Frame_GetLength.text:SetText(SoDWhisper:GetDisplayNameForTooltip(v.plr, dbg, true, nil, nil, 0))
			len = Frame_GetLength.text:GetStringWidth()
			if nameW < len then nameW = len end
			Frame_GetLength.text:SetText(dbg.chatHistory[v.plr].tells)
			len = Frame_GetLength.text:GetStringWidth()
			if tellsW < len then tellsW = len end
			Frame_GetLength.text:SetText(dbg.chatHistory[v.plr].zone or "")
			len = Frame_GetLength.text:GetStringWidth()
			if zoneW < len then zoneW = len end
			Frame_GetLength.text:SetText(SoDWhisper:GetRealmForTooltip(v.plr, true, 0, dbg))
			len = Frame_GetLength.text:GetStringWidth()
			if BNsidesW < len then BNsidesW = len end
		end	
	end
	BNsidesW, levelW, tellsW, nameW, zoneW = BNsidesW + 5, levelW + 2, tellsW + 2, nameW + 5, zoneW + 5
	if BNsidesW < 50 then BNsidesW = 50 end
	local temp1stTitlemin = nameW + levelW + tellsW
	local time2ndTitlemin = zoneW
	if temp1stTitlemin < 95 then 
		temp1stTitlemin = 95
		nameW = 95 - levelW - tellsW
	end
	if time2ndTitlemin < 105 then 
		time2ndTitlemin = 105 
		zoneW = 105
	end
	local paddingConstant = 6
	local padding = 0
	---------------------------------------------------------------------------------------------
	local y = titleTT:AddLine()
	local titlespace = db.tooltipOptions and 0 or temp1stTitlemin + paddingConstant + 3 + time2ndTitlemin + paddingConstant + 3
	titleTT:SetCell(y, 1, "|c001eff00SoDWhisper|r", nil, "CENTER", 4, nil, nil, nil, titlespace, titlespace)  
	titleTT:SetLineScript(y, "OnMouseDown", mod.HandleTTClick, "titleOptions")
	titleTT:AddLine(" ")
	
	if db.tooltipOptions then
		y = titleTT:AddHeader()
		titleTT:SetCell(y, 1, UI_PLUS..L["TimeframeTitle"], nil, "LEFT", 3, nil, nil, nil, temp1stTitlemin + paddingConstant, temp1stTitlemin + paddingConstant)
		titleTT:SetCell(y, 4, TIME_FRAMES[db.tooltipTimeFrame], nil, "RIGHT", 1, nil, nil, nil, time2ndTitlemin + paddingConstant, time2ndTitlemin + paddingConstant)
		titleTT:SetLineScript(y, "OnMouseDown", mod.HandleTTClick, "timeframe") 

		y = titleTT:AddHeader()
		titleTT:SetCell(y, 1, UI_PLUS..L["Sort by"], nil, "LEFT", 3, nil, nil, nil, temp1stTitlemin + paddingConstant, temp1stTitlemin + paddingConstant)
		titleTT:SetCell(y, 4, (db.tooltipSort and L["Time"]) or L["Name"], nil, "RIGHT", 1, nil, nil, nil, time2ndTitlemin + paddingConstant, time2ndTitlemin + paddingConstant)
		titleTT:SetLineScript(y, "OnMouseDown", mod.HandleTTClick, "sortby")
	end
	---------------------------------------------------------------------------------------------
	if not OtherTempTB[1] then padding = paddingConstant end
	y = otherTT:AddHeader()
	otherTT:SetCell(y, 1, UI_PLUS..L["Other"], nil, "LEFT", 3, nil, nil, nil, temp1stTitlemin + padding, temp1stTitlemin + padding)
	otherTT:SetCell(y, 4, L["Timeframe"], nil, "RIGHT", 1, nil, nil, nil, time2ndTitlemin + padding, time2ndTitlemin + padding)
	otherTT:SetLineScript(y, "OnMouseDown", mod.HandleTTClick, "other") 
	
	if OtherTempTB[1] then
		for i,v in pairs(OtherTempTB) do
			y = otherTT:AddLine()
			otherTT:SetCell(y, 1, SoDWhisper:GetColoredLevel(dbr.chatHistory[v.plr].level, dbr.chatHistory[v.plr].online), nil, "CENTER", 1, nil, nil, nil, levelW, levelW)
			otherTT:SetCell(y, 2, SoDWhisper:GetDisplayNameForTooltip(v.plr, dbr, nil, nil, nil, 0), nil, "LEFT", 1, nil, nil, nil, nameW, nameW)
			otherTT:SetCell(y, 3, dbr.chatHistory[v.plr].tells > 0 and dbr.chatHistory[v.plr].tells or "", nil, "CENTER", 1, nil, nil, nil, tellsW, tellsW)
			otherTT:SetCell(y, 4, SoDWhisper:GetZoneColor(dbr.chatHistory[v.plr].zone, dbr.chatHistory[v.plr].online), nil, "CENTER", 1, nil, nil, nil, zoneW, zoneW)
			otherTT:SetLineScript(y, "OnEnter", mod.ShowBrokerFrame, v.plr) 
			otherTT:SetLineScript(y, "OnLeave", mod.HideBrokerFrame) 			
			otherTT:SetLineScript(y, "OnMouseDown", mod.HandleTTClick, v.plr) 
		end
	end
	---------------------------------------------------------------------------------------------
	if not GuildTempTB[1] then padding = paddingConstant
	else padding = 0 end
	y = guildTT:AddHeader()
	guildTT:SetCell(y, 1, UI_PLUS..L["Guild"], nil, "LEFT", 3, nil, nil, nil, temp1stTitlemin + padding, temp1stTitlemin + padding)
	guildTT:SetCell(y, 4, (db.tooltipGuildTimeFrame and L["Online"]) or L["Timeframe"], nil, "RIGHT", 1, nil, nil, nil, time2ndTitlemin + padding, time2ndTitlemin + padding)
	guildTT:SetLineScript(y, "OnMouseDown", mod.HandleTTClick, "guild") 
		
	if GuildTempTB[1] then
		for i,v in pairs(GuildTempTB) do
			y = guildTT:AddLine()
			guildTT:SetCell(y, 1, SoDWhisper:GetColoredLevel(dbr.chatHistory[v.plr].level, dbr.chatHistory[v.plr].online), nil, "CENTER", 1, nil, nil, nil, levelW, levelW)
			guildTT:SetCell(y, 2, SoDWhisper:GetDisplayNameForTooltip(v.plr, dbr, nil, nil, nil, 0), nil, "LEFT", 1, nil, nil, nil, nameW, nameW)
			guildTT:SetCell(y, 3, dbr.chatHistory[v.plr].tells > 0 and dbr.chatHistory[v.plr].tells or "", nil, "CENTER", 1, nil, nil, nil, tellsW, tellsW)
			guildTT:SetCell(y, 4, SoDWhisper:GetZoneColor(dbr.chatHistory[v.plr].zone, dbr.chatHistory[v.plr].online), nil, "CENTER", 1, nil, nil, nil, zoneW, zoneW)
			guildTT:SetLineScript(y, "OnEnter", mod.ShowBrokerFrame, v.plr) 
			guildTT:SetLineScript(y, "OnLeave", mod.HideBrokerFrame) 			
			guildTT:SetLineScript(y, "OnMouseDown", mod.HandleTTClick, v.plr) 
		end
	end
	---------------------------------------------------------------------------------------------
	if not BattleNetTempTB[1] then padding = paddingConstant * 2
	else padding = 0 end
	
	local friendTFText
	if db.tooltipFriendsTimeFrame then
		friendTFText = db.noAppAway == 3 and "!"..L["Online"] or db.noAppAway == 2 and "*"..L["Online"] or L["Online"]
	else
		friendTFText = L["Timeframe"]
	end
	
	y = friendsTT:AddHeader()
	friendsTT:SetCell(y, 1, UI_PLUS..L["Friends"], nil, "LEFT", 4, nil, nil, nil, temp1stTitlemin + BNsidesW + padding, temp1stTitlemin + BNsidesW + padding)
	friendsTT:SetCell(y, 5, friendTFText, nil, "RIGHT", 2, nil, nil, nil, time2ndTitlemin + BNsidesW + padding, time2ndTitlemin + BNsidesW + padding)
	friendsTT:SetLineScript(y, "OnMouseDown", mod.HandleTTClick, "friends") 
	
	if BattleNetTempTB[1] then
		for i,v in pairs(BattleNetTempTB) do
			y = friendsTT:AddLine()
			friendsTT:SetCell(y, 1, SoDWhisper:GetDisplayNameForTooltip(v.plr, dbg, true, true), nil, "RIGHT", 1, nil, nil, nil, BNsidesW, BNsidesW)
			friendsTT:SetCell(y, 2, SoDWhisper:GetColoredLevel(dbg.chatHistory[v.plr].level, dbg.chatHistory[v.plr].online, true), nil, "CENTER", 1, nil, nil, nil, levelW, levelW)
			friendsTT:SetCell(y, 3, SoDWhisper:GetDisplayNameForTooltip(v.plr, dbg, true, nil, nil, 0), nil, "LEFT", 1, nil, nil, nil, nameW, nameW)
			friendsTT:SetCell(y, 4, dbg.chatHistory[v.plr].tells > 0 and dbg.chatHistory[v.plr].tells or "", nil, "CENTER", 1, nil, nil, nil, tellsW, tellsW)
			friendsTT:SetCell(y, 5, SoDWhisper:GetZoneColor(dbg.chatHistory[v.plr].zone, dbg.chatHistory[v.plr].online), nil, "CENTER", 1, nil, nil, nil, zoneW, zoneW)
			friendsTT:SetCell(y, 6, SoDWhisper:GetRealmForTooltip(v.plr, true, 0, dbg), nil, "CENTER", 1, nil, nil, nil, BNsidesW, BNsidesW)				
			friendsTT:SetLineScript(y, "OnEnter", mod.ShowBrokerFrame, v.plr) 
			friendsTT:SetLineScript(y, "OnLeave", mod.HideBrokerFrame) 			
			friendsTT:SetLineScript(y, "OnMouseDown", mod.HandleTTClick, v.plr)
		end
	end
	if RegFriendTempTB[1] then
		for i,v in pairs(RegFriendTempTB) do
			y = friendsTT:AddLine()
			friendsTT:SetCell(y, 1, (dbr.chatHistory[v.plr].online and "-") or "|c00585858-|r", nil, "RIGHT", 1, nil, nil, nil, BNsidesW, BNsidesW)
			friendsTT:SetCell(y, 2, SoDWhisper:GetColoredLevel(dbr.chatHistory[v.plr].level, dbr.chatHistory[v.plr].online), nil, "CENTER", 1, nil, nil, nil, levelW, levelW)
			friendsTT:SetCell(y, 3, SoDWhisper:GetDisplayNameForTooltip(v.plr, dbr, nil, nil, nil, 0), nil, "LEFT", 1, nil, nil, nil, nameW, nameW)
			friendsTT:SetCell(y, 4, dbr.chatHistory[v.plr].tells > 0 and dbr.chatHistory[v.plr].tells or "", nil, "CENTER", 1, nil, nil, nil, tellsW, tellsW)
			friendsTT:SetCell(y, 5, SoDWhisper:GetZoneColor(dbr.chatHistory[v.plr].zone, dbr.chatHistory[v.plr].online), nil,"CENTER", 1, nil, nil, nil, zoneW, zoneW)
			friendsTT:SetCell(y, 6, SoDWhisper:GetRealmForTooltip(v.plr, true, 0, dbr), nil, "CENTER", 1, nil, nil, nil, BNsidesW, BNsidesW)
			friendsTT:SetLineScript(y, "OnEnter", mod.ShowBrokerFrame, v.plr) 
			friendsTT:SetLineScript(y, "OnLeave", mod.HideBrokerFrame) 			
			friendsTT:SetLineScript(y, "OnMouseDown", mod.HandleTTClick, v.plr) 
		end
	end

	if db.maxTTHeight ~= 0 then 
		if toolTUP then
			friendsTT:UpdateScrolling(db.maxTTHeight)
			guildTT:UpdateScrolling(db.maxTTHeight)
			otherTT:UpdateScrolling(db.maxTTHeight)
			titleTT:UpdateScrolling(db.maxTTHeight) 
		else
			titleTT:UpdateScrolling(db.maxTTHeight)
			otherTT:UpdateScrolling(db.maxTTHeight)
			guildTT:UpdateScrolling(db.maxTTHeight)
			friendsTT:UpdateScrolling(db.maxTTHeight)
		end
	end
	
	local titleScroll, otherScroll, guildScroll, friendsScroll
	if titleTT.slider and titleTT.slider:IsShown() then titleScroll = true end
	if otherTT.slider and otherTT.slider:IsShown() then otherScroll = true end
	if guildTT.slider and guildTT.slider:IsShown() then guildScroll = true end
	if friendsTT.slider and friendsTT.slider:IsShown() then friendsScroll = true end
	
	if titleScroll or otherScroll or guildScroll or friendsScroll then
		if not titleScroll then titleTT:SetWidth(titleTT:GetWidth() + 20) end
		if not otherScroll then otherTT:SetWidth(otherTT:GetWidth() + 20) end
		if not guildScroll then guildTT:SetWidth(guildTT:GetWidth() + 20) end
		if not friendsScroll then friendsTT:SetWidth(friendsTT:GetWidth() + 20) end
	end
	
	friendsTT:Show()
	guildTT:Show()
	otherTT:Show()
	titleTT:Show()
	
	guildTT:SetClampedToScreen(true)
	otherTT:SetClampedToScreen(true)
	titleTT:SetClampedToScreen(true)
	friendsTT:SetClampedToScreen(true)
	
	wipe(OtherTempTB)
	wipe(GuildTempTB)
	wipe(BattleNetTempTB)
	wipe(RegFriendTempTB)
end

--**********************************************************************************************************************************************************
------------------------------------------------------------------ LDB/Minimap Display
--**********************************************************************************************************************************************************

function mod:CreateLDBObject()
	if mod.obj then return end
	mod.obj = LDB:NewDataObject("SoDWhisper", {
		type = "data source",
		text = "SoDWhisper",
		icon = ICON_NORMAL,
		OnClick = function(frame, button)
				if button == "RightButton" then
					if _G.IsControlKeyDown() then
						_G.ToggleGuildFrame(1)
					else
						SoDWhisper:SetupOptions()
					end
				else
					if _G.IsControlKeyDown() then
						_G.ToggleFriendsFrame(1)
					elseif lastsender then
						if _G.IsShiftKeyDown() then
							lastsenderpath.chatHistory[lastsender].message, lastsenderpath.chatHistory[lastsender].time, lastsenderpath.chatHistory[lastsender].incoming, lastsenderpath.chatHistory[lastsender].tells = {}, {}, {}, 0 
							mod:LastSenderUpdate()
						elseif lastsenderpath == dbg then
							local presID, plr = SoDWhisper:CompareBattleTag(lastsender)
							if presID then
								plr = plr..":"..presID
								_G.SetItemRef("BNplayer:"..plr, ("|HBNplayer:%1$s|h[%1$s]|h"):format(plr), "LeftButton")
							end
						else
							_G.SetItemRef("player:"..lastsender, "|Hplayer:"..lastsender.."|h["..lastsender.."]|h", "LeftButton")
						end
					end
				end
		end,
		OnEnter = function(frame)
				local friendsTT = LibQTip:Acquire("SoDWhisper_FriendsTooltip", 6)
				mod.friendsTT = friendsTT
				friendsTT:Clear()
				friendsTT:ClearAllPoints()
				
				local guildTT = LibQTip:Acquire("SoDWhisper_GuildTooltip", 4)
				mod.guildTT = guildTT
				guildTT:Clear()
				guildTT:ClearAllPoints()			
							
				local otherTT = LibQTip:Acquire("SoDWhisper_OtherTooltip", 4)
				mod.otherTT = otherTT
				otherTT:Clear()
				otherTT:ClearAllPoints()			
				
				local titleTT = LibQTip:Acquire("SoDWhisper_SoDWhisperTitleTooltip", 4)
				mod.titleTT = titleTT
				titleTT:Clear()
				titleTT:ClearAllPoints()	
				titleTT:SetScript("OnUpdate", function() if not MouseIsOver(frame) then mod:HideTooltip() end end)
				
				--------------------------------------------------------------------------------------
				local scale = (frame:GetParent() and frame:GetParent():GetScale()) or frame:GetScale()
				local istopT = select(2, frame:GetCenter()) > (_G.UIParent:GetHeight() / scale) / 2
				
				if istopT then
					toolTUP = nil
					local rightT = select(1, frame:GetCenter()) > (_G.UIParent:GetWidth() / scale) * .9
					local leftT = select(1, frame:GetCenter()) < (_G.UIParent:GetWidth()  / scale) * .1 
					local xpointT = (rightT and "RIGHT") or (leftT and "LEFT") or ""
					
					titleTT:SetPoint("TOP"..xpointT, frame, "BOTTOM"..xpointT, 8, 0)
					titleTT:SetFrameLevel(_G.GameTooltip:GetFrameLevel() + 10)
					
					otherTT:SetPoint("TOP"..xpointT, titleTT, "BOTTOM"..xpointT, 0, db.tooltipSpacing)
					otherTT:SetFrameLevel(titleTT:GetFrameLevel() + 1)
					
					guildTT:SetPoint("TOP"..xpointT, otherTT, "BOTTOM"..xpointT, 0, db.tooltipSpacing)
					guildTT:SetFrameLevel(otherTT:GetFrameLevel() + 1)
					
					friendsTT:SetPoint("TOP", guildTT, "BOTTOM", 0, db.tooltipSpacing)
					friendsTT:SetFrameLevel(guildTT:GetFrameLevel() + 1)
				else
					toolTUP = true
					friendsTT:SetPoint("BOTTOM", frame, "TOP")
					friendsTT:SetFrameLevel(_G.GameTooltip:GetFrameLevel() + 13)
				
					guildTT:SetPoint("BOTTOM", friendsTT, "TOP", 0, -db.tooltipSpacing)
					guildTT:SetFrameLevel(friendsTT:GetFrameLevel() - 1)
				
					otherTT:SetPoint("BOTTOM", guildTT, "TOP", 0, -db.tooltipSpacing)
					otherTT:SetFrameLevel(guildTT:GetFrameLevel() - 1)
				
					titleTT:SetPoint("BOTTOM", otherTT, "TOP", 0, -db.tooltipSpacing)
					titleTT:SetFrameLevel(otherTT:GetFrameLevel() - 1)
				end

				LF_DisplayTooltip()
		end,
		OnLeave = function()
				mod:HideTooltip()
		end,
	})
end

--**********************************************************************************************************************************************************
--------------------------------------------------------- Display LDB Message History
--**********************************************************************************************************************************************************

function mod:HideBrokerFrame()
	Frame_Messages:Hide()
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function mod:ShowBrokerFrame(plr)
	if not plr or db.enableMsgFrame then return end
	local path, ignoreT
	
	if dbr.chatHistory[plr] then
		if dbr.chatHistory[plr].BT and BNFeaturesEnabledAndConnected() and dbr.chatHistory[plr].tells == 0 then
			ignoreT = true
			path = dbg
			plr = dbr.chatHistory[plr].BT
		else 
			path = dbr 
		end
	elseif dbg.chatHistory[plr] then
		path = dbg
	else return end
	
	if not path.chatHistory[plr].message[1] then return end
	
	Frame_Messages:SetClampedToScreen(false)
	Frame_Messages:ClearAllPoints()
	if toolTUP then
		Frame_Messages:SetPoint("BOTTOM", mod.titleTT, "TOP")
	else
		Frame_Messages:SetPoint("TOP", mod.friendsTT, "BOTTOM")
	end
	
	SoDWhisper:UpdateMyFrame(Frame_Messages, plr, path, db.msgSortDown, ignoreT)
	
	Frame_Messages:Show()
	Frame_Messages:SetClampedToScreen(true)
end

--**********************************************************************************************************************************************************
---------------------------------------------------------------------- Tools
--**********************************************************************************************************************************************************

local function LF_ToggleMinimapIcon(HIDE)
	if HIDE then 
		LibDBIcon:Hide("SoDWhisper")
	else 
		LibDBIcon:Show("SoDWhisper") 
	end
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function mod:OnSkinUpdate()
	SoDWhisper:SkinMyFrame(Frame_Messages)
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function mod:HandleTTClick(name, button)
	if not name then return end
	local path = (dbr.chatHistory[name] and dbr) or dbg
	
	if name == "titleOptions" then
		db.tooltipOptions = not db.tooltipOptions
	elseif name == "timeframe" then
		if button == "RightButton" then
			db.tooltipTimeFrame = db.tooltipTimeFrame - 1
			if db.tooltipTimeFrame < 1 then 
				db.tooltipTimeFrame = 5 
			end
		else
			db.tooltipTimeFrame = db.tooltipTimeFrame + 1
			if db.tooltipTimeFrame > 5 then 
				db.tooltipTimeFrame = 1 
			end
		end
		SoDWhisper.timeframe = db.tooltipTimeFrame
		SoDWhisper:UpdateOtherToons()
	elseif name == "sortby" then
		db.tooltipSort = not db.tooltipSort 
	elseif name == "other" then
		if _G.IsShiftKeyDown() then
			for i,v in pairs(dbr.chatHistory) do
				if not v.typeBNtoon and not v.typeGuild and not v.typeRegFriend then
					if not v.changed then 
						dbr.chatHistory[i] = nil
					else 
						v.message, v.time, v.incoming, v.tells = {}, {}, {}, 0 
					end
				end
			end
			mod:LastSenderUpdate()
			return
		else
			return
		end
	elseif name == "guild" then
		if _G.IsShiftKeyDown() then
			for i,v in pairs(dbr.chatHistory) do
				if v.typeGuild and not v.typeRegFriend then
					if not v.changed then 
						dbr.chatHistory[i] = nil
					else 
						v.message, v.time, v.incoming, v.tells = {}, {}, {}, 0 
					end
				end
			end
			SoDWhisper:UpdateGuild()
			return
		else
			db.tooltipGuildTimeFrame = not db.tooltipGuildTimeFrame
		end
	elseif name == "friends" then
		if _G.IsShiftKeyDown() then
			for i,v in pairs(dbr.chatHistory) do
				if v.typeRegFriend then
					if not v.changed then 
						dbr.chatHistory[i] = nil
					else 
						v.message, v.time, v.incoming, v.tells = {}, {}, {}, 0 
					end
				end
			end
			for i,v in pairs(dbg.chatHistory) do
				if not v.changed then 
					dbg.chatHistory[i] = nil
				else 
					v.message, v.time, v.incoming, v.tells = {}, {}, {}, 0 
				end
			end
			SoDWhisper:UpdateBNFriends()
			SoDWhisper:UpdateRegFriends()
			return
		elseif button == "MiddleButton" then
			if db.tooltipFriendsTimeFrame then
				db.noAppAway = db.noAppAway + 1
				if db.noAppAway > 3 then 
					db.noAppAway = 1 
				end
				mod:LastSenderUpdate()
				return
			end
		else
			db.tooltipFriendsTimeFrame = not db.tooltipFriendsTimeFrame
		end
	elseif button == "RightButton" then
		if _G.IsControlKeyDown() then 
			SoDWhisper:UpdateChangePlayerName(name, path)
		elseif path.chatHistory[name].toon and dbr.chatHistory[path.chatHistory[name].toon] then 
			_G.SetItemRef("player:"..path.chatHistory[name].toon, "|Hplayer:"..path.chatHistory[name].toon.."|h["..path.chatHistory[name].toon.."]|h", "LeftButton")
		end
	else
		if _G.IsControlKeyDown() then
			SoDWhisper:ShowLogFrame(name, path)
		elseif _G.IsShiftKeyDown() then
			path.chatHistory[name].message, path.chatHistory[name].time, path.chatHistory[name].incoming, path.chatHistory[name].tells = {}, {}, {}, 0 
			mod:LastSenderUpdate()
			return
		elseif _G.IsAltKeyDown() then
			if path.chatHistory[name].pID then
				_G.FriendsFrame_BattlenetInvite(nil, path.chatHistory[name].pID)
			else
				_G.InviteUnit(name)
			end
		else
			if path == dbg then
				local presID, plr = SoDWhisper:CompareBattleTag(name)
				if presID then
					plr = plr..":"..presID
					_G.SetItemRef( "BNplayer:"..plr, ("|HBNplayer:%1$s|h[%1$s]|h"):format(plr), "LeftButton")
				end
			else
				_G.SetItemRef("player:"..name, "|Hplayer:"..name.."|h["..name.."]|h", "LeftButton")
			end
		end
	end
	LF_DisplayTooltip()
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function mod:LastSenderUpdate()
	lastsender, lastsenderpath = SoDWhisper.lastSender, SoDWhisper.lastSenderPath
	local GuildFriends, tempSubtract = "", 0
	
	if dbr.chatHistory then
		for i,v in pairs(dbr.chatHistory) do
			if v.time[1] and v.tells > 0 then
				table_insert(MissedTempTB, {time = v.time[#v.time], plr = i, tells = v.tells, isDBR = true})
			end
		end
	end
	if dbg.chatHistory then
		for i,v in pairs(dbg.chatHistory) do
			if v.time[1] and v.tells > 0 then
				table_insert(MissedTempTB, {time = v.time[#v.time], plr = i, tells = v.tells, isDBR = false})
			end 
			if db.showOnlineCount then
				if db.noAppAway == 2 and v.online and v.client and v.client == "App" and v.status and string_find(v.status, "<AFK>") then
					tempSubtract = tempSubtract + 1
				elseif db.noAppAway == 3 and v.online and v.client and v.client == "App" then
					tempSubtract = tempSubtract + 1
				end
			end
		end
	end
	
	if db.showOnlineCount then
		local onFriends, onGuild = SoDWhisper:GetOnlineCount()
		GuildFriends = "|cff00ff00"..onFriends - tempSubtract.."|r|||cff00ff00"..onGuild.."|r "
	end
	
	if MissedTempTB[1] then
		if MissedTempTB[2] then table_sort(MissedTempTB, function(a,b) return a.time>b.time end) end
		lastsender = MissedTempTB[1].plr
		lastsenderpath = ( MissedTempTB[1].isDBR and dbr ) or dbg
		
		local lastsendercombi
		if lastsenderpath.chatHistory[lastsender].online then
			lastsendercombi = lastsenderpath.chatHistory[lastsender].displayName..string_format("(%s)", MissedTempTB[1].tells)
			lastsendercombi = SoDWhisper:FormatPlayerName(lastsendercombi, lastsender, lastsenderpath)
		else
			lastsendercombi = "|c00585858"..lastsenderpath.chatHistory[lastsender].displayName.."|r"..string_format("(%s)", MissedTempTB[1].tells)
		end
		
		mod.obj.text = GuildFriends..lastsendercombi
		mod.obj.icon = db.changeIcon and ICON_MISSED or ICON_NORMAL
		wipe(MissedTempTB)
	elseif lastsender and lastsenderpath.chatHistory[lastsender] and lastsenderpath.chatHistory[lastsender].time[1] then
		local lastsendercombi
		if lastsenderpath.chatHistory[lastsender].online then
			lastsendercombi = SoDWhisper:FormatPlayerName(lastsenderpath.chatHistory[lastsender].displayName, lastsender, lastsenderpath)
		else
			lastsendercombi = "|c00585858"..lastsenderpath.chatHistory[lastsender].displayName.."|r"
		end
		
		mod.obj.text = GuildFriends..lastsendercombi.."    "
		mod.obj.icon = ICON_NORMAL
	else
		mod.obj.text = GuildFriends.."SoDWhisper "
		mod.obj.icon = ICON_NORMAL
		lastsender, lastsenderpath = nil, nil
	end
	if mod.titleTT and mod.titleTT:IsShown() then
		LF_DisplayTooltip()
	end
end

--**********************************************************************************************************************************************************
-------------------------------------------------------------- Initialisation Functions
--**********************************************************************************************************************************************************

function mod:OnInitialize()
	mod.db = SoDWhisper.db:RegisterNamespace(MODNAME, defaults)
	db = mod.db.profile
	
	mod:SetEnabledState(SoDWhisper.db.profile.modules[module])
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function mod:OnEnable()
	dbg = SoDWhisper.db.global
	dbr = SoDWhisper.db.factionrealm
	SoDWhisper.timeframe = db.tooltipTimeFrame
	
	mod:RegisterMessage("SoDWhisper_MESSAGE", "LastSenderUpdate")
	mod:RegisterMessage("SoDWhisper_SKIN", "OnSkinUpdate")
	
	Frame_Messages = SoDWhisper:CreateMyFrame("MESSAGES", db.frameWidth)
	
	Frame_GetLength = _G.CreateFrame("Frame", "SoDWhisper_BP_LENGTH", _G.UIParent)
	Frame_GetLength:SetScale(GameTooltip:GetScale())
	Frame_GetLength.text = Frame_GetLength:CreateFontString("SoDWhisper_MEASURELENGTH", "ARTWORK", "GameTooltipText")
	
	mod:CreateLDBObject()
	if not LibDBIcon:IsRegistered("SoDWhisper") then 
		LibDBIcon:Register("SoDWhisper", mod.obj, db.minimap) 
	end
	
	mod:OnSkinUpdate()
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function mod:OnDisable()
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function mod:ProfileChanged()
	db = mod.db.profile
	SoDWhisper.timeframe = db.tooltipTimeFrame
	
	-- Manually toggle Hide/Show Minimap Button. Because it does not currently work behind the scenes
	LF_ToggleMinimapIcon(db.minimap.hide)
	mod:LastSenderUpdate()
end

--**********************************************************************************************************************************************************
------------------------------------------------------------------ Options
--**********************************************************************************************************************************************************

local options
function mod:GetOptions()
	if options then return options end
	options = {
		type = "group",
		name = L["LDB/Minimap Plugin"],
		get = function(info) return db[ info[#info] ] end,
		set = function(info, v) db[ info[#info] ] = v end,
		childGroups = "tab",
		args = {
			titleEnable = {
				type = "group",
				order = 0,
				name = L["LDB/Minimap Plugin"],
				inline = true,
				args = {
					temptoggle = {
						type = "toggle", 
						name = L["Enable"], 
						desc = L["Quickly view information from the minimap or type of LDB display."], 
						get = function() return SoDWhisper.db.profile.modules[MODNAME] end,
						set = function(_, v) SoDWhisper.db.profile.modules[MODNAME] = v
							if v then
								SoDWhisper:EnableModule(MODNAME)
							else
								SoDWhisper:DisableModule(MODNAME)
							end
						end,
					},
				},
			},
			brokericon = {
				type = "group",
				name = L["Icon"],
				disabled = function() return not mod:IsEnabled() end,
				args = {
					toggleminimap = {
						type = "toggle",
						order = 0,
						name = L["Hide Minimap Icon"],
						get = function() return db.minimap.hide end,
						set = function(_, v) db.minimap.hide = v 
							LF_ToggleMinimapIcon(v) end,
					},
					changeIcon = {
						type = "toggle",
						name = L["Change Icon"],
						desc = L["Change icon while there is an unchecked messages."],
					},
					showOnlineCount = {
						type = "toggle",
						name = L["Show Online Count"],
						desc = L["Show online count in LDB text (ex. 2Friends | 4Guild online)."],
						set = function(info, v) db[ info[#info] ] = v 
							mod:LastSenderUpdate() end,
					},
					b2f = {
						type = "execute",
						order = -1,
						name = L["Broker2FuBar Options"],
						desc = L["Open the Broker2FuBar options panel."],
						hidden = function() return not IsAddOnLoaded('Broker2FuBar') end,
						func = function() LibStub("AceAddon-3.0"):GetAddon("Broker2FuBar", true):OpenGUI() end,
					},
				},
			},
	------------------------------------------------------------------------------------------------------------------------------------------------------------
			brokerappearance = {
				type = "group",
				name = L["Appearance"],
				disabled = function() return not mod:IsEnabled() end,
				args = {
					maxTTHeight = {
						type = "range",
						name = L["Max Tooltip Height"],
						desc = L["Max height of tooltip before scrolling enables."],
						min = 125, max = 700, step = 1,
					},
					tooltipSpacing = {
						type = "range",
						name = L["Tooltip Spacing"],
						desc = L["Space between tooltips."],
						min = -15, max = 15, step = 1,
					},
					textures = {
						type = "group",
						order = -1,
						name = L["Format Tooltip"],
						inline = true,
						disabled = function() return not db.enableFormatTT end,
						args = {
							enableFormatTT = {
								type = "toggle",
								order = 2,
								name = L["Enable"],
								desc = L["Set background and border of tooltip."],
								disabled = false,
							},
							scaleTT = {
								type = "range",
								order = 4,
								name = L["Scale"],
								min = .5, max = 2, step = .01,
							}, 
							bgColorTT = {
								type = "color",
								order = 5,
								name = L["Background Color"],
								hasAlpha = true,
								get = function(info) local c = db[ info[#info] ] 
									return c[1], c[2], c[3], c[4] end,
								set = function(info, r, g, b, a) db[ info[#info] ] = {r, g, b, a} end,
							},
							bgTextureTT = {
								type = 'select',
								order = 10,
								name = L["Background"],
								desc = L["Change the background texture (For some textures the background color needs to be set to white)."],
								dialogControl = "LSM30_Background",
								values = AceGUIWidgetLSMlists.background,
							},
							borderColorTT = {
								type = 'color',
								order = 15,
								name = L["Border Color"],
								hasAlpha = true,
								get = function(info) local c = db[ info[#info] ] 
									return c[1], c[2], c[3], c[4] end,
								set = function(info, r, g, b, a) db[ info[#info] ] = {r, g, b, a} end,
							},        
							borderTextureTT = {
								type = 'select',
								order = 20,
								name = L["Border Style"],
								desc = L["Change the border style of the panel."],
								dialogControl = "LSM30_Border",
								values = AceGUIWidgetLSMlists.border,
							},
						},
					},
				},
			},
	------------------------------------------------------------------------------------------------------------------------------------------------------------
			brokermessage = {
				type = "group",
				name = L["Messages"],
				desc = L["Message history for the LDB/Minimap tooltip."],
				disabled = function() return not mod:IsEnabled() end,
				args = {
					enableMsgFrame = {
						type = 'toggle',
						order = 0,
						name = L["Hide Message Panel"],
						desc = L["Hide message history panel and hover over missed message checking for LDB/Minimap tooltip."],
					},
					msgSortDown = {
						type = 'toggle',
						name = L["Message Sort"],
						desc = L["Show entries from old to new on the message panel for the LDB/Minimap Plugin."],
						disabled = function() return db.enableMsgFrame end,
					},
					frameWidth = {
						type = "range",
						name = L["Panel Width"],
						desc = L["Panel Width of message history for LDB/Minimap tooltip."],
						set = function(info, v) db[ info[#info] ] = v 
							Frame_Messages:SetWidth(v) end,
						min = 300, 
						max = 700, 
						step = 1,
						disabled = function() return db.enableMsgFrame end,
					},
				},
			},
		},
	}
	
	return options 
end
