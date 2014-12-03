htLeaderboard = {}
htLeaderboard.name = "HyperToxic-s-Leaderboard"
htLeaderboard.version = 0.1

htLeaderboard.inCombat = false

htLeaderboard.WEEKLY = "Weekly"
htLeaderboard.HEL_RA_CITADEL = "Hel Ra Citadel"
htLeaderboard.AETHERIAN_ARCHIVE = "Aetherian Archive"
htLeaderboard.SANCTUM_OPHIDIA = "Sanctum Ophidia"
htLeaderboard.DRAGONSTAR_ARENA = "Dragonstar Arena (Veteran)"

htLeaderboard.boards = {htLeaderboard.WEEKLY, htLeaderboard.HEL_RA_CITADEL, htLeaderboard.AETHERIAN_ARCHIVE, htLeaderboard.SANCTUM_OPHIDIA, htLeaderboard.DRAGONSTAR_ARENA}

htLeaderboard.raidLeaderboardData = {}

-- Tooltip hooks

function ZO_FriendsListRowDisplayName_OnMouseEnter(control)
	local parent = control:GetParent()
	local data = ZO_ScrollList_GetData(parent)
	htLeaderboard:ShowTooltip(control, data.characterName)
end

function ZO_FriendsListRowDisplayName_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_GroupListRow_OnMouseEnter(control)
	local data = ZO_ScrollList_GetData(control)
	htLeaderboard:ShowTooltip(control, data.characterName)
end

function ZO_GroupListRow_OnMouseExit(control)
	ClearTooltip(InformationTooltip)
end

function ZO_GuildRosterRowDisplayName_OnMouseEnter(control)
	local parent = control:GetParent()
	local data = ZO_ScrollList_GetData(parent)
	htLeaderboard:ShowTooltip(control, data.characterName)
end

function ZO_GuildRosterRowDisplayName_OnMouseExit(control)
	ClearTooltip(InformationTooltip)
end

-- End tooltip hooks

-- Initialize our addon
function htLeaderboard.OnAddOnLoaded(eventCode, addOnName)
	if (addOnName == htLeaderboard.name) then 
		htLeaderboard:Initialize()
	end
end

function htLeaderboard:Initialize()
	self.inCombat = IsUnitInCombat("player")

	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_COMBAT_STATE, self.OnPlayerCombatState)

	--self.savedVariables = ZO_SavedVars:New("HyperToxic-s-LeaderboardSavedVariables", 1, nil, {})
	self.savedVariables = ZO_SavedVars:NewAccountWide("HyperToxic-s-LeaderboardSavedVariables", 1, nil, {})

    	htLeaderboardIndicatorBG:SetAlpha(0)
    
	htLeaderboardIndicator:SetWidth( 300 )
	htLeaderboardIndicator:SetHeight( 150 )

    	htLeaderboardIndicatorW:ClearAnchors();
    	htLeaderboardIndicatorW:SetAnchor(TOP, htLeaderboardIndicator, TOP, 0, 0)
    	htLeaderboardIndicatorW:SetWidth( 300 )
	htLeaderboardIndicatorW:SetHeight( 25 )
	htLeaderboardIndicatorW:SetHorizontalAlignment(1)

    	htLeaderboardIndicatorHRC:ClearAnchors();
    	htLeaderboardIndicatorHRC:SetAnchor(TOP, htLeaderboardIndicatorW, BOTTOM, 0, 0)
    	htLeaderboardIndicatorHRC:SetWidth( 300 )
	htLeaderboardIndicatorHRC:SetHeight( 25 )
	htLeaderboardIndicatorHRC:SetHorizontalAlignment(1)

    	htLeaderboardIndicatorAA:ClearAnchors();
    	htLeaderboardIndicatorAA:SetAnchor(TOP, htLeaderboardIndicatorHRC, BOTTOM, 0, 0)
    	htLeaderboardIndicatorAA:SetWidth( 300 )
	htLeaderboardIndicatorAA:SetHeight( 25 )
	htLeaderboardIndicatorAA:SetHorizontalAlignment(1)

    	htLeaderboardIndicatorSO:ClearAnchors();
    	htLeaderboardIndicatorSO:SetAnchor(TOP, htLeaderboardIndicatorAA, BOTTOM, 0, 0)
    	htLeaderboardIndicatorSO:SetWidth( 300 )
	htLeaderboardIndicatorSO:SetHeight( 25 )
	htLeaderboardIndicatorSO:SetHorizontalAlignment(1)

    	htLeaderboardIndicatorDSA:ClearAnchors();
    	htLeaderboardIndicatorDSA:SetAnchor(TOP, htLeaderboardIndicatorSO, BOTTOM, 0, 0)
    	htLeaderboardIndicatorDSA:SetWidth( 300 )
	htLeaderboardIndicatorDSA:SetHeight( 25 )
	htLeaderboardIndicatorDSA:SetHorizontalAlignment(1)

	self:RestorePosition()

	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_RETICLE_TARGET_CHANGED, htLeaderboard.TargetChange)

	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_GAME_CAMERA_UI_MODE_CHANGED, htLeaderboard.UIModeChanged)


	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_ACTIVATED, htLeaderboard.LateInitialize);
	EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED);
