local TypeDefs = require(script.Parent.Parent.TypeDefinitions)

local PointConnection = {}
PointConnection.__index = PointConnection

type PatrolPoint = TypeDefs.PatrolPoint
type PointConnection = TypeDefs.PointConnection

function PointConnection.new(patrolPoint1:PatrolPoint, patrolPoint2:PatrolPoint) : PointConnection
    local patrolPointVis1 = patrolPoint1._visual
    local patrolPointVis2 = patrolPoint2._visual
        
    local att0 = Instance.new("Attachment")
    att0.Name = "POINT_CONNECTION_VISUAL_ATT0"
    att0.Parent = patrolPointVis1

    local att1 = Instance.new("Attachment")
    att1.Name = "POINT_CONNECTION_VISUAL_ATT1"
    att1.Parent = patrolPointVis2

    local visual = Instance.new("Beam")
    visual.Color = ColorSequence.new(Color3.fromRGB(91, 154, 76))
    visual.Name = "POINT_CONNECTION_VISUAL"
    visual.Attachment0 = att0
    visual.Attachment1 = att1
    visual.FaceCamera = true
    visual.Parent = patrolPointVis1

    local self = setmetatable({
        att0 = att0;
        att1 = att1;
        visual = visual;
    }, PointConnection)

    return self :: PointConnection
end

function PointConnection.Reconstruct(point1:PatrolPoint, point2:PatrolPoint)
    local patrolPart1 = point1._visual
    local patrolPart2 = point2._visual

    local beam = patrolPart1:FindFirstChild("POINT_CONNECTION_VISUAL")
    if not beam then return end
    local self = setmetatable({
        att0 = patrolPart1.POINT_CONNECTION_VISUAL_ATT0;
        att1 = patrolPart2.POINT_CONNECTION_VISUAL_ATT1;
        visual = beam;
    }, PointConnection)

    return self
end

function PointConnection:Destroy()
    self.visual:Destroy()
    self.att0:Destroy()
    self.att1:Destroy()
end

return PointConnection