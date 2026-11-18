-- CarryService: the registry of who holds what. Tracks the pet riding
-- above each player's head and every pet placed on a display pad, and
-- performs the physical moves between the three states a pet can be in:
-- carried (welded to a head), placed (anchored on a pad) and washed away
-- (handed back to the conveyor by the wave). Money never moves here.

local CarryService = {}

local PetFactory = require(script.Parent.PetFactory)

local carriedByPlayer = {} -- [player] = pet model
local placedByPad = {} -- [pad part] = { Model = model, Owner = player }
local padsByPlayer = {} -- [player] = { [pad part] = true }
local washHandler = nil -- set by init: function(model) sends a dropped pet back to the lane

function CarryService.SetWashHandler(handler)
	washHandler = handler
end

function CarryService.GetCarried(player)
	return carriedByPlayer[player]
end

function CarryService.IsCarrying(player)
	return carriedByPlayer[player] ~= nil
end

-- Weld a pet above a player's head so it rides along with them.
-- Returns false (and changes nothing) if their hands are already full.
function CarryService.Carry(player, model)
	if carriedByPlayer[player] then
		return false
	end
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return false
	end

	PetFactory.SetAnchored(model, false)
	PetFactory.SetPriceTagVisible(model, false)
	model:PivotTo(head.CFrame * CFrame.new(0, 2.6, 0))

	local weld = Instance.new("WeldConstraint")
	weld.Name = "CarryWeld"
	weld.Part0 = model.PrimaryPart
	weld.Part1 = head
	weld.Parent = model.PrimaryPart

	carriedByPlayer[player] = model
	model:SetAttribute("CarriedByUserId", player.UserId)
	return true
end

-- Detach the carried pet's weld without moving the pet.
local function detachCarry(player)
	local model = carriedByPlayer[player]
	if not model then
		return nil
	end
	carriedByPlayer[player] = nil
	model:SetAttribute("CarriedByUserId", 0)
	local body = model.PrimaryPart
	local weld = body and body:FindFirstChild("CarryWeld")
	if weld then
		weld:Destroy()
	end
	return model
end

-- Put the pet a player is carrying down on one of their pads, anchored,
-- facing the plaza centre. Returns false if they carry nothing or the
-- pad is taken.
function CarryService.PlaceOnPad(player, pad)
	if placedByPad[pad] then
		return false
	end
	local model = detachCarry(player)
	if not model then
		return false
	end

	local padTopY = pad.Position.Y + pad.Size.Y / 2
	local standPosition = Vector3.new(pad.Position.X, padTopY + PetFactory.GroundOffset, pad.Position.Z)
	model:PivotTo(CFrame.lookAt(standPosition, Vector3.new(0, standPosition.Y, 0)))
	PetFactory.SetAnchored(model, true)
	model:SetAttribute("OwnerUserId", player.UserId)

	placedByPad[pad] = { Model = model, Owner = player }
	padsByPlayer[player] = padsByPlayer[player] or {}
	padsByPlayer[player][pad] = true
	return true
end

-- The record of the pet standing on a pad, or nil if the pad is empty.
function CarryService.GetPlacedRecord(pad)
	return placedByPad[pad]
end

-- Remove a pad's pet from the registry. Destroys the model unless
-- destroyModel is false (stealing keeps the model alive).
function CarryService.RemovePlaced(pad, destroyModel)
	local record = placedByPad[pad]
	if not record then
		return nil
	end
	placedByPad[pad] = nil
	local ownerPads = padsByPlayer[record.Owner]
	if ownerPads then
		ownerPads[pad] = nil
	end
	record.Model:SetAttribute("OwnerUserId", 0)
	if destroyModel then
		record.Model:Destroy()
	end
	return record
end

-- Re-register a pet that is already standing on a pad (used when a steal
-- fails halfway and the pet has to go back exactly where it stood).
function CarryService.RegisterPlaced(pad, model, owner)
	placedByPad[pad] = { Model = model, Owner = owner }
	padsByPlayer[owner] = padsByPlayer[owner] or {}
	padsByPlayer[owner][pad] = true
	model:SetAttribute("OwnerUserId", owner.UserId)
	PetFactory.SetAnchored(model, true)
end

-- Total $/s of every pet a player has placed (before their multiplier).
function CarryService.GetPlacedIncome(player)
	local total = 0
	local ownerPads = padsByPlayer[player]
	if ownerPads then
		for pad in pairs(ownerPads) do
			local record = placedByPad[pad]
			if record and record.Model.Parent then
				total += record.Model:GetAttribute("Income") or 0
			end
		end
	end
	return total
end

-- The wave caught this player in the open: their carried pet is ripped
-- away and washed back to the start of the conveyor lane.
function CarryService.DropCarriedToWave(player)
	local model = detachCarry(player)
	if not model then
		return false
	end
	if washHandler then
		washHandler(model)
	else
		model:Destroy()
	end
	return true
end

-- Re-weld the carried pet after a respawn (the old head is gone).
function CarryService.Reattach(player)
	local model = carriedByPlayer[player]
	if not model then
		return
	end
	carriedByPlayer[player] = nil
	model:SetAttribute("CarriedByUserId", 0)
	if not model.Parent then
		return
	end
	CarryService.Carry(player, model)
end

-- Destroy the carried pet and every placed pet of a player (they left,
-- or they rebirthed). Used by BaseService, RebirthService and init.
function CarryService.ClearPlayer(player)
	local model = detachCarry(player)
	if model then
		model:Destroy()
	end
	local ownerPads = padsByPlayer[player]
	if ownerPads then
		local pads = {}
		for pad in pairs(ownerPads) do
			table.insert(pads, pad)
		end
		for _, pad in ipairs(pads) do
			CarryService.RemovePlaced(pad, true)
		end
	end
	padsByPlayer[player] = nil
end

return CarryService
