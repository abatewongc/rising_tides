//---------------------------------------------------------------------------------------
//  FILE:    RTAbility_GathererAbilitySet.uc
//  AUTHOR:  Aleosiss
//  DATE:    18 December 2016
//  PURPOSE: Defines abilities used by Nova.
//
//---------------------------------------------------------------------------------------
//	Nova's perks.
//---------------------------------------------------------------------------------------

class RTAbility_GathererAbilitySet extends RTAbility_GhostAbilitySet config(RisingTides);



	var config float OTS_RADIUS;
	var config float OTS_RADIUS_SQ;
	var config int OTS_ACTION_POINT_COST;
	var config int UV_AIM_PENALTY;
	var config int UV_DEFENSE_PENALTY;
	var config int UV_WILL_PENALTY;

	var config int GUARDIAN_ANGEL_HEAL_VALUE;
	


	var config int MELD_INDUCTION_ACTION_POINT_COST;
	var config int MELD_INDUCTION_COOLDOWN;
	var config int MELD_INDUCTION_DURATION;
	var config bool MELD_INDUCTION_INFINITE;

	var config int EXTINCTION_EVENT_RADIUS_METERS;
	var config int EXTINCTION_EVENT_ACTION_POINT_COST;
	var config int EXTINCTION_EVENT_CHARGES;

	var config WeaponDamageValue EXTINCTION_EVENT_DMG;
	var config WeaponDamageValue RUDIMENTARY_CREATURES_DMG;

	var name ExtinctionEventStageThreeEventName;
	var name OverTheShoulderTagName;
	var name OverTheShoulderEffectName;


	var localized name GuardianAngelHealText;

//---------------------------------------------------------------------------------------
//---CreateTemplates---------------------------------------------------------------------
//---------------------------------------------------------------------------------------
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;


	Templates.AddItem(OverTheShoulder());
	Templates.AddItem(OverTheShoulderVisibilityUpdate());

	Templates.AddItem(RTForcedIntroversion());
	Templates.AddItem(PurePassive('RTUnsettlingVoices', "img:///UILibrary_PerkIcons.UIPerk_swordSlash", true));
	Templates.AddItem(RTTheSixPathsOfPain());
	Templates.AddItem(RTTheSixPathsOfPainIcon());
	Templates.AddItem(RTMeldInduction());
	Templates.AddItem(RTGuardianAngel());
	Templates.AddItem(RTRudimentaryCreatures());
	Templates.AddItem(RTRudimentaryCreaturesEvent());
	Templates.AddItem(RTExtinctionEventPartOne());
	Templates.AddItem(RTExtinctionEventPartTwo());
	Templates.AddItem(RTExtinctionEventPartThree());


	return Templates;
}

	


