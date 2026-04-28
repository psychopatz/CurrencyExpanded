-- DT_MANUAL_EDITOR_BEGIN
-- {
--   "manual_id": "currency_expanded_guide",
--   "module": "CurrencyExpanded",
--   "title": "Currency Expanded Add-",
--   "description": "The definitive guide to looting and gambling in Kentucky.",
--   "start_page_id": "ce_overview",
--   "audiences": [
--     "CurrencyExpanded"
--   ],
--   "sort_order": 5,
--   "release_version": "",
--   "popup_version": "",
--   "auto_open_on_update": false,
--   "is_whats_new": false,
--   "manual_type": "manual",
--   "show_in_library": true,
--   "support_url": "",
--   "banner_title": "",
--   "banner_text": "",
--   "banner_action_label": "",
--   "source_folder": "Universal",
--   "chapters": [
--     {
--       "id": "scavenging",
--       "title": "Scavenging for Wealth",
--       "description": "Finding hidden cash in the world."
--     },
--     {
--       "id": "lottery_systems",
--       "title": "Lottery & Gambling",
--       "description": "High-stakes gameplay mechanics."
--     },
--     {
--       "id": "lottery_agent",
--       "title": "The Lottery Agent",
--       "description": "Meeting the Gambler."
--     }
--   ],
--   "pages": [
--     {
--       "id": "ce_overview",
--       "chapter_id": "scavenging",
--       "title": "Rummaging through Wallets",
--       "keywords": [
--         "wallet",
--         "rummage",
--         "loot",
--         "search",
--         "money"
--       ],
--       "blocks": [
--         {
--           "type": "heading",
--           "id": "wallet-looting",
--           "level": 1,
--           "text": "The Art of Rummaging"
--         },
--         {
--           "type": "paragraph",
--           "text": "In Currency Expanded, wallets found on the deceased or in containers are no longer just cosmetic. They are physical containers that must be carefully searched to reveal their contents."
--         },
--         {
--           "type": "paragraph",
--           "text": "Right-click any unsearched wallet to Rummage Through it. This takes time and produces audible rustling, but can reward you with anything from a few loose bills to literal jackpots of cash."
--         },
--         {
--           "type": "callout",
--           "tone": "info",
--           "title": "Inventory Management",
--           "text": "Once a wallet is emptied, its name changes to Empty Wallet. You can safely discard these or keep them for organization."
--         }
--       ]
--     },
--     {
--       "id": "scratch_tickets",
--       "chapter_id": "lottery_systems",
--       "title": "Scratch Tickets",
--       "keywords": [
--         "scratch",
--         "ticket",
--         "lottery",
--         "win",
--         "lose"
--       ],
--       "blocks": [
--         {
--           "type": "heading",
--           "id": "scratching-mechanics",
--           "level": 1,
--           "text": "Testing Your Luck"
--         },
--         {
--           "type": "paragraph",
--           "text": "Scratch Tickets are the ultimate high-risk, high-reward items in the exclusion zone. To use one, you must carefully scratch it via the context menu."
--         },
--         {
--           "type": "bullet_list",
--           "items": [
--             "Low/Medium/High Wins: Most winning tickets grant immediate cash injections to your inventory.",
--             "The Jackpot: Rare tickets that grant massive payouts. Your character will audibly react when hitting these!",
--             "Bulk Scratching: If you have a stack of tickets, you can carefully scratch all selected items to save time."
--           ]
--         },
--         {
--           "type": "callout",
--           "tone": "warn",
--           "title": "Anticipation",
--           "text": "Scratching takes focus (and time). Make sure your surroundings are clear of zeds before checking your numbers!"
--         }
--       ]
--     },
--     {
--       "id": "gambler_agent",
--       "chapter_id": "lottery_agent",
--       "title": "The Lottery Agent",
--       "keywords": [
--         "gambler",
--         "agent",
--         "independent",
--         "claims",
--         "buy"
--       ],
--       "blocks": [
--         {
--           "type": "heading",
--           "id": "gambler-role",
--           "level": 1,
--           "text": "The Exclusive Agent"
--         },
--         {
--           "type": "paragraph",
--           "text": "Meeting the Gambler (Lottery Agent) is essential for any aspiring winner. Unlike other traders, the Gambler is a specialist who facilitates the lottery ecosystem."
--         },
--         {
--           "type": "bullet_list",
--           "items": [
--             "Ticket Distribution: The Gambler is the primary source for fresh, unscratched tickets. They keep a massive fixed stock of 50 tickets at all times.",
--             "Claiming Winners: They are currently the only authorized agent who supports Scratch Claims, allowing you to turn in your winning tickets for hard currency.",
--             "No Buying: The Gambler strictly deals in lottery and exchange; they will not buy your general loot or survival gear."
--           ]
--         },
--         {
--           "type": "callout",
--           "tone": "info",
--           "title": "Faction Status",
--           "text": "Gamblers are currently aligned as Independent Traders. They require a healthy Global Wealth (min $25,000) to operate their high-stakes business."
--         }
--       ]
--     }
--   ]
-- }
-- DT_MANUAL_EDITOR_END
if CurrencyExpanded and CurrencyExpanded.RegisterManual then
    CurrencyExpanded.RegisterManual("currency_expanded_guide", {
        title = "Currency Expanded Add-",
        description = "The definitive guide to looting and gambling in Kentucky.",
        startPageId = "ce_overview",
        audiences = { "CurrencyExpanded" },
        sortOrder = 5,
        releaseVersion = "",
        popupVersion = "",
        autoOpenOnUpdate = false,
        isWhatsNew = false,
        manualType = "manual",
        showInLibrary = true,
        supportUrl = "",
        bannerTitle = "",
        bannerText = "",
        bannerActionLabel = "",
        chapters = {
            {
                id = "scavenging",
                title = "Scavenging for Wealth",
                description = "Finding hidden cash in the world.",
            },
            {
                id = "lottery_systems",
                title = "Lottery & Gambling",
                description = "High-stakes gameplay mechanics.",
            },
            {
                id = "lottery_agent",
                title = "The Lottery Agent",
                description = "Meeting the Gambler.",
            },
        },
        pages = {
            {
                id = "ce_overview",
                chapterId = "scavenging",
                title = "Rummaging through Wallets",
                keywords = { "wallet", "rummage", "loot", "search", "money" },
                blocks = {
                    { type = "heading", id = "wallet-looting", level = 1, text = "The Art of Rummaging" },
                    { type = "paragraph", text = "In Currency Expanded, wallets found on the deceased or in containers are no longer just cosmetic. They are physical containers that must be carefully searched to reveal their contents." },
                    { type = "paragraph", text = "Right-click any unsearched wallet to Rummage Through it. This takes time and produces audible rustling, but can reward you with anything from a few loose bills to literal jackpots of cash." },
                    { type = "callout", tone = "info", title = "Inventory Management", text = "Once a wallet is emptied, its name changes to Empty Wallet. You can safely discard these or keep them for organization." },
                },
            },
            {
                id = "scratch_tickets",
                chapterId = "lottery_systems",
                title = "Scratch Tickets",
                keywords = { "scratch", "ticket", "lottery", "win", "lose" },
                blocks = {
                    { type = "heading", id = "scratching-mechanics", level = 1, text = "Testing Your Luck" },
                    { type = "paragraph", text = "Scratch Tickets are the ultimate high-risk, high-reward items in the exclusion zone. To use one, you must carefully scratch it via the context menu." },
                    { type = "bullet_list", items = { "Low/Medium/High Wins: Most winning tickets grant immediate cash injections to your inventory.", "The Jackpot: Rare tickets that grant massive payouts. Your character will audibly react when hitting these!", "Bulk Scratching: If you have a stack of tickets, you can carefully scratch all selected items to save time." } },
                    { type = "callout", tone = "warn", title = "Anticipation", text = "Scratching takes focus (and time). Make sure your surroundings are clear of zeds before checking your numbers!" },
                },
            },
            {
                id = "gambler_agent",
                chapterId = "lottery_agent",
                title = "The Lottery Agent",
                keywords = { "gambler", "agent", "independent", "claims", "buy" },
                blocks = {
                    { type = "heading", id = "gambler-role", level = 1, text = "The Exclusive Agent" },
                    { type = "paragraph", text = "Meeting the Gambler (Lottery Agent) is essential for any aspiring winner. Unlike other traders, the Gambler is a specialist who facilitates the lottery ecosystem." },
                    { type = "bullet_list", items = { "Ticket Distribution: The Gambler is the primary source for fresh, unscratched tickets. They keep a massive fixed stock of 50 tickets at all times.", "Claiming Winners: They are currently the only authorized agent who supports Scratch Claims, allowing you to turn in your winning tickets for hard currency.", "No Buying: The Gambler strictly deals in lottery and exchange; they will not buy your general loot or survival gear." } },
                    { type = "callout", tone = "info", title = "Faction Status", text = "Gamblers are currently aligned as Independent Traders. They require a healthy Global Wealth (min $25,000) to operate their high-stakes business." },
                },
            },
        },
    })
end
