--- STEAMODDED HEADER
--- MOD_NAME: Emergence
--- MOD_ID: SnoresvilleEmergence
--- MOD_AUTHOR: [Snoresville]
--- MOD_DESCRIPTION: 177013
--- BADGE_COLOUR: 177013

----------------------------------------------
------------MOD CODE -------------------------

local MOD_ID = "SnoresvilleEmergence"
local DECK_NAME = "Metamorphosis Deck"
local EMERGENCE_BREAK_DENOMINATOR = 8

----------------------------------------------
-- DATA
local mod_localization = {
    joker_description = {
        snoresville_emergence = {
            name = "Emergence",
            text = {
                "If a scoring card is not a",
                "{C:attention}Red Seal Polychrome Steel King of Hearts{},",
                "partially transform the card towards it,",
                "{C:green}#1# in #2#{} chance of breaking the card instead." -- #1# and #2# refer to values from loc_def
            },
        }
    },
    deck_description = {
        metamorphosis_deck = {
            name = DECK_NAME,
            text = {
                "Start with an",
                "{C:attention}Eternal{} {C:dark_edition}Negative{} Emergence,",
                "and a Deck full of",
                "{C:attention}Ace of Spades{}."
            },
        },
    },
    misc = {
        emergence_upgrade_message = "Emerging!",
        emergence_broken_message = "Broken..."
    }
}

local metamorphosis_value_scaling = {
    ["A"] = '2',

    ["2"] = '5',
    ["3"] = '5',
    ["4"] = '5',

    ["5"] = '8',
    ["6"] = '8',
    ["7"] = '8',

    ["8"] = 'T',
    ["9"] = 'T',

    ["T"] = 'J',
    ["J"] = 'Q',
    ["Q"] = 'K',
    ["K"] = 'K',
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
        local card_upgrade = metamorphosis_value_scaling[card_value_current] or 'K'
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
            -- Still need this if condition for when blueprint/brainstorm is used with it
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
                if not card_is_rshskoh(card) then
                    play_sound('card1')
                    card:flip()
                end
                return true
            end}))
        end
        delay(0.2)

        -- This is where I transform the cards
        for i, card in ipairs(emergenceCards) do
            if not card.destroyed and not card.shattered then
                G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.1, func = function()
                    if not card_is_rshskoh(card) then
                        card_eval_status_text(card, 'extra', nil, nil, nil, {
                            message = mod_localization.misc.emergence_upgrade_message,
                            instant = true
                        })
                    end
                    return true
                end}))
                G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.1, func = function()
                    if not card_is_rshskoh(card) then
                        -- super_metamorphosis(card) -- too much power...
                        apply_metamorphosis_upgrade(card)
                    end
                    return true
                end}))
            end
        end

        -- Unflip it for the fans
        for i, card in ipairs(emergenceCards) do
            G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.15, func = function()
                if card.facing == 'back' then
                    play_sound('tarot2')
                    card:flip()
                    card:juice_up(0.3, 0.3)
                end
                return true
            end}))
        end

        delay(#emergenceCards * 0.15 + 0.5)

    -- This phase happens just after scoring but before triggering the joker aftermath
    elseif context.destroying_card and not context.blueprint then
        local card = context.destroying_card
        if not card_is_rshskoh(card) and pseudorandom('177013') < G.GAME.probabilities.normal/EMERGENCE_BREAK_DENOMINATOR then
            G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.15, func = function()
                card_eval_status_text(card, 'extra', nil, nil, nil, {
                    message = mod_localization.misc.emergence_broken_message,
                    colour = G.C.RED,
                    instant = true
                })
                card:set_ability(G.P_CENTERS.m_glass)
                card:juice_up(0.3, 0.5)
                return true -- if i dont return true here, the game freezes
            end}))

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
local function init_modded_jokers()
    --[[SMODS.Joker:new(
        name, slug,
        config,
        spritePos, loc_txt,
        rarity, cost, unlocked, discovered, blueprint_compat, eternal_compat
    )
    ]]

    -- DO NOT PUT THIS OUTSIDE OF THIS FUNCTION
    -- THAT WILL BREAK THE GAME SO HARD ON LOCALIZATION FOR SOME REASON!!
    local joker_def = {
        snoresville_emergence = SMODS.Joker:new(
            "Emergence",
            "snoresville_emergence",
            {},     -- It needs a config???
            {x = 0, y = 0},
            mod_localization.joker_description.snoresville_emergence,
            1,      -- Rarity
            2,      -- Cost
            true,   -- Unlocked
            true,   -- Discovered
            true,   -- Blueprint Compatible
            true    -- Eternal Compatible
        ),
    }

    -- Order the jokers
    local joker_sorted = {}

    for joker_name, joker_data in pairs(joker_def) do
        local j = {}
        j.name = joker_data.name
        j.rarity = joker_data.rarity
        j.slug = joker_name
        table.insert(joker_sorted, j)
    end

    table.sort(joker_sorted, function(a, b)
        if a.rarity ~= b.rarity then
            return a.rarity < b.rarity
        end
        return a.name < b.name
    end)

    for _, joker_data in ipairs(joker_sorted) do
        local name = joker_data.slug
        local v = joker_def[name]

        v.slug = "j_" .. name
        v.loc_txt = mod_localization.joker_description[name]
        v.mod = MOD_ID
        v:register()

        -- https://github.com/Steamopollys/Steamodded/wiki/Creating-new-game-objects#creating-jokers
        SMODS.Sprite:new(v.slug, SMODS.findModByID(MOD_ID).path, v.slug..".png", 71, 95, "asset_atli")
        :register()
    end
end

function SMODS.INIT.SnoresvilleEmergence()
    sendDebugMessage("Emergence is coming")
    init_localization()
    init_modded_jokers()

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
                add_joker('j_snoresville_emergence', "negative", nil, true)

				return true
			end
		}))
	end
end

-- https://github.com/Steamopollys/Steamodded/wiki/Create-a-Deck#mod-core-api-deck-documentation
-- do not trust the order of parameters on the wiki...
local metaDeck = SMODS.Deck:new(
    DECK_NAME,                                              -- name
    "snoresvilleMetamorphosis",                             -- slug
    {snoresvilleMetamorphosisDeck = true},                  -- config
    {x = 5, y = 1},                                         -- Card Back, x and y correspond to the location of the sprite in resources/textures/2x/Enhancers.png   --
    mod_localization.deck_description.metamorphosis_deck    -- localization
)
metaDeck:register()