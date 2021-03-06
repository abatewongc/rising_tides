//---------------------------------------------------------------------------------------
//  FILE:    RTGameState_TimeStopEffect.uc
//  AUTHOR:  Aleosiss
//  DATE:    21 June 2016
//  PURPOSE: Extended GameState_Effect that holds damage taken value for the time stop
//---------------------------------------------------------------------------------------

class RTGameState_TimeStopEffect extends RTGameState_Effect;

var array<WeaponDamageValue> PreventedDamageValues;
var bool bExplosive, bCrit;


simulated function WeaponDamageValue GetFinalDamageValue() {

	local WeaponDamageValue FinalDamageValue, IteratorDamageValue;

	if(PreventedDamageValues.Length == 0) {
		return FinalDamageValue;
	}

	foreach PreventedDamageValues(IteratorDamageValue) {

		FinalDamageValue.Damage += IteratorDamageValue.Damage;
		FinalDamageValue.Pierce += IteratorDamageValue.Pierce;
		FinalDamageValue.Rupture += IteratorDamageValue.Rupture;
		FinalDamageValue.Shred += IteratorDamageValue.Shred;
		FinalDamageValue.Crit += IteratorDamageValue.Crit;

	}

	FinalDamageValue.Tag = 'TimeStopDamageEffect';
	FinalDamageValue.DamageType = PreventedDamageValues[0].DamageType;

	return FinalDamageValue;
}

DefaultProperties
{

}
