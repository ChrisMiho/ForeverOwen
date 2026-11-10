local Sound = LoadAddonFile("src/Sound.lua").Sound

describe("Sound borrow core", function()
	local cvars, timers, sets, borrower

	before_each(function()
		cvars = { Sound_DialogVolume = "0.7", Sound_EnableDialog = "0" }
		timers = {}
		sets = 0
		borrower = Sound.NewBorrower({
			getCVar = function(name)
				return cvars[name]
			end,
			setCVar = function(name, value)
				sets = sets + 1
				cvars[name] = value
			end,
			after = function(seconds, cb)
				timers[#timers + 1] = { seconds, cb }
			end,
		})
	end)

	it("has the shared constants", function()
		assert.equals("Interface\\AddOns\\ForeverOwen\\media\\OwenWilson.mp3", Sound.CLIP_PATH)
		assert.equals(0.84, Sound.CLIP_SECONDS)
		assert.equals(0.25, Sound.RESTORE_PAD)
		assert.equals("Dialog", Sound.CHANNEL)
	end)

	it("Begin snapshots, sets volume and enables dialog", function()
		local db = {}
		borrower:Begin(db, 0.4)
		assert.same({ dialogVolume = "0.7", enableDialog = "0" }, db.restore)
		assert.equals("0.4", cvars.Sound_DialogVolume)
		assert.equals("1", cvars.Sound_EnableDialog)
		assert.is_true(math.abs(timers[1][1] - 1.09) < 1e-9)
	end)

	it("timer restores the originals and clears db.restore", function()
		local db = {}
		borrower:Begin(db, 0.4)
		timers[1][2]()
		assert.equals("0.7", cvars.Sound_DialogVolume)
		assert.equals("0", cvars.Sound_EnableDialog)
		assert.is_nil(db.restore)
	end)

	it("a second Begin during a borrow keeps the original snapshot", function()
		local db = {}
		borrower:Begin(db, 0.4)
		borrower:Begin(db, 0.9)
		assert.equals("0.7", db.restore.dialogVolume)
		timers[1][2]()
		assert.equals("0.9", cvars.Sound_DialogVolume)
		assert.equals("1", cvars.Sound_EnableDialog)
		assert.is_not_nil(db.restore)
		timers[2][2]()
		assert.equals("0.7", cvars.Sound_DialogVolume)
		assert.is_nil(db.restore)
	end)

	it("Restore on login puts back a leftover snapshot", function()
		local db = { restore = { dialogVolume = "0.5", enableDialog = "1" } }
		borrower:Restore(db)
		assert.equals("0.5", cvars.Sound_DialogVolume)
		assert.equals("1", cvars.Sound_EnableDialog)
		assert.is_nil(db.restore)
	end)

	it("Restore skips nil fields", function()
		local db = { restore = { dialogVolume = "0.5" } }
		borrower:Restore(db)
		assert.equals(1, sets)
		assert.equals("0", cvars.Sound_EnableDialog)
		assert.is_nil(db.restore)
	end)

	it("Restore with nothing borrowed does nothing", function()
		borrower:Restore({})
		assert.equals(0, sets)
	end)
end)
