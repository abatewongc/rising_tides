// Load PerkContents via this class PostBeginPlay
class RTEffect_LoadPerks extends X2Effect;

var array<name> AbilitiesToLoad;
var name ReservedName;

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComContentManager		Content;
	local XComUnitPawnNativeBase	UnitPawnNativeBase;
	local XComGameState_Unit		UnitState;
	local name n;
	
	super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
	
	Content = `CONTENT;
	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if(UnitState == none) {
		`RedScreen("Warning, was unable to find a UnitState for X2Effect_LoadPerks!");
		return;
	}
	
	UnitPawnNativeBase = XGUnit(UnitState.GetVisualizer()).GetPawn();
	if(UnitPawnNativeBase == none) {
		`RedScreen("Warning, was unable to find a UnitPawnNativeBase for X2Effect_LoadPerks!");
		return;
	}

	Content.BuildPerkPackageCache();
	foreach AbilitiesToLoad(n) {
		if(n == ReservedName)
			continue;
		Content.CachePerkContent(n);
		Content.AppendAbilityPerks(n, UnitPawnNativeBase);
	}
}

defaultproperties
{
	ReservedName = "RT_Reserved"
}