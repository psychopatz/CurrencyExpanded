-- DT_MANUAL_EDITOR_BEGIN
-- {
--   "manual_id": "ce_upd_2026_04_03",
--   "module": "CurrencyExpanded",
--   "title": "Update: 03/30 - 04/03",
--   "description": "Currency Overhaul and Lottery Launch. No miscellaneous changes were recorded for this update.",
--   "start_page_id": "cat_features",
--   "audiences": [
--     "CurrencyExpanded"
--   ],
--   "sort_order": 1,
--   "release_version": "",
--   "popup_version": "",
--   "auto_open_on_update": false,
--   "is_whats_new": true,
--   "manual_type": "whats_new",
--   "show_in_library": false,
--   "support_url": "",
--   "banner_title": "",
--   "banner_text": "",
--   "banner_action_label": "",
--   "source_folder": "WhatsNew",
--   "chapters": [
--     {
--       "id": "release_notes",
--       "title": "Release Notes",
--       "description": "No specific bugs were addressed in this update cycle."
--     }
--   ],
--   "pages": [
--     {
--       "id": "cat_features",
--       "chapter_id": "release_notes",
--       "title": "Features",
--       "keywords": [],
--       "blocks": [
--         {
--           "type": "heading",
--           "id": "item_item_2026_03_30_currencyexpanded",
--           "level": 2,
--           "text": "Scratch Ticket Lottery & Trader Updates"
--         },
--         {
--           "type": "paragraph",
--           "text": "- **New scratch ticket system** now features weekly jackpots and NPC winner announcements.\n- Updated trader dialogue to support the new lottery mechanics and scratch ticket sales.\n- Added custom sound effects for casino interactions and updated mod dependencies."
--         },
--         {
--           "type": "callout",
--           "tone": "success",
--           "title": "Impact",
--           "text": "Adds a new weekly scratch ticket lottery system with NPC winners and custom sounds."
--         }
--       ]
--     },
--     {
--       "id": "cat_misc",
--       "chapter_id": "release_notes",
--       "title": "Misc",
--       "keywords": [],
--       "blocks": [
--         {
--           "type": "callout",
--           "tone": "info",
--           "title": "Misc Highlights",
--           "text": "No miscellaneous changes were recorded for this update."
--         },
--         {
--           "type": "heading",
--           "id": "item_item_2026_04_03_currencyexpanded",
--           "level": 2,
--           "text": "Currency Expansion Guide Updates"
--         },
--         {
--           "type": "paragraph",
--           "text": "- Replaced the old manual wallet guide with a new comprehensive currency expansion guide.\n- Added a dedicated file specifically detailing how to use *dt_wallets* within the mod."
--         },
--         {
--           "type": "callout",
--           "tone": "success",
--           "title": "Impact",
--           "text": "Players now have clearer, updated instructions for managing expanded currency and wallets."
--         },
--         {
--           "type": "heading",
--           "id": "item_item_2026_04_01_currencyexpanded",
--           "level": 2,
--           "text": "Currency Wallet Manual Metadata Update"
--         },
--         {
--           "type": "paragraph",
--           "text": "- Added audience metadata to the currency wallet manual definition.\n- **Clarifies manual content** to better guide players on wallet usage."
--         },
--         {
--           "type": "callout",
--           "tone": "success",
--           "title": "Impact",
--           "text": "Improves wallet documentation clarity with new audience metadata."
--         }
--       ]
--     }
--   ],
--   "raw_lua": null
-- }
-- DT_MANUAL_EDITOR_END
if CurrencyExpanded and CurrencyExpanded.RegisterManual then
    CurrencyExpanded.RegisterManual("ce_upd_2026_04_03", {
        title = "Update: 03/30 - 04/03",
        description = "Currency Overhaul and Lottery Launch. No miscellaneous changes were recorded for this update.",
        startPageId = "cat_features",
        audiences = { "CurrencyExpanded" },
        sortOrder = 1,
        releaseVersion = "",
        popupVersion = "",
        autoOpenOnUpdate = false,
        isWhatsNew = true,
        manualType = "whats_new",
        showInLibrary = false,
        supportUrl = "",
        bannerTitle = "",
        bannerText = "",
        bannerActionLabel = "",
        chapters = {
            {
                id = "release_notes",
                title = "Release Notes",
                description = "No specific bugs were addressed in this update cycle.",
            },
        },
        pages = {
            {
                id = "cat_features",
                chapterId = "release_notes",
                title = "Features",
                keywords = {  },
                blocks = {
                    { type = "heading", id = "item_item_2026_03_30_currencyexpanded", level = 2, text = "Scratch Ticket Lottery & Trader Updates" },
                    { type = "paragraph", text = "- **New scratch ticket system** now features weekly jackpots and NPC winner announcements.\n- Updated trader dialogue to support the new lottery mechanics and scratch ticket sales.\n- Added custom sound effects for casino interactions and updated mod dependencies." },
                    { type = "callout", tone = "success", title = "Impact", text = "Adds a new weekly scratch ticket lottery system with NPC winners and custom sounds." },
                },
            },
            {
                id = "cat_misc",
                chapterId = "release_notes",
                title = "Misc",
                keywords = {  },
                blocks = {
                    { type = "callout", tone = "info", title = "Misc Highlights", text = "No miscellaneous changes were recorded for this update." },
                    { type = "heading", id = "item_item_2026_04_03_currencyexpanded", level = 2, text = "Currency Expansion Guide Updates" },
                    { type = "paragraph", text = "- Replaced the old manual wallet guide with a new comprehensive currency expansion guide.\n- Added a dedicated file specifically detailing how to use *dt_wallets* within the mod." },
                    { type = "callout", tone = "success", title = "Impact", text = "Players now have clearer, updated instructions for managing expanded currency and wallets." },
                    { type = "heading", id = "item_item_2026_04_01_currencyexpanded", level = 2, text = "Currency Wallet Manual Metadata Update" },
                    { type = "paragraph", text = "- Added audience metadata to the currency wallet manual definition.\n- **Clarifies manual content** to better guide players on wallet usage." },
                    { type = "callout", tone = "success", title = "Impact", text = "Improves wallet documentation clarity with new audience metadata." },
                },
            },
        },
    })
end
