local CharacterRandomizer = {}

local RS = game:GetService("ReplicatedStorage")
local modules = RS.Modules
local Promise = require(modules.Promise)

local NPCModels = RS.RandomizedNPC.NPCModels
local accessories = NPCModels.Parent.Accessories

local tones = {
	Color3.fromRGB(204, 142, 105),
	Color3.fromRGB(218, 133, 65),
	Color3.fromRGB(255, 204, 153),
	Color3.fromRGB(247, 198, 148),
	Color3.fromRGB(212, 170, 127),
	Color3.fromRGB(204, 142, 105),
	Color3.fromRGB(197, 136, 101),
	Color3.fromRGB(181, 125, 93),
	Color3.fromRGB(105, 64, 40),
}

-- randomizers
function randomizeSkinTone(char)
	local bodyColors = char:FindFirstChildOfClass("BodyColors")
	local c = tones[math.random(1,#tones)]
	
	bodyColors.HeadColor3 = c
	bodyColors.LeftArmColor3 = c
	bodyColors.RightArmColor3 = c
	bodyColors.LeftLegColor3 = c
	bodyColors.RightLegColor3 = c
	bodyColors.TorsoColor3 = c
end

local defaultShirtColors = {
	Color3.fromRGB(160,160,160),
	Color3.fromRGB(90,90,90),
	Color3.fromRGB(170, 85, 0),
	Color3.fromRGB(170, 170, 0),
	Color3.fromRGB(170, 0, 127),
	Color3.fromRGB(0, 85, 127),
	Color3.fromRGB(170, 170, 127),
	Color3.fromRGB(255, 170, 0),
	Color3.fromRGB(85, 85, 127),
	Color3.fromRGB(85, 255, 127),
	Color3.fromRGB(255, 255, 127),
	Color3.fromRGB(85, 170, 255),
}
local shirtsIds = {
	{
		ID = "rbxassetid://exampleID",
		Type = 1,
		Colors = {Color3.new(1,1,1)},
		Accessories = {"ExampleAccessory"},
		LinkedPants = "rbxassetid://exampleID",
	},
}

local pantsIds = {
	{
		ID = "rbxassetid://exampleID",
		Colors = {Color3.new(1,1,1)},
	},
}

-- preload all
local provider = game:GetService("ContentProvider")

Promise.try(function()
	local assetsToLoad = {}

	for _, shirt in shirtsIds do
		table.insert(assetsToLoad, shirt.ID)
		if shirt.LinkedPants then
			table.insert(assetsToLoad, shirt.LinkedPants)
		end
	end

	for _, pants in pantsIds do
		table.insert(assetsToLoad, pants.ID)
	end

	provider:PreloadAsync(assetsToLoad)
end)

function weldAttachments(attach1, attach2)
	local weld = Instance.new("Weld")
	weld.Part0 = attach1.Parent
	weld.Part1 = attach2.Parent
	weld.C0 = attach1.CFrame
	weld.C1 = attach2.CFrame
	weld.Parent = attach1.Parent
	return weld
end

local function buildWeld(weldName, parent, part0, part1, c0, c1)
	local weld = Instance.new("Weld")
	weld.Name = weldName
	weld.Part0 = part0
	weld.Part1 = part1
	weld.C0 = c0
	weld.C1 = c1
	weld.Parent = parent
	return weld
end

local function findFirstMatchingAttachment(model, name)
	for _, child in pairs(model:GetChildren()) do
		if child:IsA("Attachment") and child.Name == name then
			return child
		elseif not child:IsA("Accoutrement") and not child:IsA("Tool") then -- Don't look in hats or tools in the character
			local foundAttachment = findFirstMatchingAttachment(child, name)
			if foundAttachment then
				return foundAttachment
			end
		end
	end
end

function addAccoutrement(character, accoutrement)  
	accoutrement.Parent = character
	local handle = accoutrement:FindFirstChild("Handle")
	if handle then
		local accoutrementAttachment = handle:FindFirstChildOfClass("Attachment")
		if accoutrementAttachment then
			local characterAttachment = findFirstMatchingAttachment(character, accoutrementAttachment.Name)
			if characterAttachment then
				weldAttachments(characterAttachment, accoutrementAttachment)
			end
		else
			local head = character:FindFirstChild("Head")
			if head then
				local attachmentCFrame = CFrame.new(0, 0.5, 0)
				local hatCFrame = accoutrement.AttachmentPoint
				buildWeld("HeadWeld", head, head, handle, attachmentCFrame, hatCFrame)
			end
		end
	end
end

function applyAccessory(char,accessoryName)
	local accessory = accessories:FindFirstChild(accessoryName)
	if accessory then
		local new = accessory:Clone()
		
		addAccoutrement(char,new)
	end
end

function randomizeClothing(char,npcType)
	local shirtData = nil
	repeat
		shirtData = shirtsIds[math.random(1,#shirtsIds)]
		
		if shirtData.Type and shirtData.Type ~= npcType then
			shirtData = nil
		end
	until shirtData
	
	-- apply
	local shirt = char:FindFirstChildOfClass("Shirt")
	shirt.ShirtTemplate = shirtData.ID
	shirt.Color3 = shirtData.Colors[math.random(1,#shirtData.Colors)]
	
	if shirtData.Accessories then
		for _, acc in shirtData.Accessories do
			applyAccessory(char,acc)
		end
	end
	
	local pants = char:FindFirstChildOfClass("Pants")
	if shirtData.LinkedPants then
		pants.PantsTemplate = shirtData.LinkedPants
		pants.Color3 = shirt.Color3
	else
		local pantsData = nil
		repeat
			pantsData = pantsIds[math.random(1,#pantsIds)]

			if pantsData.Type and pantsData.Type ~= npcType then
				pantsData = nil
			end
		until pantsData
		
		pants.PantsTemplate = pantsData.ID
		pants.Color3 = pantsData.Colors[math.random(1,#pantsData.Colors)]
	end

	return shirtData.Accessories ~= nil
end

function randomizeSize(char)
	local isRandomized = (math.random(1,3) == 1)
	if isRandomized then
		char:ScaleTo(1 + math.random(-125,125)/1000)
	end
end

local hairs = NPCModels.Parent.Hairs
local hairsModels = {
	hairs["1"]:GetChildren(),
	hairs["2"]:GetChildren()
}
function randomizeHair(char,npcType)
	local pickedHair = hairsModels[npcType][math.random(1,#hairsModels[npcType])]:Clone()
	addAccoutrement(char,pickedHair)
end

function randomizeAccessories(char)
	-- none yet
end

local faceIds = {
	{
		"faceIdsSet1" -- add real face ids here
	},
	{
		"faceIdsSet2", -- add real face ids here
	}
}
function randomizeFace(char,npcType)
	local head = char:FindFirstChild("Head")
	if head then
		local face = head:FindFirstChild("face")
		if face then
			face.Texture = faceIds[npcType][math.random(1,#faceIds[npcType])]
		end
	end
end

function CharacterRandomizer:generate()
	local newNpc = NPCModels.BaseNPC:Clone()
	local npcType = math.random(1,2)
	
	randomizeSkinTone(newNpc)
	local setAccessories = randomizeClothing(newNpc,npcType)
	randomizeHair(newNpc,npcType)
	if not setAccessories then randomizeAccessories(newNpc) end
	randomizeFace(newNpc,npcType)
	randomizeSize(newNpc)
	
	return newNpc
end

return CharacterRandomizer
