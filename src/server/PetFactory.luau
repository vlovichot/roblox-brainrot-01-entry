-- PetFactory: builds a blocky brainrot pet Model out of parts -- body, head,
-- eyes, little feet and the one accessory its catalog entry wears -- welded
-- to the body, with a BillboardGui label showing name, rarity and income.
-- Every other service moves pets around; only this module knows how a pet
-- is put together.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))

local PetFactory = {}

local BODY_SIZE = Vector3.new(3, 2, 2.6)
local HEAD_SIZE = Vector3.new(2.2, 1.9, 2.0)
local HEAD_OFFSET = Vector3.new(0, 0.6, -1.95) -- the pet faces -Z

-- How far the model origin (the body's centre) floats above the surface a
-- pet stands on, so its feet rest exactly on that surface.
PetFactory.GroundOffset = 1.45

local function makePart(name, size, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.CanQuery = false
	part.Massless = true
	part.Anchored = false
	return part
end

local function weldTo(part, body)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = body
	weld.Part1 = part
	weld.Parent = part
end

local function buildLabel(pet, mutationName, income)
	local gui = Instance.new("BillboardGui")
	gui.Name = "PetLabel"
	gui.Size = UDim2.new(7, 0, 3, 0)
	gui.StudsOffset = Vector3.new(0, 2.8, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0

	local rarityColor = BrainrotCatalog.RarityInfo[pet.Rarity].Color

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.38, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.TextScaled = true
	nameLabel.TextStrokeTransparency = 0.35
	nameLabel.TextColor3 = rarityColor
	local displayName = pet.Name
	if mutationName then
		displayName = BrainrotCatalog.Mutations[mutationName].Label .. " " .. displayName
	end
	nameLabel.Text = displayName
	nameLabel.Parent = gui

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Name = "InfoLabel"
	infoLabel.Size = UDim2.new(1, 0, 0.3, 0)
	infoLabel.Position = UDim2.new(0, 0, 0.38, 0)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Font = Enum.Font.GothamBold
	infoLabel.TextScaled = true
	infoLabel.TextStrokeTransparency = 0.35
	infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	infoLabel.Text = string.format("%s  •  $%s/s", string.upper(pet.Rarity), BrainrotCatalog.FormatMoney(income))
	infoLabel.Parent = gui

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "PriceLabel"
	priceLabel.Size = UDim2.new(1, 0, 0.32, 0)
	priceLabel.Position = UDim2.new(0, 0, 0.68, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Font = Enum.Font.GothamBlack
	priceLabel.TextScaled = true
	priceLabel.TextStrokeTransparency = 0.35
	priceLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
	priceLabel.Text = "$" .. BrainrotCatalog.FormatMoney(pet.Price)
	priceLabel.Visible = false
	priceLabel.Parent = gui

	return gui
end

-- Cycle a Disco pet's body colours through the rainbow for as long as it
-- exists. Started once at build time; ends when the model is destroyed.
local function startDiscoCycle(model, body, head, accessoryPart)
	local bodyHue = select(1, body.Color:ToHSV())
	local headHue = select(1, head.Color:ToHSV())
	local _, bodySat, bodyVal = body.Color:ToHSV()
	local _, headSat, headVal = head.Color:ToHSV()
	task.spawn(function()
		local t = 0
		while model.Parent do
			t += 0.12
			body.Color = Color3.fromHSV((bodyHue + t) % 1, math.max(bodySat, 0.55), bodyVal)
			head.Color = Color3.fromHSV((headHue + t) % 1, math.max(headSat, 0.55), headVal)
			if accessoryPart then
				accessoryPart.Color = Color3.fromHSV((bodyHue + t + 0.5) % 1, 0.6, 1)
			end
			task.wait(0.12)
		end
	end)
end

-- Build a fresh pet model for the given catalog id and mutation name
-- (mutationName may be nil). The model is unanchored and unwelded to the
-- world; callers anchor or weld it as they need.
function PetFactory.CreatePet(petId, mutationName)
	local pet = BrainrotCatalog.PetById[petId]
	assert(pet, "Unknown pet id: " .. tostring(petId))

	local _, mutationMultiplier = 1, 1
	if mutationName then
		mutationMultiplier = BrainrotCatalog.Mutations[mutationName].IncomeMultiplier
	end
	local income = pet.Income * mutationMultiplier

	local model = Instance.new("Model")
	model.Name = pet.Name

	local body = makePart("Body", BODY_SIZE, pet.BodyColor)
	body:SetAttribute("IsPetBody", true)
	model.PrimaryPart = body
	body.Parent = model

	local head = makePart("Head", HEAD_SIZE, pet.HeadColor)
	head.Position = HEAD_OFFSET
	head.Parent = model
	weldTo(head, body)

	-- Eyes: white balls with black pupils, on the front of the head.
	for _, side in ipairs({ -1, 1 }) do
		local eyeWhite = makePart("EyeWhite", Vector3.new(0.5, 0.5, 0.5), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
		eyeWhite.Shape = Enum.PartType.Ball
		eyeWhite.Position = HEAD_OFFSET + Vector3.new(0.55 * side, 0.25, -1.02)
		eyeWhite.Parent = model
		weldTo(eyeWhite, body)

		local pupil = makePart("Pupil", Vector3.new(0.24, 0.24, 0.24), Color3.fromRGB(20, 20, 20))
		pupil.Shape = Enum.PartType.Ball
		pupil.Position = HEAD_OFFSET + Vector3.new(0.55 * side, 0.28, -1.24)
		pupil.Parent = model
		weldTo(pupil, body)
	end

	-- Little feet under the body.
	for _, side in ipairs({ -1, 1 }) do
		local foot = makePart("Foot", Vector3.new(0.8, 0.5, 0.9), pet.BodyColor)
		foot.Position = Vector3.new(0.9 * side, -1.2, 0.4)
		foot.Parent = model
		weldTo(foot, body)
	end

	-- The one accessory this pet wears.
	local accessoryData = pet.Accessory
	local accessoryPart = makePart("Accessory", accessoryData.Size, accessoryData.Color)
	if accessoryData.Shape == "Ball" then
		accessoryPart.Shape = Enum.PartType.Ball
	elseif accessoryData.Shape == "Cylinder" then
		accessoryPart.Shape = Enum.PartType.Cylinder
	end
	accessoryPart.Transparency = accessoryData.Transparency
	accessoryPart.Position = HEAD_OFFSET + accessoryData.Offset
	if accessoryData.Shape == "Cylinder" then
		-- Roblox cylinders lie along X; stand squat ones (bowls, hats) upright.
		if accessoryData.Size.Y < accessoryData.Size.X then
			accessoryPart.CFrame = CFrame.new(accessoryPart.Position) * CFrame.Angles(0, 0, math.rad(90))
		else
			accessoryPart.CFrame = CFrame.new(accessoryPart.Position)
		end
	end
	accessoryPart.Parent = model
	weldTo(accessoryPart, body)

	-- Mutation dressing.
	if mutationName == "Gold" then
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "Accessory" then
				part.Material = Enum.Material.Metal
				part.Color = Color3.fromRGB(255, 201, 60)
			end
		end
		accessoryPart.Material = Enum.Material.Metal
	elseif mutationName == "Disco" then
		body.Material = Enum.Material.Neon
		head.Material = Enum.Material.Neon
		startDiscoCycle(model, body, head, accessoryPart)
	end

	local label = buildLabel(pet, mutationName, income)
	label.Adornee = head
	label.Parent = model

	model:SetAttribute("PetId", pet.Id)
	model:SetAttribute("PetName", pet.Name)
	model:SetAttribute("Rarity", pet.Rarity)
	model:SetAttribute("Price", pet.Price)
	model:SetAttribute("Income", income)
	model:SetAttribute("Mutation", mutationName or "")

	return model
end

-- Show or hide the green price line on a pet's label (lane pets show it,
-- carried and placed pets do not).
function PetFactory.SetPriceTagVisible(model, visible)
	local label = model:FindFirstChild("PetLabel")
	if label then
		local priceLabel = label:FindFirstChild("PriceLabel")
		if priceLabel then
			priceLabel.Visible = visible
		end
	end
end

-- Anchor or unanchor the pet's body (the welded parts follow either way).
function PetFactory.SetAnchored(model, anchored)
	local body = model.PrimaryPart
	if body then
		body.Anchored = anchored
	end
end

return PetFactory