//---------------------------------------------------------------------------------------
//---Over the Shoulder-------------------------------------------------------------------
//---------------------------------------------------------------------------------------
static function X2AbilityTemplate OverTheShoulder()
{
	local X2AbilityTemplate						Template;
	local X2AbilityCost_ActionPoints			ActionPoint;
	local X2AbilityCooldown						Cooldown;
	local X2AbilityMultiTarget_Radius			Radius;
	local X2Condition_UnitProperty				AllyCondition, LivingNonAllyUnitOnlyProperty;
	local array<name>                       SkipExclusions;
	

	local RTEffect_OverTheShoulder				OTSEffect;      // I'm unsure of how this works... but it appears that
																// this will control the application and removal of aura effects within its range

	// Over The Shoulder
	local RTEffect_MobileSquadViewer			VisionEffect;	// this lifts a small amount of the FOG around the unit
	local X2Effect_ScanningProtocol				ScanningEffect;	// this gives sight of the unit to the player														
	local X2Effect_IncrementUnitValue			TagEffect;		// this tags the unit so certain OTS effects can only proc once per turn

	// Unsettling Voices
	local RTEffect_UnsettlingVoices				VoiceEffect;
	local X2Condition_AbilityProperty			VoicesCondition;

	// Guardian Angel

	local X2Effect_Persistent					SelfEffect, EnemyEffect, AllyEffect;




	`CREATE_X2TEMPLATE(class'RTAbilityTemplate', Template, 'OverTheShoulder');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_swordSlash";
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Neutral;

	ActionPoint = new class'X2AbilityCost_ActionPoints';
	ActionPoint.iNumPoints = default.OTS_ACTION_POINT_COST;
	ActionPoint.bConsumeAllPoints = false;
	Template.AbilityCosts.AddItem(ActionPoint);

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = 1;
	Template.AbilityCooldown = Cooldown;

	AllyCondition = new class 'X2Condition_UnitProperty';
	AllyCondition.ExcludeDead = true;
	AllyCondition.ExcludeCivilian = true;
	AllyCondition.ExcludeRobotic = true;
	AllyCondition.ExcludeHostileToSource = true;
	AllyCondition.ExcludeFriendlyToSource = false;
	AllyCondition.FailOnNonUnits = true;
	
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	LivingNonAllyUnitOnlyProperty = new class 'X2Condition_UnitProperty';
	LivingNonAllyUnitOnlyProperty.ExcludeAlive = false;
	LivingNonAllyUnitOnlyProperty.ExcludeDead = true;
	LivingNonAllyUnitOnlyProperty.ExcludeFriendlyToSource = true;
	LivingNonAllyUnitOnlyProperty.ExcludeHostileToSource = false;
	LivingNonAllyUnitOnlyProperty.TreatMindControlledSquadmateAsHostile = true;
	LivingNonAllyUnitOnlyProperty.FailOnNonUnits = true;
	LivingNonAllyUnitOnlyProperty.ExcludeCivilian = false;

	Radius = new class'X2AbilityMultiTarget_Radius';
	Radius.bUseWeaponRadius = false;
	Radius.bIgnoreBlockingCover = true;
	Radius.bExcludeSelfAsTargetIfWithinRadius = true; // for now
	Radius.fTargetRadius = 	default.OTS_RADIUS * class'XComWorldData'.const.WORLD_StepSize * class'XComWorldData'.const.WORLD_UNITS_TO_METERS_MULTIPLIER;
	Template.AbilityMultiTargetStyle = Radius;
	Template.AbilityMultiTargetConditions.Additem(default.LivingTargetUnitOnlyProperty);

	TagEffect = new class'X2Effect_IncrementUnitValue';
	TagEffect.UnitName = default.OverTheShoulderTagName;
	TagEffect.NewValueToSet = 1;
	TagEffect.CleanupType = eCleanup_BeginTurn;
	TagEffect.SetupEffectOnShotContextResult(true, true);      //  mark them regardless of whether the shot hit or missed
	Template.AddMultiTargetEffect(TagEffect);

	// begin non-ally aura effects	---------------------------------------

	VisionEffect = new class'RTEffect_MobileSquadViewer';
	VisionEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	VisionEffect.SetDisplayInfo(ePerkBuff_Penalty, default.OTS_TITLE, default.OTS_DESC_ENEMY, Template.IconImage, true,,Template.AbilitySourceName);
	VisionEffect.TargetConditions.AddItem(LivingNonAllyUnitOnlyProperty);
	VisionEffect.DuplicateResponse = eDupe_Ignore;
	VisionEffect.bUseTargetSightRadius = false;
	VisionEffect.iCustomTileRadius = 3;
	VisionEffect.bRemoveWhenTargetDies = true;
	VisionEffect.bRemoveWhenSourceDies = true;
	VisionEffect.EffectName = default.OverTheShoulderEffectName;
	Template.AddMultiTargetEffect(VisionEffect);

	ScanningEffect = new class'X2Effect_ScanningProtocol';
	ScanningEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	ScanningEffect.TargetConditions.AddItem(LivingNonAllyUnitOnlyProperty);
	ScanningEffect.DuplicateResponse = eDupe_Ignore;
	ScanningEffect.bRemoveWhenTargetDies = true;
	ScanningEffect.bRemoveWhenSourceDies = true;
	Template.AddMultiTargetEffect(ScanningEffect);

	VoiceEffect = new class'RTEffect_UnsettlingVoices';
	VoiceEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	VoiceEffect.TargetConditions.AddItem(LivingNonAllyUnitOnlyProperty);
	VoiceEffect.SetDisplayInfo(ePerkBuff_Penalty,default.UV_TITLE, default.UV_DESC, Template.IconImage, true,,Template.AbilitySourceName);	// TODO: ICON
	VoiceEffect.DuplicateResponse = eDupe_Ignore;
	VoiceEffect.bRemoveWhenTargetDies = true;
	VoiceEffect.bRemoveWhenSourceDies = true;
	VoiceEffect.UV_AIM_PENALTY = default.UV_AIM_PENALTY;
	VoiceEffect.UV_DEFENSE_PENALTY = default.UV_DEFENSE_PENALTY;
	VoiceEffect.UV_WILL_PENALTY = default.UV_WILL_PENALTY;

	VoicesCondition = new class'X2Condition_AbilityProperty';
	VoicesCondition.OwnerHasSoldierAbilities.AddItem('RTUnsettlingVoices');
	VoiceEffect.TargetConditions.AddItem(VoicesCondition);

	Template.AddMultiTargetEffect(VoiceEffect);





	// end non-ally aura effects      -----------------------------------------

	// begin ally aura effects	  -----------------------------------------

	AllyEffect = new class'X2Effect_Persistent';
	AllyEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	AllyEffect.SetDisplayInfo(ePerkBuff_Bonus,default.OTS_TITLE, default.OTS_DESC_ALLY, Template.IconImage, true,,Template.AbilitySourceName);
	AllyEffect.TargetConditions.AddItem(default.LivingShooterProperty);
	AllyEffect.DuplicateResponse = eDupe_Ignore;
	Template.AddMultiTargetEffect(AllyEffect);

	// guardian angel
	CreateGuardianAngel(Template.AbilityMultiTargetEffects);




	// end ally aura effects	  ------------------------------------------

	
	// aura controller effect         ------------------------------------------
	OTSEffect = new class'RTEffect_OverTheShoulder';
	OTSEffect.BuildPersistentEffect(1,,,, eGameRule_PlayerTurnBegin);
	OTSEffect.SetDisplayInfo(ePerkBuff_Bonus, default.OTS_TITLE, default.OTS_DESC_SELF, Template.IconImage, true,,Template.AbilitySourceName);
	OTSEffect.DuplicateResponse = eDupe_Ignore;
	Template.AddShooterEffect(OTSEffect);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.AdditionalAbilities.AddItem('OverTheShoulderVisibilityUpdate');

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bShowActivation = true;
	Template.bSkipFireAction = true;

	// standard ghost abilities
	Template.AdditionalAbilities.AddItem('GhostPsiSuite');
	Template.AdditionalAbilities.AddItem('JoinMeld');
	Template.AdditionalAbilities.AddItem('LeaveMeld');
	Template.AdditionalAbilities.AddItem('PsiOverload');
	Template.AdditionalAbilities.AddItem('RTFeedback');

	// special meld abilities
	Template.AdditionalAbilities.AddItem('LIOverwatchShot');
	Template.AdditionalAbilities.AddItem('RTUnstableConduitBurst');
	Template.AdditionalAbilities.AddItem('PsionicActivate');
	Template.AdditionalAbilities.AddItem('RTHarbingerBonusDamage');


	return Template;
}

static function X2AbilityTemplate OverTheShoulderVisibilityUpdate() {
	local X2AbilityTemplate                     Template;
	local X2AbilityTrigger_EventListener        EventListener;
	local X2Effect_Persistent					Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'OverTheShoulderVisibilityUpdate')

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_solace";
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	Effect = new class'X2Effect_Persistent';
	Effect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	Effect.SetDisplayInfo(ePerkBuff_Penalty, "DEBUG", "DEBUG X2EFFECT_VISIBILITYUPDATE", Template.IconImage, true,,Template.AbilitySourceName);
	Effect.DuplicateResponse = eDupe_Allow;
	Template.AddTargetEffect(Effect);

	// If I remove this, it works. But if I remove it, then you get that annoying "No points, no abilities, still doesn't automatically end turn" state.
	Template.AbilityCosts.AddItem(default.FreeActionCost);

	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnVisualizationBlockCompleted;
	EventListener.ListenerData.EventID = 'UnitMoveFinished';
	EventListener.ListenerData.Filter = eFilter_None;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	EventListener.ListenerData.Priority = 40;


	//Template.AbilityTriggers.AddItem(EventListener);
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.bSkipFireAction = true;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;
}


//---------------------------------------------------------------------------------------
//---Forced Introversion-----------------------------------------------------------------
//---------------------------------------------------------------------------------------
static function X2AbilityTemplate RTForcedIntroversion() {
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener Trigger;
	local RTEffect_Stealth StealthEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'RTForcedIntroversion');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_solace";
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnVisualizationBlockCompleted;
	Trigger.ListenerData.EventID = 'RTUnitFeedbacked';
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Trigger.ListenerData.Priority = 50;
	Template.AbilityTriggers.AddItem(Trigger);

	StealthEffect = new class'RTEffect_Stealth';
	StealthEffect.fStealthModifier = 1.0f;
	StealthEffect.BuildPersistentEffect(4, false, true, false, eGameRule_PlayerTurnBegin);
	StealthEffect.SetDisplayInfo(ePerkBuff_Bonus, "Stealth", "Become invisible, and extremely difficult to detect.", Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect(StealthEffect);

	Template.AddTargetEffect(class'X2Effect_Spotted'.static.CreateUnspottedEffect());

	Template.bShowPostActivation = true;
	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	// TODO: Visualization!

	return Template;
}

//---------------------------------------------------------------------------------------
//---Extinction Event--------------------------------------------------------------------
//---------------------------------------------------------------------------------------
// Extinction Event is by nature a multi-stage ability:
// Part One: A standard move ability, except that it has Charges, an increased cost, and most importantly, a PostActivationEvent.
// Part Two: A StealthEffect and DelayedAbilityActivation that responds to the PostActivationEvent fired previously.
// Part Three: Boom in response to the DelayedAbilityActivation.
static function X2AbilityTemplate RTExtinctionEventPartOne() {
      local X2AbilityTemplate Template;
      local X2AbilityCost_ActionPoints ActionPointCost;
      local X2AbilityCharges Charges;

      `CREATE_X2ABILITY_TEMPLATE(Template, 'RTExtinctionEventPartOne');
      Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
      Template.Hostility = eHostility_Neutral;
      Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_swordSlash";
      Template.AbilitySourceName = 'eAbilitySource_Psionic';

      Template.FrameAbilityCameraType = eCameraFraming_Never;

  	  Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
  	  Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

      Template.CinescriptCameraType = "StandardMovement";

  	  Template.bSkipFireAction = false;
  	  Template.bCrossClassEligible = false;

      Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
      Template.AbilityTargetStyle = default.SelfTarget;
      Template.AbilityToHitCalc = default.Deadeye;

      ActionPointCost = new class'X2AbilityCost_ActionPoints';
      ActionPointCost.iNumPoints = default.EXTINCTION_EVENT_ACTION_POINT_COST;
      ActionPointCost.bConsumeAllPoints = true;
      Template.AbilityCosts.AddItem(ActionPointCost);

      Charges = new class'X2AbilityCharges';
      Charges.InitialCharges = default.EXTINCTION_EVENT_CHARGES;
      Template.AbilityCharges = Charges;

      Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
      Template.AddShooterEffectExclusions();

      Template.PostActivationEvents.AddItem('RTExtinctionEventPartTwo');
	  Template.AdditionalAbilities.AddItem('RTExtinctionEventPartTwo');
	  Template.AdditionalAbilities.AddItem('RTExtinctionEventPartThree');


      return Template;
  }

