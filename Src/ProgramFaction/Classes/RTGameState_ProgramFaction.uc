class RTGameState_ProgramFaction extends XComGameState_ResistanceFaction config(ProgramFaction);

// a lot of the DeathRecordData code is from Xyl's Anatomist Perk. Thanks to him!

/* *********************************************************************** */

/* BEGIN KILL RECORD */

// each type of unit has an RTDeathRecord
// in this DeathRecord, there is an individual killcount array that lists all the units
// that have ever killed this one, and how many they'd defeated.
// the NumDeaths variable in the DeathRecord is the sum of all of the IndividualKillCounts.KillCount values.
// Additionally, whenever a critical hit is landed, it increments the NumCrits value.

// required methods:
// void UpdateDeathRecordData(name CharacterTemplateName, StateObjectReference UnitRef, bool bWasCrit)
// RTDeathRecord GetDeathRecord(name CharacterTemplateName)
// RTKillCount GetKillCount(StateObjectReference UnitRef, name CharacterTemplateName)

struct RTKillCount
{
	var StateObjectReference      UnitRef;				// The owner of this kill count
	var int                       KillCount;			// the number of kills
};

struct RTDeathRecord
{
	var name                      CharacterTemplateName;	// the type of unit that died
	var int                       NumDeaths;              	// number of times the unit has been killed by a friendly unit
	var int                       NumCrits;               	// number of times the unit has been critically hit
	var array<RTKillCount>        IndividualKillCounts;   	// per-unit kill counts ( worth more to VitalPointTargeting than other kills ); the sum of these should always equal NumDeaths
};

var() array<RTDeathRecord> DeathRecordData;					// Program Datavault contianing information on every kill made by deployed actor

/* END KILL RECORD   */

/* *********************************************************************** */

/* *********************************************************************** */

/* BEGIN OPERATIVE RECORD */

struct RTGhostOperative
{
	var name 						SoldierClassTemplateName;
	var name						CharacterTemplateName;
	var array<name>					WeaponUpgrades;

	var StateObjectReference 		StateObjectRef;

	var string						ExternalID;
	var localized string			FirstName;
	var localized string			NickName;
	var localized string			LastName;
	var localized string			preBackground;
	var localized string			finBackGround;
};

var localized string SquadOneName;
var localized string SquadOneBackground;


struct Squad
{

};

var const config array<RTGhostOperative>	GhostTemplates;

var() array<RTGhostOperative>									Master; 			// master list of operatives
var() array<StateObjectReference> 								Active;				// ghosts active
var() RTGameState_PersistentGhostSquad							Deployed; 			// ghosts that will be on the next mission
var() array<StateObjectReference>								Captured;			// ghosts not available
var() array<RTGameState_PersistentGhostSquad>					Squads;				// list of ghost teams (only one for now)
var() int 														iOperativeLevel;	// all ghosts get level ups after a mission, even if they weren't on it. lorewise, they're constantly running missions; the player only sees a fraction of them
var bool														bSetupComplete;		// if we should rebuild the ghost array from config

/* END OPERATIVE RECORD   */


// FACTION VARIABLES
var bool														bOneSmallFavorAvailable;	// can send squad on a mission, replacing XCOM	
var bool														bTemplarsDestroyed;														


/* *********************************************************************** */

// SetUpRisingTidesCommand(XComGameState StartState)
static function SetUpRisingTidesCommand(XComGameState StartState)
{
	local RTGameState_RisingTidesCommand RTCom;

	foreach StartState.IterateByClassType(class'RTGameState_RisingTidesCommand', RTCom) {
		break;
	}

	if (RTCom == none) {
		RTCom = RTGameState_RisingTidesCommand(StartState.CreateStateObject(class'RTGameState_RisingTidesCommand'));
	}

	StartState.AddStateObject(RTCom);
	RTCom.InitListeners();
	if(!RTCom.bSetupComplete) {
		RTCom.CreateRTOperatives(StartState);
		//RTCom.CreateRTDeathRecord(StartState);
	}
}

