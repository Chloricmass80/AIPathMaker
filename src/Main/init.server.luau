local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")
local Tweens = require(script.Tweens)
local TextOptions = require(script.TextOptions)
local TypeDefs = require(script.TypeDefinitions)
local PatrolActionButton = require(script.PatrolActionButton)
local RecognizedPatrolActions = require(script.RecognizedPatrolActions)
local States = require(script.StateManager.States)

local Path = require(script.Path)
local PositionSelection = require(script.PositionSelection)
local SavedPaths = require(script.SavedPaths)
local StateManager = require(script.StateManager)

StateManager.plugin = plugin
SavedPaths:ReconstructFromSavedPaths()


type PatrolPath = TypeDefs.PatrolPath
type PatrolPoint = TypeDefs.PatrolPoint
type PatrolAction = TypeDefs.PatrolAction
type PositionSelection = TypeDefs.PositionSelection

local toolbar = plugin:CreateToolbar("AI Path Maker")
local mouse = plugin:GetMouse()

local activateButton = toolbar:CreateButton("ACTIVATE_PLUGIN", "Activates the AI Path Maker plugin.", "rbxassetid://18656049086", "AI Path Maker")
local mainUi = script.AiPathMakerUI
local mainFrame = mainUi.MainFrame
local pathCustomizeFrame = mainFrame.PathCustomizeFrame
local patrolActionsFrame = mainFrame.PatrolActionsFrame
local patrolActionsActionsFrame = mainFrame.PatrolActionActionsFrame
local patrolActionDropDownButton = patrolActionsFrame.PointActionDropDownButton
local newPathButton = mainFrame.NewPathButton
local toggleWaitForPatrolActionButton = patrolActionsActionsFrame.ToggleWaitForPatrolActionButton
local normalTxtBox = pathCustomizeFrame.PointNormalTxtBox
local positionTxtBox = pathCustomizeFrame.PointPosTxtBox
local waitTimeTxtBox = pathCustomizeFrame.PointWaitTxtBox


newPathButton.Text = TextOptions.pathButtonNoCharacterSelected
patrolActionDropDownButton.Text = TextOptions.patrolActionsDropDownBringUp
mainFrame.Position = UDim2.fromScale(-0.2, 0)
patrolActionsFrame.Visible = false
pathCustomizeFrame.Visible = false

for patrolActionName:string, _ in pairs(RecognizedPatrolActions) do
    PatrolActionButton.new(patrolActionName)
end

function createPath(char:Model)
    local savedPathFldr = SavedPaths.SavedPathsFldr
    local path = Path.new(char, savedPathFldr)
    table.insert(SavedPaths.Paths, path)

    return path
end

function toVector3(str:string) : Vector3?
    local nums = str:split(",")
    if #nums ~= 3 then return end


    local x = tonumber(nums[1])
    local y = tonumber(nums[2])
    local z = tonumber(nums[3])

    if not (x or y or z) then return end

    return Vector3.new(x,y,z)
end

function patrolActionsDropDownClicked()
    if Tweens.PatrolActionDropDownEndTween.PlaybackState == Enum.PlaybackState.Playing or Tweens.patrolActionDropDownStartTween.PlaybackState == Enum.PlaybackState.Playing then
        return
    end
    StateManager:TogglePatrolActionsDropDown()
end

function fetchCharacterPath(character:Model?) : Path?
    local char = StateManager.selectedCharacter or character
    assert(char, "Either have a selected character or pass a character into this function")
    return Path.FetchCharacterPath(char)
end

function injectPathData(character:Model)
    local injectable = character:FindFirstChild("PathDataInjection", true)
    if injectable then
        injectable.Source = script.Injectable.Source
        return
    end

    injectable = script.Injectable:Clone()
    injectable.Name = "PathDataInjection"
    injectable.Parent = character
end

function onCharacterSelected(agent:Instance)
    StateManager.selectedCharacter = agent
    local path = fetchCharacterPath()
    if path then
        StateManager:ChangeToEditingPath(path)
    else
        StateManager:ChangeToCharacterSelected(agent)
    end
    injectPathData(agent)
end


function solidifyPosition(pointIndex:number?)
    if not StateManager.selectedPosition then return end
    StateManager.selectedPosition:SolidifyToPoint(StateManager.selectedPath, pointIndex)
end

function newPathButtonClicked()
    if StateManager.currentState == States.EditingPath then
        StateManager:ChangeToSelectingPosition()
    elseif StateManager.currentState == States.EditingPosition then
        local pointIndex = #StateManager.selectedPath.points + 1
        solidifyPosition(pointIndex)
        StateManager:ChangeToEditingPath()
    elseif StateManager.currentState == States.CharacterSelected then
        StateManager:ChangeToEditingPath(createPath(StateManager.selectedCharacter))
    elseif StateManager.currentState == States.EditingPatrolPoint then
        StateManager:ChangeToEditingPath()
    end
end

function newPathButtonRightClicked()
    if StateManager.currentState == States.EditingPatrolPoint then
        local pointIndex = table.find(StateManager.selectedPath.points, StateManager.selectedPatrolPoint)
        StateManager.selectedPath:RemovePatrolPoint(pointIndex)
        StateManager:ChangeToEditingPath()
    end
end

