//---------------------------------------------------------------------------------------
//  FILE:    RTAbilityMultiTarget_Line.uc
//  AUTHOR:  Aleosiss
//  DATE:    March 24 2016 
//
//  PURPOSE: Implement GetMultiTargetOptions for Line target schema         
//---------------------------------------------------------------------------------------
//  
//---------------------------------------------------------------------------------------
class RTAbilityMultiTarget_TargetedLine extends X2AbilityMultiTarget_Line;

// ----------- Have to override this native function in X2AbilityMultiTargetStyle, as all others are native-to-native calls and cannot be intercepted -----------------
/**
 * GetMultiTargetOptions
 * @param Targets will have valid PrimaryTarget filled out already
 * @return Targets with AdditionalTargets filled out given the PrimaryTarget in each element
 */
simulated function GetMultiTargetOptions(const XComGameState_Ability Ability, out array<AvailableTarget> Targets)
{
	local int								i;
	local vector							TargetUnitLocation;
	local XComGameState_Unit				TargetUnit;
	local AvailableTarget					Target;
	local XComWorldData						XWorld;
	local XComGameStateHistory				History;

	World = `XWORLD;
	History = `XCOMHISTORY;

	// I have no idea how I would go about implementing this myself, so just hijack GetMultiTargetsForLocation
	// Get the TargetUnitLocation from the primary target of the targets array, then save the primary target
	// so it doesn't get overwritten 	 
	`LOG("Rising Tides: RTAbilityMultiTarget_TargetedLine is getting MultiTargetOptions!");
	for(i = 0; i < Targets.Length; i++)
	{
		TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Targets[i].PrimaryTarget.ObjectID));
		TargetUnitLocation = World.GetPositionFromTileCoordinates(TargetUnit.TileLocation);
		Target.PrimaryTarget = Targets[i].PrimaryTarget;
		GetMultiTargetsForLocation(Ability, TargetUnitLocation, Target);
		Targets[i] = Target; 
	}
}

simulated function GetMultiTargetsForLocation(const XComGameState_Ability Ability, const vector Location, out AvailableTarget Target)
{
	super.GetMultiTargetsForLocation(Ability, Location, Target);
}

simulated function GetValidTilesForLocation(const XComGameState_Ability Ability, const vector Location, out array<TTile> ValidTiles)
{
	super.GetValidTilesForLocation(Ability, Location, ValidTiles);
}

/**
* CheckFilteredMultiTargets
* @param Target will contain a filtered primary target with its filtered multi-targets
* @return Return value should indicate if this primary target is valid, given the list of multi-targets (used to further filter the primary targets).
*/
simulated function name CheckFilteredMultiTargets(const XComGameState_Ability Ability, const AvailableTarget Target)
{
	return super.CheckFilteredMultiTargets(Ability, Target);
}

// Used to collect TargetLocations for an Ability
simulated function bool CalculateValidLocationsForLocation(const XComGameState_Ability Ability, const vector Location, AvailableTarget AvailableTargets, out array<vector> ValidLocations)
{
	return super.CalculateValidLocationsForLocation(Ability, Location, AvailableTargets, ValidLocations);
}