static function X2AbilityTemplate RTExtinctionEventPartTwo() {
      local X2AbilityTemplate Template;
      local RTEffect_Stealth StealthEffect;
      local X2Effect_DelayedAbilityActivation ActivationEffect;
      local X2AbilityTrigger_EventListener Trigger;

      `CREATE_X2ABILITY_TEMPLATE(Template, 'RTExtinctionEventPartTwo');
      Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
      Template.Hostility = eHostility_Neutral;
      Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_swordSlash";
      Template.AbilitySourceName = 'eAbilitySource_Psionic';

      Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
  	  Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
  	  Template.bSkipFireAction = true;
  	  Template.bCrossClassEligible = false;

      Trigger = new class'X2AbilityTrigger_EventListener';
      Trigger.ListenerData.EventID = 'RTExtinctionEventPartTwo';
      Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
      Trigger.ListenerData.Filter = eFilter_Unit;
      Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
      Trigger.ListenerData.Priority = 50;
      Template.AbilityTriggers.AddItem(Trigger);

      Template.AbilityTargetStyle = default.SelfTarget;
      Template.AbilityToHitCalc = default.Deadeye;

      StealthEffect = new class'RTEffect_Stealth';
      StealthEffect.fStealthModifier = 1.0f;
      StealthEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
      StealthEffect.SetDisplayInfo(ePerkBuff_Bonus, "Stealth", "Become invisible, and extremely difficult to detect.", Template.IconImage, true,,Template.AbilitySourceName);
      Template.AddTargetEffect(StealthEffect);

      ActivationEffect = new class'X2Effect_DelayedAbilityActivation';
      ActivationEffect.BuildPersistentEffect(1, false, false, , eGameRule_PlayerTurnBegin);
      ActivationEffect.TriggerEventName = default.ExtinctionEventStageThreeEventName;
      Template.AddTargetEffect(ActivationEffect);

      Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

      return Template;
  }

static function X2AbilityTemplate RTExtinctionEventPartThree() {
      local X2AbilityTemplate Template;
      local X2AbilityTrigger_EventListener Trigger;
      //local X2Effect_ApplyDamageToWorld WorldDamage;
      local X2Effect_ApplyWeaponDamage WeaponDamage;
      local X2AbilityMultiTarget_Radius Radius;
      local X2Effect_Persistent UnconsciousEffect;

      `CREATE_X2ABILITY_TEMPLATE(Template, 'RTExtinctionEventPartThree');
      Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
      Template.Hostility = eHostility_Offensive;
      Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_swordSlash";
      Template.AbilitySourceName = 'eAbilitySource_Psionic';

      Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
  	  Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
  	  Template.bSkipFireAction = true; //TODO
  	  Template.bCrossClassEligible = false;

      Template.AbilityTargetStyle = default.SelfTarget;
      Template.AbilityToHitCalc = default.Deadeye; // ur ded

      Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

      Trigger = new class'X2AbilityTrigger_EventListener';
      Trigger.ListenerData.Priority = 40; // this way we don't conflict with automatic SquadViewer cleanup
      Trigger.ListenerData.EventID = default.ExtinctionEventStageThreeEventName;
      Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
      Trigger.ListenerData.Filter = eFilter_Unit;
      Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
      Template.AbilityTriggers.AddItem(Trigger);

      Radius = new class'X2AbilityMultiTarget_Radius';
      Radius.fTargetRadius = default.EXTINCTION_EVENT_RADIUS_METERS * class'XComWorldData'.const.WORLD_StepSize * class'XComWorldData'.const.WORLD_UNITS_TO_METERS_MULTIPLIER;
      Radius.bUseWeaponRadius = false;
      Radius.bIgnoreBlockingCover = true;
      Radius.bExcludeSelfAsTargetIfWithinRadius = true; // for now
      Template.AbilityMultiTargetStyle = Radius;

      UnconsciousEffect = class'X2StatusEffects'.static.CreateUnconsciousStatusEffect();
      Template.AddTargetEffect(UnconsciousEffect);

	  WeaponDamage = new class'X2Effect_ApplyWeaponDamage';
      WeaponDamage.bIgnoreBaseDamage = true;
      WeaponDamage.EnvironmentalDamageAmount = 9999999; // good bye
      WeaponDamage.EffectDamageValue = default.EXTINCTION_EVENT_DMG;
	  WeaponDamage.DamageTypes.AddItem('Psi');
      Template.AddMultiTargetEffect(WeaponDamage);

      return Template;
  }

