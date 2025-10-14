local TypeDefs = require(script.Parent.Parent.TypeDefinitions)
local PatrolAction = require(script.Parent.PatrolAction)

local PatrolPoint = {}
PatrolPoint.__index = PatrolPoint

local patrolPointPart = script.Parent.Parent.PatrolPointPart
local patrolPointNormalVisualizer = script.Parent.Parent.PatrolPointNormalVisualizer

type PatrolPoint = TypeDefs.PatrolPoint
type PatrolAction = TypeDefs.PatrolAction

function PatrolPoint.new(position:Vector3, pointIndex:number, patrolPathInstFldr:Folder) : PatrolPoint
    local pointFldr = Instance.new("Folder")
    pointFldr.Name = "PatrolPointInstFlder"
    pointFldr.Parent = patrolPathInstFldr

    local patrolPart:Part = patrolPointPart:Clone()
    patrolPart.Position = position
    patrolPart.CanCollide = false
    patrolPart.CanQuery = false
    patrolPart.Anchored = true
    patrolPart:SetAttribute("WaitTime", 0)
    patrolPart:SetAttribute("PointIndex", pointIndex)
    patrolPart.Parent = pointFldr

    local self = setmetatable({
        _visual = patrolPart;
        _normalVisual = nil;
        _pointFldr = pointFldr;

        position = position;
        normal = nil;
        waitTime = 0;
        patrolActions = {};
    }, PatrolPoint)

    return self :: PatrolPoint
end

function PatrolPoint.Reconstruct(visual:BasePart)
    local self = setmetatable({
        _visual = visual;
        _normalVisual = visual:FindFirstChild("PatrolPointNormalVisualizer");
        _pointFldr = visual.Parent;

        position = visual.Position;
        normal = visual:GetAttribute("Normal");
        waitTime = visual:GetAttribute("WaitTime");
        patrolActions = {};
    }, PatrolPoint)

    return self
end

-- Moves the PatrolPoint
function PatrolPoint:Move(position:Vector3)
    self.position = position
    self._visual.CFrame = CFrame.new(position)
    self:_OrientateNormalVisual()
end


-- Sets the WaitTime (in seconds) of the PatrolPoint
function PatrolPoint:SetWaitTime(waitTime:number?)
    local visual:BasePart = self._visual
    self.waitTime = waitTime or 0
    visual:SetAttribute("WaitTime", self.waitTime)
end


-- Creates a part that visualizes the normal of the PatrolPoint to the developer
function PatrolPoint:_VisualizeNormal(normal:Vector3) : BasePart?
    local normalVisual:BasePart = self._normalVisual
    local visual:BasePart = self._visual

    local function createNormalVisual() : BasePart
        local nrmlVisual:BasePart = patrolPointNormalVisualizer:Clone()
        nrmlVisual.CanCollide = false
        nrmlVisual.CanQuery = false
        nrmlVisual.Anchored = true
        nrmlVisual.Parent = visual

        return nrmlVisual
    end

    local function orientateNormalVisual(nrmlVisual:BasePart)
        nrmlVisual.PivotOffset = CFrame.new(0,0,1.25)
        nrmlVisual.CFrame = CFrame.lookAlong(Vector3.new(), normal)
        local dif = visual.CFrame.Position - (nrmlVisual.CFrame.Position + nrmlVisual.PivotOffset.Position)
        nrmlVisual.CFrame = CFrame.new(nrmlVisual.CFrame.Position + dif) * CFrame.Angles(nrmlVisual.CFrame:ToEulerAnglesXYZ())
    end

    if not normal then
        if normalVisual then
            normalVisual:Destroy()
        end
    else
        if not normalVisual then
            normalVisual = createNormalVisual()
        end
        orientateNormalVisual(normalVisual)
    end

    self._normalVisual = normalVisual
    return normalVisual
end

function PatrolPoint:_OrientateNormalVisual()
    local nrmlVisual = self._normalVisual
    local visual = self._visual
    if not nrmlVisual then return end
    local dif = visual.CFrame.Position - (nrmlVisual.CFrame.Position + nrmlVisual.PivotOffset.Position)
    nrmlVisual.CFrame = CFrame.new(nrmlVisual.CFrame.Position + dif) * CFrame.Angles(nrmlVisual.CFrame:ToEulerAnglesXYZ())
end

-- Sets the normal of the PatrolPoint
function PatrolPoint:SetNormal(normal:Vector3?)
    local visual:BasePart = self._visual

    if normal then
        self.normal = normal.Unit
    else
        self.normal = nil
    end
    self:_VisualizeNormal(self.normal)
    visual:SetAttribute("Normal", self.normal)
end

-- !INTERNAL FUNC! Finds the Patrol Action by the actionName in the PatrolPoint's "patrolActions" table, and returns it
function PatrolPoint:_FetchAction(actionName:string) : PatrolAction
    local action = self.patrolActions[actionName]
    assert(action, string.format("PatrolAction by the name %s does not exist under the specified PatrolPoint", actionName))
    return action
end

-- Add a PatrolAction--an animation--to the PatrolPoint
function PatrolPoint:AddAction(actionName:string, weight:number?)
    if self.patrolActions[actionName] then return end
    
    local action = PatrolAction.new(actionName, self._pointFldr)
    action:ChangeWeight(weight)
    self.patrolActions[actionName] = action
end

-- Change the Weight, or liklihood of playing the PatrolAction at that PatrolPoint
function PatrolPoint:SetActionWeight(actionName:string, weight:number)
    local action = self:_FetchAction(actionName)
    action:ChangeWeight(weight)
end

-- Change the WaitForAnim (boolean) property of a PatrolAction, when enabled the PatrolPoint's delay will be paused until the anim is complete
function PatrolPoint:ChangeActionWaitForAnim(actionName:string)
    local action = self:_FetchAction(actionName)
    action:ChangeWaitForAnim()
end

-- Destroys the Patrol Point and it's associated visualizers
function PatrolPoint:Destroy()
    if self._visual then
        self._visual:Destroy()
    end
    if self._normalVisual then
        self._normalVisual:Destroy()
    end
    self._pointFldr:Destroy()
end

return PatrolPoint