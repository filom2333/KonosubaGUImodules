-- Content for ContentBuilder.lua
-- Original lines: 653-777
local ContentBuilder = {}
do -- ContentBuilder Scope
    local Cfg; local CtrlFactory -- 
    function ContentBuilder:init(injectedConfig, injectedControlFactory) Cfg = injectedConfig; CtrlFactory = injectedControlFactory end -- 
    function ContentBuilder.buildContent(parentPageFrame, sectionsDefinition)
        if not Cfg or not CtrlFactory then warn("ContentBuilder not initialized!"); return end -- 
        local SUBSECTION_FRAME_PADDING_VAL = 9; local SUBSECTION_ELEMENT_PADDING_VAL = 5; local SUBSECTION_STROKE_THICKNESS_VAL = 1; local CORNER_RADIUS_SUBSECTION_VAL = 8 -- 
        local colorSubsectionBackground = Color3.fromRGB(25, 30, 35); local colorSubsectionStroke = Color3.fromRGB(15, 20, 25); local colorTextSecondary = Color3.fromRGB(120, 125, 135) -- 
        local globalLayoutOrder = 1 -- 
        for _, sectionDef in ipairs(sectionsDefinition) do
            local currentContentParent = parentPageFrame
            if sectionDef.title and (sectionDef.titleLevel or 0) == 1 and (sectionDef.isHeaderOnly or not sectionDef.elements or (typeof(sectionDef.elements) == "table" and #sectionDef.elements == 0)) then
                CtrlFactory.createHeader(currentContentParent, { text = sectionDef.title, level = 1, layoutOrder = globalLayoutOrder }); -- 
                globalLayoutOrder += 1 -- 
            elseif sectionDef.title and sectionDef.elements and typeof(sectionDef.elements) == "table" and #sectionDef.elements > 0 then -- 
                local subSectionFrame = Instance.new("Frame", currentContentParent) -- 
                subSectionFrame.Name = (sectionDef.title or "SubSection") .. "Container" -- 
                subSectionFrame.BackgroundColor3 = colorSubsectionBackground
                subSectionFrame.BackgroundTransparency = Cfg.SUBSECTION_FRAME_TRANSPARENCY -- 
                subSectionFrame.BorderSizePixel = 0; subSectionFrame.LayoutOrder = globalLayoutOrder; subSectionFrame.AutomaticSize = Enum.AutomaticSize.Y; subSectionFrame.Size = UDim2.new(1, 0, 0, 0); -- 
                globalLayoutOrder += 1 -- 
                Instance.new("UICorner", subSectionFrame).CornerRadius = UDim.new(0, CORNER_RADIUS_SUBSECTION_VAL); local subSectionStroke = Instance.new("UIStroke", subSectionFrame); subSectionStroke.Color = colorSubsectionStroke; subSectionStroke.Thickness = SUBSECTION_STROKE_THICKNESS_VAL; subSectionStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; local subSectionPadding = Instance.new("UIPadding", subSectionFrame); -- 
                subSectionPadding.PaddingTop = UDim.new(0, SUBSECTION_FRAME_PADDING_VAL); subSectionPadding.PaddingBottom = UDim.new(0, SUBSECTION_FRAME_PADDING_VAL); subSectionPadding.PaddingLeft = UDim.new(0, SUBSECTION_FRAME_PADDING_VAL); subSectionPadding.PaddingRight = UDim.new(0, SUBSECTION_FRAME_PADDING_VAL); -- 
                local subSectionListLayout = Instance.new("UIListLayout", subSectionFrame); subSectionListLayout.FillDirection = Enum.FillDirection.Vertical; subSectionListLayout.SortOrder = Enum.SortOrder.LayoutOrder; subSectionListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left; -- 
                subSectionListLayout.Padding = UDim.new(0, SUBSECTION_ELEMENT_PADDING_VAL) -- 
                local internalElementLayoutOrder = 1; CtrlFactory.createHeader(subSectionFrame, { text = sectionDef.title, level = sectionDef.titleLevel or 2, layoutOrder = internalElementLayoutOrder }); -- 
                internalElementLayoutOrder += 1 -- 
                if sectionDef.description and sectionDef.description ~= "" then CtrlFactory.createLabel(subSectionFrame, { text = sectionDef.description, textSize = Cfg.TextSizes.Small, textColor = colorTextSecondary, layoutOrder = internalElementLayoutOrder, textWrapped = true, automaticSize = Enum.AutomaticSize.Y }); internalElementLayoutOrder += 1 end -- 
                for _, elementDef in ipairs(sectionDef.elements) do local propsForFactory = {}; for k, v in pairs(elementDef) do propsForFactory[k] = v end; propsForFactory.layoutOrder = internalElementLayoutOrder; -- 
                propsForFactory.internalName = elementDef.internalName or sectionDef.title .. (elementDef.actionName or elementDef.text or elementDef.label or "") or "UnnamedElement"; -- 
                if elementDef.type == "toggle" or elementDef.type == "slider" or elementDef.type == "switch_buttons" or elementDef.type == "keybind_input" or elementDef.type == "checkbox" then if (elementDef.type ~= "keybind_input" or not propsForFactory.actionName) and (elementDef.type ~= "checkbox" or not propsForFactory.text) and (elementDef.type ~= "toggle" or not propsForFactory.label) and (elementDef.type ~= "slider" or not propsForFactory.label) and (elementDef.type ~= "switch_buttons" or not propsForFactory.label) then propsForFactory.label = nil end end; -- 
                if elementDef.type == "label" then CtrlFactory.createLabel(subSectionFrame, propsForFactory) elseif elementDef.type == "header" then CtrlFactory.createHeader(subSectionFrame, propsForFactory) elseif elementDef.type == "toggle" then CtrlFactory.createToggleButton(subSectionFrame, propsForFactory) elseif elementDef.type == "slider" then pcall(CtrlFactory.createSlider, subSectionFrame, propsForFactory) elseif elementDef.type == "switch_buttons" then pcall(CtrlFactory.createSwitchButtons, subSectionFrame, propsForFactory) elseif elementDef.type == "keybind_input" then pcall(CtrlFactory.createKeybindInput, subSectionFrame, propsForFactory) elseif elementDef.type == "checkbox" then pcall(CtrlFactory.createCheckbox, subSectionFrame, propsForFactory) end; -- 
                internalElementLayoutOrder += 1 end -- 
            elseif not sectionDef.title and sectionDef.elements and typeof(sectionDef.elements) == "table" and #sectionDef.elements > 0 then -- 
                for _, elementDef in ipairs(sectionDef.elements) do local propsForFactory = {}; for k, v in pairs(elementDef) do propsForFactory[k] = v end; propsForFactory.layoutOrder = globalLayoutOrder; -- 
                if elementDef.type == "toggle" or elementDef.type == "slider" or elementDef.type == "switch_buttons" or elementDef.type == "keybind_input" or elementDef.type == "checkbox" then if (elementDef.type ~= "keybind_input" or not propsForFactory.actionName) and (elementDef.type ~= "checkbox" or not propsForFactory.text) and (elementDef.type ~= "toggle" or not propsForFactory.label) and (elementDef.type ~= "slider" or not propsForFactory.label) and (elementDef.type ~= "switch_buttons" or not propsForFactory.label) then propsForFactory.label = nil end end; -- 
                if elementDef.type == "label" then CtrlFactory.createLabel(currentContentParent, propsForFactory) elseif elementDef.type == "toggle" then CtrlFactory.createToggleButton(currentContentParent, propsForFactory) elseif elementDef.type == "slider" then pcall(CtrlFactory.createSlider, currentContentParent, propsForFactory) elseif elementDef.type == "switch_buttons" then pcall(CtrlFactory.createSwitchButtons, currentContentParent, propsForFactory) elseif elementDef.type == "keybind_input" then pcall(CtrlFactory.createKeybindInput, currentContentParent, propsForFactory) elseif elementDef.type == "checkbox" then pcall(CtrlFactory.createCheckbox, currentContentParent, propsForFactory) end; -- 
                globalLayoutOrder += 1 end -- 
            end
        end
    end
end -- ContentBuilder Scope End 

return ContentBuilder -- Or ensure ContentBuilder is global
