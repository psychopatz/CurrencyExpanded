-- DT_MANUAL_EDITOR_BEGIN
-- {
--   "manual_id": "ce_upd_2026_05_02",
--   "module": "CurrencyExpanded",
--   "title": "Update: 04/21 - 05/02",
--   "description": "Trading Refinement and Naming Clarity. Internal naming conventions were updated for better consistency.",
--   "start_page_id": "cat_misc",
--   "audiences": [
--     "CurrencyExpanded"
--   ],
--   "sort_order": 3,
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
--       "description": "No specific bugs were resolved in this update."
--     }
--   ],
--   "pages": [
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
--           "text": "Internal naming conventions were updated for better consistency."
--         },
--         {
--           "type": "heading",
--           "id": "item_item_2026_04_29_currencyexpanded",
--           "level": 2,
--           "text": "Gambler Archetype Removal and UI Update"
--         },
--         {
--           "type": "paragraph",
--           "text": "- Removed the Gambler archetype definitions to clean up internal logic.\n- Updated manual audience configurations to reflect the latest system changes.\n- Ensures smoother compatibility with other currency expansion features."
--         },
--         {
--           "type": "callout",
--           "tone": "success",
--           "title": "Impact",
--           "text": "Streamlines manual audience settings by removing outdated Gambler definitions."
--         },
--         {
--           "type": "heading",
--           "id": "item_item_2026_04_21_currencyexpanded",
--           "level": 2,
--           "text": "Refined Sandbox Option Naming"
--         },
--         {
--           "type": "paragraph",
--           "text": "- *Improved readability* of CurrencyExpanded sandbox options.\n- Updated setting labels to be more intuitive for players.\n- No gameplay mechanics changed, only interface text."
--         },
--         {
--           "type": "callout",
--           "tone": "success",
--           "title": "Impact",
--           "text": "Sandbox settings now use clearer names for easier configuration."
--         }
--       ]
--     }
--   ],
--   "raw_lua": null
-- }
-- DT_MANUAL_EDITOR_END
if CurrencyExpanded and CurrencyExpanded.RegisterManual then
    CurrencyExpanded.RegisterManual("ce_upd_2026_05_02", {
        title = "Update: 04/21 - 05/02",
        description = "Trading Refinement and Naming Clarity. Internal naming conventions were updated for better consistency.",
        startPageId = "cat_misc",
        audiences = { "CurrencyExpanded" },
        sortOrder = 3,
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
                description = "No specific bugs were resolved in this update.",
            },
        },
        pages = {
            {
                id = "cat_misc",
                chapterId = "release_notes",
                title = "Misc",
                keywords = {  },
                blocks = {
                    { type = "callout", tone = "info", title = "Misc Highlights", text = "Internal naming conventions were updated for better consistency." },
                    { type = "heading", id = "item_item_2026_04_29_currencyexpanded", level = 2, text = "Gambler Archetype Removal and UI Update" },
                    { type = "paragraph", text = "- Removed the Gambler archetype definitions to clean up internal logic.\n- Updated manual audience configurations to reflect the latest system changes.\n- Ensures smoother compatibility with other currency expansion features." },
                    { type = "callout", tone = "success", title = "Impact", text = "Streamlines manual audience settings by removing outdated Gambler definitions." },
                    { type = "heading", id = "item_item_2026_04_21_currencyexpanded", level = 2, text = "Refined Sandbox Option Naming" },
                    { type = "paragraph", text = "- *Improved readability* of CurrencyExpanded sandbox options.\n- Updated setting labels to be more intuitive for players.\n- No gameplay mechanics changed, only interface text." },
                    { type = "callout", tone = "success", title = "Impact", text = "Sandbox settings now use clearer names for easier configuration." },
                },
            },
        },
    })
end
