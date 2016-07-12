class RTEffect_TimeStopMaster extends X2Effect_PersistentStatChange;

var bool bWasPreviouslyTrue;


simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	  
	  // Could you, Madoka? Could you see me in my stopped time?
	  // Uh, no...
	  // Oh.
	  AddPersistentStatChange(eStat_DetectionModifier, 1);


}

simulated function bool OnEffectTicked(const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication)
{
	local XComGameState_AIReinforcementSpawner OldSpawnerState, NewSpawnerState;
	local XComGameState_UITimer UiTimer, OldUiTimer;
  	
	OldUiTimer = XComGameState_UITimer(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_UITimer', true));
	UiTimer = XComGameState_UITimer(NewGameState.CreateStateObject(class 'XComGameState_UITimer', OldUiTimer.ObjectID));

	UiTimer.UiState = OldUiTimer.UIState;
	UiTimer.ShouldShow = OldUiTimer.ShouldShow;
	UiTimer.DisplayMsgTitle = OldUiTimer.DisplayMsgTitle;
	UiTimer.DisplayMsgSubtitle = OldUiTimer.DisplayMsgSubtitle;
	UiTimer.TimerValue = OldUiTimer.TimerValue + 1;
	
	NewGameState.AddStateObject(UiTimer);


	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_AIReinforcementSpawner', OldSpawnerState) {
		NewSpawnerState = XComGameState_AIReinforcementSpawner(NewGameState.CreateStateObject(class'XComGameState_AIReinforcementSpawner', OldSpawnerState.ObjectID));
		NewSpawnerState.Countdown = OldSpawnerState.Countdown + 1;
		NewGameState.AddStateObject(NewSpawnerState);
	}							
  return false;
}
