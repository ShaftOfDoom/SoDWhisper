-- AddOn nameSpace
local SoDWhisper = LibStub("AceAddon-3.0"):GetAddon("SoDWhisper")
local L = SoDWhisper.L

local MODNAME = "Editbox_Plugin"
local mod = SoDWhisper:NewModule(MODNAME, "AceEvent-3.0", "AceHook-3.0")
local LibQTip = LibStub('LibQTip-1.0')
SoDWhisper.LibQTip = LibQTip
local LSM = SoDWhisper.LSM

-- UpValue
local _G = _G
local string_find = _G.string.find
local string_match = _G.string.match
local math_min = _G.math.min
local math_max = _G.math.max

-- Constants
local INVITE_ICON = "|TInterface\\AddOns\\SoDWhisper\\MediaFiles\\Icon-Invite:17|t"
local ADD_FRIEND_ICON = "|TInterface\\AddOns\\SoDWhisper\\MediaFiles\\Icon-Add:17|t"
local IGNORE_ICON = "|TInterface\\AddOns\\SoDWhisper\\MediaFiles\\Icon-Ignore:17|t"
local LOCATION_ICON = "|TInterface\\AddOns\\SoDWhisper\\MediaFiles\\Icon-Location:17|t"
local COPY_ICON = "|TInterface\\AddOns\\SoDWhisper\\MediaFiles\\Icon-History:10|t"
local LINK_TYPES = SoDWhisper.LINK_TYPES

-- Frames
local Frame_EditBox								-- Frame for Messages
local Frame_EditBox_Title						-- Frame for Messages Title

-- Variables
local dbg, dbr, db								-- SoDWhisper.db.global, SoDWhisper.db.factionrealm, mod.db.profile
local openEBName, openEBPath					-- Open EditBox player information

local defaults = {
	profile = {
		enable = true,
		-- Appearance
		hideInCombat = false,					-- Hide message panel in combat
		msgSortDown = true,						-- Sorts message
		titlescale = .9,						-- Scale of message pane's title
		-- Position
		locked = true,							-- Locks the message pane in place
		growUp = true,							-- Grow the pane upwards
		snapToEditbox = true,					-- Snap the pane to the inputBox
		snapSpace = 0,							-- Snap space between inputBox and history frame
		-- Saved Information
		frameWidth = 400,						-- Width of message pane
		frameLeft = 10,							-- Position of message pane
		frameTop = 370,							-- Position of message pane
		frameBottom = 400,						-- Position of message pane
	}
}

--**********************************************************************************************************************************************************
-------------------------------------------------------------- Frame Positioning
--**********************************************************************************************************************************************************

local function LF_SetPosition()
	Frame_EditBox:ClearAllPoints()
	local ChatFrameEditBox = _G.ChatEdit_GetActiveWindow()
	if db.snapToEditbox and ChatFrameEditBox then
		db.frameWidth = ChatFrameEditBox:GetRight() - ChatFrameEditBox:GetLeft()
		if db.growUp then
			Frame_EditBox:SetPoint("BOTTOMLEFT", ChatFrameEditBox, "TOPLEFT", 0, db.snapSpace)
		else
			Frame_EditBox:SetPoint("TOPLEFT", ChatFrameEditBox, "BOTTOMLEFT", 0, db.snapSpace)
		end
	else
		if db.growUp then
			Frame_EditBox:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", db.frameLeft, db.frameBottom)
		else
			Frame_EditBox:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db.frameLeft, db.frameTop)
		end
	end
	Frame_EditBox:SetWidth(db.frameWidth)
	
	if Frame_EditBox_Title then
		Frame_EditBox_Title:ClearAllPoints()
		Frame_EditBox_Title:SetPoint(db.growUp and "BOTTOMRIGHT" or "TOPRIGHT", Frame_EditBox, db.growUp and "TOPRIGHT" or "BOTTOMRIGHT")
	end
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

local function LF_SavePosition()
	db.frameWidth = Frame_EditBox:GetRight() - Frame_EditBox:GetLeft()
	Frame_EditBox:SetWidth(db.frameWidth)
	db.frameLeft = Frame_EditBox:GetLeft()
	db.frameTop = Frame_EditBox:GetTop()
	db.frameBottom = Frame_EditBox:GetBottom()
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

