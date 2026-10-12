--[[ Azerothian Relic - a complete theme for NetherUI (and NetherBars, when installed)

	Ancient bronze reliquary, navy obsidian and polished lapis. Every texture is Azerothian
	Relic's own artwork (RelicData.lua lists them; Textures/ holds them).

	How it plugs in (only the public plugin APIs, nothing of NetherUI is changed):
	  NetherUI:RegisterTheme("azerothianrelic", palette + art)   the theme and its art swaps
	  NetherUI:RegisterTexture("AzerothianRelic_<Name>", info)   pieces with no Nether slot
	  NetherBars:RegisterThemePack / RegisterMedia / RegisterTheme   the nameplate theme

	Pick it in NetherUI's Settings > General > Theme, or /nui theme azerothianrelic.
	Switching to another theme puts NetherUI's own art back. ]]

local ADDON, ns = ...
local A = _G.NetherUI
local D = ns.Data
local ROOT = "Interface\\AddOns\\" .. ADDON .. "\\"
local KEY = "azerothianrelic"
local TITLE = "|cffc9a45cAzerothian|r |cff3a5fb8Relic|r"
local VERSION = (C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata or function() end)(ADDON, "Version") or "?"

local Relic = { key = KEY, version = VERSION, problems = {} }
ns.Relic = Relic
_G.AzerothianRelic = Relic

local function Say(msg)
	if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(TITLE .. "  " .. msg) else print("Azerothian Relic  " .. msg) end
end

-- a problem is never swallowed: it is kept (/relic shows them) and said once
local function Problem(where, err)
	local line = where .. ": " .. tostring(err)
	Relic.problems[#Relic.problems + 1] = line
	Say("|cffff8080could not " .. line .. "|r")
end

-- ------------------------------------------------------------------ requirement check
local SUPPORTED = type(A) == "table" and type(A.RegisterTheme) == "function" and type(A.RegisterTexture) == "function"
if not SUPPORTED then
	local f = CreateFrame("Frame")
	f:RegisterEvent("PLAYER_LOGIN")
	f:SetScript("OnEvent", function()
		Say("needs |cffffffffNetherUI 2.0 or newer|r. Install or update NetherUI, then restart the game.")
	end)
	return
end

-- ------------------------------------------------------------------ NetherUI theme
local function Entry(e)
	local t = { path = ROOT .. e.path, w = e.w, h = e.h }
	if e.colored then t.colored = true end
	if e.slice then t.slice = { e.slice[1], e.slice[2], e.slice[3], e.slice[4] } end
	if e.blend then t.blend = e.blend end
	if e.tile then t.tile = true end
	return t
end

-- pieces without a NetherUI slot (talent backdrops, extra glyphs...) stay available by name
for name, e in pairs(D.extra) do
	local ok, err = pcall(A.RegisterTexture, A, "AzerothianRelic_" .. name, Entry(e))
	if not ok then Problem("register texture " .. name, err) end
end

local function Palette()
	local p = {
		name = "Azerothian Relic", mode = "dark",
		desc = "Ancient bronze reliquary, navy obsidian and polished lapis.",
		light = true,            -- keep Nether's Light (seams, edge light, embers) with the Relic's own light art
		-- the Relic's tooltip border is thick bronze: text kept clear of it on every side
		tooltipPad = { left = 10, right = 10, bottom = 6 },
		art = {},
	}
	for role, c in pairs(D.palette) do p[role] = { c[1], c[2], c[3], c[4] } end
	for name, e in pairs(D.art) do p.art[name] = Entry(e) end
	return p
end

local ok, err = pcall(A.RegisterTheme, A, KEY, Palette())
if not ok then Problem("register the NetherUI theme", err) end
Relic.netherTheme = ok

-- ------------------------------------------------------------------ NetherBars theme (optional)
-- NetherBars themes use bar-shaped pieces (fill, edge, mask, caps, crest, ring, target glow).
-- The Relic's compatibility pieces are made for exactly these slots. Caps, crest and portrait
-- ring are painted in colour, so the theme asks NetherBars (3.0.26+) to draw them as painted.
--
-- ALL OR NONE: the Relic is one complete look. While Azerothian Relic is NetherUI's theme,
-- NetherBars draws every kind of nameplate and its unit frames with the Relic too, whatever was
-- picked per kind; with any other NetherUI theme, nothing anywhere uses the Relic (a Relic
-- choice saved in NetherBars falls back to what NetherBars would otherwise show). The players'
-- own NetherBars choices are never overwritten: the Relic only decides which theme is drawn.
local PACK = "azerothianrelic"
function Relic:Active() return A.db and A.db.theme == KEY or false end
local function Hex(c) return string.format("#%02x%02x%02x", c[1] * 255 + 0.5, c[2] * 255 + 0.5, c[3] * 255 + 0.5) end

-- Native unit-frame plates: texture size, and per frame the plate, its wells and portrait opening
-- in art pixels (measured from the approved runtime frames; the wells are runtime_bindings.json's)
local NATIVE_CANVAS = {
	Player = { 1024, 256 }, Focus = { 512, 256 }, Party = { 512, 128 }, Target_of_Target = { 256, 256 },
	Nameplate_Normal = { 512, 128 }, Nameplate_Elite = { 1024, 128 }, Nameplate_Rare = { 1024, 256 },
}
-- the chevrons worn around a target's portrait (Extra/UnitFrames Crest_Circle sets, joined)
local function Chevron(kind)
	return { wings = PACK .. "/Chevron_" .. kind .. "_Wings", body = PACK .. "/Chevron_" .. kind .. "_Body",
		gem = PACK .. "/Chevron_" .. kind .. "_Gem", gemTint = "gem", scale = 2 }
end
local function Native(plate, t)
	t.frame = PACK .. "/Native_" .. plate
	t.well = PACK .. "/Native_" .. plate .. "_Well"
	t.canvas = NATIVE_CANVAS[plate]
	return t
end
local function EliteBar(kind)
	return Native("Nameplate_Elite", { art = { 793, 244 }, frameAt = { 0, 102 }, frameArt = { 538, 118 }, scale = 0.5,
		nameAbove = 35, health = { 73, 35, 466, 57 },
		portrait = { cx = 618, cy = 148, d = 120, levelY = 96, over = true, ring = PACK .. "/Ring_Circle", crest = Chevron(kind) } })
end
-- nameplates: the approved painted plates, the bar in the well (top / bottom: where the paint starts and ends)
local NATIVE_PLATES = {
	normal = Native("Nameplate_Normal", { art = { 367, 88 }, health = { 50, 41, 314, 56 }, top = 20, bottom = 80 }),
	elite  = Native("Nameplate_Elite",  { art = { 538, 118 }, health = { 73, 35, 466, 57 }, top = 0, bottom = 118 }),
	rare   = Native("Nameplate_Rare",   { art = { 571, 151 }, health = { 109, 43, 467, 70 }, top = 0, bottom = 151 }),
}
local NATIVE = {
	player = Native("Player", { art = { 596, 211 }, scale = 0.56,
		nameAbove = 10, health = { 205, 88, 556, 118 }, power = { 209, 137, 553, 149 }, portrait = { cx = 101.5, cy = 104, d = 123, levelY = 108 } }),
	-- a normal target: the player's plate facing the other way
	target = Native("Player", { art = { 596, 211 }, scale = 0.56, mirror = true,
		nameAbove = 10, health = { 205, 88, 556, 118 }, power = { 209, 137, 553, 149 }, portrait = { cx = 101.5, cy = 104, d = 123, levelY = 108 } }),
	-- elites, elite bosses (world bosses, ?? and level-cap elites such as Saurfang and Runthak), rares and
	-- rare elites: the horned elite bar for all of them, the portrait in its ring with that kind's chevron
	targetElite = EliteBar("Elite"),
	targetBoss = EliteBar("Boss"),
	targetRare = EliteBar("Rare"),
	targetRareElite = EliteBar("RareElite"),
	bossLevel = "max",
	focus = Native("Focus", { art = { 318, 138 }, scale = 0.6,
		health = { 98, 93, 284, 109 }, portrait = { cx = 53, cy = 84, d = 54, levelY = 30, square = true, over = true } }),
	pet = Native("Party", { art = { 427, 122 }, scale = 0.5,
		health = { 116, 62, 385, 79 }, power = { 115, 90, 386, 100 }, portrait = { cx = 64, cy = 60, d = 58, levelY = 32, over = true } }),
	targettarget = Native("Target_of_Target", { art = { 255, 149 }, scale = 0.55,
		health = { 111, 65, 203, 79 }, portrait = { cx = 63, cy = 93, d = 82, levelY = 44 } }),
}

function Relic:RegisterBars()
	local AB = rawget(_G, "NetherBars")
	if self.barsDone or not (AB and AB.RegisterThemePack and AB.RegisterMedia and AB.RegisterTheme and (AB.API_VERSION or 0) >= 1) then return end
	self.barsDone = true
	AB:RegisterThemePack({ id = PACK, name = "Azerothian Relic", author = "NetherUI", version = VERSION,
		description = "Bronze reliquary plates with lapis fills, to match the Azerothian Relic theme for NetherUI." })
	local function Media(name, e)
		local opts = {}
		if e.slice then opts.slice = { e.slice[1], e.slice[2], e.slice[3], e.slice[4] } end
		if e.blend and e.blend ~= "BLEND" then opts.blend = e.blend end
		if name == "Fill_Flow" then opts.frames = 32 end
		AB:RegisterMedia(PACK .. "/" .. name, ROOT .. e.path, e.w, e.h, opts)
	end
	for name, e in pairs(D.bars) do Media(name, e) end
	-- from the NetherUI set: the target glow and the classification crests
	Media("Nameplate_Glow", D.art.Nameplate_Glow)
	Media("Crest_Elite", D.extra.Crest_Elite or D.art.Crest_Elite)
	Media("Crest_Rare", D.extra.Crest_Rare or D.art.Crest_Rare)
	Media("Portrait_Ring", D.art.Portrait_Ring)
	Media("Portrait_Chevron", D.art.Portrait_Chevron)
	Media("Portrait_Chevron_Wings", D.art.Portrait_Chevron_Wings)
	Media("Portrait_Chevron_Gem", D.art.Portrait_Chevron_Gem)
	-- the approved native unit-frame plates (Phase 1 locked art): the painted plate with its
	-- wells and portrait opening cut out, and the dark wells behind the bars
	for plate, size in pairs(NATIVE_CANVAS) do
		AB:RegisterMedia(PACK .. "/Native_" .. plate, ROOT .. "Textures\\Native\\" .. plate .. "_Frame", size[1], size[2], {})
		AB:RegisterMedia(PACK .. "/Native_" .. plate .. "_Well", ROOT .. "Textures\\Native\\" .. plate .. "_Well", size[1], size[2], {})
	end
	AB:RegisterMedia(PACK .. "/Ring_Circle", ROOT .. "Textures\\Native\\Ring_Circle", 128, 128, {})
	AB:RegisterMedia(PACK .. "/Target_Mark", ROOT .. "Textures\\Native\\Target_Mark", 128, 128, {})
	AB:RegisterMedia(PACK .. "/Target_Mark_Glow", ROOT .. "Textures\\Native\\Target_Mark_Glow", 64, 64, {})
	for _, kind in ipairs({ "Elite", "Boss", "Rare", "RareElite" }) do
		for _, part in ipairs({ "Wings", "Body", "Gem" }) do
			AB:RegisterMedia(PACK .. "/Chevron_" .. kind .. "_" .. part, ROOT .. "Textures\\Native\\Chevron_" .. kind .. "_" .. part, 256, 256, {})
		end
	end

	local P = D.palette
	local okT, errs = AB:RegisterTheme(PACK .. "_relic", {
		pack = PACK, name = "Azerothian Relic", category = "Relic",
		description = "Bronze rails, lapis fill and the Relic's crests; matches the Azerothian Relic theme for NetherUI.",
		traits = { "bronze", "lapis", "relic" },
		netherKeys = { KEY },
		palette = {
			background = Hex(P.bg), surface = Hex(P.bgAlt), border = Hex(P.border),
			accent = Hex(P.accent), highlight = Hex(P.borderHighlight), glow = Hex(P.targetGlow),
			health = Hex(P.health), healthLoss = Hex(P.negative), text = Hex(P.text), textDim = Hex(P.textDim),
			worldText = Hex(P.worldText), elite = Hex(P.accent), selection = Hex(P.targetGlow),
		},
		fonts = { primary = "Cinzel|Friz", numeric = "ArialNarrow", display = "Cinzel|Friz" },
		plate = {
			height = 12, castHeight = 9,
			health = { fill = PACK .. "/Fill_LapisGrain", flow = PACK .. "/Fill_Flow", edge = PACK .. "/Edge",
				mask = PACK .. "/Mask", cap = PACK .. "/Cap_Left" },
			cast = { fill = PACK .. "/Fill_Smooth", edge = PACK .. "/Edge", shield = PACK .. "/Castbar_Shield" },
			target = { kind = "glow", art = PACK .. "/Nameplate_Glow", tint = "glow" },
			crest = PACK .. "/Crest_Elite",
			ring = PACK .. "/Portrait_Ring",
			ringTint = "white", capTint = "white", crestTint = "white",   -- painted art, drawn as painted
			-- elites wear the Relic chevron around the portrait (as on NetherUI's own frames)
			portraitCrest = { body = PACK .. "/Portrait_Chevron", wings = PACK .. "/Portrait_Chevron_Wings",
				gem = PACK .. "/Portrait_Chevron_Gem", scale = 2, bodyTint = "white", wingsTint = "white", gemTint = "gem" },
			capsOnTop = true,   -- the caps are the plate's painted ends: over the bar ends, on every unit
			-- unit frames are the approved native plates; the level, a size larger, sits under the portrait
			nativeFrames = NATIVE,
			nativePlates = NATIVE_PLATES,   -- and the nameplates are the approved painted plates
			-- the Triad Crown over your target's nameplate, its lapis glow pulsing softly
			targetMark = { art = PACK .. "/Target_Mark", glow = PACK .. "/Target_Mark_Glow", w = 40, h = 40, y = -8,
				glowTint = { 0.3, 0.5, 1 } },
			friendlyPlayerLook = "oocName", -- friendly players: their name, and the plate while they're in combat
			levelSize = 14,
			power = { fill = PACK .. "/Fill_Smooth", height = 3 },
			anim = { target = "breathe" },
		},
	})
	if okT == false then Problem("register the NetherBars theme", type(errs) == "table" and table.concat(errs, "; ") or errs) end
	self.barsTheme = okT ~= false
	local T = AB.Themes
	if not (self.barsTheme and T and type(T.ScopeId) == "function") then return end
	local ID = PACK .. "_relic"
	if type(T.NETHER_MAP) == "table" then T.NETHER_MAP[KEY] = ID end   -- shown as "follows NetherUI"
	-- every scope (each nameplate kind, the unit frames): the Relic exactly while it is NetherUI's theme
	local ScopeId = T.ScopeId
	T.ScopeId = function(themes, scope, ...)
		if tostring(scope):match("^theme:") then return ScopeId(themes, scope, ...) end  -- gallery previews
		if Relic:Active() then return ID end
		local id = ScopeId(themes, scope, ...)
		if id ~= ID then return id end
		local mapped = T.NETHER_MAP and T.NETHER_MAP[T:NetherThemeKey() or ""]
		return (mapped and mapped ~= ID and themes.byId[mapped]) and mapped or "vanilla"
	end
	self.barsAll = true
	-- redraw NetherBars whenever the Relic switches on or off in NetherUI
	local was = self:Active()
	A:RegisterCallback("THEME_CHANGED", function()
		local now = Relic:Active()
		if now ~= was then
			was = now
			if T.Invalidate then T:Invalidate() end
			if AB.Apply then AB:Apply(true) end
		end
	end)
	if was then T:Invalidate(); if AB.Apply then AB:Apply(true) end end
end

-- NetherBars normally loads first (OptionalDeps); if it loads later, catch it then
local function TryBars()
	local okB, errB = pcall(Relic.RegisterBars, Relic)
	if not okB then Problem("set up the NetherBars theme", errB) end
end
TryBars()
if not Relic.barsDone then
	local f = CreateFrame("Frame")
	f:RegisterEvent("ADDON_LOADED")
	f:SetScript("OnEvent", function(self, _, name)
		if name == "NetherBars" then self:UnregisterEvent("ADDON_LOADED"); TryBars() end
	end)
end

-- ------------------------------------------------------------------ the choice: Relic on or off
-- AzerothianRelicDB (account-wide):
--   asked  = true once the login question was answered (either way)
--   prev   = the NetherUI theme the player had before the Relic, given back when it is turned off
-- "On" simply means Azerothian Relic is NetherUI's theme. That one switch hands NetherUI's art
-- and, through the scope wrapper above, every NetherBars nameplate kind and its unit frames to
-- the Relic. "Off" puts the previous NetherUI theme back; NetherBars was never changed, so its
-- own choices show again at once. Picking themes in NetherUI's gallery works the same way.
local DB
local DEFAULT_THEME = "obsidian"

local function ThemeExists(key)
	local M = _G.NetherMedia
	return type(key) == "string" and M and M.themes and M.themes[key] ~= nil
end

function Relic:Enable()
	if DB then DB.asked = true end
	if self:Active() then return end
	if DB and A.db and A.db.theme and A.db.theme ~= KEY then DB.prev = A.db.theme end
	A:SetTheme(KEY)
end

function Relic:Disable()
	if DB then DB.asked = true end
	if not self:Active() then return end
	local back = DB and DB.prev
	if not ThemeExists(back) or back == KEY then back = DEFAULT_THEME end
	A:SetTheme(back)
end

function Relic:SetEnabled(on) if on then self:Enable() else self:Disable() end end

-- remember the player's own theme whenever it isn't the Relic (gallery picks included)
A:RegisterCallback("THEME_CHANGED", function(key)
	key = type(key) == "string" and key or (A.db and A.db.theme)
	if DB and key and key ~= KEY then DB.prev = key end
	if DB and key == KEY then DB.asked = true end
	if Relic.check then Relic.check:SetChecked(Relic:Active()) end
end)

-- The square minimap border: Nether's own art is a thin frame at the texture's edge, so NetherUI
-- draws it 5 pixels outside the map. The Relic's frame is broad, with its opening 28 of 256 pixels
-- in from each side. While the Relic is on, the border is sized so its opening covers the map's
-- edge by 2 pixels all round (the frame's rim sits over the map, never a gap between them); off,
-- or round: NetherUI's own placement again.
local MINIMAP_OPEN = 1 - 2 * 28 / 256
local MINIMAP_OVERLAP = 2
function Relic:FitMinimap()
	local S = A.Skins
	local fr = S and S.minimapFrame
	local M = rawget(_G, "Minimap")
	if not (fr and M) then return end
	local off = 5
	local square = not (A.db and A.db.skins and A.db.skins.minimapShape == "round")
	if self:Active() and square then
		local w = M:GetWidth()
		if type(w) == "number" and w > 0 then off = ((w - 2 * MINIMAP_OVERLAP) / MINIMAP_OPEN - w) / 2 end
	end
	if fr.relicOff == off then return end
	fr.relicOff = off
	fr:ClearAllPoints()
	fr:SetPoint("TOPLEFT", M, "TOPLEFT", -off, off)
	fr:SetPoint("BOTTOMRIGHT", M, "BOTTOMRIGHT", off, -off)
end
-- Quest giver windows: the Relic's ornate corners are large, and NetherUI draws the ornate
-- border over the whole window, so the corners covered Accept, Decline and Complete. While the
-- Relic is on, these windows draw their contents over the border (as the spellbook's page sits
-- over its border); off, NetherUI's own order again (border on top).
local UNDER_BORDER = { "QuestFrame", "GossipFrame" }
function Relic:LayerQuestWindows()
	for _, name in ipairs(UNDER_BORDER) do
		local f = rawget(_G, name)
		local o = f and f.AUIOrnate
		if o and o.SetFrameLevel and not (InCombatLockdown and InCombatLockdown()) then
			o:SetFrameLevel(f:GetFrameLevel() + (self:Active() and 0 or 60))
		end
	end
end
A:RegisterCallback("THEME_CHANGED", function() Relic:FitMinimap(); Relic:LayerQuestWindows() end)
if A.Skins and type(A.Skins.Window) == "function" then
	hooksecurefunc(A.Skins, "Window", function(_, f)
		local n = f and f.GetName and f:GetName()
		if n == "QuestFrame" or n == "GossipFrame" then Relic:LayerQuestWindows() end
	end)
end
if type(A.SetMinimapShape) == "function" then hooksecurefunc(A, "SetMinimapShape", function() Relic:FitMinimap() end) end

-- (only our own entry is added to the game's popup table; the table itself is never assigned, which
-- would taint it and get the Relic blamed for blocked actions in the game's own windows)
StaticPopupDialogs.AZEROTHIANRELIC_TAKEOVER = {
	text = TITLE .. "\n\nWould you like to allow Azerothian Relic to handle all UI/Nameplates/Unit Frames?\n\n" ..
		"|cffaaaaaaYou can change this at any time in Options > AddOns > Azerothian Relic.|r",
	button1 = "Azerothian Relic",
	button2 = "No",
	OnAccept = function() Relic:Enable() end,
	OnCancel = function(_, _, reason)
		-- "No" keeps everything as it is; closing it some other way asks again next login
		if reason == "clicked" and DB then DB.asked = true end
	end,
	timeout = 0, whileDead = true, hideOnEscape = false, showAlert = true, preferredIndex = 3,
}

function Relic:Ask()
	if StaticPopup_Show then StaticPopup_Show("AZEROTHIANRELIC_TAKEOVER") end
end

-- Options > AddOns > Azerothian Relic: the one switch
function Relic:BuildOptions()
	local SS = rawget(_G, "Settings")
	if self.panel or type(SS) ~= "table" or not SS.RegisterCanvasLayoutCategory or not SS.RegisterAddOnCategory then return end
	local p = CreateFrame("Frame")
	p:Hide()
	self.panel = p
	p:SetScript("OnShow", function()
		if not p.built then
			p.built = true
			local logo = p:CreateTexture(nil, "ARTWORK")
			logo:SetSize(52, 52)
			logo:SetPoint("TOPLEFT", 16, -14)
			logo:SetTexture(ROOT .. "Media\\Icon")
			local title = p:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 10, -6)
			title:SetText(TITLE .. "  " .. VERSION)
			local about = p:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
			about:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
			about:SetWidth(520); about:SetJustifyH("LEFT")
			about:SetText("Ancient bronze reliquary, navy obsidian and polished lapis: one complete look for NetherUI and NetherBars.")
			local cb = CreateFrame("CheckButton", nil, p, "NetherUI_CheckTemplate")
			cb:SetPoint("TOPLEFT", 16, -96)
			if cb.Label then cb.Label:SetText("Let Azerothian Relic handle all UI, nameplates and unit frames") end
			cb:HookScript("OnClick", function(b) Relic:SetEnabled(b:GetChecked() and true or false) end)
			self.check = cb
			local note = p:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			note:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 4, -10)
			note:SetWidth(520); note:SetJustifyH("LEFT")
			note:SetText("On: NetherUI and NetherBars hand everything they draw to the Relic.\n" ..
				"Off: they take it straight back, exactly as you had it. Same as /relic on and /relic off.")
		end
		if self.check then self.check:SetChecked(self:Active()) end
	end)
	local ok, cat = pcall(SS.RegisterCanvasLayoutCategory, p, "Azerothian Relic")
	if ok and cat then
		pcall(SS.RegisterAddOnCategory, cat)
		self.category = cat
	else
		Problem("add the options page", cat)
	end
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(self, event, name)
	if event == "ADDON_LOADED" then
		if name ~= ADDON then return end
		AzerothianRelicDB = type(AzerothianRelicDB) == "table" and AzerothianRelicDB or {}
		DB = AzerothianRelicDB
		Relic.db = DB
		if A.db and A.db.theme and A.db.theme ~= KEY and not DB.prev then DB.prev = A.db.theme end
		return
	end
	self:UnregisterAllEvents()
	local okO, errO = pcall(Relic.BuildOptions, Relic)
	if not okO then Problem("add the options page", errO) end
	if Relic:Active() then DB.asked = true end
	Relic:FitMinimap()
	Relic:LayerQuestWindows()
	local M = rawget(_G, "Minimap")
	if M and M.HookScript then M:HookScript("OnSizeChanged", function() Relic:FitMinimap() end) end
	if C_Timer and C_Timer.After then C_Timer.After(1, function() Relic:FitMinimap() end) end
	if not DB.asked then C_Timer.After(2, function() if not DB.asked and not Relic:Active() then Relic:Ask() end end) end
end)

-- ------------------------------------------------------------------ /relic
SLASH_AZEROTHIANRELIC1 = "/relic"
SlashCmdList.AZEROTHIANRELIC = function(msg)
	msg = strlower(strtrim(msg or ""))
	if msg == "on" or msg == "use" then
		Relic:Enable(); Say("on: NetherUI and NetherBars hand everything to the Relic. |cffaaaaaa/relic off|r gives it back.")
	elseif msg == "off" then
		Relic:Disable(); Say("off: NetherUI and NetherBars are back exactly as you had them.")
	elseif msg == "ask" then
		Relic:Ask()
	else
		Say(("version %s, %s. NetherUI theme: %s. NetherBars theme: %s."):format(VERSION,
			Relic:Active() and "|cff60ff60on|r (/relic off)" or "off (/relic on)",
			Relic.netherTheme and "|cff60ff60ready|r" or "|cffff6060missing|r",
			Relic.barsTheme and ("|cff60ff60ready|r" .. (Relic.barsAll and ", all nameplates and unit frames" or "")) or ((rawget(_G, "NetherBars") and rawget(_G, "NetherBars").RegisterThemePack) and "|cffff6060missing|r" or "NetherBars not installed")))
		for _, line in ipairs(Relic.problems) do Say("|cffff8080" .. line .. "|r") end
		-- the target frame's plate and what the game says about the target (to check the choice)
		local AB = rawget(_G, "NetherBars")
		local uf = AB and AB.UnitFrames and AB.UnitFrames.frames and AB.UnitFrames.frames.target
		local d = uf and uf.display
		if d and d.unit then
			local cls, lvl = UnitClassification("target"), UnitEffectiveLevel("target")
			if issecretvalue and (issecretvalue(cls) or issecretvalue(lvl)) then cls, lvl = "hidden", "hidden" end
			Say(("target: %s, level %s; frame plate: %s"):format(tostring(cls), tostring(lvl), tostring(d.nativeVariant or "built")))
		end
	end
end