// CreateRTOperatives(XComGameState NewGameState)
function CreateRTOperatives(XComGameState StartState) {
	local RTGhostOperative IteratorGhostTemplate;


	foreach default.GhostTemplates(IteratorGhostTemplate) {
		CreateRTOperative(IteratorGhostTemplate, StartState);

	}
}

function CreateRTOperative(RTGhostOperative IteratorGhostTemplate, XComGameState StartState) {
	local XComGameState_Unit UnitState;
	local X2ItemTemplateManager ItemTemplateMgr;
	local X2CharacterTemplateManager CharMgr;
	local X2CharacterTemplate CharTemplate;
	local XComGameState_Item WeaponState;
	local X2WeaponUpgradeTemplate UpgradeTemplate;
	local name WeaponUpgradeName;
	local RTGhostOperative Ghost;

	CharMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	ItemTemplateMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	CharTemplate = CharMgr.FindCharacterTemplate(IteratorGhostTemplate.CharacterTemplateName);
	CharTemplate.bIsPsionic = true;

	UnitState = CharTemplate.CreateInstanceFromTemplate(StartState);
	StartState.AddStateObject(UnitState);

	UnitState.SetCharacterName(IteratorGhostTemplate.FirstName, IteratorGhostTemplate.LastName, IteratorGhostTemplate.NickName);
	UnitState.SetCountry(CharTemplate.DefaultAppearance.nmFlag);
	UnitState.RankUpSoldier(StartState, IteratorGhostTemplate.SoldierClassTemplateName);
	UnitState.ApplyInventoryLoadout(StartState, CharTemplate.DefaultLoadout);
	UnitState.StartingRank = 1;
	UnitState.SetXPForRank(1);
	UnitState.SetBackground(IteratorGhostTemplate.preBackground);

	WeaponState = UnitState.GetPrimaryWeapon();
	foreach IteratorGhostTemplate.WeaponUpgrades(WeaponUpgradeName) {
		UpgradeTemplate = X2WeaponUpgradeTemplate(ItemTemplateMgr.FindItemTemplate(WeaponUpgradeName));
		if (UpgradeTemplate != none) {
			WeaponState.ApplyWeaponUpgradeTemplate(UpgradeTemplate);
		}
	}

	Ghost = IteratorGhostTemplate;
	Ghost.StateObjectRef = UnitState.GetReference();

	Active.AddItem(UnitState.GetReference());
	Master.AddItem(Ghost);
}



function CreateRTSquads(XComGameState StartState) {

	local RTGameState_PersistentGhostSquad one;
	local RTGhostOperative Ghost;

	one = RTGameState_PersistentGhostSquad(StartState.CreateStateObject(class'RTGameState_PersistentGhostSquad'));
	one.CreateSquad(1, default.SquadOneName, default.SquadOneBackground);
	StartState.AddStateObject(one);
	Squads.AddItem(one);

	foreach Master(Ghost) {
		// team 1 "SPECTRE"
		if(Ghost.ExternalID == "Queen" || Ghost.ExternalID == "Whisper" || Ghost.ExternalID == "Nova") {
			one.Operatives.AddItem(Ghost.StateObjectRef);
			one.initOperatives.AddItem(Ghost.StateObjectRef);
		}
	}


}

// UpdateNumDeaths(name CharacterTemplateName, StateObjectReference UnitRef)
simulated function UpdateNumDeaths(name CharacterTemplateName, StateObjectReference UnitRef) {
	local RTDeathRecord 	IteratorDeathRecord, NewDeathRecord;
	local RTKillCount		IteratorKillCount, NewKillCount;
	local bool				bFoundDeathRecord, bFoundKillCount;

	foreach DeathRecordData(IteratorDeathRecord) {
		if(IteratorDeathRecord.CharacterTemplateName != CharacterTemplateName) {
			continue;
		}

		bFoundDeathRecord = true;
		IteratorDeathRecord.NumDeaths++;

		foreach IteratorDeathRecord.IndividualKillCounts(IteratorKillCount) {
			if(IteratorKillCount.UnitRef.ObjectID == UnitRef.ObjectID) {
				bFoundKillCount = true;
				IteratorKillCount.KillCount++;
			}
		}

		if(!bFoundKillCount) {
			NewKillCount.UnitRef = UnitRef;
			NewKillCount.KillCount = 1;
			IteratorDeathRecord.IndividualKillCounts.AddItem(NewKillCount);
		}

	}

	// new character. make a new death record and increment the number of deaths.
	// also, create a new kill count and increment the number of kills.
	if(!bFoundDeathRecord) {
		NewDeathRecord.CharacterTemplateName = CharacterTemplateName;
		NewDeathRecord.NumDeaths = 1;

		NewKillCount.UnitRef = UnitRef;
		NewKillCount.KillCount = 1;
		NewDeathRecord.IndividualKillCounts.AddItem(NewKillCount);
		DeathRecordData.AddItem(NewDeathRecord);
	}
}

