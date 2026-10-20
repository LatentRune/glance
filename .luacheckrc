-- luacheck settings for Glance: https://luacheck.readthedocs.io
-- CI runs `luacheck src`. It's here to catch globals: a typo in a name, or a variable
-- that leaks out of its file. Style warnings are left to review.

std = "lua51"            -- the game's Lua
max_line_length = false
ignore = {
  "2",                   -- unused variables and arguments: handlers get more than they use
  "3",                   -- values assigned and not read
  "4",                   -- shadowing
  "5",                   -- empty blocks and unreachable code
  "6",                   -- whitespace
}

-- What Glance itself sets for the game: saved variables, /glance, key bindings.
globals = {
  "GlanceDB", "GlanceCharDB",
  "SLASH_GLANCE1", "SlashCmdList",
  "Glance_Mark", "BINDING_HEADER_GLANCE", "BINDING_NAME_GLANCE_SKULL", "BINDING_NAME_GLANCE_CROSS",
}

-- The game's API that Glance reads. Add a name here when you use a new one.
read_globals = {
  "COMBATLOG_OBJECT_REACTION_HOSTILE", "C_Container", "C_Item", "C_NamePlate",
  "C_QuestLog", "C_Spell", "C_Timer", "C_TooltipInfo", "C_UnitAuras", "CanLootUnit",
  "CheckInteractDistance", "CombatLogGetCurrentEventInfo", "ComboFrame",
  "ComboPointPlayerFrame", "CreateFrame", "EditModeManagerFrame", "FACTION_BAR_COLORS",
  "GameTooltip", "GameTooltipTextLeft1", "GetAddOnMemoryUsage", "GetComboPoints",
  "GetContainerItemID", "GetContainerNumFreeSlots", "GetContainerNumSlots",
  "GetInventoryItemCount", "GetInventoryItemDurability", "GetInventoryItemID",
  "GetItemCooldown", "GetItemCount", "GetItemFamily", "GetItemIcon", "GetItemInfo",
  "GetLootSlotInfo", "GetLootSourceInfo", "GetNumLootItems", "GetNumPartyMembers",
  "GetNumQuestLeaderBoards", "GetNumQuestLogEntries", "GetPetHappiness",
  "GetQuestDifficultyColor", "GetQuestLogLeaderBoard", "GetQuestLogQuestText",
  "GetQuestLogSelection", "GetQuestLogTitle", "GetRaidTargetIndex", "GetSpellCooldown",
  "GetSpellInfo", "GetSpellPowerCost", "GetTime", "InCombatLockdown", "IsAltKeyDown",
  "IsControlKeyDown", "IsInGroup", "IsInRaid", "IsPlayerSpell", "IsSpellInRange",
  "IsSpellKnown", "Menu", "MouseIsOver", "PetFrameDropDown", "PlayerFrame",
  "PlayerFrameDropDown", "PowerBarColor", "RAID_CLASS_COLORS", "RegisterStateDriver",
  "RegisterUnitWatch", "ReloadUI", "SelectQuestLogEntry", "SendChatMessage",
  "SetRaidTarget", "SetRaidTargetIconTexture", "TargetFrame", "TargetFrameDropDown",
  "ToggleDropDownMenu", "UIDropDownMenu_AddButton", "UIDropDownMenu_CreateInfo",
  "UIDropDownMenu_Initialize", "UIParent", "UnitAffectingCombat", "UnitAttackSpeed",
  "UnitAura", "UnitCanAttack", "UnitCastingInfo", "UnitChannelInfo", "UnitClass",
  "UnitClassification", "UnitCreatureFamily", "UnitCreatureType",
  "UnitDetailedThreatSituation", "UnitExists", "UnitFactionGroup", "UnitGUID",
  "UnitHealth", "UnitHealthMax", "UnitInParty", "UnitInRaid", "UnitInRange", "UnitIsDead",
  "UnitIsDeadOrGhost", "UnitIsFriend", "UnitIsPVP", "UnitIsPVPFreeForAll", "UnitIsPlayer",
  "UnitIsTapDenied", "UnitIsTapped", "UnitIsTappedByPlayer", "UnitIsUnit", "UnitLevel",
  "UnitName", "UnitOnTaxi", "UnitPopup_OpenMenu", "UnitPower", "UnitPowerMax",
  "UnitPowerType", "UnitRangedDamage", "UnitReaction", "UnitThreatSituation",
  "UnregisterStateDriver", "UnregisterUnitWatch", "UpdateAddOnMemoryUsage",
  "WOW_PROJECT_ID", "WOW_PROJECT_MAINLINE", "bit", "debugprofilestop", "strsplit",
}
