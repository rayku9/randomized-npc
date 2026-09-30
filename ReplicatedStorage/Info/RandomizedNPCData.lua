return {
	ExampleAreaNPCs = {
		PathData = {
			Start = {
				LinkTo = {"StartLeft", "StartRight"},
				IsStartNode = true,
			},
			StartLeft = {
				LinkTo = {"AreaLeft1","AreaCenterLeft1","AreaCenterRight1"},
				LinkFrom = {"Start"},
			},
			StartRight = {
				LinkTo = {"AreaLeft1","AreaCenterLeft1","AreaCenterRight1"},
				LinkFrom = {"Start"},
			},
			
			-- left
			AreaLeft1 = {
				LinkFrom = {"StartLeft","StartRight"},
				LinkTo = {"AreaLeft1Left","AreaLeft1Right"},
			},
			AreaLeft1Left = {
				LinkFrom = {"AreaLeft1"},
				LinkTo = {"AreaLeft2"},
			},
			AreaLeft1Right = {
				LinkFrom = {"AreaLeft1"},
				LinkTo = {"AreaLeft2"},
			},
			
			AreaLeft2 = {
				LinkFrom = {"AreaLeft1Right","AreaLeft2Right"},
				LinkTo = {"AreaLeft2Left","AreaLeft2Right"},
				ReverseLinkTo = {"AreaCenterLeft1","AreaCenterRight1"},
			},
			AreaLeft2Left = {
				LinkFrom = {"AreaLeft2"},
				LinkTo = {"AreaCenterLeft2"},
			},
			AreaLeft2Right = {
				LinkFrom = {"AreaLeft2"},
				LinkTo = {"AreaCenterLeft2"},
			},
			
			-- center
			AreaCenterLeft1 = {
				LinkFrom = {"StartLeft","StartRight"},
				ReverseLinkTo = {"AreaLeft2","AreaCenterRight1"},
				LinkTo = {"AreaCenterLeft2"},
			},
			AreaCenterLeft2 = {
				LinkFrom = {"AreaCenterLeft1","AreaLeft2Left","AreaLeft2Right"},
				LinkTo = {"AreaEndLeft1","AreaEndRight1"},
			},
			AreaCenterRight1 = {
				LinkFrom = {"StartLeft","StartRight"},
				ReverseLinkTo = {"AreaLeft2","AreaCenterRight1"},
				LinkTo = {"AreaCenterRight2"},
			},
			AreaCenterRight2 = {
				LinkFrom = {"AreaCenterRight2"},
				LinkTo = {"AreaEndRight1","AreaEndLeft1"},
				ReverseLinkTo = {"AreaRight1"},
			},
			
			-- right
			AreaRight1 = {
				LinkFrom = {"AreaCenterRight1"},
				LinkTo = {"AreaRight1Left","AreaRight1Right"},
				ReverseLinkTo = {"AreaCenterRight2"},
			},
			AreaRight1Right = {
				LinkFrom = {"AreaRight1"},
				LinkTo = {"AreaRight1Right2","AreaRight1Left2"},
			},
			AreaRight1Left = {
				LinkFrom = {"AreaRight1"},
				LinkTo = {"AreaRight1Right2","AreaRight1Left2"},
			},
			AreaRight1Right2 = {
				LinkFrom = {"AreaRight1Left","AreaRight1Right"},
				LinkTo = {"AreaRight1Right3"},
			},
			AreaRight1Left2 = {
				LinkFrom = {"AreaRight1Left","AreaRight1Right"},
				LinkTo = {"AreaRightLoop"},
			},
			AreaRight1Right3 = {
				LinkFrom = {"AreaRight1Right2"},
			},
			AreaRightLoop = {
				LinkFrom = {"AreaRight1Left2"},
			},
			
			-- end
			AreaEndRight1 = {
				LinkFrom = {"AreaCenterLeft2"},
				LinkTo = {"AreaEndLeft2","AreaEndRight2"},
				ReverseLinkTo = {"AreaEndLeft2"},
			},
			AreaEndLeft1 = {
				LinkFrom = {"AreaCenterLeft2"},
				LinkTo = {"AreaEndLeft2","AreaEndRight2"},
				ReverseLinkTo = {"AreaEndRight2"},
			},
			AreaEndRight2 = {
				LinkFrom = {"AreaEndRight1","AreaEndLeft1"},
			},
			AreaEndLeft2 = {
				LinkFrom = {"AreaEndRight1","AreaEndLeft1"},
			},
			
			-- reverse sides needed:
			-- all area end
			-- all area center
		},
		NPCSettings = {
			minLifetime = 90,
			maxLifetime = 300,
			minWait = 2,
			maxWait = 6,
			minDoorRange = 18,

			walkMin = 13,
			walkMax = 15,

			runMin = 19,
			runMax = 23,

			offsetMax = 1.5,
		},
	},
}