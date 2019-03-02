// This is an Unreal Script
class RTUIScreenListener_OneSmallFavor extends UIScreenListener config(ProgramFaction);

var UICheckbox 	cb;
var UIMission	ms;
var StateObjectReference mr;
var bool		bDebugging;

var config array<name> FatLaunchButtonMissionTypes;

delegate OldOnClickedDelegate(UIButton Button);

event OnInit(UIScreen Screen)
{
	if(UIMission(Screen) == none) {
		return;
	}
	
	bDebugging = false;

	ms = UIMission(Screen);
	AddOneSmallFavorSelectionCheckBox(UIMission(Screen));
}

event OnRemoved(UIScreen Screen) {
	local UISquadSelect ss;
	local StateObjectReference EmptyRef;

	if(UISquadSelect(Screen) != none) {
		ss = UISquadSelect(Screen);
		// If the mission was launched, we don't want to clean up the XCGS_MissionSite
		if(!ss.bLaunched) {
			RemoveOneSmallFavorSitrep(XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(mr.ObjectID)));
			mr = EmptyRef;
		}
		ManualGC();
	}

	if(UIStrategyMap(Screen) != none) {
		// Just avoiding a RedScreen here, not necessarily a useful check
		if(mr.ObjectID != 0) {
			RemoveOneSmallFavorSitrep(XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(mr.ObjectID)));	
		}

		mr = EmptyRef;
		ManualGC();
	}
}	

simulated function ManualGC() {
	OldOnClickedDelegate = none;
	ms = none;
	cb.Remove();
	cb = none;
}

simulated function AddOneSmallFavorSelectionCheckBox(UIScreen Screen) {
	local UIMission MissionScreen;
	local RTGameState_ProgramFaction Program;

	MissionScreen = UIMission(Screen);
	if(MissionScreen == none) {
		return;
	}
	
	Program = RTGameState_ProgramFaction(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'RTGameState_ProgramFaction'));
	if(Program == none) {
		return;
	}

	if(!Program.bMetXCom) {
		return;
	}

	Program.HandleOSFTutorial();

	// immediately execute the init code if we're somehow late to the initialization party
	if(MissionScreen.ConfirmButton.bIsVisible) {
		if(MissionScreen.ConfirmButton.bIsInited && MissionScreen.ConfirmButton.bIsVisible) {
			OnConfirmButtonInited(MissionScreen.ConfirmButton);
		} else {
			// otherwise add the button to the init delegates
			MissionScreen.ConfirmButton.AddOnInitDelegate(OnConfirmButtonInited);	
		}
	}
	// immediately execute the init code if we're somehow late to the initialization party
	else if(MissionScreen.Button1.bIsVisible) {
		if(MissionScreen.Button1.bIsInited) {
			OnConfirmButtonInited(MissionScreen.Button1);
		} else {
			// otherwise add the button to the init delegates
			MissionScreen.Button1.AddOnInitDelegate(OnConfirmButtonInited);	
		}
	}
	
	else {
		class'RTHelpers'.static.RTLog("Could not find a confirm button for the mission!", true);
	}
}

