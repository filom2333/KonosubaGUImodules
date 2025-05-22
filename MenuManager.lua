-- Content for MenuManager.lua
-- Original lines: 1027-1324
local MenuManager = {}
do -- MenuManager Scope
    MenuManager.screenGui = nil; MenuManager.mainFrame = nil; MenuManager.mainDragConnection = nil; MenuManager.isMinimized = false; MenuManager.originalMainFrameWidth = 0; MenuManager.originalMainFrameHeight = 0; MenuManager.mainWorkingAreaRef = nil; -- 
    MenuManager.originalWorkingAreaSize = nil; MenuManager.settingsButton = nil; MenuManager.resizeHandle = nil; MenuManager.resizeDragConnection = nil; MenuManager.minimizedStrip = nil; -- 
    MenuManager.minimizedStripHeight = 12; MenuManager.minimizedStripWidth = 120; MenuManager.minimizedStripTopMargin = 10; -- Positioned 10px from top -- 
    MenuManager.minimizedStripHoverOffset = 4; MenuManager.isAnimatingMinimize = false; MenuManager.minimizedStripBaseTransparency = 0.85 -- 
    local blurEffect = nil -- 

    local MENU_ANIM_DURATION = 0.3; local MENU_ANIM_STYLE = Enum.EasingStyle.Quint; local MENU_ANIM_DIRECTION_OPEN = Enum.EasingDirection.Out; local MENU_CLOSE_CONTENT_SHRINK_FACTOR = 0.7; local MENU_OPEN_INITIAL_SCALE = 0.8; -- 
    local MENU_OPEN_CONTENT_DELAY = 0.1 -- 

    local MINIMIZE_ANIM_DURATION = 0.35 -- 
    local MINIMIZE_FRAME_SCALE_FACTOR = 0.9 -- 
    local MINIMIZE_EASING_STYLE = Enum.EasingStyle.Quint -- 
    local MINIMIZE_CONTENT_DURATION_FACTOR = 0.6 -- 
    local MINIMIZE_STRIP_ANIM_DURATION_FACTOR = 0.8 -- 
    local MINIMIZE_STRIP_ENTRY_DELAY_FACTOR = 0.15 -- 

    local function _createMMUIElements(parentInstance, elementDefinition, namedElementsTable) namedElementsTable = namedElementsTable or {}; local instance = Instance.new(elementDefinition.InstanceType); for propName, propValue in pairs(elementDefinition.Properties or {}) do instance[propName] = propValue end; -- 
    if elementDefinition.Name then instance.Name = elementDefinition.Name; if namedElementsTable then namedElementsTable[elementDefinition.Name] = instance end end; instance.Parent = parentInstance; -- 
    for _, childDefinition in ipairs(elementDefinition.Children or {}) do _createMMUIElements(instance, childDefinition, namedElementsTable) end; -- 
    return instance, namedElementsTable end -- 

    function MenuManager:toggleMinimize()
        if self.isAnimatingMinimize then return end
        self.isAnimatingMinimize = true
        self.isMinimized = not self.isMinimized

        if not self.mainFrame or not self.mainFrame.Parent then
            self.isAnimatingMinimize = false
            return
        end

        local currentFrameWidth = self.originalMainFrameWidth == 0 and Config.FRAME_WIDTH or self.originalMainFrameWidth -- 
        local currentFrameHeight = self.originalMainFrameHeight == 0 and Config.FRAME_HEIGHT or self.originalMainFrameHeight -- 

        if self.isMinimized then
            if blurEffect then blurEffect.Enabled = false end
            if self.mainFrame.TitleBar then self.mainFrame.TitleBar.Active = false end
            if self.resizeHandle then self.resizeHandle.Visible = false end

            if self.mainWorkingAreaRef and self.mainWorkingAreaRef.Visible then -- 
                local workingAreaShrinkTweenInfo = TweenInfo.new( -- 
                    MINIMIZE_ANIM_DURATION * MINIMIZE_CONTENT_DURATION_FACTOR, -- 
                    MINIMIZE_EASING_STYLE, -- 
                    Enum.EasingDirection.In
                ) -- 
                local workingAreaShrinkTween = TweenService:Create(self.mainWorkingAreaRef, workingAreaShrinkTweenInfo, { -- 
                    Size = UDim2.new(self.mainWorkingAreaRef.Size.X.Scale, self.mainWorkingAreaRef.Size.X.Offset, 0, 0) -- 
                })
                workingAreaShrinkTween.Completed:Connect(function()
                    if self.mainWorkingAreaRef and self.isMinimized then -- 
                        self.mainWorkingAreaRef.Visible = false -- 
                    end
                end)
                workingAreaShrinkTween:Play() -- 
            end

            local frameMinimizeTweenInfo = TweenInfo.new( -- 
                MINIMIZE_ANIM_DURATION, -- 
                MINIMIZE_EASING_STYLE, -- 
                Enum.EasingDirection.In -- 
            )
            local frameMinimizeTween = TweenService:Create(self.mainFrame, frameMinimizeTweenInfo, {
                Position = UDim2.new(0.5, 0, -0.5, 0), -- 
                Size = UDim2.new(0, currentFrameWidth * MINIMIZE_FRAME_SCALE_FACTOR, 0, currentFrameHeight * MINIMIZE_FRAME_SCALE_FACTOR), -- 
                BackgroundTransparency = 1 -- 
            })
            frameMinimizeTween:Play() -- 

            frameMinimizeTween.Completed:Connect(function()
                if not self.isMinimized then return end -- 
                if not (self.minimizedStrip and self.minimizedStrip.Parent) then -- 
                    self.isAnimatingMinimize = false -- 
                end
            end)

            if self.minimizedStrip then
                task.delay(MINIMIZE_ANIM_DURATION * MINIMIZE_STRIP_ENTRY_DELAY_FACTOR, function() -- 
                    if not self.minimizedStrip or not self.minimizedStrip.Parent or not self.isMinimized then return end -- 

                    self.minimizedStrip.Visible = true -- 
                    self.minimizedStrip.Position = UDim2.new(0.5, 0, 0, self.minimizedStripTopMargin - self.minimizedStripHeight - 10) -- 
                    self.minimizedStrip.BackgroundTransparency = 1 -- 
                    self.minimizedStrip.TextTransparency = 1 -- 

                    local stripAppearTweenInfo = TweenInfo.new( -- 
                        MINIMIZE_ANIM_DURATION * MINIMIZE_STRIP_ANIM_DURATION_FACTOR, -- 
                        MINIMIZE_EASING_STYLE, -- 
                        Enum.EasingDirection.Out -- 
                    )
                    local stripAppearTween = TweenService:Create(self.minimizedStrip, stripAppearTweenInfo, {
                        Position = UDim2.new(0.5, 0, 0, self.minimizedStripTopMargin), -- 
                        BackgroundTransparency = self.minimizedStripBaseTransparency, -- 
                        TextTransparency = 0 -- 
                    })
                    stripAppearTween:Play() -- 
                    stripAppearTween.Completed:Connect(function() -- 
                        if self.isMinimized then -- 
                           self.isAnimatingMinimize = false -- 
                        end
                    end) -- 
                end)
            else
                frameMinimizeTween.Completed:Connect(function()
                    if self.isMinimized then self.isAnimatingMinimize = false end
                end) -- 
            end

        else -- When un-minimizing
            if self.minimizedStrip and self.minimizedStrip.Visible then
                local stripHideTweenInfo = TweenInfo.new(
                    MINIMIZE_ANIM_DURATION * MINIMIZE_STRIP_ANIM_DURATION_FACTOR,
                    MINIMIZE_EASING_STYLE, -- 
                    Enum.EasingDirection.In -- 
                )
                local stripHideTween = TweenService:Create(self.minimizedStrip, stripHideTweenInfo, {
                    Position = UDim2.new(0.5, 0, 0, self.minimizedStripTopMargin - self.minimizedStripHeight - 10),
                    BackgroundTransparency = 1, -- 
                    TextTransparency = 1 -- 
                })
                stripHideTween.Completed:Connect(function()
                    if self.minimizedStrip then self.minimizedStrip.Visible = false end
                end) -- 
                stripHideTween:Play() -- 
            end

            self.mainFrame.Position = UDim2.new(0.5, 0, -0.5, 0) -- 
            self.mainFrame.Size = UDim2.new(0, currentFrameWidth * MINIMIZE_FRAME_SCALE_FACTOR, 0, currentFrameHeight * MINIMIZE_FRAME_SCALE_FACTOR) -- 
            self.mainFrame.BackgroundTransparency = 1 -- 
            if self.mainWorkingAreaRef and self.originalWorkingAreaSize then -- 
                 self.mainWorkingAreaRef.Visible = false -- 
                 self.mainWorkingAreaRef.Size = UDim2.new(self.originalWorkingAreaSize.X.Scale, self.originalWorkingAreaSize.X.Offset, 0, 0) -- 
            end

            local frameRestoreTweenInfo = TweenInfo.new(
                MINIMIZE_ANIM_DURATION,
                MINIMIZE_EASING_STYLE, -- 
                Enum.EasingDirection.Out -- 
            )
            task.delay(MINIMIZE_ANIM_DURATION * (1 - MINIMIZE_STRIP_ANIM_DURATION_FACTOR) * 0.5, function() -- 
                if not self.mainFrame or not self.mainFrame.Parent or self.isMinimized then return end -- 

                local frameRestoreTween = TweenService:Create(self.mainFrame, frameRestoreTweenInfo, {
                    Position = UDim2.new(0.5, 0, 0.5, 0), -- 
                    Size = UDim2.new(0, currentFrameWidth, 0, currentFrameHeight), -- 
                    BackgroundTransparency = Config.FRAME_TARGET_TRANSPARENCY -- 
                })
                frameRestoreTween:Play() -- 

                frameRestoreTween.Completed:Connect(function() -- 
                    if self.isMinimized then return end -- 

                    if self.mainFrame.TitleBar then self.mainFrame.TitleBar.Active = true end -- 
                    if self.resizeHandle and FeatureController:isMenuResizingEnabled() then self.resizeHandle.Visible = true end -- 
                    if blurEffect then blurEffect.Enabled = true end -- 

                    if self.mainWorkingAreaRef and self.originalWorkingAreaSize then -- 
                        self.mainWorkingAreaRef.Visible = true -- 
                        local workingAreaExpandTweenInfo = TweenInfo.new(
                            MINIMIZE_ANIM_DURATION * (MINIMIZE_CONTENT_DURATION_FACTOR + 0.2), -- 
                            MINIMIZE_EASING_STYLE, -- 
                            Enum.EasingDirection.Out
                        ) -- 
                        local workingAreaExpandTween = TweenService:Create(self.mainWorkingAreaRef, workingAreaExpandTweenInfo, { -- 
                            Size = self.originalWorkingAreaSize -- 
                        })
                        workingAreaExpandTween:Play() -- 
                        workingAreaExpandTween.Completed:Connect(function()
                            if not self.isMinimized then
                                self.isAnimatingMinimize = false -- 
                            end
                        end)
                    else
                        self.isAnimatingMinimize = false -- 
                    end
                end)
            end)
        end
    end

    function MenuManager:_createBaseGui()
        local colorPrimaryBackground = Color3.fromRGB(20, 25, 30)
        local colorSecondaryBackground = Color3.fromRGB(30, 35, 40)
        local colorAccentStrokeMain = Color3.fromRGB(50, 60, 70) -- 
        local colorTextPrimary = Color3.fromRGB(190, 195, 205) -- 
        local CORNER_RADIUS_MEDIUM_VAL = 8 -- 
        local stripColor = Color3.fromRGB(60, 60, 60) -- 
        local stripIconColor = Color3.fromRGB(220, 220, 220) -- 
        local resizeHandleColor = Color3.fromRGB(80, 90, 100) -- 

        local TITLE_BUTTON_HEIGHT = Config.TITLE_BAR_HEIGHT - Config.PADDING * 1.8 -- 
        local TITLE_BUTTON_WIDTH = TITLE_BUTTON_HEIGHT * 1.2 -- 
        local TITLE_BUTTON_SPACING = Config.PADDING * 0.5 -- 
        local TITLE_BUTTON_CORNER_RADIUS = 10 -- 

        local colorSettingsButtonBgNormal = Color3.fromRGB(20, 80, 30) -- 
        local colorSettingsButtonBgHover  = Color3.fromRGB(30, 100, 40) -- 
        local colorMinimizeButtonBgNormal = Color3.fromRGB(60, 100, 160) -- 
        local colorMinimizeButtonBgHover  = Color3.fromRGB(80, 120, 180) -- 
        local colorCloseButtonBgNormal    = Color3.fromRGB(160, 40, 40) -- 
        local colorCloseButtonBgHover     = Color3.fromRGB(190, 50, 50) -- 

        local buttonGroupWidth = (TITLE_BUTTON_WIDTH * 3) + (TITLE_BUTTON_SPACING * 2) -- 
        local buttonGroupFrameXOffset = Config.PADDING * 0.8 -- 
        local buttonGroupFrameYOffset = Config.PADDING * 0.2 -- 

        local screenGuiStructure = { InstanceType = "ScreenGui", Name = "MyModernMenuScreenGui", Properties = { ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, -- 
            Children = {
                { InstanceType = "TextButton", Name = "MinimizedStrip", Properties = { AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0, self.minimizedStripWidth, 0, self.minimizedStripHeight), Position = UDim2.new(0.5, 0, 0, self.minimizedStripTopMargin - self.minimizedStripHeight - 10), BackgroundColor3 = stripColor, BorderSizePixel = 0, BackgroundTransparency = 1, TextTransparency = 1, Visible = false, ZIndex = 10001, AutoButtonColor = false, Text = "▼", Font = Config.Fonts.Bold, TextSize = 14, TextColor3 = stripIconColor, ClipsDescendants = true, }, Children = { { InstanceType = "UICorner", Properties = { CornerRadius = UDim.new(0, self.minimizedStripHeight / 2) } } } }, -- 
                { InstanceType = "Frame", Name = "MainFrame", Properties = { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, Config.FRAME_WIDTH * MENU_OPEN_INITIAL_SCALE, 0, Config.FRAME_HEIGHT * MENU_OPEN_INITIAL_SCALE), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1, BackgroundColor3 = colorPrimaryBackground, BorderSizePixel = 0, Active = true, ClipsDescendants = true, }, -- 
                    Children = { -- 
                        { InstanceType = "UICorner", Properties = { CornerRadius = UDim.new(0, Config.CORNER_RADIUS_BIG) } }, -- 
                        { InstanceType = "UIStroke", Properties = { Color = colorAccentStrokeMain, Thickness = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border } }, -- 
                        { InstanceType = "Frame", Name = "TitleBar", Properties = { Size = UDim2.new(1, -Config.PADDING * 2, 0, Config.TITLE_BAR_HEIGHT), Position = UDim2.new(0, Config.PADDING, 0, Config.PADDING), BackgroundColor3 = colorSecondaryBackground, BackgroundTransparency = Config.TITLE_BAR_TRANSPARENCY, BorderSizePixel = 0, ZIndex = 2 }, -- 
                            Children = {
                                { InstanceType = "UICorner", Properties = { CornerRadius = UDim.new(0, CORNER_RADIUS_MEDIUM_VAL) } }, -- 
                                { InstanceType = "TextLabel", Name = "TitleLabel", Properties = { Size = UDim2.new(1, -(buttonGroupWidth + Config.PADDING + buttonGroupFrameXOffset), 1, 0), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, Font = Config.Fonts.Semibold, Text = Config.FRAME_TITLE, TextColor3 = colorTextPrimary, TextSize = Config.TextSizes.Large, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, }, Children = { { InstanceType = "UIPadding", Properties = { PaddingLeft = UDim.new(0,12) } } } }, -- 
                                { InstanceType = "Frame", Name = "ButtonBackgroundFrame", Properties = { -- 
                                        Size = UDim2.new(0, buttonGroupWidth, 1, 0), -- 
                                        Position = UDim2.new(1, -(buttonGroupWidth + buttonGroupFrameXOffset) , 0.5, buttonGroupFrameYOffset ), -- 
                                        AnchorPoint = Vector2.new(0,0.5), BackgroundTransparency = 1, BorderSizePixel = 0, -- 
                                    }, -- 
                                    Children = {
                                        { InstanceType = "UIListLayout", Properties = { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, TITLE_BUTTON_SPACING)} }, -- 
                                        { InstanceType = "TextButton", Name = "SettingsButton", Properties = { -- 
                                            Size = UDim2.new(0, TITLE_BUTTON_WIDTH, 0, TITLE_BUTTON_HEIGHT), BackgroundColor3 = colorSettingsButtonBgNormal, AutoButtonColor = false, -- 
                                            Text = "", BackgroundTransparency = 0, LayoutOrder = 1 -- 
                                        }, Children = { { InstanceType = "UICorner", Properties = { CornerRadius = UDim.new(0,TITLE_BUTTON_CORNER_RADIUS) } } } }, -- 
                                        { InstanceType = "TextButton", Name = "MinimizeButton", Properties = { -- 
                                            Size = UDim2.new(0, TITLE_BUTTON_WIDTH, 0, TITLE_BUTTON_HEIGHT), BackgroundColor3 = colorMinimizeButtonBgNormal, AutoButtonColor = false, -- 
                                            Text = "", BackgroundTransparency = 0, LayoutOrder = 2 -- 
                                        }, Children = { { InstanceType = "UICorner", Properties = { CornerRadius = UDim.new(0,TITLE_BUTTON_CORNER_RADIUS) } } } }, -- 
                                        { InstanceType = "TextButton", Name = "CloseButton", Properties = { -- 
                                            Size = UDim2.new(0, TITLE_BUTTON_WIDTH, 0, TITLE_BUTTON_HEIGHT), BackgroundColor3 = colorCloseButtonBgNormal, AutoButtonColor = false, -- 
                                            Text = "", BackgroundTransparency = 0, LayoutOrder = 3 -- 
                                        }, Children = { { InstanceType = "UICorner", Properties = { CornerRadius = UDim.new(0,TITLE_BUTTON_CORNER_RADIUS) } } } } -- 
                                    } -- 
                                },
                            }
                        },
                        { InstanceType = "Frame", Name = "MainWorkingArea", Properties = { Size = UDim2.new(1, -Config.PADDING * 2, 1, -(Config.TITLE_BAR_HEIGHT + Config.PADDING * 2)), Position = UDim2.new(0, Config.PADDING, 0, Config.TITLE_BAR_HEIGHT + Config.PADDING * 1.5), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ClipsDescendants = true, ZIndex = 1 }, -- 
                            Children = {
                                { InstanceType = "UIListLayout", Properties = { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Left, VerticalAlignment = Enum.VerticalAlignment.Top, Padding = UDim.new(0, Config.PADDING) } }, -- 
                                { InstanceType = "Frame", Name = "TabsSection", Properties = { Size = UDim2.new(0, Config.TAB_BAR_SIZE, 1, 0), BackgroundColor3 = colorSecondaryBackground, BackgroundTransparency = Config.TAB_SECTION_TRANSPARENCY, BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = 1 }, -- 
                                    Children = { { InstanceType = "UICorner", Properties = { CornerRadius = UDim.new(0, CORNER_RADIUS_MEDIUM_VAL) } }, { InstanceType = "UIListLayout", Properties = { FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top, Padding = UDim.new(0, Config.PADDING / 2)} }, { InstanceType = "UIPadding", Properties = { PaddingTop = UDim.new(0, Config.PADDING), PaddingBottom = UDim.new(0, Config.PADDING), PaddingLeft = UDim.new(0, Config.PADDING / 2), PaddingRight = UDim.new(0, Config.PADDING / 2)} } } -- 
                                },
                                { InstanceType = "Frame", Name = "ContentSection", Properties = { Size = UDim2.new(1, -(Config.TAB_BAR_SIZE + Config.PADDING), 1, 0), BackgroundColor3 = colorSecondaryBackground, BackgroundTransparency = Config.CONTENT_SECTION_TRANSPARENCY, BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = 2 }, -- 
                                    Children = { { InstanceType = "UICorner", Properties = { CornerRadius = UDim.new(0, CORNER_RADIUS_MEDIUM_VAL) } }, { InstanceType = "UIPadding", Properties = { PaddingTop = UDim.new(0, Config.PADDING), PaddingBottom = UDim.new(0, Config.PADDING), PaddingLeft = UDim.new(0, Config.PADDING), PaddingRight = UDim.new(0, Config.PADDING)} } } -- 
                                } -- 
                            }
                        },
                        { InstanceType = "Frame", Name = "ResizeHandle", Properties = { Size = UDim2.new(0, Config.RESIZE_HANDLE_DIMENSION, 0, Config.RESIZE_HANDLE_DIMENSION), Position = UDim2.new(1, -Config.RESIZE_HANDLE_DIMENSION, 1, -Config.RESIZE_HANDLE_DIMENSION), AnchorPoint = Vector2.new(1, 1), BackgroundColor3 = resizeHandleColor, BackgroundTransparency = 0.3, BorderSizePixel = 0, Visible = FeatureController:isMenuResizingEnabled(), ZIndex = 3, Active = true, }, Children = { { InstanceType = "UICorner", Properties = {CornerRadius = UDim.new(0,3)} } } } -- 
                    }
                }
            }
        } -- 
        local namedElements = {}; self.screenGui, namedElements = _createMMUIElements(CoreGui, screenGuiStructure, namedElements); self.minimizedStrip = namedElements.MinimizedStrip; self.mainFrame = namedElements.MainFrame; self.settingsButton = namedElements.SettingsButton; self.mainWorkingAreaRef = namedElements.MainWorkingArea; -- 
        self.resizeHandle = namedElements.ResizeHandle; local titleBar = namedElements.TitleBar; self.originalWorkingAreaSize = self.mainWorkingAreaRef.Size; -- 
        NotificationService:init(self.screenGui, Config, TweenService) -- 
        
        self.minimizedStrip.MouseButton1Click:Connect(function() if self.isMinimized and not self.isAnimatingMinimize then self:toggleMinimize() end end) -- 
        self.minimizedStrip.MouseEnter:Connect(function() if self.isMinimized and self.minimizedStrip and self.minimizedStrip.Visible and not self.isAnimatingMinimize then TweenService:Create(self.minimizedStrip, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0, self.minimizedStripTopMargin + self.minimizedStripHoverOffset), Size = UDim2.new(0, self.minimizedStripWidth + 10, 0, self.minimizedStripHeight + 2) }):Play() end end) -- 
        self.minimizedStrip.MouseLeave:Connect(function() if self.isMinimized and self.minimizedStrip and self.minimizedStrip.Visible and not self.isAnimatingMinimize then TweenService:Create(self.minimizedStrip, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0, self.minimizedStripTopMargin), Size = UDim2.new(0, self.minimizedStripWidth, 0, self.minimizedStripHeight) }):Play() end end) -- 
        
        local btnAnimInfo = TweenInfo.new(0.1) -- 
        namedElements.SettingsButton.MouseEnter:Connect(function() TweenService:Create(namedElements.SettingsButton, btnAnimInfo, {BackgroundColor3 = colorSettingsButtonBgHover}):Play() end) -- 
        namedElements.SettingsButton.MouseLeave:Connect(function() TweenService:Create(namedElements.SettingsButton, btnAnimInfo, {BackgroundColor3 = colorSettingsButtonBgNormal}):Play() end) -- 
        namedElements.SettingsButton.MouseButton1Click:Connect(function() TabSystem:setActiveTab("+ settings") end) -- 

        namedElements.MinimizeButton.MouseEnter:Connect(function() TweenService:Create(namedElements.MinimizeButton, btnAnimInfo, {BackgroundColor3 = colorMinimizeButtonBgHover}):Play() end) -- 
        namedElements.MinimizeButton.MouseLeave:Connect(function() TweenService:Create(namedElements.MinimizeButton, btnAnimInfo, {BackgroundColor3 = colorMinimizeButtonBgNormal}):Play() end) -- 
        namedElements.MinimizeButton.MouseButton1Click:Connect(function() self:toggleMinimize() end) -- 

        namedElements.CloseButton.MouseEnter:Connect(function() TweenService:Create(namedElements.CloseButton, btnAnimInfo, {BackgroundColor3 = colorCloseButtonBgHover}):Play() end) -- 
        namedElements.CloseButton.MouseLeave:Connect(function() TweenService:Create(namedElements.CloseButton, btnAnimInfo, {BackgroundColor3 = colorCloseButtonBgNormal}):Play() end) -- 
        namedElements.CloseButton.MouseButton1Click:Connect(function() self:close() end) -- 
        
        TabSystem:init(namedElements.TabsSection, namedElements.ContentSection, Config, TweenService, ContentBuilder); self:_setupDragging(titleBar); self:_setupResizing(self.resizeHandle) -- 
    end

    function MenuManager:_setupDragging(draggableElement) local dragging = false; local dragInput, dragStart, startPos; draggableElement.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = input.Position; startPos = self.mainFrame.Position; local inputChangedConnection; inputChangedConnection = input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false; if inputChangedConnection then inputChangedConnection:Disconnect() end end end) end end); -- 
    draggableElement.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end); -- 
    self.mainDragConnection = UserInputService.InputChanged:Connect(function(input) if not (self.mainFrame and self.mainFrame.Parent) then if self.mainDragConnection then self.mainDragConnection:Disconnect(); self.mainDragConnection = nil; end; return end; if input == dragInput and dragging and not self.isMinimized and draggableElement.Active then local delta = input.Position - dragStart; self.mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end) end -- 
    function MenuManager:_setupResizing(resizeHandleElement) local resizing = false; local resizeDragStartMouse, resizeDragStartFrameSize; resizeHandleElement.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then if not self.mainFrame or not self.mainFrame.Parent or self.isMinimized or not FeatureController:isMenuResizingEnabled() then return end; resizing = true; resizeDragStartMouse = input.Position; resizeDragStartFrameSize = self.mainFrame.AbsoluteSize end end); -- 
    local function endResize() if resizing then resizing = false end end; -- 
    resizeHandleElement.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then endResize() end end); -- 
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then if resizing then endResize() end end end); -- 
    if self.resizeDragConnection then self.resizeDragConnection:Disconnect() end; self.resizeDragConnection = UserInputService.InputChanged:Connect(function(input) if not (self.mainFrame and self.mainFrame.Parent) then if self.resizeDragConnection then self.resizeDragConnection:Disconnect(); self.resizeDragConnection = nil; end; return end; if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then if resizing and not self.isMinimized then local delta = input.Position - resizeDragStartMouse; local newWidth = math.clamp(resizeDragStartFrameSize.X + delta.X, Config.RESIZE_HANDLE_MIN_FRAME_WIDTH, Config.RESIZE_HANDLE_MAX_FRAME_WIDTH); local newHeight = math.clamp(resizeDragStartFrameSize.Y + delta.Y, Config.RESIZE_HANDLE_MIN_FRAME_HEIGHT, Config.RESIZE_HANDLE_MAX_FRAME_HEIGHT); self.mainFrame.Size = UDim2.new(0, newWidth, 0, newHeight); self.originalMainFrameWidth = newWidth; self.originalMainFrameHeight = newHeight end end end) end -- 
    function MenuManager:updateResizeHandleVisibility(isVisible) if self.resizeHandle then self.resizeHandle.Visible = isVisible and not self.isMinimized end end -- 

    function MenuManager:open(tabsDefinition)
        if CoreGui:FindFirstChild("MyModernMenuScreenGui") then CoreGui.MyModernMenuScreenGui:Destroy(); self.mainFrame = nil end -- 
        self.isMinimized = false; self.originalMainFrameWidth = Config.FRAME_WIDTH; self.originalMainFrameHeight = Config.FRAME_HEIGHT; self.isAnimatingMinimize = false -- 
        if not blurEffect then blurEffect = Lighting:FindFirstChild("ModernMenuBlur") or Instance.new("BlurEffect", Lighting); blurEffect.Name = "ModernMenuBlur"; blurEffect.Size = Config.BLUR_EFFECT_SIZE; blurEffect.Enabled = false else blurEffect.Size = Config.BLUR_EFFECT_SIZE; -- 
        blurEffect.Enabled = false end -- 
        ControlFactory:init(Config, TweenService, UserInputService, NotificationService); ContentBuilder:init(Config, ControlFactory); FeatureController:init(UserInputService, MenuManager, NotificationService); -- 
        self:_createBaseGui(); if not self.mainFrame then return end; self:updateResizeHandleVisibility(FeatureController:isMenuResizingEnabled()) -- 
        local openTweenInfo = TweenInfo.new(MENU_ANIM_DURATION, MENU_ANIM_STYLE, MENU_ANIM_DIRECTION_OPEN); local mainFrameOpenAnimation = TweenService:Create(self.mainFrame, openTweenInfo, { Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, self.originalMainFrameWidth, 0, self.originalMainFrameHeight), BackgroundTransparency = Config.FRAME_TARGET_TRANSPARENCY }) -- 
        mainFrameOpenAnimation.Completed:Connect(function() if self.mainWorkingAreaRef and self.originalWorkingAreaSize then task.delay(MENU_OPEN_CONTENT_DELAY, function() if self.mainWorkingAreaRef and self.mainWorkingAreaRef.Parent then self.mainWorkingAreaRef.Visible = true; self.mainWorkingAreaRef.Size = self.originalWorkingAreaSize; local firstTabName = nil; for _, tabDef in ipairs(tabsDefinition) do if tabDef.Name ~= "+ settings" then firstTabName = tabDef.Name; break end end; if not firstTabName and #tabsDefinition > 0 and tabsDefinition[1].Name == "+ settings" and TabSystem.contentPages["+ settings"] then firstTabName = "+ settings" elseif not firstTabName and #tabsDefinition > 0 then firstTabName = tabsDefinition[1].Name end; if firstTabName and TabSystem.contentPages[firstTabName] then TabSystem:setActiveTab(firstTabName) else NotificationService:show("Вкладки не определены или первая вкладка не найдена!", 4) end end end) end; -- 
        if blurEffect then blurEffect.Enabled = true end; NotificationService:show(Config.FRAME_TITLE .. " загружено!", Config.Notification.DURATION) end); -- 
        mainFrameOpenAnimation:Play() -- 
        if not tabsDefinition or #tabsDefinition == 0 then NotificationService:show("Ошибка: Определения вкладок не предоставлены.", 4); return end; local settingsTabFound = false; for _, tabDef in ipairs(tabsDefinition) do local success, err = pcall(TabSystem.createTab, TabSystem, tabDef); -- 
        if not success then NotificationService:show("Ошибка создания вкладки: " .. (tabDef.Name or "N/A") .. " - " .. tostring(err), 5); -- 
        print("Error creating tab:", tabDef.Name, err) end; if tabDef.Name == "+ settings" then settingsTabFound = true end end; -- 
        if self.settingsButton then self.settingsButton.Visible = settingsTabFound end; for _, page in pairs(TabSystem.contentPages) do page.Visible = false end -- 
    end
    function MenuManager:close()
        if not self.mainFrame or not self.mainFrame.Parent then return end; NotificationService:show(Config.FRAME_TITLE .. " закрыто.", 2); if blurEffect then blurEffect.Enabled = false end -- 
        if self.minimizedStrip and self.minimizedStrip.Visible then self.minimizedStrip.Visible = false end; if self.resizeHandle then self.resizeHandle.Visible = false end -- 
        if self.mainWorkingAreaRef and self.mainWorkingAreaRef.Parent and self.mainWorkingAreaRef.Visible then local contentShrinkDuration = MENU_ANIM_DURATION * MENU_CLOSE_CONTENT_SHRINK_FACTOR; local contentTweenInfo = TweenInfo.new(contentShrinkDuration, MENU_ANIM_STYLE, Enum.EasingDirection.In); local contentCloseTween = TweenService:Create(self.mainWorkingAreaRef, contentTweenInfo, {Size = UDim2.new(self.mainWorkingAreaRef.Size.X.Scale, self.mainWorkingAreaRef.Size.X.Offset, 0,0)}); -- 
        contentCloseTween.Completed:Connect(function() if self.mainWorkingAreaRef and self.mainWorkingAreaRef.Parent then self.mainWorkingAreaRef.Visible = false end end); -- 
        contentCloseTween:Play() end -- 
        local closeTweenInfo = TweenInfo.new(MENU_ANIM_DURATION, MENU_ANIM_STYLE, Enum.EasingDirection.In); local mainFrameCloseAnimation = TweenService:Create(self.mainFrame, closeTweenInfo, { Position = UDim2.new(0.5,0,0.5,0), Size = UDim2.new(0,0,0,0), BackgroundTransparency = 1 }) -- 
        mainFrameCloseAnimation.Completed:Connect(function() if self.mainDragConnection then self.mainDragConnection:Disconnect(); self.mainDragConnection = nil end; if self.resizeDragConnection then self.resizeDragConnection:Disconnect(); self.resizeDragConnection = nil end; ControlFactory.cleanupSliderConnections(); FeatureController:cleanup(); TabSystem:clear(); if self.minimizedStrip and self.minimizedStrip.Parent then self.minimizedStrip:Destroy() end; self.minimizedStrip = nil; if self.screenGui and self.screenGui.Parent then self.screenGui:Destroy() end; self.screenGui = nil; self.mainFrame = nil; self.mainWorkingAreaRef = nil; self.resizeHandle = nil; self.isMinimized = false; self.originalMainFrameWidth = 0; self.originalMainFrameHeight = 0; self.originalWorkingAreaSize = nil; self.settingsButton = nil; -- 
        self.isAnimatingMinimize = false; if blurEffect then blurEffect:Destroy(); blurEffect = nil end end); -- 
        mainFrameCloseAnimation:Play() -- 
    end
end -- MenuManager Scope End 

return MenuManager -- Or ensure MenuManager is global
