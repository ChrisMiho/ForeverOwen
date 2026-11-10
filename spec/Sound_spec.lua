local Sound = LoadAddonFile("src/Sound.lua").Sound

describe("Sound", function()
	it("has the shared constants", function()
		assert.equals("Interface\\AddOns\\ForeverOwen\\media\\OwenWilson.mp3", Sound.CLIP_PATH)
		assert.equals(0.84, Sound.CLIP_SECONDS)
		assert.equals("Dialog", Sound.CHANNEL)
	end)

	it("no longer borrows the game's sound settings", function()
		assert.is_nil(Sound.NewBorrower)
		assert.is_nil(Sound.RESTORE_PAD)
	end)
end)
