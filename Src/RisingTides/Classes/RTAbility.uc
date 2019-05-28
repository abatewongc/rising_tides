//---------------------------------------------------------------------------------------
//  FILE:    RTAbility.uc
//  AUTHOR:  Aleosiss
//  DATE:    8 February 2016
//  PURPOSE: Defines methods used by all Rising Tides ability sets.
//
//---------------------------------------------------------------------------------------

class RTAbility extends X2Ability config(RisingTides);
	var protected X2Condition_UnitProperty						LivingFriendlyUnitOnlyProperty;
	var protected X2Condition_UnitEffectsWithAbilitySource		OverTheShoulderProperty;
	var protected X2Condition_UnitProperty						LivingHostileUnitOnlyNonRoboticProperty;
	var protected RTCondition_PsionicTarget						PsionicTargetingProperty;
	var protected RTCondition_UnitSize							StandardSizeProperty;
	var protected EffectReason									TagReason;

	var name UnitUsedPsionicAbilityEvent;
	var name ForcePsionicAbilityEvent;
	var name RTFeedbackEffectName;
	var name RTFeedbackWillDebuffName;
	var name RTTechnopathyTemplateName;
	var name RTGhostTagEffectName;
	var name RTMindControlEffectName;
	var name RTMindControlTemplateName;

	var config string BurstParticleString;
	var config name BurstSocketName;
	var config name BurstArrayName;
	var config name BurstAnimName;

	var config int FEEDBACK_DURATION;
	var config int MAX_BLOODLUST_MELDJOIN;

	var float DefaultPsionicAnimDelay;

// helpers
static function X2Condition_UnitValue CreateOverTheShoulderProperty() {
	local X2Condition_UnitValue Condition;

	Condition = new class'X2Condition_UnitValue';
	Condition.AddCheckValue(class'RTAbility_GathererAbilitySet'.default.OverTheShoulderTagName, 1, eCheck_LessThan);

	return Condition;

}

static function X2AbilityTemplate CreateRTCooldownCleanse(name TemplateName, name EffectNameToRemove, name EventIDToListenFor) {
	local X2AbilityTemplate Template;
	local X2Effect_RemoveEffects RemoveEffectEffect;
	local X2AbilityTrigger_EventListener Trigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.ConcealmentRule = eConceal_Always;

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = EventIDToListenFor;
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(Trigger);

	RemoveEffectEffect = new class'X2Effect_RemoveEffects';
	RemoveEffectEffect.EffectNamesToRemove.AddItem(EffectNameToRemove);

	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AddTargetEffect(RemoveEffectEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;

	Template.bCrossClassEligible = false;
	return Template;
}

static function X2AbilityTemplate CreateRTPassiveAbilityCooldown(name TemplateName, name CooldownTrackerEffectName, optional bool bTriggerCooldownViaEvent = false, optional name EventIDToListenFor) {
		local X2AbilityTemplate Template;
		local X2Effect_Persistent Effect;
		local X2AbilityTrigger_EventListener Trigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.ConcealmentRule = eConceal_Always;

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = EventIDToListenFor;
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	if(bTriggerCooldownViaEvent) {
		Template.AbilityTriggers.AddItem(Trigger);
	} else {
		Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');
	}

	// Add dead eye to guarantee
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	Effect = new class'X2Effect_Persistent';
	Effect.BuildPersistentEffect(1, true, true, true, eGameRule_PlayerTurnEnd);
	Effect.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true,,Template.AbilitySourceName);
	Effect.EffectName = CooldownTrackerEffectName;
	Template.AddTargetEffect(Effect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;	//TODO: VISUALIZATION

	Template.bSkipFireAction = true;

	Template.bCrossClassEligible = false;

		return Template;
}

static function Passive(X2AbilityTemplate Template) {
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
}

static function bool AbilityTagExpandHandler(string InString, out string OutString)
{
//	local name Tag;

//	Tag = name(InString);

	return false;
}

static function TestAbilitySetValues() {
	
}


defaultproperties
{
	DefaultPsionicAnimDelay = 4.0
	RTGhostTagEffectName = "RTGhostOperative"
	UnitUsedPsionicAbilityEvent = "UnitUsedPsionicAbility"
	ForcePsionicAbilityEvent = "ForcePsionicAbilityEvent"
	RTFeedbackEffectName = "RTFeedback"
	RTFeedbackWillDebuffName = "RTFeedbackWillDebuff"
	RTTechnopathyTemplateName = "RTTechnopathy"
	RTMindControlEffectName = "MindControl"
	RTMindControlTemplateName = "RTMindControl"
	


	Begin Object Class=X2Condition_UnitProperty Name=DefaultLivingFriendlyUnitOnlyProperty
		ExcludeAlive=false
		ExcludeDead=true
		ExcludeFriendlyToSource=false
		ExcludeHostileToSource=true
		TreatMindControlledSquadmateAsHostile=false
		FailOnNonUnits=true
		ExcludeCivilian=true
	End Object
	LivingFriendlyUnitOnlyProperty = DefaultLivingFriendlyUnitOnlyProperty

	Begin Object Class=X2Condition_UnitProperty Name=DefaultLivingHostileUnitOnlyNonRoboticProperty
		ExcludeAlive=false
		ExcludeDead=true
		ExcludeFriendlyToSource=true
		ExcludeHostileToSource=false
		TreatMindControlledSquadmateAsHostile=true
		ExcludeRobotic=true
		FailOnNonUnits=true
	End Object
	LivingHostileUnitOnlyNonRoboticProperty = DefaultLivingHostileUnitOnlyNonRoboticProperty

	Begin Object Class=RTCondition_PsionicTarget Name=DefaultPsionicTargetingProperty
		bIgnoreRobotic=false
		bIgnorePsionic=false
		bIgnoreGHOSTs=false
		bIgnoreDead=true
		bIgnoreEnemies=false
		bTargetAllies=false
		bTargetCivilians=false
	End Object
	PsionicTargetingProperty = DefaultPsionicTargetingProperty

	Begin Object Class=RTCondition_UnitSize Name=DefaultStandardSizeProperty
	End Object
	StandardSizeProperty = DefaultStandardSizeProperty
}