Holdings = LibStub("AceAddon-3.0"):NewAddon("Holdings", "AceConsole-3.0", "AceEvent-3.0")

-- ---------------------------------------------------------------------------------------
-- General variables and declarations
-- ---------------------------------------------------------------------------------------
local frame = CreateFrame("FRAME", "HoldingsAddonFrame");
local rememberedBag, rememberedSlot, rememberedName, rememberedGold, extendedState = ""
local currentHoldings = {}

local Loot, Record, RememberItemLocation, RememberItemCount, RememberState, CountDifference
local RememberGold, CalculateCost, Remove, PollHoldings, ShowHoldings

-- ---------------------------------------------------------------------------------------
-- Standard Ace addon state handlers
-- ---------------------------------------------------------------------------------------
function Holdings:OnInitialize()
    -- Called when the addon is loaded
end

function Holdings:OnEnable()
    -- Called when the addon is enabled

    frame:RegisterEvent("CHAT_MSG_LOOT")
    frame:RegisterEvent("ITEM_LOCKED")
    frame:RegisterEvent("DELETE_ITEM_CONFIRM")
    frame:RegisterEvent("BAG_UPDATE")
    frame:RegisterEvent("MERCHANT_SHOW")
    frame:RegisterEvent("MERCHANT_CLOSED")
    frame:RegisterEvent("PLAYER_MONEY")
    frame:RegisterEvent("MAIL_SHOW")
    frame:RegisterEvent("MAIL_CLOSED")

    Holdings:RegisterChatCommand("holdings", "HoldingsCommand")

    RememberGold()

    Holdings:Print("Holdings enabled.")
end

function Holdings:OnDisable()
    -- Called when the addon is disabled
end

-- ---------------------------------------------------------------------------------------
-- Slash command handlers
-- ---------------------------------------------------------------------------------------
function Holdings:HoldingsCommand(params)
    currentHoldings = PollHoldings()
    ShowHoldings()
end


-- ---------------------------------------------------------------------------------------
-- Utility functions
-- ---------------------------------------------------------------------------------------
function Record(inout, context, msg, itemCount)
    print(inout..","..context..","..msg..","..itemCount)
end

function RememberItemLocation(bag, slot)
    rememberedBag = bag
    rememberedSlot = slot
    _, itemCount, _, _, _, _, itemLink, _, _, _ = GetContainerItemInfo(rememberedBag, rememberedSlot)
    local itemName = string.match(itemLink, "%[(.-)%]")
    rememberedName = itemName
end

function RememberItemCount(bag, slot)
    _, itemCount, _, _, _, _, itemLink, _, _, _ = GetContainerItemInfo(rememberedBag, rememberedSlot)
    rememberedCount = itemCount
end

function CountDifference(bag, slot)
    _, itemCount, _, _, _, _, itemLink, _, _, _ = GetContainerItemInfo(rememberedBag, rememberedSlot)
    local diff = itemCount
    if (rememberedCount ~= nil) then
        diff = rememberedCount - itemCount
    end
    return diff
end

function Remove()
    local diff = CountDifference(rememberedBag, rememberedSlot)
    local removeContext = "destroy"
    if (extendedState == "mail") then
        removeContext = "mail"
    end
    Record("out", removeContext, rememberedName, diff)
    RememberState("", "")
end

function Loot(text, playerName)
    local item = string.match(text, "%[(.-)%]")
    local itemCount = string.match(text, "[0-9]+$")
    if (itemCount == nil) then
        itemCount = 1
    end
    local lootContext = "loot"
    if (extendedState == "merchant") then
        lootContext = "merchant"
    elseif (extendedState == "mail") then
        lootContext = "mail"
    end
    if (playerName == UnitName("player")) then
        Record("in", lootContext, item, itemCount)
    end
end

function RememberState(state, item)
    extendedState = state
    rememberedName = item
end

function RememberGold()
    rememberedGold = GetMoney()
end

function CalculateCost(gold)
    local diff = gold - rememberedGold
    local inout = "out"
    if (diff > -1) then
        inout = "in"
    end
    local costContext = "loot"
    if (extendedState == "merchant") then
        costContext = "merchant"
    elseif (extendedState == "mail") then
        costContext = "mail"
    end
    Record(inout, costContext, "", diff)
    RememberGold()
end

function PollHoldings()
	local newHoldings = {}
	for bag = 0,4,1
	do
		slots = GetContainerNumSlots(bag)
		for slot = 1,slots,1
		do
			icon, itemCount, locked, quality, readable, lootable, itemLink, isFiltered, noValue, itemID = GetContainerItemInfo(bag,slot);
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
	for i in pairs(currentHoldings) do
		print("Holding: "..i.." "..currentHoldings[i]);
	end
	print("Cash: "..GetMoney())
end



-- ---------------------------------------------------------------------------------------
-- WoW event handling -- basically the app body, define here as a backstop in case I've
-- not declared one or more functions, variables. For each event parse args and call a
-- descriptive method
-- ---------------------------------------------------------------------------------------
local function eventHandler(self, event, ...)
    
    print("Rx: " .. event);

    if (event == "CHAT_MSG_LOOT") then
        text, _, _, _, playerName, _, _, _, _, _, _, _, _, _, _, _, _ = ...
        Loot(text, playerName)
    elseif (event == "ITEM_LOCKED") then
        bag, slot = ...
        RememberItemLocation(bag, slot)
        RememberGold()
    elseif (event == "DELETE_ITEM_CONFIRM") then
        itemName, _, _, _ = ...
        RememberState("destroying", itemName)
        RememberItemCount(rememberedBag, rememberedSlot)
    elseif (event == "BAG_UPDATE") then
        Remove()
    elseif (event == "MERCHANT_SHOW") then
        RememberState("merchant", "")
        RememberGold()
    elseif (event == "MERCHANT_CLOSED") then
        RememberState("", "")
    elseif (event == "PLAYER_MONEY") then
        local currentGold = GetMoney()
        CalculateCost(currentGold)
    elseif (event == "MAIL_SHOW") then
        RememberState("mail")
    elseif (event == "MAIL_CLOSED") then
        RememberState("", "")
    end

end

local function onLoadHandler()
    RememberGold()

    print("Holdings loaded")
end

frame:SetScript("OnLoad", onLoadHandler)
frame:SetScript("OnEvent", eventHandler);
