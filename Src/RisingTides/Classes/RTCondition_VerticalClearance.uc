// This is an Unreal Script
class RTCondition_VerticalClearance extends X2Condition;

var float fVerticalSpaceRequirement;

event name CallMeetsCondition(XComGameState_BaseObject kTarget) {
	if(CheckTarget(kTarget)) {
		return 'AA_Success';
	}

	`LOG("Rising Tides: Target invalid height clearance!");
	return 'AA_TileIsBlocked';
}

private function bool CheckTarget(XComGameState_BaseObject kTarget) {
	local XComGameState_Unit TargetUnitState;
	local Vector InitialTargetUnitLocation;
	local TTile InitialTargetUnitTile;
	// local float DesiredTargetUnitHeight;
	local XComWorldData World;

	World = `XWORLD;

	TargetUnitState = XComGameState_Unit(kTarget);
	if(TargetUnitState == none) {
		`LOG("Rising Tides: invalid unit state!");
		return false;
	}

	InitialTargetUnitTile = TargetUnitState.TileLocation;
	InitialTargetUnitTile.Z += TargetUnitState.UnitHeight;
	InitialTargetUnitLocation = World.GetPositionFromTileCoordinates(InitialTargetUnitTile);

	if (!World.HasOverheadClearance(InitialTargetUnitLocation, 64.0f)) {
			`LOG("Rising Tides: did not have overhead clearance!");
			return false;
	}

	return true;
}

defaultproperties
{
	fVerticalSpaceRequirement = 128.0f // WORLD_FloorHeight * 2
}
