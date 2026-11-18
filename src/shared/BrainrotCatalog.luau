-- BrainrotCatalog: the single source of truth for every brainrot pet in
-- Brainrot Pet Bazaar -- names, prices, income, rarity, colours and the
-- accessory each pet wears, plus the mutation rules rolled at spawn time.
-- Lives in ReplicatedStorage so server and client read the same table.

local BrainrotCatalog = {}

-- Rarity ladder, lowest to highest. Colour is used for labels and pads.
BrainrotCatalog.RarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic" }

BrainrotCatalog.RarityInfo = {
	Common = { Color = Color3.fromRGB(205, 205, 205), LaneWeight = 45 },
	Rare = { Color = Color3.fromRGB(70, 145, 255), LaneWeight = 27 },
	Epic = { Color = Color3.fromRGB(175, 85, 255), LaneWeight = 15 },
	Legendary = { Color = Color3.fromRGB(255, 190, 40), LaneWeight = 9 },
	Mythic = { Color = Color3.fromRGB(255, 70, 200), LaneWeight = 4 },
}

-- Mutations are rolled once when a pet appears on the conveyor.
-- Disco is checked first: a pet is never both Gold and Disco.
BrainrotCatalog.Mutations = {
	Gold = { Chance = 0.12, IncomeMultiplier = 3, Label = "GOLD" },
	Disco = { Chance = 0.03, IncomeMultiplier = 8, Label = "DISCO" },
}

-- Accessory: one extra part built by PetFactory.
-- Shape is a Roblox PartType ("Block", "Ball" or "Cylinder"); Offset is
-- relative to the centre of the pet's head; Transparency defaults to 0.
local function accessory(shape, size, color, offset, transparency)
	return {
		Shape = shape,
		Size = size,
		Color = color,
		Offset = offset,
		Transparency = transparency or 0,
	}
end

BrainrotCatalog.Pets = {
	-- Common
	{
		Id = "NoodleCapybara", Name = "Noodle Capybara", Rarity = "Common",
		Price = 25, Income = 1,
		BodyColor = Color3.fromRGB(176, 124, 78), HeadColor = Color3.fromRGB(198, 146, 98),
		Accessory = accessory("Cylinder", Vector3.new(1.8, 0.45, 1.8), Color3.fromRGB(245, 245, 240), Vector3.new(0, 1.15, 0)),
	},
	{
		Id = "ToiletDuck", Name = "Toilet Duck", Rarity = "Common",
		Price = 50, Income = 2,
		BodyColor = Color3.fromRGB(255, 210, 60), HeadColor = Color3.fromRGB(255, 222, 85),
		Accessory = accessory("Block", Vector3.new(1.4, 1.6, 0.5), Color3.fromRGB(245, 245, 245), Vector3.new(0, 0.5, 1.35)),
	},
	{
		Id = "BananaSlug", Name = "Banana Slug", Rarity = "Common",
		Price = 90, Income = 4,
		BodyColor = Color3.fromRGB(250, 220, 60), HeadColor = Color3.fromRGB(250, 232, 115),
		Accessory = accessory("Ball", Vector3.new(1.0, 0.6, 1.0), Color3.fromRGB(255, 242, 160), Vector3.new(0, 1.1, 0.2)),
	},
	-- Rare
	{
		Id = "PizzaSloth", Name = "Pizza Sloth", Rarity = "Rare",
		Price = 300, Income = 9,
		BodyColor = Color3.fromRGB(150, 110, 80), HeadColor = Color3.fromRGB(192, 162, 132),
		Accessory = accessory("Cylinder", Vector3.new(1.9, 0.25, 1.9), Color3.fromRGB(242, 182, 82), Vector3.new(0, 1.15, 0)),
	},
	{
		Id = "DiscoFrog", Name = "Disco Frog", Rarity = "Rare",
		Price = 550, Income = 14,
		BodyColor = Color3.fromRGB(70, 200, 90), HeadColor = Color3.fromRGB(95, 226, 112),
		Accessory = accessory("Ball", Vector3.new(1.1, 1.1, 1.1), Color3.fromRGB(205, 205, 235), Vector3.new(0, 1.55, 0)),
	},
	{
		Id = "CactusElephant", Name = "Cactus Elephant", Rarity = "Rare",
		Price = 800, Income = 19,
		BodyColor = Color3.fromRGB(80, 170, 90), HeadColor = Color3.fromRGB(98, 188, 108),
		Accessory = accessory("Ball", Vector3.new(0.65, 0.65, 0.65), Color3.fromRGB(255, 120, 180), Vector3.new(0, 1.2, 0)),
	},
	-- Epic
	{
		Id = "BurgerAxolotl", Name = "Burger Axolotl", Rarity = "Epic",
		Price = 2500, Income = 48,
		BodyColor = Color3.fromRGB(255, 150, 170), HeadColor = Color3.fromRGB(255, 172, 188),
		Accessory = accessory("Block", Vector3.new(2.0, 0.7, 2.0), Color3.fromRGB(232, 172, 92), Vector3.new(0, 1.25, 0)),
	},
	{
		Id = "AstroHamster", Name = "Astro Hamster", Rarity = "Epic",
		Price = 4200, Income = 75,
		BodyColor = Color3.fromRGB(240, 160, 80), HeadColor = Color3.fromRGB(246, 182, 112),
		Accessory = accessory("Ball", Vector3.new(2.7, 2.7, 2.7), Color3.fromRGB(200, 230, 255), Vector3.new(0, 0.1, 0), 0.6),
	},
	{
		Id = "WizardPotato", Name = "Wizard Potato", Rarity = "Epic",
		Price = 6000, Income = 110,
		BodyColor = Color3.fromRGB(190, 150, 95), HeadColor = Color3.fromRGB(202, 166, 112),
		Accessory = accessory("Cylinder", Vector3.new(1.4, 1.7, 1.4), Color3.fromRGB(122, 82, 222), Vector3.new(0, 1.65, 0)),
	},
	-- Legendary
	{
		Id = "GoldenToiletDuck", Name = "Golden Toilet Duck", Rarity = "Legendary",
		Price = 20000, Income = 380,
		BodyColor = Color3.fromRGB(255, 200, 50), HeadColor = Color3.fromRGB(255, 216, 72),
		Accessory = accessory("Block", Vector3.new(1.4, 1.6, 0.5), Color3.fromRGB(255, 205, 55), Vector3.new(0, 0.5, 1.35)),
	},
	{
		Id = "MechaBananaShark", Name = "Mecha Banana Shark", Rarity = "Legendary",
		Price = 32000, Income = 560,
		BodyColor = Color3.fromRGB(120, 140, 160), HeadColor = Color3.fromRGB(142, 162, 182),
		Accessory = accessory("Ball", Vector3.new(1.3, 0.8, 1.3), Color3.fromRGB(252, 224, 80), Vector3.new(0, 1.2, 0.2)),
	},
	{
		Id = "VampireCappuccino", Name = "Vampire Cappuccino", Rarity = "Legendary",
		Price = 45000, Income = 800,
		BodyColor = Color3.fromRGB(240, 235, 225), HeadColor = Color3.fromRGB(182, 122, 82),
		Accessory = accessory("Cylinder", Vector3.new(0.25, 1.6, 0.25), Color3.fromRGB(205, 32, 42), Vector3.new(0.5, 1.35, 0)),
	},
	-- Mythic
	{
		Id = "CosmicBrainOctopus", Name = "Cosmic Brain Octopus", Rarity = "Mythic",
		Price = 150000, Income = 3000,
		BodyColor = Color3.fromRGB(130, 80, 200), HeadColor = Color3.fromRGB(152, 102, 222),
		Accessory = accessory("Ball", Vector3.new(1.6, 1.1, 1.6), Color3.fromRGB(255, 140, 190), Vector3.new(0, 1.25, 0)),
	},
	{
		Id = "FinalBossBaby", Name = "The Final Boss Baby", Rarity = "Mythic",
		Price = 400000, Income = 8500,
		BodyColor = Color3.fromRGB(255, 210, 170), HeadColor = Color3.fromRGB(255, 222, 186),
		Accessory = accessory("Cylinder", Vector3.new(1.5, 0.7, 1.5), Color3.fromRGB(255, 190, 40), Vector3.new(0, 1.3, 0)),
	},
}

