//---------------------------------------------------------------------------------------
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameStateContext_EffectAdded extends XComGameStateContext;

var array<StateObjectReference> AddedEffects;

function bool Validate(optional EInterruptionStatus InInterruptionStatus)
{
	return true;
}

function XComGameState ContextBuildGameState()
{
	// this class is not used to build a game state, see XComGameState_Effect for use
	`assert(false);
	return none;
}

protected function ContextBuildVisualization(out array<VisualizationTrack> VisualizationTracks, out array<VisualizationTrackInsertedInfo> VisTrackInsertedInfoArray)
{
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

	History = `XCOMHISTORY;
	
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

function string SummaryString()
{
	return "XComGameStateContext_EffectAdded";
}

function AddEffectAdded(XComGameState_Effect EffectState)
{
	AddedEffects.AddItem(EffectState.GetReference());
}

static function XComGameStateContext_EffectAdded CreateEffectAddedContext(XComGameState_Effect EffectState)
{
	local XComGameStateContext_EffectAdded container;

	container = XComGameStateContext_EffectAdded(CreateXComGameStateContext());
	container.AddedEffects.AddItem(EffectState.GetReference());
	return container;
}

static function XComGameStateContext_EffectAdded CreateEffectsAddedContext(array<XComGameState_Effect> EffectStates)
{
	local XComGameStateContext_EffectAdded container;
	local int i;

	container = XComGameStateContext_EffectAdded(CreateXComGameStateContext());
	for (i = 0; i < EffectStates.Length; ++i)
	{
		container.AddedEffects.AddItem(EffectStates[i].GetReference());
	}
	return container;
}