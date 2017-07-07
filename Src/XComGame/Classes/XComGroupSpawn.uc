class XComGroupSpawn extends Actor
	  placeable;
	  //hidecategories(Display, Attachment, Collision, Physics, Advanced, Mobile, Debug);

var StaticMeshComponent StaticMesh;
var float Score;

function bool IsLocationInside(const out Vector TestLocation)
{
	local Vector MinPoint;
	local Vector MaxPoint;

	MinPoint = StaticMesh.Bounds.Origin - StaticMesh.Bounds.BoxExtent;
	MaxPoint = StaticMesh.Bounds.Origin + StaticMesh.Bounds.BoxExtent;

	if( TestLocation.X >= MinPoint.X && TestLocation.Y >= MinPoint.Y && TestLocation.Z >= MinPoint.Z &&
		TestLocation.X <= MaxPoint.X && TestLocation.Y <= MaxPoint.Y && TestLocation.Z <= MaxPoint.Z)
	{
		return true;
	}

	return false;
}

function bool IsBoxInside(Vector TestLocation, Vector TestExtents)
{
	local Vector MinPoint, MaxPoint;
	local Vector TestMin, TestMax;

	MinPoint = StaticMesh.Bounds.Origin - StaticMesh.Bounds.BoxExtent;
	MaxPoint = StaticMesh.Bounds.Origin + StaticMesh.Bounds.BoxExtent;

	TestMin = TestLocation;
	TestMax = TestLocation + TestExtents;

	if ((TestMin.X > MaxPoint.X) || (TestMax.X < MinPoint.X))
	{
		return false;
	}
	if ((TestMin.Y > MaxPoint.Y) || (TestMax.Y < MinPoint.Y))
	{
		return false;
	}
	if ((TestMin.Z > MaxPoint.Z) || (TestMax.Z < MinPoint.Z))
	{
		return false;
	}

	return true;
}

// gets all the floor locations that this group spawn encompasses
//LWS : Modified with hook to allow DLC/Mods to alter the floor points
function GetValidFloorLocations(out array<Vector> FloorPoints)
{
	local array<X2DownloadableContentInfo> DLCInfos;
	local int i;

	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	for(i = 0; i < DLCInfos.Length; ++i)
	{
		if(DLCInfos[i].GetValidFloorSpawnLocations(FloorPoints, self))
		{
			return; 
		}
	}

	`XWORLD.GetFloorTilePositions(Location, 96 * 2, 64 * 2, FloorPoints, true);
}

// gets all the floor TILES that this group spawn encompasses, within the provided dimensions
function GetValidFloorTilesForMP(out array<TTile> FloorTiles, int iWidth, int iHeight)
{
	local TTile RootTile;

	RootTile = GetTile();

	`XWORLD.GetSpawnTilePossibilities(RootTile, iWidth, iHeight, 1, FloorTiles);
}

function TTile GetTile()
{
	return `XWORLD.GetTileCoordinatesFromPosition(Location);
}

function bool HasValidFloorLocations()
{
	local XComTacticalMissionManager MissionManager;
	local array<Vector> FloorPoints;
	local int NumSoldiers;

	GetValidFloorLocations(FloorPoints);

	MissionManager = `TACTICALMISSIONMGR;
	if(`XCOMHQ != none)
		NumSoldiers = `XCOMHQ.Squad.Length;
	else
		NumSoldiers = class'X2StrategyGameRulesetDataStructures'.static.GetMaxSoldiersAllowedOnMission(MissionManager.ActiveMission);

	// For TQL, etc, where the soldier are coming from the Start State, always reserve space for six soldiers
    if (NumSoldiers == 0)
        NumSoldiers = 6;

	return FloorPoints.Length > NumSoldiers;
}

defaultproperties
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bEnabled=true     // precomputed lighting is used until the static mesh is changed
		bCastShadows=false // there will be a static shadow so no need to cast a dynamic shadow
		bSynthesizeSHLight=false
		bSynthesizeDirectionalLight=true; // get rid of this later if we can
		bDynamic=true     // using a static light environment to save update time
		bForceNonCompositeDynamicLights=TRUE // needed since we are using a static light environment
		bUseBooleanEnvironmentShadowing=FALSE
		TickGroup=TG_DuringAsyncWork
	End Object

	Begin Object Class=StaticMeshComponent Name=ExitStaticMeshComponent
		HiddenGame=True
		StaticMesh=StaticMesh'Parcel.Meshes.Parcel_Extraction_3x3'
		bUsePrecomputedShadows=FALSE //Bake Static Lights, Zel
		LightingChannels=(BSP=FALSE,Static=TRUE,Dynamic=TRUE,CompositeDynamic=TRUE,bInitialized=TRUE)//Bake Static Lights, Zel
		WireframeColor=(R=255,G=0,B=255,A=255)
		LightEnvironment=MyLightEnvironment
	End Object
	Components.Add(ExitStaticMeshComponent)
	StaticMesh = ExitStaticMeshComponent;

	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'LayerIcons.Editor.group_spawn'
		HiddenGame=True
		Translation=(X=0,Y=0,Z=64)
	End Object
	Components.Add(Sprite);

	bEdShouldSnap=true

	// half size the sprite but scale the mesh back up so it's normal size
	DrawScale3D=(X=2.0,Y=2.0,Z=2.0)
	DrawScale=0.5

	Layer=Markup
}