end

-- Fancy loaded message
function htLeaderboard.LateInitialize(eventCode, addOnName)
	d("htLeaderboard loaded...")

	htLeaderboard:UpdateRaidLeaderboardData()
	htLeaderboard:DisplayRaidLeaderboardData()

	EVENT_MANAGER:UnregisterForEvent(htLeaderboard.name, EVENT_PLAYER_ACTIVATED);
end

function htLeaderboard:ShowTooltip(control, characterName)
	local tooltip = characterName
	for i, board in ipairs(htLeaderboard.boards) do
		local boardData = htLeaderboard:GetCharectorNameRaidLeaderboardData(board, characterName)
		if boardData then
			local timeinminutes = boardData.time / 1000.0 / 60.0;
			local minutes = math.floor(timeinminutes);
			local seconds = math.floor((timeinminutes - minutes) * 60.0);
			tooltip = tooltip .. "\n" .. board .. " (" .. boardData.ranking .. ") " .. string.format("%d", minutes) .. ":" .. string.format("%02d", seconds)
		end
	end
	
	InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0, BOTTOMLEFT)
	SetTooltipText(InformationTooltip, tooltip)
end

function htLeaderboard:UpdateRaidLeaderboardData()
	QueryRaidLeaderboardData()
	
	local raidIndex
	local name, isWeekly, raidId, category
	local ranking, charName, time, classId, allianceId 
	local currentRanking, currentTime
	local entryIndex
	local currentPlayer
	local currentRaid
	local alliance

	alliance = GetUnitAlliance("player")

	htLeaderboard.raidLeaderboardData = {}

	for raidIndex = 1, GetNumRaidLeaderboards() do
		name, isWeekly, raidId, category = GetRaidLeaderboardInfo(raidIndex)
		if (isWeekly == true) then
			name = "Weekly"
		end

		--d("name: " .. name .. ", isWeekly: " .. string.format("%s", isWeekly and "true" or "false") .. ", raidId: " .. raidId .. ", category: " .. category )

		currentRanking = 0
		currentTime = 0

		htLeaderboard.raidLeaderboardData[name] = {}

		for entryIndex = 1 , GetNumRaidLeaderboardEntries(raidIndex) do
			ranking, charName, time, classId, allianceId = GetRaidLeaderboardEntryInfo(raidIndex, entryIndex)

			if (ranking > currentRanking) then
				currentRanking = ranking
				currentTime = time
			end

			if (alliance == allianceId) then

				--d("ranking: " .. currentRanking .. ", charName: " .. charName .. ", time: " .. currentTime .. ", classId: " .. classId .. ", allianceId: " .. allianceId)

				htLeaderboard.raidLeaderboardData[name][charName] = {ranking = currentRanking, charName = charName, time = currentTime, classId = classId, allianceId = allianceId}
			end
		end
	end
end

function htLeaderboard:GetCharectorNameRaidLeaderboardData(leaderboardName, charName)
	for key,value in pairs(htLeaderboard.raidLeaderboardData[leaderboardName]) do 
		if (key == charName) then
			return value
		end
	end
	return nil
end

function htLeaderboard:DisplayRaidLeaderboardDataForCharacter(leaderboardName, charName)
	local charData
	local timeinminutes
	local minutes
	local seconds
	charData = self:GetCharectorNameRaidLeaderboardData(leaderboardName, charName);
	if (charData ~= nil) then
		timeinminutes = charData.time / 1000.0 / 60.0;
		minutes = math.floor(timeinminutes);
		seconds = math.floor((timeinminutes - minutes) * 60.0);
		d(leaderboardName .. " Rank: #" .. charData.ranking .. " Time: " .. string.format("%02d", minutes) .. ":" .. string.format("%02d", seconds) )
	end
end

function htLeaderboard:DisplayRaidLeaderboardData()
	local playerName
	playerName = GetUnitName("player")
	self:DisplayRaidLeaderboardDataForName(playerName)
end

function htLeaderboard:DisplayRaidLeaderboardDataForName(playerName)
	for i, board in ipairs(htLeaderboard.boards) do
		self:DisplayRaidLeaderboardDataForCharacter(board, playerName)
	end
end

function htLeaderboard.OnIndicatorMoveStop()
	htLeaderboard.savedVariables.left = htLeaderboardIndicator:GetLeft()
	htLeaderboard.savedVariables.top = htLeaderboardIndicator:GetTop()
end