local function LF_ResetPosition()
	db.frameWidth = 400
	db.frameLeft = 10
	db.frameTop = 370
	db.frameBottom = 400
	db.snapSpace = 0
	LF_SetPosition()
end

--**********************************************************************************************************************************************************
----------------------------------------------------------------- Create TitleBox
--**********************************************************************************************************************************************************

local function LF_SetupEditboxtTitle()	
	local dbH = openEBPath.chatHistory[openEBName]
	local tempIsBT = (openEBPath == dbg and true) or nil
	
	local editboxTitle = LibQTip:Acquire("SoDWhisper_EditboxTitle", 6, "LEFT", "RIGHT", "RIGHT", "RIGHT", "RIGHT", "RIGHT")
	Frame_EditBox_Title = editboxTitle
	
	editboxTitle:SetFrameStrata(Frame_EditBox:GetFrameStrata())
	editboxTitle:Clear()
	editboxTitle:SetScale(db.titlescale)
	
	local bg = LSM:Fetch('background', SoDWhisper.db.profile.bgTexture, "Blizzard Tooltip")
	local ed = LSM:Fetch('border', SoDWhisper.db.profile.borderTexture, "Blizzard Tooltip")
	editboxTitle:SetBackdrop({bgFile = bg, tile = true, tileSize = 16, edgeFile = ed, edgeSize = 16, insets = {left = 3, right = 3, top = 3, bottom = 3}})
	local c,d = SoDWhisper.db.profile.bgColor, SoDWhisper.db.profile.borderColor
	editboxTitle:SetBackdropColor(c[1], c[2], c[3], c[4])
	editboxTitle:SetBackdropBorderColor(d[1], d[2], d[3], d[4])
	
	editboxTitle:AddHeader()
	
	editboxTitle:SetCell(1, 1, COPY_ICON, nil, "RIGHT")
	editboxTitle:SetCellScript(1, 1, "OnMouseDown", mod.HandleTTClick, "COPY_ICON")
	
	if tempIsBT then
		local templvl, tempToonDN = "", ""
		if dbH.online then
			if dbH.client and dbH.client == _G.BNET_CLIENT_WOW then
				templvl = SoDWhisper:GetColoredLevel(dbH.level, dbH.online, true, true)
			end	
			tempToonDN = " - "..SoDWhisper:GetDisplayNameForTooltip(openEBName, openEBPath, true, true, true, 16)
		end
		editboxTitle:SetCell(1, 2, templvl..SoDWhisper:GetDisplayNameForTooltip(openEBName, openEBPath, true, nil, true, 16)..tempToonDN, nil, "LEFT")
	else 
		editboxTitle:SetCell(1, 2, SoDWhisper:GetColoredLevel(dbH.level, dbH.online, nil, true)..SoDWhisper:GetDisplayNameForTooltip(openEBName, openEBPath, nil, nil, nil, 16), nil, "LEFT")
	end
	editboxTitle:SetCellScript(1, 2, "OnMouseDown", function()
		SoDWhisper:UpdateChangePlayerName(openEBName, openEBPath)
	end)
	
	editboxTitle:SetCell(1, 3, INVITE_ICON, nil, "RIGHT", tempIsBT and 3 or nil)
	editboxTitle:SetCellScript(1, 3, "OnMouseDown", mod.HandleTTClick, "INVITE_ICON")
	
	if not tempIsBT then
		editboxTitle:SetCell(1, 4, ADD_FRIEND_ICON, nil, "RIGHT")
		editboxTitle:SetCellScript(1, 4, "OnMouseDown", mod.HandleTTClick, "ADD_FRIEND_ICON")
		
		editboxTitle:SetCell(1, 5, IGNORE_ICON, nil, "RIGHT")
		editboxTitle:SetCellScript(1, 5, "OnMouseDown", mod.HandleTTClick, "IGNORE_ICON")
	end
	
	editboxTitle:SetCell(1, 6, LOCATION_ICON, nil, "RIGHT")
	editboxTitle:SetCellScript(1, 6, "OnMouseDown", mod.HandleTTClick, "LOCATION_ICON")
	editboxTitle:SetCellScript(1, 6, "OnEnter", function()
					local titletooltip = LibQTip:Acquire("SoDWhisper_TitleTooltip", 1, "CENTER")
					mod.titletooltip = titletooltip
					titletooltip:Clear()
					titletooltip:SetScale(db.titlescale)
					titletooltip:ClearAllPoints()
					titletooltip:SetPoint(db.growUp and "BOTTOMRIGHT" or "TOPRIGHT", editboxTitle, db.growUp and "TOPRIGHT" or "BOTTOMRIGHT")
					
					titletooltip:SetBackdrop({bgFile = bg, tile = true, tileSize = 16, edgeFile = ed, edgeSize = 16, insets = {left = 3, right = 3, top = 3, bottom = 3}})
					titletooltip:SetBackdropColor(c[1], c[2], c[3], c[4])
					titletooltip:SetBackdropBorderColor(d[1], d[2], d[3], d[4])
					
					if dbH.zone and dbH.zone ~= "" then
						titletooltip:AddHeader(SoDWhisper:GetZoneColor(dbH.zone))
					end
					if dbH.guild and dbH.guild ~= "" then
						titletooltip:AddHeader("<"..dbH.guild..">")
					end
					if tempIsBT and dbH.online and dbH.client == _G.BNET_CLIENT_WOW then
						titletooltip:AddHeader(SoDWhisper:GetRealmForTooltip(openEBName, false, 16, openEBPath))
					end
					
					if titletooltip:GetLineCount() ~= 0 then
						titletooltip:Show()
					end
		end)
	editboxTitle:SetCellScript(1, 6, "OnLeave", function()
				mod.titletooltip:Hide()
				LibQTip:Release(mod.titletooltip)
				mod.titletooltip = nil
	end)
