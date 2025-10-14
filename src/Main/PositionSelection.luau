local UserInputService = game:GetService("UserInputService")
local TypeDefs = require(script.Parent.TypeDefinitions)

type PatrolPath = TypeDefs.PatrolPath

local PositionSelection = {}
PositionSelection.__index = PositionSelection

function positionFromMouse()
    local mousePos = UserInputService:GetMouseLocation()
    local unitRay = workspace.CurrentCamera:ScreenPointToRay(mousePos.X, mousePos.Y)

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {}
    params.FilterType = Enum.RaycastFilterType.Exclude

    local cast:RaycastResult? = workspace:Raycast(unitRay.Origin, unitRay.Direction * 200, params)
    if not cast then return end

    local position = cast.Position

    return position
end

function PositionSelection.new()
    local position = positionFromMouse()
    if not position then return end

    local visual = Instance.new("Part")
    visual.Shape = Enum.PartType.Ball
    visual.Color = Color3.new(1,1,1)
    visual.Material = Enum.Material.Neon
    visual.Size = Vector3.new(1,1,1)
    visual.Anchored = true
    visual.Massless = true
    visual.CanCollide = false
    visual.CanQuery = false
    visual.Position = position
    visual.Name = "POSITION_SELECTION_PATHMAKER"
    visual.Parent = workspace

    local self = setmetatable({
        visual = visual;
        position = position;
    }, PositionSelection)

    return self
end

function PositionSelection:Move()
    local position = positionFromMouse()
    if not position then return end
    self.visual.Position = position
    self.position = position
end

function PositionSelection:Destroy()
    self.visual:Destroy()
    self.position = nil
end

function PositionSelection:SolidifyToPoint(path:PatrolPath, pointIndex:number?)
    path:AddPatrolPoint(self.position, pointIndex)
    self.visual:Destroy()
end

return PositionSelection