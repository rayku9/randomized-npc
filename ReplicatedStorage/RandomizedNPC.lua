local RandomizedNPC = {}
RandomizedNPC.__index = RandomizedNPC

local TS = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")

local mods = RS.Modules
-- utilizes third-party modules 
	-- Promise : https://github.com/evaera/roblox-lua-promise
	-- Janitor : https://github.com/howmanysmall/Janitor
local Promise = require(mods.Promise)
local Janitor = require(mods.Janitor)
local fMod = require(mods.Functions)

local function setCollisionGroupRecursive(object)
	if object:IsA("BasePart") then
		object.CollisionGroup = "RandomizedNPC"
	end
	for _, child in object:GetChildren() do
		setCollisionGroupRecursive(child)
	end
end

local allNPCs = {}
function RandomizedNPC:getAllNPCS()
	return allNPCs
end

function RandomizedNPC.new(character, pathFolder, pathData, settings,spawnSettings)
	if not character or not character:FindFirstChildOfClass("Humanoid") then return end
	if not pathFolder then return end
	if not pathData then return end
	
	local self = setmetatable({}, RandomizedNPC)
	
	if not settings then 
		settings = {
			minLifetime = 15,
			maxLifetime = 30,
			minWait = 5,
			maxWait = 15,
			minDoorRange = 18,

			walkMin = 9,
			walkMax = 11,

			runMin = 14,
			runMax = 17,

			offsetMax = .75,
		}
	end

	self.character = character
	self.hum = character:FindFirstChildOfClass("Humanoid")
	self.rootPart = character:FindFirstChild("HumanoidRootPart")
	self.pathFolder = pathFolder:FindFirstChild("Branches")
	self.pathData = pathData
	self.destroyed = false
	self.originalPathFolder = pathFolder
	self.ID = fMod:getId()
	
	local newAnimate = RS.RandomizedNPC:FindFirstChild("Animate"):Clone()
	newAnimate.Parent = character
	newAnimate.Enabled = true

	if not allNPCs[pathFolder] then
		allNPCs[pathFolder] = {}
	end
	table.insert(allNPCs[pathFolder],self)

	-- walkSpeed
	local run = (math.random(0,1)==1)
	local wSpeed = 16
	if run then
		wSpeed = math.random(settings.runMin,settings.runMax)
	else
		wSpeed = math.random(settings.walkMin,settings.walkMax)
	end
	self.hum.WalkSpeed = wSpeed
	self.offsetMax = settings.offsetMax

	setCollisionGroupRecursive(character)

	self.janitor = Janitor.new()

	self.invisData = {}
	self.maxLifetime = math.random(settings.minLifetime,settings.maxLifetime)
	self.currentTime = os.clock()
	self.reverseNext = false
	self.minWait = settings.minWait
	self.maxWait = settings.maxWait
	self.minDoorRange = settings.minDoorRange

	self.doorPoints = {}
	local doors = pathFolder:FindFirstChild("Doors")
	if doors then
		for _, obj in doors:GetChildren() do
			if obj:IsA("Attachment") then
				table.insert(self.doorPoints, obj.WorldPosition)
			end
		end
	end

	self:makeInvisible()
	
	local spawnAtt = self:findSpawnPoint()
	local startName = spawnAtt:GetAttribute("LinkedStart") or "Start"
	self.startName = startName
	if not pathData[startName] then warn("No starting path found",pathData) return end
	self.currentPath = startName
	

	self:spawnInEffect(true, 2.5)
	
	if spawnSettings then
		self.currentPath = spawnSettings.currentPath
		self.nextPath = spawnSettings.nextPath
		self.nextPathReverse = spawnSettings.isReverse
		
		-- spawn pt
		local branch = self.pathFolder:FindFirstChild(self.currentPath)
		if spawnSettings.spawnPoint == "start" then
			self.character:PivotTo(CFrame.new(branch:FindFirstChild("1").WorldPosition+Vector3.new(0,1,0)))
		else
			local endAtt = branch:FindFirstChild(#branch:GetChildren())
			self.character:PivotTo(CFrame.new(branch:FindFirstChild(tostring(endAtt)).WorldPosition+Vector3.new(0,1,0)))
		end
		
		-- walk
		self:walkPath(self.pathFolder:FindFirstChild(self.nextPath),self.nextPathReverse,self.offsetMax,true)
		self.currentPath = self.nextPath
		
		self.nextPath = nil
		self.nextPathReverse = nil
	end
	
	self:startWalking()

	-- create random offset
	if math.random(1,2) == 2 then
		local att1 = self.rootPart:FindFirstChild("RootAttachment")
		local att2 = self.rootPart:FindFirstChild("RootRigAttachment")

		local randOffset = math.random(-4,4)/10
		if att1 then att1.Position += Vector3.new(randOffset,0,0) end
		if att2 then att2.Position += Vector3.new(randOffset,0,0) end
	end

	-- setup connections
	self.janitor:Add(character.Destroying:Once(function()
		self:Destroy()
	end))

	return self
end

function RandomizedNPC:Destroy()
	if self.destroyed then return end
	self.destroyed = true
	
	local npcData = allNPCs[self.originalPathFolder]
	if npcData then
		for i, npc in npcData do
			if npc.ID == self.ID then
				table.remove(npcData, i)
				break
			end
		end
	end
	
	if self.character then self.character:Destroy() end
	self.janitor:Destroy()
end

function RandomizedNPC:makeInvisible()
	for _, obj in self.character:GetDescendants() do
		if obj:IsA("BasePart") or obj:IsA("Decal") then
			self.invisData[obj] = obj.Transparency
			obj.Transparency = 1
		end
	end
end

function RandomizedNPC:findSpawnPoint()
	local spawnPts = self.pathFolder.Parent:FindFirstChild("SpawnPoints")
	if not spawnPts then return end

	local children = spawnPts:GetChildren()
	if #children == 0 then return end

	local pos = children[math.random(1, #children)]
	self.character:PivotTo(CFrame.new(pos.WorldPosition + Vector3.new(0, 1, 0)))
	
	return pos
end

function RandomizedNPC:spawnInEffect(spawnIn, t)
	self.janitor:AddPromise(Promise.try(function()
		local newH = Instance.new("Highlight")
		newH.OutlineColor = Color3.fromRGB(50, 50, 50)
		newH.FillColor = newH.OutlineColor
		newH.OutlineTransparency = if spawnIn then 0 else 1
		newH.FillTransparency = newH.OutlineTransparency
		newH.DepthMode = Enum.HighlightDepthMode.Occluded
		newH.Parent = self.character

		self.janitor:Add(newH)

		if not spawnIn then
			local newT = if t > .5 then 1 else .3
			TS:Create(newH, TweenInfo.new(newT), {OutlineTransparency = 0, FillTransparency = 0}):Play()
			task.wait(newT)
			if self.destroyed then return end
		end

		local tInfo = TweenInfo.new(t or 1,Enum.EasingStyle.Linear)
		for _, obj in self.character:GetDescendants() do
			if obj.Name == "HumanoidRootPart" then continue end
			if obj:IsA("BasePart") or obj:IsA("Decal") then
				local mult = if obj.Parent:IsA("Accessory") then .7 else 1
				TS:Create(obj, if spawnIn and mult ~= 1 then TweenInfo.new(mult,Enum.EasingStyle.Linear) else tInfo, {Transparency = if spawnIn then self.invisData[obj] else 1}):Play()
			end
		end

		TS:Create(newH, tInfo, {OutlineTransparency = 1, FillTransparency = 1}):Play()

		task.wait(t)
		if newH and newH.Parent then
			newH:Destroy()
		end
	end))
end

function RandomizedNPC:moveToPoint(pos)
	if self.currentMovePromise then
		self.currentMovePromise:cancel()
	end

	self.hum:MoveTo(pos)
	local dist = (self.rootPart.Position * Vector3.new(1, 0, 1) - pos * Vector3.new(1, 0, 1)).Magnitude
	local predictedTime = (dist / self.hum.WalkSpeed) + 1
	local time = 0

	self.currentMovePromise = Promise.try(function()
		while task.wait(.1) do
			if self.destroyed then break end
			dist = (self.rootPart.Position * Vector3.new(1, 0, 1) - pos * Vector3.new(1, 0, 1)).Magnitude
			time += .1
			if dist < 1 or time > predictedTime then
				break
			end
		end
	end)

	self.janitor:AddPromise(self.currentMovePromise)
	self.currentMovePromise:await()
end

function RandomizedNPC:walkPath(pathFolder, reverse, offsetMax, canStop)
	local attachments = {}
	for _, child in ipairs(pathFolder:GetChildren()) do
		if child:IsA("Attachment") then
			local num = tonumber(child.Name)
			if num then
				attachments[num] = child
			end
		end
	end

	local startIdx, endIdx, step
	if reverse then
		startIdx = #attachments
		endIdx = 1
		step = -1
	else
		startIdx = 1
		endIdx = #attachments
		step = 1
	end

	local shouldStop = canStop and math.random(1,4) == 1
	local stopIndex = nil
	if shouldStop and #attachments >= 3 then
		stopIndex = math.random(2, #attachments - 1)
	elseif shouldStop and #attachments >= 2 then
		stopIndex = #attachments
	end

	for i = startIdx, endIdx, step do
		local attachment = attachments[i]
		if attachment then
			local targetPos = attachment.WorldPosition
			if offsetMax then
				-- Extra spread on the last point of this leg so NPCs land in
				-- roughly the area rather than exactly on the same spot every
				-- time.
				local isFinalPoint = (i == endIdx)
				local pointOffsetMax = if isFinalPoint then offsetMax * 2.2 else offsetMax
				local offsetX = math.random(-pointOffsetMax * 10, pointOffsetMax * 10) / 10
				local offsetZ = math.random(-pointOffsetMax * 10, pointOffsetMax * 10) / 10
				targetPos = targetPos + Vector3.new(offsetX, 0, offsetZ)
			end
			self:moveToPoint(targetPos)

			if stopIndex and i == stopIndex then
				return true
			end
		end
	end

	return false
end

function RandomizedNPC:findPathTo(currentPath, pathName, atStart)
	if currentPath == pathName then
		if atStart then
			return {}
		else
			return {{path = pathName, reverse = true}}
		end
	end

	local route = {}
	local current = currentPath
	local visited = {[current] = true}

	if not atStart then
		table.insert(route, {path = current, reverse = true})
	end

	while current ~= pathName do
		local info = self.pathData[current]
		if info and info.LinkFrom and #info.LinkFrom > 0 then
			current = info.LinkFrom[1]
			if visited[current] then
				return nil
			end
			visited[current] = true
			table.insert(route, {path = current, reverse = true})
		else
			return nil
		end
	end

	return route
end

function RandomizedNPC:startWalking()
	self.janitor:AddPromise(Promise.try(function()
		local wanderCooldown = 0
		local reverseMode = false

		local walkingOutDoor
		while true do
			if self.destroyed then break end

			local canWander = os.clock() >= wanderCooldown
			local stoppedEarly = self:walkPath(self.pathFolder:FindFirstChild(self.currentPath), self.reverseNext, self.offsetMax, true)

			local justReversed = self.reverseNext
			self.reverseNext = false

			local thisData = self.pathData[self.currentPath]
			local prev = self.currentPath

			local to = thisData.LinkTo or {}
			local from = thisData.LinkFrom or {}

			local walkBack = math.random(1, 5)
			if prev == self.startName then
				walkBack = 5 -- no reversing on start
			end

			local delays = math.random(1, 3)
			if justReversed == true then delays = 3 end
			if delays == 3 then task.wait(math.random(self.minWait * 10, self.maxWait * 10) / 10) end

			if os.clock() - self.currentTime >= self.maxLifetime then
				local currentPos = self.rootPart.Position

				local enterDoor = (math.random(1, 3) == 3)
				if enterDoor then
					local closestDoorDist = math.huge
					local closestDoor = nil

					for _, pos in self.doorPoints do
						local dist = (currentPos * Vector3.new(1, 0, 1) - pos * Vector3.new(1, 0, 1)).Magnitude
						if dist < closestDoorDist then
							closestDoorDist = dist
							closestDoor = pos
						end
					end

					if closestDoor and closestDoorDist < self.minDoorRange then
						local direction = (closestDoor - currentPos).Unit
						local startPos = currentPos - direction * 1
						local endPos = closestDoor + direction * 2.5
						local distance = (endPos - startPos).Magnitude

						local raycastParams = RaycastParams.new()
						raycastParams.FilterType = Enum.RaycastFilterType.Exclude
						raycastParams.FilterDescendantsInstances = {self.character,CS:GetTagged("InvisibleBox")}

						local result = workspace:Raycast(startPos, direction * distance, raycastParams)
						if not result then
							self:moveToPoint(closestDoor)
							walkingOutDoor = true
							break
						end
					end
				end

				local path = self:findPathTo(prev, self.startName, justReversed)
				if not path then break end

				for _, pathNode in path do
					local name, reverse = pathNode.path, pathNode.reverse
					self:walkPath(self.pathFolder:FindFirstChild(name), reverse, self.offsetMax, false)
				end

				break
			end

			if justReversed then
				self:walkPath(self.pathFolder:FindFirstChild(prev), nil, self.offsetMax, false)
			end

			if stoppedEarly and canWander then
				-- A short chain of small wander hops, each one starting from
				-- where the last left off, with a brief pause in between,
				-- instead of one single hop out and a long stand-still.
				local hopCount = math.random(2, 3)
				local didWander = false

				for hop = 1, hopCount do
					if self.destroyed then break end

					local wanderDist = math.random(4,10)
					local startPos = self.rootPart.Position
					local angle = math.random(0,360)
					local endpoint = nil

					for attempt = 1, 6 do
						local radians = math.rad(angle)
						local direction = Vector3.new(math.cos(radians), 0, math.sin(radians))
						local targetPos = startPos + (direction * wanderDist)

						local raycastParams = RaycastParams.new()
						raycastParams.FilterType = Enum.RaycastFilterType.Exclude
						raycastParams.FilterDescendantsInstances = {self.character,CS:GetTagged("InvisibleBox")}

						local result = workspace:Raycast(startPos, direction * wanderDist, raycastParams)

						if not result then
							endpoint = targetPos
							break
						end

						angle = angle + 60
					end

					if not endpoint then break end

					self:moveToPoint(endpoint)
					didWander = true
					task.wait(math.random(3,8) / 10)
				end

				if didWander then
					wanderCooldown = os.clock() + math.random(5,15)
				end
			elseif not stoppedEarly then
				if reverseMode then
					local exitReverse = math.random(1, 5) == 1
					if exitReverse and #to ~= 0 then
						reverseMode = false
						self.currentPath = to[math.random(1, #to)]
					else
						self:walkPath(self.pathFolder:FindFirstChild(self.currentPath), true, self.offsetMax, false)

						local combined = {}
						for _, x in from do
							table.insert(combined, x)
						end
						for _, x in thisData.ReverseLinkTo or {} do
							table.insert(combined, x)
						end

						if #combined > 0 then
							self.currentPath = combined[math.random(1, #combined)]

							if table.find(from, self.currentPath) then
								self.reverseNext = true
							end
						else
							reverseMode = false
							self.currentPath = prev
						end
					end
				else
					if #to ~= 0 and walkBack ~= 1 then
						self.currentPath = to[math.random(1, #to)]
					else
						reverseMode = true
						self:walkPath(self.pathFolder:FindFirstChild(self.currentPath), true, self.offsetMax, false)

						local combined = {}
						for _, x in from do
							table.insert(combined, x)
						end
						for _, x in thisData.ReverseLinkTo or {} do
							table.insert(combined, x)
						end

						if #combined > 0 then
							self.currentPath = combined[math.random(1, #combined)]

							if table.find(from, self.currentPath) then
								self.reverseNext = true
							end
						else
							self.currentPath = prev
						end
					end
				end
			end
		end

		if walkingOutDoor then
			self:spawnInEffect(false,.5)
		else
			self:spawnInEffect(false, 2.5)

			local walkOffPath = self.pathFolder.Parent:FindFirstChild("WalkOffPath")
			if walkOffPath then
				self:walkPath(walkOffPath, nil, self.offsetMax, false)
			end
		end

		Promise.delay(2.5):andThen(function()
			self:Destroy()
		end)
	end))
end

return RandomizedNPC