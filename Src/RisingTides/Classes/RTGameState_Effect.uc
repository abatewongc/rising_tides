class RTGameState_Effect extends XComGameState_Effect;

var array<StateObjectReference> EffectsAddedList;
var array<StateObjectReference> EffectsRemovedList;

// OnTacticalGameEnd (Don't need this anymore)
function EventListenerReturn OnTacticalGameEnd(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local X2EventManager EventManager;
	local Object ListenerObj;
    local XComGameState NewGameState;
	
    //`LOG("Rising Tides: 'TacticalGameEnd' event listener delegate invoked.");
	
	EventManager = `XEVENTMGR;

	// Unregister our callbacks
	ListenerObj = self;
	
	EventManager.UnRegisterFromAllEvents(ListenerObj);
	
    NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("RTGameState_Effect states cleanup");
	NewGameState.RemoveStateObject(ObjectID);
	`GAMERULES.SubmitGameState(NewGameState);

	`LOG("RisingTides: RTGameState_Effect of type " @ self.class @" passive effect unregistered from events.");
	
	return ELR_NoInterrupt;
}

// ActivateAbility
protected function ActivateAbility(XComGameState_Ability AbilityState, StateObjectReference TargetRef) {
	local XComGameStateContext_Ability AbilityContext;
	
	if(AbilityState.CanActivateAbilityForObserverEvent(XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetRef.ObjectID))) != 'AA_Success')
		`LOG("Rising Tides: Couldn't Activate "@ AbilityState.GetMyTemplateName() @ " for observer event.");
	
	AbilityContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility(AbilityState, TargetRef.ObjectID);
	
	if( AbilityContext.Validate() ) {
		`TACTICALRULES.SubmitGameStateContext(AbilityContext);
	} else {
		`LOG("Rising Tides: Couldn't validate AbilityContext, " @ AbilityState.GetMyTemplateName() @ " not activated.");
	}
}

// InitializeAbilityForActivation
protected function InitializeAbilityForActivation(out XComGameState_Ability AbilityState, XComGameState_Unit AbilityOwnerUnit, Name AbilityName, XComGameStateHistory History) {
	local StateObjectReference AbilityRef;

	AbilityRef = AbilityOwnerUnit.FindAbility(AbilityName);
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
	if(AbilityState == none) {
		`LOG("Rising Tides: Couldn't initialize ability for activation!");
	}

}

// EffectAddedBuildVisualizationFn
function EffectAddedBuildVisualizationFn (XComGameState VisualizeGameState, out array<VisualizationTrack> VisualizationTracks) {
  local VisualizationTrack SourceTrack;
  local VisualizationTrack TargetTrack;
  local XComGameStateHistory History;
  local X2VisualizerInterface VisualizerInterface;
  local XComGameState_Effect EffectState;
  local XComGameState_BaseObject EffectTarget;
  local XComGameState_BaseObject EffectSource;
  local X2Effect_Persistent EffectTemplate;
  local int i;
  local int n;
  local bool FoundSourceTrack;
  local bool FoundTargetTrack;
  local int SourceTrackIndex;   
  local int TargetTrackIndex;


  local XComGameState AssociatedState;
  local array<StateObjectReference> AddedEffects;


  History = `XCOMHISTORY;

  AddedEffects = EffectsAddedList;
  AssociatedState = VisualizeGameState;

  for (i = 0; i < AddedEffects.Length; ++i)
  {
    EffectState = XComGameState_Effect(History.GetGameStateForObjectID(AddedEffects[i].ObjectID));
    if (EffectState != none)
    {
      EffectSource = History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID);
      EffectTarget = History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID);

      FoundSourceTrack = False;
      FoundTargetTrack = False;
      for (n = 0; n < VisualizationTracks.Length; ++n)
      {
        if (EffectSource.ObjectID == XGUnit(VisualizationTracks[n].TrackActor).ObjectID)
        {
          SourceTrack = VisualizationTracks[n];
          FoundSourceTrack = true;
          SourceTrackIndex = n;
        }

        if (EffectTarget.ObjectID == XGUnit(VisualizationTracks[n].TrackActor).ObjectID)
        {
          TargetTrack = VisualizationTracks[n];
          FoundTargetTrack = true;
          TargetTrackIndex = n;
        }
      }

      if (EffectTarget != none)
      {
        TargetTrack.TrackActor = History.GetVisualizer(EffectTarget.ObjectID);
        VisualizerInterface = X2VisualizerInterface(TargetTrack.TrackActor);
        if (TargetTrack.TrackActor != none)
        {
          History.GetCurrentAndPreviousGameStatesForObjectID(EffectTarget.ObjectID, TargetTrack.StateObject_OldState, TargetTrack.StateObject_NewState, eReturnType_Reference, AssociatedState.HistoryIndex);
          if (TargetTrack.StateObject_NewState == none)
          TargetTrack.StateObject_NewState = TargetTrack.StateObject_OldState;

          if (VisualizerInterface != none)
          VisualizerInterface.BuildAbilityEffectsVisualization(AssociatedState, TargetTrack);

          EffectTemplate = EffectState.GetX2Effect();
          EffectTemplate.AddX2ActionsForVisualization(AssociatedState, TargetTrack, 'AA_Success');
          if (FoundTargetTrack)
          {
            VisualizationTracks[TargetTrackIndex] = TargetTrack;
          }
          else
          {
            TargetTrackIndex = VisualizationTracks.AddItem(TargetTrack);
          }
        }

        if (EffectTarget.ObjectID == EffectSource.ObjectID)
        {
          SourceTrack = TargetTrack;
          FoundSourceTrack = True;
          SourceTrackIndex = TargetTrackIndex;
        }

        SourceTrack.TrackActor = History.GetVisualizer(EffectSource.ObjectID);
        if (SourceTrack.TrackActor != none)
        {
          History.GetCurrentAndPreviousGameStatesForObjectID(EffectSource.ObjectID, SourceTrack.StateObject_OldState, SourceTrack.StateObject_NewState, eReturnType_Reference, AssociatedState.HistoryIndex);
          if (SourceTrack.StateObject_NewState == none)
          SourceTrack.StateObject_NewState = SourceTrack.StateObject_OldState;

          EffectTemplate.AddX2ActionsForVisualizationSource(AssociatedState, SourceTrack, 'AA_Success');
          if (FoundSourceTrack)
          {
            VisualizationTracks[SourceTrackIndex] = SourceTrack;
          }
          else
          {
            SourceTrackIndex = VisualizationTracks.AddItem(SourceTrack);
          }
        }

      }
    }
  }
}

