local HealRotate = select(2, ...)

local L = HealRotate.L

-- Adds healer to global table and one of the two rotation tables
function HealRotate:registerHealer(healerName)

    -- Initialize healer 'object'
    local healer = {}
    healer.name = healerName
    healer.GUID = UnitGUID(healerName)
    healer.frame = nil
    healer.nextHeal = false
    healer.lastHealTime = 0
    healer.class_name = select(2, UnitClass(healerName))

    -- Add to global list
    table.insert(HealRotate.healerTable, healer)

    -- Add to rotation or backup group depending on rotation group size
    if (#HealRotate.rotationTables.rotation > 2) then
        table.insert(HealRotate.rotationTables.backup, healer)
    else
        table.insert(HealRotate.rotationTables.rotation, healer)
    end

    HealRotate:drawHealerFrames()

    return healer
end

-- Removes a healer from all lists
function HealRotate:removeHealer(deletedHealer)

    -- Clear from global list
    for key, healer in pairs(HealRotate.healerTable) do
        if (healer.name == deletedHealer.name) then
            HealRotate:hideHealer(healer)
            table.remove(HealRotate.healerTable, key)
            break
        end
    end

    -- clear from rotation lists
    for key, healerTable in pairs(HealRotate.rotationTables) do
        for subkey, healer in pairs(healerTable) do
            if (healer.name == deletedHealer.name) then
                table.remove(healerTable, subkey)
            end
        end
    end

    HealRotate:drawHealerFrames()
end

-- Update the rotation list once a heal has been done.
-- The parameter is the healer that used it's heal (successfully or not)
function HealRotate:rotate(lastHealer, rotateWithoutCooldown)

    local playerName, realm = UnitName("player")
    local healerRotationTable = HealRotate:getHealerRotationTable(lastHealer)

    lastHealer.lastHealTime = GetTime()

    -- Do not trigger cooldown when rotation from a dead or disconnected status
    if (rotateWithoutCooldown ~= true) then
        HealRotate:startHealerCooldown(lastHealer)
    else
        HealRotate:hideHealerCooldown(lastHealer)
    end

    if (healerRotationTable == HealRotate.rotationTables.rotation) then
        local nextHealer = HealRotate:getNextRotationHealer(lastHealer)

        if (nextHealer ~= nil) then

            HealRotate:setNextHeal(nextHealer)
        end
    end

    if (HealRotate:isPlayerNextHeal()) then
        HealRotate:throwHealAlert()
    end
end

-- Removes all nextHeal flags and set it true for next shooter
function HealRotate:setNextHeal(nextHealer)
    for key, healer in pairs(HealRotate.rotationTables.rotation) do
        if (healer.name == nextHealer.name) then
            healer.nextHeal = true

            if (nextHealer.name == UnitName("player")) and HealRotate.db.profile.enableNextToHealSound then
                PlaySoundFile(HealRotate.constants.sounds.nextToHeal)
            end
        else
            healer.nextHeal = false
        end

        HealRotate:refreshHealerFrame(healer)
    end
end

-- Check if the player is the next in position to heal
function HealRotate:isPlayerNextHeal()

    local player = HealRotate:getHealer(nil, UnitGUID("player"))

    -- Non healer user
    if (player == nil) then
        return false
    end

    if (not player.nextHeal) then

        local isRotationInitialized = false;
        local rotationTable = HealRotate.rotationTables.rotation

        -- checking if a healer is flagged nextHeal
        for key, healer in pairs(rotationTable) do
            if (healer.nextHeal) then
                isRotationInitialized = true;
                break
            end
        end

        -- First in rotation has to heal if not one is flagged
        if (not isRotationInitialized and HealRotate:getHealerIndex(player, rotationTable) == 1) then
            return true
        end

    end

    return player.nextHeal
end

-- Find and returns the next healer that will heal base on last shooter
function HealRotate:getNextRotationHealer(lastHealer)

    local rotationTable = HealRotate.rotationTables.rotation
    local nextHealer
    local lastHealerIndex = 1

    -- Finding last healer index in rotation
    for key, healer in pairs(rotationTable) do
        if (healer.name == lastHealer.name) then
            lastHealerIndex = key
            break
        end
    end

    -- Search from last healer index if not last on rotation
    if (lastHealerIndex < #rotationTable) then
        for index = lastHealerIndex + 1 , #rotationTable, 1 do
            local healer = rotationTable[index]
            if (HealRotate:isEligibleForNextHeal(healer)) then
                nextHealer = healer
                break
            end
        end
    end

    -- Restart search from first index
    if (nextHealer == nil) then
        for index = 1 , lastHealerIndex, 1 do
            local healer = rotationTable[index]
            if (HealRotate:isEligibleForNextHeal(healer)) then
                nextHealer = healer
                break
            end
        end
    end

    -- If no healer in the rotation match the alive/online/CD criteria
    -- Pick the healer with the lowest cooldown
    if (nextHealer == nil and #rotationTable > 0) then
        local latestHeal = GetTime() + 1
        for key, healer in pairs(rotationTable) do
            if (HealRotate:isHealerAliveAndOnline(healer) and healer.lastHealTime < latestHeal) then
                nextHealer = healer
                latestHeal = healer.lastHealTime
            end
        end
    end

    return nextHealer
end

-- Init/Reset rotation status, next heal is the first healer on the list
function HealRotate:resetRotation()
    for key, healer in pairs(HealRotate.rotationTables.rotation) do
        healer.nextHeal = false
        HealRotate:refreshHealerFrame(healer)
    end
end

-- @todo: remove this | TEST FUNCTION - Manually rotate healers for test purpose
function HealRotate:testRotation()

    for key, healer in pairs(HealRotate.rotationTables.rotation) do
        if (healer.nextHeal) then
            HealRotate:rotate(healer, false)
            break
        end
    end
end

-- Check if a healer is already registered
function HealRotate:isHealerRegistered(GUID)

    -- @todo refactor this using HealRotate:getHealer(name, GUID)
    for key,healer in pairs(HealRotate.healerTable) do
        if (healer.GUID == GUID) then
            return true
        end
    end

    return false
end

-- Return our healer object from name or GUID
function HealRotate:getHealer(name, GUID)

    for key,healer in pairs(HealRotate.healerTable) do
        if ((GUID ~= nil and healer.GUID == GUID) or (name ~= nil and healer.name == name)) then
            return healer
        end
    end

    return nil
end

-- Iterate over healer list and purge healer that aren't in the group anymore
function HealRotate:purgeHealerList()

    local change = false

    for key,healer in pairs(HealRotate.healerTable) do
        if (not UnitInParty(healer.name)) then
            HealRotate:unregisterUnitEvents(healer)
            HealRotate:removeHealer(healer)
            change = true
        end
    end

    if (change) then
        HealRotate:drawHealerFrames()
    end

end

-- Iterate over all raid members to find healers and update their status
function HealRotate:updateRaidStatus()

    if (HealRotate:isInPveRaid()) then

        local playerCount = GetNumGroupMembers()

        for index = 1, playerCount, 1 do

            local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(index)

            -- Players name might be nil at loading
            if (name ~= nil) then
                local GUID = UnitGUID(name)
                local healer

                if HealRotate.classes[select(2,UnitClass(name))] ~= nil then
                    local registered = HealRotate:isHealerRegistered(GUID)

                    if (not registered) then
                        if (not InCombatLockdown()) then
                            healer = HealRotate:registerHealer(name)
                            HealRotate:registerUnitEvents(healer)
                            registered = true
                        end
                    else
                        healer = HealRotate:getHealer(nil, GUID)
                    end

                    if (registered) then
                        HealRotate:updateHealerStatus(healer)
                    end
                end

            end
        end

        if (not HealRotate.raidInitialized) then
            if (not HealRotate.db.profile.doNotShowWindowOnRaidJoin) then
                HealRotate:updateDisplay()
            end
            HealRotate:sendSyncOrderRequest()
            HealRotate.raidInitialized = true
        end
    else
        if(HealRotate.raidInitialized == true) then
            HealRotate:updateDisplay()
            HealRotate.raidInitialized = false
        end
    end

    HealRotate:purgeHealerList()
end

-- Update healer status
function HealRotate:updateHealerStatus(healer)

    -- Jump to the next healer if the current one is dead or offline
    if (healer.nextHeal and (not HealRotate:isHealerAliveAndOnline(healer))) then
        HealRotate:rotate(healer, false, true)
    end

    HealRotate:refreshHealerFrame(healer)
end

-- Moves given healer to the given position in the given group (ROTATION or BACKUP)
function HealRotate:moveHealer(healer, group, position)

    local originTable = HealRotate:getHealerRotationTable(healer)
    local originIndex = HealRotate:getHealerIndex(healer, originTable)

    local destinationTable = HealRotate.rotationTables.rotation
    local finalIndex = position

    if (group == 'BACKUP') then
        destinationTable = HealRotate.rotationTables.backup
        -- Remove nextHeal flag when moved to backup
        healer.nextHeal = false
    end

    -- Setting originalIndex
    local sameTableMove = originTable == destinationTable

    -- Defining finalIndex
    if (sameTableMove) then
        if (position > #destinationTable or position == 0) then
            if (#destinationTable > 0) then
                finalIndex = #destinationTable
            else
                finalIndex = 1
            end
        end
    else
        if (position > #destinationTable + 1 or position == 0) then
            if (#destinationTable > 0) then
                finalIndex = #destinationTable  + 1
            else
                finalIndex = 1
            end
        end
    end

    if (sameTableMove) then
        if (originIndex ~= finalIndex) then
            table.remove(originTable, originIndex)
            table.insert(originTable, finalIndex, healer)
        end
    else
        table.remove(originTable, originIndex)
        table.insert(destinationTable, finalIndex, healer)
    end

    HealRotate:drawHealerFrames()
end

-- Find the table that contains given healer (rotation or backup)
function HealRotate:getHealerRotationTable(healer)
    if (HealRotate:tableContains(HealRotate.rotationTables.rotation, healer)) then
        return HealRotate.rotationTables.rotation
    end
    if (HealRotate:tableContains(HealRotate.rotationTables.backup, healer)) then
        return HealRotate.rotationTables.backup
    end
end

-- Returns a healer's index in the given table
function HealRotate:getHealerIndex(healer, table)
    local originIndex = 0

    for key, loopHealer in pairs(table) do
        if (healer.name == loopHealer.name) then
            originIndex = key
            break
        end
    end

    return originIndex
end

-- Builds simple rotation tables containing only healers names
function HealRotate:getSimpleRotationTables()

    local simpleTables = { rotation = {}, backup = {} }

    for key, rotationTable in pairs(HealRotate.rotationTables) do
        for _, healer in pairs(rotationTable) do
            table.insert(simpleTables[key], healer.name)
        end
    end

    return simpleTables
end

-- Apply a simple rotation configuration
function HealRotate:applyRotationConfiguration(rotationsTables)

    for key, rotationTable in pairs(rotationsTables) do

        local group = 'ROTATION'
        if (key == 'backup') then
            group = 'BACKUP'
        end

        for index, healerName in pairs(rotationTable) do
            local healer = HealRotate:getHealer(healerName)
            if (healer) then
                HealRotate:moveHealer(healer, group, index)
            end
        end
    end
end

-- Display an alert and play a sound when the player should immediatly heal
function HealRotate:throwHealAlert()
    RaidNotice_AddMessage(RaidWarningFrame, L['HEAL_NOW_LOCAL_ALERT_MESSAGE'], ChatTypeInfo["RAID_WARNING"])

    if (HealRotate.db.profile.enableHealNowSound) then
        PlaySoundFile(HealRotate.constants.sounds.alarms[HealRotate.db.profile.healNowSound])
    end
end
