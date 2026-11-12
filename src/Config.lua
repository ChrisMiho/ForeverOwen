local _, ns = ...

local Config = {}
ns.Config = Config

Config.DEFAULTS = { schemaVersion = 2, enabled = true }

Config.COMMANDS = {
	{ "/owen", "open this window" },
	{ "/owen on", "turn it on" },
	{ "/owen off", "turn it off" },
}

-- A saved window position the UI can pass straight to SetPoint.
local function IsValidPoint(p)
	return type(p) == "table"
		and type(p.point) == "string"
		and type(p.relativePoint) == "string"
		and type(p.x) == "number"
		and type(p.y) == "number"
end

function Config.Load(saved)
	local db = type(saved) == "table" and saved or {}
	db.schemaVersion = Config.DEFAULTS.schemaVersion
	if type(db.enabled) ~= "boolean" then
		db.enabled = Config.DEFAULTS.enabled
	end
	if not IsValidPoint(db.point) then
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
