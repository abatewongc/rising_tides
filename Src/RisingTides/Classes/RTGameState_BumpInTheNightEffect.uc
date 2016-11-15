class RTGameState_BumpInTheNightEffect extends XComGameState_Effect;

function EventListenerReturn OnTacticalGameEnd(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local X2EventManager EventManager;
	local Object ListenerObj;
    local XComGameState NewGameState;

	EventManager = `XEVENTMGR;

	// Unregister our callbacks
	ListenerObj = self;
	
	EventManager.UnRegisterFromEvent(ListenerObj, 'AbilityActivated');
	
    NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("BITN cleanup");
	NewGameState.RemoveStateObject(ObjectID);
	`GAMERULES.SubmitGameState(NewGameState);
	
	return ELR_NoInterrupt;
}
function EventListenerReturn RTBumpInTheNight(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability AbilityContext;
	local StateObjectReference AbilityRef;
	local XComGameState_Ability BloodlustAbilityState, StealthAbilityState, RemoveMeldAbilityState, PsionicActivationAbilityState;
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState_Unit TargetUnit, OldTargetUnitState, NewAttacker, Attacker;
	local XComGameState NewGameState;
	local RTEffect_BumpInTheNight BITNEffect;
	local bool	bShouldTriggerMelee, bShouldTriggerStandard, bTargetIsDead;
	local int i, iNumPreviousActionPoints;

	local XComGameState_Unit AttackerStatePrevious;
	
	History = `XCOMHISTORY;
		

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none)
		return ELR_NoInterrupt;
	
	// Check if the source object was the source unit for this effect, and make sure the target was not
	if (AbilityContext.InputContext.SourceObject.ObjectID != ApplyEffectParameters.SourceStateObjectRef.ObjectID ||
		AbilityContext.InputContext.SourceObject.ObjectID == AbilityContext.InputContext.PrimaryTarget.ObjectID)
		return ELR_NoInterrupt;
	
	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	if (AbilityState == none || AbilityState.ObjectID == 0)
		return ELR_NoInterrupt;
	
	if(AbilityState.GetMyTemplateName() == 'OverwatchShot' ||  AbilityState.GetMyTemplateName() == 'StandardShot' || AbilityState.GetMyTemplateName() == 'StandardGhostShot')
            bShouldTriggerStandard = true;
	if(AbilityState.GetMyTemplateName() == 'RTBerserkerKnifeAttack' || AbilityState.GetMyTemplateName() == 'RTPyroclasticSlash' || AbilityState.GetMyTemplateName() == 'RTReprobateWaltz')
			bShouldTriggerMelee = true;
	
	// We only want to trigger BITN when the source is actually using the right ability
	if(!bShouldTriggerStandard && !bShouldTriggerMelee) {
		return ELR_NoInterrupt;
	}
	
	BITNEffect = RTEffect_BumpInTheNight(GetX2Effect());
	OldTargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	TargetUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	if (OldTargetUnitState != none && OldTargetUnitState.ObjectID > 0 &&
		TargetUnit != none && TargetUnit.ObjectID > 0) {
			bTargetIsDead = TargetUnit.IsDead();
	}

	if (bTargetIsDead)
	{
		Attacker = XComGameState_Unit(EventSource);
																																	 
		AttackerStatePrevious = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID,, GameState.HistoryIndex - 1));
		iNumPreviousActionPoints = AttackerStatePrevious.ActionPoints.Length;

		if (Attacker != none)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
			//TODO: Visualization
			NewAttacker = XComGameState_Unit(NewGameState.CreateStateObject(Attacker.Class, Attacker.ObjectID));
			XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = TriggerBumpInTheNightFlyoverVisualizationFn;
			NewGameState.AddStateObject(NewAttacker);

			if(Attacker.HasSoldierAbility('RTQueenOfBlades', true) && bShouldTriggerMelee) {	
				for(i = 0; i < iNumPreviousActionPoints; i++) {
					NewAttacker.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
				}
			}
			NewAttacker.ModifyCurrentStat(eStat_DetectionModifier, 0);

			`TACTICALRULES.SubmitGameState(NewGameState);

			
			if(Attacker.TileDistanceBetween(TargetUnit) < BITNEffect.iTileDistanceToActivate) {
				
				// melee kills additionally give bloodlust stacks and proc queen of blades
				if(bShouldTriggerMelee) { 
					// t-t-t-t-triggered
					InitializeAbilityForActivation(BloodlustAbilityState, NewAttacker, 'BumpInTheNightBloodlustListener', History);
					ActivateAbility(BloodlustAbilityState, NewAttacker.GetReference());
					NewAttacker = XComGameState_Unit(History.GetGameStateForObjectID(NewAttacker.ObjectID));
					
					// since we've added a bloodlust stack, we need to check if we should leave the meld
					if(!Attacker.HasSoldierAbility('RTContainedFury', false) && Attacker.IsUnitAffectedByEffectName('RTEffect_Meld')) {
						if(class'RTGameState_Ability'.static.getBloodlustStackCount(NewAttacker) > class'RTAbility_BerserkerAbilitySet'.default.MAX_BLOODLUST_MELDJOIN) {
							InitializeAbilityForActivation(RemoveMeldAbilityState, NewAttacker, 'LeaveMeld', History);
							ActivateAbility(RemoveMeldAbilityState, NewAttacker.GetReference());
							NewAttacker = XComGameState_Unit(History.GetGameStateForObjectID(NewAttacker.ObjectID));	
						}
					}
				} else {
					// all of the kills give stealth...
					InitializeAbilityForActivation(StealthAbilityState, NewAttacker, 'BumpInTheNightStealthListener', History);
					ActivateAbility(StealthAbilityState, NewAttacker.GetReference());																
					NewAttacker = XComGameState_Unit(History.GetGameStateForObjectID(NewAttacker.ObjectID));
				} 
			}
		}
	}

	// trigger psionic activation for unstable conduit if psionic blades were present and used
	if(Attacker.HasSoldierAbility('RTPsionicBlades') && bShouldTriggerMelee) {
		InitializeAbilityForActivation(PsionicActivationAbilityState, NewAttacker, 'PsionicActivate', History);
		ActivateAbility(PsionicActivationAbilityState, NewAttacker.GetReference());
		NewAttacker = XComGameState_Unit(History.GetGameStateForObjectID(NewAttacker.ObjectID));
	}

	return ELR_NoInterrupt;
}

