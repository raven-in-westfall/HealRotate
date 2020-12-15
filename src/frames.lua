local HealRotate = select(2, ...)

-- Create main window
function HealRotate:createMainFrame()
    HealRotate.mainFrame = CreateFrame("Frame", 'mainFrame', UIParent)
    HealRotate.mainFrame:SetWidth(HealRotate.constants.mainFrameWidth)
    HealRotate.mainFrame:SetHeight(HealRotate.constants.rotationFramesBaseHeight * 2 + HealRotate.constants.titleBarHeight)
    HealRotate.mainFrame:Show()

    HealRotate.mainFrame:RegisterForDrag("LeftButton")
    HealRotate.mainFrame:SetClampedToScreen(true)
    HealRotate.mainFrame:SetScript("OnDragStart", function() HealRotate.mainFrame:StartMoving() end)

    HealRotate.mainFrame:SetScript(
        "OnDragStop",
        function()
            local config = HealRotate.db.profile
            HealRotate.mainFrame:StopMovingOrSizing()

            config.point = 'TOPLEFT'
            config.y = HealRotate.mainFrame:GetTop()
            config.x = HealRotate.mainFrame:GetLeft()
        end
    )
end

-- Create Title frame
function HealRotate:createTitleFrame()
    HealRotate.mainFrame.titleFrame = CreateFrame("Frame", 'rotationFrame', HealRotate.mainFrame)
    HealRotate.mainFrame.titleFrame:SetPoint('TOPLEFT')
    HealRotate.mainFrame.titleFrame:SetPoint('TOPRIGHT')
    HealRotate.mainFrame.titleFrame:SetHeight(HealRotate.constants.titleBarHeight)

    HealRotate.mainFrame.titleFrame.texture = HealRotate.mainFrame.titleFrame:CreateTexture(nil, "BACKGROUND")
    HealRotate.mainFrame.titleFrame.texture:SetColorTexture(HealRotate.colors.darkGreen:GetRGB())
    HealRotate.mainFrame.titleFrame.texture:SetAllPoints()

    HealRotate.mainFrame.titleFrame.text = HealRotate.mainFrame.titleFrame:CreateFontString(nil, "ARTWORK")
    HealRotate.mainFrame.titleFrame.text:SetFont("Fonts\\ARIALN.ttf", 12)
    HealRotate.mainFrame.titleFrame.text:SetShadowColor(0,0,0,0.5)
    HealRotate.mainFrame.titleFrame.text:SetShadowOffset(1,-1)
    HealRotate.mainFrame.titleFrame.text:SetPoint("LEFT",5,0)
    HealRotate.mainFrame.titleFrame.text:SetText('HealRotate')
    HealRotate.mainFrame.titleFrame.text:SetTextColor(1,1,1,1)
end

-- Create title bar buttons
function HealRotate:createButtons()

    local buttons = {
        {
            ['texture'] = 'Interface/Buttons/UI-Panel-MinimizeButton-Up',
            ['callback'] = HealRotate.toggleDisplay,
            ['textCoord'] = {0.18, 0.8, 0.2, 0.8}
        },
        {
            ['texture'] = 'Interface/GossipFrame/BinderGossipIcon',
            ['callback'] = HealRotate.openSettings
        },
        {
            ['texture'] = 'Interface/Buttons/UI-RefreshButton',
            ['callback'] = function()
                    HealRotate:updateRaidStatus()
                    HealRotate:resetRotation()
                    HealRotate:sendSyncOrderRequest()
                end
        },
        {
            ['texture'] = 'Interface/Buttons/UI-GuildButton-MOTD-Up',
            ['callback'] = HealRotate.printRotationSetup
        },
    }

    local position = 5

    for key, button in pairs(buttons) do
        HealRotate:createButton(position, button.texture, button.callback, button.textCoord)
        position = position + 13
    end
end

-- Create a single button in the title bar
function HealRotate:createButton(position, texture, callback, textCoord)

    local button = CreateFrame("Button", nil, HealRotate.mainFrame.titleFrame)
    button:SetPoint('RIGHT', -position, 0)
    button:SetWidth(10)
    button:SetHeight(10)

    local normal = button:CreateTexture()
    normal:SetTexture(texture)
    normal:SetAllPoints()
    button:SetNormalTexture(normal)

    local highlight = button:CreateTexture()
    highlight:SetTexture(texture)
    highlight:SetAllPoints()
    button:SetHighlightTexture(highlight)

    if (textCoord) then
        normal:SetTexCoord(unpack(textCoord))
        highlight:SetTexCoord(unpack(textCoord))
    end

    button:SetScript("OnClick", callback)
end

-- Create rotation frame
function HealRotate:createRotationFrame()
    HealRotate.mainFrame.rotationFrame = CreateFrame("Frame", 'rotationFrame', HealRotate.mainFrame)
    HealRotate.mainFrame.rotationFrame:SetPoint('LEFT')
    HealRotate.mainFrame.rotationFrame:SetPoint('RIGHT')
    HealRotate.mainFrame.rotationFrame:SetPoint('TOP', 0, -HealRotate.constants.titleBarHeight)
    HealRotate.mainFrame.rotationFrame:SetHeight(HealRotate.constants.rotationFramesBaseHeight)

    HealRotate.mainFrame.rotationFrame.texture = HealRotate.mainFrame.rotationFrame:CreateTexture(nil, "BACKGROUND")
    HealRotate.mainFrame.rotationFrame.texture:SetColorTexture(0,0,0,0.5)
    HealRotate.mainFrame.rotationFrame.texture:SetAllPoints()
end

