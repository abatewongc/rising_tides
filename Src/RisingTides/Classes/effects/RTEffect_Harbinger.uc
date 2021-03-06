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
	local X2EventManager EventMgr;
	local RTGameState_Effect HarbyEffectState;
	local Object ListenerObj, FilterObj;

	EventMgr = `XEVENTMGR;

	HarbyEffectState = RTGameState_Effect(EffectState);

	ListenerObj = HarbyEffectState;
	FilterObj = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	EventMgr.RegisterForEvent(ListenerObj, 'RTRemoveFromMeld', HarbyEffectState.RemoveHarbingerEffect, ELD_OnStateSubmitted, 40, FilterObj); // shields expended appears to just be a generic remove effect listener
	// EventMgr.RegisterForEvent(ListenerObj, 'AbilityActivated', HarbyEffectState.RTHarbingerBonusDamage, ELD_OnStateSubmitted, 75, FilterObj); // this should go before everything...
}

simulated function bool OnEffectTicked(const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication, XComGameState_Player Player)
{
	local XComGameState_Ability OldAbilityState, NewAbilityState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	OldAbilityState = XComGameState_Ability(History.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
	if(OldAbilityState != none) {
		NewAbilityState = XComGameState_Ability(NewGameState.CreateStateObject(OldAbilityState.class, OldAbilityState.ObjectID));
		NewGameState.AddStateObject(NewAbilityState);

		NewAbilityState.iCooldown += 1;
	}

	return true;
}


simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnitState;
	local int HealAmount;

	m_aStatChanges.Length = 0;

	// gain bonus will and psi offense
	AddPersistentStatChange(eStat_Will, BONUS_WILL);
	AddPersistentStatChange(eStat_PsiOffense, BONUS_WILL);
	AddPersistentStatChange(eStat_ArmorMitigation, BONUS_ARMOR);

	TargetUnitState = XComGameState_Unit(kNewTargetState);
	// heal to full
	HealAmount = TargetUnitState.GetMaxStat(eStat_Hp) - TargetUnitState.GetCurrentStat(eStat_Hp);
	TargetUnitState.ModifyCurrentStat(eStat_HP, HealAmount);

	// remove damage mods
	TargetUnitState.Shredded = 0;
	TargetUnitState.Ruptured = 0;

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

function ModifyTurnStartActionPoints(XComGameState_Unit UnitState, out array<name> ActionPoints, XComGameState_Effect EffectState) {
	ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
}


//function int GetArmorMitigation(XComGameState_Effect EffectState, XComGameState_Unit UnitState) { return BONUS_ARMOR; }
//function string GetArmorName(XComGameState_Effect EffectState, XComGameState_Unit UnitState) { return "Harbinger"; }

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers) {
	local ShotModifierInfo ModInfoAim;

	ModInfoAim.ModType = eHit_Success;
	ModInfoAim.Reason = RTFriendlyName;
	ModInfoAim.Value = BONUS_AIM;
	ShotModifiers.AddItem(ModInfoAim);
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit OldUnit, NewUnit;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;

	OldUnit = XComGameState_Unit(ActionMetadata.StateObject_OldState);
	NewUnit = XComGameState_Unit(ActionMetadata.StateObject_NewState);

	if (OldUnit != none && NewUnit != None)
	{

		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "Harbinger Intervention", '', eColor_Good);
	}
}

defaultproperties
{
	GameStateEffectClass = class'RTGameState_Effect'
}
