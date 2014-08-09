local nibRealUI = LibStub("AceAddon-3.0"):GetAddon("nibRealUI")

nibRealUI.LoadAddOnData_Aurora = function()
    AuroraConfig = {
        ["useButtonGradientColour"] = false,
        ["chatBubbles"] = false,
        ["bags"] = false,
        ["tooltips"] = false,
        ["loot"] = false,
        ["useCustomColour"] = false,
        ["enableFont"] = false,
        ["buttonSolidColour"] = {
            0.2, -- [1]
            0.2, -- [2]
            0.2, -- [3]
            1, -- [4]
        },
    }
end
