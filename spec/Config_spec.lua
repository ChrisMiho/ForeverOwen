local Config = LoadAddonFile("src/Config.lua").Config

local function near(a, b)
	assert.is_true(math.abs(a - b) < 1e-9)
end

describe("Config", function()
	it("Load(nil) returns defaults", function()
		assert.are.same({ schemaVersion = 1, enabled = true, volume = 1.0 }, Config.Load(nil))
	end)

	it("accepts a non-table", function()
		assert.are.equal(1.0, Config.Load("junk").volume)
	end)

	it("keeps valid saved values", function()
		local point = { point = "CENTER", relativePoint = "CENTER", x = 10, y = 20 }
		local db = Config.Load({ enabled = false, volume = 0.35, point = point })
		assert.is_false(db.enabled)
		near(db.volume, 0.35)
		assert.are.same(point, db.point)
	end)

	it("treats NaN volume as the default", function()
		near(Config.Load({ volume = 0 / 0 }).volume, 1.0)
	end)

	it("clamps and rounds volume", function()
		near(Config.ClampVolume(7), 1)
		near(Config.ClampVolume(-1), 0)
		near(Config.ClampVolume(0.42), 0.40)
		near(Config.ClampVolume(0.43), 0.45)
	end)

	it("replaces non-number volume", function()
		assert.are.equal(1.0, Config.Load({ volume = "loud" }).volume)
	end)

	it("drops a non-table restore", function()
		assert.is_nil(Config.Load({ restore = "x" }).restore)
	end)

	it("keeps a table restore", function()
		local restore = { Sound_MasterVolume = "0.5" }
		assert.are.same(restore, Config.Load({ restore = restore }).restore)
	end)

	it("SetVolume stores the clamped value", function()
		local db = Config.Load(nil)
		near(Config.SetVolume(db, 0.42), 0.40)
		near(db.volume, 0.40)
	end)

	it("SetEnabled stores the flag", function()
		local db = Config.Load(nil)
		Config.SetEnabled(db, false)
		assert.is_false(db.enabled)
	end)

	it("ParseCommand", function()
		assert.are.equal("toggle", Config.ParseCommand(nil))
		assert.are.equal("toggle", Config.ParseCommand(""))
		assert.are.equal("on", Config.ParseCommand("  ON "))
		assert.are.equal("off", Config.ParseCommand("Off"))
		assert.are.equal("help", Config.ParseCommand("volume 5"))
		assert.are.equal("help", Config.ParseCommand("help"))
	end)

	it("COMMANDS lists the three commands in order", function()
		assert.are.same({
			{ "/owen", "open this window" },
			{ "/owen on", "turn it on" },
			{ "/owen off", "turn it off" },
		}, Config.COMMANDS)
	end)
end)
