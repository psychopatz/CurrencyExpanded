pcall(require, "DT/Common/Config")

if DynamicTrading and DynamicTrading.RegisterDialogue then
    DynamicTrading.RegisterDialogue("Gambler", "Buying", {
        EN = {
            Generic = {
                "There you go. {item} is yours for {price}.",
                "Bet accepted. {price} buys you the {item}.",
                "I'll slide the {item} over. Cash clears at {price}.",
                "That's a fair stake. {item} for {price}."
            },
            HighValue = {
                "Big table, big price. {price} for the {item}, no flinching.",
                "High roller stock costs high roller cash. {item} goes for {price}."
            },
            HighMarkup = {
                "Odds shifted against you. {price} for the {item}.",
                "Hot demand means hot prices. {price} if you still want the {item}."
            },
            LowMarkup = {
                "Lucky break for you. {item} only costs {price} today.",
                "Table's in your favor. {price} for the {item}."
            },
            LastStock = {
                "Last one on the table. Make it count.",
                "That's the final {item}. No second spin after this."
            },
            SoldOut = {
                "Table's dry. No {item} left.",
                "Nothing left in the pot for {item}. Try later."
            },
            NoCash = {
                "No cash, no chance. You need more than {price}.",
                "House doesn't front credit, {player}. Come back with {price}."
            }
        }
    })
end