//---------------------------------------------------------------------------------------
//---The Six Paths of Pain---------------------------------------------------------------
//---------------------------------------------------------------------------------------
// The Six Paths of Pain is relatively simple compared to other abilities on the Gatherer tree:
// On PlayerTurnBegun, after CleanUpMobileSquadViewers, it activates.
// This adds a self-targeted effect, and an ally-targeted effect.
// Both add an action point to the target. This is for using Over the Shoulder.
// Next, SPoP activates OverTheShoulder on the Gatherer.
// Next, SPoP does a series of checks for Triangulation. First, it checks for the meld on both source and target.
// Then, it checks for Triangulation on the source.
// Finally, SPoP activates TriangulatedOverTheShoulder on each MultiTarget that passes.
static function X2AbilityTemplate RTTheSixPathsOfPain() {
      local X2AbilityTemplate Template;
      local X2AbilityTrigger_EventListener Trigger;
      local X2Effect_GrantActionPoints ActionPointEffect;
      local X2Effect_ImmediateAbilityActivation ActivationEffect;
      local X2Effect_ImmediateMultiTargetAbilityActivation MultiActivationEffect;

      local X2Condition_AbilityProperty TriangulationCondition;
      local X2AbilityMultiTarget_AllAllies MultiTarget;
      local X2Condition_UnitEffects   MeldCondition;
      local X2Condition_UnitEffectsWithAbilitySource SourceMeldCondition;
	  local X2Condition_UnitEffects FeedbackCondition;

      `CREATE_X2ABILITY_TEMPLATE(Template, 'RTTheSixPathsOfPain');
      Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
      Template.Hostility = eHostility_Neutral;
      Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_swordSlash";
      Template.AbilitySourceName = 'eAbilitySource_Psionic';

      Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
  	  Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
  	  Template.bSkipFireAction = true;
  	  Template.bCrossClassEligible = false;

      Template.AbilityTargetStyle = default.SelfTarget;
      Template.AbilityToHitCalc = default.Deadeye;

      Trigger = new class'X2AbilityTrigger_EventListener';
      Trigger.ListenerData.Priority = 35; // this way we don't conflict with automatic SquadViewer cleanup
      Trigger.ListenerData.EventID = 'PlayerTurnBegun';
      Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
      Trigger.ListenerData.Filter = eFilter_None;
      Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
      Template.AbilityTriggers.AddItem(Trigger);

      // This block handles MultiTargeting for Triangulation effects:
      // Only if the Gatherer has Triangulation.
      // Only if the Gatherer is melded.
      // Only if the Target is melded.
      MeldCondition = new class'X2Condition_UnitEffects';
      MeldCondition.AddRequireEffect(class'RTEffect_Meld'.default.EffectName, 'AA_UnitNotMelded');
      SourceMeldCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
      SourceMeldCondition.AddRequireEffect(class'RTEffect_Meld'.default.EffectName, 'AA_UnitNotMelded');
      TriangulationCondition = new class'X2Condition_AbilityProperty';
      TriangulationCondition.OwnerHasSoldierAbilities.AddItem('RTTriangulation');

      Template.AbilityMultiTargetConditions.AddItem(TriangulationCondition);
      Template.AbilityMultiTargetConditions.AddItem(MeldCondition);
      Template.AbilityMultiTargetConditions.AddItem(SourceMeldCondition);
	  Template.AbilityMultiTargetConditions.AddItem(default.LivingFriendlyUnitOnlyProperty);

      MultiTarget = new class'X2AbilityMultiTarget_AllAllies';
      Template.AbilityMultiTargetStyle = MultiTarget;

      // OTS requires an Action Point to use, but The Six Paths of Pain makes it free. Grant an additional point here.
      ActionPointEffect = new class'X2Effect_GrantActionPoints';
      ActionPointEffect.NumActionPoints = default.OTS_ACTION_POINT_COST;
      ActionPointEffect.PointType = class'X2CharacterTemplateManager'.default.StandardActionPoint;
      Template.AddTargetEffect(ActionPointEffect);
      //Template.AddMultiTargetEffect(ActionPointEffect);

	  Template.AddShooterEffectExclusions();
	  FeedbackCondition = new class'X2Condition_UnitEffects';
	  FeedbackCondition.AddExcludeEffect(default.RTFeedbackEffectName, 'AA_UnitIsPanicked');
	  Template.AbilityShooterConditions.AddItem(FeedbackCondition);

      ActivationEffect = new class'X2Effect_ImmediateAbilityActivation';
      ActivationEffect.AbilityName = 'OverTheShoulder';

      MultiActivationEffect = new class'X2Effect_ImmediateMultiTargetAbilityActivation';
      MultiActivationEffect.AbilityName = 'TriangulatedOverTheShoulder';

      Template.AddTargetEffect(ActivationEffect);
      Template.AddMultiTargetEffect(MultiActivationEffect);

      Template.AdditionalAbilities.AddItem('RTTheSixPathsOfPainIcon');

      return Template;
}

static function X2AbilityTemplate RTTheSixPathsOfPainIcon() {
    return PurePassive('RTTheSixPathsOfPainIcon', "img:///UILibrary_PerkIcons.UIPerk_swordSlash", true);
}

//---------------------------------------------------------------------------------------
//---Meld Induction----------------------------------------------------------------------
//---------------------------------------------------------------------------------------
// Meld Induction is a very simple ability.
// Simple single target ability with only a few conditions:
// Living Organic Unit
// that's not already melded.
static function X2AbilityTemplate RTMeldInduction() {
    local X2AbilityTemplate Template;
    local RTEffect_Meld MeldEffect;
    local X2AbilityCost_ActionPoints ActionPointCost;
    local X2AbilityCooldown Cooldown;
    local X2Condition_UnitProperty LivingOrganicUnitProperty;
    local X2AbilityToHitCalc_StatCheck_UnitVsUnit ToHitCalc;
	local X2Condition_UnitEffects	MeldCondition, NoMeldCondition;

    `CREATE_X2ABILITY_TEMPLATE(Template, 'RTMeldInduction');
    Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
    Template.Hostility = eHostility_Offensive;
    Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_swordSlash";
	  Template.AbilitySourceName = 'eAbilitySource_Psionic';

    ActionPointCost = new class'X2AbilityCost_ActionPoints';
    ActionPointCost.bConsumeAllPoints = false;
    ActionPointCost.iNumPoints = default.MELD_INDUCTION_ACTION_POINT_COST;
    Template.AbilityCosts.AddItem(ActionPointCost);

    Cooldown = new class'X2AbilityCooldown';
    Cooldown.iNumTurns = default.MELD_INDUCTION_COOLDOWN;
    Template.AbilityCooldown = Cooldown;

    LivingOrganicUnitProperty = new class 'X2Condition_UnitProperty';
    LivingOrganicUnitProperty.ExcludeAlive = false;
    LivingOrganicUnitProperty.ExcludeDead = true;
    LivingOrganicUnitProperty.ExcludeFriendlyToSource = false;
    LivingOrganicUnitProperty.ExcludeHostileToSource = false;
    LivingOrganicUnitProperty.TreatMindControlledSquadmateAsHostile = true;
    LivingOrganicUnitProperty.FailOnNonUnits = true;
    LivingOrganicUnitProperty.ExcludeCivilian = false;
    LivingOrganicUnitProperty.ExcludeRobotic = true;

    Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
    Template.AbilityTargetStyle = default.SimpleSingleTarget;
    Template.AbilityTargetConditions.AddItem(LivingOrganicUnitProperty);

    ToHitCalc = new class 'X2AbilityToHitCalc_StatCheck_UnitVsUnit';
    Template.AbilityToHitCalc = ToHitCalc;

	MeldCondition = new class'X2Condition_UnitEffects';
	MeldCondition.AddRequireEffect('RTEffect_Meld', 'AA_UnitNotMelded');

    Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	Template.AbilityShooterConditions.AddItem(MeldCondition);

	NoMeldCondition = new class'X2Condition_UnitEffects';
	NoMeldCondition.AddExcludeEffect('RTEffect_Meld', 'AA_UnitNotMelded');

	Template.AbilityTargetConditions.AddItem(NoMeldCondition);

    MeldEffect = new class'RTEffect_Meld';
    MeldEffect.BuildPersistentEffect(default.MELD_INDUCTION_DURATION, default.MELD_INDUCTION_INFINITE, true, false);
    MeldEffect.SetDisplayInfo(ePerkBuff_Bonus, default.MELD_TITLE,
		default.MELD_DESC, Template.IconImage);
    Template.AddTargetEffect(MeldEffect);

    Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	  Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	  Template.bSkipFireAction = true; // TODO: Visualization!

	  Template.bCrossClassEligible = false;

    return Template;
}


