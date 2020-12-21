HealRotate = select(2, ...)

local L = HealRotate.L

local parent = ...
HealRotate.version = GetAddOnMetadata(parent, "Version")

-- Initialize addon - Shouldn't be call more than once
function HealRotate:init()

    self:LoadDefaults()

    self.db = LibStub:GetLibrary("AceDB-3.0"):New("HealRotateDb", self.defaults, true)
    self.db.RegisterCallback(self, "OnProfileChanged", "ProfilesChanged")
    self.db.RegisterCallback(self, "OnProfileCopied", "ProfilesChanged")
    self.db.RegisterCallback(self, "OnProfileReset", "ProfilesChanged")

    self:CreateConfig()

    HealRotate.healerTable = {}
    HealRotate.rotationTables = { rotation = {}, backup = {} }
    HealRotate.enableDrag = true
    HealRotate.fightingLothab = false

    HealRotate.raidInitialized = false
    HealRotate.testMode = false

    HealRotate:initGui()
    HealRotate:updateRaidStatus()
    HealRotate:applySettings()

    HealRotate:initComms()

    HealRotate:printMessage(L['LOADED_MESSAGE'])
end

-- Apply setting on profile change
function HealRotate:ProfilesChanged()
	self.db:RegisterDefaults(self.defaults)
    self:applySettings()
end

-- Apply settings
function HealRotate:applySettings()

    HealRotate.mainFrame:ClearAllPoints()

    local config = HealRotate.db.profile
    if config.point then
        HealRotate.mainFrame:SetPoint(config.point, UIParent, 'BOTTOMLEFT', config.x, config.y)
    else
        HealRotate.mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    HealRotate:updateDisplay()

    HealRotate.mainFrame:EnableMouse(not HealRotate.db.profile.lock)
    HealRotate.mainFrame:SetMovable(not HealRotate.db.profile.lock)
end

-- Print wrapper, just in case
function HealRotate:printMessage(msg)
    print(msg)
end

-- Print message with colored prefix
function HealRotate:printPrefixedMessage(msg)
    HealRotate:printMessage(HealRotate:colorText(HealRotate.constants.printPrefix) .. msg)
end

-- Send a heal annouce message to a given channel
function HealRotate:sendAnnounceMessage(message, targetName)
    if HealRotate.db.profile.enableAnnounces then
        HealRotate:sendMessage(
            message,
            targetName,
            HealRotate.db.profile.channelType,
            HealRotate.db.profile.targetChannel
        )
    end
end

-- Send a rotation broadcast message
function HealRotate:sendRotationSetupBroacastMessage(message)
    if HealRotate.db.profile.enableAnnounces then
        HealRotate:sendMessage(
            message,
            nil,
            HealRotate.db.profile.rotationReportChannelType,
            HealRotate.db.profile.setupBroadcastTargetChannel
        )
    end
end

-- Send a message to a given channel
function HealRotate:sendMessage(message, spellName, channelType, targetChannel)
    local channelNumber
    if channelType == "CHANNEL" then
        channelNumber = GetChannelName(targetChannel)
    end
    SendChatMessage(string.format(message, spellName), channelType, nil, channelNumber or targetChannel)
end

SLASH_HEALROTATE1 = "/heal"
SLASH_HEALROTATE2 = "/healrotate"
SlashCmdList["HEALROTATE"] = function(msg)
    local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

    if (cmd == 'toggle') then
        HealRotate:toggleDisplay()
    elseif (cmd == 'lock') then
        HealRotate:lock(true)
    elseif (cmd == 'unlock') then
        HealRotate:lock(false)
    elseif (cmd == 'backup') then
        HealRotate:whisperBackup()
    elseif (cmd == 'rotate') then -- @todo decide if this should be removed or not
        HealRotate:testRotation()
    elseif (cmd == 'test') then -- @todo: remove this
        HealRotate:test()
    elseif (cmd == 'report') then
        HealRotate:printRotationSetup()
    elseif (cmd == 'settings') then
        HealRotate:openSettings()
    elseif (cmd == 'start') then
        HealRotate:startYelling()
    elseif (cmd == 'stop') then
        HealRotate:stopYelling()
    else
        HealRotate:printHelp()
    end
