local _, ns = ...

local Crit = {}
ns.Crit = Crit

local DAMAGE = { crit = 21 }
local HEAL = { crit = 18 }
local MISSED = { crit = 18, miss = 15 }

Crit.EVENTS = {
	SWING_DAMAGE = { crit = 18 },
	RANGE_DAMAGE = DAMAGE,
	SPELL_DAMAGE = DAMAGE,
	SPELL_PERIODIC_DAMAGE = DAMAGE,
	DAMAGE_SHIELD = DAMAGE,
	SPELL_HEAL = HEAL,
	SPELL_PERIODIC_HEAL = HEAL,
	SWING_MISSED = { crit = 15, miss = 12 },
	RANGE_MISSED = MISSED,
	SPELL_MISSED = MISSED,
	SPELL_PERIODIC_MISSED = MISSED,
	DAMAGE_SHIELD_MISSED = MISSED,
}

local EVENTS = Crit.EVENTS

-- Runs on every combat-log event: no allocations here.
function Crit.IsMyCrit(mineMask, band, ...)
	local e = EVENTS[(select(2, ...))]
	if not e then
		return false
	end
	if band((select(6, ...)) or 0, mineMask) == 0 then
		return false
	end
	if not (select(e.crit, ...)) then
		return false
	end
	if e.miss and (select(e.miss, ...)) ~= "ABSORB" then
		return false
	end
	return true
end

-- The epsilon absorbs float error (10.84 - 10 < 0.84 in doubles).
function Crit.ShouldPlay(now, lastStart, window)
	return lastStart == nil or now - lastStart >= window - 1e-9
end
