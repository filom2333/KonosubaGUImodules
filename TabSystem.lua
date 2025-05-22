-- Content for TabSystem.lua
-- Original lines: 779-918
local TabSystem = {}
do -- TabSystem Scope
    local Cfg; local Tsrv; local CntBuilder -- 
    TabSystem.activeTabButton = nil; TabSystem.activeContentPage = nil; TabSystem.tabButtons = {}; TabSystem.contentPages = {}; TabSystem.tabsSection = nil; TabSystem.contentSection = nil; TabSystem.isTransitioning = false -- 
    local CONTENT_STAGGER_DURATION = 0.04; local CONTENT_ANIM_DURATION = 0.5; local CONTENT_ANIM_STYLE = Enum.EasingStyle.Quad; local CONTENT_ANIM_DIRECTION = Enum.EasingDirection.Out -- 
    function TabSystem:_animateContentElements(contentFrame)
        if not contentFrame or not contentFrame.Parent then return end
        local elementsToAnimate = {}; for _, child in ipairs(contentFrame:GetChildren()) do if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("ScrollingFrame") then if not (child:IsA("UILayout") or child:IsA("UICorner") or child:IsA("UIStroke") or child:IsA("UIPadding") or (contentFrame:FindFirstChildOfClass("UIListLayout") == child)) then table.insert(elementsToAnimate, child) end end end -- 
        table.sort(elementsToAnimate, function(a, b) return (a.LayoutOrder or 0) < (b.LayoutOrder or 0) end) -- 
        local SLIDE_OFFSET_Y = 15; local originalProperties = {} -- 
        for _, element in ipairs(elementsToAnimate) do originalProperties[element] = { Position = element.Position, BackgroundTransparency = element.BackgroundTransparency, TextTransparency = (element:IsA("TextLabel") or element:IsA("TextButton")) and element.TextTransparency or 1 }; -- 
        element.Position = UDim2.new(originalProperties[element].Position.X.Scale, originalProperties[element].Position.X.Offset, originalProperties[element].Position.Y.Scale, originalProperties[element].Position.Y.Offset + SLIDE_OFFSET_Y); if string.match(element.Name, "SubSection") and string.match(element.Name, "Container$") then element.BackgroundTransparency = 1 elseif element:IsA("TextLabel") or element:IsA("TextButton") then element.TextTransparency = 1 end; -- 
        local function setChildrenTransparent(parentElement) for _, childItem in ipairs(parentElement:GetChildren()) do if childItem:IsA("UILayout") or childItem:IsA("UICorner") or childItem:IsA("UIStroke") or childItem:IsA("UIPadding") then continue end; -- 
        if not originalProperties[childItem] then originalProperties[childItem] = { Position = childItem.Position, BackgroundTransparency = childItem.BackgroundTransparency, TextTransparency = (childItem:IsA("TextLabel") or childItem:IsA("TextButton")) and childItem.TextTransparency or 1 } end; -- 
        if childItem:IsA("Frame") or childItem:IsA("TextButton") then if originalProperties[childItem].BackgroundTransparency < 1 then childItem.BackgroundTransparency = 1 end end; -- 
        if childItem:IsA("TextLabel") or childItem:IsA("TextButton") then if originalProperties[childItem].TextTransparency < 1 then childItem.TextTransparency = 1 end end; -- 
        if childItem:IsA("Frame") and (string.match(childItem.Name, "Container$") or string.match(childItem.Name, "Holder$") or string.match(childItem.Name, "Frame$")) then setChildrenTransparent(childItem) end end end; -- 
        if element:IsA("Frame") then setChildrenTransparent(element) end end -- 
        for i, element in ipairs(elementsToAnimate) do task.delay((i - 1) * CONTENT_STAGGER_DURATION, function() if not (element and element.Parent and originalProperties[element]) then return end; local animInfo = TweenInfo.new(CONTENT_ANIM_DURATION, CONTENT_ANIM_STYLE, CONTENT_ANIM_DIRECTION); local targetPropsForElement = { Position = originalProperties[element].Position }; if element:IsA("Frame") or element:IsA("TextButton") then targetPropsForElement.BackgroundTransparency = originalProperties[element].BackgroundTransparency end; if element:IsA("TextLabel") or element:IsA("TextButton") then targetPropsForElement.TextTransparency = originalProperties[element].TextTransparency end; Tsrv:Create(element, animInfo, targetPropsForElement):Play(); local function animateChildrenFadeIn(parentElement) for _, childItem in ipairs(parentElement:GetChildren()) do if not (childItem and childItem.Parent and originalProperties[childItem]) then continue end; -- 
        if childItem:IsA("UILayout") or childItem:IsA("UICorner") or childItem:IsA("UIStroke") or childItem:IsA("UIPadding") then continue end; local childTargetProps = {}; -- 
        if childItem:IsA("Frame") or childItem:IsA("TextButton") then childTargetProps.BackgroundTransparency = originalProperties[childItem].BackgroundTransparency end; if childItem:IsA("TextLabel") or childItem:IsA("TextButton") then childTargetProps.TextTransparency = originalProperties[childItem].TextTransparency end; -- 
        if next(childTargetProps) then Tsrv:Create(childItem, TweenInfo.new(CONTENT_ANIM_DURATION, CONTENT_ANIM_STYLE, CONTENT_ANIM_DIRECTION), childTargetProps):Play() end; if childItem:IsA("Frame") and (string.match(childItem.Name, "Container$") or string.match(childItem.Name, "Holder$") or string.match(childItem.Name, "Frame$")) then animateChildrenFadeIn(childItem) end end end; -- 
        if element:IsA("Frame") then animateChildrenFadeIn(element) end end) end -- 
    end
    function TabSystem:init(tabsSectionParam, contentSectionParam, injectedConfig, injectedTweenService, injectedContentBuilder) self.tabsSection = tabsSectionParam; self.contentSection = contentSectionParam; Cfg = injectedConfig; Tsrv = injectedTweenService; CntBuilder = injectedContentBuilder; local contentSectionBgColor = Color3.fromRGB(30, 35, 40); -- 
    self.contentSection.BackgroundColor3 = contentSectionBgColor; self.contentSection.BackgroundTransparency = Cfg.CONTENT_SECTION_TRANSPARENCY; self:clear() end -- 
    function TabSystem:setActiveTab(tabName) if self.isTransitioning then return end; local newButton, newPage = self.tabButtons[tabName], self.contentPages[tabName]; if not newButton or not newPage or self.activeTabButton == newButton then return end; -- 
    self.isTransitioning = true; local oldButton, oldPage = self.activeTabButton, self.activeContentPage; local colorTabButtonBgNormal = Color3.fromRGB(35, 40, 45); -- 
    local colorTabButtonBgActive = Color3.fromRGB(55, 65, 75); local colorTabButtonTextNormal = Color3.fromRGB(190, 195, 205); local colorTabButtonTextActive = Color3.fromRGB(230, 235, 245); -- 
    if oldButton and oldButton:IsA("TextButton") and oldButton.Parent == self.tabsSection then oldButton.BackgroundColor3 = colorTabButtonBgNormal; oldButton.TextColor3 = colorTabButtonTextNormal end; -- 
    if newButton and newButton:IsA("TextButton") and newButton.Parent == self.tabsSection then newButton.BackgroundColor3 = colorTabButtonBgActive; newButton.TextColor3 = colorTabButtonTextActive end; self.activeTabButton = newButton; -- 
    self.activeContentPage = newPage; if oldPage then oldPage.Visible = false end; newPage.Position = UDim2.new(0,0,0,0); newPage.Visible = true; newPage.ZIndex = 2; self:_animateContentElements(newPage); -- 
    self.isTransitioning = false end -- 
    function TabSystem:createTab(tabInfo) if not Cfg or not Tsrv or not CntBuilder then warn("TabSystem not fully initialized for createTab!"); return end; local colorTabButtonBgNormal = Color3.fromRGB(35, 40, 45); local colorTabButtonBgHover = Color3.fromRGB(45, 50, 55); local colorTabButtonTextNormal = Color3.fromRGB(190, 195, 205); -- 
    local colorScrollbar = Color3.fromRGB(50, 60, 70); local contentPage; if tabInfo.Scrolling == true then contentPage = Instance.new("ScrollingFrame", self.contentSection); contentPage.ScrollBarThickness = 8; -- 
    contentPage.ScrollBarImageColor3 = colorScrollbar else contentPage = Instance.new("Frame", self.contentSection) end; contentPage.Name = tabInfo.Name .. "Page"; contentPage.Size = UDim2.new(1, 0, 1, 0); -- 
    contentPage.BackgroundTransparency = 1; contentPage.Visible = false; contentPage.ClipsDescendants = true; contentPage.BorderSizePixel = 0; contentPage.Position = UDim2.new(0,0,0,0); local internalPagePadding = Instance.new("UIPadding", contentPage); -- 
    internalPagePadding.PaddingLeft = UDim.new(0, Cfg.PADDING / 2); internalPagePadding.PaddingRight = UDim.new(0, Cfg.PADDING / 2); internalPagePadding.PaddingTop = UDim.new(0, Cfg.PADDING / 2); -- 
    internalPagePadding.PaddingBottom = UDim.new(0, Cfg.PADDING / 2); local pageListLayout = Instance.new("UIListLayout", contentPage); pageListLayout.FillDirection = Enum.FillDirection.Vertical; pageListLayout.SortOrder = Enum.SortOrder.LayoutOrder; pageListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left; -- 
    pageListLayout.Padding = UDim.new(0, Cfg.PADDING / 1.2); self.contentPages[tabInfo.Name] = contentPage; if tabInfo.sections then CntBuilder.buildContent(contentPage, tabInfo.sections); -- 
    if contentPage:IsA("ScrollingFrame") then local function updateCanvas() if not (contentPage and contentPage.Parent and pageListLayout and pageListLayout.Parent) then return end; -- 
    contentPage.CanvasSize = UDim2.new(0, 0, 0, pageListLayout.AbsoluteContentSize.Y) end; task.defer(updateCanvas); if pageListLayout then pageListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas) end end end; -- 
    if tabInfo.Name ~= "+ settings" then local tabButton = Instance.new("TextButton", self.tabsSection); tabButton.Name = tabInfo.Name .. "Button"; -- 
    tabButton.Size = UDim2.new(0, Cfg.TAB_BUTTON_SIZE, 0, Cfg.TAB_BUTTON_SIZE); tabButton.AutomaticSize = Enum.AutomaticSize.None; tabButton.BackgroundColor3 = colorTabButtonBgNormal; tabButton.BackgroundTransparency = 0; tabButton.BorderSizePixel = 0; -- 
    tabButton.AutoButtonColor = false; tabButton.LayoutOrder = tabInfo.Order or 0; tabButton.Text = tabInfo.Name; tabButton.Font = Cfg.Fonts.Bold; tabButton.TextSize = Cfg.TextSizes.Header1; tabButton.TextColor3 = colorTabButtonTextNormal; -- 
    tabButton.TextXAlignment = Enum.TextXAlignment.Center; tabButton.TextYAlignment = Enum.TextYAlignment.Center; Instance.new("UICorner", tabButton).CornerRadius = UDim.new(0.5, 0); -- 
    tabButton.MouseEnter:Connect(function() if self.activeTabButton ~= tabButton then Tsrv:Create(tabButton, TweenInfo.new(0.1), {BackgroundColor3 = colorTabButtonBgHover}):Play() end end); -- 
    tabButton.MouseLeave:Connect(function() if self.activeTabButton ~= tabButton then Tsrv:Create(tabButton, TweenInfo.new(0.1), {BackgroundColor3 = colorTabButtonBgNormal}):Play() end end); tabButton.MouseButton1Click:Connect(function() self:setActiveTab(tabInfo.Name) end); -- 
    self.tabButtons[tabInfo.Name] = tabButton else self.tabButtons[tabInfo.Name] = contentPage end end -- 
    function TabSystem:clear() self.activeTabButton = nil; self.activeContentPage = nil; self.tabButtons = {}; self.contentPages = {}; self.isTransitioning = false end -- 
end -- TabSystem Scope End 

return TabSystem -- Or ensure TabSystem is global
