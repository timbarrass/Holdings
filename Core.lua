Holdings = LibStub("AceAddon-3.0"):NewAddon("Holdings", "AceConsole-3.0", "AceEvent-3.0")

-- ---------------------------------------------------------------------------------------
-- General variables and declarations
-- ---------------------------------------------------------------------------------------
local frame = CreateFrame("FRAME", "HoldingsAddonFrame");
local rememberedBag, rememberedSlot, rememberedName, extendedState

local Loot, Record, RememberItemLocation, RememberItemCount, RememberState, CountDifference

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

    print("Holdings enabled.")
end

function Holdings:OnDisable()
    -- Called when the addon is disabled
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
end

function RememberItemCount(bag, slot)
    _, itemCount, _, _, _, _, itemLink, _, _, _ = GetContainerItemInfo(rememberedBag, rememberedSlot)
    rememberedCount = itemCount
end

function CountDifference(bag, slot)
    _, itemCount, _, _, _, _, itemLink, _, _, _ = GetContainerItemInfo(rememberedBag, rememberedSlot)
    return rememberedCount - itemCount
end


function Loot(text, playerName)
    local item = string.match(text, "%[(.-)%]")
    local itemCount = string.match(text, "[0-9]+")
    if (itemCount == nil) then
        itemCount = 1
    end
    if (playerName == UnitName("player")) then
        Record("in", "loot", item, itemCount)
    end
end

function RememberState(state, item)
    extendedState = state
    rememberedName = item
end

-- ---------------------------------------------------------------------------------------
-- WoW event handling -- basically the app body, define here as a backstop in case I've
-- not declared one or more functions, variables. For each event parse args and call a
-- descriptive method
-- ---------------------------------------------------------------------------------------
local function eventHandler(self, event, ...)
    
    print("Rx: " .. event);

    if (event == "CHAT_MSG_LOOT") then
        text, playerName, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ = ...
        Loot(text, playerName)
    elseif (event == "ITEM_LOCKED") then
        bag, slot = ...
        RememberItemLocation(bag, slot)
    elseif (event == "DELETE_ITEM_CONFIRM") then
        itemName, _, _, _ = ...
        RememberState("destroying", itemName)
        RememberItemCount(rememberedBag, rememberedSlot)
    elseif (event == "BAG_UPDATE") then
        if (extendedState == "destroying") then
            local diff = CountDifference(rememberedBag, rememberedSlot)
            Record("out", "destroy", rememberedName, diff)
            RememberState("", "")
        end
    end

end

frame:SetScript("OnEvent", eventHandler);
