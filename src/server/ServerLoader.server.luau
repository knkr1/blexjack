for i, v in pairs(script.Parent:WaitForChild("Services"):GetChildren()) do
	if v:IsA("ModuleScript") then
		require(v):Init()
	end
end
