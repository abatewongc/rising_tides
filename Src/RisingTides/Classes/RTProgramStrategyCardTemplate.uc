class RTProgramStrategyCardTemplate extends X2StrategyCardTemplate;

//---------------------------------------------------------------------------------------
function XComGameState_StrategyCard CreateInstanceFromTemplate(XComGameState NewGameState)
{
	local RTGameState_StrategyCard CardState;

	CardState = RTGameState_StrategyCard(NewGameState.CreateNewStateObject(class'RTGameState_StrategyCard', self));


	return CardState;
}