require "CE/Common/Config/CE_Config"

CurrencyExpanded = CurrencyExpanded or {}

if not CurrencyExpanded.RegisterInteractionStrings then
    return nil
end

CurrencyExpanded.RegisterInteractionStrings("Lottery", "ScratchTicket", {
    Anticipation = {
        "Come on, give me something decent...",
        "Just one clean hit, that's all I need.",
        "Let's see if luck still remembers me.",
        "Don't be a dud, ticket.",
        "House owes me one.",
        "Scratch, scratch, payday...",
        "Feels like this one's got a pulse.",
        "Maybe this is the one.",
        "All right, surprise me.",
        "Let's peel the bad news off slow."
    },
    BulkStart = {
        "All right, stack them up. Let's work the board.",
        "Whole pile of chances right here.",
        "Maybe one of these actually pays.",
        "Let's burn through the stack.",
        "Time to see if the house slips."
    },
    BulkLoop = {
        "Next one...",
        "Still scratching...",
        "Keep them coming...",
        "Another shot...",
        "Work the stack..."
    },
    Lose = {
        "Dead ticket.",
        "Nothing. Figures.",
        "House keeps it.",
        "Bust.",
        "All dust, no payout."
    },
    Low = {
        "Small hit. I'll take it.",
        "Not huge, but it counts.",
        "Little win. Better than dead paper.",
        "Cheap ticket, cheap smile.",
        "Barely a score, still a score."
    },
    Medium = {
        "Okay, that's respectable.",
        "Now we're talking.",
        "Solid pull.",
        "That's enough to feel lucky.",
        "Decent board. Decent payout."
    },
    High = {
        "That's a real win.",
        "Nice. Finally, a proper payout.",
        "That one bites back in my favor.",
        "House just coughed up.",
        "Yeah, that's worth redeeming."
    },
    Jackpot = {
        "Jackpot. No way.",
        "That is a screaming winner.",
        "Big board. Big money.",
        "House is going to hate me for this one.",
        "That's the top shelf payout."
    },
    AlreadyScratched = {
        "Already burned this one.",
        "This ticket's already dead.",
        "No second scratch on the same board.",
        "Already checked this one."
    }
})

return CurrencyExpanded.GetInteractionStrings("Lottery", "ScratchTicket")