end

function HealRotate:toggleDisplay()
    if (HealRotate.mainFrame:IsShown()) then
        HealRotate.mainFrame:Hide()
        HealRotate:printMessage(L['HEAL_WINDOW_HIDDEN'])
    else
        HealRotate.mainFrame:Show()
    end
end

-- @todo: remove this
function HealRotate:test()
    HealRotate:toggleTesting()
end

-- Open ace settings
function HealRotate:openSettings()
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")
    AceConfigDialog:Open("HealRotate")
end

-- Sends rotation setup to raid channel
function HealRotate:printRotationSetup()

    if (IsInRaid()) then
        HealRotate:sendRotationSetupBroacastMessage('--- ' .. HealRotate.constants.printPrefix .. L['BROADCAST_HEADER_TEXT'] .. ' ---', channel)

        if (HealRotate.db.profile.useMultilineRotationReport) then
            HealRotate:printMultilineRotation(HealRotate.rotationTables.rotation)
        else
            HealRotate:sendRotationSetupBroacastMessage(
                HealRotate:buildGroupMessage(L['BROADCAST_ROTATION_PREFIX'] .. ' : ', HealRotate.rotationTables.rotation)
            )
        end

        if (#HealRotate.rotationTables.backup > 0) then
            HealRotate:sendRotationSetupBroacastMessage(
                HealRotate:buildGroupMessage(L['BROADCAST_BACKUP_PREFIX'] .. ' : ', HealRotate.rotationTables.backup)
            )
        end
    end
end

-- Print the main rotation on multiple lines
function HealRotate:printMultilineRotation(rotationTable, channel)
    local position = 1;
    for key, hunt in pairs(rotationTable) do
        HealRotate:sendRotationSetupBroacastMessage(tostring(position) .. ' - ' .. hunt.name)
        position = position + 1;
    end
end

-- Serialize healers names of a given rotation group
function HealRotate:buildGroupMessage(prefix, rotationTable)
    local healers = {}

    for key, hunt in pairs(rotationTable) do
        table.insert(healers, hunt.name)
    end

    return prefix .. table.concat(healers, ', ')
end

-- Print command options to chat
function HealRotate:printHelp()
    local spacing = '   '
    HealRotate:printMessage(HealRotate:colorText('/healrotate') .. ' commands options :')
    HealRotate:printMessage(spacing .. HealRotate:colorText('toggle') .. ' : Show/Hide the main window')
    HealRotate:printMessage(spacing .. HealRotate:colorText('lock') .. ' : Lock the main window position')
    HealRotate:printMessage(spacing .. HealRotate:colorText('unlock') .. ' : Unlock the main window position')
    HealRotate:printMessage(spacing .. HealRotate:colorText('settings') .. ' : Open HealRotate settings')
    HealRotate:printMessage(spacing .. HealRotate:colorText('report') .. ' : Print the rotation setup to the configured channel')
    HealRotate:printMessage(spacing .. HealRotate:colorText('backup') .. ' : Whispers backup healers to immediately heal')
end

-- Adds color to given text
function HealRotate:colorText(text)
    return '|cffffbf00' .. text .. '|r'
end

-- Check if unit is promoted
function HealRotate:isHealerPromoted(name)

    local raidIndex = UnitInRaid(name)

    if (raidIndex) then
        local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(raidIndex)

        if (rank > 0) then
            return true
        end
    end

    return false
end

-- Toggle testing mode
function HealRotate:toggleTesting(disable)

    if (not disable and not HealRotate.testMode) then
        HealRotate:printPrefixedMessage(L['TESTING_ENABLED'])
        HealRotate.testMode = true

        -- Disable testing after 10 minutes
        C_Timer.After(600, function()
            HealRotate:toggleTesting(true)
        end)
    else
        HealRotate.testMode = false
        HealRotate:printPrefixedMessage(L['TESTING_DISABLED'])
    end
end
