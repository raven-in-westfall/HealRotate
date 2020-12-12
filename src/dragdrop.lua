local HealRotate = select(2, ...)

-- Enable drag & drop for all healer frames
function HealRotate:enableListSorting()
    for key,healer in pairs(HealRotate.healerTable) do
        HealRotate:enableHealerFrameDragging(healer, true)
    end
end

-- Enable or disable drag & drop for the healer frame
function HealRotate:enableHealerFrameDragging(healer, movable)
    healer.frame:EnableMouse(movable)
    healer.frame:SetMovable(movable)
end

-- configure healer frame drag behavior
function HealRotate:configureHealerFrameDrag(healer)

    healer.frame:RegisterForDrag("LeftButton")
    healer.frame:SetClampedToScreen(true)

    healer.frame:SetScript(
        "OnDragStart",
        function()
            healer.frame:StartMoving()
            healer.frame:SetFrameStrata("HIGH")
            HealRotate.mainFrame.rulerFrame:SetPoint('BOTTOMRIGHT', healer.frame, 'TOPLEFT', 0, 0)
            HealRotate.mainFrame.dropHintFrame:Show()
            HealRotate.mainFrame.backupFrame:Show()
        end
    )

    healer.frame:SetScript(
        "OnDragStop",
        function()
            healer.frame:StopMovingOrSizing()
            healer.frame:SetFrameStrata(HealRotate.mainFrame:GetFrameStrata())
            HealRotate.mainFrame.dropHintFrame:Hide()

            if (#HealRotate.rotationTables.backup < 1) then
                HealRotate.mainFrame.backupFrame:Hide()
            end

            local group, position = HealRotate:getDropPosition(HealRotate.mainFrame.rulerFrame:GetHeight())
            HealRotate:handleDrop(healer, group, position)
            HealRotate:sendSyncOrder(false)
        end
    )
end

-- create and initialize the drop hint frame
function HealRotate:createDropHintFrame()

    local hintFrame = CreateFrame("Frame", nil, HealRotate.mainFrame.rotationFrame)

    hintFrame:SetPoint('TOP', HealRotate.mainFrame.rotationFrame, 'TOP', 0, 0)
    hintFrame:SetHeight(HealRotate.constants.healerFrameHeight)
    hintFrame:SetWidth(HealRotate.constants.mainFrameWidth - 10)

    hintFrame.texture = hintFrame:CreateTexture(nil, "BACKGROUND")
    hintFrame.texture:SetColorTexture(HealRotate.colors.white:GetRGB())
    hintFrame.texture:SetAlpha(0.7)
    hintFrame.texture:SetPoint('LEFT')
    hintFrame.texture:SetPoint('RIGHT')
    hintFrame.texture:SetHeight(2)

    hintFrame:Hide()

    HealRotate.mainFrame.dropHintFrame = hintFrame
end

-- Create and initialize the 'ruler' frame.
-- It's height will be used as a ruler for position calculation
function HealRotate:createRulerFrame()

    local rulerFrame = CreateFrame("Frame", nil, HealRotate.mainFrame.rotationFrame)
    HealRotate.mainFrame.rulerFrame = rulerFrame

    rulerFrame:SetPoint('TOPLEFT', HealRotate.mainFrame.rotationFrame, 'TOPLEFT', 0, 0)

    rulerFrame:SetScript(
        "OnSizeChanged",
        function (self, width, height)
            HealRotate:setDropHintPosition(self, width, height)
        end
    )

end

-- Set the drop hint frame position to match dragged frame position
function HealRotate:setDropHintPosition(self, width, height)

    local healerFrameHeight = HealRotate.constants.healerFrameHeight
    local healerFrameSpacing = HealRotate.constants.healerFrameSpacing
    local hintPosition = 0

    local group, position = HealRotate:getDropPosition(height)

    if (group == 'ROTATION') then
        if (position == 0) then
            hintPosition = -2
        else
            hintPosition = (position) * (healerFrameHeight + healerFrameSpacing) - healerFrameSpacing / 2;
        end
    else
        hintPosition = HealRotate.mainFrame.rotationFrame:GetHeight()

        if (position == 0) then
            hintPosition = hintPosition - 2
        else
            hintPosition = hintPosition + (position) * (healerFrameHeight + healerFrameSpacing) - healerFrameSpacing / 2;
        end
    end

    HealRotate.mainFrame.dropHintFrame:SetPoint('TOP', 0 , -hintPosition)
end

-- Compute drop group and position from ruler height
function HealRotate:getDropPosition(rulerHeight)

    local group = 'ROTATION'
    local position = 0

    local healerFrameHeight = HealRotate.constants.healerFrameHeight
    local healerFrameSpacing = HealRotate.constants.healerFrameSpacing

    -- Dragged frame is above rotation frames
    if (HealRotate.mainFrame.rulerFrame:GetTop() > HealRotate.mainFrame.rotationFrame:GetTop()) then
        rulerHeight = 0
    end

    position = floor(rulerHeight / (healerFrameHeight + healerFrameSpacing))

    -- Dragged frame is bellow rotation frame
    if (rulerHeight > HealRotate.mainFrame.rotationFrame:GetHeight()) then

        group = 'BACKUP'

        -- Removing rotation frame size from calculation, using it's height as base hintPosition offset
        rulerHeight = rulerHeight - HealRotate.mainFrame.rotationFrame:GetHeight()

        if (rulerHeight > HealRotate.mainFrame.backupFrame:GetHeight()) then
            -- Dragged frame is bellow backup frame
            position = #HealRotate.rotationTables.backup
        else
            position = floor(rulerHeight / (healerFrameHeight + healerFrameSpacing))
        end
    end

    return group, position
end

-- Compute the table final position from the drop position
function HealRotate:handleDrop(healer, group, position)

    local originTable = HealRotate:getHealerRotationTable(healer)
    local originIndex = HealRotate:getHealerIndex(healer, originTable)

    local destinationTable = HealRotate.rotationTables.rotation
    local finalPosition = 1

    if (group == "BACKUP") then
        destinationTable = HealRotate.rotationTables.backup
    end

    if (destinationTable == originTable) then

        if (position == originIndex or position == originIndex - 1 ) then
            finalPosition = originIndex
        else
            if (position > originIndex) then
                finalPosition = position
            else
                finalPosition = position + 1
            end
        end

    else
        finalPosition = position + 1
    end

    HealRotate:moveHealer(healer, group, finalPosition)
end
