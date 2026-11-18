-- EconomyService: owns every player's money. Creates leaderstats
-- (Cash, Rebirths), runs the per-second income tick that pays out for
-- placed pets, and applies the permanent rebirth income multiplier.
-- All money changes in the game go through here -- server authoritative.

local Players = game:GetService("Players")

local EconomyService = {}

EconomyService.StartingCash = 100
EconomyService.IncomePerRebirth = 0.5 -- +50% income per rebirth, forever

local deps = nil
local fractions = {} -- [player] = fractional cash carried between ticks

function EconomyService.Init(dependencies)
	deps = dependencies
end

-- Create leaderstats and HUD attributes for a joining player.
function EconomyService.SetupPlayer(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = EconomyService.StartingCash
	cash.Parent = leaderstats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = leaderstats

	leaderstats.Parent = player

	player:SetAttribute("IncomePerSecond", 0)
	player:SetAttribute("IncomeMultiplier", 1)
	fractions[player] = 0
end

function EconomyService.CleanupPlayer(player)
	fractions[player] = nil
end

local function getStat(player, name)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return nil
	end
	return leaderstats:FindFirstChild(name)
end

function EconomyService.GetCash(player)
	local cash = getStat(player, "Cash")
	return cash and cash.Value or 0
end

function EconomyService.SetCash(player, amount)
	local cash = getStat(player, "Cash")
	if cash then
		cash.Value = math.max(0, math.floor(amount))
	end
end

function EconomyService.AddCash(player, amount)
	local cash = getStat(player, "Cash")
	if cash then
		cash.Value += math.floor(amount)
	end
end

-- Spend if the player can afford it. Returns true when the money was taken.
function EconomyService.TrySpend(player, amount)
	local cash = getStat(player, "Cash")
	if not cash or cash.Value < amount then
		return false
	end
	cash.Value -= amount
	return true
end

function EconomyService.GetRebirths(player)
	local rebirths = getStat(player, "Rebirths")
	return rebirths and rebirths.Value or 0
end

function EconomyService.AddRebirth(player)
	local rebirths = getStat(player, "Rebirths")
	if rebirths then
		rebirths.Value += 1
	end
	player:SetAttribute("IncomeMultiplier", EconomyService.GetMultiplier(player))
end

-- 1x income at 0 rebirths, +50% for each rebirth after that.
function EconomyService.GetMultiplier(player)
	return 1 + EconomyService.IncomePerRebirth * EconomyService.GetRebirths(player)
end

-- The per-second income tick: every placed pet pays its owner its $/s,
-- scaled by the owner's rebirth multiplier. Fractional payouts are
-- carried between ticks so a 1/s pet at 1.5x still pays 3 every 2 s.
function EconomyService.Start()
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local baseRate = deps.GetPlacedIncome(player)
				local payout = baseRate * EconomyService.GetMultiplier(player) + (fractions[player] or 0)
				local whole = math.floor(payout)
				fractions[player] = payout - whole
				if whole > 0 then
					EconomyService.AddCash(player, whole)
				end
				player:SetAttribute("IncomePerSecond", baseRate * EconomyService.GetMultiplier(player))
			end
		end
	end)
end

return EconomyService
