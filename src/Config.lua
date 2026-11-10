local _, ns = ...

local Config = {}
ns.Config = Config

Config.DEFAULTS = { schemaVersion = 2, enabled = true }

Config.COMMANDS = {
	{ "/owen", "open this window" },
	{ "/owen on", "turn it on" },
	{ "/owen off", "turn it off" },
}

function Config.Load(saved)
	local db = type(saved) == "table" and saved or {}
	db.schemaVersion = Config.DEFAULTS.schemaVersion
	db.enabled = db.enabled ~= false
	if type(db.point) ~= "table" then
		db.point = nil
	end
	-- Retired in schema 2 (PRD 6). The old restore snapshot is dropped, never applied.
	db.volume = nil
	db.restore = nil
	return db
end

function Config.SetEnabled(db, on)
	db.enabled = on
end

function Config.ParseCommand(text)
	local cmd = (text or ""):match("^%s*(.-)%s*$"):lower()
	if cmd == "" then
		return "toggle"
	elseif cmd == "on" or cmd == "off" then
		return cmd
	end
	return "help"
end
