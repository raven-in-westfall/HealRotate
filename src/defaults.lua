local L = HealRotate.L

function HealRotate:LoadDefaults()
	self.defaults = {
	    profile = {
	        enableAnnounces = true,
	        channelType = "YELL",
	        rotationReportChannelType = "RAID",
	        useMultilineRotationReport = false,
	        announceStartMessage = L["DEFAULT_START_ANNOUNCE_MESSAGE"],
	        announceStopMessage = L["DEFAULT_STOP_ANNOUNCE_MESSAGE"],
		lock = false,
		hideNotInRaid = false,
		enableNextToHealSound = true,
		enableHealNowSound = true,
		healNowSound = 'alarm1',
		doNotShowWindowOnRaidJoin = false,
		showWindowWhenTargetingBoss = false,
	    },
	}
end