end

--**********************************************************************************************************************************************************
----------------------------------------------------------------- Edit-box Functions 
--**********************************************************************************************************************************************************

local function LF_ChatEdit_OnHide()
	if Frame_EditBox_Title then
		Frame_EditBox_Title:Hide()
		LibQTip:Release(Frame_EditBox_Title)
		Frame_EditBox_Title = nil
	end
	Frame_EditBox:Hide()
	openEBName, openEBPath = nil, nil
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

local function LF_ShowFrame()
	if not openEBName or not openEBPath or not openEBPath.chatHistory[openEBName].message[1] then return end
	
	LF_SetupEditboxtTitle() 	-- Must be before SetPostion	
	LF_SetPosition() 			-- Must be before UpdateMyFrame function
	SoDWhisper:UpdateMyFrame(Frame_EditBox, openEBName, openEBPath, db.msgSortDown)	
	
	Frame_EditBox:Show()
	Frame_EditBox_Title:Show()
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function mod:ChatEdit_Update(self)
	if not _G.ChatEdit_GetActiveWindow() or (db.hideInCombat and _G.InCombatLockdown()) then 
		LF_ChatEdit_OnHide()
		return 
	end
	
	local chatAttribute = self:GetAttribute("chatType")
	if chatAttribute == "WHISPER" then
		local tarAttribute = self:GetAttribute("tellTarget")
		if not string_find(tarAttribute,"-") then 
			tarAttribute = tarAttribute.."-"..SoDWhisper.player.realm 
		end
		
		if dbr.chatHistory[tarAttribute] then
			if dbr.chatHistory[tarAttribute].BT and _G.BNFeaturesEnabledAndConnected() then
				if dbg.chatHistory[dbr.chatHistory[tarAttribute].BT] and dbg.chatHistory[dbr.chatHistory[tarAttribute].BT].message[1] then
					if dbr.chatHistory[tarAttribute].BT == openEBName and dbg == openEBPath then return end  -- stops mod:ChatEdit_Update's rapid firing
					openEBName, openEBPath = dbr.chatHistory[tarAttribute].BT, dbg
					LF_ShowFrame()
				elseif dbr.chatHistory[tarAttribute].message[1] then
					if tarAttribute == openEBName and dbr == openEBPath then return end  -- stops mod:ChatEdit_Update's rapid firing
					openEBName, openEBPath = tarAttribute, dbr
					LF_ShowFrame()	
				else 
					LF_ChatEdit_OnHide() 
				end
			elseif dbr.chatHistory[tarAttribute].message[1] then
				if tarAttribute == openEBName and dbr == openEBPath then return end  -- stops mod:ChatEdit_Update's rapid firing
				openEBName, openEBPath = tarAttribute, dbr
				LF_ShowFrame()
			else 
				LF_ChatEdit_OnHide() 
			end
		else 
			LF_ChatEdit_OnHide() 
		end
	elseif chatAttribute == "BN_WHISPER" then
		local tarAttribute = self:GetAttribute("tellTarget")
		
		if _G.GetAutoCompletePresenceID(tarAttribute) then
			local acc = C_BattleNet.GetAccountInfoByID(_G.GetAutoCompletePresenceID(tarAttribute))
			tarAttribute = ( not acc.battleTag and acc.accountName ) or acc.battleTag
		end
		
		if dbg.chatHistory[tarAttribute] and dbg.chatHistory[tarAttribute].message[1] then
			if tarAttribute == openEBName and dbg == openEBPath then return end  -- stops mod:ChatEdit_Update's rapid firing
			openEBName, openEBPath = tarAttribute, dbg
			LF_ShowFrame()
		else 
			LF_ChatEdit_OnHide() 
		end
	else 
		LF_ChatEdit_OnHide() 
	end
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function mod:HandleTTClick(name, button)
	if not name then return end
	
	if name == "INVITE_ICON" then
		if openEBPath.chatHistory[openEBName].pID then
			_G.FriendsFrame_BattlenetInvite(nil, openEBPath.chatHistory[openEBName].pID)
		else
			_G.InviteUnit(openEBName)
		end
	elseif name == "COPY_ICON" then
		SoDWhisper:ShowLogFrame(openEBName, openEBPath)
	elseif name == "ADD_FRIEND_ICON" then
		if _G.BNFeaturesEnabledAndConnected() then
			_G.AddFriendEntryFrame_Collapse(true)
			_G.AddFriendFrame.editFocus = _G.AddFriendNameEditBox
			_G.StaticPopupSpecial_Show(_G.AddFriendFrame)
			
			if _G.GetCVarBool("addFriendInfoShown") then
				_G.AddFriendFrame_ShowEntry()
			else
				_G.AddFriendFrame_ShowInfo()
			end
		else
			_G.StaticPopup_Show("ADD_FRIEND")
		end	
	elseif name == "IGNORE_ICON" then
		_G.AddOrDelIgnore(openEBName)
	elseif name == "LOCATION_ICON" then
		if openEBPath == dbr and SoDWhisper:GetConnectedAnsOrName(openEBName) then
			local wholib = SoDWhisper
			wholib:Who(openEBName, {queue = wholib.WHOLIB_QUEUE_USER})
		end
	end
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function mod:UpdateOpenEditBox()
	if SoDWhisper.lastSender == openEBName and SoDWhisper.lastSenderPath == openEBPath then
		SoDWhisper:UpdateMyFrame(Frame_EditBox, openEBName, openEBPath, db.msgSortDown)
	end
