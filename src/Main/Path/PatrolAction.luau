local RecognizedPatrolActions = require(script.Parent.Parent.RecognizedPatrolActions)
local TypDefs = require(script.Parent.Parent.TypeDefinitions)

local PatrolAction = {}
PatrolAction.__index = PatrolAction

type PatrolAction = TypDefs.PatrolAction

function PatrolAction.new(actionName:string, parentFldr:Folder) : PatrolAction
    local animId = RecognizedPatrolActions[actionName]
    assert(animId, string.format("PatrolAction by the name of %s is not recognized, add it to the RecognizedPatrolActions Module or check for typos", actionName))
    
    local patrolActionInst = Instance.new("StringValue")
    patrolActionInst.Value = actionName
    patrolActionInst.Name = actionName
    patrolActionInst:SetAttribute("Weight", 1)
    patrolActionInst:SetAttribute("WaitForAnim", false)
    patrolActionInst.Parent = parentFldr

    local self = setmetatable({
        _inst = patrolActionInst;
        name  = actionName;
        waitForAnim = false;
        weight = 1;

    }, PatrolAction)

    return self :: PatrolAction
end

function PatrolAction:ChangeWeight(weight:number?)
    self.weight = weight or self.weight
    self._inst:SetAttribute("Weight", self.weight)
end

function PatrolAction:ChangeWaitForAnim()
    self.waitForAnim = not self.WaitForAnim
    self._inst:SetAttribute("WaitForAnim", self.waitForAnim)
end

return PatrolAction