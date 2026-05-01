-- DT_MANUAL_EDITOR_BEGIN
-- {
--   "manual_id": "ce_upd_2026_04_20",
--   "module": "CurrencyExpanded",
--   "title": "Update: 04/04 - 04/20",
--   "description": "Currency Expansion for Build 42.16. No miscellaneous changes were recorded for this release.",
--   "start_page_id": "cat_misc",
--   "audiences": [
--     "CurrencyExpanded"
--   ],
--   "sort_order": 2,
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
--       "description": "No specific bug fixes were included in this update cycle."
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
--           "text": "No miscellaneous changes were recorded for this release."
--         },
--         {
--           "type": "heading",
--           "id": "item_item_2026_04_16_currencyexpanded",
--           "level": 2,
--           "text": "Currency Expanded Code Cleanup"
--         },
--         {
--           "type": "paragraph",
--           "text": "- Removed legacy version 42.13 modules and associated outdated assets.\n- Consolidated manual definitions into a common directory for cleaner organization.\n- Eliminated version-specific files to simplify the overall mod architecture."
--         },
--         {
--           "type": "callout",
--           "tone": "success",
--           "title": "Impact",
--           "text": "Streamlined mod structure for better stability and easier future updates."
--         },
--         {
--           "type": "heading",
--           "id": "item_item_2026_04_15_currencyexpanded",
--           "level": 2,
--           "text": "Currency Expanded Build 42.16 Support"
--         },
--         {
--           "type": "paragraph",
--           "text": "- Added full compatibility for Project Zomboid build 42.16.\n- Ensured all currency systems function correctly in the new update."
--         },
--         {
--           "type": "callout",
--           "tone": "success",
--           "title": "Impact",
--           "text": "The mod now fully supports the latest Project Zomboid build."
--         }
--       ]
--     }
--   ],
--   "raw_lua": null
-- }
-- DT_MANUAL_EDITOR_END
if CurrencyExpanded and CurrencyExpanded.RegisterManual then
    CurrencyExpanded.RegisterManual("ce_upd_2026_04_20", {
        title = "Update: 04/04 - 04/20",
        description = "Currency Expansion for Build 42.16. No miscellaneous changes were recorded for this release.",
        startPageId = "cat_misc",
        audiences = { "CurrencyExpanded" },
        sortOrder = 2,
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
                description = "No specific bug fixes were included in this update cycle.",
            },
        },
        pages = {
            {
                id = "cat_misc",
                chapterId = "release_notes",
                title = "Misc",
                keywords = {  },
                blocks = {
                    { type = "callout", tone = "info", title = "Misc Highlights", text = "No miscellaneous changes were recorded for this release." },
                    { type = "heading", id = "item_item_2026_04_16_currencyexpanded", level = 2, text = "Currency Expanded Code Cleanup" },
                    { type = "paragraph", text = "- Removed legacy version 42.13 modules and associated outdated assets.\n- Consolidated manual definitions into a common directory for cleaner organization.\n- Eliminated version-specific files to simplify the overall mod architecture." },
                    { type = "callout", tone = "success", title = "Impact", text = "Streamlined mod structure for better stability and easier future updates." },
                    { type = "heading", id = "item_item_2026_04_15_currencyexpanded", level = 2, text = "Currency Expanded Build 42.16 Support" },
                    { type = "paragraph", text = "- Added full compatibility for Project Zomboid build 42.16.\n- Ensured all currency systems function correctly in the new update." },
                    { type = "callout", tone = "success", title = "Impact", text = "The mod now fully supports the latest Project Zomboid build." },
                },
            },
        },
    })
end
