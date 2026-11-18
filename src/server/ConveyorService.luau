-- ConveyorService: runs the conveyor lane down the middle of the plaza.
-- Pets spawn at the start arch, ride the belt to the far end and despawn;
-- each carries a Buy ProximityPrompt. Buying is server-authoritative:
-- hands free and enough cash, or nothing happens. Also takes back pets
-- the gravy tsunami washed off their carriers.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))
local PetFactory = require(script.Parent.PetFactory)

local ConveyorService = {}

local MAX_LANE_PETS = 8
local SPAWN_INTERVAL = 2.2
local LANE_SPEED = 7 -- studs per second

local deps = nil
local rng = Random.new()
local lanePets = {} -- array of { Model = model, X = number }

function ConveyorService.Init(dependencies)
	deps = dependencies
end

local function removeLaneEntry(entry)
	for i, other in ipairs(lanePets) do
		if other == entry then
			table.remove(lanePets, i)
			return
		end
	end
end

-- Attach the Buy prompt to a lane pet. Shared by fresh spawns and by pets
-- the wave washed back to the lane.
local function addBuyPrompt(entry)
	local model = entry.Model
	local body = model.PrimaryPart
	if not body then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy"
	prompt.ObjectText = string.format("%s - $%s", model:GetAttribute("PetName"), BrainrotCatalog.FormatMoney(model:GetAttribute("Price")))
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.Parent = body

	prompt.Triggered:Connect(function(player)
		if entry.Bought then
			return
		end
		if deps.CarryService.IsCarrying(player) then
			deps.Notice(player, "Your hands are full! Place or sell a pet first.")
			return
		end
		local price = model:GetAttribute("Price")
		if not deps.EconomyService.TrySpend(player, price) then
			deps.Notice(player, string.format("Not enough cash! %s costs $%s.", model:GetAttribute("PetName"), BrainrotCatalog.FormatMoney(price)))
			return
		end
		entry.Bought = true
		removeLaneEntry(entry)
		prompt:Destroy()
		if not deps.CarryService.Carry(player, model) then
			-- The character vanished mid-buy: refund and put the pet back.
			deps.EconomyService.AddCash(player, price)
			entry.Bought = false
			table.insert(lanePets, entry)
			addBuyPrompt(entry)
			return
		end
		deps.Notice(player, string.format("You bought %s! Carry it to a pad at your base.", model:GetAttribute("PetName")))
	end)
end

local function spawnLanePet()
	local pet = BrainrotCatalog.RollRandomPet(rng)
	local mutationName, _ = BrainrotCatalog.RollMutation(rng)
	local model = PetFactory.CreatePet(pet.Id, mutationName)
	PetFactory.SetAnchored(model, true)
	PetFactory.SetPriceTagVisible(model, true)
	model:PivotTo(CFrame.new(deps.World.LaneStartX, deps.World.LanePetY, deps.World.LaneZ) * CFrame.Angles(0, math.rad(-90), 0))
	model.Parent = workspace

	local entry = { Model = model, X = deps.World.LaneStartX, Bought = false }
	table.insert(lanePets, entry)
	addBuyPrompt(entry)
end

-- A pet the tsunami ripped from its carrier washes back to the lane
-- start, on sale again at its catalog price.
function ConveyorService.ReclaimWashedPet(model)
	PetFactory.SetAnchored(model, true)
	PetFactory.SetPriceTagVisible(model, true)
	model:PivotTo(CFrame.new(deps.World.LaneStartX, deps.World.LanePetY, deps.World.LaneZ) * CFrame.Angles(0, math.rad(-90), 0))
	if not model.Parent then
		model.Parent = workspace
	end
	local entry = { Model = model, X = deps.World.LaneStartX, Bought = false }
	table.insert(lanePets, entry)
	addBuyPrompt(entry)
end

function ConveyorService.Start()
	-- Spawn loop: keep the belt stocked.
	task.spawn(function()
		while true do
			task.wait(SPAWN_INTERVAL)
			if #lanePets < MAX_LANE_PETS then
				spawnLanePet()
			end
		end
	end)

	-- Movement loop: ride every lane pet toward the despawn arch.
	RunService.Heartbeat:Connect(function(deltaTime)
		for i = #lanePets, 1, -1 do
			local entry = lanePets[i]
			if not entry.Model.Parent then
				table.remove(lanePets, i)
			else
				entry.X += LANE_SPEED * deltaTime
				if entry.X >= deps.World.LaneEndX then
					table.remove(lanePets, i)
					entry.Model:Destroy()
				else
					entry.Model:PivotTo(CFrame.new(entry.X, deps.World.LanePetY, deps.World.LaneZ) * CFrame.Angles(0, math.rad(-90), 0))
				end
			end
		end
	end)
end

return ConveyorService
