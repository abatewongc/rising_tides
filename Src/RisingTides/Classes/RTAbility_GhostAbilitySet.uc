//---------------------------------------------------------------------------------------
//  FILE:    RTAbility_GhostAbilitySet.uc
//  AUTHOR:  Aleosiss
//  DATE:    8 February 2016
//  PURPOSE: Defines abilities used by all Rising Tides classes.
//           
//---------------------------------------------------------------------------------------
//	General Perks
//---------------------------------------------------------------------------------------

class RTAbility_GhostAbilitySet extends X2Ability
	config(RTGhost);

	var config int BASE_REFLECTION_CHANCE, BASE_DEFENSE_INCREASE;
	var config int TEEK_REFLECTION_INCREASE, TEEK_DEFENSE_INCREASE;
	var config int BURST_DAMAGE, BURST_COOLDOWN;
	var config int OVERLOAD_CHARGES, OVERLOAD_BASE_COOLDOWN;
	var config int OVERLOAD_PANIC_CHECK;

//---------------------------------------------------------------------------------------
//---CreateTemplates---------------------------------------------------------------------
//---------------------------------------------------------------------------------------
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(GhostPsiSuite());
	//Templates.AddItem(Meld());
	Templates.AddItem(LeaveMeld());
	Templates.AddItem(JoinMeld());
	//Templates.AddItem(Reflection());
	Templates.AddItem(PsiOverload());
	Templates.AddItem(PsiOverloadPanic());
	

	return Templates;
}
//---------------------------------------------------------------------------------------
//---Ghost Psi Suite---------------------------------------------------------------------
//---------------------------------------------------------------------------------------
static function X2AbilityTemplate GhostPsiSuite()
{
	local X2AbilityTemplate						Template;
	local X2Effect_Persistent					Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'GhostPsiSuite');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_adventpsiwitch_mindcontrol";

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Effect = new class 'X2Effect_Persistent';
	Effect.BuildPersistentEffect(1, true, true, true);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true,, Template.AbilitySourceName);
	Template.AddTargetEffect(Effect);

	Template.AdditionalAbilities.AddItem('JoinMeld');
	Template.AdditionalAbilities.AddItem('LeaveMeld');
	//Template.AdditionalAbilities.AddItem('Reflection');
	//Template.AdditionalAbilities.AddItem('PsiOverload');


	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	// Note: no visualization on purpose!
	
	Template.bCrossClassEligible = false;

	return Template;
}
//---------------------------------------------------------------------------------------
//---Reflection--------------------------------------------------------------------------
//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------
//---Meld--------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------
//---JoinMeld----------------------------------------------------------------------------
//---------------------------------------------------------------------------------------
static function X2AbilityTemplate JoinMeld()
{
	local X2AbilityTemplate					Template;
	local X2AbilityCooldown                 Cooldown;
	local X2Condition_UnitEffects			Condition;
	local RTEffect_Meld						MeldEffect;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'JoinMeld');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_adventpsiwitch_mindcontrol";
	
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_HideSpecificErrors;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_CORPORAL_PRIORITY;
	Template.HideErrors.AddItem('AA_AbilityUnavailable');
	Template.HideErrors.AddItem('MeldEffect_Active');
	Template.HideErrors.AddItem('AA_NoTargets');

	Template.ConcealmentRule = eConceal_Always;

	Template.AbilityCosts.AddItem(default.FreeActionCost);
	
	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = 1;
	Template.AbilityCooldown = Cooldown;

	Condition = new class'X2Condition_UnitEffects';
	Condition.AddExcludeEffect('RTMeld', 'MeldEffect_Active');
	Template.AbilityShooterConditions.AddItem(Condition);

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Add dead eye to guarantee
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	MeldEffect = new class 'RTEffect_Meld';
	MeldEffect.BuildPersistentEffect(1, true, false, false,  eGameRule_PlayerTurnEnd);
		MeldEffect.SetDisplayInfo(ePerkBuff_Bonus, "Mind Meld", 
		"This unit has joined the squad's mind meld, gaining and delivering psionic support.", Template.IconImage);
	Template.AddTargetEffect(MeldEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	// Note: no visualization on purpose!
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;

	Template.bCrossClassEligible = false;

	return Template;
}

//---------------------------------------------------------------------------------------
//---LeaveMeld---------------------------------------------------------------------------
//---------------------------------------------------------------------------------------
static function X2AbilityTemplate LeaveMeld()
{
	local X2AbilityTemplate					Template;
	local X2AbilityCooldown                 Cooldown;
	local RTEffect_MeldRemoved				MeldRemovedEffect;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'LeaveMeld');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_adventpsiwitch_mindcontrol";
	
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_HideIfOtherAvailable;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_CORPORAL_PRIORITY;
	Template.HideIfAvailable.AddItem('JoinMeld');

	Template.AbilityCosts.AddItem(default.FreeActionCost);
	Template.ConcealmentRule = eConceal_Always;
	
	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = 1;
	Template.AbilityCooldown = Cooldown;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Add dead eye to guarantee
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	MeldRemovedEffect = new class 'RTEffect_MeldRemoved';
	MeldRemovedEffect.BuildPersistentEffect(1, false, false, false,  eGameRule_PlayerTurnEnd);
	Template.AddTargetEffect(MeldRemovedEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	// Note: no visualization on purpose!
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;


	Template.bCrossClassEligible = false;

	return Template;
}

