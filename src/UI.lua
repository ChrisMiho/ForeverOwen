local _, ns = ...

-- The window (PRD 4.6). Built lazily on the first /owen. ns.Config, ns.Sound and ns.db are
-- looked up when these functions run: this file loads before Init.lua sets ns.db.
local UI = {}
ns.UI = UI

local FRAME_NAME = "ForeverOwenFrame"
local WHITE8X8 = "Interface\\Buttons\\WHITE8x8"

-- { r, g, b } floats in 0..1, keyed by UnitFactionGroup("player").
local PALETTE = {
	Alliance = {
		title = { 0.114, 0.302, 0.690 },
		border = { 0.208, 0.408, 0.808 },
		button = { 0.400, 0.580, 1.000 },
	},
	Horde = {
		title = { 0.490, 0.110, 0.110 },
		border = { 0.651, 0.200, 0.200 },
		button = { 1.000, 0.450, 0.450 },
	},
}
local WINDOW_BG = { 0.06, 0.06, 0.08, 0.92 }

local LAYOUT = {
	width = 260,
	height = 200,
	titleHeight = 26,
	padding = 12,
	buttonWidth = 80,
	buttonHeight = 22,
	checkGap = 40, -- from the Play button to the Enabled checkbox
	commandColumn = 80, -- x of the description column, from the left padding
	commandRow = 16,
}

local TEXT = {
	title = "ForeverOwen",
	play = "Play",
	enabled = "Enabled",
	volumeNote = "Volume follows your game's Dialog volume (Options > Audio > Dialog).",
}

local BACKDROP = {
	bgFile = WHITE8X8,
	edgeFile = WHITE8X8,
	edgeSize = 1,
}

local window -- the built parts; nil until the first Toggle
local attempted = false -- set before the first build, so a failed build is never repeated

local function Tint()
	return PALETTE[UnitFactionGroup("player")] or PALETTE.Alliance
end

local function SavePosition(frame)
	local point, _, relativePoint, x, y = frame:GetPoint(1)
	if point then
		ns.db.point = { point = point, relativePoint = relativePoint, x = x, y = y }
	end
end

local function ApplyPosition(frame)
	frame:ClearAllPoints()
	local p = ns.db.point -- checked by Config.Load; SavePosition only writes valid ones
	if p then
		frame:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
end

local function BuildTitleBar(frame, tint)
	local bar = CreateFrame("Frame", nil, frame)
	bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
	bar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
	bar:SetHeight(LAYOUT.titleHeight)
	bar:EnableMouse(true)
	bar:RegisterForDrag("LeftButton")
	bar:SetScript("OnDragStart", function()
		frame:StartMoving()
	end)
	bar:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
		frame:SetUserPlaced(false)
		SavePosition(frame)
	end)

	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(unpack(tint.title))

	local title = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	title:SetPoint("LEFT", bar, "LEFT", LAYOUT.padding, 0)
	title:SetText(TEXT.title)

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetSize(LAYOUT.titleHeight, LAYOUT.titleHeight)
	close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
	close:SetFrameLevel(bar:GetFrameLevel() + 1)
end

local function BuildPlay(frame, tint)
	local play = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	play:SetSize(LAYOUT.buttonWidth, LAYOUT.buttonHeight)
	play:SetPoint("TOPLEFT", frame, "TOPLEFT", LAYOUT.padding, -(LAYOUT.titleHeight + LAYOUT.padding))
	play:SetText(TEXT.play)
	-- The template's three slices are named Left/Middle/Right on modern clients; tint whichever exist.
	for _, key in ipairs({ "Left", "Middle", "Right" }) do
		local slice = play[key]
		if slice and slice.SetVertexColor then
			slice:SetVertexColor(unpack(tint.button))
		end
	end
	play:SetScript("OnClick", function()
		ns.Sound.Play()
	end)
	return play
end

local function BuildEnabled(frame, play)
	local check = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
	check:SetSize(LAYOUT.buttonHeight + 4, LAYOUT.buttonHeight + 4)
	check:SetPoint("LEFT", play, "RIGHT", LAYOUT.checkGap, 0)
	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	label:SetPoint("LEFT", check, "RIGHT", 2, 0)
	label:SetText(TEXT.enabled)
	check:SetHitRectInsets(0, -(label:GetStringWidth() + 4), 0, 0)
	check:SetScript("OnClick", function(self)
		ns.Config.SetEnabled(ns.db, self:GetChecked() and true or false)
	end)
	return check
end

local function BuildVolumeNote(frame, play)
	local note = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	note:SetPoint("TOPLEFT", play, "BOTTOMLEFT", 0, -LAYOUT.padding)
	note:SetWidth(LAYOUT.width - 2 * LAYOUT.padding)
	note:SetJustifyH("LEFT")
	note:SetText(TEXT.volumeNote)
	return note
end

local function BuildCommands(frame, below)
	local top = below
	for i, entry in ipairs(ns.Config.COMMANDS) do
		local cmd = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		cmd:SetPoint("TOPLEFT", top, "BOTTOMLEFT", 0, i == 1 and -LAYOUT.padding or -4)
		cmd:SetJustifyH("LEFT")
		cmd:SetText(entry[1])
		local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		desc:SetPoint("TOPLEFT", cmd, "TOPLEFT", LAYOUT.commandColumn, 0)
		desc:SetJustifyH("LEFT")
		desc:SetText(entry[2])
		top = cmd
	end
end

local function Build()
	local tint = Tint()
	local frame = CreateFrame("Frame", FRAME_NAME, UIParent, "BackdropTemplate")
	frame:SetSize(LAYOUT.width, LAYOUT.height)
	frame:SetFrameStrata("DIALOG")
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:SetBackdrop(BACKDROP)
	frame:SetBackdropColor(unpack(WINDOW_BG))
	frame:SetBackdropBorderColor(unpack(tint.border))
	frame:Hide()
	ApplyPosition(frame)
	tinsert(UISpecialFrames, FRAME_NAME)

	BuildTitleBar(frame, tint)
	local play = BuildPlay(frame, tint)
	local check = BuildEnabled(frame, play)
	local note = BuildVolumeNote(frame, play)
	BuildCommands(frame, note)

	window = { frame = frame, check = check }
end

function UI.Refresh()
	if not window or not ns.db then
		return
	end
	window.check:SetChecked(ns.db.enabled and true or false)
end

function UI.Toggle()
	if not ns.db then
		return
	end
	if not attempted then
		attempted = true
		Build()
	end
	if not window then
		return
	end
	if window.frame:IsShown() then
		window.frame:Hide()
	else
		UI.Refresh()
		window.frame:Show()
	end
end
