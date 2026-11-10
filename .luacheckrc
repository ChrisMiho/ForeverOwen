std = "lua51"
max_line_length = 120
codes = true

exclude_files = {
	".release/",
	".lua/",        -- Lua installed by CI (leafo/gh-actions-lua)
	".luarocks/",   -- LuaRocks installed by CI (leafo/gh-actions-luarocks)
	"lua_modules/", -- project-local rocks tree, if you use one
	".luacheckrc",
	".worktrees/",
	".superpowers/", -- local tooling state
}

-- Globals this addon creates
globals = {
	"ForeverOwenDB", -- SavedVariables (account-wide), see ForeverOwen.toc
	"SlashCmdList",
	"SLASH_FOREVEROWEN1",
}

-- WoW API this addon reads. Add each new API here as it is used,
-- so a typo in an API name fails lint instead of failing in game.
read_globals = {
	"bit",
	"C_AddOns",
	"C_Timer",
	"COMBATLOG_OBJECT_AFFILIATION_MINE",
	"COMBATLOG_OBJECT_TYPE_PET",
	"CombatLogGetCurrentEventInfo",
	"CreateFrame",
	"GameFontHighlight",
	"GameFontHighlightSmall",
	"GameFontNormal",
	"GameTooltip",
	"GetCVar",
	"GetTime",
	"PlaySoundFile",
	"SetCVar",
	"StopSound",
	"UIParent",
	"UnitFactionGroup",
	"UnitGUID",
}

files["spec/"] = {
	std = "+busted",
	read_globals = { "LoadAddonFile" },
}

files["spec/helper.lua"] = {
	globals = { "LoadAddonFile" },
}
