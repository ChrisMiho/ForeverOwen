local Crit = LoadAddonFile("src/Crit.lua").Crit

local MINE = 0x1

local function band(a, b)
	local result, bit = 0, 1
	while a > 0 and b > 0 do
		if a % 2 == 1 and b % 2 == 1 then
			result = result + bit
		end
		a = math.floor(a / 2)
		b = math.floor(b / 2)
		bit = bit * 2
	end
	return result
end

local function tuple(sub, flags, fields)
	local t = {}
	t[1] = 0
	t[2] = sub
	t[6] = flags
	for i, v in pairs(fields) do
		t[i] = v
	end
	return t
end

local function check(sub, flags, fields)
	local t = tuple(sub, flags, fields)
	return Crit.IsMyCrit(MINE, band, unpack(t, 1, 21))
end

describe("Crit.IsMyCrit", function()
	it("SWING_DAMAGE crit by me", function()
		assert.is_true(check("SWING_DAMAGE", 0x1, { [18] = 1 }))
	end)

	it("SWING_DAMAGE non-crit", function()
		assert.is_false(check("SWING_DAMAGE", 0x1, { [18] = nil }))
	end)

	it("SPELL_DAMAGE crit at 21", function()
		assert.is_true(check("SPELL_DAMAGE", 0x1, { [21] = 1 }))
	end)

	it("SPELL_HEAL crit at 18", function()
		assert.is_true(check("SPELL_HEAL", 0x1, { [18] = 1 }))
	end)

	it("SPELL_PERIODIC_HEAL crit", function()
		assert.is_true(check("SPELL_PERIODIC_HEAL", 0x1, { [18] = 1 }))
	end)

	it("DAMAGE_SHIELD crit", function()
		assert.is_true(check("DAMAGE_SHIELD", 0x1, { [21] = 1 }))
	end)

	it("crit by someone else", function()
		assert.is_false(check("SPELL_DAMAGE", 0x400, { [21] = 1 }))
	end)

	it("crit by my totem/guardian", function()
		assert.is_true(check("SPELL_DAMAGE", 0x2111, { [21] = 1 }))
	end)

	it("nil flags", function()
		assert.is_false(check("SPELL_DAMAGE", nil, { [21] = 1 }))
	end)

	it("SPELL_MISSED ABSORB crit", function()
		assert.is_true(check("SPELL_MISSED", 0x1, { [15] = "ABSORB", [18] = true }))
	end)

	it("SPELL_MISSED DODGE", function()
		assert.is_false(check("SPELL_MISSED", 0x1, { [15] = "DODGE", [18] = true }))
	end)

	it("SWING_MISSED ABSORB crit", function()
		assert.is_true(check("SWING_MISSED", 0x1, { [12] = "ABSORB", [15] = true }))
	end)

	it("unknown sub-event", function()
		assert.is_false(check("SPELL_CAST_SUCCESS", 0x1, { [18] = 1, [21] = 1 }))
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