// EffectRemovedBuildVisualizationFn
function EffectRemovedBuildVisualizationFn(XComGameState VisualizeGameState, out array<VisualizationTrack> VisualizationTracks) {
  local VisualizationTrack SourceTrack;
  local VisualizationTrack TargetTrack;
  local XComGameStateHistory History;
  local X2VisualizerInterface VisualizerInterface;
  local XComGameState_Effect EffectState;
  local XComGameState_BaseObject EffectTarget;
  local XComGameState_BaseObject EffectSource;
  local X2Effect_Persistent EffectTemplate;
  local int i;
  local int n;
  local bool FoundSourceTrack;
  local bool FoundTargetTrack;
  local int SourceTrackIndex;
  local int TargetTrackIndex;

  local XComGameState AssociatedState;
  local array<StateObjectReference> RemovedEffects;

  History = `XCOMHISTORY;

  RemovedEffects = EffectsRemovedList;
  AssociatedState = VisualizeGameState;

  for (i = 0; i < RemovedEffects.Length; ++i)
  {
    EffectState = XComGameState_Effect(History.GetGameStateForObjectID(RemovedEffects[i].ObjectID));
    if (EffectState != none)
    {
      EffectSource = History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID);
      EffectTarget = History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID);

      FoundSourceTrack = False;
      FoundTargetTrack = False;
      for (n = 0; n < VisualizationTracks.Length; ++n)
      {
        if (EffectSource.ObjectID == XGUnit(VisualizationTracks[n].TrackActor).ObjectID)
        {
          SourceTrack = VisualizationTracks[n];
          FoundSourceTrack = true;
          SourceTrackIndex = n;
        }

        if (EffectTarget.ObjectID == XGUnit(VisualizationTracks[n].TrackActor).ObjectID)
        {
          TargetTrack = VisualizationTracks[n];
          FoundTargetTrack = true;
          TargetTrackIndex = n;
        }
      }

      if (EffectTarget != none)
      {
        TargetTrack.TrackActor = History.GetVisualizer(EffectTarget.ObjectID);
        VisualizerInterface = X2VisualizerInterface(TargetTrack.TrackActor);
        if (TargetTrack.TrackActor != none)
        {
          History.GetCurrentAndPreviousGameStatesForObjectID(EffectTarget.ObjectID, TargetTrack.StateObject_OldState, TargetTrack.StateObject_NewState, eReturnType_Reference, AssociatedState.HistoryIndex);
          if (TargetTrack.StateObject_NewState == none)
          TargetTrack.StateObject_NewState = TargetTrack.StateObject_OldState;

          if (VisualizerInterface != none)
          VisualizerInterface.BuildAbilityEffectsVisualization(AssociatedState, TargetTrack);

          EffectTemplate = EffectState.GetX2Effect();
          EffectTemplate.AddX2ActionsForVisualization_Removed(AssociatedState, TargetTrack, 'AA_Success', EffectState);
          if (FoundTargetTrack)
          {
            VisualizationTracks[TargetTrackIndex] = TargetTrack;
          }
          else
          {
            TargetTrackIndex = VisualizationTracks.AddItem(TargetTrack);
          }
        }

        if (EffectTarget.ObjectID == EffectSource.ObjectID)
        {
          SourceTrack = TargetTrack;
          FoundSourceTrack = True;
          SourceTrackIndex = TargetTrackIndex;
        }

        SourceTrack.TrackActor = History.GetVisualizer(EffectSource.ObjectID);
        if (SourceTrack.TrackActor != none)
        {
          History.GetCurrentAndPreviousGameStatesForObjectID(EffectSource.ObjectID, SourceTrack.StateObject_OldState, SourceTrack.StateObject_NewState, eReturnType_Reference, AssociatedState.HistoryIndex);
          if (SourceTrack.StateObject_NewState == none)
          SourceTrack.StateObject_NewState = SourceTrack.StateObject_OldState;

          EffectTemplate.AddX2ActionsForVisualization_RemovedSource(AssociatedState, SourceTrack, 'AA_Success', EffectState);
          if (FoundSourceTrack)
          {
            VisualizationTracks[SourceTrackIndex] = SourceTrack;
          }
          else
          {
            SourceTrackIndex = VisualizationTracks.AddItem(SourceTrack);
          }
        }
      }
    }
  }
}

// EffectsModifiedBuildVisualizationFn
function EffectsModifiedBuildVisualizationFn(XComGameState VisualizeGameState, out array<VisualizationTrack> VisualizationTracks) {
  local VisualizationTrack SourceTrack;
  local VisualizationTrack TargetTrack;
  local XComGameStateHistory History;
  local X2VisualizerInterface VisualizerInterface;
  local XComGameState_Effect EffectState;
  local XComGameState_BaseObject EffectTarget;
  local XComGameState_BaseObject EffectSource;
  local X2Effect_Persistent EffectTemplate;
  local int i;
  local int n;
  local bool FoundSourceTrack;
  local bool FoundTargetTrack;
  local int SourceTrackIndex;
  local int TargetTrackIndex;

  local XComGameState AssociatedState;
  local array<StateObjectReference> RemovedEffects;
  local array<StateObjectReference> AddedEffects;

  History = `XCOMHISTORY;

  AddedEffects = EffectsAddedList;
  RemovedEffects = EffectsRemovedList;
  AssociatedState = VisualizeGameState;
  
  // remove the effects...
  for (i = 0; i < RemovedEffects.Length; ++i) {
    EffectState = XComGameState_Effect(History.GetGameStateForObjectID(RemovedEffects[i].ObjectID));
    if (EffectState != none)
    {
      EffectSource = History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID);
      EffectTarget = History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID);

      FoundSourceTrack = False;
      FoundTargetTrack = False;
      for (n = 0; n < VisualizationTracks.Length; ++n)
      {
        if (EffectSource.ObjectID == XGUnit(VisualizationTracks[n].TrackActor).ObjectID)
        {
          SourceTrack = VisualizationTracks[n];
          FoundSourceTrack = true;
          SourceTrackIndex = n;
        }

        if (EffectTarget.ObjectID == XGUnit(VisualizationTracks[n].TrackActor).ObjectID)
        {
          TargetTrack = VisualizationTracks[n];
          FoundTargetTrack = true;
          TargetTrackIndex = n;
        }
      }

      if (EffectTarget != none)
      {
        TargetTrack.TrackActor = History.GetVisualizer(EffectTarget.ObjectID);
        VisualizerInterface = X2VisualizerInterface(TargetTrack.TrackActor);
        if (TargetTrack.TrackActor != none)
        {
          History.GetCurrentAndPreviousGameStatesForObjectID(EffectTarget.ObjectID, TargetTrack.StateObject_OldState, TargetTrack.StateObject_NewState, eReturnType_Reference, AssociatedState.HistoryIndex);
          if (TargetTrack.StateObject_NewState == none)
          TargetTrack.StateObject_NewState = TargetTrack.StateObject_OldState;

          if (VisualizerInterface != none)
          VisualizerInterface.BuildAbilityEffectsVisualization(AssociatedState, TargetTrack);

          EffectTemplate = EffectState.GetX2Effect();
          EffectTemplate.AddX2ActionsForVisualization_Removed(AssociatedState, TargetTrack, 'AA_Success', EffectState);
          if (FoundTargetTrack)
          {
            VisualizationTracks[TargetTrackIndex] = TargetTrack;
          }
          else
          {
            TargetTrackIndex = VisualizationTracks.AddItem(TargetTrack);
          }
        }

        if (EffectTarget.ObjectID == EffectSource.ObjectID)
        {
          SourceTrack = TargetTrack;
          FoundSourceTrack = True;
          SourceTrackIndex = TargetTrackIndex;
        }

        SourceTrack.TrackActor = History.GetVisualizer(EffectSource.ObjectID);
        if (SourceTrack.TrackActor != none)
        {
          History.GetCurrentAndPreviousGameStatesForObjectID(EffectSource.ObjectID, SourceTrack.StateObject_OldState, SourceTrack.StateObject_NewState, eReturnType_Reference, AssociatedState.HistoryIndex);
          if (SourceTrack.StateObject_NewState == none)
          SourceTrack.StateObject_NewState = SourceTrack.StateObject_OldState;

          EffectTemplate.AddX2ActionsForVisualization_RemovedSource(AssociatedState, SourceTrack, 'AA_Success', EffectState);
          if (FoundSourceTrack)
          {
            VisualizationTracks[SourceTrackIndex] = SourceTrack;
          }
          else
          {
            SourceTrackIndex = VisualizationTracks.AddItem(SourceTrack);
          }
        }
      }
    }
  } // end remove effects
  // add new effects...
  for (i = 0; i < AddedEffects.Length; ++i)
  {
    EffectState = XComGameState_Effect(History.GetGameStateForObjectID(AddedEffects[i].ObjectID));
    if (EffectState != none)
    {
      EffectSource = History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID);
      EffectTarget = History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID);

      FoundSourceTrack = False;
      FoundTargetTrack = False;
      for (n = 0; n < VisualizationTracks.Length; ++n)
      {
        if (EffectSource.ObjectID == XGUnit(VisualizationTracks[n].TrackActor).ObjectID)
        {
          SourceTrack = VisualizationTracks[n];
          FoundSourceTrack = true;
          SourceTrackIndex = n;
        }

        if (EffectTarget.ObjectID == XGUnit(VisualizationTracks[n].TrackActor).ObjectID)
        {
          TargetTrack = VisualizationTracks[n];
          FoundTargetTrack = true;
          TargetTrackIndex = n;
        }
      }

      if (EffectTarget != none)
      {
        TargetTrack.TrackActor = History.GetVisualizer(EffectTarget.ObjectID);
        VisualizerInterface = X2VisualizerInterface(TargetTrack.TrackActor);
        if (TargetTrack.TrackActor != none)
        {
          History.GetCurrentAndPreviousGameStatesForObjectID(EffectTarget.ObjectID, TargetTrack.StateObject_OldState, TargetTrack.StateObject_NewState, eReturnType_Reference, AssociatedState.HistoryIndex);
          if (TargetTrack.StateObject_NewState == none)
          TargetTrack.StateObject_NewState = TargetTrack.StateObject_OldState;

          if (VisualizerInterface != none)
          VisualizerInterface.BuildAbilityEffectsVisualization(AssociatedState, TargetTrack);

          EffectTemplate = EffectState.GetX2Effect();
          EffectTemplate.AddX2ActionsForVisualization(AssociatedState, TargetTrack, 'AA_Success');
          if (FoundTargetTrack)
          {
            VisualizationTracks[TargetTrackIndex] = TargetTrack;
          }
          else
          {
            TargetTrackIndex = VisualizationTracks.AddItem(TargetTrack);
          }
        }

        if (EffectTarget.ObjectID == EffectSource.ObjectID)
        {
          SourceTrack = TargetTrack;
          FoundSourceTrack = True;
          SourceTrackIndex = TargetTrackIndex;
        }

        SourceTrack.TrackActor = History.GetVisualizer(EffectSource.ObjectID);
        if (SourceTrack.TrackActor != none)
        {
          History.GetCurrentAndPreviousGameStatesForObjectID(EffectSource.ObjectID, SourceTrack.StateObject_OldState, SourceTrack.StateObject_NewState, eReturnType_Reference, AssociatedState.HistoryIndex);
          if (SourceTrack.StateObject_NewState == none)
          SourceTrack.StateObject_NewState = SourceTrack.StateObject_OldState;

          EffectTemplate.AddX2ActionsForVisualizationSource(AssociatedState, SourceTrack, 'AA_Success');
          if (FoundSourceTrack)
          {
            VisualizationTracks[SourceTrackIndex] = SourceTrack;
          }
          else
          {
            SourceTrackIndex = VisualizationTracks.AddItem(SourceTrack);
          }
        }

      }
    }
  }	// end add effects
   ClearEffectLists();
}

