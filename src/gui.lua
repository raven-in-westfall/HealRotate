local HealRotate = select(2, ...)

local L = HealRotate.L

-- Initialize GUI frames. Shouldn't be called more than once
function HealRotate:initGui()

    HealRotate:createMainFrame()
    HealRotate:createTitleFrame()
    HealRotate:createButtons()
    HealRotate:createRotationFrame()
    HealRotate:createBackupFrame()

    HealRotate:drawHealerFrames()
    HealRotate:createDropHintFrame()
    HealRotate:createRulerFrame()

    HealRotate:updateDisplay()
end

-- Show/Hide main window based on user settings
function HealRotate:updateDisplay()

    if (HealRotate:isInPveRaid()) then
        HealRotate.mainFrame:Show()
    else
        if (HealRotate.db.profile.hideNotInRaid) then
            HealRotate.mainFrame:Hide()
        end
    end
end

-- render / re-render healer frames to reflect table changes.
function HealRotate:drawHealerFrames()

    -- Different height to reduce spacing between both groups
    HealRotate.mainFrame:SetHeight(HealRotate.constants.rotationFramesBaseHeight + HealRotate.constants.titleBarHeight)
    HealRotate.mainFrame.rotationFrame:SetHeight(HealRotate.constants.rotationFramesBaseHeight)

    HealRotate:drawList(HealRotate.rotationTables.rotation, HealRotate.mainFrame.rotationFrame)

    if (#HealRotate.rotationTables.backup > 0) then
        HealRotate.mainFrame:SetHeight(HealRotate.mainFrame:GetHeight() + HealRotate.constants.rotationFramesBaseHeight)
    end

    HealRotate.mainFrame.backupFrame:SetHeight(HealRotate.constants.rotationFramesBaseHeight)
    HealRotate:drawList(HealRotate.rotationTables.backup, HealRotate.mainFrame.backupFrame)

end

-- Handle the render of a single healer frames group
function HealRotate:drawList(healerList, parentFrame)

    local index = 1
    local healerFrameHeight = HealRotate.constants.healerFrameHeight
    local healerFrameSpacing = HealRotate.constants.healerFrameSpacing

    if (#healerList < 1 and parentFrame == HealRotate.mainFrame.backupFrame) then
        parentFrame:Hide()
    else
        parentFrame:Show()
    end

    for key,healer in pairs(healerList) do

        -- Using existing frame if possible
        if (healer.frame == nil) then
            HealRotate:createHealerFrame(healer, parentFrame)
        else
            healer.frame:SetParent(parentFrame)
        end

        healer.frame:ClearAllPoints()
        healer.frame:SetPoint('LEFT', 10, 0)
        healer.frame:SetPoint('RIGHT', -10, 0)

        -- Setting top margin
        local marginTop = 10 + (index - 1) * (healerFrameHeight + healerFrameSpacing)
        healer.frame:SetPoint('TOP', parentFrame, 'TOP', 0, -marginTop)

        -- Handling parent windows height increase
        if (index == 1) then
            parentFrame:SetHeight(parentFrame:GetHeight() + healerFrameHeight)
            HealRotate.mainFrame:SetHeight(HealRotate.mainFrame:GetHeight() + healerFrameHeight)
        else
            parentFrame:SetHeight(parentFrame:GetHeight() + healerFrameHeight + healerFrameSpacing)
            HealRotate.mainFrame:SetHeight(HealRotate.mainFrame:GetHeight() + healerFrameHeight + healerFrameSpacing)
        end

        -- SetColor
        setHealerFrameColor(healer)

        healer.frame:Show()
        healer.frame.healer = healer

        index = index + 1
    end
end

-- Hide the healer frame
function HealRotate:hideHealer(healer)
    if (healer.frame ~= nil) then
        healer.frame:Hide()
    end
end

-- Refresh a single healer frame
function HealRotate:refreshHealerFrame(healer)
    setHealerFrameColor(healer)
end

-- Set the healer frame color regarding it's status
function setHealerFrameColor(healer)

    r, g, b, hex = GetClassColor(healer.class_name)
    local color = CreateColor(r,g,b)

    if (not HealRotate:isHealerOnline(healer)) then
        color = HealRotate.colors.gray
    elseif (not HealRotate:isHealerAlive(healer)) then
        color = HealRotate.colors.red
    elseif (healer.nextHeal) then
        color = HealRotate.colors.nextcaster
    end

    healer.frame.texture:SetVertexColor(color:GetRGB())
end

function HealRotate:hideHealerCooldown(healer)
    healer.frame.cooldownFrame:Hide()
end

function HealRotate:startHealerCooldown(healer)
    healer.frame.castFrame:Hide()
    healer.frame.cooldownFrame.statusBar:SetMinMaxValues(GetTime(), GetTime() + 60)
    healer.frame.cooldownFrame.statusBar.exirationTime = GetTime() + 60
    healer.frame.cooldownFrame:Show()
end

function HealRotate:startHealerCast(healer, spell_cast_duration)
    healer.frame.cooldownFrame:Hide()
    healer.frame.castFrame.statusBar:SetMinMaxValues(GetTime(), GetTime() + spell_cast_duration)
    healer.frame.castFrame.statusBar.exirationTime = GetTime() + spell_cast_duration 
    healer.frame.castFrame:Show()
end
    

-- Lock/Unlock the mainFrame position
function HealRotate:lock(lock)
    HealRotate.db.profile.lock = lock
    HealRotate:applySettings()

    if (lock) then
        HealRotate:printMessage(L['WINDOW_LOCKED'])
    else
        HealRotate:printMessage(L['WINDOW_UNLOCKED'])
    end
end
