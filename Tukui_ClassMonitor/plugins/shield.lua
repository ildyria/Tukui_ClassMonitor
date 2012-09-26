-- Dot Plugin, credits to Ildyria
local ADDON_NAME, Engine = ...
local T, C, L = unpack(Tukui) -- Import: T - functions, constants, variables; C - config; L - locales

function Engine:CreateShieldMonitor(name, spelltracked, anchor, width, height, colors, absorbthreshold, timethreshold)

	local cmShield = CreateFrame("Frame", name, TukuiPetBattleHider)
	cmShield:SetTemplate()
	cmShield:SetFrameStrata("BACKGROUND")
	cmShield:Size(width, height)
	cmShield:Point(unpack(anchor))

	cmShield.status = CreateFrame("StatusBar", "cmShieldStatus", cmShield)
	cmShield.status:SetStatusBarTexture(C.media.normTex)
	cmShield.status:SetFrameLevel(6)
	cmShield.status:Point("TOPLEFT", cmShield, "TOPLEFT", 2, -2)
	cmShield.status:Point("BOTTOMRIGHT", cmShield, "BOTTOMRIGHT", -2, 2)
	cmShield.status:SetMinMaxValues(0, UnitPowerMax("player"))

	cmShield.text = cmShield.status:CreateFontString(nil, "OVERLAY")
	cmShield.text:SetFont(C.media.uffont, 12)
	cmShield.text:Point("CENTER", cmShield.status)
	cmShield.text:SetShadowColor(0, 0, 0)
	cmShield.text:SetShadowOffset(1.25, -1.25)

	cmShield.dmg = 0
	cmShield.timeSinceLastUpdate = GetTime()

	cmShield.tooltip = CreateFrame( "GameTooltip", "cmShieldTooltip" ); -- Tooltip name cannot be nil
	cmShield.tooltip:SetOwner( WorldFrame, "ANCHOR_NONE" );
	cmShield.tooltip:AddFontStrings(
	cmShield.tooltip:CreateFontString( "$parentTextLeft1", nil, "GameTooltipText" ),
	cmShield.tooltip:CreateFontString( "$parentTextRight1", nil, "GameTooltipText" ) );

	-- we need to use another function to check spell ID instead of spell Name (example : Paladin Sacred Shield)
	local function cmUnitBuff(unitID, inSpellID)
		for i = 1, 40, 1 do
			local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellID = UnitBuff(unitID, i)
			if not GetSpellInfo(spellID) then return; end
			if not name then break end
			if inSpellID == spellID then
				return name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellID, i
			end
		end
		return nil
	end

	local function OnUpdate(self, elapsed)
		cmShield.timeSinceLastUpdate = cmShield.timeSinceLastUpdate + elapsed
		if cmShield.timeSinceLastUpdate > 0.01 then
			
			local _, _, _, _, _, duration, expTime, _, _, _, _, i = cmUnitBuff("player", spelltracked)

			local newbietips = GetCVar("UberTooltips");
			SetCVar("UberTooltips","0");
			cmShield.tooltip:ClearLines();
			cmShield.tooltip:SetUnitBuff('player', i)
			local tiplines = cmShield.tooltip:NumLines();
			if (tiplines > 2) then
				local mytext = getglobal("cmShieldTooltipTextLeft2");
				local text = mytext:GetText();
				local _,_,dmgab = strfind(text, "[aA]bsorb%a* (%d+) [^d]?%a*%s?damage");
				if (dmgab == nil) then
					print("unable to read shield value from tooltip ");
					cmShield:Hide()
					dmgab = -1;
				end
				cmShield.dmg = tonumber(dmgab);
			else
				print("failed reading spell ");
				cmShield:Hide()
				cmShield.dmg = -1;
			end
			-- restore the player's chosen tooltip setting
			SetCVar("UberTooltips",newbietips);
		
			local remainTime = expTime - GetTime()
			local color

			if(remainTime <= timethreshold) then 
				color = {1,0,0,1}
			else
				if(absorbthreshold <= cmShield.dmg) then
					color = (colors and (colors[1])) or T.UnitColor.class[T.myclass]
				else
					color = (colors and (colors[2])) or T.UnitColor.class[T.myclass]
				end
			end
			cmShield.status:SetStatusBarColor(unpack(color))
			cmShield.status:SetMinMaxValues(0, duration)
			cmShield.status:SetValue(remainTime)
			cmShield.text:SetText(cmShield.dmg)
			cmShield.timeSinceLastUpdate = 0
		end
	end

	local function CombatAuraCheck(self,event)																			-- Aura check
		local _, _, _, count, _, duration, expTime, _, _, _, _ = cmUnitBuff("player", spelltracked)
		if expTime ~= nil then
			local remainTime = expTime - GetTime()
			if remainTime <= 0 then
				remainTime = 0
				cmShield:Hide()
				cmShield.dmg = 0
			end
			cmShield:Show()
		else
			cmShield:Hide()
			cmShield.dmg = 0
		end
	end

	cmShield.auracheck = CreateFrame("Frame", "cmAuraCheck", cmShield)
	cmShield.auracheck:RegisterEvent("PLAYER_ENTERING_WORLD")
	cmShield.auracheck:RegisterEvent("UNIT_AURA")
	cmShield.auracheck:SetScript("OnEvent", CombatAuraCheck)

	-- This is what stops constant OnUpdate
	cmShield:SetScript("OnShow", function(self) self:SetScript("OnUpdate", OnUpdate) end)
	cmShield:SetScript("OnHide", function (self) self:SetScript("OnUpdate", nil) end)
	
	return cmShield
end