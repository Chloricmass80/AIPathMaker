local PathingAI = {}
local savedPathsFldr = workspace:FindFirstChild("SavedPathsFldr")

function PathingAI.GetPoints(character:Model, patrolPointModule:ModuleScript, patrolActionModule:ModuleScript)
    local PatrolPoint = require(patrolPointModule)
    local PatrolAction = require(patrolActionModule)
    local pathNum = character:GetAttribute("PathNum")
    assert(pathNum, "The character doesn't have an associated path through the plugin.")

    if not savedPathsFldr then return end
    local pathFldr = savedPathsFldr:FindFirstChild(string.format("PathFldr%s", tostring(pathNum)))
    if not pathFldr then return end
    local points = {}

    for _, point in pathFldr:GetChildren() do
		local pointPart = point.PatrolPointPart
		local index = pointPart:GetAttribute("PointIndex")
		local waitTime = pointPart:GetAttribute("WaitTime")
		local position = pointPart.Position
		local normal = pointPart:GetAttribute("Normal")

        local actions = {}
        for _, action in point:GetDescendants() do
            if not action:IsA("StringValue") then continue end
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