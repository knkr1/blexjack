local ContentProvider = game:GetService("ContentProvider")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local LoadingFrame = game.Players.LocalPlayer.PlayerGui:WaitForChild("LoadingScreen").MainFrame.LoadingFrame
local TweenService = game:GetService("TweenService")
local LoadingController = {
	loading = true,
	LoadingBarTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
	currentLoadingBarTween = nil,
}

function LoadingController:Init()
	LoadingController:SetupLoading()
	LoadingController:InterfaceLoad()
	LoadingController:LoadHandlers()
end

function LoadingController:SetupLoading()
	ReplicatedFirst:RemoveDefaultLoadingScreen()
	for i, v in pairs(game.Players.LocalPlayer.PlayerGui:WaitForChild("LoadingScreen"):GetDescendants()) do
		ContentProvider:PreloadAsync({ v })
		LoadingFrame.BarTemplate.LoadingBar.Size = UDim2.new(0, 0, 1, 0)
	end
	LoadingFrame.Parent.Parent.Enabled = true
	print("LoadingController setuploading done")
end

function LoadingController:InterfaceLoad()
	local assetTable = game:GetDescendants()
	local guiAssets = {}

	for _, asset in ipairs(assetTable) do
		if
			asset:IsA("GuiObject")
			or asset:IsA("TextLabel")
			or asset:IsA("TextButton")
			or asset:IsA("ImageLabel")
			or asset:IsA("ImageButton")
		then
			table.insert(guiAssets, asset)
		end
	end

	local totalAssets = #guiAssets
	print("Loading started", totalAssets)

	-- batch preload
	local batchSize = 10
	for i = 1, totalAssets, batchSize do
		local batch = {}
		for j = i, math.min(i + batchSize - 1, totalAssets) do
			table.insert(batch, guiAssets[j])
		end

		pcall(function()
			ContentProvider:PreloadAsync(batch)
		end)

		local progress = math.min(i + batchSize - 1, totalAssets) / totalAssets
		LoadingController:RequestLoadingBarTween(
			TweenService:Create(
				LoadingFrame.BarTemplate.LoadingBar,
				LoadingController.LoadingBarTweenInfo,
				{ Size = UDim2.new(progress, 0, 1, 0) }
			)
		)
	end
	LoadingFrame.status.Text = "Loaded!"
	wait(2)
	print("LoadingController InterfaceLoad done")
	LoadingFrame.Parent.Parent.Enabled = false
end

function LoadingController:RequestLoadingBarTween(tween)
	if LoadingController.currentLoadingBarTween ~= nil then
		LoadingController.currentLoadingBarTween:Cancel()
	end
	LoadingController.currentLoadingBarTween = tween
	LoadingController.currentLoadingBarTween:Play()
end

function LoadingController:LoadHandlers()
	for i, v in pairs(script.Parent.Handlers:GetDescendants()) do
		local _, r = pcall(function()
			require(v):Init()
		end)
		if r then
			warn(r)
		end
	end
	print("LoadingController LoadHandlers done")
end

return LoadingController
