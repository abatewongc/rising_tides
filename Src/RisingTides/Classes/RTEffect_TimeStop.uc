// This is an Unreal Script



class RTEffect_TimeStop extends X2Effect_PersistentStatChange;

var localized string	StunnedText;
var localized string	RoboticStunnedText;
var localized string	RTFriendlyNameAim;
var localized string	RTFriendlyNameCrit;

var bool bWasPreviouslyImmobilized;
var int PreviousStunDuration;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;
	local RTGameState_TimeStopEffect TimeStopEFfectState;
	local X2EventManager EventManager;
	local UnitValue	UnitVal;
	local bool IsOurTurn;

	UnitState = XComGameState_Unit(kNewTargetState);
	TimeStopEffectState = RTGameState_TimeStopEffect(NewEffectState);
	bWasPreviouslyImmobilized = false;

	if(UnitState != none)
	{
		// remove all action points... ZA WARUDO, TOKI YO, TOMARE! 
		UnitState.ReserveActionPoints.Length = 0;
		UnitState.ActionPoints.Length = 0;

		if( UnitState.IsTurret() ) // Stunned Turret.   Update turret state.
		{
			UnitState.UpdateTurretState(false);
		}

		// Immobilize to prevent scamper or panic from enabling this unit to move again.
		// Instead of just setting it to one, we're going to check and extend any immobilize already present (because TIME IS STOPPED)
		if(UnitState.GetUnitValue(class'X2Ability_DefaultAbilitySet'.default.ImmobilizedValueName, UnitVal)) {
			if(UnitVal.fValue > 0) {
				bWasPreviouslyImmobilized = true;
			}
		}
		else {
			UnitState.SetUnitFloatValue(class'X2Ability_DefaultAbilitySet'.default.ImmobilizedValueName, 1);
		}

		// TODO: Catch and delay the duration/effects of other effects
		PreviousStunDuration = UnitState.StunnedActionPoints;
		ExtendCooldownTimers(UnitState);
		
	}																			
	
	// You can't see any changes to the world while time is stopped, and you can't move either... don't know why the immo tag isn't working
	AddPersistentStatChange(eStat_DetectionRadius, 0, MODOP_PostMultiplication);
	AddPersistentStatChange(eStat_Mobility, 0, MODOP_PostMultiplication);
	AddPersistentStatChange(eStat_Dodge, 0, MODOP_PostMultiplication);

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

function GetToHitAsTargetModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ModInfoAim, ModInfoCrit;

	ModInfoAim.ModType = eHit_Success;
	ModInfoAim.Reason = RTFriendlyNameAim;
	ModInfoAim.Value = 100;
	ShotModifiers.AddItem(ModInfoAim);

	ModInfoCrit.ModType = eHit_Crit;
	ModInfoCrit.Reason = RTFriendlyNameCrit;
	ModInfoCrit.Value = 100;
	ShotModifiers.AddItem(ModInfoCrit);							   					  
}

function ModifyTurnStartActionPoints(XComGameState_Unit UnitState, out array<name> ActionPoints, XComGameState_Effect EffectState)
{
	ActionPoints.Length = 0;
}

simulated function bool OnEffectTicked(const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication)
{
	local XComGameState_Unit	TimeStopperUnit, TimeStoppedUnit;
	local UnitValue				UnitVal;


	TimeStopperUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	TimeStoppedUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));

	TimeStoppedUnit.ActionPoints.Length = 0;
	TimeStoppedUnit.ReserveActionPoints.Length = 0; 
	
	return super.OnEffectTicked(ApplyEffectParameters, kNewEffectState, NewGameState, FirstApplication);
}

