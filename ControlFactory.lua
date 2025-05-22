-- Content for ControlFactory.lua
-- Original lines: 151-651
local ControlFactory = {}
do -- ControlFactory Scope
    local Cfg
    local Tsrv
    local UsrInSrv
    local NotifSrv

    ControlFactory.activeSliderDragConnections = {}
    ControlFactory.currentlyListeningKeybindInput = nil
    ControlFactory.keybindInputListenerConnection = nil

    local function _createElementsFromTree(parentInstance, elementDefinition, namedElementsTable)
        namedElementsTable = namedElementsTable or {} -- 
        local instance = Instance.new(elementDefinition.InstanceType) -- 

        for propName, propValue in pairs(elementDefinition.Properties or {}) do
            instance[propName] = propValue
        end

        if elementDefinition.Name then
            instance.Name = elementDefinition.Name
            if namedElementsTable then
                namedElementsTable[elementDefinition.Name] = instance -- 
            end
        end
        instance.Parent = parentInstance -- 

        for _, childDefinition in ipairs(elementDefinition.Children or {}) do
            _createElementsFromTree(instance, childDefinition, namedElementsTable)
        end

        return instance, namedElementsTable
    end

    function ControlFactory:init(injectedConfig, injectedTweenService, injectedUserInputService, injectedNotificationService) -- 
        Cfg = injectedConfig -- 
        Tsrv = injectedTweenService -- 
        UsrInSrv = injectedUserInputService -- 
        NotifSrv = injectedNotificationService -- 
    end

    function ControlFactory.keyCodeToString(keyCodeEnum)
        if not Cfg then return "CFG_N/A" end
        if not keyCodeEnum or keyCodeEnum == Enum.KeyCode.Unknown then
            return Cfg.KEYBIND_UNBOUND_TEXT
        end -- 
        local name = keyCodeEnum.Name -- 
        if string.sub(name, 1, 13) == "MouseButton" then -- 
            if name == "MouseButton1" then return "LMB" -- 
            elseif name == "MouseButton2" then return "RMB" -- 
            elseif name == "MouseButton3" then return "MMB" end -- 
        end
        if string.len(name) > 1 and string.sub(name, 1, 3) == "Key" and string.upper(string.sub(name, 4,4)) == string.sub(name, 4,4) then -- 
            local shortName = string.sub(name, 4) -- 
            if string.len(shortName) <= 4 then return shortName end -- 
        end
        if name == "LeftShift" then return "LShift" end; -- 
        if name == "RightShift" then return "RShift" end -- 
        if name == "LeftControl" then return "LCtrl" end; -- 
        if name == "RightControl" then return "RCtrl" end -- 
        if name == "LeftAlt" then return "LAlt" end; -- 
        if name == "RightAlt" then return "RAlt" end -- 
        if name == "Space" then return "Space" end; -- 
        if name == "PageUp" then return "PgUp" end -- 
        if name == "PageDown" then return "PgDown" end; -- 
        if name == "Home" then return "Home" end -- 
        if name == "End" then return "End" end; -- 
        if name == "Insert" then return "Ins" end -- 
        if name == "Delete" then return "Del" end -- 
        return name -- 
    end

    function ControlFactory.createLabel(parent, props)
        local labelTextColor = Color3.fromRGB(120, 125, 135)

        local labelDefinition = {
            InstanceType = "TextLabel",
            Name = (props.name or "InfoLabel"),
            Properties = { -- 
                Text = props.text or "", -- 
                Font = props.font or Cfg.Fonts.Default, -- 
                TextSize = props.textSize or Cfg.TextSizes.Default, -- 
                TextColor3 = props.textColor or labelTextColor, -- 
                TextWrapped = props.textWrapped == nil and true or props.textWrapped, -- 
                TextXAlignment = props.textXAlignment or Enum.TextXAlignment.Left, -- 
                TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Top, -- 
                BackgroundTransparency = 1, -- 
                LayoutOrder = props.layoutOrder or 0, -- 
            } -- 
        }

        if props.automaticSize and props.automaticSize == Enum.AutomaticSize.Y then -- 
            labelDefinition.Properties.Size = UDim2.new(props.size and props.size.X.Scale or 1, props.size and props.size.X.Offset or 0, 0,0) -- 
            labelDefinition.Properties.AutomaticSize = Enum.AutomaticSize.Y -- 
        else
            labelDefinition.Properties.Size = props.size or UDim2.new(1, 0, 0, (props.textSize or Cfg.TextSizes.Default) + Cfg.PADDING / 2) -- 
        end -- 

        local labelInstance, _ = _createElementsFromTree(parent, labelDefinition) -- 
        return labelInstance -- 
    end

    function ControlFactory.createHeader(parent, props)
        local headerTextColor = Color3.fromRGB(210, 215, 225)
        local textSize = Cfg.TextSizes.Header1
        if props.level == 2 then textSize = Cfg.TextSizes.Header2 end

        local headerDefinition = {
            InstanceType = "TextLabel", -- 
            Name = (props.name or "HeaderLabel"), -- 
            Properties = {
                Size = props.size or UDim2.new(1, 0, 0, textSize + Cfg.PADDING / 2), -- 
                Text = props.text or "Header", -- 
                Font = props.font or Cfg.Fonts.Bold, -- 
                TextSize = textSize, -- 
                TextColor3 = props.textColor or headerTextColor, -- 
                TextXAlignment = props.textXAlignment or Enum.TextXAlignment.Left, -- 
                TextYAlignment = props.textYAlignment or Enum.TextYAlignment.Center, -- 
                BackgroundTransparency = 1, -- 
                LayoutOrder = props.layoutOrder or 0, -- 
            }
        }
        local headerInstance, _ = _createElementsFromTree(parent, headerDefinition) -- 
        return headerInstance -- 
    end

    function ControlFactory.createToggleButton(parent, props)
        local labelText = props.label
        local initialState = props.initialState or false
        local callback = props.callback -- 
        local containerName = (props.internalName or labelText or "Unnamed") .. "ToggleContainer" -- 
        local hasLabel = labelText and labelText ~= "" -- 
        local toggleButtonWidth = 60; local toggleButtonHeight = 30 -- 
        local TOGGLE_ANIM_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out) -- 

        local colorToggleBgOn = Color3.fromRGB(70, 130, 180) -- 
        local colorToggleBgOff = Color3.fromRGB(40, 45, 50) -- 
        local colorToggleKnob = Color3.fromRGB(190, 195, 205) -- 
        local colorToggleKnobStroke = Color3.fromRGB(25, 30, 35) -- 
        local colorTextPrimary = Color3.fromRGB(190, 195, 205) -- 

        local knobPadding = 0; local knobDiameter = toggleButtonHeight - (knobPadding * 2) -- 
        local knobPositionX_Off = knobPadding -- 
        local knobPositionX_On = toggleButtonWidth - knobDiameter - knobPadding -- 

        local containerDefinition = {
            InstanceType = "Frame",
            Name = containerName,
            Properties = {
                BackgroundTransparency = 1, -- 
                LayoutOrder = props.layoutOrder or 0, -- 
                Size = hasLabel and UDim2.new(1, 0, 0, 40) or UDim2.new(1,0,0,0), -- 
                AutomaticSize = not hasLabel and Enum.AutomaticSize.Y or Enum.AutomaticSize.None -- 
            },
            Children = {} -- 
        } -- 

        if hasLabel then -- 
            table.insert(containerDefinition.Children, { -- 
                InstanceType = "TextLabel", Name = "Label", -- 
                Properties = { BackgroundTransparency = 1, Font = Cfg.Fonts.Default, Text = labelText, TextColor3 = colorTextPrimary, TextSize = Cfg.TextSizes.Large, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, Size = UDim2.new(1, -(toggleButtonWidth + Cfg.PADDING), 1, 0) } -- 
            }) -- 
        else
            table.insert(containerDefinition.Children, { InstanceType = "UIListLayout", Properties = { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 5) } }) -- 
        end

        table.insert(containerDefinition.Children, {
            InstanceType = "TextButton", Name = "ToggleButton",
            Properties = { -- 
                Size = UDim2.new(0, toggleButtonWidth, 0, toggleButtonHeight), -- 
                Position = hasLabel and UDim2.new(1, -toggleButtonWidth, 0.5, -toggleButtonHeight / 2) or UDim2.new(0,0,0,0), -- 
                LayoutOrder = not hasLabel and 1 or 0, -- 
                BackgroundColor3 = initialState and colorToggleBgOn or colorToggleBgOff, -- 
                BackgroundTransparency = 0, -- 
                BorderSizePixel = 0, Text = "", AutoButtonColor = false -- 
            },
            Children = {
                { InstanceType = "UICorner", Properties = { CornerRadius = UDim.new(0.5, 0) } }, -- 
                { -- 
                    InstanceType = "Frame", Name = "Knob", -- 
                    Properties = { Size = UDim2.new(0, knobDiameter, 0, knobDiameter), BackgroundColor3 = colorToggleKnob, BackgroundTransparency = 0, BorderSizePixel = 0, Position = UDim2.new(0, initialState and knobPositionX_On or knobPositionX_Off, 0.5, -knobDiameter / 2) }, -- 
                    Children = { { InstanceType = "UICorner", Properties = { CornerRadius = UDim.new(0.5, 0) } }, { InstanceType = "UIStroke", Name = "KnobStroke", Properties = { Color = colorToggleKnobStroke, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border } } } -- 
                }
            }
        })

        local containerInstance, elements = _createElementsFromTree(parent, containerDefinition) -- 
        local toggleButtonVisual = elements.ToggleButton; local knobVisual = elements.Knob -- 
        local currentState = initialState -- 
        toggleButtonVisual.MouseButton1Click:Connect(function()
            currentState = not currentState
            local targetColor = currentState and colorToggleBgOn or colorToggleBgOff
            local targetKnobX = currentState and knobPositionX_On or knobPositionX_Off
            Tsrv:Create(toggleButtonVisual, TOGGLE_ANIM_INFO, {BackgroundColor3 = targetColor}):Play()
            Tsrv:Create(knobVisual, TOGGLE_ANIM_INFO, {Position = UDim2.new(0, targetKnobX, 0.5, -knobDiameter / 2)}):Play() -- 
            if callback then pcall(callback, currentState) end -- 
        end)
        return containerInstance -- 
    end

    function ControlFactory.createSlider(parent, props)
        local labelText = props.label
        local minVal, maxVal, initialVal, step = props.minVal or 0, props.maxVal or 100, props.initialVal or 0, props.step or 1
        local callback = props.callback -- 
        initialVal = math.clamp(initialVal, minVal, maxVal); local currentValue = initialVal -- 
        local container = Instance.new("Frame", parent) -- 
        container.Name = (props.internalName or labelText or "Unnamed") .. "SliderContainer" -- 
        container.BackgroundTransparency = 1; container.LayoutOrder = props.layoutOrder or 0 -- 
        local hasLabel = labelText and labelText ~= "" -- 
        local labelHeight, sliderFrameHeight, sliderFrameYOffset = 20, 40, 0 -- 

        local colorSliderTrackBg = Color3.fromRGB(30, 35, 40) -- 
        local colorSliderFill = Color3.fromRGB(70, 130, 180) -- 
        local colorSliderHandle = Color3.fromRGB(190, 195, 205) -- 
        local colorSliderHandleStroke = Color3.fromRGB(25, 30, 35) -- 
        local colorTextPrimary = Color3.fromRGB(190, 195, 205) -- 
        local colorTextSecondary = Color3.fromRGB(120, 125, 135) -- 

        local valueLabel = Instance.new("TextLabel", container) -- 
        valueLabel.Name = "ValueLabel"; valueLabel.BackgroundTransparency = 1; valueLabel.Font = Cfg.Fonts.Bold; valueLabel.TextColor3 = colorTextSecondary; valueLabel.TextSize = Cfg.TextSizes.Default; valueLabel.TextXAlignment = Enum.TextXAlignment.Right; -- 
        valueLabel.Text = tostring(math.floor(currentValue / step) * step) -- 

        if hasLabel then -- 
            container.Size = UDim2.new(1, 0, 0, labelHeight + sliderFrameHeight); sliderFrameYOffset = labelHeight -- 
            local label = Instance.new("TextLabel", container) -- 
            label.Name = "Label"; label.Size = UDim2.new(0.7, -Cfg.PADDING/2, 0, labelHeight); label.Position = UDim2.new(0,0,0,0); label.BackgroundTransparency = 1; label.Font = Cfg.Fonts.Default; label.Text = labelText; -- 
            label.TextColor3 = colorTextPrimary; label.TextSize = Cfg.TextSizes.Default; label.TextXAlignment = Enum.TextXAlignment.Left; label.TextYAlignment = Enum.TextYAlignment.Center -- 
            valueLabel.Size = UDim2.new(0.3, 0, 0, labelHeight); valueLabel.Position = UDim2.new(0.7, 0, 0, 0); valueLabel.TextYAlignment = Enum.TextYAlignment.Center -- 
        else
            container.Size = UDim2.new(1, 0, 0, labelHeight + sliderFrameHeight) -- 
            valueLabel.Size = UDim2.new(1, 0, 0, labelHeight); valueLabel.Position = UDim2.new(0,0,0,0); valueLabel.TextXAlignment = Enum.TextXAlignment.Left; valueLabel.TextYAlignment = Enum.TextYAlignment.Center; sliderFrameYOffset = labelHeight -- 
        end
        local sliderFrame = Instance.new("Frame", container) -- 
        sliderFrame.Name = "SliderFrame"; sliderFrame.Size = UDim2.new(1,0,0, sliderFrameHeight); sliderFrame.Position = UDim2.new(0,0,0,sliderFrameYOffset); sliderFrame.BackgroundTransparency = 1 -- 
        local trackHeight = 18 -- 
        local track = Instance.new("Frame", sliderFrame) -- 
        track.Name = "Track"; track.Size = UDim2.new(1, 0, 0, trackHeight); track.Position = UDim2.new(0, 0, 0.5, -trackHeight / 2); track.BackgroundColor3 = colorSliderTrackBg; track.BorderSizePixel = 0; -- 
        track.BackgroundTransparency = 0 -- 
        Instance.new("UICorner", track).CornerRadius = UDim.new(0.5, 0) -- 
        local fill = Instance.new("Frame", track) -- 
        fill.Name = "Fill"; fill.Size = UDim2.new(0, 0, 1, 0); fill.BackgroundColor3 = colorSliderFill; fill.BorderSizePixel = 0; -- 
        fill.BackgroundTransparency = 0 -- 
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0.5, 0) -- 
        local handleDiameter = 28 -- 
        local handle = Instance.new("TextButton", sliderFrame) -- 
        handle.Name = "Handle"; handle.Size = UDim2.new(0, handleDiameter, 0, handleDiameter); handle.BackgroundColor3 = colorSliderHandle; handle.BorderSizePixel = 0; handle.Text = ""; handle.AutoButtonColor = false; -- 
        handle.ZIndex = 2; handle.BackgroundTransparency = 0 -- 
        Instance.new("UICorner", handle).CornerRadius = UDim.new(0.5, 0) -- 
        local handleStroke = Instance.new("UIStroke", handle); handleStroke.Color = colorSliderHandleStroke; handleStroke.Thickness = 1.5; handleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- 
        local draggingSlider = false; local sliderInputChangedConn = nil -- 
        local SUBSECTION_FRAME_PADDING_VAL = 9 -- 
        local SLIDER_ANIM_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out) -- 

        local function updateSliderVisuals(currentVal, an_imate)
            an_imate = an_imate == nil and false or an_imate
            local percent = (maxVal - minVal) > 0 and math.clamp((currentVal - minVal) / (maxVal - minVal), 0, 1) or 0
            local trackEffectiveWidth = sliderFrame.AbsoluteSize.X; if trackEffectiveWidth == 0 then trackEffectiveWidth = Cfg.FRAME_WIDTH - (Cfg.PADDING * 4) - (SUBSECTION_FRAME_PADDING_VAL * 2) end -- 
            local handleXOffset = math.clamp((percent * trackEffectiveWidth) - (handleDiameter / 2), 0, trackEffectiveWidth - handleDiameter) -- 
            local targetHandlePosition = UDim2.new(0, handleXOffset, 0.5, -handleDiameter / 2) -- 
            local targetFillSize = UDim2.new(0, math.min(handleXOffset + handleDiameter / 2, trackEffectiveWidth), 1, 0) -- 
            if an_imate then Tsrv:Create(fill, SLIDER_ANIM_INFO, {Size = targetFillSize}):Play(); Tsrv:Create(handle, SLIDER_ANIM_INFO, {Position = targetHandlePosition}):Play() -- 
            else fill.Size = targetFillSize; handle.Position = targetHandlePosition end -- 
            valueLabel.Text = tostring(math.floor(currentValue / step) * step) -- 
        end
        task.defer(updateSliderVisuals, currentValue, false) -- 
        local function processInput(inputPosition, isDrag)
            isDrag = isDrag == nil and false or isDrag
            if not sliderFrame or not sliderFrame.Parent then return end
            local relativeX = inputPosition.X - sliderFrame.AbsolutePosition.X; local trackEffectiveWidth = sliderFrame.AbsoluteSize.X; -- 
            if trackEffectiveWidth == 0 then return end -- 
            local newPercent = math.clamp(relativeX / trackEffectiveWidth, 0, 1); local rawValue = minVal + newPercent * (maxVal - minVal) -- 
            local newValue = math.clamp(math.floor(rawValue / step + 0.5) * step, minVal, maxVal) -- 
            if newValue ~= currentValue then currentValue = newValue; updateSliderVisuals(currentValue, isDrag); if callback then pcall(callback, currentValue) end end -- 
        end
        handle.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = true; processInput(input.Position, false); if sliderInputChangedConn and sliderInputChangedConn.Connected then sliderInputChangedConn:Disconnect() end; sliderInputChangedConn = UsrInSrv.InputChanged:Connect(function(subInput) if not (handle and handle.Parent) then if sliderInputChangedConn and sliderInputChangedConn.Connected then sliderInputChangedConn:Disconnect(); local idx = table.find(ControlFactory.activeSliderDragConnections, sliderInputChangedConn); if idx then table.remove(ControlFactory.activeSliderDragConnections, idx) end; sliderInputChangedConn = nil end; return end; if subInput.UserInputType == Enum.UserInputType.MouseMovement or subInput.UserInputType == Enum.UserInputType.Touch then if draggingSlider then processInput(subInput.Position, true) end end end); -- 
        local oldIdx = table.find(ControlFactory.activeSliderDragConnections, sliderInputChangedConn); if oldIdx then table.remove(ControlFactory.activeSliderDragConnections, oldIdx) end; -- 
        table.insert(ControlFactory.activeSliderDragConnections, sliderInputChangedConn) end end) -- 
        handle.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = false end end) -- 
        track.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then if not draggingSlider then processInput(input.Position, true) end end end) -- 
        container.Destroying:Connect(function() if sliderInputChangedConn and sliderInputChangedConn.Connected then sliderInputChangedConn:Disconnect(); local idx = table.find(ControlFactory.activeSliderDragConnections, sliderInputChangedConn); if idx then table.remove(ControlFactory.activeSliderDragConnections, idx) end; sliderInputChangedConn = nil end end) -- 
        return container -- 
    end

    function ControlFactory.createSwitchButtons(parent, props) -- 
        local labelText = props.label; local options = props.options or {"Opt1", "Opt2"}; local initialOption = props.initialOption; local callback = props.callback -- 
        local SWITCH_ANIM_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out) -- 
        local SWITCH_BUTTON_HEIGHT_VAL = 40; local SWITCH_BUTTON_LABEL_HEIGHT_VAL = 20; local SWITCH_BUTTON_SPACING_VAL = 10 -- 
        local CORNER_RADIUS_SWITCH_BUTTON_VAL = 8; local SWITCH_BUTTON_STROKE_THICKNESS_VAL = 1; local SWITCH_BUTTON_PADDING_X_VAL = 16 -- 
        local colorSwitchButtonBgNormal = Color3.fromRGB(40, 45, 50); local colorSwitchButtonBgHover = Color3.fromRGB(50, 55, 60); local colorSwitchButtonBgActive = Color3.fromRGB(70, 130, 180) -- 
        local colorSwitchButtonTextNormal = Color3.fromRGB(170, 175, 185); local colorSwitchButtonTextActive = Color3.fromRGB(230, 235, 245) -- 
        local colorSwitchButtonStrokeNormal = Color3.fromRGB(25,30,35); local colorTabButtonStrokeActive = Color3.fromRGB(90, 150, 200); local colorTextPrimary = Color3.fromRGB(190, 195, 205) -- 

        local mainContainer = Instance.new("Frame", parent); mainContainer.Name = (props.internalName or labelText or "Unnamed") .. "SwitchButtonsContainer"; mainContainer.BackgroundTransparency = 1; mainContainer.Size = UDim2.new(1, 0, 0, 0); -- 
        mainContainer.AutomaticSize = Enum.AutomaticSize.Y; mainContainer.LayoutOrder = props.layoutOrder or 0 -- 
        local mainListLayout = Instance.new("UIListLayout", mainContainer); mainListLayout.FillDirection = Enum.FillDirection.Vertical; mainListLayout.SortOrder = Enum.SortOrder.LayoutOrder; mainListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left; mainListLayout.Padding = UDim.new(0, Cfg.PADDING / 3) -- 
        if labelText and labelText ~= "" then local labelElement = Instance.new("TextLabel", mainContainer); labelElement.Name = "SwitchButtonsLabel"; labelElement.Size = UDim2.new(1, 0, 0, SWITCH_BUTTON_LABEL_HEIGHT_VAL); labelElement.Text = labelText; labelElement.Font = Cfg.Fonts.Default; labelElement.TextSize = Cfg.TextSizes.Default; -- 
        labelElement.TextColor3 = colorTextPrimary; labelElement.TextXAlignment = Enum.TextXAlignment.Left; labelElement.TextYAlignment = Enum.TextYAlignment.Center; labelElement.BackgroundTransparency = 1; -- 
        labelElement.LayoutOrder = 1 end -- 
        local buttonsFrame = Instance.new("Frame", mainContainer); buttonsFrame.Name = "ButtonsHolder"; buttonsFrame.BackgroundTransparency = 1; buttonsFrame.Size = UDim2.new(1, 0, 0, SWITCH_BUTTON_HEIGHT_VAL); buttonsFrame.LayoutOrder = (labelText and labelText ~= "") and 2 or 1 -- 
        local buttonsListLayout = Instance.new("UIListLayout", buttonsFrame); buttonsListLayout.FillDirection = Enum.FillDirection.Horizontal; buttonsListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left; buttonsListLayout.VerticalAlignment = Enum.VerticalAlignment.Center; buttonsListLayout.Padding = UDim.new(0, SWITCH_BUTTON_SPACING_VAL); -- 
        buttonsListLayout.SortOrder = Enum.SortOrder.LayoutOrder -- 
        local createdButtonsTable = {}; local currentActiveButton = nil -- 
        local function setActiveButtonVisuals(buttonInstance, strokeInstance, isActive) local targetBgColor = isActive and colorSwitchButtonBgActive or colorSwitchButtonBgNormal; local targetTextColor = isActive and colorSwitchButtonTextActive or colorSwitchButtonTextNormal; local targetStrokeColor = isActive and colorTabButtonStrokeActive or colorSwitchButtonStrokeNormal; -- 
        Tsrv:Create(buttonInstance, SWITCH_ANIM_INFO, {BackgroundColor3 = targetBgColor, TextColor3 = targetTextColor}):Play(); if strokeInstance then Tsrv:Create(strokeInstance, SWITCH_ANIM_INFO, {Color = targetStrokeColor}):Play() end end -- 
        local function selectButton(buttonToActivateRef) if currentActiveButton and currentActiveButton.button == buttonToActivateRef.button then return end; if currentActiveButton then setActiveButtonVisuals(currentActiveButton.button, currentActiveButton.stroke, false) end; currentActiveButton = buttonToActivateRef; setActiveButtonVisuals(currentActiveButton.button, currentActiveButton.stroke, true); -- 
        if callback then pcall(callback, currentActiveButton.button.Text) end end -- 
        for i, optionTextValue in ipairs(options) do local switchButton = Instance.new("TextButton", buttonsFrame); switchButton.Name = "SwitchButton_" .. optionTextValue:gsub("%s+", ""); switchButton.Text = optionTextValue; switchButton.Font = Cfg.Fonts.Semibold; switchButton.TextSize = Cfg.TextSizes.Default; -- 
        switchButton.Size = UDim2.new(0, 0, 1, 0); switchButton.AutomaticSize = Enum.AutomaticSize.X; switchButton.AutoButtonColor = false; switchButton.LayoutOrder = i; switchButton.BackgroundTransparency = 0; -- 
        Instance.new("UICorner", switchButton).CornerRadius = UDim.new(0, CORNER_RADIUS_SWITCH_BUTTON_VAL); local stroke = Instance.new("UIStroke", switchButton); stroke.Thickness = SWITCH_BUTTON_STROKE_THICKNESS_VAL; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; -- 
        local padding = Instance.new("UIPadding", switchButton); padding.PaddingLeft = UDim.new(0, SWITCH_BUTTON_PADDING_X_VAL); padding.PaddingRight = UDim.new(0, SWITCH_BUTTON_PADDING_X_VAL); -- 
        local buttonRef = {button = switchButton, stroke = stroke}; table.insert(createdButtonsTable, buttonRef); -- 
        switchButton.MouseEnter:Connect(function() if currentActiveButton ~= buttonRef then Tsrv:Create(switchButton, SWITCH_ANIM_INFO, {BackgroundColor3 = colorSwitchButtonBgHover}):Play() end end); -- 
        switchButton.MouseLeave:Connect(function() if currentActiveButton ~= buttonRef then Tsrv:Create(switchButton, SWITCH_ANIM_INFO, {BackgroundColor3 = colorSwitchButtonBgNormal}):Play() end end); switchButton.MouseButton1Click:Connect(function() selectButton(buttonRef) end); -- 
        setActiveButtonVisuals(switchButton, stroke, false) end -- 
        local initialButtonFound = false; if initialOption then for _, btnRef in ipairs(createdButtonsTable) do if btnRef.button.Text == initialOption then selectButton(btnRef); initialButtonFound = true; -- 
        break end end end; if not initialButtonFound and #createdButtonsTable > 0 then selectButton(createdButtonsTable[1]) end -- 
        function mainContainer:SetValue(optionTextValue) for _, btnRef in ipairs(createdButtonsTable) do if btnRef.button.Text == optionTextValue then selectButton(btnRef); break end end end; function mainContainer:GetValue() if currentActiveButton then return currentActiveButton.button.Text end; -- 
        return nil end -- 
        return mainContainer -- 
    end

    function ControlFactory.createKeybindInput(parent, props)
        local actionName = props.actionName or "Действие"
        local initialKeybind = props.initialKeybind or Enum.KeyCode.Unknown
        local callback = props.callback
        local internalName = props.internalName or actionName .. "Keybind"
        local currentKey = initialKeybind
        local isListening = false

        -- NEW Keybind Styling Constants 
        local CONTROL_HEIGHT = 36 -- 
        local CORNER_RADIUS = 6 -- 
        local ACTION_LABEL_WIDTH_SCALE = 0.55 -- 
        local KEY_BUTTON_WIDTH_SCALE = 0.45 -- 
        local INTERNAL_SPACING = 8 -- 
        local RESET_ICON_SIZE = 18 -- 
        local RESET_ICON_MARGIN = 6 -- 

        -- Colors
        local colorBaseBackground = Color3.fromRGB(35, 40, 45) -- 
        local colorBaseStroke = Color3.fromRGB(20, 25, 30) -- 
        local colorActionLabelText = Color3.fromRGB(190, 195, 205) -- 
        local colorKeyButtonBgNormal = Color3.fromRGB(45, 50, 55) -- 
        local colorKeyButtonBgHover = Color3.fromRGB(55, 60, 65) -- 
        local colorKeyButtonBgListening = Color3.fromRGB(70, 130, 180) -- 
        local colorKeyButtonTextNormal = Color3.fromRGB(210, 215, 225) -- 
        local colorKeyButtonTextListening = Color3.fromRGB(255, 255, 255) -- 
        local colorKeyButtonStroke = Color3.fromRGB(30, 35, 40) -- 
        local colorResetIcon = Color3.fromRGB(140, 145, 155) -- 
        local colorResetIconHover = Color3.fromRGB(190, 195, 205) -- 

        local ANIM_DURATION_SHORT = 0.12 -- 
        local animInfo = TweenInfo.new(ANIM_DURATION_SHORT, Enum.EasingStyle.Sine, Enum.EasingDirection.Out) -- 

        local container = Instance.new("Frame", parent) -- 
        container.Name = internalName .. "Container" -- 
        container.Size = UDim2.new(1, 0, 0, CONTROL_HEIGHT) -- 
        container.BackgroundColor3 = colorBaseBackground -- 
        container.BackgroundTransparency = 0 -- 
        container.BorderSizePixel = 0 -- 
        container.LayoutOrder = props.layoutOrder or 0 -- 
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, CORNER_RADIUS) -- 
        local baseStroke = Instance.new("UIStroke", container) -- 
        baseStroke.Color = colorBaseStroke -- 
        baseStroke.Thickness = 1 -- 
        baseStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- 

        local padding = Instance.new("UIPadding", container) -- 
        padding.PaddingLeft = UDim.new(0, INTERNAL_SPACING) -- 
        padding.PaddingRight = UDim.new(0, INTERNAL_SPACING) -- 

        local listLayout = Instance.new("UIListLayout", container) -- 
        listLayout.FillDirection = Enum.FillDirection.Horizontal -- 
        listLayout.VerticalAlignment = Enum.VerticalAlignment.Center -- 
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left -- 
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder -- 
        listLayout.Padding = UDim.new(0, INTERNAL_SPACING) -- 

        local actionLabel = Instance.new("TextLabel", container) -- 
        actionLabel.Name = "ActionLabel" -- 
        actionLabel.Size = UDim2.new(ACTION_LABEL_WIDTH_SCALE, -INTERNAL_SPACING, 0, CONTROL_HEIGHT - 10) -- 
        actionLabel.Text = actionName -- 
        actionLabel.Font = Cfg.Fonts.Semibold -- 
        actionLabel.TextSize = Cfg.TextSizes.Default -- 
        actionLabel.TextColor3 = colorActionLabelText -- 
        actionLabel.BackgroundTransparency = 1 -- 
        actionLabel.TextXAlignment = Enum.TextXAlignment.Left -- 
        actionLabel.TextYAlignment = Enum.TextYAlignment.Center -- 
        actionLabel.LayoutOrder = 1 -- 
        actionLabel.TextTruncate = Enum.TextTruncate.AtEnd -- 

        local keybindButton = Instance.new("TextButton", container) -- 
        keybindButton.Name = "KeybindButton" -- 
        keybindButton.Size = UDim2.new(KEY_BUTTON_WIDTH_SCALE, 0, 0, CONTROL_HEIGHT - 8) -- 
        keybindButton.BackgroundColor3 = colorKeyButtonBgNormal -- 
        keybindButton.BackgroundTransparency = 0 -- 
        keybindButton.BorderSizePixel = 0 -- 
        keybindButton.AutoButtonColor = false -- 
        keybindButton.Font = Cfg.Fonts.Bold -- 
        keybindButton.TextSize = Cfg.TextSizes.Default -- 
        keybindButton.TextColor3 = colorKeyButtonTextNormal -- 
        keybindButton.TextXAlignment = Enum.TextXAlignment.Center -- 
        keybindButton.TextYAlignment = Enum.TextYAlignment.Center -- 
        keybindButton.LayoutOrder = 2 -- 
        Instance.new("UICorner", keybindButton).CornerRadius = UDim.new(0, CORNER_RADIUS -2) -- 
        local keyButtonStroke = Instance.new("UIStroke", keybindButton) -- 
        keyButtonStroke.Color = colorKeyButtonStroke -- 
        keyButtonStroke.Thickness = 1 -- 
        keyButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- 

        local resetKeyIcon = Instance.new("ImageButton", keybindButton) -- 
        resetKeyIcon.Name = "ResetKeyIcon" -- 
        resetKeyIcon.Size = UDim2.new(0, RESET_ICON_SIZE, 0, RESET_ICON_SIZE) -- 
        resetKeyIcon.AnchorPoint = Vector2.new(1, 0.5) -- 
        resetKeyIcon.Position = UDim2.new(1, -RESET_ICON_MARGIN, 0.5, 0) -- 
        resetKeyIcon.BackgroundTransparency = 1 -- 
        resetKeyIcon.Image = "rbxassetid://13516605743" -- 
        resetKeyIcon.ImageColor3 = colorResetIcon -- 
        resetKeyIcon.ScaleType = Enum.ScaleType.Fit -- 
        resetKeyIcon.Visible = false -- 

        local function updateVisuals()
            if isListening then
                keybindButton.Text = Cfg.KEYBIND_PROMPT_TEXT
                Tsrv:Create(keybindButton, animInfo, { BackgroundColor3 = colorKeyButtonBgListening, TextColor3 = colorKeyButtonTextListening }):Play()
                keyButtonStroke.Color = colorKeyButtonBgListening -- 
                resetKeyIcon.Visible = false -- 
            else
                keybindButton.Text = ControlFactory.keyCodeToString(currentKey)
                Tsrv:Create(keybindButton, animInfo, { BackgroundColor3 = colorKeyButtonBgNormal, TextColor3 = colorKeyButtonTextNormal }):Play()
                keyButtonStroke.Color = colorKeyButtonStroke
                resetKeyIcon.Visible = (currentKey ~= Enum.KeyCode.Unknown) -- 
                if resetKeyIcon.Visible then resetKeyIcon.ImageColor3 = colorResetIcon end -- 
            end
        end
        updateVisuals() -- 

        local function stopListening(updateVisualsFlag)
            if ControlFactory.currentlyListeningKeybindInput == container then
                isListening = false -- 
                ControlFactory.currentlyListeningKeybindInput = nil -- 
                if updateVisualsFlag == nil or updateVisualsFlag == true then -- 
                    updateVisuals()
                end
                if ControlFactory.keybindInputListenerConnection then -- 
                    ControlFactory.keybindInputListenerConnection:Disconnect() -- 
                    ControlFactory.keybindInputListenerConnection = nil -- 
                end
            end
        end

        local function startListening()
            if ControlFactory.currentlyListeningKeybindInput and ControlFactory.currentlyListeningKeybindInput ~= container then -- 
                if ControlFactory.currentlyListeningKeybindInput.StopListening then -- 
                    ControlFactory.currentlyListeningKeybindInput.StopListening(true) -- 
                end
            end
            isListening = true
            ControlFactory.currentlyListeningKeybindInput = container -- 
            updateVisuals() -- 

            if ControlFactory.keybindInputListenerConnection then -- 
                ControlFactory.keybindInputListenerConnection:Disconnect() -- 
            end
            ControlFactory.keybindInputListenerConnection = UsrInSrv.InputBegan:Connect(function(input, gameProcessedEvent)
                if gameProcessedEvent or ControlFactory.currentlyListeningKeybindInput ~= container then return end
                local guiFocus = UsrInSrv:GetFocusedTextBox() -- 
                if guiFocus then return end -- 

                local validPress = false
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    if input.KeyCode == Enum.KeyCode.Escape then
                        stopListening(true) -- 
                        return -- 
                    end
                    currentKey = input.KeyCode
                    validPress = true -- 
                elseif input.UserInputType == Enum.UserInputType.MouseButton1 or -- 
                       input.UserInputType == Enum.UserInputType.MouseButton2 or -- 
                       input.UserInputType == Enum.UserInputType.MouseButton3 then -- 
                    currentKey = input.KeyCode -- 
                    validPress = true -- 
                end

                if validPress then
                    if callback then
                        pcall(callback, props.actionName or props.internalName, currentKey) -- 
                    end
                    stopListening(true) -- 
                end
            end)
        end

        keybindButton.MouseEnter:Connect(function()
            if not isListening then -- 
                Tsrv:Create(keybindButton, animInfo, { BackgroundColor3 = colorKeyButtonBgHover }):Play() -- 
            end
        end)
        keybindButton.MouseLeave:Connect(function()
            if not isListening then
                Tsrv:Create(keybindButton, animInfo, { BackgroundColor3 = colorKeyButtonBgNormal }):Play()
            end -- 
        end)
        keybindButton.MouseButton1Click:Connect(function()
            if isListening then
                stopListening(true)
            else
                startListening()
            end
        end) -- 

        resetKeyIcon.MouseEnter:Connect(function()
            if resetKeyIcon.Visible then
                Tsrv:Create(resetKeyIcon, animInfo, { ImageColor3 = colorResetIconHover }):Play()
            end
        end)
        resetKeyIcon.MouseLeave:Connect(function()
             if resetKeyIcon.Visible then
                Tsrv:Create(resetKeyIcon, animInfo, { ImageColor3 = colorResetIcon }):Play() -- 
             end
        end)
        resetKeyIcon.MouseButton1Click:Connect(function()
            if isListening then stopListening(true) end
            currentKey = Enum.KeyCode.Unknown
            updateVisuals()
            if callback then
                pcall(callback, props.actionName or props.internalName, currentKey) -- 
            end
            NotifSrv:show((props.actionName or "Действие") .. " сброшено", 1.5) -- 
        end)

        container.StopListening = stopListening -- 
        container.Destroying:Connect(function() stopListening(false) end) -- 
        function container:GetKeybind() return currentKey end -- 
        function container:SetKeybind(newKeyCode)
            currentKey = newKeyCode or Enum.KeyCode.Unknown -- 
            if not isListening then updateVisuals() end -- 
        end

        return container -- 
    end

    function ControlFactory.createCheckbox(parent, props)
        local labelText = props.text or ""
        local initialState = props.initialState or false
        local callback = props.callback
        local internalName = props.internalName or labelText:gsub("%s+", "") .. "Checkbox" -- 
        local currentState = initialState -- 

        local CHECKBOX_CONTROL_HEIGHT = 35 -- 
        local CHECKBOX_BOX_SIZE = 24 -- 
        local CHECKBOX_TEXT_SPACING = 10 -- 
        local CHECKBOX_DOT_SIZE_FACTOR = 0.5 -- 
        local CHECKBOX_STROKE_THICKNESS = 1 -- 

        local ANIM_DURATION_CHECKBOX_BG = 0.15 -- 
        local ANIM_DURATION_CHECKBOX_DOT = 0.12 -- 
        local ANIM_SCALE_DOT_START = 0.3 -- 

        local animInfoBg = TweenInfo.new(ANIM_DURATION_CHECKBOX_BG, Enum.EasingStyle.Quint, Enum.EasingDirection.Out) -- 
        local animInfoDotIn = TweenInfo.new(ANIM_DURATION_CHECKBOX_DOT, Enum.EasingStyle.Back, Enum.EasingDirection.Out) -- 
        local animInfoDotOut = TweenInfo.new(ANIM_DURATION_CHECKBOX_DOT * 0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.In) -- 

        local colorCheckboxBgNormal = Color3.fromRGB(40, 45, 50) -- 
        local colorCheckboxBgHover = Color3.fromRGB(50, 55, 60) -- 
        local colorCheckboxBgChecked = Color3.fromRGB(70, 130, 180) -- 
        local colorCheckboxBorder = Color3.fromRGB(25, 30, 35) -- 
        local colorCheckboxDot = Color3.fromRGB(220, 225, 235) -- 
        local colorCheckboxLabelText = Color3.fromRGB(190, 195, 205) -- 
        local SUBSECTION_FRAME_PADDING_VAL = 9 -- 

        local container = Instance.new("Frame", parent) -- 
        container.Name = internalName .. "Container" -- 
        container.BackgroundTransparency = 1 -- 
        container.Size = UDim2.new(1, 0, 0, CHECKBOX_CONTROL_HEIGHT) -- 
        container.LayoutOrder = props.layoutOrder or 0 -- 

        local listLayout = Instance.new("UIListLayout", container) -- 
        listLayout.FillDirection = Enum.FillDirection.Horizontal -- 
        listLayout.VerticalAlignment = Enum.VerticalAlignment.Center -- 
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder -- 
        listLayout.Padding = UDim.new(0, CHECKBOX_TEXT_SPACING) -- 

        local checkboxButton = Instance.new("TextButton", container) -- 
        checkboxButton.Name = "CheckboxButton" -- 
        checkboxButton.Size = UDim2.new(0, CHECKBOX_BOX_SIZE, 0, CHECKBOX_BOX_SIZE) -- 
        checkboxButton.Text = "" -- 
        checkboxButton.BackgroundColor3 = currentState and colorCheckboxBgChecked or colorCheckboxBgNormal -- 
        checkboxButton.AutoButtonColor = false -- 
        checkboxButton.LayoutOrder = 1 -- 
        checkboxButton.BackgroundTransparency = 0 -- 

        local corner = Instance.new("UICorner", checkboxButton) -- 
        corner.CornerRadius = UDim.new(0.5, 0) -- 

        local stroke = Instance.new("UIStroke", checkboxButton) -- 
        stroke.Color = colorCheckboxBorder -- 
        stroke.Thickness = CHECKBOX_STROKE_THICKNESS -- 
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- 

        local dot = Instance.new("Frame", checkboxButton) -- 
        dot.Name = "Dot" -- 
        local dotActualSize = CHECKBOX_BOX_SIZE * CHECKBOX_DOT_SIZE_FACTOR -- 
        dot.Size = UDim2.new(0, currentState and dotActualSize or dotActualSize * ANIM_SCALE_DOT_START, 0, currentState and dotActualSize or dotActualSize * ANIM_SCALE_DOT_START) -- 
        dot.Position = UDim2.fromScale(0.5, 0.5) -- 
        dot.AnchorPoint = Vector2.new(0.5, 0.5) -- 
        dot.BackgroundColor3 = colorCheckboxDot -- 
        dot.BackgroundTransparency = currentState and 0 or 1 -- 
        dot.BorderSizePixel = 0 -- 
        local dotCorner = Instance.new("UICorner", dot) -- 
        dotCorner.CornerRadius = UDim.new(0.5, 0) -- 

        local checkboxLabel = Instance.new("TextLabel", container) -- 
        checkboxLabel.Name = "CheckboxLabel" -- 
        local parentWidth = parent.AbsoluteSize.X - (SUBSECTION_FRAME_PADDING_VAL * 2) -- 
        if parentWidth <= 0 then parentWidth = (Cfg.FRAME_WIDTH - Cfg.TAB_BAR_SIZE - Cfg.PADDING*3) - (SUBSECTION_FRAME_PADDING_VAL*2) end -- 
        local labelWidth = parentWidth - CHECKBOX_BOX_SIZE - CHECKBOX_TEXT_SPACING -- 
        checkboxLabel.Size = UDim2.new(0, labelWidth, 1, 0) -- 
        checkboxLabel.Text = labelText -- 
        checkboxLabel.Font = Cfg.Fonts.Default -- 
        checkboxLabel.TextSize = Cfg.TextSizes.Default -- 
        checkboxLabel.TextColor3 = colorCheckboxLabelText -- 
        checkboxLabel.BackgroundTransparency = 1 -- 
        checkboxLabel.TextXAlignment = Enum.TextXAlignment.Left -- 
        checkboxLabel.TextYAlignment = Enum.TextYAlignment.Center -- 
        checkboxLabel.LayoutOrder = 2 -- 
        if labelText == "" then checkboxLabel.Visible = false end -- 

        checkboxButton.MouseEnter:Connect(function()
            if not currentState then
                Tsrv:Create(checkboxButton, animInfoBg, {BackgroundColor3 = colorCheckboxBgHover}):Play()
            end
        end)
        checkboxButton.MouseLeave:Connect(function()
            if not currentState then -- 
                Tsrv:Create(checkboxButton, animInfoBg, {BackgroundColor3 = colorCheckboxBgNormal}):Play() -- 
            end
        end)

        local function _animateDot(isChecked)
            local targetDotSize = dotActualSize
            local targetDotTransparency = 0
            local animInfoToUse = animInfoDotIn -- 

            if not isChecked then
                targetDotSize = dotActualSize * ANIM_SCALE_DOT_START
                targetDotTransparency = 1
                animInfoToUse = animInfoDotOut
            else
                dot.Size = UDim2.new(0, dotActualSize * ANIM_SCALE_DOT_START, 0, dotActualSize * ANIM_SCALE_DOT_START) -- 
                dot.BackgroundTransparency = 0.5 -- 
            end

            Tsrv:Create(dot, animInfoToUse, {
                Size = UDim2.new(0, targetDotSize, 0, targetDotSize),
                BackgroundTransparency = targetDotTransparency
            }):Play() -- 
        end

        checkboxButton.MouseButton1Click:Connect(function()
            currentState = not currentState
            local targetBgColor = currentState and colorCheckboxBgChecked or colorCheckboxBgNormal
            Tsrv:Create(checkboxButton, animInfoBg, {BackgroundColor3 = targetBgColor}):Play()
            _animateDot(currentState)
            if callback then pcall(callback, currentState) end -- 
        end)

        function container:IsChecked() return currentState end -- 
        function container:SetChecked(isChecked)
            if currentState ~= isChecked then
                currentState = isChecked
                local targetBgColor = currentState and colorCheckboxBgChecked or colorCheckboxBgNormal
                Tsrv:Create(checkboxButton, animInfoBg, {BackgroundColor3 = targetBgColor}):Play() -- 
                _animateDot(currentState) -- 
            end
        end
        return container -- 
    end

    function ControlFactory.createSeparatorLine(parent, props)
        local separatorColor = Color3.fromRGB(50, 60, 70)
        local lineDefinition = { InstanceType = "Frame", Name = (props.name or "SeparatorLine"), Properties = { Size = UDim2.new(1, 0, 0, props.height or Cfg.SEPARATOR_LINE_HEIGHT), BackgroundColor3 = props.color or separatorColor, BackgroundTransparency = 0, BorderSizePixel = 0, LayoutOrder = props.layoutOrder or 0, } } -- 
        local lineInstance, _ = _createElementsFromTree(parent, lineDefinition) -- 
        return lineInstance -- 
    end

    function ControlFactory.cleanupSliderConnections() local conns = {}; for k,v in pairs(ControlFactory.activeSliderDragConnections) do conns[k]=v end; for _,c in pairs(conns) do if c and c.Connected then c:Disconnect() end end; -- 
    ControlFactory.activeSliderDragConnections = {}; if ControlFactory.currentlyListeningKeybindInput and ControlFactory.currentlyListeningKeybindInput.StopListening then ControlFactory.currentlyListeningKeybindInput.StopListening(false) end; if ControlFactory.keybindInputListenerConnection then ControlFactory.keybindInputListenerConnection:Disconnect(); ControlFactory.keybindInputListenerConnection = nil end; -- 
    ControlFactory.currentlyListeningKeybindInput = nil end -- 
end -- ControlFactory Scope End 

return ControlFactory -- Or ensure ControlFactory is global