end

--**********************************************************************************************************************************************************
------------------------------------------------------------- Create EditBox Frame
--**********************************************************************************************************************************************************

function mod:OnSkinUpdate()
	SoDWhisper:SkinMyFrame(Frame_EditBox)
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

local function LF_AddDragFrame(parent, anchor1, align1, anchor2, align2, direction)
	local f = _G.CreateFrame("Frame", nil, parent)
	f:Show()
	if not db.locked then
		f:SetFrameLevel(parent:GetFrameLevel() + 10)
	else
		f:SetFrameLevel(parent:GetFrameLevel() - 10)
	end
	f:SetWidth(16)
	f:SetPoint(anchor1, parent, align1, 0, 0)
	f:SetPoint(anchor2, parent, align2, 0, 0)
	f:EnableMouse(true)
	
	f:SetScript("OnMouseDown", function(self, arg1) 
		if not db.locked and arg1 == "LeftButton" then
			self:GetParent().isResizing = true
			self:GetParent():StartSizing(direction)
		end 
	end)
	f:SetScript("OnMouseUp", function(self, arg1) 
		if self:GetParent().isResizing == true then 
			self:GetParent():StopMovingOrSizing()
			self:GetParent().isResizing = false
			LF_SavePosition()
			if openEBName and openEBPath then
				SoDWhisper:UpdateMyFrame(Frame_EditBox, openEBName, openEBPath, db.msgSortDown)
			end
		end
	end)
	return f
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