function normalTxtBoxFocusLost()
    if StateManager.currentState ~= States.EditingPatrolPoint then
        normalTxtBox.Text = TextOptions.patrolPointNormalButton
        return
    end

    local text = normalTxtBox.Text
    local normal = toVector3(text)
    if normal then
        StateManager.selectedPatrolPoint:SetNormal(normal)
    end
    normalTxtBox.Text = string.format("%s%s", TextOptions.patrolPointNormalButton, tostring(StateManager.selectedPatrolPoint.normal))
end

function positionTxtBoxFocusLost()
    if StateManager.currentState ~= States.EditingPatrolPoint then
        positionTxtBox.Text = TextOptions.patrolPointPositionButton
        return
    end

    local text = positionTxtBox.Text
    local position = toVector3(text)

    if position then
        StateManager.selectedPatrolPoint:Move(position)
    end
    positionTxtBox.Text = string.format("%s%s", TextOptions.patrolPointPositionButton, tostring(StateManager.selectedPatrolPoint.position))
end

function waitTimeTxtBoxFocusLost()
    if StateManager.currentState ~= States.EditingPatrolPoint then
        waitTimeTxtBox.Text = TextOptions.patrolPointWaitTimeButton
        return
    end

    local text = waitTimeTxtBox.Text
    local waitTime = tonumber(text)

    if waitTime then
        StateManager.selectedPatrolPoint:SetWaitTime(waitTime)
    end
    waitTimeTxtBox.Text = string.format("%s%s", TextOptions.patrolPointWaitTimeButton, tostring(StateManager.selectedPatrolPoint.waitTime))
end


function selectPosition()
    if StateManager.selectedPosition then
        StateManager.selectedPosition:Move()
    else
        return PositionSelection.new()
    end
end

function mouseButton1Clicked()
    if StateManager.currentState == States.SelectingPosition or StateManager.currentState == States.EditingPosition then
        local positionSelection = selectPosition()

        if StateManager.currentState == States.EditingPosition then
            StateManager:ChangeToEditingPosition(positionSelection)
            return
        end

        local difs = {}
        for i, point:PatrolPoint in ipairs(StateManager.selectedPath.points) do
            local dif = point.position - positionSelection.position
            difs[i] = dif.Magnitude
        end
        local potentialDifs = {}
        for i, dif:number in ipairs(difs) do
            if dif <= 3 then
                table.insert(potentialDifs, {dif, i})
            end
        end

        if #potentialDifs == 0 then
            StateManager:ChangeToEditingPosition(positionSelection)
        else
            positionSelection:Destroy()
            if not potentialDifs[2] then
                StateManager:ChangeToEditingPatrolPoint(StateManager.selectedPath.points[potentialDifs[1][2]])
            else
                local minDif = {math.huge}

                for _, dif in ipairs(potentialDifs) do
                    if dif < minDif[1] then
                        dif = minDif
                    end
                end

                StateManager:ChangeToEditingPatrolPoint(StateManager.selectedPath.points[minDif[2]])
            end
        end
    elseif StateManager.currentState == States.EditingPatrolPoint then
        local positionSelection = selectPosition()
        StateManager.selectedPatrolPoint:Move(positionSelection.position)
        positionSelection:Destroy()
        positionTxtBox.Text = string.format("%s%s", TextOptions.patrolPointPositionButton, tostring(StateManager.selectedPatrolPoint.position))
    end
end

function updateSelectedCharacter()
    local selectedInstances = Selection:Get()
    if selectedInstances[2] or (not selectedInstances[1]) then
        return 
    end
    local agent:Instance = selectedInstances[1]
    
    if not (agent:FindFirstChildOfClass("Humanoid") and agent:IsA("Model")) then
        return 
    end

    if (not StateManager.selectedCharacter) or (StateManager.selectedCharacter ~= agent) then
        onCharacterSelected(agent)
    end
end

activateButton.Click:Connect(function()
    StateManager:TogglePlugin()
end)

plugin.Unloading:Connect(function()
    for _, inst:Instance in ipairs(workspace:GetChildren()) do
        if inst.Name == "POSITION_SELECTION_PATHMAKER" then
            inst:Destroy()
        end
    end

    if StateManager.selectedPosition then
        StateManager.selectedPosition:Destroy()
        StateManager.selectedPosition = nil
    end

    for _, path:PatrolPath in ipairs(SavedPaths.Paths) do
        path:SetTransparent(true)
    end
end)

mouse.Button1Down:Connect(mouseButton1Clicked)

newPathButton.MouseButton1Click:Connect(newPathButtonClicked)
newPathButton.MouseButton2Click:Connect(newPathButtonRightClicked)

RunService.Heartbeat:Connect(function()
    if not StateManager.isActive then return end
    updateSelectedCharacter()
end)

patrolActionDropDownButton.MouseButton1Click:Connect(patrolActionsDropDownClicked)
toggleWaitForPatrolActionButton.MouseButton1Click:Connect(function()
    StateManager:TogglePatrolActionWaitForAction()
end)

normalTxtBox.FocusLost:Connect(normalTxtBoxFocusLost)
positionTxtBox.FocusLost:Connect(positionTxtBoxFocusLost)
waitTimeTxtBox.FocusLost:Connect(waitTimeTxtBoxFocusLost)