static function X2AbilityTemplate RTGuardianAngel() {
    return PurePassive('RTGuardianAngel', "img:///UILibrary_PerkIcons.UIPerk_swordSlash", true);
 }

static function CreateGuardianAngel(out array<X2Effect> Effects) {
      Effects.AddItem(CreateGuardianAngelHealEffect());
      Effects.AddItem(CreateGuardianAngelCleanseEffect());
      Effects.AddItem(CreateGuardianAngelStabilizeEffectPartOne());
      Effects.AddItem(CreateGuardianAngelStabilizeEffectPartTwo());
      Effects.AddItem(CreateGuardianAngelImmunitiesEffect());
}
static function RTEffect_SimpleHeal CreateGuardianAngelHealEffect() {
        local RTEffect_SimpleHeal Effect;
        local X2Condition_AbilityProperty AbilityProperty;
        local X2Condition_UnitEffects EffectProperty;

        Effect = new class'RTEffect_SimpleHeal';
        Effect.HEAL_AMOUNT = default.GUARDIAN_ANGEL_HEAL_VALUE;
        Effect.bUseWeaponDamage = false;
		Effect.AbilitySourceName = default.GuardianAngelHealText;

        AbilityProperty = new class'X2Condition_AbilityProperty';
        AbilityProperty.OwnerHasSoldierAbilities.AddItem('RTGuardianAngel');

        Effect.TargetConditions.AddItem(AbilityProperty);

        EffectProperty = new class'X2Condition_UnitEffects';
        EffectProperty.AddExcludeEffect(class'X2StatusEffects'.default.BleedingOutName, 'AA_BleedingOut');

        Effect.TargetConditions.AddItem(EffectProperty);

        Effect.TargetConditions.AddItem(default.LivingFriendlyUnitOnlyProperty);
        Effect.TargetConditions.AddItem(CreateOverTheShoulderProperty());

        return Effect;
}
static function X2Effect_RemoveEffects CreateGuardianAngelCleanseEffect() {
        local X2Effect_RemoveEffects Effect;
        local X2Condition_AbilityProperty AbilityProperty;

        Effect = new class'X2Effect_RemoveEffects';
        Effect.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
        Effect.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.ConfusedName);
        Effect.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.PanickedName);
        Effect.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.StunnedName);
        Effect.EffectNamesToRemove.AddItem(class'X2StatusEffects'.default.BleedingOutName);


        AbilityProperty = new class'X2Condition_AbilityProperty';
        AbilityProperty.OwnerHasSoldierAbilities.AddItem('RTGuardianAngel');

        Effect.TargetConditions.AddItem(AbilityProperty);

        Effect.TargetConditions.AddItem(default.LivingFriendlyUnitOnlyProperty);

        return Effect;
}
static function X2Effect_Persistent CreateGuardianAngelStabilizeEffectPartOne() {
        local X2Effect_Persistent Effect;
        local X2Condition_AbilityProperty AbilityProperty;
        local X2Condition_UnitStatCheck UnitStatCheckCondition;

        Effect = class'X2StatusEffects'.static.CreateUnconsciousStatusEffect();

        AbilityProperty = new class'X2Condition_AbilityProperty';
        AbilityProperty.OwnerHasSoldierAbilities.AddItem('RTGuardianAngel');
        Effect.TargetConditions.AddItem(AbilityProperty);

        UnitStatCheckCondition = new class'X2Condition_UnitStatCheck';
        UnitStatCheckCondition.AddCheckStat(eStat_HP, 0, eCheck_Exact);

        Effect.TargetConditions.AddItem(UnitStatCheckCondition);

        Effect.TargetConditions.AddItem(default.LivingFriendlyUnitOnlyProperty);

        return Effect;
}
static function X2Effect_RemoveEffects CreateGuardianAngelStabilizeEffectPartTwo() {
        local X2Effect_RemoveEffects Effect;
        local X2Condition_AbilityProperty AbilityProperty;
        local X2Condition_UnitStatCheck UnitStatCheckCondition;

        Effect = new class'X2Effect_RemoveEffects';
        Effect.EffectNamesToRemove.AddItem(class'X2StatusEffects'.default.UnconsciousName);

        AbilityProperty = new class'X2Condition_AbilityProperty';
        AbilityProperty.OwnerHasSoldierAbilities.AddItem('RTGuardianAngel');

        Effect.TargetConditions.AddItem(AbilityProperty);

        //Hack: Do this instead of ExcludeDead, to only exclude properly-dead or bleeding-out units. -fxs
        UnitStatCheckCondition = new class'X2Condition_UnitStatCheck';
        UnitStatCheckCondition.AddCheckStat(eStat_HP, 0, eCheck_GreaterThan);

        Effect.TargetConditions.AddItem(UnitStatCheckCondition);

        Effect.TargetConditions.AddItem(default.LivingFriendlyUnitOnlyProperty);

        return Effect;
}
static function X2Effect_DamageImmunity CreateGuardianAngelImmunitiesEffect() {
        local X2Effect_DamageImmunity Effect;
        local X2Condition_AbilityProperty AbilityProperty;

        Effect = new class'X2Effect_DamageImmunity';
        Effect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
		Effect.SetDisplayInfo(ePerkBuff_Bonus, "Guardian Angel", "Get up.", "img:///UILibrary_PerkIcons.UIPerk_swordSlash", true,, 'eAbilitySource_Psionic');
        // Guardian Angel will not stop hard CC, but cleanse it next turn.
        Effect.ImmuneTypes.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
        Effect.ImmuneTypes.AddItem(class'X2AbilityTemplateManager'.default.ConfusedName);
        Effect.ImmuneTypes.AddItem(class'X2AbilityTemplateManager'.default.PanickedName);
        Effect.DuplicateResponse = eDupe_Ignore;


        AbilityProperty = new class'X2Condition_AbilityProperty';
        AbilityProperty.OwnerHasSoldierAbilities.AddItem('RTGuardianAngel');

        Effect.TargetConditions.AddItem(AbilityProperty);

        Effect.TargetConditions.AddItem(default.LivingFriendlyUnitOnlyProperty);

        return Effect;
}

