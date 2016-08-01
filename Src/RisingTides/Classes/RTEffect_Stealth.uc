//---------------------------------------------------------------------------------------
//  FILE:    RTEffect_Stealth.uc
//  AUTHOR:  Aleosiss
//	DATE:	 7/14/16
//  PURPOSE: True stealth ability, which is simply normal Ranger Stealth + 
//			 a DetectionModifier bump.
//           
//---------------------------------------------------------------------------------------
//  
//---------------------------------------------------------------------------------------
class RTEffect_Stealth extends X2Effect_PersistentStatChange;
	
var float fStealthModifier;
var bool bWasPreviouslyConcealed;


simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;

	
	
	UnitState = XComGameState_Unit(kNewTargetState);
	bWasPreviouslyConcealed = UnitState.IsConcealed();
		
	if (UnitState != none && !bWasPreviouslyConcealed)
		`XEVENTMGR.TriggerEvent('EffectEnterUnitConcealment', UnitState, UnitState, NewGameState);
	
	AddPersistentStatChange(eStat_DetectionModifier, fStealthModifier);
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (UnitState != none && !bWasPreviouslyConcealed)
	{
		`XEVENTMGR.TriggerEvent('EffectBreakUnitConcealment', UnitState, UnitState, NewGameState);
	}
	
	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);
}

DefaultProperties
{
	EffectName = "RTStealth"
	fStealthModifier=0.9f
	bWasPreviouslyConcealed = false
	DuplicateResponse = eDupe_Refresh
}
