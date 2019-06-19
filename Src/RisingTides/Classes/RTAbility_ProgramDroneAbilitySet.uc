class RTAbility_ProgramDroneAbilitySet extends RTAbility
	config(ProgramFaction);

	var name 				CloakingProtocolEffectName;
	var config float		CLOAKING_PROTOCOL_RADIUS_METERS;
	var localized string	CloakingProtocolTitle;
	var localized string	CloakingProtocolSelfDescription;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(RTProgramDroneCloakingProtocol());
	Templates.AddItem(RTProgramDroneCloakingProtocolOn());
	Templates.AddItem(RTProgramDroneCloakingProtocolOff());
	Templates.AddItem(RTProgramDroneConcealmentHandler());

	return Templates;
}

static function X2AbilityTemplate RTProgramDroneCloakingProtocol() {
	local X2AbilityTemplate Template;

	// name TemplateName, optional string TemplateIconImage="img:///UILibrary_PerkIcons.UIPerk_standard", optional bool bCrossClassEligible=false, optional Name AbilitySourceName='eAbilitySource_Perk', optional bool bDisplayInUI=true
	Template = PurePassive('RTProgramDroneCloakingProtocol', class'RTEffectBuilder'.default.StealthIconPath, false, 'eAbilitySource_Perk', true);
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer);

	Template.AdditionalAbilities.AddItem('RTProgramDroneCloakingProtocolOn');
	Template.AdditionalAbilities.AddItem('RTProgramDroneCloakingProtocolOff');
	Template.AdditionalAbilities.AddItem('RTProgramDroneConcealmentHandler');

	return Template;
}

static function X2AbilityTemplate RTProgramDroneCloakingProtocolOn() {
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityMultiTarget_Radius Radius;
	local RTEffect_AuraSource AuraEffect;
	local X2Condition_UnitEffects UnitEffectCondition;
	local X2Effect_PersistentStatChange MobilityDebuffEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'RTProgramDroneCloakingProtocolOn');

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = class'RTEffectBuilder'.default.StealthIconPath;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = false;
	Template.AbilityCosts.AddItem(ActionPointCost);

	UnitEffectCondition = new class'X2Condition_UnitEffects';
	UnitEffectCondition.AddExcludeEffect(default.CloakingProtocolEffectName, 'AA_UnitIsConcealed');
	Template.AbilityShooterConditions.AddItem(UnitEffectCondition);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bShowActivation = true;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	Radius = new class'X2AbilityMultiTarget_Radius';
	Radius.bUseWeaponRadius = false;
	Radius.bIgnoreBlockingCover = true;
	Radius.bExcludeSelfAsTargetIfWithinRadius = true;
	Radius.fTargetRadius =	default.CLOAKING_PROTOCOL_RADIUS_METERS * class'XComWorldData'.const.WORLD_StepSize * class'XComWorldData'.const.WORLD_UNITS_TO_METERS_MULTIPLIER;
	Template.AbilityMultiTargetStyle = Radius;

	Template.AddMultiTargetEffect(`RTEB.CreateStealthEffect(2, false));
	Template.AddMultiTargetEffect(class'X2Effect_Spotted'.static.CreateUnspottedEffect());

	// aura controller effect	------------------------------------------
	AuraEffect = new class'RTEffect_AuraSource';
	AuraEffect.BuildPersistentEffect(1, true,,, eGameRule_PlayerTurnBegin);
	AuraEffect.SetDisplayInfo(ePerkBuff_Bonus, default.CloakingProtocolTitle, default.CloakingProtocolSelfDescription, Template.IconImage, true,,Template.AbilitySourceName);
	AuraEffect.DuplicateResponse = eDupe_Refresh;
	AuraEffect.EffectName = default.CloakingProtocolEffectName;
//	AuraEffect.VFXTemplateName = "RisingTidesContentPackage.fX.P_Drone_CloakingProtocolAura";
//	AuraEffect.VFXSocket = 'FX_Base';
//	AuraEffect.VFXSocketsArrayName = 'None';
//	AuraEffect.fVFXScale = 0.5;
	AuraEffect.fRadius = default.CLOAKING_PROTOCOL_RADIUS_METERS;
	AuraEffect.bReapplyOnTick = true;
	Template.AddTargetEffect(AuraEffect);

	MobilityDebuffEffect = new class'X2Effect_PersistentStatChange';
	MobilityDebuffEffect.BuildPersistentEffect(1, true, true, false);
	MobilityDebuffEffect.AddPersistentStatChange(eStat_Mobility, 0.7, MODOP_PostMultiplication);
	MobilityDebuffEffect.EffectName = 'CloakingProtocolMobilityMalus';

	Template.AddTargetEffect(MobilityDebuffEffect);
	Template.AddTargetEffect(`RTEB.CreateConcealmentEffect());
	Template.AddTargetEffect(class'X2Effect_Spotted'.static.CreateUnspottedEffect());

	Template.CustomFireAnim = 'NO_CloakingProtocol';

	return Template;
}