private function ActivateAbility(XComGameState_Ability AbilityState, StateObjectReference TargetRef) {
	local XComGameStateContext_Ability AbilityContext;
	
	AbilityContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility(AbilityState, TargetRef.ObjectID);
	
	if( AbilityContext.Validate() ) {
		`TACTICALRULES.SubmitGameStateContext(AbilityContext);
	} else {
		`LOG("Rising Tides: Couldn't validate AbilityContext, " @ AbilityState.GetMyTemplateName() @ " not activated.");
	}
}



private function InitializeAbilityForActivation(out XComGameState_Ability AbilityState, XComGameState_Unit AbilityOwnerUnit, Name AbilityName, XComGameStateHistory History) {
	local StateObjectReference AbilityRef;

	AbilityRef = AbilityOwnerUnit.FindAbility(AbilityName);
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
	if(AbilityState == none) {
		`LOG("Rising Tides: Couldn't Initialize Ability for Activation!");
	}

}

function TriggerBumpInTheNightFlyoverVisualizationFn(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameState_Unit UnitState;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local VisualizationTrack BuildTrack;
	local XComGameStateHistory History;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState_Ability AbilityState;

	History = `XCOMHISTORY;
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		foreach VisualizeGameState.IterateByClassType(class'XComGameState_Ability', AbilityState)
		{
			break;
		}
		if (AbilityState == none)
		{
			`RedScreenOnce("Ability state missing from" @ GetFuncName() @ "-jbouscher @gameplay");
			return;
		}

		History.GetCurrentAndPreviousGameStatesForObjectID(UnitState.ObjectID, BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState, , VisualizeGameState.HistoryIndex);
		BuildTrack.StateObject_NewState = UnitState;
		BuildTrack.TrackActor = UnitState.GetVisualizer();

		AbilityTemplate = AbilityState.GetMyTemplate();
		if (AbilityTemplate != none)
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocFriendlyName, '', eColor_Good, AbilityTemplate.IconImage);

			OutVisualizationTracks.AddItem(BuildTrack);
		}
		break;
	}
}



