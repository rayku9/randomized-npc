local RS = game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")
local plrs = game:GetService("Players")
local localPlr = plrs.LocalPlayer

local mods = RS.Modules
local RandomizedNPC = require(mods.RandomizedNPC)
local randomizedNPCData = require(mods.Info.RandomizedNPCData)
local Zone = require(mods.Zone)
local Promise = require(mods.Promise)

local function spawnNPC(folder,pathData,settings,instructions)
	Promise.try(function()
		local newNPC = require(RS.Modules.CharacterRandomizer):generate()
		newNPC.Parent = workspace
 
		local randomizedNPC = RandomizedNPC.new(newNPC, folder, pathData, settings,instructions)

		return randomizedNPC
	end)
end

-- make zones
local currentSpawningPromise = nil
local spawnCD1,spawnCD2 = 5,10

local function shuffle(t)
	local j, temp
	for i = #t, 1, -1 do
		j = math.random(i)
		temp = t[i]
		t[i] = t[j]
		t[j] = temp
	end
end

for _, folder in CS:GetTagged("RandomizedNPCSpawn") do
	local holder = folder:FindFirstChild("NPCHolder")
	local cityFolder = folder:FindFirstChild("CityFolder")
	local zoneParts = folder:WaitForChild("ZoneParts")
	
	local data = randomizedNPCData[folder.Name]
	local path,settings = data.PathData,data.NPCSettings
	
	local maxNPCs = folder:GetAttribute("MaxNPCs")
	local respawnRate = folder:GetAttribute("RespawnRate")
	
	local newZone = Zone.new(zoneParts)
	newZone.playerEntered:Connect(function(plr)
		if not plr or not plr.Parent then return end
		if plr ~= localPlr then return end

		if currentSpawningPromise then
			currentSpawningPromise:cancel()
			currentSpawningPromise = nil
		end
		
		-- main spawn
		local npcCount = #(RandomizedNPC:getAllNPCS()[cityFolder] or {})
		if npcCount < math.floor(maxNPCs/3) then
			-- auto spawn
			local allPaths = {}
			for pathName,_ in path do
				table.insert(allPaths,pathName)
			end
			shuffle(allPaths)
			
			for i=1,math.floor(maxNPCs/3) do
				task.wait(.2)
				local pickedPath = allPaths[i]
				if not pickedPath then
					pickedPath = allPaths[math.random(1,#allPaths)]
				end
				
				local endOfPath = (math.random(1,2)==2)
				local nextPath = nil
				local isReverse = nil
				if endOfPath then
					local pathData = path[pickedPath]
					
					if pathData.LinkTo and #pathData.LinkTo~=0 then
						nextPath = pathData.LinkTo[math.random(1,#pathData.LinkTo)]
					else
						nextPath = pickedPath
						isReverse = true
					end
				else
					nextPath = pickedPath
				end
				
				local instructions = {
					currentPath = pickedPath,
					nextPath = nextPath,
					isReverse = isReverse,
					spawnPoint = if endOfPath then "end" else "start",
				}
			
				spawnNPC(folder.CityFolder,path,settings,instructions)
			end
		end
		
		-- beginLoading
		currentSpawningPromise = Promise.try(function()
			while true do
				local npcCount = #(RandomizedNPC:getAllNPCS()[cityFolder] or {})
				
				if npcCount >= maxNPCs then
					repeat task.wait(1) until npcCount < maxNPCs
				end
				
				spawnNPC(folder.CityFolder,path,settings)
				task.wait(math.random(spawnCD1*respawnRate,spawnCD2*respawnRate))
			end
		end)
	end)
	newZone.playerExited:Connect(function(plr)
		if not plr or not plr.Parent then return end
		if plr ~= localPlr then return end
		
		if currentSpawningPromise then
			currentSpawningPromise:cancel()
			currentSpawningPromise = nil
		end
	end)
end