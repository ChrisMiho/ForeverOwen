-- ForeverOwen Phase 0 probe (throwaway). Prints raw combat-log fields and checks API assumptions.
local PREFIX = "|cff33ff99OwenProbe|r "
local CLIP = "Interface\\AddOns\\ForeverOwenProbe\\OwenWilson.mp3"
local CLIP_SECONDS = 1.09

local function out(msg)
	print(PREFIX .. tostring(msg))
end

local EVENTS = {
	SWING_DAMAGE = true,
	RANGE_DAMAGE = true,
	SPELL_DAMAGE = true,
	SPELL_PERIODIC_DAMAGE = true,
	DAMAGE_SHIELD = true,
	SPELL_HEAL = true,
	SPELL_PERIODIC_HEAL = true,
	SWING_MISSED = true,
	RANGE_MISSED = true,
	SPELL_MISSED = true,
	SPELL_PERIODIC_MISSED = true,
	DAMAGE_SHIELD_MISSED = true,
}

local function onCombatLog()
	local ok, err = pcall(function()
		local info = { CombatLogGetCurrentEventInfo() }
		local subevent, sourceName, sourceFlags = info[2], info[5], info[6]
		if not EVENTS[subevent] then return end
		local mine = tonumber(COMBATLOG_OBJECT_AFFILIATION_MINE) or 1
		local flags = tonumber(sourceFlags)
		if not flags or bit.band(flags, mine) == 0 then return end
		out(string.format("%s src=%s flags=0x%X", tostring(subevent), tostring(sourceName), flags))
		local parts = {}
		for i = 12, 21 do
			parts[#parts + 1] = "[" .. i .. "]=" .. tostring(info[i])
		end
		out(table.concat(parts, " "))
	end)
	if not ok then out("handler error: " .. tostring(err)) end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:SetScript("OnEvent", onCombatLog)

local volRunning = false

local function probeVol(arg)
	local v = tonumber(arg)
	if not v or v < 0 or v > 1 then
		out("usage: /owenprobe vol <0-1>")
		return
	end
	if volRunning then
		out("test already running")
		return
	end
	volRunning = true
	local oldVol, oldEnable = GetCVar("Sound_DialogVolume"), GetCVar("Sound_EnableDialog")
	out("current Sound_DialogVolume=" .. tostring(oldVol) .. " Sound_EnableDialog=" .. tostring(oldEnable))
	SetCVar("Sound_DialogVolume", tostring(v))
	SetCVar("Sound_EnableDialog", "1")
	local willPlay, handle = PlaySoundFile(CLIP, "Dialog")
	out("willPlay=" .. tostring(willPlay) .. " handle=" .. tostring(handle))
	C_Timer.After(CLIP_SECONDS, function()
		SetCVar("Sound_DialogVolume", oldVol)
		SetCVar("Sound_EnableDialog", oldEnable)
		volRunning = false
		out("restored Sound_DialogVolume=" .. tostring(GetCVar("Sound_DialogVolume"))
			.. " Sound_EnableDialog=" .. tostring(GetCVar("Sound_EnableDialog")))
	end)
end

local function probeApi()
	out("type(C_AddOns)=" .. type(C_AddOns))
	for _, template in ipairs({ "BackdropTemplate", "UICheckButtonTemplate", "UIPanelButtonTemplate" }) do
		local ok, res = pcall(CreateFrame, "Frame", nil, UIParent, template)
		out(template .. ": ok=" .. tostring(ok) .. " result=" .. type(res))
	end
	out("type(UISpecialFrames)=" .. type(UISpecialFrames))
end

SLASH_OWENPROBE1 = "/owenprobe"
SlashCmdList["OWENPROBE"] = function(msg)
	local cmd, arg = (msg or ""):match("^(%S*)%s*(.-)$")
	cmd = cmd:lower()
	if cmd == "vol" then
		probeVol(arg)
	elseif cmd == "api" then
		probeApi()
	else
		out("usage: /owenprobe vol <0-1> | /owenprobe api")
	end
end

out("loaded. Crit with melee/spell/heal/DoT/pet/totem; /owenprobe vol 0.2; /owenprobe api")
