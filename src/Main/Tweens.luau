local TweenService = game:GetService("TweenService")
local TypeDefs = require(script.Parent.TypeDefinitions)

type PatrolPoint = TypeDefs.PatrolPoint
type PointConnection = TypeDefs.PointConnection

local mainFrame = script.Parent.AiPathMakerUI.MainFrame
local patrolActionFrame = mainFrame.PatrolActionsFrame

local endInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad)
local endProperties = {
    Position = UDim2.fromScale(-0.2, 0)
}
local endTween = TweenService:Create(mainFrame, endInfo, endProperties)

local startProperties = {
    Position = UDim2.new()
}
local startTween = TweenService:Create(mainFrame, endInfo, startProperties)

local patrolActionDropDownTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad)
local patrolActionDropDownStartProperties = {
    Position = UDim2.fromScale(0, 0.588)
}
local patrolActionDropDownEndProperties = {
    Position = UDim2.fromScale(-0.85, 0.588)
}
local patrolActionDropDownStartTween = TweenService:Create(patrolActionFrame, patrolActionDropDownTweenInfo, patrolActionDropDownStartProperties)
local PatrolActionDropDownEndTween = TweenService:Create(patrolActionFrame, patrolActionDropDownTweenInfo, patrolActionDropDownEndProperties)

local patrolPointPartTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad)
local patrolPointPartDisableProperties = {
    Transparency = 1
}
local patrolPointPartEnableProperties = {
    Transparency = 0
}

local patrolPointConnectionTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad)
local patrolPointConnectionDisableProperties = {
    Width0 = 0;
    Width1 = 0;
}
local patrolPointConnectionEnableProperties = {
    Width0 = 1;
    Width1 = 1;
}

local patrolPointNormalVisualTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad)
local patrolPointNormalVisualDisableProperties = {
    Transparency = 1
}
local patrolPointNormalVisualEnableProperties = {
    Transparency = 0.8
}

function enableTweenPatrolParts(patrolPoints : {PatrolPoint})
    for _, point:PatrolPoint in ipairs(patrolPoints) do
        local part = point._visual
        TweenService:Create(part, patrolPointPartTweenInfo, patrolPointPartEnableProperties):Play()
        if point._normalVisual then
            TweenService:Create(point._normalVisual, patrolPointNormalVisualTweenInfo, patrolPointNormalVisualEnableProperties):Play()
        end
    end
end

function disableTweenPatrolParts(patrolPoints : {PatrolPoint})
    for _, point:PatrolPoint in ipairs(patrolPoints) do
        local part = point._visual
        TweenService:Create(part, patrolPointPartTweenInfo, patrolPointPartDisableProperties):Play()
        if point._normalVisual then
            TweenService:Create(point._normalVisual, patrolPointNormalVisualTweenInfo, patrolPointNormalVisualDisableProperties):Play()
        end
    end
end

function disableTweenPointConnections(pointConnections : {PointConnection})
    for _, pointConnection : PointConnection in ipairs(pointConnections) do
        local beam = pointConnection.visual
        TweenService:Create(beam, patrolPointConnectionTweenInfo, patrolPointConnectionDisableProperties):Play()
    end
end

function enableTweenPointConnections(pointConnections : {PointConnection})
    for _, pointConnection : PointConnection in ipairs(pointConnections) do
        local beam = pointConnection.visual
        TweenService:Create(beam, patrolPointConnectionTweenInfo, patrolPointConnectionEnableProperties):Play()
    end
end

local Tweens = {
    endTween = endTween;
    startTween = startTween;
    patrolActionDropDownStartTween = patrolActionDropDownStartTween;
    PatrolActionDropDownEndTween = PatrolActionDropDownEndTween;
    disableTweenPatrolParts = disableTweenPatrolParts;
    enableTweenPatrolParts = enableTweenPatrolParts;
    disableTweenPointConnections = disableTweenPointConnections;
    enableTweenPointConnections = enableTweenPointConnections;
}

return Tweens