local function LF_CreateFrame()
	local f = SoDWhisper:CreateMyFrame("EDITBOX", db.frameWidth)
	Frame_EditBox = f
	f:EnableMouse(true)
	f:SetResizable(true)
	f:SetMovable(true)
	
	f:SetScript("OnMouseDown", function(self, arg1) 
		if not db.locked and arg1 == "LeftButton" then
			self:StartMoving()
			self.isMoving = true
		end
	end)
	
	f:SetScript("OnMouseUp", function(self, arg1) 
		if not db.locked and arg1 == "LeftButton" then
			self:StopMovingOrSizing()
			self.isMoving = false
			LF_SavePosition()
		end
	end)
	
	f.sChild:SetHyperlinksEnabled(true)
		
	f.sChild:SetScript("OnHyperlinkEnter", function(_, link)
			local t = string_match(link, "^([^:]+)")
			if t and LINK_TYPES[t] then
				local isLeft = select(1, f:GetCenter()) > (_G.UIParent:GetWidth() / f:GetScale()) / 2
				local position
				if db.growUp then
					position = isLeft and "ANCHOR_LEFT" or "ANCHOR_RIGHT"
				else
					position = isLeft and "ANCHOR_BOTTOMLEFT" or "ANCHOR_BOTTOMRIGHT"
				end
				_G.GameTooltip:SetOwner(f, position)
				_G.GameTooltip:SetHyperlink(link)
				_G.GameTooltip:Show()
			end
	end)
	f.sChild:SetScript("OnHyperlinkLeave", _G.GameTooltip_Hide)
	f.sChild:SetScript("OnHyperlinkClick", _G.ChatFrame_OnHyperlinkShow)
	
	f.sChild:SetScript("OnMouseWheel", function(self, delta)
			if not f.enableMouseWheel then return end
			local currentValue = f.slider:GetValue()
			local minValue, maxValue = f.slider:GetMinMaxValues()

			if delta < 0 and currentValue < maxValue then
				if _G.IsControlKeyDown() then
					f.slider:SetValue(maxValue)
				elseif _G.IsShiftKeyDown() then
					f.slider:SetValue(math_min(maxValue, currentValue + 60))
				else
					f.slider:SetValue(math_min(maxValue, currentValue + 30))
				end
			elseif delta > 0 and currentValue > minValue then
				if _G.IsControlKeyDown() then
					f.slider:SetValue(minValue)
				elseif _G.IsShiftKeyDown() then
					f.slider:SetValue(math_max(minValue, currentValue - 60))
				else
					f.slider:SetValue(math_max(minValue, currentValue - 30))
				end
			end
	end)
	
	Frame_EditBox.dragRight = LF_AddDragFrame(f, "BOTTOMRIGHT", "BOTTOMRIGHT", "TOPRIGHT", "TOPRIGHT", "RIGHT")
	Frame_EditBox.dragLeft  = LF_AddDragFrame(f, "BOTTOMLEFT", "BOTTOMLEFT", "TOPLEFT", "TOPLEFT", "LEFT")
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
	
	mod:RegisterMessage("SoDWhisper_SKIN", "OnSkinUpdate")
	mod:RegisterMessage("SoDWhisper_UPDATE_EDITBOX", "UpdateOpenEditBox")
	mod:SecureHook("ChatEdit_UpdateHeader", "ChatEdit_Update")
	mod:SecureHook("ChatEdit_DeactivateChat", "ChatEdit_Update")
		
	LF_CreateFrame()
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function mod:OnDisable()
	LF_ChatEdit_OnHide()
	mod:UnregisterAllEvents()
	mod:UnhookAll()
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function mod:ProfileChanged()
	db = mod.db.profile
