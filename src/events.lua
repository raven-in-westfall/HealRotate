local HealRotate = select(2, ...)

local healShot = GetSpellInfo(19801)
local arcaneShot = GetSpellInfo(14287)

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

eventFrame:SetScript(
    "OnEvent",
    function(self, event, ...)
        if (event == "PLAYER_LOGIN") then
            HealRotate:init()
            self:UnregisterEvent("PLAYER_LOGIN")

            -- Delayed raid update because raid data is unreliable at PLAYER_LOGIN
            C_Timer.After(5, function()
                HealRotate:updateRaidStatus()
            end)
        else
            HealRotate[event](HealRotate, ...)
        end
    end
)

function HealRotate:COMBAT_LOG_EVENT_UNFILTERED()
    -- @todo : Improve this with register / unregister event to save ressources
    -- Avoid parsing combat log when not able to use it
--    if not HealRotate.raidInitialized then return end
    -- Avoid parsing combat log when outside instance if test mode isn't enabled
--    if not HealRotate.testMode and not IsInInstance() then return end

    local timestamp, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
    local spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, CombatLogGetCurrentEventInfo())

    -- @todo try to refactor a bit
    if HealRotate.healingSpells[spellName] == 1 then
        local healer = HealRotate:getHealer(nil, sourceGUID)
        if event == 'SPELL_CAST_START' then
            if  (sourceGUID == UnitGUID("player")) then
                HealRotate:sendAnnounceMessage(HealRotate.db.profile.announceStartMessage, spellName)
            end
        elseif (event == "SPELL_CAST_SUCCESS") then
            HealRotate:sendSyncHeal(healer, timestamp)
            HealRotate:rotate(healer, false)
            if  (sourceGUID == UnitGUID("player")) then
                HealRotate:sendAnnounceMessage(HealRotate.db.profile.announceStopMessage, spellName)
            elseif (UnitName("player") == nextHealer) then
                HealRotate:throwHealAlert()
            end
        end
    elseif event == "UNIT_DIED" and HealRotate:isHealableBoss(destGUID) then
        HealRotate:resetRotation()
    end
end

-- Raid group has changed
function HealRotate:GROUP_ROSTER_UPDATE()
    HealRotate:updateRaidStatus()
end

-- Player left combat
function HealRotate:PLAYER_REGEN_ENABLED()
    HealRotate:updateRaidStatus()
end

function HealRotate:PLAYER_TARGET_CHANGED()
    if (HealRotate.db.profile.showWindowWhenTargetingBoss) then
        if (HealRotate:isHealableBoss(UnitGUID("target")) and not UnitIsDead('target')) then
            HealRotate.mainFrame:Show()
        end
    end
end

-- Register single unit events for a given healer
function HealRotate:registerUnitEvents(healer)

    healer.frame:RegisterUnitEvent("PARTY_MEMBER_DISABLE", healer.name)
    healer.frame:RegisterUnitEvent("PARTY_MEMBER_ENABLE", healer.name)
    healer.frame:RegisterUnitEvent("UNIT_HEALTH", healer.name)
    healer.frame:RegisterUnitEvent("UNIT_CONNECTION", healer.name)
    healer.frame:RegisterUnitEvent("UNIT_FLAGS", healer.name)

    healer.frame:SetScript(
        "OnEvent",
        function(self, event, ...)
            HealRotate:updateHealerStatus(healer)
        end
    )

end

-- Unregister single unit events for a given healer
function HealRotate:unregisterUnitEvents(healer)
    healer.frame:UnregisterEvent("PARTY_MEMBER_DISABLE")
    healer.frame:UnregisterEvent("PARTY_MEMBER_ENABLE")
    healer.frame:UnregisterEvent("UNIT_HEALTH_FREQUENT")
    healer.frame:UnregisterEvent("UNIT_CONNECTION")
    healer.frame:UnregisterEvent("UNIT_FLAGS")
end
