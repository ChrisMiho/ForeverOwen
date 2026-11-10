local _, ns = ...

local Sound = {}
ns.Sound = Sound

Sound.CLIP_PATH = "Interface\\AddOns\\ForeverOwen\\media\\OwenWilson.mp3"
Sound.CLIP_SECONDS = 0.84
Sound.RESTORE_PAD = 0.25
Sound.CHANNEL = "Dialog"

local VOLUME_CVAR = "Sound_DialogVolume"
local ENABLE_CVAR = "Sound_EnableDialog"

-- api = { getCVar = fn(name) -> string|nil, setCVar = fn(name, value), after = fn(seconds, cb) }
-- db.restore is the only record of an active borrow: it is saved, so a crash can be undone on login.
function Sound.NewBorrower(api)
	local borrower = {}
	local gen = 0

	function borrower.Restore(_, db)
		local saved = db.restore
		if not saved then
			return
		end
		if saved.dialogVolume ~= nil then
			api.setCVar(VOLUME_CVAR, saved.dialogVolume)
		end
		if saved.enableDialog ~= nil then
			api.setCVar(ENABLE_CVAR, saved.enableDialog)
		end
		db.restore = nil
	end

	function borrower.Begin(_, db, volume)
		if db.restore == nil then
			db.restore = {
				dialogVolume = api.getCVar(VOLUME_CVAR),
				enableDialog = api.getCVar(ENABLE_CVAR),
			}
		end
		api.setCVar(VOLUME_CVAR, tostring(volume))
		api.setCVar(ENABLE_CVAR, "1")
		gen = gen + 1
		local mine = gen
		api.after(Sound.CLIP_SECONDS + Sound.RESTORE_PAD, function()
			if mine == gen then
				borrower:Restore(db)
			end
		end)
	end

	return borrower
end

-- Playback glue. WoW globals are looked up only when these run, never at file load.
local borrower
local handle

local function GetBorrower()
	if not borrower then
		borrower = Sound.NewBorrower({
			getCVar = GetCVar,
			setCVar = SetCVar,
			after = C_Timer.After,
		})
	end
	return borrower
end

function Sound.Play(db)
	GetBorrower():Begin(db, db.volume)
	if handle then
		StopSound(handle)
	end
	local _, newHandle = PlaySoundFile(Sound.CLIP_PATH, Sound.CHANNEL)
	handle = newHandle
	Sound.lastStart = GetTime()
end

function Sound.OnCrit(db)
	if db.enabled and ns.Crit.ShouldPlay(GetTime(), Sound.lastStart, Sound.CLIP_SECONDS) then
		Sound.Play(db)
	end
end

function Sound.RestoreLeftover(db)
	GetBorrower():Restore(db)
end
