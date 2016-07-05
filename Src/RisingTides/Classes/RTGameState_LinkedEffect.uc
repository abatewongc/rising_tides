class RTGameState_LinkedEffect extends XComGameState_Effect;

function EventListenerReturn LinkedFireCheck (Object EventData, Object EventSource, XComGameState GameState, Name EventID) {
    local XComGameState_Unit TargetUnit, LinkedSourceUnit, LinkedUnit;
	local XComGameStateHistory History;
	local RTEffect_LinkedIntelligence LinkedEffect;
    local RTGameState_MeldEffect  MeldEffectState;
	local StateObjectReference AbilityRef;
	local XComGameState_Ability AbilityState, OriginalShot;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState NewGameState;
	local RTGameState_LinkedEffect NewLinkedEffectState;

	History = `XCOMHISTORY;
    // The TargetUnit is the unit targeted by the source unit
	TargetUnit = XComGameState_Unit(EventData);

    // The LinkedSourceUnit should be the unit that has Linked Intelligence
	LinkedSourceUnit = XComGameState_Unit(EventSource);

	// The Linked Unit is the one responding to the call to arms
	LinkedUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	
	// The parent template of this RTGameState_LinkedEffect
	LinkedEffect = RTEffect_LinkedIntelligence(GetX2Effect()); 

	// Get the ability we're going to fire if we do so
	// EventID should only be the exact names of the shot fired by the source unit
	// that way the LinkedUnits fire the same type of shot (standard OW or TR)
	AbilityRef = LinkedUnit.FindAbility(EventID);
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));

	// Only other units can shoot
	if(LinkedUnit.ObjectID == LinkedSourceUnit.ObjectID) {
		return ELR_NoInterrupt; 
	}
	// meld check
	if(!LinkedUnit.IsUnitAffectedByEffectName('RTEffect_Meld')|| !LinkedSourceUnit.IsUnitAffectedByEffectName('RTEffect_Meld')) {
		return ELR_NoInterrupt;
	}

	// Don't reveal ourselves
	if(LinkedUnit.IsConcealed()) {
		return ELR_NoInterrupt;
	}

    // only shoot enemy units
	if (TargetUnit != none && TargetUnit.IsEnemyUnit(LinkedUnit)) {
		// break out if we can't shoot
		if (AbilityState != none) {
				// break out if we can't grant an action point to shoot with
				if (LinkedEffect.GrantActionPoint != '') {
					
					// create an new gamestate and increment the number of grants
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
					NewLinkedEffectState = RTGameState_LinkedEffect(NewGameState.CreateStateObject(Class, ObjectID));
					NewLinkedEffectState.GrantsThisTurn++;
					NewGameState.AddStateObject(NewLinkedEffectState);
					
					// add a action point to shoot with
					LinkedUnit = XComGameState_Unit(NewGameState.CreateStateObject(LinkedUnit.Class, LinkedUnit.ObjectID));
					LinkedUnit.ReserveActionPoints.AddItem(LinkedEffect.GrantActionPoint);
					NewGameState.AddStateObject(LinkedUnit);

					// check if we can shoot. if we can't, clean up the gamestate from history
					if (AbilityState.CanActivateAbilityForObserverEvent(TargetUnit, LinkedUnit) != 'AA_Success')
					{
						History.CleanupPendingGameState(NewGameState);
					}
					else
					{
						`TACTICALRULES.SubmitGameState(NewGameState);

						if (LinkedEffect.bUseMultiTargets)
						{
							AbilityState.AbilityTriggerAgainstSingleTarget(LinkedUnit.GetReference(), true);
						}
						else
						{
							AbilityContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility(AbilityState, TargetUnit.ObjectID);
							if( AbilityContext.Validate() )
							{
								`TACTICALRULES.SubmitGameStateContext(AbilityContext);
							}
						}
					}
				}
				else if (AbilityState.CanActivateAbilityForObserverEvent(TargetUnit) == 'AA_Success')
				{
					if (LinkedEffect.bUseMultiTargets)
					{
						AbilityState.AbilityTriggerAgainstSingleTarget(LinkedUnit.GetReference(), true);
					}
					else
					{
						AbilityContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility(AbilityState, TargetUnit.ObjectID);
						if( AbilityContext.Validate() )
						{
							`TACTICALRULES.SubmitGameStateContext(AbilityContext);
						}
					}
				}
		}
	}

	return ELR_NoInterrupt;



}