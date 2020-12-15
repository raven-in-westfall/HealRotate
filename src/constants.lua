local HealRotate = select(2, ...)

HealRotate.colors = {
    ['green'] = CreateColor(0.67, 0.83, 0.45),
    ['darkGreen'] = CreateColor(0.1, 0.4, 0.1),
    ['darkRed'] = CreateColor(0.4, 0.1, 0.1),
    ['blue'] = CreateColor(0.3, 0.3, 0.7),
    ['red'] = CreateColor(0.7, 0.3, 0.3),
    ['gray'] = CreateColor(0.3, 0.3, 0.3),
    ['purple'] = CreateColor(0.71,0.45,0.75),
    ['white'] = CreateColor(1,1,1),
}

HealRotate.constants = {
    ['healerFrameHeight'] = 22,
    ['healerFrameSpacing'] = 4,
    ['titleBarHeight'] = 18,
    ['mainFrameWidth'] = 130,
    ['rotationFramesBaseHeight'] = 20,

    ['commsPrefix'] = 'healrotate',
    ['commsChannel'] = 'RAID',

    ['commsTypes'] = {
        ['healshotDone'] = 'healshot-done',
        ['syncOrder'] = 'sync-order',
        ['syncRequest'] = 'sync-request',
    },

    ['printPrefix'] = 'HealRotate - ',
    ['duplicateHealshotDelayThreshold'] = 10,

    ['minimumCooldownElapsedForEligibility'] = 60,

    ['sounds'] = {
        ['nextToHeal'] = 'Interface\\AddOns\\HealRotate\\sounds\\ding.ogg',
        ['alarms'] = {
            ['alarm1'] = 'Interface\\AddOns\\HealRotate\\sounds\\alarm.ogg',
            ['alarm2'] = 'Interface\\AddOns\\HealRotate\\sounds\\alarm2.ogg',
            ['alarm3'] = 'Interface\\AddOns\\HealRotate\\sounds\\alarm3.ogg',
            ['alarm4'] = 'Interface\\AddOns\\HealRotate\\sounds\\alarm4.ogg',
            ['flagtaken'] = 'Sound\\Spells\\PVPFlagTaken.ogg',
        }
    },

    ['healNowSounds'] = {
        ['alarm1'] = 'Loud BUZZ',
        ['alarm2'] = 'Gentle beeplip',
        ['alarm3'] = 'Gentle dong',
        ['alarm4'] = 'Light bipbip',
        ['flagtaken'] = 'Flag Taken (DBM)',
    },

    ['bosses'] = {
        [16011] = 19451, -- lothab is first id, second ID we peob dont need
    }
}

HealRotate.healingSpells = {
    ['Lesser Heal'] = 1,
    ['Heal'] = 1,
    ['Flash Heal'] = 1,
    ['Renew'] = 1,
    ['Prayer of Healing'] = 1,
    ['Holy Nova'] = 1,
    ['Desperate Prayer'] = 1,
    ['Power Word: Shield'] = 1,
    ['Greater Heal'] = 1,
    ['Healing Touch'] = 1,
    ['Regrowth'] = 1,
    ['Rejuvenation'] = 1,
    ['Swiftmend'] = 1,
    ['Holy Light'] = 1,
    ['Flash of Light'] = 1,
    ['Holy Shock'] = 1
}

HealRotate.debuffs = {
    ['29185'] = 1,
    ['2920'] = 1,
    ['2919'] = 1,
}