// ClearEffectLists
function ClearEffectLists() {
	EffectsAddedList.Length = 0;
	EffectsRemovedList.Length = 0;
}

// CleanupMobileSquadViewers
function EventListenerReturn CleanupMobileSquadViewers(Object EventData, Object EventSource, XComGameState GameState, Name EventID) {
	local XComGameStateHistory History;
	local RTGameState_SquadViewer ViewerState;
	local XComGameState NewGameState;

	History = `XCOMHISTORY;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("RTGameState_Effect cleaning up OTS SquadViewers!");

	foreach History.IterateByClassType(class'RTGameState_SquadViewer', ViewerState) {
		if(XComGameState_Unit(History.GetGameStateForObjectID(ViewerState.AssociatedUnit.ObjectID)).AffectedByEffectNames.Find(class'RTEffect_TimeStop'.default.EffectName) != INDEX_NONE) {
			ViewerState.bRequiresVisibilityUpdate = true;
			ViewerState.DestroyVisualizer();
		}
	}

	SubmitNewGameState(NewGameState);



	return ELR_NoInterrupt;
}

// OnUpdateAuraCheck
function EventListenerReturn OnUpdateAuraCheck(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local X2Effect_AuraSource AuraTemplate;
	local XComGameState_Unit UpdatedUnitState, AuraSourceUnitState;
	local XComGameStateHistory History;
	local XComGameState_Effect ThisEffect;
	local XComGameState NewGameState;

	UpdatedUnitState = XComGameState_Unit(EventData);
	`assert(UpdatedUnitState != none);

	if (ApplyEffectParameters.TargetStateObjectRef.ObjectID == UpdatedUnitState.ObjectID)
	{
		// If the Target Unit (Owning Unit of the aura) is the same as the Updated unit, then a comprehensive check must be done
		OnTotalAuraCheck(EventData, EventSource, GameState, EventID);
	}
	else
	{
		History = `XCOMHISTORY;
		ThisEffect = self;

		AuraSourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
		`assert(AuraSourceUnitState != none);

		AuraTemplate = X2Effect_AuraSource(GetX2Effect());

		`assert(AuraTemplate != none);

		// Create a new gamestate
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("X2Effect_AuraSource: Affecting Target");

		// The Target Unit different than the Owning Unit of the aura, so only it needs to be checked
		AuraTemplate.UpdateBasedOnAuraTarget(AuraSourceUnitState, UpdatedUnitState, ThisEffect, NewGameState);

		// Submit the new gamestate
		SubmitNewGameState(NewGameState);

	}



	return ELR_NoInterrupt;
}

// OnTotalAuraCheck
function EventListenerReturn OnTotalAuraCheck(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local X2Effect_AuraSource AuraTemplate;
	local XComGameState_Unit TargetUnitState, AuraSourceUnitState;
	local XComGameStateHistory History;
	local XComGameState_Effect ThisEffect;
	local XComGameState NewGameState;

	History = `XCOMHISTORY;

	AuraSourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	`assert(AuraSourceUnitState != none);

	AuraTemplate = X2Effect_AuraSource(GetX2Effect());
	`assert(AuraTemplate != none);

	ThisEffect = self;

	// Create a new gamestate
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("RTEffect_OverTheShoulder: Affecting Target");

	/// All Units must be checked and possibly have the aura effects added or removed
	foreach History.IterateByClassType(class'XComGameState_Unit', TargetUnitState)
	{
		if ((TargetUnitState.ObjectID != AuraSourceUnitState.ObjectID))
		{
			AuraTemplate.UpdateBasedOnAuraTarget(AuraSourceUnitState, TargetUnitState, ThisEffect, NewGameState);
		}
	}

	// Submit the new gamestate
	SubmitNewGameState(NewGameState);

	return ELR_NoInterrupt;
}

// Overkill Damage Recorder (KillMail);
function EventListenerReturn RTOverkillDamageRecorder(Object EventData, Object EventSource, XComGameState GameState, Name EventID) {
    local XComGameState_Unit DeadUnitState, PreviousDeadUnitState, KillerUnitState, NewKillerUnitState;
    local UnitValue LastEffectDamageValue;
    local int iOverKillDamage, i, iHPValue;
    local XComGameStateHistory History;
    local XComGameState NewGameState;
	local XComGameState_BaseObject PreviousObject, CurrentObject;

    History = `XCOMHISTORY;

    DeadUnitState = XComGameState_Unit(EventData);
    KillerUnitState = XComGameState_Unit(EventSource);
    if(DeadUnitState == none || KillerUnitState == none) {
        `RedScreenOnce("Rising Tides: OverkillDamageRecorder received invalid Killer or Dead Unit from KillMail");
        return ELR_NoInterrupt;
    }

    if(KillerUnitState.ObjectID != ApplyEffectParameters.TargetStateObjectRef.ObjectID) {
        // not me! (teehee)
        return ELR_NoInterrupt;
    }

    DeadUnitState.GetUnitValue('LastEffectDamage', LastEffectDamageValue);
    PreviousDeadUnitState = XComGameState_Unit(History.GetPreviousGameStateForObject(DeadUnitState));
	
	while(iHPValue == 0 && i != 20) {
		i++;																													 
		History.GetCurrentAndPreviousGameStatesForObjectID(DeadUnitState.GetReference().ObjectID, PreviousObject, CurrentObject,, GameState.HistoryIndex - i);
		PreviousDeadUnitState = XComGameState_Unit(PreviousObject);
		iHPValue = PreviousDeadUnitState.GetCurrentStat( eStat_HP );
		`LOG("Rising Tides: iHPValue"@iHPValue);
	}

    iOverKillDamage = abs(PreviousDeadUnitState.GetCurrentStat( eStat_HP ) - LastEffectDamageValue.fValue);
	
    NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Rising Tides: Recording Overkill Damage!");
    NewKillerUnitState = XComGameState_Unit(NewGameState.CreateStateObject(KillerUnitState.class, KillerUnitState.ObjectID));
    NewKillerUnitState.SetUnitFloatValue('RTLastOverkillDamage', iOverKillDamage, eCleanup_BeginTactical);
	`LOG("Rising Tides: Logging overkill damage =" @iOverkillDamage);
    NewGameState.AddStateObject(NewKillerUnitState);
    SubmitNewGameState(NewGameState);
	
    return ELR_NoInterrupt;
}

// intended event id = AbilityActivated filter = none
// intended EventData = Ability we're going to try to interrupt
// intended EventSource = Unit we're going to try to interrupt
function EventListenerReturn RTPsionicInterrupt(Object EventData, Object EventSource, XComGameState GameState, Name EventID) {
    local XComGameStateHistory History;
    local XComGameState_Ability AbilityState;
    local XComGameState_Ability InterruptAbilityState;
    local StateObjectReference AbilityRef;
    local XComGameState_Unit TargetUnitState, SourceUnitState;
    local XComGameStateContext AbilityContext;

    AbilityContext = GameState.GetContext();
    if(AbilityContext == none) {
        return ELR_NoInterrupt;
    }

    if (AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt) {
    		return ELR_NoInterrupt;
    }

    History = `XCOMHISTORY;
    AbilityState = XComGameState_Ability(EventData);
    if(AbilityState == none) {
        `LOG("Rising Tides: " @ GetFuncName() @ " has invalid EventData!");
        return ELR_NoInterrupt;
    }

    TargetUnitState = XComGameState_Unit(EventSource);
    if(TargetUnitState == none) {
        `LOG("Rising Tides: " @ GetFuncName() @ " has invalid EventSource!")`
        return ELR_NoInterrupt;
    }

    SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
    if(SourceUnitState == none) {
        `LOG("Rising Tides: " @ GetFuncName() @ " has no SourceUnit?! ");
        return ELR_NoInterrupt;

    }
    if(TargetUnitState.AffectedByEffectNames.Find(class'RTAbility_GathererAbilitySet'.default.OverTheShoulderName) == INDEX_NONE)
        return ELR_NoInterrupt;

    if(class'RTHelpers'.static.CheckAbility(AbilityState.GetMyTemplateName(), eChecklist_PsionicAbilities)) {
        InitializeAbilityForActivation(InterruptAbilityState, SourceUnitState, 'RTRudimentaryCreaturesEvent', History);
        ActivateAbility(InterruptAbilityState, TargetUnitState.GetReference());
        return ELR_InterruptEventAndListeners;
    }

    return ELR_NoInterrupt;
}

// intended event id AbilityActivated filter = unit with Harbinger attached
// intended EventData is the ability we're going to add bonus damage to
// intended EventSource is the unit with Harbinger attached
function EventListenerReturn RTHarbingerBonusDamage(Object EventData, Object EventSource, XComGameState GameState Name EventID) {
    local XComGameStateHistory History;
    local XComGameState_Ability AbilityState, AdditionalDamageState;
    local XComGameState_Unit TargetUnitState, SourceUnitState;
    local XComGameStateContext AbilityContext;

    AbilityContext = GameState.GetContext();
    if(AbilityContext == none) {
        return ELR_NoInterrupt;
    }
    // we want to do the additional damage first, i think
    if(AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt) {
        return ELR_NoInterrupt;
    }

    // don't add bonus damage to an attack that missed...
    if(AbilityContext.ResultContext.HitResult != (eHit_Success | eHit_Crit | eHit_Graze) ) {
        return ELR_NoInterrupt;
    }

    History = `XCOMHISTORY;
    AbilityState = XComGameState_Ability(EventData);
    if(AbilityState == none) {
        `LOG("Rising Tides: " @ GetFuncName() @ " has invalid EventData!");
        return ELR_NoInterrupt;
    }

    SourceUnitState = XComGameState_Unit(EventSource);
    if(SourceUnitState == none) {
        `LOG("Rising Tides: " @ GetFuncName() @ " has invalid EventSource!")`
        return ELR_NoInterrupt;
    }

    TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
    if(TargetUnitState == none) {
        `LOG("Rising Tides: " @ GetFuncName() @ " has no TargetUnit?! ");
        return ELR_NoInterrupt;

    }

    if(class'RTHelpers'.static.CheckAbility(AbilityState.GetMyTemplateName(), eChecklist_SniperShots) ||
       class'RTHelpers'.static.CheckAbility(AbilityState.GetMyTemplateName(), eChecklist_DefaultShots)) {
        InitializeAbilityForActivation(InterruptAbilityState, SourceUnitState, 'RTHarbingerBonusDamage', History);
        ActivateAbility(InterruptAbilityState, TargetUnitState.GetReference());
        return ELR_NoInterrupt;
    }

    return ELR_NoInterrupt;
}



private function SubmitNewGameState(out XComGameState NewGameState)
{
	local X2TacticalGameRuleset TacticalRules;
	local XComGameStateHistory History;

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		TacticalRules = `TACTICALRULES;
		TacticalRules.SubmitGameState(NewGameState);

		//  effects may have changed action availability - if a unit died, took damage, etc.
	}
	else
	{
		History = `XCOMHISTORY;
		History.CleanupPendingGameState(NewGameState);
	}
}


