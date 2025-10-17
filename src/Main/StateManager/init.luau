local States = require(script.States)
local TypeDefs = require(script.Parent.TypeDefinitions)
local TextOptions = require(script.Parent.TextOptions)
local SavedPaths = require(script.Parent.SavedPaths)
local Tweens = require(script.Parent.Tweens)

local mainUi = script.Parent.AiPathMakerUI
local mainFrame = mainUi.MainFrame
local pathCustomizeFrame = mainFrame.PathCustomizeFrame
local patrolActionsFrame = mainFrame.PatrolActionsFrame
local patrolActionDropDownButton = patrolActionsFrame.PointActionDropDownButton
local newPathButton = mainFrame.NewPathButton

local normalTxtBox = pathCustomizeFrame.PointNormalTxtBox
local positionTxtBox = pathCustomizeFrame.PointPosTxtBox
local waitTimeTxtBox = pathCustomizeFrame.PointWaitTxtBox

type PatrolPath = TypeDefs.PatrolPath
type PatrolPoint = TypeDefs.PatrolPoint
type PositionSelection = TypeDefs.PositionSelection
type StateManager = TypeDefs.StateManager


local StateManager = {
    currentState = States.SelectingCharacter;
    isActive = false;
    isPatrolActionsDropDownActive = false;

    selectedPath = nil;
    selectedPosition = nil;
    seletedCharacter = nil;
    selectedPatrolPoint = nil;

    plugin = nil
}

function StateManager:ChangeToSelectingCharacter()
    self:_DeselectPatrolPoint()
    if StateManager.currentState == States.SelectingCharacter then return end
    self.plugin:Deactivate()
    newPathButton.Text = TextOptions.pathButtonNoCharacterSelected
    self.currentState = States.SelectingCharacter
    patrolActionsFrame.Visible = false
    pathCustomizeFrame.Visible = false

    self.selectedCharacter = nil
    self.selectedPath = nil
    self.selectedPosition = nil
end

function StateManager:ChangeToCharacterSelected(character:Model?)
    self:_DeselectPatrolPoint()
    if StateManager.currentState == States.CharacterSelected then return end
    self.plugin:Deactivate()
    newPathButton.Text = TextOptions.pathButtonCharacterSelected
    self.currentState = States.CharacterSelected
    
    self.selectedCharacter = character or self.selectedCharacter
    self.selectedPath = nil
    self.selectedPosition = nil
end

function StateManager:ChangeToEditingPath(path:PatrolPath?)
    self:_DeselectPatrolPoint()
    if StateManager.currentState == States.EditingPath then return end
    self.plugin:Deactivate()
    newPathButton.Text = TextOptions.pathButtonEditingPath
    self.currentState = States.EditingPath
    patrolActionsFrame.Visible = true
    pathCustomizeFrame.Visible = true

    self.selectedPath = path or self.selectedPath
    self.selectedPosition = nil
end

function StateManager:ChangeToSelectingPosition()
    self:_DeselectPatrolPoint()
    if StateManager.currentState == States.SelectingPosition then return end
    self.plugin:Activate(true)
    newPathButton.Text = TextOptions.pathButtonSelectingPositon
    self.currentState = States.SelectingPosition

    self.selectedPosition = nil
end

function StateManager:ChangeToEditingPosition(positionSelection:PositionSelection?)
    self:_DeselectPatrolPoint()
    if StateManager.currentState == States.EditingPosition then return end
    self.plugin:Activate(true)
    self.currentState = States.EditingPosition
    newPathButton.Text = TextOptions.pathButtonEditingPosition

    self.selectedPosition = positionSelection or self.selectedPosition
end

function StateManager:_DeselectPatrolPoint()
    local point = self.selectedPatrolPoint
    if not point then return end
    self.selectedPatrolPoint = nil

    if point._visual:FindFirstChild("PATROL_POINT_SELECTION_HIGHLIGHT") then
        point._visual.PATROL_POINT_SELECTION_HIGHLIGHT.Enabled = false
    end

    waitTimeTxtBox.Text = TextOptions.patrolPointWaitTimeButton
    positionTxtBox.Text = TextOptions.patrolPointPositionButton
    normalTxtBox.Text = TextOptions.patrolPointNormalButton
