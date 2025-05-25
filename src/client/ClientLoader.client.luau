game.Loaded:Wait()
print("Client Loaded")
for i, v in pairs(script.Parent:WaitForChild("Handlers"):GetChildren()) do
	if v:IsA("ModuleScript") then
		require(v):Init()
	end
end