static function X2AbilityTemplate RTProgramDroneCloakingProtocolOff() {
	local X2AbilityTemplate Template;
	local X2Effect_RemoveEffects RemoveEffect;
	local X2AbilityMultiTarget_Radius Radius;
	local X2Condition_UnitEffects UnitEffectCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'RTProgramDroneCloakingProtocolOff');

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_defend_panic";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityCosts.AddItem(default.FreeActionCost);

	UnitEffectCondition = new class'X2Condition_UnitEffects';
	UnitEffectCondition.AddRequireEffect(default.CloakingProtocolEffectName, 'AA_UnitIsFlanked');
	Template.AbilityShooterConditions.AddItem(UnitEffectCondition);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	RemoveEffect = new class'X2Effect_RemoveEffects';
	RemoveEffect.EffectNamesToRemove.AddItem(default.CloakingProtocolEffectName);
	RemoveEffect.EffectNamesToRemove.AddItem('CloakingProtocolMobilityMalus');
	Template.AddTargetEffect(RemoveEffect);

	Radius = new class'X2AbilityMultiTarget_Radius';
	Radius.bUseWeaponRadius = false;
	Radius.bIgnoreBlockingCover = true;
	Radius.bExcludeSelfAsTargetIfWithinRadius = true; // for now
	Radius.fTargetRadius = 	default.CLOAKING_PROTOCOL_RADIUS_METERS * class'XComWorldData'.const.WORLD_StepSize * class'XComWorldData'.const.WORLD_UNITS_TO_METERS_MULTIPLIER;
	Template.AbilityMultiTargetStyle = Radius;

	RemoveEffect = new class'X2Effect_RemoveEffects';
	RemoveEffect.EffectNamesToRemove.AddItem(class'RTEffectBuilder'.default.StealthEffectName);
	Template.AddMultiTargetEffect(RemoveEffect);

	//Template.CustomFireAnim = 'NO_CloakingProtocolOff';

	return Template;
}

static function X2AbilityTemplate RTProgramDroneConcealmentHandler() {
	local X2AbilityTemplate Template;
	local X2Condition_UnitEffects UnitEffectCondition;
	local X2AbilityTrigger_EventListener Trigger;

	`CREATE_X2TEMPLATE(class'RTAbilityTemplate', Template, 'RTProgramDroneConcealmentHandler');

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_defend_panic";

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityCosts.AddItem(default.FreeActionCost);

	UnitEffectCondition = new class'X2Condition_UnitEffects';
	UnitEffectCondition.AddRequireEffect(default.CloakingProtocolEffectName, 'AA_UnitIsFlanked');
	Template.AbilityShooterConditions.AddItem(UnitEffectCondition);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventFn = class'RTGameState_Ability'.static.AbilityTriggerEventListener_Self_CloakingProtocolConcealmentHandler;
	Trigger.ListenerData.EventID = 'EffectBreakUnitConcealment';
	Template.AbilityTriggers.AddItem(Trigger);

	Template.AddTargetEffect(new class'X2Effect_BreakUnitConcealment');

	return Template;
}

defaultproperties
{
	CloakingProtocolEffectName = "RTProgramDroneCloakingProtocolAura"
}