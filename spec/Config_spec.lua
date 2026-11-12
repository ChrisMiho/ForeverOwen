local Config = LoadAddonFile("src/Config.lua").Config

describe("Config", function()
	it("Load(nil) returns defaults", function()
		assert.are.same({ schemaVersion = 2, enabled = true }, Config.Load(nil))
	end)

	it("accepts a non-table", function()
		assert.are.same({ schemaVersion = 2, enabled = true }, Config.Load("junk"))
	end)

	it("keeps valid saved values", function()
		local point = { point = "CENTER", relativePoint = "CENTER", x = 10, y = 20 }
		local db = Config.Load({ enabled = false, point = point })
		assert.is_false(db.enabled)
		assert.are.same(point, db.point)
	end)

	it("returns the saved table itself, keeping unknown keys", function()
		local saved = { enabled = true, future = "kept" }
		local db = Config.Load(saved)
		assert.are.equal(saved, db)
		assert.are.equal("kept", db.future)
	end)

	it("enabled defaults to true when missing or not a boolean", function()
		assert.is_true(Config.Load({}).enabled)
		assert.is_true(Config.Load({ enabled = "false" }).enabled)
		assert.is_true(Config.Load({ enabled = 0 }).enabled)
	end)

	it("drops a saved position that is not a table", function()
		assert.is_nil(Config.Load({ point = "junk" }).point)
	end)

	it("drops a saved position with a missing or wrong field", function()
		local bad = {
			{ relativePoint = "CENTER", x = 1, y = 2 },
			{ point = "CENTER", relativePoint = 5, x = 1, y = 2 },
			{ point = "CENTER", relativePoint = "CENTER", x = "1", y = 2 },
			{ point = "CENTER", relativePoint = "CENTER", x = 1 },
		}
		for _, point in ipairs(bad) do
			assert.is_nil(Config.Load({ point = point }).point)
		end
	end)

	it("drops retired volume and restore keys", function()
		local db = Config.Load({ volume = 0.4, restore = { dialogVolume = "0.7" } })
		assert.is_nil(db.volume)
		assert.is_nil(db.restore)
		assert.are.equal(2, db.schemaVersion)
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
		assert.are.equal("help", Config.ParseCommand("on now"))
	end)

	it("COMMANDS lists the three commands in order", function()
		assert.are.same({
			{ "/owen", "open this window" },
			{ "/owen on", "turn it on" },
			{ "/owen off", "turn it off" },
		}, Config.COMMANDS)
	end)
end)
