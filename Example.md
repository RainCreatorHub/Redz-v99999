###### isso foi usado IA mas n usarei em outras coisas.
# inspirado na redz lib.

## All
``` lua
local RZ = loadstring(game:HttpGet("https://raw.githubusercontent.com/RainCreatorHub/Redz-v99999/refs/heads/main/Source.lua"))()
local lib = RZ.new("MinhaLib")

local tab1 = lib:createTab("Main")
local section1 = tab1:addSection("Player")
section1:addToggle("Auto Jump", false, function(state)
    print("AutoJump:", state)
end)
section1:addSlider("WalkSpeed", 16, 100, 16, function(val)
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = val
    end
end)
section1:addButton("Reset Speed", function()
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 16
    end
end)
local bindSection = tab1:addSection("Binds")
bindSection:addBind("Toggle UI", "R", function(key)
    print("Bind pressed or set to:", key)
end)

local configTab = lib:createTab("Config")
local sec = configTab:addSection("Options")
sec:addDropdown("Quality", {"Low","Medium","High"}, function(sel) print("Selecionou",sel) end)
sec:addColorPicker("Accent", Color3.fromRGB(96,165,250), function(c) print("Cor:", c) end)

```