// UpdateNumCrits(name CharacterTemplateName)
simulated function UpdateNumCrits(name CharacterTemplateName) {
	local RTDeathRecord 	IteratorDeathRecord, NewDeathRecord;
	local bool				bFoundDeathRecord;

	foreach DeathRecordData(IteratorDeathRecord) {
		if(IteratorDeathRecord.CharacterTemplateName != CharacterTemplateName) {
			continue;
		}

		bFoundDeathRecord = true;
		IteratorDeathRecord.NumCrits++;
	}

	// new character. make a new death record and increment the number of crits.
	if(!bFoundDeathRecord) {
		NewDeathRecord.CharacterTemplateName = CharacterTemplateName;
		NewDeathRecord.NumCrits = 1;
		DeathRecordData.AddItem(NewDeathRecord);
	}

}

// Creates the killtracker object if it doesn't exist
// RTGameState_RisingTidesCommand GetRTCommand()
static function RTGameState_RisingTidesCommand GetRTCommand() {
	local XComGameStateHistory History;
	local RTGameState_RisingTidesCommand RTCom;


	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'RTGameState_RisingTidesCommand', RTCom)
	{
		break;
	}

	if (RTCom != none) {
		return RTCom;
	} else {
		`RedScreen("RTCom does not exist! Returning null!");
		return none;
	}
}

// RefreshListeners()
static function RefreshListeners() {
	local RTGameState_RisingTidesCommand RTCom;

	RTCom = GetRTCommand();
	RTCom.InitListeners();
}

// InitListeners()
function InitListeners() {
	local X2EventManager EventMgr;
	local Object ThisObj;

	ThisObj = self;
	EventMgr = `XEVENTMGR;
	EventMgr.UnregisterFromAllEvents(ThisObj); // clear all old listeners to clear out old stuff before re-registering

	EventMgr.RegisterForEvent(ThisObj, 'KillMail', OnKillMail, ELD_OnStateSubmitted,,,);
	EventMgr.RegisterForEvent(ThisObj, 'UnitAttacked', OnUnitAttacked, ELD_OnStateSubmitted,,,);
}

