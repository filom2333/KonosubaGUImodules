-- FeatureController.lua
-- Этот модуль управляет логикой специфичных функций, таких как горячие клавиши.
-- Он ожидает, что 'UserInputService', 'NotificationService'
-- и 'MenuManager' (для toggleMinimize и updateResizeHandleVisibility)
-- будут доступны в среде выполнения или переданы через init.

FeatureController = {}
do -- FeatureController Scope
    local UsrInSrv
    local MnuMgr -- Reference to MenuManager
    local NotifSrv -- Reference to NotificationService

    local minimizeHotkey = Enum.KeyCode.F2 -- Default value
    local minimizeHotkeyListenerConnection = nil
    local aimbotFeatureEnabled = true -- Default value, example
    local menuResizingEnabled = false -- Default value

    function FeatureController:_updateMinimizeListener()
        if minimizeHotkeyListenerConnection then
            minimizeHotkeyListenerConnection:Disconnect()
            minimizeHotkeyListenerConnection = nil
        end

        if not UsrInSrv then
            -- warn("FeatureController: UserInputService not available for minimize listener.")
            return
        end
        if not MnuMgr then
            -- warn("FeatureController: MenuManager not available for minimize listener.")
            return
        end

        if minimizeHotkey ~= Enum.KeyCode.Unknown then
            minimizeHotkeyListenerConnection = UsrInSrv.InputBegan:Connect(function(input, gameProcessedEvent)
                if gameProcessedEvent then return end
                local guiFocus = UsrInSrv:GetFocusedTextBox()
                if guiFocus then return end

                if input.KeyCode == minimizeHotkey then
                    -- Check if MenuManager and its necessary components are available and menu is not already minimized/animating
                    if MnuMgr and MnuMgr.screenGui and MnuMgr.screenGui.Parent and
                       not MnuMgr.isMinimized and not MnuMgr.isAnimatingMinimize then
                        MnuMgr:toggleMinimize()
                    end
                end
            end)
        end
    end

    -- init function expects UserInputService, MenuManager, NotificationService
    -- to be available (either globally or passed).
    function FeatureController:init(injectedUserInputService, injectedMenuManager, injectedNotificationService)
        UsrInSrv = injectedUserInputService or UserInputService
        MnuMgr = injectedMenuManager -- MenuManager is specific, less likely to be global
        NotifSrv = injectedNotificationService or NotificationService

        if not UsrInSrv then warn("FeatureController:init - UserInputService is not available.") end
        if not MnuMgr then warn("FeatureController:init - MenuManager was not provided.") end
        if not NotifSrv then warn("FeatureController:init - NotificationService is not available.") end

        self:_updateMinimizeListener()
        print("FeatureController: Initialized.")
    end

    function FeatureController:setMinimizeHotkey(keyCode)
        local newEffectiveKey = keyCode or Enum.KeyCode.Unknown
        if minimizeHotkey == newEffectiveKey then return end
        minimizeHotkey = newEffectiveKey
        self:_updateMinimizeListener()
        -- Optional: Notify user about the change, if NotifSrv is available
        -- if NotifSrv and ControlFactory and ControlFactory.keyCodeToString then
        -- NotifSrv:show("Minimize Hotkey set to: " .. ControlFactory.keyCodeToString(minimizeHotkey), 2)
        -- end
    end

    function FeatureController:getMinimizeHotkey()
        return minimizeHotkey
    end

    function FeatureController:setAimbotFeatureEnabled(enabled)
        if aimbotFeatureEnabled == enabled then return end
        aimbotFeatureEnabled = enabled
        if NotifSrv then NotifSrv:show("Aimbot (через FC): " .. (aimbotFeatureEnabled and "ВКЛ" or "ВЫКЛ"), 1.5)
        else warn("FeatureController: NotificationService not available for Aimbot status.") end
    end

    function FeatureController:isAimbotFeatureEnabled()
        return aimbotFeatureEnabled
    end

    function FeatureController:setMenuResizingEnabled(enabled)
        if menuResizingEnabled == enabled then return end
        menuResizingEnabled = enabled
        if MnuMgr and MnuMgr.updateResizeHandleVisibility then
            MnuMgr:updateResizeHandleVisibility(menuResizingEnabled)
        end
        -- Optional: Notify user
        -- if NotifSrv then
        -- NotifSrv:show("Menu Resizing: " .. (enabled and "Enabled" or "Disabled"), 1.5)
        -- end
    end

    function FeatureController:isMenuResizingEnabled()
        return menuResizingEnabled
    end

    function FeatureController:cleanup()
        if minimizeHotkeyListenerConnection then
            minimizeHotkeyListenerConnection:Disconnect()
            minimizeHotkeyListenerConnection = nil
        end
        minimizeHotkey = Enum.KeyCode.Unknown -- Reset to a default or unassigned state
        aimbotFeatureEnabled = true -- Reset to default
        menuResizingEnabled = false -- Reset to default
        print("FeatureController: Cleaned up listeners and states.")
    end

end -- FeatureController Scope End

print("FeatureController.lua: Loaded and executed.")
