-- Smoke tests for the package layout: the .toc the game reads and the
-- sound file it plays.

local TOC = "ForeverOwen.toc"

local function readFile(path)
	local f = io.open(path, "rb")
	if not f then
		return nil
	end
	local data = f:read("*a")
	f:close()
	return data
end

local function tocField(text, name)
	return text:match("\n## " .. name .. ":%s*([^\r\n]-)%s*\r?\n")
		or text:match("^## " .. name .. ":%s*([^\r\n]-)%s*\r?\n")
end

local function tocFiles(text)
	local files = {}
	for line in text:gmatch("[^\r\n]+") do
		if not line:match("^%s*#") and line:match("%S") then
			files[#files + 1] = line:match("^%s*(.-)%s*$")
		end
	end
	return files
end

describe("ForeverOwen.toc", function()
	local toc = readFile(TOC)

	it("exists", function()
		assert.is_not_nil(toc)
	end)

	it("targets WoW Forever (Interface 16001)", function()
		assert.are.equal("16001", tocField(toc, "Interface"))
	end)

	it("saves ForeverOwenDB", function()
		assert.are.equal("ForeverOwenDB", tocField(toc, "SavedVariables"))
	end)

	it("lets the packager stamp the version", function()
		assert.are.equal("@project-version@", tocField(toc, "Version"))
	end)

	it("loads the modules in order", function()
		assert.are.same({
			"src\\Config.lua",
			"src\\Crit.lua",
			"src\\Sound.lua",
			"src\\UI.lua",
			"src\\Init.lua",
		}, tocFiles(toc))
	end)

	it("lists only files that exist", function()
		local missing = {}
		for _, path in ipairs(tocFiles(toc)) do
			if not readFile((path:gsub("\\", "/"))) then
				missing[#missing + 1] = path
			end
		end
		assert.are.same({}, missing)
	end)

	it("lists every src/ file", function()
		local isWindows = package.config:sub(1, 1) == "\\"
		local pipe = assert(io.popen(isWindows and "dir /b src\\*.lua" or "ls src"))
		local listed = {}
		for _, path in ipairs(tocFiles(toc)) do
			listed[path] = true
		end
		local unlisted = {}
		for name in pipe:lines() do
			name = name:match("^%s*(.-)%s*$")
			if name:match("%.lua$") and not listed["src\\" .. name] then
				unlisted[#unlisted + 1] = name
			end
		end
		pipe:close()
		assert.are.same({}, unlisted)
	end)
end)

describe("media/OwenWilson.mp3", function()
	it("exists and is an MP3", function()
		local data = readFile("media/OwenWilson.mp3")
		assert.is_not_nil(data)
		-- ID3v2 tag, or a bare MPEG audio frame sync
		local isMp3 = data:sub(1, 3) == "ID3"
			or (data:byte(1) == 0xFF and data:byte(2) >= 0xE0)
		assert.is_true(isMp3)
	end)
end)
