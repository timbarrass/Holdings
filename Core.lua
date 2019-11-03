Holdings = LibStub("AceAddon-3.0"):NewAddon("Holdings", "AceConsole-3.0", "AceEvent-3.0")

-- ---------------------------------------------------------------------------------------
-- General variables and declarations
-- ---------------------------------------------------------------------------------------
local frame = CreateFrame("FRAME", "HoldingsAddonFrame");
local rememberedName, rememberedGold, db
local rememberedBag = 0
local rememberedSlot = 0
local lootIndex = 0
local extendedState = ""
local acurrentHoldings = {}

local Loot, Record, RememberItemLocation, RememberItemCount, RememberState, CountDifference
local RememberGold, CalculateCost, Remove, PollHoldings, ShowHoldings, Timestamp

local character = UnitName("player")

-- ---------------------------------------------------------------------------------------
-- Standard Ace addon state handlers
-- ---------------------------------------------------------------------------------------
function Holdings:OnInitialize()
    -- Called when the addon is loaded

    self.db = LibStub("AceDB-3.0"):New("HoldingsDB")

    db = self.db

    if (db.char.money == nil)        then db.char.money = {} end
    if (db.char.transactions == nil) then db.char.transactions = {} end
    table.insert(db.char.money, rememberedGold)

    Holdings:Print("DB init")
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
    frame:RegisterEvent("TAXIMAP_OPENED")

    Holdings:RegisterChatCommand("holdings", "HoldingsCommand")
    Holdings:RegisterChatCommand("rememberGold", "RememberGoldCommand")

    RememberGold(self)

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

function Holdings:RememberGoldCommand(params)
    RememberGold(self)
end


-- ---------------------------------------------------------------------------------------
-- Utility functions
-- ---------------------------------------------------------------------------------------
function Timestamp()
    return time()
end

function Record(inout, context, msg, itemCount)
    if (msg == nil) then msg = "" end
    table.insert(db.char.transactions, Timestamp()..","..inout..","..context..","..msg..","..itemCount)
    Holdings:Print(Timestamp()..","..inout..","..context..","..msg..","..itemCount)
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
    if (extendedState ~= "") then
        local diff = CountDifference(rememberedBag, rememberedSlot)
        local removeContext = "destroy"
        if (extendedState == "mail") then
            removeContext = "mail"
        end
        Record("out", removeContext, rememberedName, diff)
        RememberState("", "")
    end
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

function RememberGold(self)
    rememberedGold = GetMoney()

    table.insert(db.char.money, Timestamp() .. "," .. rememberedGold)

    Holdings:Print(db.char.money[table.maxn(db.char.money)])
end

function CalculateCost(self, gold)
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
    elseif (extendedState == "taxi") then
        costContext = "taxi"
        RememberState("", "") -- do this here, as taximap closes before money event
    end
    Record(inout, costContext, "", diff)
    RememberGold(self)
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
        RememberGold(self)
    elseif (event == "DELETE_ITEM_CONFIRM") then
        itemName, _, _, _ = ...
        RememberState("destroying", itemName)
        RememberItemCount(rememberedBag, rememberedSlot)
    elseif (event == "BAG_UPDATE") then
        Remove()
    elseif (event == "MERCHANT_SHOW") then
        RememberState("merchant", "")
        RememberGold(self)
    elseif (event == "MERCHANT_CLOSED") then
        RememberState("", "")
    elseif (event == "PLAYER_MONEY") then
        local currentGold = GetMoney()
        CalculateCost(self, currentGold)
    elseif (event == "MAIL_SHOW") then
        RememberState("mail")
    elseif (event == "MAIL_CLOSED") then
        RememberState("", "")
    elseif (event == "TAXIMAP_OPENED") then
        RememberState("taxi")
    end

end

local function onLoadHandler()
    print("Holdings loaded")
end

frame:SetScript("OnLoad", onLoadHandler)
frame:SetScript("OnEvent", eventHandler);
