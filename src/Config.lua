local _, ns = ...

local Config = {}
ns.Config = Config

Config.DEFAULTS = { schemaVersion = 1, enabled = true, volume = 1.0 }

Config.COMMANDS = {
	{ "/owen", "open this window" },
	{ "/owen on", "turn it on" },
	{ "/owen off", "turn it off" },
}

function Config.ClampVolume(v)
	if v ~= v then
		return Config.DEFAULTS.volume
	end
	if v < 0 then
		v = 0
	elseif v > 1 then
		v = 1
	end
	return math.floor(v * 20 + 0.5) / 20
end

function Config.Load(saved)
	local db = type(saved) == "table" and saved or {}
	db.schemaVersion = Config.DEFAULTS.schemaVersion
	db.enabled = db.enabled ~= false
	if type(db.volume) == "number" then
		db.volume = Config.ClampVolume(db.volume)
	else
		db.volume = Config.DEFAULTS.volume
	end
	if type(db.point) ~= "table" then
		db.point = nil
	end
	if type(db.restore) ~= "table" then
		db.restore = nil
	end
	return db
end

function Config.SetVolume(db, v)
	db.volume = Config.ClampVolume(v)
	return db.volume
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
