-- Brainrot Pet Bazaar -- server bootstrap.
-- Characters load normally (Players.CharacterAutoLoads is on in the
-- project file). This script builds the world, creates the two client
-- remotes, wires the services together, starts their loops, and handles
-- the player lifecycle: stats, a base, a teleport home on spawn, and
-- cleanup on leave.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldBuilder = require(script.WorldBuilder)
local EconomyService = require(script.EconomyService)
local CarryService = require(script.CarryService)
local BaseService = require(script.BaseService)
local ConveyorService = require(script.ConveyorService)
local WaveService = require(script.WaveService)
local RebirthService = require(script.RebirthService)

-- Remotes the client HUD listens to: one-line notices and wave phases.
local noticeRemote = Instance.new("RemoteEvent")
noticeRemote.Name = "GameNotice"
noticeRemote.Parent = ReplicatedStorage

local waveRemote = Instance.new("RemoteEvent")
waveRemote.Name = "WaveWarning"
waveRemote.Parent = ReplicatedStorage

local function notice(player, text)
	noticeRemote:FireClient(player, text)
end

-- Build the plaza before anyone spawns into it.
local world = WorldBuilder.Build()

-- Wire the services. CarryService is the pet registry EconomyService
-- reads for income; ConveyorService takes washed pets back from it.
CarryService.SetWashHandler(function(model)
	ConveyorService.ReclaimWashedPet(model)
end)
EconomyService.Init({
	GetPlacedIncome = function(player)
		return CarryService.GetPlacedIncome(player)
	end,
})
BaseService.Init({
	World = world,
	CarryService = CarryService,
	EconomyService = EconomyService,
	Notice = notice,
})
ConveyorService.Init({
	World = world,
	CarryService = CarryService,
	EconomyService = EconomyService,
	Notice = notice,
})
WaveService.Init({
	World = world,
	CarryService = CarryService,
	WaveRemote = waveRemote,
	Notice = notice,
})
RebirthService.Init({
	World = world,
	CarryService = CarryService,
	EconomyService = EconomyService,
	Notice = notice,
})

EconomyService.Start()
BaseService.Start()
ConveyorService.Start()
WaveService.Start()

local function onCharacterAdded(player, character)
	-- Respawn at your own base, and get your carried pet back overhead.
	task.wait(0.3)
	local base = BaseService.GetBase(player)
	local root = character:FindFirstChild("HumanoidRootPart")
	if base and root then
		character:PivotTo(base.SpawnCFrame)
	end
	CarryService.Reattach(player)
end

local function onPlayerAdded(player)
	EconomyService.SetupPlayer(player)
	BaseService.AssignBase(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

local function onPlayerRemoving(player)
	CarryService.ClearPlayer(player)
	BaseService.ReleaseBase(player)
	EconomyService.CleanupPlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