end

function StateManager:_SelectPatrolPoint(point:PatrolPoint)
    self.selectedPatrolPoint = point
    local normal = point.normal
    local position = point.position
    local waitTime = point.waitTime

    normalTxtBox.Text = string.format("%s%s", TextOptions.patrolPointNormalButton, tostring(normal))
    positionTxtBox.Text = string.format("%s%s", TextOptions.patrolPointPositionButton, tostring(position))
    waitTimeTxtBox.Text = string.format("%s%s", TextOptions.patrolPointWaitTimeButton, tostring(waitTime))

    if self.selectedPatrolPoint._visual:FindFirstChild("PATROL_POINT_SELECTION_HIGHLIGHT") then
        self.selectedPatrolPoint._visual.PATROL_POINT_SELECTION_HIGHLIGHT.Enabled = false
    end
        
    local highlight = point._visual:FindFirstChild("PATROL_POINT_SELECTION_HIGHLIGHT")

    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.new(1, 1, 1)
        highlight.OutlineColor = Color3.new(1, 0, 0)
        highlight.FillTransparency = 1
        highlight.Name = "PATROL_POINT_SELECTION_HIGHLIGHT"
        highlight.Parent = point._visual
    else
        highlight.Enabled = true
    end
end

function StateManager:ChangeToEditingPatrolPoint(patrolPoint:PatrolPoint?)
    local point = patrolPoint or self.selectedPatrolPoint
    assert(point, "If there's not a selected Patrol Point then you must pass a Patrol Point into the patrolPoint feild.")
    self.plugin:Activate(true)
    StateManager.currentState = States.EditingPatrolPoint
    newPathButton.Text = TextOptions.pathButtonEditingPatrolPoint

    self.selectedPatrolPoint = patrolPoint
    self:_SelectPatrolPoint(self.selectedPatrolPoint)
end

function StateManager:ActivatePatrolActionsDropDown()
    if self.isPatrolActionsDropDownActive then return end
    self.isPatrolActionsDropDownActive = true
    Tweens.patrolActionDropDownStartTween:Play()
    patrolActionDropDownButton.Text = TextOptions.patrolActionsDropDownBringDown
end

function StateManager:DeactivatePatrolActionsDropDown()
    if not self.isPatrolActionsDropDownActive then return end
    self.isPatrolActionsDropDownActive = false
    Tweens.PatrolActionDropDownEndTween:Play()
    patrolActionDropDownButton.Text = TextOptions.patrolActionsDropDownBringUp
end

function StateManager:TogglePatrolActionsDropDown()
    self.isPatrolActionsDropDownActive = not self.isPatrolActionsDropDownActive

    if self.isPatrolActionsDropDownActive then
        self:ActivatePatrolActionsDropDown()
    else
        self:DeactivatePatrolActionsDropDown()
    end
end

function StateManager:DisablePlugin()
    if not self.isActive then return end
    self.isActive = false

    Tweens.endTween:Play()
    for _, path:PatrolPath in ipairs(SavedPaths.Paths) do
        path:SetTransparent()
    end

    Tweens.endTween.Completed:Once(function()
        mainUi.Parent = script
        self:ChangeToSelectingCharacter()
        if self.selectedPosition then
            self.selectedPosition:Destroy()
        end
    end)
end

function StateManager:EnablePlugin()
    if self.isActive then return end
    self.isActive = true

    mainUi.Parent = game:WaitForChild("CoreGui")

    Tweens.startTween:Play()
    for _, path:PatrolPath in ipairs(SavedPaths.Paths) do
        path:SetOpaque()
    end
end

function StateManager:TogglePlugin()
    if Tweens.startTween.PlaybackState == Enum.PlaybackState.Playing or Tweens.endTween.PlaybackState == Enum.PlaybackState.Playing then
        return
    end

    if not self.isActive then
        self:EnablePlugin()
    else
        self:DisablePlugin()
    end
end


return StateManager :: StateManager