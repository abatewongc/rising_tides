// This is an Unreal Script
class RTCondition_VisibleToPlayer extends X2Condition;

var bool bRequireLOS;

event name CallMeetsCondition(XComGameState_BaseObject kTarget) {
	return 'AA_Success';
}
event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource) {
	if(IsTargetVisibleToLocalPlayer(kTarget.GetReference(), kSource.ObjectID)) {
		if(!bRequireLOS) {
			return 'AA_Success';
		} else {
			if(DoesSourceHaveLOS(kTarget, kSource))
				return 'AA_Success';
		}
	}

	return 'AA_NotVisibleToPlayer';
}

simulated static function bool DoesSourceHaveLOS(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource) {
	local GameRulesCache_VisibilityInfo VisInfo;
	if (`TACTICALRULES.VisibilityMgr.GetVisibilityInfo(kSource.ObjectID, kTarget.ObjectID, VisInfo)) {
		if(VisInfo.bClearLOS)  {
			return true;
		}
	}
	return false;
}

simulated static function bool IsTargetVisibleToLocalPlayer(StateObjectReference TargetUnitRef, optional int SourceUnitObjectID = -2)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local EForceVisibilitySetting ForceVisibleSetting;
	local array<StateObjectReference> VisibleTargets;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(TargetUnitRef.ObjectID));
	if( UnitState != none ) {
		ForceVisibleSetting = UnitState.ForceModelVisible(); // Checks if local player, among other things.
		if( ForceVisibleSetting == eForceVisible ) {
			return true;
		}
		else if( ForceVisibleSetting == eForceNotVisible || UnitState.IsConcealed() ) { // Have to find a better way, because we might want to shoot things only visible through OverTheShoulder
			return false;
		}

		// Check if enemy can see this unit.
		return class'X2TacticalVisibilityHelpers'.static.GetNumEnemyViewersOfTarget(TargetUnitRef.ObjectID) > 0;
	} else { // the target was not a unit. in this case, all we can do is a general target check
		 // because interactive objects and destructables are always technically visible to the player through the FOW
		if(SourceUnitObjectID != -2) {
			class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyTargetsForUnit( SourceUnitObjectID, VisibleTargets );
			if(VisibleTargets.Find('ObjectID', TargetUnitRef.ObjectID) != INDEX_NONE) {
				return true;
			}
		}
		else {
			return false;
		}

	}

	return false;
}

defaultproperties
{

}
