--- STEAMODDED HEADER
--- MOD_NAME: Emergence
--- MOD_ID: SnoresvilleEmergence
--- MOD_AUTHOR: [Snoresville]
--- MOD_DESCRIPTION: 177013
--- BADGE_COLOUR: 177013

----------------------------------------------
------------MOD CODE -------------------------

local EMERGENCE_BREAK_DENOMINATOR = 8
local DECK_NAME = "Metamorphosis Deck"

local mod_localization = {
    joker_description = {
        name = "Emergence",
        text = {
            "If a scoring card is not a",
            "{C:attention}Red Seal Polychrome Steel King of Hearts{},",
            "partially transform the card towards it,",
            "{C:green}#1# in #2#{} chance of breaking the card instead." -- #1# and #2# refer to values from loc_def
        }
    },
    metamorphosis_deck_description = {
        name = DECK_NAME,
        text = {
            "Start with an",
            "eternal {C:attention}Emergence{},",
            "and a Deck full of",
            "{C:attention}Ace of Spades{}."
        },
    }
}

-------------------------------------------------
-- Utility functions to help make this joker work
---
local function get_card_value_code(card)
    return (card.base.value == 'Ace' and 'A') or
    (card.base.value == 'King' and 'K') or
    (card.base.value == 'Queen' and 'Q') or
    (card.base.value == 'Jack' and 'J') or
    (card.base.value == '10' and 'T') or
    (card.base.value)
end

local function get_card_suit_code(card)
    return string.sub(card.base.suit, 1, 1)
end

-- Goal: Red Seal Polychrome Steel King of Hearts
local function card_is_rshskoh(card)
    -- sendDebugMessage("This card...")
    -- sendDebugMessage(card.seal or "no seal")
    -- sendDebugMessage(card.edition and (card.edition.polychrome and "polychrome") or "not polychrome")
    -- sendDebugMessage(card.ability and card.ability.name or "no ability")
    -- sendDebugMessage(get_card_value_code(card))
    -- sendDebugMessage(get_card_suit_code(card))
    return card.seal == 'Red'
    and card.edition and card.edition.polychrome
    and card.ability and card.ability.name == 'Steel Card'
    and get_card_value_code(card) == 'K'
    and get_card_suit_code(card) == 'H'
end