function OnConfirmButtonInited(UIPanel Panel) {
	local UIMission MissionScreen;
	local bool bReadOnly;
	local RTGameState_ProgramFaction Program;
	local UIButton Button;
	local float PosX, PosY;
	local string strCheckboxDesc;

	MissionScreen = ms;
	if(MissionScreen == none) {
		`RedScreen("Error, parent is not of class 'UIMission'");
		return;
	}

	Program = RTGameState_ProgramFaction(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'RTGameState_ProgramFaction'));
	Button = UIButton(Panel);
	if(Button == none) {
		class'RTHelpers'.static.RTLog("This isn't a button!");
	}

	// the checkbox shouldn't be clickable if the favor isn't available
	bReadOnly = !Program.bOneSmallFavorAvailable;
	if(!bReadOnly) {
		bReadOnly = class'RTHelpers'.static.IsInvalidMission(MissionScreen.GetMission().GetMissionSource());
		if(bReadOnly) {
			class'RTHelpers'.static.RTLog("This MissionSource is invalid!", true);
		}
	}


	if(bReadOnly) {
		strCheckboxDesc = class'RTGameState_ProgramFaction'.default.OSFCheckboxUnavailable;
	} else {
		strCheckboxDesc = class'RTGameState_ProgramFaction'.default.OSFCheckboxAvailable;
	}

	GetPositionByMissionType(MissionScreen.GetMission().GetMissionSource().DataName, PosX, PosY);

	cb = MissionScreen.Spawn(class'UICheckbox', MissionScreen.ButtonGroup);	
	cb.InitCheckbox('OSFActivateCheckbox', , false, , bReadOnly)
		.SetSize(Button.Height, Button.Height)
		.OriginTopLeft()
		.SetPosition(PosX, PosY)
		.SetColor(class'UIUtilities_Colors'.static.ColorToFlashHex(Program.GetMyTemplate().FactionColor))
		.SetTooltipText(strCheckboxDesc, , , 10, , , true, 0.0f);
	class'RTHelpers'.static.RTLog("Created a checkbox at position " $ PosX $ " x and " $ PosY $ " y.");

	// Modify the OnLaunchButtonClicked Delegate
	if(Button != none) {
		OldOnClickedDelegate = Button.OnClickedDelegate;
		Button.OnClickedDelegate = ModifiedLaunchButtonClicked;
	} else {
		class'RTHelpers'.static.RTLog("Panel was not a button?", true);
	}
}

function ModifiedLaunchButtonClicked(UIButton Button) {
	mr = ms.GetMission().GetReference();
	AddOneSmallFavorSitrep(XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(mr.ObjectID)));
	OldOnClickedDelegate(Button);
}

simulated function bool AddOneSmallFavorSitrep(XComGameState_MissionSite MissionState) {
	local RTGameState_ProgramFaction			Program;
	local XComGameState							NewGameState;
	//local GeneratedMissionData					MissionData;
	local XComGameState_HeadquartersXCom		XComHQ; //because the game stores a copy of mission data and this is where its stored in
	local XComGameStateHistory					History;
	//local int									iNumOperativesInSquad;

	History = `XCOMHISTORY;
	Program = RTGameState_ProgramFaction(History.GetSingleGameStateObjectForClass(class'RTGameState_ProgramFaction'));
	if(Program == none) {
		return false;
	}

	if(!bDebugging) {
		if(!Program.bOneSmallFavorAvailable) {
			return false;
		}
	
		if(!cb.bChecked) {
			return false;
		}

		class'RTHelpers'.static.RTLog("Adding One Small Favor SITREP due to it being available and activated!");
	} else { 
		class'RTHelpers'.static.RTLog("Adding One Small Favor SITREP via debug override!"); 
	}


	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if(MissionState.GeneratedMission.SitReps.Find('RTOneSmallFavor') != INDEX_NONE) {
		class'RTHelpers'.static.RTLog("This map already has the One Small Favor tag!", true);
		return false;
	}
	
	if(class'RTHelpers'.static.IsInvalidMission(MissionState.GetMissionSource())) {
		class'RTHelpers'.static.RTLog("This map is invalid!", true);
		return false;
	}

	if(MissionState.TacticalGameplayTags.Find('RTOneSmallFavor') != INDEX_NONE) {
		class'RTHelpers'.static.RTLog("This mission is already tagged for one small favor!");
		return false;
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Rising Tides: Cashing in One Small Favor");
	Program = RTGameState_ProgramFaction(NewGameState.ModifyStateObject(Program.class, Program.ObjectID));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(XComHQ.class, XComHQ.ObjectID));
	MissionState = XComGameState_MissionSite(NewGameState.ModifyStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));

	Program.bOneSmallFavorActivated = true; // we're doing it boys
	MissionState.TacticalGameplayTags.AddItem('RTOneSmallFavor');
	Program.CashOneSmallFavor(NewGameState, MissionState);
	ModifyOneSmallFavorSitrepForGeneratedMission(Program, MissionState, true);

	ModifyMissionData(XComHQ, MissionState);

	if (NewGameState.GetNumGameStateObjects() > 0) {
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		//MissionScreen.UpdateData();
	} else {
		class'RTHelpers'.static.RTLog("Warning: One Small Favor activated but didn't add any objects to the GameState?!", true);
		History.CleanupPendingGameState(NewGameState);
	}

	return true;
}