// EventData = DeadUnitState
// EventSource = KillerUnitState
function EventListenerReturn OnKillMail(Object EventData, Object EventSource, XComGameState GameState, Name InEventID, Object CallbackData) {
	local XComGameState_Unit KillerUnitState, DeadUnitState;
	local RTGameState_RisingTidesCommand RTCom;
	local XComGameState NewGameState;

	// `Log("OnKillMail: EventData =" @ EventData);
	// EventData is the unit who died
	// `Log("OnKillMail: EventSource =" @ EventSource);
	// EventSource is the unit that killed
	KillerUnitState = XComGameState_Unit(EventSource);
	if (KillerUnitState == none)
		return ELR_NoInterrupt;

	DeadUnitState = XComGameState_Unit(EventData);
	if (DeadUnitState == none)
		return ELR_NoInterrupt;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Rising Tides: UpdateDeathRecordData");
	RTCom = RTGameState_RisingTidesCommand(NewGameState.CreateStateObject(class'RTGameState_RisingTidesCommand', self.ObjectID));
	NewGameState.AddStateObject(RTCom);
	RTCom.UpdateNumDeaths(DeadUnitState.GetMyTemplate().CharacterGroupName, KillerUnitState.GetReference());
	`GAMERULES.SubmitGameState(NewGameState);

	return ELR_NoInterrupt;
}
// EventID = AbilityActivated
// EventData = AbilityState
// EventSource = UnitWhoUsedAbilityStateState
// or...
// EventID = UnitAttacked
// EventData = UnitState
// EventSource = UnitState
function EventListenerReturn OnUnitAttacked(Object EventData, Object EventSource, XComGameState GameState, Name InEventID, Object CallbackData) {
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit AttackedUnitState;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if(AbilityContext == none) {
		return ELR_NoInterrupt;
	}

	AttackedUnitState = XComGameState_Unit(EventData);
	if(AttackedUnitState == none) {
		AttackedUnitState = XComGameState_Unit(EventSource);
		if(AttackedUnitState == none) {
			return ELR_NoInterrupt;
		}
	}

	if(AbilityContext.ResultContext.HitResult == eHit_Crit) {
		UpdateNumCrits(AttackedUnitState.GetMyTemplate().CharacterGroupName);
	}

	return ELR_NoInterrupt;
}
/*
function OnEndTacticalPlay(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_HeadquartersXCom XComHQ, NewXComHQ;
	local XComGameState_MissionSite MissionState;

	local RTGameState_RisingTidesCommand 	RTCom, NewRTCom;


	super.OnEndTacticalPlay(NewGameState);
	History = class'XComGameStateHistory'.static.GetGameStateHistory();

	RTCom	= RTGameState_RisingTidesCommand(History.GetSingleGameStateObjectForClass(class'RTGameState_RisingTidesCommand'));
	NewRTCom = RTGameState_RisingTidesCommand(NewGameState.ModifyStateObject(class'RTGameState_RisingTidesCommand', RTCom.GetReference().ObjectID));
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NewXComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.GetReference().ObjectID));
	
	MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState) {
		if(Master.Find('NickName', UnitState.GetNickName()) != INDEX_NONE) {
			Deployed.RemoveItem(UnitState.GetReference());
			if(UnitState.bCaptured) {
				Captured.AddItem(UnitState.GetReference());
			} else {
				Active.AddItem(UnitState.GetReference());
			}
		}
	}
}*/




// Faction Stuff

//#############################################################################################
//----------------   FACTION SOLDIERS ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function int GetNumFactionSoldiers(optional XComGameState NewGameState)
{
	return Master.Length;
}

//---------------------------------------------------------------------------------------
function bool IsFactionSoldierRewardAllowed(XComGameState NewGameState)
{
	// The Program doesn't give out Faction Soldier rewards
	return false;
}

//---------------------------------------------------------------------------------------
function bool IsExtraFactionSoldierRewardAllowed(XComGameState NewGameState)
{
	// The Program doesn't give out Faction Soldier rewards
	return false;
}

private function AddRisingTidesTacticalTags(XComGameState_HeadquartersXCom XComHQ) // mark missions as being invalid for One Small Favor or Just Passing Through, usually story, (golden path or otherwise)
{
	
}

simulated function bool CashOneSmallFavor(XComGameState NewGameState, XComGameState_MissionSite MissionSite) {
	local StateObjectReference GhostRef, EmptyRef;
	local name GhostTemplateName;

	if(!bOneSmallFavorAvailable)
		return false;

	RotateRandomSquadToDeploy();
	if(Deployed == none) {
		return false;
	}

	MissionSite = XComGameState_MissionSite(NewGameState.ModifyStateObject(MissionSite.class, MissionSite.ObjectID));	
	foreach Deployed.Operatives(GhostRef) {
		GhostTemplateName = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GhostRef.ObjectID)).GetMyTemplateName();
		MissionSite.GeneratedMission.Mission.SpecialSoldiers.AddItem(GhostTemplateName);
	}

	return true;
}

protected function RotateRandomSquadToDeploy() {
	if(Squads.Length == 0)
		return;
	Deployed = Squads[`SYNC_RAND(Squads.Length)];
}