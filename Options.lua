-- AddOn nameSpace
local SoDWhisper = LibStub("AceAddon-3.0"):GetAddon("SoDWhisper")
local L
local Dialog

-- Variables
local db

--**********************************************************************************************************************************************************
-------------------------------------------------------------------- Options 
--**********************************************************************************************************************************************************

local TIME_FORMATS, SOUND_OUTPUT, REALID_FORMATS, FRAME_STRATA
local options
local function LF_GetOptions()	
	if options then return options end
	
	TIME_FORMATS = {
		["1"] = L["None"],
		["2%X"] = L["HH:MM:SS (24-hour)"],
		["3%H:%M"] = L["HH:MM (24-hour)"],
		["4%I:%M:%S %p"] = L["HH:MM:SS AM (12-hour)"],
		["5%I:%M:%S"] = L["HH:MM:SS (12-hour)"],
		["6%I:%M %p"] = L["HH:MM AM (12-hour)"],
		["7%I:%M"] = L["HH:MM (12-hour)"],
		["8%M:%S"] = L["MM:SS"],
	}

	SOUND_OUTPUT = {
		["1Master"] = L["Master sound"],
		["2SFX"] = L["SFX sound"],
		["3Music"] = L["Music sound"],
		["4Ambience"] = L["Ambience sound"],
	}

	REALID_FORMATS = {
		["FIRST"] = L["First name"],
		["LAST"] = L["Last name"],
		["FULL"] = L["Full name"],
	}

	FRAME_STRATA = {
		["1DIALOG"] = L["DIALOG"],
		["2HIGH"] = L["HIGH"],
		["3MEDIUM"] = L["MEDIUM"],
		["4LOW"] = L["LOW"],
	}
	
	options = {
		type = "group",
		name = "SoDWhisper: "..GetAddOnMetadata("SoDWhisper", "Version"),
		get = function(info) return db[ info[#info] ] end,
		set = function(info, v) db[ info[#info] ] = v end,
		args = {
			general = {
				type = "group",
				order = 0,
				name = L["General Settings"],
				args = {
					hints = {
						type = "group",
						name = L["Hints"],
						childGroups = "tab",
						args = {
							editboxhints = {
								type = "group",
								name = L["Editbox Plugin"],
								args = {
									editboxdescriptionCT = {
										type = "group",
										name = L["Player Title"],
										inline = true,
										args = {
											editboxdescription = {
												type = "description",
												name = "|c00ffff00"..L["Page Icon"].."|r - |c001eff00"..L["Open Chat History Log Frame for player"]..
													"|r\n|c00ffff00"..L["Player Name"].."|r - |c001eff00"..L["Open Change Display Name Frame for player"]..
													"|r\n|c00ffff00"..L["Group Icon"].."|r - |c001eff00"..L["Invite player to group"]..
													"|r\n|c00ffff00"..L["Add Icon"].."|r - |c001eff00"..L["Add player to friends"]..
													"|r\n|c00ffff00"..L["Ignore Icon"].."|r - |c001eff00"..L["Ignore or stop ignoring player"]..
													"|r\n|c00ffff00"..L["Location Icon"].."|r - |c001eff00"..L["Display information about player"].."|r",
											},
										},
									},
								},
							},
							brokerhints = {
								type = "group",
								name = L["LDB/Minimap Plugin"],
								args = {
									brokerplugindescriptionBI = {
										type = "group",
										order = 0,
										name = L["LDB/Minimap Icon"],
										inline = true,
										args = {
											brokerplugindescriptionBI = {
												type = "description",
												name = "|c00ffff00"..L["Left Click"].."|r - |c001eff00"..L["Whisper player of missed message"]..
													"|r\n|c00ffff00"..L["Right Click"].."|r - |c001eff00"..L["Open options"].."|r",
											},
										},
									},
									brokerplugindescriptionGT = {
										type = "group",
										name = L["Group Title"],
										inline = true,
										args = {
											brokerplugindescriptionGT = {
												type = "description",
												name = "|c00ffff00"..L["Left Click"].."|r - |c001eff00"..L["Toggle between Timeframe and Online"]..
													"|r\n|c00ffff00"..L["Middle Click"].."|r - |c001eff00"..L["Toggle showing BattleNet App players that are away"]..
													"|r\n|c00ffff00"..L["Shift"].." + "..L["Left Click"].."|r - |c001eff00"..L["DELETE history for group (ex. All of Guild)"].."|r",
											},
										},
									},
									brokerplugindescriptionPN = {
										type = "group",
										name = L["Player Names"],
										inline = true,
										args = {
											brokerplugindescriptionPN = {
												type = "description",
												name = "|c00ffff00"..L["Left Click"].."|r - |c001eff00"..L["Reply to player"]..
													"|r\n|c00ffff00"..L["Right Click"].."|r - |c001eff00"..L["Reply to BattleNet character if applicable"]..
													"|r\n|c00ffff00"..L["Alt"].. " + "..L["Left Click"].."|r - |c001eff00"..L["Invite player to group"]..
													"|r\n|c00ffff00"..L["Ctrl"].." + "..L["Left Click"].."|r - |c001eff00"..L["Open Chat History Log Frame for player"]..
													"|r\n|c00ffff00"..L["Ctrl"].." + "..L["Right Click"].."|r - |c001eff00"..L["Open Change Display Name Frame for player"]..
													"|r\n|c00ffff00"..L["Shift"].." + "..L["Left Click"].."|r - |c001eff00"..L["DELETE player history"].."|r",
											},
										},
									},
								},
							},
						},
					},
	------------------------------------------------------------------------------------------------------------------------------------------------------------
					appearance = {
						type = "group",
						name = L["Appearance"],
						args = {
							entries = {
								type = "group",
								name = L["Entries"],
								inline = true,
								args = {
									entriesShow = {
										type = "range",
										name = L["Entries Shown"],
										desc = L["The number of entries to show in the message panels."],
										min = 1, max = 30, step = 1,
									},
									msgMaxHeight = {
										type = "range",
										name = L["Max Message Height"],
										desc = L["Max height of message panels before scrolling enables."],
										min = 100, max = 700, step = 1,
									}, 
								},
							},
							textures = {
								type = "group",
								name = L["Texture"],
								inline = true,
								args = {
									bgColor = {
										type = "color",
										order = 5,
										name = L["Background Color"],
										hasAlpha = true,
										get = function(info) local c = db[ info[#info] ]
											return c[1], c[2], c[3], c[4] end,
										set = function(info, r, g, b, a) db[ info[#info] ] = {r, g, b, a}
											SoDWhisper:SendMessage("SoDWhisper_SKIN") end,
									},
									bgTexture = {
										type = 'select',
										order = 10,
										name = L["Background"],
										desc = L["Change the background texture (For some textures the background color needs to be set to white)."],
										dialogControl = "LSM30_Background",
										values = AceGUIWidgetLSMlists.background,
										set = function(info, v) db[ info[#info] ] = v
											SoDWhisper:SendMessage("SoDWhisper_SKIN") end,
									},
									borderColor = {
										type = 'color',
										order = 15,
										name = L["Border Color"],
										hasAlpha = true,
										get = function(info) local c = db[ info[#info] ]
											return c[1], c[2], c[3], c[4] end,
										set = function(info, r, g, b, a) db[ info[#info] ] = {r, g, b, a}
											SoDWhisper:SendMessage("SoDWhisper_SKIN") end,
									},        
									borderTexture = {
										type = 'select',
										order = 20,
										name = L["Border Style"],
										desc = L["Change the border style of the panel."],
										dialogControl = "LSM30_Border",
										values = AceGUIWidgetLSMlists.border,
										set = function(info, v) db[ info[#info] ] = v
											SoDWhisper:SendMessage("SoDWhisper_SKIN") end,
									},
									frameLevelCF = {
										type = "range",
										order = 25,
										name = L["Frame Level"],
										desc = L["Level the frame appears on within the strata."],
										min = 0,
										max = 80,
										step = 1,
										set = function(info, v) db[ info[#info] ] = v 
											SoDWhisper:SendMessage("SoDWhisper_SKIN") end,
									},
									frameStrataCF = {
										type = 'select',
										order = 30,
										name = L["Frame Strata"],
										desc = L["Strata the frame appears on."],
										values = FRAME_STRATA,
										set = function(info, v) db[ info[#info] ] = v 
											SoDWhisper:SendMessage("SoDWhisper_SKIN") end,
									},
								},
							},
							text = {
								type = "group",
								name = L["Text"],
								inline = true,
								args = {
									colorOutgoing = {
										type = "color",
										order = 1,
										name = L["Color Outgoing"],
										desc = L["Set the color of outgoing messages."],
										get = function(info) local c = db[ info[#info] ]
											return c[1], c[2], c[3], c[4] end,
										set = function(info, r, g, b, a) db[ info[#info] ] = {r, g, b, a}
											SoDWhisper:SendMessage("SoDWhisper_SKIN") end,
									},
									colorIncoming = {
										type = "color",
										order = 2,
										name = L["Color Incoming"],
										desc = L["Set the color of incoming messages."],
										get = function(info) local c = db[ info[#info] ]
											return c[1], c[2], c[3], c[4] end,
										set = function(info, r, g, b, a) db[ info[#info] ] = {r, g, b, a}
											SoDWhisper:SendMessage("SoDWhisper_SKIN") end,
									},
									fontFace = {
										type = 'select',
										order = 3,
										name = L["Font"],
										dialogControl = "LSM30_Font",
										values = AceGUIWidgetLSMlists.font,
										set = function(info, v) db[ info[#info] ] = v 
											SoDWhisper:SkinMyFrame(nil, true, true)
											SoDWhisper:SendMessage("SoDWhisper_SKIN") end,
									},
									fontSize = {
										type = "range",
										order = 4,
										name = L["Font Size"],
										min = 6,
										max = 20,
										step = 1,
										set = function(info, v) db[ info[#info] ] = v 
											SoDWhisper:SkinMyFrame(nil, true, true)
											SoDWhisper:SendMessage("SoDWhisper_SKIN") end,
									},
								},
							},
							timestamps = {
								type = "group",
								name = L["Timestamp"],
								inline = true,
								args = {
									timeColor = {
										type = "color",
										name = L["Timestamp Color"],
										get = function(info) local c = db[ info[#info] ]
											return c[1], c[2], c[3], c[4] end,
										set = function(info, r, g, b, a) db[ info[#info] ] = {r, g, b, a}
											SoDWhisper:SendMessage("SoDWhisper_SKIN") end,
										disabled = function() return db.timeFormat == "" end,
									},
									timeFormat = { 
										type = "select",
										name = L["Timestamp Format"],
										values = TIME_FORMATS,
									},
								},
							},
						},
					},
	------------------------------------------------------------------------------------------------------------------------------------------------------------
					names = {
						type = "group",
						name = L["Names"],
						args = {
							realIDName = { 
								type = "select",
								order = 0,
								name = L["RealID Display"],
								desc = L["Select the display for realID names."],
								values = REALID_FORMATS,
								set = function(info, v) db[ info[#info] ] = v
									SoDWhisper:UpdateBNFriends(true) end,
							},
							colornames = {
								type = "group",
								name = L["Color By Class"],
								inline = true,
								args = {
									colorClassT = {
										type = "toggle",
										name = L["Character Names"],
										desc = L["Color character names by class."],
									},
									colorClassBN = {
										type = "toggle",
										name = L["BattleNet Names"],
										desc = L["Color BattleNet names by character class when possible."],
									},
								},
							},
						},
					},
	------------------------------------------------------------------------------------------------------------------------------------------------------------
					sound = {
						type = "group",
						name = L["Sounds"],
						args = {
							enableSound = {
								type = "toggle",
								order = 0,
								name = L["Enable"],
								desc = L["Use Sound for incoming messages."],
							},
							soundChannel = { 
								type = "select",
								order = 1,
								name = L["Channel Output"],
								desc = L["Channel for sound to play through."],
								values = SOUND_OUTPUT,
								disabled = function() return not db.enableSound end,
							},
							customSounds = {
								type = "group",
								name = L["Custom Sounds"],
								inline = true,
								disabled = function() return not db.enableSound end,
								args = {
									otherWhispSound = {
										type = 'select',
										name = L["Other Whisper"],
										desc = L["Sound for whispers that are not from guild or friends."],
										dialogControl = "LSM30_Sound",
										values = AceGUIWidgetLSMlists.sound,
									},
									guildWhispSound = {
										type = 'select',
										name = L["Guild Whisper"],
										desc = L["Sound for guild whispers."],
										dialogControl = "LSM30_Sound",
										values = AceGUIWidgetLSMlists.sound,
									},
									friendWhispSound = {
										type = 'select',
										name = L["Friend Whisper"],
										desc = L["Sound for friend whispers."],
										dialogControl = "LSM30_Sound",
										values = AceGUIWidgetLSMlists.sound,
									},
								},
							},
						},
					},
	------------------------------------------------------------------------------------------------------------------------------------------------------------
					history = {
						type = "group",
						name = L["History"],
						args = {
							saveHistory = {
								type = "group",
								name = L["Saved History Per Player"],
								inline = true,
								args = {
									historyDays = {
										type = "range",
										name = L["Days To Keep"],
										desc = L["Number of days messages will be kept per player (When set to 0, messages will be kept only for the session)."],
										min = 0, max = 45, step = 1,
									},
									historyMax = {
										type = "range",
										name = L["Maximum To Keep"],
										desc = L["Maximum number of messages to keep per player."],
										set = function(info, v) db[ info[#info] ] = (v < db.historyMin and db.historyMax) or v end,
										min = 1, max = 800, step = 1,
									},
									historyMin = {
										type = "range",
										name = L["Minimum To Always Keep"],
										desc = L["Minimum number of messages to always keep per player (*WARNING* If used, be sure to manually delete player history that you do not need)."],
										set = function(info, v) db[ info[#info] ] = (v > db.historyMax and db.historyMin) or v end,
										min = 0, max = 30, step = 1,
									},
								},
							},
							clear = {
								type = "execute",
								order = -1,
								name = L["Clear"],
								desc = L["Clears player and message history."],
								confirm = true,
								confirmText = L["Are you sure you want to clear the history?"],
								func = function() 
									wipe(SoDWhisper.db.factionrealm.chatHistory) 
									wipe(SoDWhisper.db.global.chatHistory) 
									SoDWhisper:UpdateGuild(true)
									SoDWhisper:UpdateBNFriends(true)	
									SoDWhisper:UpdateRegFriends(true)
									SoDWhisper:UpdateOtherToons(true)
									
									SoDWhisper:SendMessage("SoDWhisper_MESSAGE")
								end,
							},
						},
					},
	------------------------------------------------------------------------------------------------------------------------------------------------------------
					miscellaneous = {
						type = "group",
						name = L["Miscellaneous"],
						args = {
							BTNotify = {
								type = "toggle",
								name = L["BattleTag Notify"],
								desc = L["Automatic BattleTag notification to players that have never setup a BattleTag (Helps save their history)."],
							},
							combatUpdate = { 
								type = "toggle",
								name = L["Update In Combat"],
								desc = L["Update status in combat."],
							},
							inputSticky = { 
								type = "toggle",
								name = L["Whisper Sticky"],
								desc = L["Do NOT allow the Enter Key to open Whispers (Keeps missed message count correct)."],
								set = function(info, v) db[ info[#info] ] = v
									if v then
										ChatTypeInfo["WHISPER"].sticky = 0
										ChatTypeInfo["BN_WHISPER"].sticky = 0
									else
										ChatTypeInfo["WHISPER"].sticky = 1
										ChatTypeInfo["BN_WHISPER"].sticky = 1
									end
								end,
							},
							ignoreDBM = { 
								type = "toggle",
								name = L["Ignore DBM"],
								desc = L["Ignore DBM auto reply whispers."],
							},
						},
					},
				},
			},
		},
	}
		
	return options
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:ProfileChanged()
	db = SoDWhisper.db.profile
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

local function LF_OpenConfig()
	if not Dialog.OpenFrames["SoDWhisper"] then 
		Dialog:SetDefaultSize("SoDWhisper", 700, 580)
		Dialog:Open("SoDWhisper") 
	else 
		Dialog:Close("SoDWhisper") 
	end
end
------------------------------------------------------------------------------------------------------------------------------------------------------------

function SoDWhisper:SetupOptions()
	db = SoDWhisper.db.profile	
	
	if not options then
		L = SoDWhisper.L
		Dialog = LibStub("AceConfigDialog-3.0")
		local options = LF_GetOptions()
		
		LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("SoDWhisper", options)
		Dialog:AddToBlizOptions("SoDWhisper", options.args.general.name, "SoDWhisper", "general")	
		
		local panels = {}
		for k, v in SoDWhisper:IterateModules() do
			if type(v.GetOptions) == "function" then
				options.args[k] = v:GetOptions()
				tinsert(panels, k)
			end
		end
		sort(panels)
		for i = 1, #panels do
			local k = panels[i]
			Dialog:AddToBlizOptions("SoDWhisper", options.args[k].name, "SoDWhisper", k)
		end
		wipe(panels)
		
		options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(SoDWhisper.db)
		options.args.profile.order = -1
		Dialog:AddToBlizOptions("SoDWhisper", options.args.profile.name, "SoDWhisper", "profile") 
		
		print("|cff20ff20SoDWhisper|r: "..L["Option table now loaded into memory"])
	end
	
	LF_OpenConfig()	
end
