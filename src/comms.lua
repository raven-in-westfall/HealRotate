local HealRotate = select(2, ...)

local AceComm = LibStub("AceComm-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")

-- Register comm prefix at initialization steps
function HealRotate:initComms()

    HealRotate.syncVersion = 0
    HealRotate.syncLastSender = ''

    AceComm:RegisterComm(HealRotate.constants.commsPrefix, HealRotate.OnCommReceived)
end

-- Handle message reception and
function HealRotate.OnCommReceived(prefix, data, channel, sender)

    if not UnitIsUnit('player', sender) then

        local success, message = AceSerializer:Deserialize(data)

        if (success) then
            if (message.type == HealRotate.constants.commsTypes.healshotDone) then
                HealRotate:receiveSyncHeal(prefix, message, channel, sender)
            elseif (message.type == HealRotate.constants.commsTypes.syncOrder) then
                HealRotate:receiveSyncOrder(prefix, message, channel, sender)
            elseif (message.type == HealRotate.constants.commsTypes.syncRequest) then
                HealRotate:receiveSyncRequest(prefix, message, channel, sender)
            end
        end
    end
end

-- Checks if a given version from a given sender should be applied
function HealRotate:isVersionEligible(version, sender)
    return version > HealRotate.syncVersion or (version == HealRotate.syncVersion and sender < HealRotate.syncLastSender)
end

-----------------------------------------------------------------------------------------------------------------------
-- Messaging functions
-----------------------------------------------------------------------------------------------------------------------

-- Proxy to send raid addon message
function HealRotate:sendRaidAddonMessage(message)
    HealRotate:sendAddonMessage(message, HealRotate.constants.commsChannel)
end

-- Proxy to send whisper addon message
function HealRotate:sendWhisperAddonMessage(message, name)
    HealRotate:sendAddonMessage(message, 'WHISPER', name)
end

-- Broadcast a given message to the commsChannel with the commsPrefix
function HealRotate:sendAddonMessage(message, channel, name)
    AceComm:SendCommMessage(
        HealRotate.constants.commsPrefix,
        AceSerializer:Serialize(message),
        channel,
        name
    )
end

-----------------------------------------------------------------------------------------------------------------------
-- OUTPUT
-----------------------------------------------------------------------------------------------------------------------

-- Broadcast a healshot event
function HealRotate:sendSyncHeal(healer, timestamp)
    local message = {
        ['type'] = HealRotate.constants.commsTypes.healshotDone,
        ['timestamp'] = timestamp,
        ['player'] = healer.name,
    }

    HealRotate:sendRaidAddonMessage(message)
end

-- Broadcast current rotation configuration
function HealRotate:sendSyncOrder(whisper, name)

    HealRotate.syncVersion = HealRotate.syncVersion + 1
    HealRotate.syncLastSender = UnitName("player")

    local message = {
        ['type'] = HealRotate.constants.commsTypes.syncOrder,
        ['version'] = HealRotate.syncVersion,
        ['rotation'] = HealRotate:getSimpleRotationTables()
    }

    if (whisper) then
        HealRotate:sendWhisperAddonMessage(message, name)
    else
        HealRotate:sendRaidAddonMessage(message, name)
    end
end

-- Broadcast a request for the current rotation configuration
function HealRotate:sendSyncOrderRequest()

    local message = {
        ['type'] = HealRotate.constants.commsTypes.syncRequest,
    }

    HealRotate:sendRaidAddonMessage(message)
end

-----------------------------------------------------------------------------------------------------------------------
-- INPUT
-----------------------------------------------------------------------------------------------------------------------

-- Healshot event received
function HealRotate:receiveSyncHeal(prefix, message, channel, sender)

    local healer = HealRotate:getHealer(message.player)
    local notDuplicate = healer.lastHealTime <  GetTime() - HealRotate.constants.duplicateHealshotDelayThreshold
end

-- Rotation configuration received
function HealRotate:receiveSyncOrder(prefix, message, channel, sender)

    HealRotate:updateRaidStatus()

    if (HealRotate:isVersionEligible(message.version, sender)) then
        HealRotate.syncVersion = (message.version)
        HealRotate.syncLastSender = sender

        HealRotate:printPrefixedMessage('Received new rotation configuration from ' .. sender)
        HealRotate:applyRotationConfiguration(message.rotation)
    end
end

-- Request to send current roration configuration received
function HealRotate:receiveSyncRequest(prefix, data, channel, sender)
    HealRotate:sendSyncOrder(true, sender)
end
