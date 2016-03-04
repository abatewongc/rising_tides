//---------------------------------------------------------------------------------------
//  FILE:    RTEffect_PrecisionShotDamage.uc
//  AUTHOR:  Aleosiss
//  DATE:    3 March 2016
//  PURPOSE: Gives Precision Shot its damage boost
//  NOTES: Credit to steam user guby for GetToHitModifiers function         
//---------------------------------------------------------------------------------------
//	Precision Shot damage effect
//---------------------------------------------------------------------------------------
class RTEffect_PrecisionShotDamage extends X2Effect_Persistent config(RTMarksman);

var config float HEADSHOT_CRITDMG_BONUS;
var config int HEADSHOT_CRIT_BONUS;
var config int SQUADSIGHT_CRIT_CHANCE;
var localized string RTFriendlyName;

//CREDIT: user guby on Steam (/u/munchbunny) 
function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ModInfo;
	local XComGameState_Item SourceWeapon;
	local GameRulesCache_VisibilityInfo VisInfo;
	local bool bSquadsight;
	local int crit_bonus;
	
	// Check for squadsight because we will silently cancel the squadsight crit if it's squadsight.
	`TACTICALRULES.VisibilityMgr.GetVisibilityInfo(Attacker.ObjectID, Target.ObjectID, VisInfo);
	if (VisInfo.bClearLOS && !VisInfo.bVisibleGameplay)
		bSquadsight = true;

	SourceWeapon = AbilityState.GetSourceWeapon();
	//Add bonus crit chance if we're shooting a precision shot.	
	if (AbilityState.GetMyTemplateName() == 'PrecisionShot' && SourceWeapon != none)
	{
		ModInfo.ModType = eHit_Crit;
		ModInfo.Reason = RTFriendlyName;
		// If squadsight, apply squadsight compensation.
		if (bSquadsight)
		{
			crit_bonus = HEADSHOT_CRIT_BONUS + SQUADSIGHT_CRIT_CHANCE;
		}
		else
		{
			crit_bonus = HEADSHOT_CRIT_BONUS;
		}

		ModInfo.Value = crit_bonus;
		ShotModifiers.AddItem(ModInfo);
	}
}

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage)
{
	local float ExtraDamage;
	//Check for crit
	if (AppliedData.AbilityResultContext.HitResult == eHit_Crit)
	{
		//Check for precision shot
		if (AbilityState.GetMyTemplateName() == 'PrecisionShot')
		{
			ExtraDamage = CurrentDamage * HEADSHOT_CRITDMG_BONUS;
		}
	}
	return int(ExtraDamage);
}

DefaultProperties
{
	DuplicateResponse = eDupe_Ignore
}