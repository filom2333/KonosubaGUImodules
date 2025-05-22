-- Content for NotificationService.lua
-- Original lines: 48-149

local NotificationService = {}
do -- NotificationService Scope
    local Cfg
    local Tsrv

    NotificationService.frame = nil
    NotificationService.textLabel = nil
    NotificationService.showTween = nil
    NotificationService.hideTween = nil
    NotificationService.timer = nil -- 
    NotificationService.isInitialized = false
    NotificationService.screenGuiRef = nil
    NotificationService.notificationConfig = nil

    function NotificationService:_createGuiElements()
        if self.frame and self.frame.Parent then return end
        if not (self.screenGuiRef and self.screenGuiRef.Parent) then return end

        local NOTIFICATION_CORNER_RADIUS = 10
        local NOTIFICATION_STROKE_THICKNESS = 3
        local NOTIFICATION_BG_TRANSPARENCY_VISIBLE = 0.1

        local bgColor = Color3.fromRGB(30, 35, 40) -- 
        local strokeColor = Color3.fromRGB(20, 25, 30) -- 
        local textColor = Color3.fromRGB(190, 195, 205) -- 

        self.frame = Instance.new("Frame")
        self.frame.Name = "CustomNotificationFrame"
        self.frame.Size = UDim2.new(0, self.notificationConfig.WIDTH, 0, self.notificationConfig.HEIGHT)
        self.frame.Position = UDim2.new(1, self.notificationConfig.WIDTH + self.notificationConfig.PADDING_X, 1, -(self.notificationConfig.HEIGHT + self.notificationConfig.PADDING_Y))
        self.frame.BackgroundColor3 = bgColor
        self.frame.BackgroundTransparency = 1
        self.frame.BorderSizePixel = 0 -- 
        self.frame.ZIndex = 10000 -- 
        self.frame.ClipsDescendants = true -- 
        self.frame.Parent = self.screenGuiRef -- 

        local uiC = Instance.new("UICorner", self.frame) -- 
        uiC.CornerRadius = UDim.new(0, NOTIFICATION_CORNER_RADIUS) -- 
        local uiS = Instance.new("UIStroke", self.frame) -- 
        uiS.Color = strokeColor -- 
        uiS.Thickness = NOTIFICATION_STROKE_THICKNESS -- 
        uiS.ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- 
        local uiP = Instance.new("UIPadding", self.frame) -- 
        uiP.PaddingLeft = UDim.new(0, 10); -- 
        uiP.PaddingRight = UDim.new(0, 10) -- 
        uiP.PaddingTop = UDim.new(0, 8); -- 
        uiP.PaddingBottom = UDim.new(0, 8) -- 

        self.textLabel = Instance.new("TextLabel")
        self.textLabel.Name = "NotificationText"
        self.textLabel.Size = UDim2.new(1, 0, 1, 0)
        self.textLabel.BackgroundTransparency = 1
        self.textLabel.Font = Cfg.Fonts.Default
        self.textLabel.Text = ""
        self.textLabel.TextColor3 = textColor
        self.textLabel.TextTransparency = 1
        self.textLabel.TextSize = 13
        self.textLabel.TextWrapped = true -- 
        self.textLabel.TextXAlignment = Enum.TextXAlignment.Left -- 
        self.textLabel.TextYAlignment = Enum.TextYAlignment.Center -- 
        self.textLabel.Parent = self.frame -- 
        self.isInitialized = true -- 
    end

    function NotificationService:init(parentScreenGui, injectedConfig, injectedTweenService)
        self.screenGuiRef = parentScreenGui
        Cfg = injectedConfig
        Tsrv = injectedTweenService
        self.notificationConfig = Cfg.Notification
    end -- 

    function NotificationService:show(message, duration)
        if not Cfg or not Tsrv then
            warn("NotificationService not initialized!")
            return
        end
        duration = duration or self.notificationConfig.DURATION
        if not (self.screenGuiRef and self.screenGuiRef.Parent) then return end
        if not self.isInitialized or not (self.frame and self.frame.Parent) then
            self:_createGuiElements() -- 
            if not self.frame then return end -- 
        end

        local NOTIFICATION_BG_TRANSPARENCY_VISIBLE = 0.1

        self.textLabel.Text = message
        if self.showTween and self.showTween.PlaybackState == Enum.PlaybackState.Playing then self.showTween:Cancel() end
        if self.hideTween and self.hideTween.PlaybackState == Enum.PlaybackState.Playing then self.hideTween:Cancel() end
        if self.timer then task.cancel(self.timer); self.timer = nil; end -- 

        self.frame.Position = UDim2.new(1, self.notificationConfig.WIDTH + self.notificationConfig.PADDING_X, 1, -(self.notificationConfig.HEIGHT + self.notificationConfig.PADDING_Y)) -- 
        self.frame.BackgroundTransparency = 1 -- 
        self.textLabel.TextTransparency = 1 -- 
        self.frame.Visible = true -- 

        local targetPosShow = UDim2.new(1, -(self.notificationConfig.WIDTH + self.notificationConfig.PADDING_X), 1, -(self.notificationConfig.HEIGHT + self.notificationConfig.HEIGHT + self.notificationConfig.PADDING_Y)) -- 
        local tweenInfoShow = TweenInfo.new(self.notificationConfig.FADE_TIME, self.notificationConfig.EASING_STYLE, Enum.EasingDirection.Out) -- 

        self.showTween = Tsrv:Create(self.frame, tweenInfoShow, {Position = targetPosShow, BackgroundTransparency = NOTIFICATION_BG_TRANSPARENCY_VISIBLE}) -- 
        local txtShowTween = Tsrv:Create(self.textLabel, tweenInfoShow, {TextTransparency = 0}) -- 

        self.showTween:Play() -- 
        txtShowTween:Play() -- 

        self.timer = task.delay(duration, function()
            if not (self.frame and self.frame.Parent) then return end
            local targetPosHide = UDim2.new(1, self.notificationConfig.WIDTH + self.notificationConfig.PADDING_X, 1, -(self.notificationConfig.HEIGHT + self.notificationConfig.PADDING_Y)) -- 
            local tweenInfoHide = TweenInfo.new(self.notificationConfig.FADE_TIME, self.notificationConfig.EASING_STYLE, Enum.EasingDirection.In) -- 

            self.hideTween = Tsrv:Create(self.frame, tweenInfoHide, {Position = targetPosHide, BackgroundTransparency = 1}) -- 
            local txtHideTween = Tsrv:Create(self.textLabel, tweenInfoHide, {TextTransparency = 1}) -- 

            self.hideTween:Play() -- 
            txtHideTween:Play() -- 

            self.hideTween.Completed:Connect(function()
                if self.frame then self.frame.Visible = false end
                self.timer = nil -- 
            end)
        end)
    end
end -- NotificationService Scope End 

return NotificationService -- Or ensure NotificationService is global