simulated function bool RemoveOneSmallFavorSitrep(XComGameState_MissionSite MissionState) {
	local RTGameState_ProgramFaction			Program;
	local XComGameState							NewGameState;
	//local GeneratedMissionData					MissionData;
	local XComGameState_HeadquartersXCom		XComHQ; //because the game stores a copy of mission data and this is where its stored in
	local XComGameStateHistory					History;
	//local int									iNumOperativesInSquad;

	History = `XCOMHISTORY;
	Program = RTGameState_ProgramFaction(History.GetSingleGameStateObjectForClass(class'RTGameState_ProgramFaction'));

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if(MissionState.GeneratedMission.SitReps.Find('RTOneSmallFavor') != INDEX_NONE) {
		MissionState.GeneratedMission.SitReps.RemoveItem('RTOneSmallFavor');
	}

	if(MissionState.TacticalGameplayTags.Find('RTOneSmallFavor') != INDEX_NONE) {
		MissionState.TacticalGameplayTags.RemoveItem('RTOneSmallFavor');
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Rising Tides: Uncashing in One Small Favor");
	Program = RTGameState_ProgramFaction(NewGameState.ModifyStateObject(Program.class, Program.ObjectID));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(XComHQ.class, XComHQ.ObjectID));
	MissionState = XComGameState_MissionSite(NewGameState.ModifyStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));
	Program.bOneSmallFavorActivated = false;
	Program.UncashOneSmallFavor(NewGameState, MissionState);
	ModifyOneSmallFavorSitrepForGeneratedMission(Program, MissionState, false);

	ModifyMissionData(XComHQ, MissionState);

	if (NewGameState.GetNumGameStateObjects() > 0) {
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		//MissionScreen.UpdateData();
	} else {
		History.CleanupPendingGameState(NewGameState);
	}

	return true;
}

simulated function ModifyOneSmallFavorSitrepForGeneratedMission(RTGameState_ProgramFaction Program, XComGameState_MissionSite MissionState, bool bAdd = true) {
	if(bAdd) { MissionState.GeneratedMission.SitReps.AddItem(Program.Deployed.GetAssociatedSitRepTemplateName()); }
	else { MissionState.GeneratedMission.SitReps.RemoveItem(Program.Deployed.GetAssociatedSitRepTemplateName()); }
}

//---------------------------------------------------------------------------------------
function ModifyMissionData(XComGameState_HeadquartersXCom NewXComHQ, XComGameState_MissionSite NewMissionState)
{
	local int MissionDataIndex;

	MissionDataIndex = NewXComHQ.arrGeneratedMissionData.Find('MissionID', NewMissionState.GetReference().ObjectID);

	if(MissionDataIndex != INDEX_NONE)
	{
		NewXComHQ.arrGeneratedMissionData[MissionDataIndex] = NewMissionState.GeneratedMission;
	}
}

simulated function PrintUIMissionButtonPositions(UIMission MissionScreen) {
	
}

simulated function GetPositionByMissionType(name MissionSource, out float PosX, out float PosY) {
	// WOTC missions have these really fat launch buttons
	if(default.FatLaunchButtonMissionTypes.Find(MissionSource) != INDEX_NONE) {
		PosX = -192;
		PosY = -30;
		if(MissionSource == 'MissionSource_ChosenStronghold') {
			PosX = -172;
		}
	} else {
		PosX = -98;
		PosY = -18;
	}

	if(MissionSource == 'MissionSource_GuerillaOp') {
		PosX = -198;
		PosY = 125;
	}
}

defaultproperties
{
	// Leaving this assigned to none will cause every screen to trigger its signals on this class
	ScreenClass = none;
}
