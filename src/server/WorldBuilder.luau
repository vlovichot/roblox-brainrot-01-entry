-- WorldBuilder: constructs the whole Brainrot Pet Bazaar plaza out of
-- anchored parts at server start -- checkered plaza floor, the conveyor
-- lane with its arches, four player bases with display pads, the rebirth
-- shrine, fences, lamp posts and the big title sign. Returns a table of
-- the pieces the services need (lane geometry, bases, shrine crystal).

local WorldBuilder = {}

-- Lane geometry, shared with ConveyorService and WaveService.
WorldBuilder.LaneStartX = -52
WorldBuilder.LaneEndX = 54
WorldBuilder.LaneZ = 0
WorldBuilder.BeltTopY = 1.5

local PLAZA_HALF = 60 -- the plaza floor spans -60..60 on both axes
local BASE_POSITIONS = {
	Vector3.new(-36, 0, -36),
	Vector3.new(36, 0, -36),
	Vector3.new(-36, 0, 36),
	Vector3.new(36, 0, 36),
}
local BASE_COLORS = {
	Color3.fromRGB(255, 150, 150),
	Color3.fromRGB(140, 200, 255),
	Color3.fromRGB(160, 255, 170),
	Color3.fromRGB(255, 220, 130),
}
local PLATFORM_SIZE = Vector3.new(26, 1, 26)
local PLATFORM_TOP_Y = 1.5