end

--**********************************************************************************************************************************************************
------------------------------------------------------------- Options 
--**********************************************************************************************************************************************************

local options
function mod:GetOptions()
	if options then return options end
	options = {
		type = "group",
		name = L["Editbox Plugin"],
		get = function(info) return db[ info[#info] ] end,
		set = function(info, v) db[ info[#info] ] = v end,
		childGroups = "tab",
		args = {
			titleEnable = {
				type = "group",
				order = 0,
				name = L["Editbox Plugin"],
				inline = true,
				args = {
					temptoggle = {
						type = "toggle", 
						name = L["Enable"], 
						desc = L["This plugin will show your current conversation when you are sending a whisper to someone."], 
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
			editboxappearance = {
				type = "group",
				name = L["Appearance"],
				disabled = function() return not mod:IsEnabled() end,
				args = {
					hideInCombat = {
						type = "toggle",
						name = L["Hide In Combat"],
					},
					msgSortDown = {
						type = "toggle",
						name = L["Message Sort"],
						desc = L["Show entries from old to new on the message panel for the EditBox."],
					},
					titlescale = {
						type = "range",
						name = L["Title Scale"],
						min = .5, 
						max = 2, 
						step = .01,
					}, 
				},
			},
	------------------------------------------------------------------------------------------------------------------------------------------------------------
			editboxposition = {
				type = "group",
				name = L["Position"],
				disabled = function() return not mod:IsEnabled() end,
				args = {
					snapGroup = {
						type = "group",
						order = 5,
						name = L["Anchor"],
						inline = true,
						args = {
							locked = {
								type = "toggle",
								order = 0,
								name = L["Lock"],
								desc = L["Locks the panel."],
								set = function(info, v) db[ info[#info] ] = v
									if v then
										Frame_EditBox.dragRight:SetFrameLevel(Frame_EditBox:GetFrameLevel() - 10)
										Frame_EditBox.dragLeft:SetFrameLevel(Frame_EditBox:GetFrameLevel() - 10)
									else
										db.snapToEditbox = false
										Frame_EditBox.dragRight:SetFrameLevel(Frame_EditBox:GetFrameLevel() + 10)
										Frame_EditBox.dragLeft:SetFrameLevel(Frame_EditBox:GetFrameLevel() + 10)
									end
								end,
							},
							growUp = {
								type = "toggle",
								order = 10,
								name = L["Grow Up"],
								desc = L["The panel will grow up from the set position."],
								set = function(info, v) db[ info[#info] ] = v LF_SetPosition() end,
							}, 
							snapToEditbox = {
								type = "toggle",
								order = 15,
								name = L["Snap To Inputbox"],
								desc = L["Makes the panel stick to the inputbox."],
								set = function(info, v) db[ info[#info] ] = v
									if v then 
										db.locked = true
										LF_SetPosition()
										LF_SavePosition()
										Frame_EditBox.dragRight:SetFrameLevel(Frame_EditBox:GetFrameLevel() - 10)
										Frame_EditBox.dragLeft:SetFrameLevel(Frame_EditBox:GetFrameLevel() - 10)
										if openEBName and openEBPath then
											SoDWhisper:UpdateMyFrame(Frame_EditBox, openEBName, openEBPath, db.msgSortDown)
										end
									end
								end,
							},
							snapSpace = {
								type = "range",
								order = 20,
								name = L["Snap Spacing"],
								desc = L["Space between inputbox and message history pane."],
								min = -30,
								max = 30,
								step = 1,
								disabled = function() return not db.snapToEditbox end,
							},
						},
					},
					reset = {
						type = "execute",
						order = -1,
						name = L["Reset Position"],
						desc = L["Reset the position of the panel."],
						func = function() LF_ResetPosition() end,
					},
					
				},
			},
		},
	}
	return options
end
