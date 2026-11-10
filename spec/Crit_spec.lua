local Crit = LoadAddonFile("src/Crit.lua").Crit

local SECRET = setmetatable({}, {
	__eq = function()
		error("compared a secret value")
	end,
})

local function canRead(v)
	return v ~= SECRET and true or false
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

	it("hidden flag is not compared", function()
		assert.is_false(check("target", "WOUND", SECRET, true))
	end)

	it("does not ask about the target for an ordinary hit", function()
		local asked = false
		Crit.IsCritReport(canRead, "target", "WOUND", "", function()
			asked = true
			return true
		end)
		assert.is_false(asked)
	end)

	it("hidden event is not compared", function()
		assert.is_false(check("target", SECRET, "CRITICAL", true))
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
end)
