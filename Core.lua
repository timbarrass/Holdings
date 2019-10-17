Holdings = LibStub("AceAddon-3.0"):NewAddon("Holdings", "AceConsole-3.0", "AceEvent-3.0")

-- ---------------------------------------------------------------------------------------
-- General variables
-- ---------------------------------------------------------------------------------------
local frame = CreateFrame("FRAME", "HoldingsAddonFrame");
local context = ""
local holdings = {}

-- ---------------------------------------------------------------------------------------
-- Standard Ace addon state handlers
-- ---------------------------------------------------------------------------------------
function Holdings:OnInitialize()
    -- Called when the addon is loaded
end

function Holdings:OnEnable()
    -- Called when the addon is enabled

    frame:RegisterEvent("CHAT_MSG_LOOT")

    self:Print("Holdings enabled.");

    holdings = BuildHoldings()
    ShowHoldings()
end

function Holdings:OnDisable()
    -- Called when the addon is disabled
end

-- ---------------------------------------------------------------------------------------
-- WoW event handling
-- ---------------------------------------------------------------------------------------
local function eventHandler(self, event, ...)
    
    print("Rx: " .. event);

    if event == "CHAT_MSG_LOOT" then
        text, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ = ...
        loot = (string.match(text, "%[(.-)%]"))
        AddHolding("loot", loot)
    end

end

frame:SetScript("OnEvent", eventHandler);

-- ---------------------------------------------------------------------------------------
-- Utility functions
-- ---------------------------------------------------------------------------------------

function AddHolding(context, item)
    print("Add " .. context .. " " .. item)
    if holdings[item] then
        holdings[item] = holdings[item] + 1
    else
        holdings[item] = 1
    end
end

function BuildHoldings()
	local newHoldings = {}
	for i = 0,4,1
	do
		slots = GetContainerNumSlots(i)
		for j = 1,slots,1
		do
            _, itemCount, _, _, _, _, itemLink, _, _, _ = GetContainerItemInfo(i,j);
            itemName, _, _, _, _, _, _, _, _, _, _ = GetItemInfo(itemLink)
			if (itemCount == nil) then
			else
				if (newHoldings[itemName]) then
					newHoldings[itemName] = newHoldings[itemName] + itemCount;
				else
					newHoldings[itemName] = itemCount;
				end
			end
		end
	end

	return newHoldings;
end

function ShowHoldings()
    print("HOLDINGS")
    for i in pairs(holdings) do
		print("Holding: " .. i .. " " .. holdings[i]);
	end
	print("Cash: " .. GetMoney())
end