local function makePart(parent, name, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- A free-standing board with one line of big text on its front face.
local function makeSign(parent, name, text, size, cframe, boardColor, textColor, fontSize)
	local board = makePart(parent, name, size, cframe, boardColor)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignGui"
	gui.Face = Enum.NormalId.Front
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Name = "SignLabel"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = textColor
	label.Text = text
	label.Parent = gui
	return board, label
end

local function buildFloor(parent)
	local tileSize = 12
	local light = Color3.fromRGB(245, 240, 230)
	local dark = Color3.fromRGB(120, 200, 235)
	for gx = 0, 9 do
		for gz = 0, 9 do
			local color = ((gx + gz) % 2 == 0) and light or dark
			makePart(
				parent,
				"PlazaTile",
				Vector3.new(tileSize, 0.5, tileSize),
				CFrame.new(-PLAZA_HALF + tileSize / 2 + gx * tileSize, 0.25, -PLAZA_HALF + tileSize / 2 + gz * tileSize),
				color
			)
		end
	end
end

local function buildLane(parent)
	local beltLength = WorldBuilder.LaneEndX - WorldBuilder.LaneStartX + 10
	local beltCenterX = (WorldBuilder.LaneStartX + WorldBuilder.LaneEndX) / 2
	makePart(parent, "ConveyorBelt", Vector3.new(beltLength, 1, 9), CFrame.new(beltCenterX, 1.0, WorldBuilder.LaneZ), Color3.fromRGB(45, 45, 55), Enum.Material.Metal)
	-- Pale stripes across the belt so the surface reads as moving machinery.
	for x = WorldBuilder.LaneStartX - 2, WorldBuilder.LaneEndX + 2, 8 do
		makePart(parent, "BeltStripe", Vector3.new(0.7, 0.06, 9), CFrame.new(x, WorldBuilder.BeltTopY + 0.03, WorldBuilder.LaneZ), Color3.fromRGB(120, 120, 135), Enum.Material.Metal)
	end
	-- Side rails.
	for _, side in ipairs({ -1, 1 }) do
		makePart(parent, "LaneRail", Vector3.new(beltLength, 0.8, 0.6), CFrame.new(beltCenterX, 1.9, WorldBuilder.LaneZ + 5 * side), Color3.fromRGB(255, 170, 40))
	end
	-- Spawn and despawn arches at the two ends of the lane.
	for _, endX in ipairs({ WorldBuilder.LaneStartX - 4, WorldBuilder.LaneEndX + 4 }) do
		for _, side in ipairs({ -1, 1 }) do
			makePart(parent, "ArchPost", Vector3.new(1.2, 9, 1.2), CFrame.new(endX, 5, WorldBuilder.LaneZ + 5.5 * side), Color3.fromRGB(255, 90, 160))
		end
		makePart(parent, "ArchBeam", Vector3.new(1.2, 1.6, 12.2), CFrame.new(endX, 9.5, WorldBuilder.LaneZ), Color3.fromRGB(255, 90, 160))
	end
	makeSign(parent, "SpawnArchSign", "FRESH BRAINROTS!", Vector3.new(0.6, 3, 11), CFrame.new(WorldBuilder.LaneStartX - 4, 12.5, WorldBuilder.LaneZ) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(40, 40, 60), Color3.fromRGB(255, 240, 120))
end

local function buildBase(parent, index, center, color)
	local baseFolder = Instance.new("Folder")
	baseFolder.Name = "Base" .. index
	baseFolder.Parent = parent

	local platform = makePart(baseFolder, "Platform", PLATFORM_SIZE, CFrame.new(center.X, 1.0, center.Z), color)
	-- A glowing trim ring on the platform edge.
	makePart(baseFolder, "PlatformTrim", Vector3.new(PLATFORM_SIZE.X + 0.4, 0.3, PLATFORM_SIZE.Z + 0.4), CFrame.new(center.X, 0.65, center.Z), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)

	-- Six display pads, two rows of three.
	local pads = {}
	for row, dz in ipairs({ -5, 5 }) do
		for col, dx in ipairs({ -7.5, 0, 7.5 }) do
			local pad = makePart(
				baseFolder,
				"Pad" .. ((row - 1) * 3 + col),
				Vector3.new(5, 0.4, 5),
				CFrame.new(center.X + dx, PLATFORM_TOP_Y + 0.2, center.Z + dz),
				Color3.fromRGB(250, 250, 250)
			)
			pad:SetAttribute("BaseIndex", index)
			table.insert(pads, pad)
		end
	end

	-- Lock button: a post by the platform's plaza-facing corner with a big
	-- red ball on top. BaseService hangs its ProximityPrompt on the ball.
	local postPosition = Vector3.new(center.X + 10, PLATFORM_TOP_Y + 1.5, center.Z + 10)
	makePart(baseFolder, "LockPost", Vector3.new(0.8, 3, 0.8), CFrame.new(postPosition), Color3.fromRGB(60, 60, 70), Enum.Material.Metal)
	local lockButton = makePart(baseFolder, "LockButton", Vector3.new(1.5, 1.5, 1.5), CFrame.new(postPosition + Vector3.new(0, 2.1, 0)), Color3.fromRGB(235, 45, 45))
	lockButton.Shape = Enum.PartType.Ball

	-- Owner sign on two posts at the back of the platform.
	local signPosition = Vector3.new(center.X, PLATFORM_TOP_Y + 5.5, center.Z - 11.5)
	for _, side in ipairs({ -1, 1 }) do
		makePart(baseFolder, "SignPost", Vector3.new(0.7, 6, 0.7), CFrame.new(center.X + 4.5 * side, PLATFORM_TOP_Y + 3, center.Z - 11.5), Color3.fromRGB(60, 60, 70), Enum.Material.Metal)
	end
	local _, ownerLabel = makeSign(baseFolder, "OwnerSign", "UNCLAIMED BASE", Vector3.new(11, 3.4, 0.5), CFrame.new(signPosition), Color3.fromRGB(35, 35, 50), Color3.fromRGB(255, 255, 255))
	ownerLabel.Name = "OwnerLabel"

	return {
		Index = index,
		Center = Vector3.new(center.X, PLATFORM_TOP_Y, center.Z),
		Platform = platform,
		Pads = pads,
		LockButton = lockButton,
		OwnerLabel = ownerLabel,
		SpawnCFrame = CFrame.lookAt(
			Vector3.new(center.X, PLATFORM_TOP_Y + 3.5, center.Z + 8),
			Vector3.new(0, PLATFORM_TOP_Y + 3.5, 0)
		),
	}
end

local function buildShrine(parent)
	local shrineFolder = Instance.new("Folder")
	shrineFolder.Name = "RebirthShrine"
	shrineFolder.Parent = parent

	local center = Vector3.new(0, 0, -48)
	local platform = makePart(shrineFolder, "ShrinePlatform", Vector3.new(15, 1, 15), CFrame.new(center.X, 1.0, center.Z), Color3.fromRGB(90, 60, 160))
	platform.Shape = Enum.PartType.Cylinder
	platform.CFrame = CFrame.new(center.X, 1.0, center.Z) * CFrame.Angles(0, 0, math.rad(90))
	makePart(shrineFolder, "ShrinePedestal", Vector3.new(3.4, 1.6, 3.4), CFrame.new(center.X, 2.3, center.Z), Color3.fromRGB(50, 40, 80), Enum.Material.Metal)
	local crystal = makePart(shrineFolder, "RebirthCrystal", Vector3.new(2.4, 5, 2.4), CFrame.new(center.X, 5.6, center.Z) * CFrame.Angles(0, math.rad(45), 0), Color3.fromRGB(190, 90, 255), Enum.Material.Neon)
	makeSign(shrineFolder, "ShrineSign", "REBIRTH SHRINE", Vector3.new(11, 2.6, 0.5), CFrame.new(center.X, 4.6, center.Z - 7.6), Color3.fromRGB(35, 35, 50), Color3.fromRGB(220, 170, 255))

	return crystal
end

local function buildDressing(parent)
	-- Low hedges around the plaza edge, with gaps at the lane ends.
	local hedgeColor = Color3.fromRGB(70, 170, 80)
	for _, side in ipairs({ -1, 1 }) do
		makePart(parent, "Hedge", Vector3.new(2 * PLAZA_HALF + 2, 1.6, 1.2), CFrame.new(0, 1.3, PLAZA_HALF * side + 0.5 * side), hedgeColor)
		-- Side hedges stop short of the lane so the conveyor can exit.
		for _, xSide in ipairs({ -1, 1 }) do
			local segmentLength = PLAZA_HALF - 8
			makePart(parent, "Hedge", Vector3.new(1.2, 1.6, segmentLength), CFrame.new(PLAZA_HALF * xSide + 0.5 * xSide, 1.3, (8 + segmentLength / 2) * side), hedgeColor)
		end
	end
	-- Lamp posts around the plaza.
	for _, position in ipairs({
		Vector3.new(-20, 0, -20), Vector3.new(20, 0, -20), Vector3.new(-20, 0, 20), Vector3.new(20, 0, 20),
		Vector3.new(-52, 0, 20), Vector3.new(52, 0, -20),
	}) do
		makePart(parent, "LampPole", Vector3.new(0.6, 7, 0.6), CFrame.new(position.X, 4, position.Z), Color3.fromRGB(50, 50, 60), Enum.Material.Metal)
		local bulb = makePart(parent, "LampBulb", Vector3.new(1.4, 1.4, 1.4), CFrame.new(position.X, 7.8, position.Z), Color3.fromRGB(255, 240, 170), Enum.Material.Neon)
		bulb.Shape = Enum.PartType.Ball
	end
	-- The big title sign across the plaza from spawn.
	for _, side in ipairs({ -1, 1 }) do
		makePart(parent, "TitlePost", Vector3.new(1, 13, 1), CFrame.new(11 * side, 7, -57), Color3.fromRGB(60, 60, 70), Enum.Material.Metal)
	end
	makeSign(parent, "TitleSign", "BRAINROT PET BAZAAR", Vector3.new(30, 6.5, 1), CFrame.new(0, 12, -57) * CFrame.Angles(0, math.rad(180), 0), Color3.fromRGB(255, 90, 160), Color3.fromRGB(255, 255, 255))
end

-- Build everything and return the pieces the services need.
function WorldBuilder.Build()
	local worldFolder = Instance.new("Folder")
	worldFolder.Name = "BrainrotWorld"
	worldFolder.Parent = workspace

	buildFloor(worldFolder)
	buildLane(worldFolder)

	local bases = {}
	for index, center in ipairs(BASE_POSITIONS) do
		bases[index] = buildBase(worldFolder, index, center, BASE_COLORS[index])
	end

	local crystal = buildShrine(worldFolder)
	buildDressing(worldFolder)

	return {
		Bases = bases,
		ShrineCrystal = crystal,
		LaneStartX = WorldBuilder.LaneStartX,
		LaneEndX = WorldBuilder.LaneEndX,
		LaneZ = WorldBuilder.LaneZ,
		LanePetY = WorldBuilder.BeltTopY + 1.45,
		PlatformTopY = PLATFORM_TOP_Y,
		PlatformSize = PLATFORM_SIZE,
	}
end

return WorldBuilder
