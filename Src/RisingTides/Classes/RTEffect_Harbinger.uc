//---------------------------------------------------------------------------------------
//  FILE:    RTEffect_Harbinger.uc
//  AUTHOR:  Aleosiss
//  DATE:    18 July 2016   
//---------------------------------------------------------------------------------------
//	We are unstoppable.
//---------------------------------------------------------------------------------------

class RTEffect_Harbinger extends X2Effect_PersistentStatChange;

var int BONUS_PSI_DAMAGE, BONUS_AIM, BONUS_WILL, BONUS_ARMOR;
var localized string RTFriendlyName;

function RegisterForEvents(XComGameState_Effect EffectState) {
  local EventManager EventMgr;
  local Object ListenerObj, FilterObj;

  ListenerObj = EffectState;
  FilterObj = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetSourceStateObjRef.ObjectID)); // the source unit will have its own method of removing the effect
  EventMgr.RegisterForEvent('RTRemoveUnitFromMeld', ListenerObj, EffectState.OnShieldsExpended, ELD_OnStateSubmitted, FilterObj); // shields expended appears to just be a generic remove effect listener
}


simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit SourceUnitState, TargetUnitState;
	local XComGameStateHistory History;
	local int HealAmount;

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

	// gain bonus will and psi offense
	AddPersistentStatChange(eStat_Will, BONUS_WILL);
	AddPersistentStatChange(eStat_PsiOffense, BONUS_WILL);
	
	TargetUnitState = XComGameState_Unit(kNewTargetState);
	// heal to full
	HealAmount = TargetUnitState.GetMaxStat(eStat_Hp) - TargetUnitState.GetCurrentStat(eStat_Hp);
	TargetUnitState.ModifyCurrentStat(eStat_HP, HealAmount);
	NewGameState.AddStateObject(TargetUnitState);
}

function ModifyTurnStartActionPoints(XComGameState_Unit UnitState, out array<name> ActionPoints, XComGameState_Effect EffectState) {
	ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers) {
	local ShotModifierInfo ModInfoAim;
	
	ModInfoAim.ModType = eHit_Success;
	ModInfoAim.Reason = RTFriendlyName;
	ModInfoAim.Value = BONUS_AIM;
	ShotModifiers.AddItem(ModInfoAim);
}

function int GetDefendingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect) { 
	return -(BONUS_ARMOR); 
}

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	return BONUS_PSI_DAMAGE;
}



simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult)
{
	local XComGameState_Unit OldUnit, NewUnit;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;

	OldUnit = XComGameState_Unit(BuildTrack.StateObject_OldState);
	NewUnit = XComGameState_Unit(BuildTrack.StateObject_NewState);

	if (OldUnit != none && NewUnit != None)
	{
	
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "Harbinger", '', eColor_Good);
	}
}

simulated function AddX2ActionsForVisualization_Tick(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const int TickIndex, XComGameState_Effect EffectState)
{
	AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, 'AA_Success');
}

