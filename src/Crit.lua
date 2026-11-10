local _, ns = ...

local Crit = {}
ns.Crit = Crit

-- This client blocks addons from the combat log (PRD 4.1), so crits come from
-- UNIT_COMBAT: (unit, event, flag, amount, school). It says what a unit took, not
-- who dealt it.
--
-- canRead(value) is false for a value the game hides from addons ("secret");
-- comparing one would throw, so every field is checked before it is compared.
-- isHostile(): whether the target is something the player can attack. Called only
-- for a crit on the target, so ordinary hits stay cheap.
function Crit.IsCritReport(canRead, unit, event, flag, isHostile)
	if not (canRead(flag) and flag == "CRITICAL") then
		return false
	end
	if not canRead(event) then
		return false
	end
	if unit == "target" then
		return event == "WOUND" and isHostile() == true
	elseif unit == "player" then
		return event == "HEAL"
	end
	return false
end

-- The epsilon absorbs float error (10.84 - 10 < 0.84 in doubles).
function Crit.ShouldPlay(now, lastStart, window)
	return lastStart == nil or now - lastStart >= window - 1e-9
end
