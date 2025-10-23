local PatrolAction = require(script.Parent.Path.PatrolAction)
local TypeDefs = require(script.Parent.TypeDefinitions)
local SavedPaths = require(script.Parent.SavedPaths)

type PatrolAction = TypeDefs.PatrolAction
type PatrolPath = TypeDefs.PatrolPath
type PatrolPoint = TypeDefs.PatrolPoint

local mainUi = script.Parent.AiPathMakerUI
local mainFrame = mainUi.MainFrame
local patrolActionsFrame = mainFrame.PatrolActionsFrame
local PatrolActionsActionsFrame = mainFrame.PatrolActionActionsFrame
local toggleWaitForPatrolActionButton = PatrolActionsActionsFrame.ToggleWaitForPatrolActionButton

function quotientBy3(number:number) : (number, number)
    if math.abs(math.round(number/3) - number/3) <= 0.01 then
        return math.round(number/3), 0
    else
        local q = math.floor(number/3)
        local r = number - q

        return q, r
    end
end

local PatrolActionButton = {}
PatrolActionButton.__index = PatrolActionButton

local buttonCount = 0

function getButtonPos() : UDim2
    local q, r = quotientBy3(buttonCount)
    local xScale = (0.3 * q) + 0.01
    local yScale = (0.35 * r) + 0.05

    return UDim2.fromScale(xScale, yScale)
end

function PatrolActionButton.getButtonFromPatrolAction(patrolAction:PatrolAction) : TextButton?
    for _, inst:Instance in ipairs(patrolActionsFrame:GetChildren()) do
        if inst:IsA("TextButton") then
            if inst.Name == string.format("%s Action Button", patrolAction.name) then
                return inst
            end
        end
    end
end

function PatrolActionButton.new(patrolActionName:string)
    local StateManager = require(script.Parent.StateManager)
    local patrolActionButton = script.PatrolActionButton:Clone()
    patrolActionButton.Name = string.format("%s Action Button", patrolActionName)
    patrolActionButton.Text = patrolActionName
    patrolActionButton.Position = getButtonPos()
    patrolActionButton.Parent = patrolActionsFrame

    local self = setmetatable({
        patrolActionName = patrolActionName;
        button = patrolActionButton;
        _patrolActions = {};
        _lastClickTime = 0;
    }, PatrolActionButton)
    buttonCount += 1

    for iPath, path:PatrolPath in ipairs(SavedPaths.Paths) do
        self._patrolActions[iPath] = {}
        for iPoint, _ in ipairs(path.points) do
            self._patrolActions[iPath][iPoint] = {}
        end
    end

    patrolActionButton.MouseButton1Click:Connect(function()
        local point = StateManager.selectedPatrolPoint
        local path = StateManager.selectedPath
        if not point then return end

        local pathNum = path.character:GetAttribute("PathNum")
        local pointIndex = table.find(path.points, point)

        local patrolAction = self._patrolActions[pathNum][pointIndex][patrolActionName]
        if math.abs(self._lastClickTime - tick()) <= .5 then
            if StateManager.selectedPatrolAction == patrolAction then
                StateManager:DeselectPatrolAction()
            end
            self:ClearColor()
            patrolAction:Destroy()
            self._patrolActions[pathNum][pointIndex][patrolActionName] = nil
            self._lastClickTime = 0
            return
        end

        if not patrolAction then
            patrolAction = PatrolAction.new(self.patrolActionName, point._pointFldr)
            self._patrolActions[pathNum][pointIndex][patrolActionName] = patrolAction
            self._lastClickTime = 0
        else
            self._lastClickTime = tick()
        end
        StateManager:SelectPatrolAction(patrolAction)
    end)

    table.insert(StateManager._patrolActionButtons, self)

    return self
end

function PatrolActionButton:ScanIfActive()
    local StateManager = require(script.Parent.StateManager)
    local point = StateManager.selectedPatrolPoint
        local path = StateManager.selectedPath
        if not point then return end

        local pathNum = path.character:GetAttribute("PathNum")
        local pointIndex = table.find(path.points, point)
        local patrolAction:PatrolAction? = self._patrolActions[pathNum][pointIndex][self.patrolActionName]

    if patrolAction then
        self.button.UIStroke.Color = Color3.new(0.454901, 0.886274, 0.6)
        if patrolAction.waitForAnim then
            toggleWaitForPatrolActionButton.UIStroke.Color = Color3.new(0.454901, 0.886274, 0.6)
        else
            toggleWaitForPatrolActionButton.UIStroke.Color = Color3.new(1,1,1)
        end
    end
end

function PatrolActionButton:NewPathAdded()
    local pathNum = #SavedPaths.Paths + 1
    self._patrolActions[pathNum] = {}
end

function PatrolActionButton:NewPointAdded(pathNum:number, pointIndex:PatrolPoint)
    self._patrolActions[pathNum][pointIndex] = {}
end

function PatrolActionButton:ClearColor()
    self.button.UIStroke.Color = Color3.new(1,1,1)
    toggleWaitForPatrolActionButton.UIStroke.Color = Color3.new(1,1,1)
end

return PatrolActionButton