//---------------------------------------------------------------------------------------
//---PsiOverload-------------------------------------------------------------------------
//---------------------------------------------------------------------------------------
static function X2AbilityTemplate PsiOverload()
{
	local X2AbilityTemplate					Template;
	local X2AbilityCooldown                 Cooldown;
	local X2Effect_KillUnit					KillUnitEffect;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2Condition_UnitProperty			UnitPropertyCondition;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'PsiOverload');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_hunter";
	
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.Hostility = eHostility_Offensive;

	Template.AbilityCosts.AddItem(default.FreeActionCost);
	Template.ConcealmentRule = eConceal_Always;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = true;
	UnitPropertyCondition.ExcludeRobotic = true;
	UnitPropertyCondition.FailOnNonUnits = true;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);	
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	
	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = 6;
	Template.AbilityCooldown = Cooldown;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Add dead eye to guarantee
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	KillUnitEffect = new class 'X2Effect_KillUnit';
	KillUnitEffect.BuildPersistentEffect(1, false, false, false,  eGameRule_PlayerTurnBegin);
	Template.AddTargetEffect(KillUnitEffect);

	Template.PostActivationEvents.AddItem('RTPsiOverload');
	//Template.AdditionalAbilities.AddItem('PsiOverloadPanic');

	Template.CustomFireAnim = 'HL_Psi_MindControl';
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.CinescriptCameraType = "Psionic_FireAtUnit";

	Template.bCrossClassEligible = false;

	return Template;
}

//---------------------------------------------------------------------------------------
//---PsiOverloadPanic--------------------------------------------------------------------
//---------------------------------------------------------------------------------------
static function X2AbilityTemplate PsiOverloadPanic()
{
	local X2AbilityTemplate					Template;
	local X2AbilityTrigger_EventListener	Trigger;
	local RTEffect_Panicked					PanicEffect;
	local X2Condition_UnitProperty			Condition;
	local X2Effect_PanickedWill				PanickedWillEffect;
	local X2AbilityCost_ActionPoints		ActionPointCost;

	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'PsiOverloadPanic');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_hunter";
	
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.Hostility = eHostility_Neutral;

	Template.ConcealmentRule = eConceal_Always;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = 'RTPsiOverload';
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(Trigger);

	// Build the effect
	PanicEffect = new class'RTEffect_Panicked';
	PanicEffect.EffectName = class'X2AbilityTemplateManager'.default.PanickedName;
	PanicEffect.DuplicateResponse = eDupe_Ignore;
	PanicEffect.AddPersistentStatChange(eStat_Offense, -10);
	PanicEffect.EffectHierarchyValue = 550;
	PanicEffect.VisualizationFn = class'X2StatusEffects'.static.PanickedVisualization;
	PanicEffect.EffectTickedVisualizationFn = class'X2StatusEffects'.static.PanickedVisualizationTicked;
	PanicEffect.EffectRemovedVisualizationFn = class'X2StatusEffects'.static.PanickedVisualizationRemoved;
	PanicEffect.bRemoveWhenTargetDies = true;
	PanicEffect.DelayVisualizationSec = 0.0f;
	// One turn duration
	PanicEffect.BuildPersistentEffect(4, false, true, false, eGameRule_PlayerTurnBegin);
	PanicEffect.SetDisplayInfo(ePerkBuff_Penalty, "AGugHGGHGH", 
		"This unit recently overloaded another unit's brain, and is suffering from psionic feedback. Protect them while they recover!", Template.IconImage);
	Template.AddTargetEffect(PanicEffect);

	PanickedWillEffect = new class'X2Effect_PanickedWill';
	PanickedWillEffect.BuildPersistentEffect(5, false, true, false);
	Template.AddTargetEffect(PanickedWillEffect);

	Condition = new class'X2Condition_UnitProperty';
	Condition.ExcludeRobotic = true;
	Condition.ExcludePanicked = true;
	//Template.AbilityTargetConditions.AddItem(Condition);

	// Add dead eye to guarantee
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.PostActivationEvents.AddItem('UnitPanicked');

	Template.bSkipFireAction = true;
	Template.FrameAbilityCameraType = eCameraFraming_Never;



	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	//  NOTE: No visualization on purpose!

	Template.bCrossClassEligible = false;

	return Template;
}