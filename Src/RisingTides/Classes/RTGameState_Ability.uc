// This is an Unreal Script

class RTGameState_Ability extends XComGameState_Ability;

// Get Bloodlust Stack Count
public static function int getBloodlustStackCount(XComGameState_Unit WaltzUnit) {
   local int iStackCount;
   local StateObjectReference IteratorObjRef;
   local RTGameState_Effect BloodlustEffectState;

   if (WaltzUnit != none) {
		// get our stacking effect
		foreach WaltzUnit.AffectedByEffects(IteratorObjRef) {
			BloodlustEffectState = RTGameState_Effect(`XCOMHISTORY.GetGameStateForObjectID(IteratorObjRef.ObjectID));
			if(BloodlustEffectState != none && BloodlustEffectState.GetX2Effect().EffectName == class'RTEffect_Bloodlust'.default.EffectName) {
				break;
			}
		}
		if(BloodlustEffectState != none) {
			iStackCount = BloodlustEffectState.iStacks;
		} else {
			iStackCount = 0;
		}
	} else  {
		`LOG("Rising Tides: No SourceUnit found for getBloodlustStackCount!");
	}
	return iStackCount;
}

// Reprobate Waltz
function EventListenerReturn ReprobateWaltzListener( Object EventData, Object EventSource, XComGameState GameState, Name EventID) {
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit WaltzUnit;
	local int iStackCount;
	local float fStackModifier, fFinalPercentChance;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	WaltzUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));

	if(AbilityContext != none) {
		iStackCount = getBloodlustStackCount(WaltzUnit);
		fFinalPercentChance = 100 -  ( class'RTAbility_BerserkerAbilitySet'.default.REPROBATE_WALTZ_BASE_CHANCE + ( class'RTAbility_BerserkerAbilitySet'.default.REPROBATE_WALTZ_BLOODLUST_STACK_CHANCE * iStackCount ));

		if(`SYNC_RAND(100) <= int(fFinalPercentChance)) {
			AbilityTriggerAgainstSingleTarget(AbilityContext.InputContext.PrimaryTarget, false);
		}
	}
	return ELR_NoInterrupt;
}

// credits to /u/robojumper

//This function is native for performance reasons, the script code below describes its function
// NO LONGER AM I SHACKLED BY NATIVE CODE
simulated function name GatherAbilityTargets(out array<AvailableTarget> Targets, optional XComGameState_Unit OverrideOwnerState)
{
	local int i, j;
	local XComGameState_Unit kOwner;
	local name AvailableCode;
	local XComGameStateHistory History;

	GetMyTemplate();
	History = `XCOMHISTORY;
	kOwner = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));
	if (OverrideOwnerState != none)
		kOwner = OverrideOwnerState;

	if (m_Template != None)
	{
		AvailableCode = m_Template.AbilityTargetStyle.GetPrimaryTargetOptions(self, Targets);
		if (AvailableCode != 'AA_Success')
			return AvailableCode;

		for (i = Targets.Length - 1; i >= 0; --i)
		{
			AvailableCode = m_Template.CheckTargetConditions(self, kOwner, History.GetGameStateForObjectID(Targets[i].PrimaryTarget.ObjectID));
			if (AvailableCode != 'AA_Success')
			{
				Targets.Remove(i, 1);
			}
		}

		if (m_Template.AbilityMultiTargetStyle != none)
		{
			m_Template.AbilityMultiTargetStyle.GetMultiTargetOptions(self, Targets);

			for (i = Targets.Length - 1; i >= 0; --i)
			{
				for (j = Targets[i].AdditionalTargets.Length - 1; j >= 0; --j)
				{
					AvailableCode = m_Template.CheckMultiTargetConditions(self, kOwner, History.GetGameStateForObjectID(Targets[i].AdditionalTargets[j].ObjectID));
					if (AvailableCode != 'AA_Success' || (Targets[i].AdditionalTargets[j].ObjectID == Targets[i].PrimaryTarget.ObjectID) && !m_Template.AbilityMultiTargetStyle.bAllowSameTarget)
					{
						Targets[i].AdditionalTargets.Remove(j, 1);
					}
				}

				AvailableCode = m_Template.AbilityMultiTargetStyle.CheckFilteredMultiTargets(self, Targets[i]);
				if (AvailableCode != 'AA_Success')
					Targets.Remove(i, 1);
			}
		}

		//The Multi-target style may have deemed some primary targets invalid in calls to CheckFilteredMultiTargets - so CheckFilteredPrimaryTargets must come afterwards.
		AvailableCode = m_Template.AbilityTargetStyle.CheckFilteredPrimaryTargets(self, Targets);
		if (AvailableCode != 'AA_Success')
			return AvailableCode;

		Targets.Sort(SortAvailableTargets);
	}
	return 'AA_Success';
}

