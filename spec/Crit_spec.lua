local Crit = LoadAddonFile("src/Crit.lua").Crit

local function canRead()
	return true
end

-- A canRead that hides one value. The hidden value is a real "CRITICAL" or "WOUND",
-- so if IsCritReport skipped the check and compared it anyway, the report would count
-- and the test would fail. (A table with an erroring __eq would not catch that: Lua 5.1
-- never calls __eq when comparing a table with a string.)
local function hiding(hidden)
	return function(v)
		return v ~= hidden
	end
end

local function check(unit, event, flag, hostile)
	return Crit.IsCritReport(canRead, unit, event, flag, function()
		return hostile
	end)
end

describe("Crit.IsCritReport", function()
	it("crit on a hostile target", function()
		assert.is_true(check("target", "WOUND", "CRITICAL", true))
	end)

	it("non-crit on a hostile target", function()
		assert.is_false(check("target", "WOUND", "", true))
	end)

	it("crit on a friendly target", function()
		assert.is_false(check("target", "WOUND", "CRITICAL", false))
	end)

	it("crit heal on a target", function()
		assert.is_false(check("target", "HEAL", "CRITICAL", true))
	end)

	it("crit heal on me", function()
		assert.is_true(check("player", "HEAL", "CRITICAL", false))
	end)

	it("crit hit on me", function()
		assert.is_false(check("player", "WOUND", "CRITICAL", false))
	end)

	it("crit on my pet", function()
		assert.is_false(check("pet", "WOUND", "CRITICAL", true))
	end)

	it("absorbed hit", function()
		assert.is_false(check("target", "WOUND", "ABSORB", true))
	end)

	it("nil flag", function()
		assert.is_false(check("target", "WOUND", nil, true))
	end)

	it("hidden flag does not count", function()
		local yes = function()
			return true
		end
		assert.is_false(Crit.IsCritReport(hiding("CRITICAL"), "target", "WOUND", "CRITICAL", yes))
		assert.is_false(Crit.IsCritReport(hiding("CRITICAL"), "player", "HEAL", "CRITICAL", yes))
	end)

	it("lowercase flag does not count", function()
		assert.is_false(check("target", "WOUND", "critical", true))
	end)

	it("hostility must be exactly true", function()
		assert.is_false(check("target", "WOUND", "CRITICAL", 1))
		assert.is_false(check("target", "WOUND", "CRITICAL", nil))
	end)

	it("does not ask about the target for a crit heal on me", function()
		local asked = false
		Crit.IsCritReport(canRead, "player", "HEAL", "CRITICAL", function()
			asked = true
			return true
		end)
		assert.is_false(asked)
	end)

	it("other units do not count", function()
		assert.is_false(check(nil, "WOUND", "CRITICAL", true))
		assert.is_false(check("focus", "WOUND", "CRITICAL", true))
		assert.is_false(check("targettarget", "WOUND", "CRITICAL", true))
	end)

	it("does not ask about the target for an ordinary hit", function()
		local asked = false
		Crit.IsCritReport(canRead, "target", "WOUND", "", function()
			asked = true
			return true
		end)
		assert.is_false(asked)
	end)

	it("hidden event does not count", function()
		local yes = function()
			return true
		end
		assert.is_false(Crit.IsCritReport(hiding("WOUND"), "target", "WOUND", "CRITICAL", yes))
		assert.is_false(Crit.IsCritReport(hiding("HEAL"), "player", "HEAL", "CRITICAL", yes))
	end)
end)

describe("Crit.ShouldPlay", function()
	it("plays when nothing played yet", function()
		assert.is_true(Crit.ShouldPlay(10, nil, 0.84))
	end)

	it("blocks inside the window", function()
		assert.is_false(Crit.ShouldPlay(10.5, 10, 0.84))
	end)

	it("plays once the window has passed", function()
		assert.is_true(Crit.ShouldPlay(10.84, 10, 0.84))
	end)

	it("blocks just before the window ends", function()
		assert.is_false(Crit.ShouldPlay(10.8399, 10, 0.84))
	end)
end)
