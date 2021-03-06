class RTTargetingMethod_TargetedMeleeTeleport extends X2TargetingMethod;

var private RTMeleePathingPawn			PathingPawn;
var private XComActionIconManager		IconManager;
var private XComLevelBorderManager		LevelBorderManager;
var private XCom3DCursor				Cursor;
var private X2Camera_Midpoint			TargetingCamera; // deprecated
var private XGUnit						TargetUnit;
var private X2Camera_LookAtActorTimed	LookAtCamera; // deprecated

// the index of the last available target we were targeting
var private int LastTarget;

function Init(AvailableAction InAction, int NewTargetIndex)
{
	local XComPresentationLayer Pres;

	super.Init(InAction, NewTargetIndex);

	Pres = `PRES;

	Cursor = `CURSOR;
	PathingPawn = Cursor.Spawn(class'RTMeleePathingPawn', Cursor);
	PathingPawn.HideRenderablePath(true);
	PathingPawn.SetVisible(true);
	PathingPawn.HideRenderablePath(true);
	PathingPawn.Init(UnitState, Ability, new class'X2TargetingMethod_MeleePath');
	IconManager = Pres.GetActionIconMgr();
	LevelBorderManager = Pres.GetLevelBorderMgr();

	// force the initial updates
	IconManager.ShowIcons(true);
	LevelBorderManager.ShowBorder(true);
	IconManager.UpdateCursorLocation(true);
	LevelBorderManager.UpdateCursorLocation(Cursor.Location, true);

	DirectSelectNearestTarget();
}

private function DirectSelectNearestTarget()
{
	local XComGameStateHistory History;
	local XComWorldData WorldData;
	local Vector SourceUnitLocation;
	local X2GameRulesetVisibilityInterface Target;
	local TTile TargetTile;

	local int TargetIndex;
	local float TargetDistanceSquared;
	local int ClosestTargetIndex;
	local float ClosestTargetDistanceSquared;

	if(Action.AvailableTargets.Length == 1)
	{
		// easy case. If only one target, they are the closest
		DirectSetTarget(0);
	}
	else
	{
		// iterate over each target in the target list and select the closest one to the source
		ClosestTargetIndex = -1;

		History = `XCOMHISTORY;
		WorldData = `XWORLD;

		SourceUnitLocation = WorldData.GetPositionFromTileCoordinates(UnitState.TileLocation);

		for (TargetIndex = 0; TargetIndex < Action.AvailableTargets.Length; TargetIndex++)
		{
			Target = X2GameRulesetVisibilityInterface(History.GetGameStateForObjectID(Action.AvailableTargets[TargetIndex].PrimaryTarget.ObjectID));
			`assert(Target != none);

			Target.GetKeystoneVisibilityLocation(TargetTile);
			TargetDistanceSquared = VSizeSq(WorldData.GetPositionFromTileCoordinates(TargetTile) - SourceUnitLocation);

			if(ClosestTargetIndex < 0 || TargetDistanceSquared < ClosestTargetDistanceSquared)
			{
				ClosestTargetIndex = TargetIndex;
				ClosestTargetDistanceSquared = TargetDistanceSquared;
			}
		}

		// we have a closest target now, so select it
		DirectSetTarget(ClosestTargetIndex);
	}
}

function Canceled()
{
	super.Canceled();
	PathingPawn.Destroy();
	IconManager.ShowIcons(false);
	LevelBorderManager.ShowBorder(false);
	ClearTargetedActors();

	if(LookAtCamera != none && LookAtCamera.LookAtDuration < 0)
	{
		`CAMERASTACK.RemoveCamera(LookAtCamera);
	}
}

function Committed()
{
	Canceled();
}

function bool AllowMouseConfirm()
{
	return true;
}

function Update(float DeltaTime)
{
	IconManager.UpdateCursorLocation();
	LevelBorderManager.UpdateCursorLocation(Cursor.Location);
	PathingPawn.HideRenderablePath(true);
}

function NextTarget()
{
	DirectSetTarget(LastTarget + 1);
}

function PrevTarget()
{
	DirectSetTarget(LastTarget - 1);
}

function DirectSetTarget(int TargetIndex)
{
	local XComPresentationLayer Pres;
	local UITacticalHUD TacticalHud;
	local XComGameStateHistory History;
	local XComGameState_BaseObject Target;
	local int NewTarget;
	local array<TTile> Tiles;

	// put the targeting reticle on the new target
	Pres = `PRES;
	TacticalHud = Pres.GetTacticalHUD();

	// advance the target counter
	NewTarget = TargetIndex % Action.AvailableTargets.Length;
	if(NewTarget < 0) NewTarget = Action.AvailableTargets.Length + NewTarget;

	LastTarget = NewTarget;
	TacticalHud.TargetEnemy(Action.AvailableTargets[NewTarget].PrimaryTarget.ObjectID);

	// have the idle state machine look at the new target
	FiringUnit.IdleStateMachine.CheckForStanceUpdate();

	// have the pathing pawn draw a path to the target
	History = `XCOMHISTORY;
	Target = History.GetGameStateForObjectID(Action.AvailableTargets[LastTarget].PrimaryTarget.ObjectID);
	PathingPawn.HideRenderablePath(true);
	PathingPawn.UpdateMeleeTarget(Target);

	Tiles = PathingPawn.GetPossibleTiles();
	class'RTAbilityTarget_TeleportMelee'.static.SelectAttackTile(PathingPawn.GetUnitState(), Target, PathingPawn.GetAbilityTemplate(), Tiles);
	ClearTargetedActors();
	DrawAOETiles(Tiles);
	PathingPawn.HideRenderablePath(true);

	TargetUnit = XGUnit(Target.GetVisualizer());

	if(LookAtCamera != none)
	{
		`CAMERASTACK.RemoveCamera(LookAtCamera);
	}

	LookAtCamera = new class'X2Camera_LookAtActorTimed';
	LookAtCamera.LookAtDuration = `ISCONTROLLERACTIVE ? -1.0f : 0.0f;
	LookAtCamera.ActorToFollow = TargetUnit != none ? TargetUnit.GetPawn() : Target.GetVisualizer();
	`CAMERASTACK.AddCamera(LookAtCamera);
}

function int GetTargetIndex()
{
	return LastTarget;
}

function bool GetPreAbilityPath(out array<TTile> PathTiles)
{
	PathingPawn.GetTargetMeleePath(PathTiles);
	return PathTiles.Length > 0;
}

function bool GetCurrentTargetFocus(out Vector Focus)
{
	local StateObjectReference Shooter;

	if( TargetUnit != None )
	{
		Shooter.ObjectID = TargetUnit.ObjectID;
		Focus = TargetUnit.GetShootAtLocation(eHit_Success, Shooter);
		return true;
	}

	return false;
}

defaultproperties
{
	ProvidesPath = false
}
