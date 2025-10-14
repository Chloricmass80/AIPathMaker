local PatrolPoint = require(script.PatrolPoint)
local PatrolAction = require(script.PatrolAction)
local PointConnection = require(script.PointConnection)
local SavedPaths = require(script.Parent.SavedPaths)
local Tweens = require(script.Parent.Tweens)
local TypeDefs = require(script.Parent.TypeDefinitions)

local Path = {}
Path.__index = Path

type PatrolPoint = TypeDefs.PatrolPoint
type PatrolPath = TypeDefs.PatrolPath
type PointConnection = TypeDefs.PointConnection

function Path.new(character:Model, parentFldr:Folder) : PatrolPath
    local pathNum = #SavedPaths.Paths+1
    print(pathNum)
    local pathFldr = Instance.new("Folder")
    pathFldr:SetAttribute("PathNum", pathNum)
    pathFldr.Name = string.format("PathFldr%s", tostring(pathNum))
    pathFldr.Parent = parentFldr
    character:SetAttribute("PathNum", pathNum)


    local self = setmetatable({
        character = character;
        _pathFldr = pathFldr;
        _pointConnections = {};
        points = {};
    }, Path)

    return self :: PatrolPath
end

function Path.ReconstructFromInst(pathFldr:Folder) : (PatrolPath, number)
    local pathNum = pathFldr:GetAttribute("PathNum")

    local points = {}

    for _, pointFldr in pathFldr:GetChildren() do
        local point = pointFldr.PatrolPointPart
        local index = point:GetAttribute("PointIndex")

        local actions = {}
        for _, action in pointFldr:GetDescendants() do
            if not action:IsA("Folder") then continue end
            local weight = action:GetAttribute("Weight")
            local waitForAnim = action:GetAttribute("WaitForAnim")
            local actionName = action.Name

            local patrolAction = PatrolAction.new(actionName, pointFldr)
            patrolAction:ChangeWeight(weight)
            patrolAction:ChangeWaitForAnim(waitForAnim)
            
        end

        local pt = PatrolPoint.Reconstruct(point)
        pt.patrolActions = actions
        points[index] = pt
    end

    local character

    for _, inst in ipairs(workspace:GetDescendants()) do
        if not inst:IsA("Model") then continue end
        if inst:FindFirstChildOfClass("Humanoid") then
            if inst:GetAttribute("PathNum") == pathNum then
                character = inst
                break
            end
        end
    end

    local pointConnections = {}
    if #points > 1 then
        for i, point:PatrolPoint in ipairs(points) do
            local pointConnection
            if i == #points and #points > 2 then 
                pointConnection = PointConnection.Reconstruct(point, points[1])
            elseif i ~= #points then
                pointConnection = PointConnection.Reconstruct(point, points[i+1])
            end
            pointConnections[i] = pointConnection
        end
    end

    local self = setmetatable({
        character = character;
        _pathFldr = pathFldr;
        _pointConnections = pointConnections;
        points = points;
    }, Path)

    return self
end

function Path.FetchCharacterPath(character:Model) : PatrolPath?
    local pathNum = character:GetAttribute("PathNum")
    if not pathNum then return end
    return SavedPaths.Paths[pathNum]
end

function Path:_PointConnetionVisual(pointIndex1:number, pointIndex2:number)
    local point1 = self.points[pointIndex1]
    local point2 = self.points[pointIndex2]
    local pointConnection = PointConnection.new(point1, point2)
    self._pointConnections[pointIndex1] = pointConnection
end

function Path:_RemovePointConnection(pointConnectionIndex:number)
    local pointConnection = self._pointConnections[pointConnectionIndex]
    pointConnection:Destroy()
    pointConnection[pointConnectionIndex] = nil
end

function Path:AddPatrolPoint(position:Vector3, pointIndex:number?)
    local point = PatrolPoint.new(position, pointIndex, self._pathFldr)
    if pointIndex then
        table.insert(self.points, pointIndex, point)
    else
        table.insert(self.points, point)
    end

    if #self.points > 1 then
        local pointIndexActual = pointIndex or #self.points
        self:_PointConnetionVisual(pointIndexActual-1, pointIndexActual)
    end
end

function Path:RemovePatrolPoint(pointIndex:number)
    local point:PatrolPoint = self.points[pointIndex]
    if pointIndex > 1 then
        self:_RemovePointConnection(pointIndex - 1)
    end

    point:Destroy()
    table.remove(self.points, pointIndex)

    if self.points[pointIndex] then
        self:_PointConnetionVisual(pointIndex-1, pointIndex)
    end
end


function Path:BisectPatrolPoints(point1Index:number, point2Index:number)
    if math.abs(point1Index - point2Index) ~= 1 then
        error("Must select 2 connected Patrol Points to bisect")
    end

    -- Ensures that smallest index is point1Index
    if point1Index > point2Index then
        local point1 = point1Index
        local point2 = point2Index

        point1Index = point2
        point2Index = point1
    end

    local point1:PatrolPoint = self.points[point1Index]
    local point2:PatrolPoint = self.points[point2Index]

    local X = (point1.position.X + point2.Position.X)/2
    local Y = (point1.position.Y + point2.Position.Y)/2
    local Z = (point1.position.Z + point2.Position.Z)/2

    local bisectorPosition = Vector3.new(X, Y, Z)
    self:AddPatrolPoint(bisectorPosition, point2Index)
end

function Path:SetTransparent(instantaneous:boolean?)
    if instantaneous then
        for _, patrolPoint:PatrolPoint in ipairs(self.points) do
            patrolPoint._visual.Transparency = 1
        end
        for _, pointConnection:PointConnection in ipairs(self._pointConnections) do
            pointConnection.visual.Width0 = 0
            pointConnection.visual.Width1 = 0
        end
    else
        Tweens.disableTweenPatrolParts(self.points)
        Tweens.disableTweenPointConnections(self._pointConnections)
    end
end

function Path:SetOpaque(instantaneous:boolean?)
    if instantaneous then
        for _, patrolPoint:PatrolPoint in ipairs(self.points) do
            patrolPoint._visual.Transparency = 0
        end
        for _, pointConnection:PointConnection in ipairs(self._pointConnections) do
            pointConnection.visual.Width0 = 1
            pointConnection.visual.Width1 = 1
        end
    else
        Tweens.enableTweenPatrolParts(self.points)
        Tweens.enableTweenPointConnections(self._pointConnections)
    end
end

return Path