BrainrotCatalog.PetById = {}
for _, pet in ipairs(BrainrotCatalog.Pets) do
	BrainrotCatalog.PetById[pet.Id] = pet
end

-- Pets grouped by rarity, for the conveyor's weighted spawn roll.
BrainrotCatalog.PetsByRarity = {}
for _, rarity in ipairs(BrainrotCatalog.RarityOrder) do
	BrainrotCatalog.PetsByRarity[rarity] = {}
end
 for _, pet in ipairs(BrainrotCatalog.Pets) do
	table.insert(BrainrotCatalog.PetsByRarity[pet.Rarity], pet)
end

-- Roll a random pet definition for the conveyor: pick a rarity by weight,
-- then a random pet of that rarity.
function BrainrotCatalog.RollRandomPet(rng)
	local totalWeight = 0
	for _, rarity in ipairs(BrainrotCatalog.RarityOrder) do
		totalWeight += BrainrotCatalog.RarityInfo[rarity].LaneWeight
	end
	local roll = rng:NextNumber(0, totalWeight)
	for _, rarity in ipairs(BrainrotCatalog.RarityOrder) do
		roll -= BrainrotCatalog.RarityInfo[rarity].LaneWeight
		if roll <= 0 then
			local pool = BrainrotCatalog.PetsByRarity[rarity]
			return pool[rng:NextInteger(1, #pool)]
		end
	end
	local pool = BrainrotCatalog.PetsByRarity.Common
	return pool[rng:NextInteger(1, #pool)]
end

-- Roll the mutation for a freshly spawned pet.
-- Returns the mutation name (or nil) and its income multiplier.
function BrainrotCatalog.RollMutation(rng)
	local roll = rng:NextNumber()
	if roll < BrainrotCatalog.Mutations.Disco.Chance then
		return "Disco", BrainrotCatalog.Mutations.Disco.IncomeMultiplier
	elseif roll < BrainrotCatalog.Mutations.Disco.Chance + BrainrotCatalog.Mutations.Gold.Chance then
		return "Gold", BrainrotCatalog.Mutations.Gold.IncomeMultiplier
	end
	return nil, 1
end

-- Short money formatting shared by labels: 950 -> "950", 12500 -> "12.5K".
function BrainrotCatalog.FormatMoney(amount)
	amount = math.floor(amount)
	if amount >= 1000000 then
		return string.format("%.2fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("%.1fK", amount / 1000)
	end
	return tostring(amount)
end

return BrainrotCatalog
