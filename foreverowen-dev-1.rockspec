-- Development dependencies only. ForeverOwen is a WoW addon, not a Lua rock:
-- this file exists so everyone (and CI) gets the same lint and test tools.
--
--   luarocks install --only-deps foreverowen-dev-1.rockspec
--
-- Versions are pinned exactly and bumped by hand (Dependabot does not read
-- rockspecs). To update: `luarocks search luacheck` / `luarocks search busted`,
-- change the versions below, then run `luacheck .` and `busted`.
rockspec_format = "3.0"
package = "foreverowen"
version = "dev-1"

source = {
	url = "git+https://github.com/ChrisMiho/ForeverOwen.git",
	branch = "main",
}

description = {
	summary = "Dev tooling for the ForeverOwen WoW addon (lint and unit tests).",
	homepage = "https://github.com/ChrisMiho/ForeverOwen",
	license = "MIT",
}

dependencies = {
	"lua >= 5.1, < 5.2",
	"luacheck == 1.2.0-1",
	"busted == 2.3.0-1",
}

build = {
	type = "none",
}
