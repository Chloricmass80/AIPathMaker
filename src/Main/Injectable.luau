local PathingAI = {}
local savedPathsFldr = workspace:FindFirstChild("SavedPathsFldr")

function PathingAI.GetPoints(character:Model, patrolPointModule:ModuleScript, patrolActionModule:ModuleScript)
    local PatrolPoint = require(patrolPointModule)
    local PatrolAction = require(patrolActionModule)
    local pathNum = character:GetAttribute("PathNum")
    assert(pathNum, "The character doesn't have an associated path through the plugin.")

    local pathFldr = savedPathsFldr:FindFirstChild(string.format("PathFldr%s", tostring(pathNum)))
    local points = {}

    for _, point in pathFldr:GetDescendants() do
        local index = point:GetAttribute("PointIndex")
        local waitTime = point:GetAttribute("WaitTime")
        local position = point.Position
        local normal = point:GetAttribute("Normal")

        local actions = {}
        for _, action in point:GetDescendants() do
            local weight = action:GetAttribute("Weight")
            local waitForAnim = action:GetAttribute("WaitForAnim")
            local actionName = action.Name

            local patrolAction = PatrolAction.new(actionName, character, weight, waitForAnim)
            table.insert(actions, patrolAction)
        end

        local pt = PatrolPoint.new(position, waitTime, normal, actions)
        points[index] = pt
    end

    return points
end


return PathingAI