local function choose_metamorphosis_upgrade(card)
    local special_upgrades = {}

    if card.seal ~= 'Red' then
        special_upgrades[#special_upgrades + 1] = "SEAL"
    end
    if not (card.edition and card.edition.polychrome) then
        special_upgrades[#special_upgrades + 1] = "POLYCHROME"
    end
    if not (card.ability and card.ability.name == 'Steel Card') then
        special_upgrades[#special_upgrades + 1] = "STEEL"
    end
    if get_card_suit_code(card) ~= 'H' then
        special_upgrades[#special_upgrades + 1] = "SUIT"
    end

    local valueGoal = 13
    local valueCurrent = get_card_value_code(card)
    valueCurrent = (valueCurrent == 'K' and 13) or
    (valueCurrent == 'Q' and 12) or
    (valueCurrent == 'J' and 11) or
    (valueCurrent == 'T' and 10) or
    (valueCurrent == 'A' and 1) or
    tonumber(valueCurrent)
    local valueDifference = valueGoal - valueCurrent

    local weights = #special_upgrades + valueDifference * 4
    local choice = math.random(weights)

    if choice <= #special_upgrades then
        return special_upgrades[choice]
    end
    return "VALUE"
end

local function apply_metamorphosis_upgrade(card)
    local upgrade = choose_metamorphosis_upgrade(card)

    if upgrade == "SEAL" then
        card:set_seal('Red', nil, true)
    elseif upgrade == "POLYCHROME" then
        card:set_edition({polychrome = true}, true)
    elseif upgrade == "STEEL" then
        card:set_ability(G.P_CENTERS.m_steel)
    elseif upgrade == "SUIT" then
        local card_value = get_card_value_code(card)
        card:set_base(G.P_CARDS["H_"..card_value])
    elseif upgrade == "VALUE" then
        local card_suit = get_card_suit_code(card)
        local card_value_current = get_card_value_code(card)
        local card_upgrade = (card_value_current == 'A' and '2') or
        (card_value_current == '2' and '3') or
        (card_value_current == '3' and '4') or
        (card_value_current == '4' and '5') or
        (card_value_current == '5' and '6') or
        (card_value_current == '6' and '7') or
        (card_value_current == '7' and '8') or
        (card_value_current == '8' and '9') or
        (card_value_current == '9' and 'T') or
        (card_value_current == 'T' and 'J') or
        (card_value_current == 'J' and 'Q') or 'K'
        card:set_base(G.P_CARDS[card_suit.."_"..card_upgrade])
    end

    return card
end

-- Me prototyping to find out if I could do this in the first place
local function super_metamorphosis(card)
    card:set_base(G.P_CARDS["H_K"])             -- number and suit
    card:set_ability(G.P_CENTERS.m_steel)       -- gold card, steel card, those kinds
    card:set_seal('Red', nil, true)             -- seal type,
    card:set_edition({polychrome = true}, true) -- edition, immediate, silent
end

--------------------------------------------------------
-- Joker Logic
--
-- SELF COULD BE ANYTHING!!!!!!!!!!!!!!!!!
-- CONTEXT COULD BE ANYTHING!!!!!!!!!
-- UNZIP BALATRO.EXE AND FIND OUT EVERYTHING!!!!!!!!!!!!
local function joker_emergence(self, context)
    -- sendDebugMessage("Context is coming")
    -- for k, v in pairs(context) do
    --     sendDebugMessage(k)
    --     sendDebugMessage(v)
    -- end
    if context.cardarea == G.jokers and context.after and context.scoring_hand then
        local emergenceCards = {}

        for i, card in ipairs(context.scoring_hand) do
            if not card_is_rshskoh(card) then
                emergenceCards[#emergenceCards + 1] = card
            end
        end

        if #emergenceCards == 0 then
            return
        end

        -- Flip the cards over for suspense...
        for i, card in ipairs(emergenceCards) do
            G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.15, func = function()
                play_sound('card1')
                card:flip()
                return true
            end}))
        end
        delay(0.2)

        -- This is where I transform the cards
        for i, card in ipairs(emergenceCards) do
            if not card.destroyed and not card.shattered then
                card_eval_status_text(card, 'extra', nil, nil, nil, {message = "Emerging!"})
                G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.1, func = function()
                    -- super_metamorphosis(card) -- too much power...
                    apply_metamorphosis_upgrade(card)
                    return true
                end}))
            end
        end

        -- Unflip it for the fans
        for i, card in ipairs(emergenceCards) do
            G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.15, func = function()
                play_sound('tarot2')
                card:flip()
                card:juice_up(0.3, 0.3)
                return true
            end}))
        end

        delay(#emergenceCards * 0.15 + 0.5)

    -- This phase happens just after scoring but before triggering the joker aftermath
    elseif context.destroying_card then
        local card = context.destroying_card
        if not card_is_rshskoh(card) and pseudorandom('177013') < G.GAME.probabilities.normal/EMERGENCE_BREAK_DENOMINATOR then
            card_eval_status_text(context.destroying_card, 'extra', nil, nil, nil, {
                message = "Broken...",
                colour = G.C.RED
            })

            -- Returning true here means that the card is DESTROYED!!
            return true
        end
    end
end

-- So some numbers have to be localized.
-- Good practice to use variables here
local function joker_emergence_loc_def(self)
    return {G.GAME.probabilities.normal, EMERGENCE_BREAK_DENOMINATOR}
end

--
-- SETUP STOLEN FROM MOREFLUFF, THANKS!!!
--
function SMODS.INIT.SnoresvilleEmergence()
    sendDebugMessage("Emergence is coming")

    local localization = {
        snoresville_emergence = mod_localization["joker_description"]
    }
    init_localization()

    --[[SMODS.Joker:new(
        name, slug,
        config,
        spritePos, loc_txt,
        rarity, cost, unlocked, discovered, blueprint_compat, eternal_compat
    )
    ]]
    local jokers = {
        snoresville_emergence = SMODS.Joker:new(
        "Emergence", "",
        {},
        {x = 0, y = 0}, "",
        1,    -- Rarity
        2,    -- Cost
        true, -- Unlocked
        true, -- Discovered
        true, -- Blueprint Compatible
        true  -- Eternal Compatible
        ),
    }

    -- Order the jokers
    local joker_order_thing = {}

    for k, v in pairs(jokers) do
        local j = {}
        j.name = v.name
        j.rarity = v.rarity
        j.slug = k
        table.insert(joker_order_thing, j)
    end

    table.sort(joker_order_thing, function(a, b)
        if a.rarity ~= b.rarity then
            return a.rarity < b.rarity
        end
        return a.name < b.name
    end)

    for i, j in ipairs(joker_order_thing) do
        local k = j.slug
        local v = jokers[k]

        v.slug = "j_" .. k
        v.loc_txt = localization[k]
        v.mod = "SnoresvilleEmergence"
        v:register()

        SMODS.Sprite:new(v.slug, SMODS.findModByID("SnoresvilleEmergence").path, v.slug..".png", 71, 95, "asset_atli")
        :register()
    end

    -- Apply logic
    SMODS.Jokers.j_snoresville_emergence.calculate = joker_emergence
    SMODS.Jokers.j_snoresville_emergence.loc_def = joker_emergence_loc_def
end

-------------------------------------
-- ADDING A DECK - METAMORPHOSIS DECK

local Backapply_to_runRef = Back.apply_to_run
function Back.apply_to_run(arg_56_0)
	Backapply_to_runRef(arg_56_0)

	if arg_56_0.effect.config.snoresvilleMetamorphosisDeck then
		G.E_MANAGER:add_event(Event({
			func = function()
                -- Converts all cards in deck to Ace of Spades
                -- Can do something even fancier, but I am satisfied here.
				for iter_57_0 = #G.playing_cards, 1, -1 do
                    local card = G.playing_cards[iter_57_0]

                    local suit = get_card_suit_code(card)
                    local value = 'A'
					card:set_base(G.P_CARDS['S_A'])
				end
                add_joker('j_snoresville_emergence', nil, nil, true)

				return true
			end
		}))
	end
end

-- IDK what the arguments mean, can someone document the API
local metaDeck = SMODS.Deck:new(DECK_NAME, "snoresvilleMetamorphosis", {snoresvilleMetamorphosisDeck = true}, {x = 0, y = 4}, mod_localization["metamorphosis_deck_description"])
metaDeck:register()