// Rudimentary Creatures is another one of my standard "there's gotta be a better way" abilities where it's just an event listener that does everything.
static function X2AbilityTemplate RTRudimentaryCreatures() {
    local X2AbilityTemplate Template;
    local RTEffect_Rudimentary Effect;

    `CREATE_X2ABILITY_TEMPLATE(Template, 'RTRudimentaryCreatures');
    Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
    Template.Hostility = eHostility_Neutral;
    Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_swordSlash";
    Template.AbilitySourceName = 'eAbilitySource_Psionic';

    Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
    Template.bCrossClassEligible = false;

    Template.AbilityTargetStyle = default.SelfTarget;
    Template.AbilityToHitCalc = default.Deadeye;
    Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

    Effect = new class'RTEffect_Rudimentary';
    Effect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnEnd);
    Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true,, Template.AbilitySourceName);
    Template.AddShooterEffect(Effect);
    Template.AdditionalAbilities.AddItem('RTRudimentaryCreaturesEvent');
	   

    return Template;
}

static function X2AbilityTemplate RTRudimentaryCreaturesEvent() {
    local X2AbilityTemplate Template;
    local X2Effect_ApplyWeaponDamage DamageEffect;

    `CREATE_X2ABILITY_TEMPLATE(Template, 'RTRudimentaryCreaturesEvent');

    Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
    Template.Hostility = eHostility_Neutral;
    Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_swordSlash";
    Template.AbilitySourceName = 'eAbilitySource_Psionic';

    Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
    Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
    Template.bCrossClassEligible = false;

    Template.AbilityTargetStyle = default.SimpleSingleTarget;
    Template.AbilityToHitCalc = default.Deadeye;
    Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder'); // triggered by listener return
	
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AbilityTargetConditions.AddItem(default.LivingTargetOnlyProperty);

    Template.AddTargetEffect(class'X2StatusEffects'.static.CreateStunnedStatusEffect(3, 100, true));

    DamageEffect = new class'X2Effect_ApplyWeaponDamage';
    DamageEffect.bIgnoreBaseDamage = true;
    DamageEffect.EffectDamageValue = default.RUDIMENTARY_CREATURES_DMG;
	DamageEffect.bIgnoreArmor = true;
	DamageEffect.DamageTypes.AddItem('Psi');
    Template.AddTargetEffect(DamageEffect);

    return Template;
}


defaultproperties
{
	ExtinctionEventStageThreeEventName = "RTExtinctionEventStageThree";
	OverTheShoulderEffectName = "RTEffect_OverTheShoulder"
	OverTheShoulderTagName = "OverTheShoulderTag"
}
