// This is an Unreal Script

class RTHelpers extends Object;

simulated static function EffectAppliedData GetApplyDataForSelfBuff(EffectAppliedData ApplyData, XComGameState_Unit UnitState, XComGameState_Effect EffectState, Name EffectName)
{
	
	//ApplyData.EffectRef.LookupType = TELT_AbilityShooterEffects;
	//ApplyData.EffectRef.TemplateEffectLookupArrayIndex = 0;
	//ApplyData.EffectRef.SourceTemplateName = EffectName;
	//ApplyData.PlayerStateObjectRef = UnitState.ControllingPlayer;
	//ApplyData.SourceStateObjectRef = UnitState.GetReference();
	//ApplyData.TargetStateObjectRef = UnitState.GetReference();
	ApplyData = EffectState.ApplyEffectParameters;

	return ApplyData;
}