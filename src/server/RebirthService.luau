-- RebirthService: the shrine at the back of the plaza. Paying the
-- (steeply scaling) cost wipes your cash back to the starting amount and
-- destroys every pet you own -- carried and placed -- in exchange for a
-- permanent +50% income multiplier per rebirth, applied by
-- EconomyService. The trade is confirmed by a 1 s hold on the prompt so
-- nobody rebirths by accident.

local RebirthService = {}

local BASE_COST = 10000
local COST_GROWTH = 4 -- each rebirth costs 4x the previous one

local deps = nil

function RebirthService.Init(dependencies)
	deps = dependencies
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RebirthPrompt"
	prompt.ActionText = "Rebirth"
	prompt.ObjectText = "Rebirth Shrine (+50% income forever)"
	prompt.HoldDuration = 1
	prompt.MaxActivationDistance = 12
	prompt.Parent = deps.World.ShrineCrystal

	prompt.Triggered:Connect(function(player)
		local rebirths = deps.EconomyService.GetRebirths(player)
		local cost = RebirthService.CostFor(rebirths)
		if not deps.EconomyService.TrySpend(player, cost) then
			deps.Notice(player, string.format("Rebirth costs $%s. You need more cash!", RebirthService.FormatCost(cost)))
			return
		end
		-- The sacrifice: every pet goes, cash resets to the starting purse.
		deps.CarryService.ClearPlayer(player)
		deps.EconomyService.SetCash(player, deps.EconomyService.StartingCash)
		deps.EconomyService.AddRebirth(player)
		deps.Notice(player, string.format(
			"REBIRTH! Income is now x%.1f forever. Your pets are gone -- rebuild, richer!",
			deps.EconomyService.GetMultiplier(player)
		))
	end)
end

-- Cost of the next rebirth for a player who already has `rebirths`.
function RebirthService.CostFor(rebirths)
	return math.floor(BASE_COST * (COST_GROWTH ^ rebirths))
end

function RebirthService.FormatCost(cost)
	if cost >= 1000000 then
		return string.format("%.2fM", cost / 1000000)
	elseif cost >= 1000 then
		return string.format("%.1fK", cost / 1000)
	end
	return tostring(cost)
end

return RebirthService
