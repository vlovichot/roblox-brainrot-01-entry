-- HudClient: the Brainrot Pet Bazaar heads-up display.
-- Top-centre (the top-left corner stays clear for Roblox's own menu):
-- cash, income per second with the rebirth multiplier, and rebirth count.
-- Below that, the big GRAVY TSUNAMI warning banner, one-line notices
-- from the server, and the base lock status along the bottom.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function formatMoney(amount)
	amount = math.floor(amount)
	if amount >= 1000000 then
		return string.format("%.2fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("%.1fK", amount / 1000)
	end
	return tostring(amount)
end

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local function makeLabel(name, size, position, anchorPoint, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.AnchorPoint = anchorPoint
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextSize = textSize
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.4
	label.Text = ""
	label.Parent = gui
	return label
end

local cashLabel = makeLabel("CashLabel", UDim2.new(0.5, 0, 0, 44), UDim2.new(0.5, 0, 0, 8), Vector2.new(0.5, 0), 34, Color3.fromRGB(120, 255, 140))
local rateLabel = makeLabel("RateLabel", UDim2.new(0.5, 0, 0, 26), UDim2.new(0.5, 0, 0, 52), Vector2.new(0.5, 0), 20, Color3.fromRGB(255, 255, 255))
local rebirthLabel = makeLabel("RebirthLabel", UDim2.new(0.5, 0, 0, 22), UDim2.new(0.5, 0, 0, 78), Vector2.new(0.5, 0), 16, Color3.fromRGB(220, 170, 255))

local bannerLabel = makeLabel("WaveBanner", UDim2.new(0.8, 0, 0, 60), UDim2.new(0.5, 0, 0.2, 0), Vector2.new(0.5, 0.5), 40, Color3.fromRGB(255, 90, 60))
bannerLabel.Visible = false

local noticeLabel = makeLabel("NoticeLabel", UDim2.new(0.8, 0, 0, 30), UDim2.new(0.5, 0, 1, -64), Vector2.new(0.5, 1), 20, Color3.fromRGB(255, 240, 150))
local lockLabel = makeLabel("LockLabel", UDim2.new(0.8, 0, 0, 26), UDim2.new(0.5, 0, 1, -34), Vector2.new(0.5, 1), 18, Color3.fromRGB(255, 255, 255))

-- Live stats: cash and rebirths come from leaderstats, the income rate
-- and multiplier from player attributes the server updates every second.
local leaderstats = player:WaitForChild("leaderstats")
local cashValue = leaderstats:WaitForChild("Cash")
local rebirthsValue = leaderstats:WaitForChild("Rebirths")

local function refreshStats()
	cashLabel.Text = "$" .. formatMoney(cashValue.Value)
	local rate = player:GetAttribute("IncomePerSecond") or 0
	local multiplier = player:GetAttribute("IncomeMultiplier") or 1
	rateLabel.Text = string.format("$%s/s  (x%.1f)", formatMoney(rate), multiplier)
	rebirthLabel.Text = string.format("Rebirths: %d", rebirthsValue.Value)
end

cashValue.Changed:Connect(refreshStats)
rebirthsValue.Changed:Connect(refreshStats)
player:GetAttributeChangedSignal("IncomePerSecond"):Connect(refreshStats)
player:GetAttributeChangedSignal("IncomeMultiplier"):Connect(refreshStats)
refreshStats()

local function refreshLock()
	lockLabel.Text = player:GetAttribute("LockStatus") or ""
end
player:GetAttributeChangedSignal("LockStatus"):Connect(refreshLock)
refreshLock()

-- Server notices: show for 3.5 s; a newer notice replaces the old one.
local noticeToken = 0
ReplicatedStorage:WaitForChild("GameNotice").OnClientEvent:Connect(function(text)
	noticeToken += 1
	local myToken = noticeToken
	noticeLabel.Text = text
	task.delay(3.5, function()
		if noticeToken == myToken then
			noticeLabel.Text = ""
		end
	end)
end)

-- Wave phases from WaveService: warning, then the sweep, then clear.
ReplicatedStorage:WaitForChild("WaveWarning").OnClientEvent:Connect(function(phase)
	if phase == "warning" then
		bannerLabel.Text = "GRAVY TSUNAMI INCOMING! GET TO A BASE!"
		bannerLabel.Visible = true
	elseif phase == "sweep" then
		bannerLabel.Text = "GRAVY TSUNAMI!"
		bannerLabel.Visible = true
	elseif phase == "clear" then
		bannerLabel.Visible = false
	end
end)
