pcall(require, "DT/Common/Config")

if DynamicTrading and DynamicTrading.RegisterDialogue then
    DynamicTrading.RegisterDialogue("Gambler", "Selling", {
        EN = {
            Generic = {
                "I'll take the {item}. {price} says it's worth the risk.",
                "Not bad. {price} for the {item}, paid clean.",
                "I can move that {item}. You've got {price}.",
                "Good pull. {price} for the {item}."
            },
            HighValue = {
                "Now that's a jackpot item. {price} coming your way.",
                "Big score, {player.firstname}. {item} is worth {price} to me."
            },
            HighMarkup = {
                "You're pushing the table hard, but fine. {price} for the {item}.",
                "Sharp deal. I'll still cover {price} for the {item}."
            },
            Trash = {
                "Rough shape, rough payout. {price} is the best I'll do.",
                "That's barely worth a side bet. {price} for the {item}."
            },
            NoCash = {
                "I'd buy it if the table wasn't tied up. Not enough cash right now.",
                "Good piece, bad timing. My money's committed elsewhere."
            }
        }
    })
end
