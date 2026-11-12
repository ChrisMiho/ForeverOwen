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
	"scripts/probe/", -- throwaway Phase 0 probe, never ships
}

-- Globals this addon creates
globals = {
	"ForeverOwenDB", -- SavedVariables (account-wide), see ForeverOwen.toc
	"ForeverOwenFrame", -- the window, named so UISpecialFrames can close it on Esc
	"SlashCmdList",
	"SLASH_FOREVEROWEN1",
}

-- WoW API this addon reads. Add each new API here as it is used,
-- so a typo in an API name fails lint instead of failing in game.
read_globals = {
	"C_AddOns",
	"canaccessvalue",
	"CreateFrame",
	"GetTime",
	"issecretvalue",
	"PlaySoundFile",
	"StopSound",
	"tinsert",
	"UIParent",
	"UISpecialFrames",
	"UnitCanAttack",
	"UnitFactionGroup",
}

files["spec/"] = {
	std = "+busted",
	read_globals = { "LoadAddonFile" },
}

files["spec/helper.lua"] = {
	globals = { "LoadAddonFile" },
}
