pcall(require, "DT/Common/Config")

DynamicTrading.RegisterDialogue("Gambler", "Greetings", {
    EN = {
        Default = {
            "Luck is still running tonight, {player.firstname}. Looking to press it?",
            "Cards are cold, odds are hot. What are you buying, {player}?",
            "House is open, survivor. Need a ticket or something shinier?",
            "I deal in chances, not promises. What do you want, {player.firstname}?",
            "Pocket full of cash, table full of temptations. Talk to me, {player}."
        },
        Morning = {
            "Sun's up and I'm still counting wins. Need something risky, {player.firstname}?",
            "Morning odds are decent. What are you chasing today, {player}?"
        },
        Evening = {
            "Evening is when the lucky ones come out. You buying, {player.firstname}?",
            "Best time to make a bad decision or a great one. What's it gonna be, {player}?"
        },
        Night = {
            "Night games pay the best. What are you after, {player.firstname}?",
            "I save the real action for dark hours. Speak up, {player}."
        },
        Raining = {
            "Rain on the roof, tickets on the table. Need one, {player.firstname}?",
            "Bad weather makes people gamble harder. What can I do for you, {player}?"
        },
        Fog = {
            "Fog's thick enough to hide a winning streak. What's your play, {player.firstname}?",
            "Can't see the road, but I can still see profit. Talk, {player}."
        }
    }
})