function htLeaderboard:RestorePosition()
	local left = self.savedVariables.left
	local top = self.savedVariables.top
 
	htLeaderboardIndicator:ClearAnchors()
	htLeaderboardIndicator:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, left, top)
end

function htLeaderboard.OnPlayerCombatState(event, inCombat)
	-- The ~= operator is "not equal to" in Lua.
	if inCombat ~= htLeaderboard.inCombat then
		-- The player's state has changed. Update the stored state...
		htLeaderboard.inCombat = inCombat
 
		-- ...and then announce the change.
		if inCombat then
			d("Entering combat.")
		else
			d("Exiting combat.")
		end
	end
end

function htLeaderboard:UpdateControl(raidName, playerName, control)

	local charData
	local timeinminutes
	local minutes
	local seconds
	local text

	charData = htLeaderboard:GetCharectorNameRaidLeaderboardData(raidName, playerName)
	if (charData ~= nil) then
		timeinminutes = charData.time / 1000.0 / 60.0;
		minutes = math.floor(timeinminutes);
		seconds = math.floor((timeinminutes - minutes) * 60.0);
		text = raidName .. " (" .. charData.ranking .. ") " .. string.format("%d:%02d", minutes, seconds)
		control:SetText(text)
		control:SetHeight( 25 )
	else
		control:SetText("")
		control:SetHeight( 0 )
	end

end

function htLeaderboard.TargetChange()

	local playerName

	if (IsReticleHidden() == false) then

		if (IsUnitPlayer('reticleover')) then
			playerName = GetUnitName('reticleover')

			htLeaderboard:UpdateControl(htLeaderboard.WEEKLY, playerName, htLeaderboardIndicatorW)
			htLeaderboard:UpdateControl(htLeaderboard.HEL_RA_CITADEL, playerName, htLeaderboardIndicatorHRC)
			htLeaderboard:UpdateControl(htLeaderboard.AETHERIAN_ARCHIVE, playerName, htLeaderboardIndicatorAA)
			htLeaderboard:UpdateControl(htLeaderboard.SANCTUM_OPHIDIA, playerName, htLeaderboardIndicatorSO)
			htLeaderboard:UpdateControl(htLeaderboard.DRAGONSTAR_ARENA, playerName, htLeaderboardIndicatorDSA)
		else
			htLeaderboardIndicatorW:SetText("")
			htLeaderboardIndicatorW:SetHeight( 0 )
			htLeaderboardIndicatorHRC:SetText("")
			htLeaderboardIndicatorHRC:SetHeight( 0 )
			htLeaderboardIndicatorAA:SetText("")
			htLeaderboardIndicatorAA:SetHeight( 0 )
			htLeaderboardIndicatorSO:SetText("")
			htLeaderboardIndicatorSO:SetHeight( 0 )
			htLeaderboardIndicatorDSA:SetText("")
			htLeaderboardIndicatorDSA:SetHeight( 0 )
		end

	end
end

function htLeaderboard.UIModeChanged()
	if (IsReticleHidden()) then
		htLeaderboardIndicatorBG:SetAlpha(100)
		htLeaderboardIndicatorW:SetText(htLeaderboard.WEEKLY)
		htLeaderboardIndicatorW:SetHeight( 25 )
		htLeaderboardIndicatorHRC:SetText(htLeaderboard.HEL_RA_CITADEL)
		htLeaderboardIndicatorHRC:SetHeight( 25 )
		htLeaderboardIndicatorAA:SetText(htLeaderboard.AETHERIAN_ARCHIVE)
		htLeaderboardIndicatorAA:SetHeight( 25 )
		htLeaderboardIndicatorSO:SetText(htLeaderboard.SANCTUM_OPHIDIA)
		htLeaderboardIndicatorSO:SetHeight( 25 )
		htLeaderboardIndicatorDSA:SetText(htLeaderboard.DRAGONSTAR_ARENA)
		htLeaderboardIndicatorDSA:SetHeight( 25 )
	else
		htLeaderboardIndicatorBG:SetAlpha(0)
		htLeaderboardIndicatorW:SetText("")
		htLeaderboardIndicatorW:SetHeight( 0 )
		htLeaderboardIndicatorHRC:SetText("")
		htLeaderboardIndicatorHRC:SetHeight( 0 )
		htLeaderboardIndicatorAA:SetText("")
		htLeaderboardIndicatorAA:SetHeight( 0 )
		htLeaderboardIndicatorSO:SetText("")
		htLeaderboardIndicatorSO:SetHeight( 0 )
		htLeaderboardIndicatorDSA:SetText("")
		htLeaderboardIndicatorDSA:SetHeight( 0 )
	end
end

EVENT_MANAGER:RegisterForEvent("htLeaderboard", EVENT_ADD_ON_LOADED, htLeaderboard.OnAddOnLoaded);
