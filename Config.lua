-- Config.lua
-- Этот модуль содержит конфигурационные данные для UI.
-- Сервисы, такие как TweenService, UserInputService, CoreGui, Lighting,
-- предполагается, что они уже определены в глобальной среде выполнения загрузчиком.
-- 'task' также является глобальной библиотекой.

Config = {
    FRAME_TITLE = "Konosuba Enhancements",
    FRAME_WIDTH = 750,
    FRAME_HEIGHT = 550,
    TITLE_BAR_HEIGHT = 45,
    TAB_BUTTON_SIZE = 50,
    PADDING = 10,
    CORNER_RADIUS_BIG = 16,

    Fonts = {
        Default = Enum.Font.Gotham, Bold = Enum.Font.GothamBold, Semibold = Enum.Font.GothamSemibold,
        Icon = Enum.Font.GothamBold -- Or a specific icon font if you have one
    },
    TextSizes = {
        Small = 12, Default = 14, Medium = 16, Large = 18, Header1 = 20, Header2 = 18,
        WindowTitleBarButtons = 16, -- Can be used for icon size too
        TitleBarIconSize = 18, -- Specific size for title bar icons
    },

    Notification = {
        DURATION = 2, FADE_TIME = 0.25,
        WIDTH = 180, HEIGHT = 55, PADDING_X = 15, PADDING_Y = 15,
        EASING_STYLE = Enum.EasingStyle.Quint,
    },

    KEYBIND_PROMPT_TEXT = "НАЖМИТЕ",
    KEYBIND_UNBOUND_TEXT = "НЕ НАЗН.",
    KEYBIND_RESET_BUTTON_TEXT = "X",

    SEPARATOR_LINE_HEIGHT = 1,

    TAB_BAR_SIZE = nil, -- Будет вычислено ниже

    RESIZE_HANDLE_DIMENSION = 15,
    RESIZE_HANDLE_MIN_FRAME_WIDTH = 400,
    RESIZE_HANDLE_MAX_FRAME_WIDTH = 1200,
    RESIZE_HANDLE_MIN_FRAME_HEIGHT = 300,
    RESIZE_HANDLE_MAX_FRAME_HEIGHT = 1000,

    FRAME_TARGET_TRANSPARENCY = 0.20,
    BLUR_EFFECT_SIZE = 12,

    TITLE_BAR_TRANSPARENCY = 0.25,
    TAB_SECTION_TRANSPARENCY = 0.25,
    CONTENT_SECTION_TRANSPARENCY = 0.25,
    SUBSECTION_FRAME_TRANSPARENCY = 0.20,
}
Config.TAB_BAR_SIZE = Config.TAB_BUTTON_SIZE + Config.PADDING * 2

print("Config.lua: Loaded and executed.")
