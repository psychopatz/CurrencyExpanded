-- DT_MANUAL_EDITOR_BEGIN
-- {
--   "manual_id": "dt_wallets",
--   "title": "A Guide to Local Currency",
--   "description": "How to find, store, and manage the only thing that still has value in Kentucky.",
--   "start_page_id": "wallet_generation",
--   "chapters": [
--     { "id": "loot_logic", "title": "Scavenging for Cash", "description": "Finding money on the bodies of the fallen." },
--     { "id": "currency_types", "title": "Storing Your Wealth", "description": "Managing loose change and currency bundles." }
--   ],
--   "pages": [
--     {
--       "id": "wallet_generation",
--       "chapter_id": "loot_logic",
--       "title": "Looting the Dead",
--       "keywords": ["wallet", "loot", "cash", "probability", "scavenge"],
--       "blocks": [
--         { "type": "heading", "id": "zombie-cash", "level": 1, "text": "The Dead Man's Wallet" },
--         { "type": "paragraph", "text": "They can't take it with them. When you search a body, there's a strong chance they were carrying some local currency. It's not guaranteed—about 35% of the time, you'll find nothing but lint—but for the rest, the server determines their wealth based on their former life." },
--         { "type": "heading", "id": "the-odds", "level": 2, "text": "What to Expect" },
--         { "type": "bullet_list", "items": [
--             "Small Change (60%): Just enough for a snack or a few bandages.",
--             "Standard Stash (30%): A decent pile of bills, enough for some ammo.",
--             "Wealthy Resident (10%): A thick wallet that'll make your day."
--         ]},
--         { "type": "callout", "tone": "info", "title": "The Big Score", "text": "Every now and then (about 5% of searches), you'll hit a 'Jackpot'. This is a lucky find that can contain significantly more than a standard wealthy stash. Always search the bodies!" }
--       ]
--     },
--     {
--       "id": "money_items",
--       "chapter_id": "currency_types",
--       "title": "Bundles and Loose Bills",
--       "keywords": ["money", "bundle", "storage", "weight"],
--       "blocks": [
--         { "type": "heading", "id": "money-management", "level": 1, "text": "Packing for the Long Haul" },
--         { "type": "paragraph", "text": "Carrying a thousand individual bills is a recipe for a messy backpack. To stay mobile, the world uses 'Money Bundles' (stacks of 100). They're lighter and much easier to trade in bulk." },
--         { "type": "image", "path": "media/ui/Backgrounds/sunrise.png", "caption": "Keep your bills bundled to save space.", "width": 400, "height": 200 },
--         { "type": "callout", "tone": "warn", "title": "Scavenger's Tip", "text": "The world automatically 'packs' your loot. If a body has $450, you'll find 4 bundles and 50 loose bills. It makes looting fast, just the way we like it." }
--       ]
--     }
--   ]
-- }
-- DT_MANUAL_EDITOR_END
if CurrencyExpanded and CurrencyExpanded.RegisterManual then
    CurrencyExpanded.RegisterManual("dt_wallets", {
        title = "A Guide to Local Currency",
        description = "How to find, store, and manage the only thing that still has value in Kentucky.",
        startPageId = "wallet_generation",
        chapters = {
            { id = "loot_logic", title = "Scavenging for Cash", description = "Finding money on the bodies of the fallen." },
            { id = "currency_types", title = "Storing Your Wealth", description = "Managing loose change and currency bundles." },
        },
        pages = {
            {
                id = "wallet_generation",
                chapterId = "loot_logic",
                title = "Looting the Dead",
                keywords = { "wallet", "loot", "cash", "probability", "scavenge" },
                blocks = {
                    { type = "heading", id = "zombie-cash", level = 1, text = "The Dead Man's Wallet" },
                    { type = "paragraph", text = "They can't take it with them. When you search a body, there's a strong chance they were carrying some local currency. It's not guaranteed—about 35% of the time, you'll find nothing but lint—but for the rest, the server determines their wealth based on their former life." },
                    { type = "heading", id = "the-odds", level = 2, text = "What to Expect" },
                    { type = "bullet_list", items = {
                        "Small Change (60%): Just enough for a snack or a few bandages.",
                        "Standard Stash (30%): A decent pile of bills, enough for some ammo.",
                        "Wealthy Resident (10%): A thick wallet that'll make your day."
                    } },
                    { type = "callout", tone = "info", title = "The Big Score", text = "Every now and then (about 5% of searches), you'll hit a 'Jackpot'. This is a lucky find that can contain significantly more than a standard wealthy stash. Always search the bodies!" },
                },
            },
            {
                id = "money_items",
                chapterId = "currency_types",
                title = "Bundles and Loose Bills",
                keywords = { "money", "bundle", "storage", "weight" },
                blocks = {
                    { type = "heading", id = "money-management", level = 1, text = "Packing for the Long Haul" },
                    { type = "paragraph", text = "Carrying a thousand individual bills is a recipe for a messy backpack. To stay mobile, the world uses 'Money Bundles' (stacks of 100). They're lighter and much easier to trade in bulk." },
                    { type = "image", path = "media/ui/Backgrounds/sunrise.png", caption = "Keep your bills bundled to save space.", width = 400, height = 200 },
                    { type = "callout", tone = "warn", title = "Scavenger's Tip", text = "The world automatically 'packs' your loot. If a body has $450, you'll find 4 bundles and 50 loose bills. It makes looting fast, just the way we like it." },
                },
            },
        },
    })
end
