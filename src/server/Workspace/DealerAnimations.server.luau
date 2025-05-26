for i, v in pairs(workspace:GetDescendants()) do
	if v:IsA("Model") and v.Name == "dealer" then
		local animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://103302331702500"
		local hum = v:FindFirstChild("Humanoid")
		local track = hum:LoadAnimation(animation)
		track.Priority = Enum.AnimationPriority.Core
		track:Play()
	end
end
