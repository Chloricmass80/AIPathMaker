export type PatrolAction = {
    name : string;
    waitForAnim : boolean;
    weight : number;

    ChangeWeight : (PatrolAction, weight:number?) -> nil;
    ChangeWaitForAnim : (PatrolAction) -> nil;
    Destroy : (PatrolAction) -> nil;
}

export type PatrolPoint = {
    position : Vector3;
    normal : Vector3?;
    waitTime : number;
    patrolActions : {[string] : PatrolAction};

    Move : (PatrolPoint, position:Vector3) -> nil;
    SetWaitTime : (PatrolPoint, waitTime:number) -> nil;
    SetNormal : (PatrolPoint, normal:Vector3) -> nil;
    Destroy : (PatrolPoint) -> nil;

    AddAction : (PatrolPoint, actionName:string, weight:number?) -> nil;
    SetActionWeight : (PatrolPoint, actionName:string, weight:number) -> nil;
    ChangeActionWaitForAnim : (PatrolPoint, actionName:string, weight:number) -> nil;
}

export type PointConnection = {
    att0 : Attachment;
    att1 : Attachment;
    visual : Beam;

    Destroy : (PointConnection) -> nil
}

export type PatrolPath = {
    character : Model;
    points : {[number] : PatrolPoint};

    AddPatrolPoint : (PatrolPath, position:Vector3, pointIndex:number?) -> nil;
    RemovePatrolPoint : (PatrolPath, pointIndex:number) -> nil;
    BisectPatrolPoints : (PatrolPath, point1Index:number, point2Index:number) -> nil;  
    SetTransparent : (PatrolPath, instantaneous:boolean?) -> nil;
    SetOpaque : (PatrolPath, instantaneous:boolean?) -> nil;
}

export type PositionSelection = {
    position : Vector3;
    visual : Part;

    Move : (PositionSelection) -> nil;
    Destroy : (PositionSelection) -> nil;
    SolidifyToPoint : (PositionSelection, path:PatrolPath, pointIndex:number?) -> nil
}

export type PatrolActionButton = {
    patrolActionName : string;
    button : TextButton;
    
    ScanIfActive : (PatrolActionButton) -> nil;
    NewPathAdded : (PatrolActionButton) -> nil;
    NewPointAdded : (PatrolActionButton, pathNum:number, pointIndex:number) -> nil;
    ClearColor : (PatrolActionButton) -> nil;
}

export type StateManager = {
    currentState : number;
    isActive : boolean;
    isPatrolActionsDropDownActive:boolean;

    selectedPath : PatrolPath?;
    selectedPosition : PositionSelection?;
    selectedCharacter : Model?;
    selectedPatrolPoint : PatrolPoint?;
    selectedPatrolAction : PatrolAction?;

    plugin : Plugin?;

    ChangeToSelectedCharacter : (StateManager) -> nil;
    ChangeToCharacterSelected : (StateManager, character : Model?) -> nil;
    ChangeToEditingPath : (StateManager, path:PatrolPath?) -> nil;
    ChangeToSelectingPosition : (StateManager) -> nil;
    ChangeToEditingPosition : (StateManager, positionSelection : PositionSelection?) -> nil;
    ChangeToEditingPatrolPoint : (StateManager, patrolPoint : PatrolPoint?) -> nil;

    DeselectPatrolAction : (StateManager) -> nil;
    SelectPatrolAction : (StateManager, patrolAction:PatrolAction) -> nil;

    ActivatePatrolActionsDropDown : (StateManager) -> nil;
    DeactivatePatrolActionsDropDown : (StateManager) -> nil;
    TogglePatrolActionsDropDown : (StateManager) -> nil;
    ActivatePatrolActionWaitForAction : (StateManager) -> nil;
    DeactivatePatrolActionWaitForAction : (StateManager) -> nil;
    TogglePatrolActionWaitForAction : (StateManager) -> nil;
    DisablePlugin : (StateManager) -> nil;
    EnablePlugin : (StateManager) -> nil;
    TogglePlugin : (StateManager) -> nil;

    SelectPatrolPoint : (StateManager, point:PatrolPoint) -> nil;
}


return {}