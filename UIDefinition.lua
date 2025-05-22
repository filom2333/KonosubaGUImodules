--- START OF FILE UIDefinition.lua ---
-- 8. UI Definition Data
-- This file relies on FeatureController, NotificationService, and ControlFactory being globally available.
MY_UI_TABS_DEFINITION = {
    { Name = "А", Order = 1, Scrolling = true, sections = { { title = "Основные Настройки Aimbot", description = "Точная настройка параметров прицеливания.", elements = { { type = "toggle", internalName = "EnableAimbot", label = "Aimbot", initialState = FeatureController:isAimbotFeatureEnabled(), callback = function(newState) FeatureController:setAimbotFeatureEnabled(newState) end }, { type = "checkbox", text = "Плавное наведение", initialState = true, callback = function(isChecked) NotificationService:show("Плавное наведение: " .. (isChecked and "ВКЛ" or "ВЫКЛ"), 1) end }, { type = "slider", internalName = "AimbotFOV", label = "Aimbot FOV", minVal = 1, maxVal = 360, initialVal = 90, step = 1, callback = function(value) NotificationService:show("Aimbot FOV: " .. value, 1) end }, { type = "switch_buttons", internalName = "AimbotTargetBone", label = "Цель Aimbot", options = {"Голова", "Шея", "Тело"}, initialOption = "Голова", callback = function(selectedOption) NotificationService:show("Цель Aimbot: " .. selectedOption, 1.5) end } } }, { title = "Дополнительно", elements = { { type = "checkbox", text = "Автоматический выстрел", initialState = false, callback = function(isChecked) NotificationService:show("Авто-выстрел: " .. (isChecked and "ВКЛ" or "ВЫКЛ"), 1) end }, { type = "checkbox", text = "Проверка видимости", initialState = true, callback = function(isChecked) NotificationService:show("Проверка видимости: " .. (isChecked and "ВКЛ" or "ВЫКЛ"), 1) end } } } } },
    { Name = "Б", Order = 2, Scrolling = true, sections = { { title = "ESP (ВХ)", description = "Настройки отображения информации об игроках и объектах.", elements = { { type = "toggle", internalName = "EnableESP", label = "ESP", initialState = true, callback = function(newState) NotificationService:show("ESP: " .. (newState and "ВКЛ" or "ВЫКЛ"), 1.5) end }, { type = "checkbox", text = "ESP на союзников", initialState = false, callback = function(isChecked) NotificationService:show("ESP союзников: " .. (isChecked and "ВКЛ" or "ВЫКЛ"), 1) end }, { type = "checkbox", text = "Имена", initialState = true, callback = function(isChecked) NotificationService:show("ESP Имена: " .. (isChecked and "ВКЛ" or "ВЫКЛ"), 1) end }, { type = "checkbox", text = "Здоровье", initialState = true, callback = function(isChecked) NotificationService:show("ESP Здоровье: " .. (isChecked and "ВКЛ" or "ВЫКЛ"), 1) end }, { type = "checkbox", text = "Линии до игроков", initialState = false, callback = function(isChecked) NotificationService:show("ESP Линии: " .. (isChecked and "ВКЛ" or "ВЫКЛ"), 1) end }, { type = "slider", internalName = "ESPDistance", label = "Дистанция ESP", minVal = 50, maxVal = 2000, initialVal = 500, step = 50, callback = function(value) NotificationService:show("Дистанция ESP: " .. value, 1) end } } }, { title = "Chams (Заливка)", elements = { { type = "toggle", internalName = "EnableChams", label = "Chams", initialState = false, callback = function(newState) NotificationService:show("Chams: " .. (newState and "ВКЛ" or "ВЫКЛ"), 1) end }, { type = "checkbox", text = "Только видимые", initialState = true, callback = function(isChecked) NotificationService:show("Chams (видимые): " .. (isChecked and "ВКЛ" or "ВЫКЛ"), 1) end } } } } },
    { Name = "С", Order = 3, Scrolling = false, sections = { { title = "Клавиши Управления Меню", description = "Здесь можно настроить клавишу открытия/закрытия меню.", elements = { { type = "keybind_input", actionName = "Открыть/Закрыть Меню", initialKeybind = Enum.KeyCode.Insert, callback = function(action, newKey) NotificationService:show(action .. " -> " .. ControlFactory.keyCodeToString(newKey), 2) end } } }, { title = "Другие Настройки", elements = { {type="label", text = "Прочие настройки интерфейса или игры."}} } } },
    { Name = "+ settings", Order = 99, Scrolling = true, sections = {
        { title = "Настройки Интерфейса", description = "Настройки внешнего вида и поведения меню.", elements = {
            { type = "label", text = "Здесь будут элементы управления настройками." },
            { type = "checkbox", text = "Разрешить растягивание меню", initialState = FeatureController:isMenuResizingEnabled(), callback = function(isChecked) FeatureController:setMenuResizingEnabled(isChecked); NotificationService:show("Растягивание меню: " .. (isChecked and "ВКЛ" or "ВЫКЛ"), 1.5) end },
        } },
        { title = "Поведение Меню", description = "Настройки, связанные с автоматическим поведением меню.", elements = {
            {
                type = "keybind_input",
                actionName = "Г.К. Сворачивания",
                initialKeybind = FeatureController:getMinimizeHotkey(),
                internalName = "MinimizeHotkeyKeybind",
                callback = function(action, newKey)
                    FeatureController:setMinimizeHotkey(newKey)
                    NotificationService:show(action .. " -> " .. ControlFactory.keyCodeToString(newKey), 2)
                end
            },
            {
                type = "label",
                text = "Если клавиша не назначена, сворачивание по Г.К. отключено.",
                textSize = Config.TextSizes.Small,
                textColor = Color3.fromRGB(120,125,135),
                textWrapped = true,
                automaticSize = Enum.AutomaticSize.Y
            }
        } },
        { title = "Тестовая Секция Настроек", description = "Пример секции в настройках.", elements = {
            { type = "toggle", internalName = "TestSettingToggle", label = "Тестовый Переключатель", initialState = false, callback = function(newState) NotificationService:show("Тестовый переключатель: " .. (newState and "ВКЛ" or "ВЫКЛ"), 1) end },
            { type = "slider", internalName = "TestSettingSlider", label = "Тестовый Слайдер", minVal = 0, maxVal = 10, initialVal = 5, step = 1, callback = function(value) NotificationService:show("Тестовый слайдер: " .. value, 1) end },
            { type = "switch_buttons", internalName = "TestSettingSwitch", label = "Тестовый Выбор", options = {"Опция 1", "Опция 2", "Опция 3"}, initialOption = "Опция 2", callback = function(selectedOption) NotificationService:show("Тестовый выбор: " .. selectedOption, 1.5) end
            }
        } }
    } },
}
print("HG: UIDefinition loaded")
--- END OF FILE UIDefinition.lua ---