-- Create backup frame
function HealRotate:createBackupFrame()
    -- Backup frame
    HealRotate.mainFrame.backupFrame = CreateFrame("Frame", 'backupFrame', HealRotate.mainFrame)
    HealRotate.mainFrame.backupFrame:SetPoint('TOPLEFT', HealRotate.mainFrame.rotationFrame, 'BOTTOMLEFT', 0, 0)
    HealRotate.mainFrame.backupFrame:SetPoint('TOPRIGHT', HealRotate.mainFrame.rotationFrame, 'BOTTOMRIGHT', 0, 0)
    HealRotate.mainFrame.backupFrame:SetHeight(HealRotate.constants.rotationFramesBaseHeight)

    -- Set Texture
    HealRotate.mainFrame.backupFrame.texture = HealRotate.mainFrame.backupFrame:CreateTexture(nil, "BACKGROUND")
    HealRotate.mainFrame.backupFrame.texture:SetColorTexture(0,0,0,0.5)
    HealRotate.mainFrame.backupFrame.texture:SetAllPoints()

    -- Visual separator
    HealRotate.mainFrame.backupFrame.texture = HealRotate.mainFrame.backupFrame:CreateTexture(nil, "BACKGROUND")
    HealRotate.mainFrame.backupFrame.texture:SetColorTexture(0.8,0.8,0.8,0.8)
    HealRotate.mainFrame.backupFrame.texture:SetHeight(1)
    HealRotate.mainFrame.backupFrame.texture:SetWidth(60)
    HealRotate.mainFrame.backupFrame.texture:SetPoint('TOP')
end

-- Create single healer frame
function HealRotate:createHealerFrame(healer, parentFrame)
    healer.frame = CreateFrame("Frame", nil, parentFrame)
    healer.frame:SetHeight(HealRotate.constants.healerFrameHeight)

    -- Set Texture
    healer.frame.texture = healer.frame:CreateTexture(nil, "ARTWORK")
    healer.frame.texture:SetTexture("Interface\\AddOns\\HealRotate\\textures\\steel.tga")
    healer.frame.texture:SetAllPoints()

    -- Set Text
    healer.frame.text = healer.frame:CreateFontString(nil, "ARTWORK")
    healer.frame.text:SetFont(HealRotate:getPlayerNameFont(), 12)
    healer.frame.text:SetPoint("LEFT",5,0)
    healer.frame.text:SetText(healer.name)

    HealRotate:createCooldownFrame(healer)
    HealRotate:createCastFrame(healer)
    HealRotate:configureHealerFrameDrag(healer)

    if (HealRotate.enableDrag) then
        HealRotate:enableHealerFrameDragging(healer, true)
    end
end

-- Create the cooldown frame
function HealRotate:createCooldownFrame(healer)

    -- Frame
    healer.frame.cooldownFrame = CreateFrame("Frame", nil, healer.frame)
    healer.frame.cooldownFrame:SetPoint('LEFT', 5, 0)
    healer.frame.cooldownFrame:SetPoint('RIGHT', -5, 0)
    healer.frame.cooldownFrame:SetPoint('TOP', 0, -17)
    healer.frame.cooldownFrame:SetHeight(3)

    -- background
    healer.frame.cooldownFrame.background = healer.frame.cooldownFrame:CreateTexture(nil, "ARTWORK")
    healer.frame.cooldownFrame.background:SetColorTexture(0,0,0,1)
    healer.frame.cooldownFrame.background:SetAllPoints()

    local statusBar = CreateFrame("StatusBar", nil, healer.frame.cooldownFrame)
    statusBar:SetAllPoints()
    statusBar:SetMinMaxValues(0,1)
    statusBar:SetStatusBarTexture("Interface\\AddOns\\HealRotate\\textures\\steel.tga")
    statusBar:GetStatusBarTexture():SetHorizTile(false)
    statusBar:GetStatusBarTexture():SetVertTile(false)
    statusBar:SetStatusBarColor(1, 0, 0)
    healer.frame.cooldownFrame.statusBar = statusBar

    healer.frame.cooldownFrame:SetScript(
        "OnUpdate",
        function(self, elapsed)
            self.statusBar:SetValue(GetTime())

            if (self.statusBar.exirationTime < GetTime()) then
                self:Hide()
            end
        end
    )

    healer.frame.cooldownFrame:Hide()
end

-- Create the cast frame
function HealRotate:createCastFrame(healer)

    -- Frame
    healer.frame.castFrame = CreateFrame("Frame", nil, healer.frame)
    healer.frame.castFrame:SetPoint('LEFT', 5, 0)
    healer.frame.castFrame:SetPoint('RIGHT', -5, 0)
    healer.frame.castFrame:SetPoint('TOP', 0, -17)
    healer.frame.castFrame:SetHeight(3)

    -- background
    healer.frame.castFrame.background = healer.frame.castFrame:CreateTexture(nil, "ARTWORK")
    healer.frame.castFrame.background:SetColorTexture(0,0,0,1)
    healer.frame.castFrame.background:SetAllPoints()

    local statusBar = CreateFrame("StatusBar", nil, healer.frame.castFrame)
    statusBar:SetAllPoints()
    statusBar:SetMinMaxValues(0,1)
    statusBar:SetStatusBarTexture("Interface\\AddOns\\HealRotate\\textures\\steel.tga")
    statusBar:GetStatusBarTexture():SetHorizTile(false)
    statusBar:GetStatusBarTexture():SetVertTile(false)
    statusBar:SetStatusBarColor(0, 1, 0)
    healer.frame.castFrame.statusBar = statusBar

    healer.frame.castFrame:SetScript(
        "OnUpdate",
        function(self, elapsed)
            self.statusBar:SetValue(GetTime())

            if (self.statusBar.exirationTime < GetTime()) then
                self:Hide()
            end
        end
    )

    healer.frame.castFrame:Hide()
end
