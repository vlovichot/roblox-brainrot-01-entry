-- BaseService: assigns the four plaza bases to players and runs
-- everything that happens at a base -- placing carried pets on pads,
-- selling placed pets back at 50%, stealing pets from unlocked rival
-- bases, and the lock button (60 s locked, then a 30 s cooldown before
-- it can lock again). The base's lock state is mirrored to a player
-- attribute so the HUD can show it.

local BaseService = {}

local LOCK_DURATION = 60
local LOCK_COOLDOWN = 30 -- after the lock ends, before it can lock again

local deps = nil
local bases = {} -- array of base state tables built in Init
local baseByPlayer = {} -- [player] = base state
local baseByPad = {} -- [pad part] = base state

function BaseService.Init(dependencies)
	deps = dependencies
	for _, worldBase in ipairs(deps.World.Bases) do
		local base = {
			Index = worldBase.Index,
			Center = worldBase.Center,
			Platform = worldBase.Platform,
			Pads = worldBase.Pads,
			LockButton = worldBase.LockButton,
			OwnerLabel = worldBase.OwnerLabel,
			SpawnCFrame = worldBase.SpawnCFrame,
			Owner = nil,
			LockedUntil = 0,
			CooldownUntil = 0,
		}
		table.insert(bases, base)
		for _, pad in ipairs(base.Pads) do
			baseByPad[pad] = base
			addPadPrompt(base, pad)
		end
		addLockPrompt(base)
	end
end

function BaseService.IsLocked(base)
	return os.clock() < base.LockedUntil
end

-- The pad prompt: only the base's owner can place, and only while
-- carrying a pet onto an empty pad.
function addPadPrompt(base, pad)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PlacePrompt"
	prompt.ActionText = "Place Pet"
	prompt.ObjectText = "Display Pad"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.Parent = pad

	prompt.Triggered:Connect(function(player)
		if base.Owner ~= player then
			deps.Notice(player, "This is not your base!")
			return
		end
		if deps.CarryService.GetPlacedRecord(pad) then
			deps.Notice(player, "That pad is taken. Sell or move the pet on it first.")
			return
		end
		if not deps.CarryService.IsCarrying(player) then
			deps.Notice(player, "Buy a brainrot from the conveyor first, then place it here.")
			return
		end
		if deps.CarryService.PlaceOnPad(player, pad) then
			addPlacedPetPrompt(base, pad)
			deps.Notice(player, "Placed! It now earns cash every second.")
		end
	end)
end

-- One prompt on each placed pet: the owner sells it back at 50%, anyone
-- else steals it -- but only while the base is unlocked.
function addPlacedPetPrompt(base, pad)
	local record = deps.CarryService.GetPlacedRecord(pad)
	if not record then
		return
	end
	local body = record.Model.PrimaryPart
	if not body then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PetActionPrompt"
	prompt.ActionText = "Sell / Steal"
	prompt.ObjectText = record.Model:GetAttribute("PetName")
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 12
	prompt.Parent = body

	prompt.Triggered:Connect(function(player)
		local current = deps.CarryService.GetPlacedRecord(pad)
		if not current or current.Model ~= record.Model then
			return -- the pet is already gone
		end
		if current.Owner == player then
			local sellPrice = math.floor((current.Model:GetAttribute("Price") or 0) * 0.5)
			deps.CarryService.RemovePlaced(pad, true)
			deps.EconomyService.AddCash(player, sellPrice)
			deps.Notice(player, string.format("Sold for $%s.", sellPrice))
		elseif BaseService.IsLocked(base) then
			deps.Notice(player, "That base is LOCKED! Its pets can't be stolen right now.")
		elseif deps.CarryService.IsCarrying(player) then
			deps.Notice(player, "Your hands are full! You can't steal while carrying a pet.")
		else
			deps.CarryService.RemovePlaced(pad, false)
			prompt:Destroy()
			if deps.CarryService.Carry(player, current.Model) then
				deps.Notice(player, string.format("You stole %s! Run it home to your base!", current.Model:GetAttribute("PetName")))
				local owner = current.Owner
				if owner then
					deps.Notice(owner, string.format("A thief stole your %s! Lock your base!", current.Model:GetAttribute("PetName")))
				end
			else
				-- Nowhere to carry it: put it straight back on the pad.
				deps.CarryService.RegisterPlaced(pad, current.Model, current.Owner)
				addPlacedPetPrompt(base, pad)
			end
		end
	end)
end

-- The lock button prompt: owner only, 60 s of lock, then cooldown.
function addLockPrompt(base)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "LockPrompt"
	prompt.ActionText = "Lock Base"
	prompt.ObjectText = "Lock Button (60s)"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.Parent = base.LockButton

	prompt.Triggered:Connect(function(player)
		if base.Owner ~= player then
			deps.Notice(player, "This is not your base!")
			return
		end
		local now = os.clock()
		if now < base.CooldownUntil then
			deps.Notice(player, string.format("Lock recharging: %d s left.", math.ceil(base.CooldownUntil - now)))
			return
		end
		base.LockedUntil = now + LOCK_DURATION
		base.CooldownUntil = now + LOCK_DURATION + LOCK_COOLDOWN
		deps.Notice(player, "Base LOCKED for 60 seconds! Nobody can steal your pets.")
	end)
end

-- Give a joining player the first free base (nil when all four are taken;
-- extra players can still buy, carry and steal, they just have no pads).
function BaseService.AssignBase(player)
	for _, base in ipairs(bases) do
		if not base.Owner then
			base.Owner = player
			baseByPlayer[player] = base
			base.OwnerLabel.Text = string.upper(player.DisplayName) .. "'S BASE"
			player:SetAttribute("LockStatus", "Base: Unlocked")
			return base
		end
	end
	return nil
end

function BaseService.GetBase(player)
	return baseByPlayer[player]
end

-- Free a leaving player's base: their pets are destroyed by init via
-- CarryService.ClearPlayer; here we just reset ownership and the sign.
function BaseService.ReleaseBase(player)
	local base = baseByPlayer[player]
	if not base then
		return
	end
	baseByPlayer[player] = nil
	base.Owner = nil
	base.LockedUntil = 0
	base.CooldownUntil = 0
	base.OwnerLabel.Text = "UNCLAIMED BASE"
end

-- Keep every base owner's LockStatus attribute current for the HUD.
function BaseService.Start()
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.clock()
			for _, base in ipairs(bases) do
				local owner = base.Owner
				if owner then
					if now < base.LockedUntil then
						owner:SetAttribute("LockStatus", string.format("Base: LOCKED (%ds)", math.ceil(base.LockedUntil - now)))
					elseif now < base.CooldownUntil then
						owner:SetAttribute("LockStatus", string.format("Base: Unlocked (lock ready in %ds)", math.ceil(base.CooldownUntil - now)))
					else
						owner:SetAttribute("LockStatus", "Base: Unlocked (lock ready)")
					end
				end
			end
		end
	end)
end

return BaseService
