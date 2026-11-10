local _, ns = ...

local Sound = {}
ns.Sound = Sound

Sound.CLIP_PATH = "Interface\\AddOns\\ForeverOwen\\media\\OwenWilson.mp3"
Sound.CLIP_SECONDS = 0.84
Sound.CHANNEL = "Dialog"

-- Playback glue. WoW globals are looked up only when these run, never at file load.
local handle

function Sound.Play()
	if handle then
		StopSound(handle)
	end
	local _, newHandle = PlaySoundFile(Sound.CLIP_PATH, Sound.CHANNEL)
	handle = newHandle
	Sound.lastStart = GetTime()
end

function Sound.OnCrit(db)
	if db.enabled and ns.Crit.ShouldPlay(GetTime(), Sound.lastStart, Sound.CLIP_SECONDS) then
		Sound.Play()
	end
end
