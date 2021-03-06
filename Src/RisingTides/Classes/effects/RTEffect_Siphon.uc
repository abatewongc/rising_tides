// Custom lifesteal logic, mostly firaxis code

class RTEffect_Siphon extends X2Effect;

var float SiphonAmountMultiplier;
var int SiphonMinVal, SiphonMaxVal;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Ability Ability;
	local XComGameState_Unit TargetUnit, OldTargetUnit, SourceUnit;
	local int SourceObjectID;
	local XComGameStateHistory History;
	local int LifeAmount, FinalLifeAmount;

	History = `XCOMHISTORY;

	Ability = XComGameState_Ability(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
	if( Ability == none )
	{
		Ability = XComGameState_Ability(History.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
	}

	TargetUnit = XComGameState_Unit(kNewTargetState);
	if( (Ability != none) && (TargetUnit != none) )
	{
		SourceObjectID = ApplyEffectParameters.SourceStateObjectRef.ObjectID;
		SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(SourceObjectID));
		OldTargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(TargetUnit.ObjectID));

		if( (SourceUnit != none) && (OldTargetUnit != none) )
		{
			LifeAmount = (OldTargetUnit.GetCurrentStat(eStat_HP) - TargetUnit.GetCurrentStat(eStat_HP));
			LifeAmount = LifeAmount * (1 + SiphonAmountMultiplier);

			if(LifeAmount > SiphonMaxVal && SiphonMaxVal > -1) {
				FinalLifeAmount = SiphonMaxVal;
			} else {
				FinalLifeAmount = max(LifeAmount, SiphonMinVal);
			}

			SourceUnit = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', SourceObjectID));
			SourceUnit.ModifyCurrentStat(eStat_HP, FinalLifeAmount);
			NewGameState.AddStateObject(SourceUnit);
		}
	}
}

simulated function AddX2ActionsForVisualizationSource(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit OldUnit, NewUnit;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local int Healed;

	if (EffectApplyResult != 'AA_Success')
		return;

	// Grab the current and previous gatekeeper unit and check if it has been healed
	OldUnit = XComGameState_Unit(ActionMetadata.StateObject_OldState);
	NewUnit = XComGameState_Unit(ActionMetadata.StateObject_NewState);

	Healed = NewUnit.GetCurrentStat(eStat_HP) - OldUnit.GetCurrentStat(eStat_HP);

	if( Healed > 0 )
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "Siphon: +" $ Healed, '', eColor_Good);
	}
}