simulated function ExtendCooldownTimers(XComGameState_Unit TimeStoppedUnit) {
	local XComGameState_Ability AbilityState;
	local int i;
	
	for(i = 0; i < TimeStoppedUnit.Abilities.Length; i++) {
		AbilityState = `XCOMHISTORY.GetGameStateForObjectID(TimeStoppedUnit.Abilities[i]);
		if(AbilityState.IsCoolingDown()) {
			AbilityState.iCooldown += 3; // need to add to config	
		}
	}
}

simulated function ExtendEffectDurations(XComGameState_Unit TimeStoppedUnit) {
	local XComGameState_Effect EffectState;
	local int i;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Effect', EffectState) {
		if(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID == TimeStoppedUnit.ObjectID) {
			if(!EffectState.GetX2Effect.bInfiniteDuration) {
			EffectState.iTurnsRemaining += 3;			   
			// need to somehow prevent these effects from doing damage while active... no idea how atm.
			}
		}
	}
}											 						

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local RTGameState_TimeStopEffect TimeStopEffectState;
	local XComGameState_Unit UnitState;
	local UnitValue UnitVal;

	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if( UnitState != none)
	{
		UnitState = XComGameState_Unit(NewGameState.CreateStateObject(UnitState.Class, UnitState.ObjectID));

		if(UnitState.IsTurret())
		{
			UnitState.UpdateTurretState(false);
		}

		// Update immobility status
		if(!bWasPreviouslyImmobilized) {
			UnitState.ClearUnitValue(class'X2Ability_DefaultAbilitySet'.default.ImmobilizedValueName);
		} 

		// Reset stun timer, (if you're stunned while/before time is stopped, the duration should be unchanged)
		UnitState.StunnedActionPoints = PreviousStunDuration;
		
		// And thus, time resumes...
		TimeStopEffectState = RTGameState_TimeStopEffect(RemovedEffectState);
		UnitState.TakeDamage(NewGameState, TimeStopEffectState.DamageTaken, 0, 0, , TimeStopEffectState, TimeStopEffectState.ApplyEffectParameters.SourceStateObjectRef, TimeStopEffectState.bTookExplosiveDamage, TimeStopEffectState.DamageTypesTaken);

		
		NewGameState.AddStateObject(UnitState);
	}

	

}

function bool TimeStopTicked(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication)
{
	
	local XComGameState_Unit UnitState;
	/*
	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (UnitState == none)
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));

	if (UnitState != none)
	{
		//The unit remains stunned if they still have more action points to spend being stunned.
		//The unit also remains "stunned" through one more turn, if the turn's action points have been consumed entirely by the stun.
		//In the latter case, the effect will be removed at the beginning of the next turn, just before the unit is able to act.
		//(This prevents one-turn stuns from looking like they "did nothing", when in fact they consumed exactly one turn of actions.)
		//-btopp 2015-09-21

		if(IsTickEveryAction(UnitState))
		{
			UnitState = XComGameState_Unit(NewGameState.CreateStateObject(UnitState.Class, UnitState.ObjectID));
			UnitState.StunnedActionPoints--;

			if(UnitState.StunnedActionPoints == 0)
			{
				// give them an action point back so they can move immediately
				UnitState.StunnedThisTurn = 0;
				UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
			}
			NewGameState.AddStateObject(UnitState);
		}

		if (UnitState.StunnedActionPoints > 0) 
		{
			return false;
		}
		else if (UnitState.StunnedActionPoints == 0 
			&& UnitState.NumAllActionPoints() == 0 
			&& !UnitState.GetMyTemplate().bCanTickEffectsEveryAction) // allow the stun to complete anytime if it is ticking per-action
		{
			return false;
		}
	}

	*/
	return false;

	
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, name EffectApplyResult)
{
	local X2Action_PlayAnimation PlayAnimation;
	local XComGameState_Unit TargetUnit;
	local XGUnit Unit;
	local XComUnitPawn UnitPawn;

	TargetUnit = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(BuildTrack.StateObject_NewState.ObjectID));
	if(TargetUnit == none)
	{
		`assert(false);
		TargetUnit = XComGameState_Unit(BuildTrack.StateObject_NewState);
	}

	if (EffectApplyResult == 'AA_Success' && TargetUnit != none)
	{
		if( TargetUnit.IsTurret() )
		{
			class'X2Action_UpdateTurretAnim'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext());
		}
		else
		{
			// Not a turret

			Unit = XGUnit(BuildTrack.TrackActor);
			if( Unit != None )
			{
				UnitPawn = Unit.GetPawn();

				// The unit may already be locked down (i.e. Viper bind), if so, do not play the stun start anim
				if( (UnitPawn != none) && (UnitPawn.GetAnimTreeController().CanPlayAnimation('HL_StunnedStart')) )
				{
					// Play the start stun animation
					PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
					PlayAnimation.Params.AnimName = 'HL_StunnedStart';
					PlayAnimation.bResetWeaponsToDefaultSockets = true;
				}
			}
		}

		if(TargetUnit.ActionPoints.Length > 0)
		{
			// unit had enough action points to consume the stun, so show the flyovers and just stand back up
			if (VisualizationFn != none)
				VisualizationFn(VisualizeGameState, BuildTrack, EffectApplyResult);		

			// we are just standing right back up
			AddX2ActionsForVisualization_Removed_Internal(VisualizeGameState, BuildTrack, EffectApplyResult);
		}
		else
		{
			// only apply common persistent visualization if we aren't immediately removing the effect
			super.AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, EffectApplyResult);
		}
	}
}

simulated function AddX2ActionsForVisualization_Sync(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack)
{
	//We assume 'AA_Success', because otherwise the effect wouldn't be here (on load) to get sync'd
	AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, 'AA_Success');
}

function int GetDefendingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect) { 
	local int DamageTaken, i;
	local RTGameState_TimeStopEffect TimeStopEffectState;

	// You can't take damage during a time-stop. Negate and store the damage for when it ends. 

	TimeStopEffectState = RTGameState_TimeStopEffect(EffectState);


	TimeStopEffectState.DamageTaken += CurrentDamage;
	TimeStopEffectState.DamageTypesTaken.AddItem(WeaponDamageEffect.EffectDamageValue.DamageType);
	


	return -(CurrentDamage); 
}


// if the stun is immediately removed due to not all action points being consumed, we will still need
// to visualize the unit getting up. Handle that here so that we can use the same code for normal and
// immediately recovery
simulated private function AddX2ActionsForVisualization_Removed_Internal(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult)
{
	local X2Action_PlayAnimation PlayAnimation;
	local XComGameState_Unit StunnedUnit;

	StunnedUnit = XComGameState_Unit(BuildTrack.StateObject_NewState);

	if( StunnedUnit.IsTurret() )
	{
		class'X2Action_UpdateTurretAnim'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext());
	}
	else if (StunnedUnit.IsAlive() && !StunnedUnit.IsIncapacitated()) //Don't play the animation if the unit is going straight from stunned to killed
	{
		// The unit is not a turret and is not dead/unconscious/bleeding-out
		PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
		PlayAnimation.Params.AnimName = 'HL_StunnedStop';
	}
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	super.AddX2ActionsForVisualization_Removed(VisualizeGameState, BuildTrack, EffectApplyResult, RemovedEffect);

	AddX2ActionsForVisualization_Removed_Internal(VisualizeGameState, BuildTrack, EffectApplyResult);
}

defaultproperties
{
	bIsImpairing= false
	EffectName = "TimeStopEffect"
//	DamageTypes(1) = "Mental"
	EffectTickedFn=TimeStopTicked
	CustomIdleOverrideAnim="HL_StunnedIdle"
	GameStateEffectClass = class'RTGameState_TimeStopEffect'
}
