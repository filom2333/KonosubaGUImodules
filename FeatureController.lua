-- Content for FeatureController.lua
-- Original lines: 920-1025
local FeatureController = {}
do -- FeatureController Scope
    local UsrInSrv; local MnuMgr; local NotifSrv -- 

    local minimizeHotkey = Enum.KeyCode.F2 -- 
    local minimizeHotkeyListenerConnection = nil -- 
    local aimbotFeatureEnabled = true -- 
    local menuResizingEnabled = false -- 

    function FeatureController:_updateMinimizeListener()
        if minimizeHotkeyListenerConnection then
            minimizeHotkeyListenerConnection:Disconnect()
            minimizeHotkeyListenerConnection = nil
        end
        if minimizeHotkey ~= Enum.KeyCode.Unknown and UsrInSrv and MnuMgr then
            minimizeHotkeyListenerConnection = UsrInSrv.InputBegan:Connect(function(input, gameProcessedEvent) -- 
                if gameProcessedEvent then return end
                local guiFocus = UsrInSrv:GetFocusedTextBox()
                if guiFocus then return end
                if input.KeyCode == minimizeHotkey then
                    if MnuMgr and MnuMgr.screenGui and MnuMgr.screenGui.Parent and not MnuMgr.isMinimized and not MnuMgr.isAnimatingMinimize then -- 
                        MnuMgr:toggleMinimize() -- 
                    end
                end
            end)
        end -- 
    end

    function FeatureController:init(injectedUserInputService, injectedMenuManager, injectedNotificationService)
        UsrInSrv = injectedUserInputService
        MnuMgr = injectedMenuManager
        NotifSrv = injectedNotificationService
        self:_updateMinimizeListener()
    end

    function FeatureController:setMinimizeHotkey(keyCode)
        local newEffectiveKey = keyCode or Enum.KeyCode.Unknown
        if minimizeHotkey == newEffectiveKey then return end
        minimizeHotkey = newEffectiveKey
        self:_updateMinimizeListener() -- 
    end

    function FeatureController:getMinimizeHotkey()
        return minimizeHotkey
    end

    function FeatureController:setAimbotFeatureEnabled(enabled)
        if aimbotFeatureEnabled == enabled then return end
        aimbotFeatureEnabled = enabled
        if NotifSrv then NotifSrv:show("Aimbot (через FC): " .. (aimbotFeatureEnabled and "ВКЛ" or "ВЫКЛ"), 1.5)
        else warn("NotificationService not available to FeatureController for Aimbot status.") end
    end
    function FeatureController:isAimbotFeatureEnabled() return aimbotFeatureEnabled end -- 

    function FeatureController:setMenuResizingEnabled(enabled)
        if menuResizingEnabled == enabled then return end
        menuResizingEnabled = enabled
        if MnuMgr and MnuMgr.updateResizeHandleVisibility then MnuMgr:updateResizeHandleVisibility(menuResizingEnabled) end
    end
    function FeatureController:isMenuResizingEnabled() return menuResizingEnabled end

    function FeatureController:cleanup()
        if minimizeHotkeyListenerConnection then
            minimizeHotkeyListenerConnection:Disconnect()
            minimizeHotkeyListenerConnection = nil -- 
        end
        minimizeHotkey = Enum.KeyCode.Unknown -- 
        menuResizingEnabled = false -- 
    end
end -- FeatureController Scope End 

return FeatureController -- Or ensure FeatureController is global
