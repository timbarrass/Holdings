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

    frame:RegisterEvent("LOOT_OPENED")
    frame:RegisterEvent("ITEM_PUSH")
    frame:RegisterEvent("LOOT_CLOSED")
    frame:RegisterEvent("PLAYER_MONEY");

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

    if event == "LOOT_OPENED" then
        context = "LOOT"
    end

end

frame:SetScript("OnEvent", eventHandler);

-- ---------------------------------------------------------------------------------------
-- Utility functions
-- ---------------------------------------------------------------------------------------

function UpdateHoldings()
	print("Handling holdings change");
	local newHoldings = holdings();
	for i in pairs(newHoldings) do
		if (holdings[i]) then
			if (holdings[i] == newHoldings[i]) then
			else
				print("Delta: "..i.." "..holdings[i].." > "..newHoldings[i]);
			end
		end
	end
	holdings = newHoldings;
end

function BuildHoldings()
	local newHoldings = {}
	for i = 0,4,1
	do
		slots = GetContainerNumSlots(i)
		for j = 1,slots,1
		do
			icon, itemCount, locked, quality, readable, lootable, itemLink, isFiltered, noValue, itemID = GetContainerItemInfo(i,j);
			if (itemCount == nil) then
			else
				if (newHoldings[itemLink]) then
					newHoldings[itemLink] = newHoldings[itemLink] + itemCount;
				else
					newHoldings[itemLink] = itemCount;
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
