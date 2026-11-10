local addonName, ns = ...

-- False for a value the game hides from addons; such a value must not be compared.
local function CanRead(value)
	if canaccessvalue then
		return canaccessvalue(value) == true
	end
	if issecretvalue then
		return issecretvalue(value) == false
	end
	return true
end

local function HostileTarget()
	local hostile = UnitCanAttack("player", "target")
	return CanRead(hostile) and hostile == true
end

local function GetVersion()
	local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
	if not version or version:sub(1, 1) == "@" then
		return "dev"
	end
	return version
end

function ns.Print(text)
	print("|cffffd100ForeverOwen|r " .. text)
end

ns.version = GetVersion()

SLASH_FOREVEROWEN1 = "/owen"
SlashCmdList.FOREVEROWEN = function(text)
	local db = ns.db
	if not db then
		return
	end
	local action = ns.Config.ParseCommand(text)
	if action == "toggle" then
		ns.UI.Toggle()
	elseif action == "on" then
		ns.Config.SetEnabled(db, true)
		ns.Print("on. Wow.")
		ns.UI.Refresh()
	elseif action == "off" then
		ns.Config.SetEnabled(db, false)
		ns.Print("off.")
		ns.UI.Refresh()
	else
		ns.Print("commands:")
		for _, entry in ipairs(ns.Config.COMMANDS) do
			ns.Print(entry[1] .. " - " .. entry[2])
		end
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, arg1, ...)
	if event == "ADDON_LOADED" then
		if arg1 ~= addonName then
			return
		end
		self:UnregisterEvent("ADDON_LOADED")
		ForeverOwenDB = ns.Config.Load(ForeverOwenDB)
		ns.db = ForeverOwenDB
		self:RegisterUnitEvent("UNIT_COMBAT", "target", "player")
	elseif event == "PLAYER_LOGIN" then
		if not ns.db then
			return
		end
		ns.Print(ns.version .. " loaded. Type /owen.")
	elseif event == "UNIT_COMBAT" then
		if not ns.db then
			return
		end
		local combatEvent, flag = ...
		if ns.Crit.IsCritReport(CanRead, arg1, combatEvent, flag, HostileTarget) then
			ns.Sound.OnCrit(ns.db)
		end
	end
end)
