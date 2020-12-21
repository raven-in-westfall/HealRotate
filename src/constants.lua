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
    ['Lesser Heal'] = 2.5,
    ['Heal'] = 2.5,
    ['Flash Heal'] = 1.5,
    ['Renew'] = 0,
    ['Prayer of Healing'] = 3,
    ['Holy Nova'] = 0,
    ['Desperate Prayer'] = 0,
    ['Power Word: Shield'] = 0,
    ['Greater Heal'] = 2.5,
    ['Healing Touch'] = 3.5,
    ['Regrowth'] = 2,
    ['Rejuvenation'] = 0,
    ['Swiftmend'] = 0,
    ['Holy Light'] = 2.5,
    ['Flash of Light'] = 1.5,
    ['Holy Shock'] = 0,
    ['Lay on Hands'] = 0,
}

HealRotate.debuffs = {
    ['29185'] = 1,
    ['2920'] = 1,
    ['2919'] = 1,
}
