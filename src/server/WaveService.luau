-- WaveService: the GRAVY TSUNAMI. Every ~100 s a warning goes out, and
-- 10 s later a wall of foam sweeps the plaza from the spawn arch to the
-- far end. A player caught in the open while carrying a pet loses it --
-- the wave washes it back to the start of the conveyor. Standing on any
-- base platform is shelter.

local WaveService = {}

local WAVE_INTERVAL = 100 -- seconds between waves
local WARNING_TIME = 10 -- seconds of warning before the wall moves
local SWEEP_TIME = 7 -- seconds the wall takes to cross the plaza
local WALL_THICKNESS = 4

local deps = nil

function WaveService.Init(dependencies)
	deps = dependencies
end

-- Shelter check: standing on any base platform keeps you (and your pet)
-- safe from the wave.
local function isSheltered(position)
	local half = deps.World.PlatformSize.X / 2
	for _, base in ipairs(deps.World.Bases) do
		if math.abs(position.X - base.Center.X) <= half and math.abs(position.Z - base.Center.Z) <= half then
			return true
		end
	end
	return false
end

local function runWave()
	local wall = Instance.new("Part")
	wall.Name = "GravyTsunamiWall"
	wall.Size = Vector3.new(WALL_THICKNESS, 15, 2 * 62)
	wall.Color = Color3.fromRGB(255, 176, 66) -- gravy orange
	wall.Material = Enum.Material.Glass
	wall.Transparency = 0.3
	wall.Anchored = true
	wall.CanCollide = false
	wall.CanQuery = false
	local startX = deps.World.LaneStartX - 8
	local endX = deps.World.LaneEndX + 8
	wall.CFrame = CFrame.new(startX, 7.5, 0)
	wall.Parent = workspace

	local elapsed = 0
	while elapsed < SWEEP_TIME do
		local deltaTime = task.wait()
		elapsed += deltaTime
		local wallX = startX + (endX - startX) * math.min(elapsed / SWEEP_TIME, 1)
		wall.CFrame = CFrame.new(wallX, 7.5, 0)
		-- Catch every carrier in the open as the wall passes over them.
		for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
			if deps.CarryService.IsCarrying(player) then
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root and math.abs(root.Position.X - wallX) < WALL_THICKNESS and not isSheltered(root.Position) then
					if deps.CarryService.DropCarriedToWave(player) then
						deps.Notice(player, "The GRAVY TSUNAMI washed your pet back to the conveyor!")
					end
				end
			end
		end
	end
	wall:Destroy()
end

function WaveService.Start()
	task.spawn(function()
		while true do
			task.wait(WAVE_INTERVAL)
			deps.WaveRemote:FireAllClients("warning")
			task.wait(WARNING_TIME)
			deps.WaveRemote:FireAllClients("sweep")
			runWave()
			deps.WaveRemote:FireAllClients("clear")
		end
	end)
end

return WaveService
