class RTProgramFactionTemplate extends X2ResistanceFactionTemplate;

function XComGameState_ResistanceFaction CreateInstanceFromTemplate(XComGameState NewGameState)
{
	local RTGameState_ProgramFaction FactionState;

	FactionState = RTGameState_ProgramFaction(NewGameState.CreateNewStateObject(class'RTGameState_ProgramFaction', self));

	return FactionState;
}
