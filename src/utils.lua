local HealRotate = select(2, ...)

-- Check if a table contains the given element
function HealRotate:tableContains(table, element)

    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end

    return false
end

-- Checks if a healer is alive
function HealRotate:isHealerAlive(healer)
    return UnitIsFeignDeath(healer.name) or not UnitIsDeadOrGhost(healer.name)
end

-- Checks if a healer is offline
function HealRotate:isHealerOnline(healer)
    return UnitIsConnected(healer.name)
end

-- Checks if a healer is online and alive
function HealRotate:isHealerAliveAndOnline(healer)
    return HealRotate:isHealerOnline(healer) and HealRotate:isHealerAlive(healer)
end

-- Checks if a healer healshot is ready
function HealRotate:isHealerHealCooldownReady(healer)
    return healer.lastHealTime <= GetTime() - 60
end

-- Checks if a healer is elligible to heal next
function HealRotate:isEligibleForNextHeal(healer)

    local isCooldownShortEnough = healer.lastHealTime <= GetTime() - HealRotate.constants.minimumCooldownElapsedForEligibility

    return HealRotate:isHealerAliveAndOnline(healer) and isCooldownShortEnough
end

-- Checks if a healer is in a battleground
function HealRotate:isPlayerInBattleground()
    return UnitInBattleground('player') ~= nil
end

-- Checks if a healer is in a PvE raid
function HealRotate:isInPveRaid()
    return IsInRaid() and not HealRotate:isPlayerInBattleground()
end

function HealRotate:getPlayerNameFont()
    if (GetLocale() == "zhCN" or GetLocale() == "zhTW") then
        return "Fonts\\ARHei.ttf"
    end

    return "Fonts\\ARIALN.ttf"
end

function HealRotate:getIdFromGuid(guid)
    local type, _, _, _, _, mobId, _ = strsplit("-", guid or "")
    return type, tonumber(mobId)
end

-- Checks if the spell and the mob match a boss frenzy
function HealRotate:isBossFrenzy(spellName, guid)

    local bosses = HealRotate.constants.bosses
    local type, mobId = HealRotate:getIdFromGuid(guid)

    if (type == "Creature") then
        for bossId, frenzy in pairs(bosses) do
            if (bossId == mobId and spellName == GetSpellInfo(frenzy)) then
                return true
            end
        end
    end

    return false
end

-- Checks if the mob is a heal-able boss
function HealRotate:isHealableBoss(guid)

    local bosses = HealRotate.constants.bosses
    local type, mobId = HealRotate:getIdFromGuid(guid)

    if (type == "Creature") then
        for bossId, frenzy in pairs(bosses) do
            if (bossId == mobId) then
                return true
            end
        end
    end

    return false
end

-- Checks if the spell is a boss frenzy
function HealRotate:isFrenzy(spellName)

    local bosses = HealRotate.constants.bosses

    for bossId, frenzy in pairs(bosses) do
        if (spellName == GetSpellInfo(frenzy)) then
            return true
        end
    end

    return false
end