simulated function int SortAvailableTargets(AvailableTarget TargetA, AvailableTarget TargetB)
{
	local XComGameStateHistory History;
	local XComGameState_Destructible DestructibleA, DestructibleB;
	local int HitChanceA, HitChanceB;
	local ShotBreakdown BreakdownA, BreakdownB;

	if (TargetA.PrimaryTarget.ObjectID != 0 && TargetB.PrimaryTarget.ObjectID == 0)
	{
		return -1;
	}
	if (TargetB.PrimaryTarget.ObjectID != 0 && TargetA.PrimaryTarget.ObjectID == 0)
	{
		return 1;
	}
	if (TargetA.PrimaryTarget.ObjectID == 0 && TargetB.PrimaryTarget.ObjectID == 0)
	{
		return 1;
	}
	History = `XCOMHISTORY;
	DestructibleA = XComGameState_Destructible(History.GetGameStateForObjectID(TargetA.PrimaryTarget.ObjectID));
	DestructibleB = XComGameState_Destructible(History.GetGameStateForObjectID(TargetB.PrimaryTarget.ObjectID));
	if (DestructibleA != none && DestructibleB == none)
	{
		return -1;
	}
	if (DestructibleB != none && DestructibleA == none)
	{
		return 1;
	}

	HitChanceA = GetShotBreakdown(TargetA, BreakdownA);
	HitChanceB = GetShotBreakdown(TargetB, BreakdownB);
	if (HitChanceA < HitChanceB)
	{
		return -1;
	}

	return 1;
}

// Unwilling Conduits
// this should be triggered off of a UnitUsedPsionicAbilityEvent:
// EventData = XComGameState_Ability
// EventSource = XComGameState_Unit
function EventListenerReturn UnwillingConduitEvent(Object EventData, Object EventSource, XComGameState GameState, Name EventID) {
	local XComGameStateHistory					History;
	local XComGameState_Ability					PreviousAbilityState, NewAbilityState;
	local XComGameState							NewGameState;
	local XComGameState_Unit					PreviousSourceUnitState, NewSourceUnitState, IteratorUnitState;
	local int									iConduits;
	local XComGameStateContext_Ability			AbilityContext;

	`LOG("Rising Tides: Starting Unwilling Conduit check!");

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none) {
		`LOG("Rising Tides: Unwilling Conduit Event failed, no AbilityContext!");
		`RedScreenOnce("Rising Tides: Unwilling Conduit Event failed, no AbilityContext!");
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;

	// EventData = AbilityState to Channel
	PreviousAbilityState = XComGameState_Ability(EventData);
	// Event Source = UnitState of AbilityState
	PreviousSourceUnitState = XComGameState_Unit(EventSource);

	if(PreviousAbilityState == none || PreviousSourceUnitState == none) {
		`RedScreenOnce("Rising Tides: Unwilling Conduit Event failed, no previous AbilityState or SourceUnitState!");
		return ELR_NoInterrupt;
	}

	if(!PreviousAbilityState.IsCoolingDown()) {
		return ELR_NoInterrupt;
	}


	iConduits = 0;
	foreach History.IterateByClassType(class'XComGameState_Unit', IteratorUnitState) {
		if(IteratorUnitState.AffectedByEffectNames.Find(class'RTAbility_GathererAbilitySet'.default.OverTheShoulderEffectName) != INDEX_NONE) {
			iConduits++;
		}
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
	NewSourceUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', PreviousSourceUnitState.ObjectID));
	NewAbilityState = XComGameState_Ability(NewGameState.CreateStateObject(class'XComGameState_Ability', PreviousAbilityState.ObjectID));

	if(PreviousAbilityState.iCooldown <= iConduits) {
		NewAbilityState.iCooldown = 1;
	} else {
		NewAbilityState.iCooldown -= iConduits;
	}

	NewGameState.AddStateObject(NewAbilityState);
	NewGameState.AddStateObject(NewSourceUnitState);

	XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = ConduitVisualizationFn;

	`LOG("Rising Tides: Finishing Unwilling Conduit check!");

	`TACTICALRULES.SubmitGameState(NewGameState);


	AbilityTriggerAgainstSingleTarget(OwnerStateObject, false);
	return ELR_NoInterrupt;
}

function ConduitVisualizationFn(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
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
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "Unwilling Conduits", '', eColor_Good, "img:///UILibrary_PerkIcons.UIPerk_reload");

			OutVisualizationTracks.AddItem(BuildTrack);
		}
		break;
	}
}

// Echoed Agony Listener
function EventListenerReturn EchoedAgonyListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID) {
	local XComGameState_Ability AbilityState;
	local XComGameState_Unit SourceUnitState;
	local XComGameState NewGameState;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameStateHistory History;
	local int PanicStrength;
	local GameRulesCache_Unit UnitCache;
	local X2TacticalGameRuleset TacticalRules;
	local int i;

	local bool bDebug;

	SourceUnitState = XComGameState_Unit(EventSource); // we are always the source
	if(SourceUnitState.ObjectID != OwnerStateObject.ObjectID) {
		`RedScreen("Rising Tides: Echoed Agony event had an invalid source!");
	}

	History = `XCOMHISTORY;
	TacticalRules = `TACTICALRULES;

	// determine correct panic value...
	switch(EventID) {
		case 'UnitTakeEffectDamage':
			PanicStrength = class'RTEffectBuilder'.default.AGONY_STRENGTH_TAKE_DAMAGE;
			break;
		case 'RTFeedback':
			PanicStrength = class'RTEffectBuilder'.default.AGONY_STRENGTH_TAKE_FEEDBACK;
			break;
		case 'UnitPanicked':
			PanicStrength = class'RTEffectBuilder'.default.AGONY_STRENGTH_TAKE_ECHO;
			break;
		default:
			`LOG("Rising Tides: Echoed Agony had an invalid EventID: " @ EventID);
			PanicStrength = class'RTEffectBuilder'.default.AGONY_STRENGTH_TAKE_FEEDBACK;
	}

	// this meaty block updates the panic event value and submits the change state
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
	// oh boy
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(SourceUnitState.FindAbility(class'RTAbility_GathererAbilitySet'.default.EchoedAgonyEffectAbilityTemplateName).ObjectID));
	AbilityState = XComGameState_Ability(NewGameState.CreateStateObject(class'XComGameState_Ability', AbilityState.ObjectID));
	AbilityState.PanicEventValue = PanicStrength;
	NewGameState.AddStateObject(AbilityState);
	`TACTICALRULES.SubmitGameState(NewGameState);

	//bDebug = false;
	// finally, activate the ability with the updated panic strength
	//TacticalRules.GetGameRulesCache_Unit(SourceUnitState.GetReference(), UnitCache);
	//for(i = 0; i < UnitCache.AvailableActions.Length; i++) {
		//AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(UnitCache.AvailableActions[i].AbilityObjectRef.ObjectID));
		//if(AbilityState.m_TemplateName == m_TemplateName) {     // found myself
			//bDebug = true;
			//if(UnitCache.AvailableActions[i].AvailableCode == 'AA_Success') {
				//class'XComGameStateContext_Ability'.static.ActivateAbility(UnitCache.AvailableActions[i]);
			//} else {
				//`LOG("Rising Tides: Could not activate Echoed Agony!");
			//}
			//break;
		//}
	//}

	AbilityTriggerAgainstSingleTarget(OwnerStateObject, false);

	if(!bDebug) {
		`LOG("Rising Tides: EchoedAgonyListener did not find Echoed Agony!");
	}
	return ELR_NoInterrupt;
}

function EventListenerReturn TriangulationListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID) {
	local XComGameState_Unit SourceUnitState, IteratorUnitState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	SourceUnitState = XComGameState_Unit(EventSource);
	if(SourceUnitState != XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID))) {
		return ELR_NoInterrupt;
	}

	if(!SourceUnitState.IsUnitAffectedByEffectName('RTEffect_Meld')) {
		return ELR_NoInterrupt;
	}

	if(!SourceUnitState.IsUnitAffectedByEffectName(class'RTAbility_GathererAbilitySet'.default.OverTheShoulderSourceEffectName))

	foreach History.IterateByClassType(class'XComGameState_Unit', IteratorUnitState) {
		// don't target ourselves
		if(IteratorUnitState.ObjectID == SourceUnitState.ObjectID) {
			continue;
		}
		// only target melded units
		if(!IteratorUnitState.IsUnitAffectedByEffectName('RTEffect_Meld')) {
			continue;
		}
		// don't duplicate the effect
		if(IteratorUnitState.IsUnitAffectedByEffectName(class'RTAbility_GathererAbilitySet'.default.OverTheShoulderSourceEffectName)) {
			continue;
		}
		// hit it
		AbilityTriggerAgainstSingleTarget(IteratorUnitState.GetReference(), false);
	}

	return ELR_NoInterrupt;


}




defaultproperties
{

}
