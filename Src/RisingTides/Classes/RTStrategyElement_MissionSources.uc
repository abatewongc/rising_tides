class RTStrategyElement_MissionSources extends X2StrategyElement_DefaultMissionSources config(ProgramFaction);

var name TemplarAmbushTemplateName;

defaultproperties
{
	TemplarAmbushTemplateName = "RTMissionSource_TemplarAmbush"
}

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> MissionSources;

	MissionSources.AddItem(CreateTemplarAmbushTemplate());

	return MissionSources;
}

static function X2DataTemplate CreateTemplarAmbushTemplate()
{
	local X2MissionSourceTemplate Template;

	`CREATE_X2TEMPLATE(class'X2MissionSourceTemplate', Template, default.TemplarAmbushTemplateName);
	Template.bSkipRewardsRecap = true;
	Template.bCannotBackOutUI = true;
	Template.bCannotBackOutSquadSelect = true;
	Template.CustomLoadingMovieName_Intro = "1080_LoadingScreen_Advent_8.bk2";
	Template.bRequiresSkyRangerTravel = false;
	Template.OnSuccessFn = TemplarAmbushOnSuccess;
	Template.OnFailureFn = TemplarAmbushOnFailure;	
	Template.GetMissionDifficultyFn = GetMissionDifficultyFromQuestlineStage;
	Template.MissionPopupFn = TemplarAmbushPopup;
	Template.WasMissionSuccessfulFn = OneStrategyObjectiveCompleted;

	//BEGIN AUTOGENERATED CODE: Template Overrides 'MissionSource_ChosenAmbush'
	Template.OverworldMeshPath = "UI_3D.Overwold_Final.EscapeAmbush";
	Template.MissionImage = "img:///UILibrary_XPACK_StrategyImages.Mission_ChosenAmbush";
	//END AUTOGENERATED CODE: Template Overrides 'MissionSource_ChosenAmbush'

	return Template;
}

static function TemplarAmbushOnSuccess(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersResistance ResHQ;
		
	// Spawn a POI and save the next time ambushes can occur
	ResHQ = GetAndAddResHQ(NewGameState);
	ResHQ.SaveNextCovertActionAmbushTime();
	ResHQ.UpdateCovertActionNegatedRisks(NewGameState);

	// Flag the ambush as completed
	XComHQ = GetAndAddXComHQ(NewGameState);
	XComHQ.bWaitingForChosenAmbush = false;

	// victory stuff
	GiveRewards(NewGameState, MissionState);
	ResHQ.AttemptSpawnRandomPOI(NewGameState);

	MissionState.RemoveEntity(NewGameState);
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_ChosenAmbushCompleted');
}

static function TemplarAmbushOnFailure(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersResistance ResHQ;

	// Save the next time ambushes can occur
	ResHQ = GetAndAddResHQ(NewGameState);
	ResHQ.SaveNextCovertActionAmbushTime();
	ResHQ.UpdateCovertActionNegatedRisks(NewGameState);

	// Flag the ambush as completed
	XComHQ = GetAndAddXComHQ(NewGameState);
	XComHQ.bWaitingForChosenAmbush = false;

	MissionState.RemoveEntity(NewGameState);
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_ChosenAmbushFailed');
}

static function int GetMissionDifficultyFromQuestlineStage(XComGameState_MissionSite MissionState)
{
	local int Difficulty;

	Difficulty = 1 + `RTS.GetProgramState().iTemplarQuestlineStage;

	Difficulty = Clamp(Difficulty, class'X2StrategyGameRulesetDataStructures'.default.MinMissionDifficulty,
	class'X2StrategyGameRulesetDataStructures'.default.MaxMissionDifficulty);

	return Difficulty;
}

static function TemplarAmbushPopup(optional XComGameState_MissionSite MissionState)
{
	UITemplarAmbushMission(MissionState); // TODO
}


static function UITemplarAmbushMission(XComGameState_MissionSite MissionState, optional bool bInstant = false)
{
	local XComGameState_ResistanceFaction FactionState;
	local DynamicPropertySet PropertySet;
	local name AmbushEvent;

	FactionState = MissionState.GetResistanceFaction();
	AmbushEvent = 'CovertActionAmbush_Central';

	class'X2StrategyGameRulesetDataStructures'.static.BuildDynamicPropertySet(PropertySet, 'RTUIAlert', 'RTAlert_TemplarAmbush', TemplarAmbushAlertCB, true, true, true, false);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'EventToTrigger', AmbushEvent);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'SoundToPlay', "ChosenPopupOpen");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'MissionRef', MissionState.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'FactionRef', FactionState.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicBoolProperty(PropertySet, 'bInstantInterp', bInstant);
	`HQPRES.QueueDynamicPopup(PropertySet);
}

static function Test(optional XComGameState_MissionSite MissionState)
{
	UITest(MissionState);
}


static function UITest(XComGameState_MissionSite MissionState, optional bool bInstant = false)
{
	local XComGameState_ResistanceFaction FactionState;
	local DynamicPropertySet PropertySet;
	local name AmbushEvent;

	FactionState = MissionState.GetResistanceFaction();
	AmbushEvent = 'CovertActionAmbush_Central';

	class'X2StrategyGameRulesetDataStructures'.static.BuildDynamicPropertySet(PropertySet, 'RTUIAlert', 'RTAlert_Test', TemplarAmbushAlertCB, true, true, true, false);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'EventToTrigger', AmbushEvent);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'SoundToPlay', "ChosenPopupOpen");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'MissionRef', MissionState.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'FactionRef', FactionState.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicBoolProperty(PropertySet, 'bInstantInterp', bInstant);
	`HQPRES.QueueDynamicPopup(PropertySet);
}

simulated function TemplarAmbushAlertCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local RTUIMission_TemplarAmbush kScreen;
	local XComHQPresentationLayer HQPres;

	if (eAction == 'eUIAction_Accept')
	{
		HQPres = `HQPRES;
		if (!`ScreenStack.GetCurrentScreen().IsA('RTUIMission_TemplarAmbush'))
		{
			
			kScreen = HQPres.Spawn(class'RTUIMission_TemplarAmbush', HQPres);
			kScreen.MissionRef.ObjectID = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'MissionRef');
			`ScreenStack.Push(kScreen);
		}

		if (`GAME.GetGeoscape().IsScanning())
			HQPres.StrategyMap2D.ToggleScan();
	}
}
