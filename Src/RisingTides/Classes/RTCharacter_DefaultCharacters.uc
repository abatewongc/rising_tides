class RTCharacter_DefaultCharacters extends X2Character_DefaultCharacters config(RisingTides);

static function array<X2DataTemplate> CreateTemplates()
{
    local array<X2DataTemplate> Templates;
    
    Templates.AddItem(CreateWhisperTemplate());
    Templates.AddItem(CreateQueenTemplate());
    Templates.AddItem(CreateNovaTemplate());

	return Templates;
}


static function X2CharacterTemplate CreateWhisperTemplate()
{
	local X2CharacterTemplate CharTemplate;

	CharTemplate = CreateSoldierTemplate('RTGhostMarksman');
	
	CharTemplate.DefaultSoldierClass = 'RT_Marksman';
	CharTemplate.DefaultLoadout = 'RT_Marksman';
    CharTemplate.bIsPsionic = true;

    CharTemplate.bForceAppearance = true;
	CharTemplate.bAppearanceDefinesPawn = true;

    CharTemplate.ForceAppearance.nmPawn = 'XCom_Soldier_M';
    CharTemplate.ForceAppearance.nmHead = 'Central';
    CharTemplate.ForceAppearance.nmHaircut = 'Central_Hair';
    CharTemplate.ForceAppearance.nmBeard = 'Central_Beard';
    CharTemplate.ForceAppearance.iArmorTint = 0;
    CharTemplate.ForceAppearance.iArmorTintSecondary = 2;
    CharTemplate.ForceAppearance.iGender = 1;
    CharTemplate.ForceAppearance.nmArms = 'CnvMed_std_B_M';
    CharTemplate.ForceAppearance.nmArms_Underlay = 'CnvUnderlay_Std_Arms_A_M';
    CharTemplate.ForceAppearance.nmEye = 'DefaultEyes_2';
    CharTemplate.ForceAppearance.nmFacePropLower = 'Prop_FaceLower_Blank';
    CharTemplate.ForceAppearance.nmFacePropUpper = 'Prop_FaceUpper_Blank';
    CharTemplate.ForceAppearance.nmFlag = 'Country_USA';
    CharTemplate.ForceAppearance.nmHelmet = 'Helmet_0_NoHelmet_M';
    CharTemplate.ForceAppearance.nmLegs = 'CnvMed_Std_D_M';
    CharTemplate.ForceAppearance.nmLegs_Underlay = 'CnvUnderlay_Std_Legs_A_M';
    CharTemplate.ForceAppearance.nmPatterns = 'Pat_Nothing';
    CharTemplate.ForceAppearance.nmTattoo_LeftArm = 'Tattoo_Arms_BLANK';
    CharTemplate.ForceAppearance.nmTattoo_RightArm = 'Tattoo_Arms_BLANK';
    CharTemplate.ForceAppearance.nmTeeth = 'DefaultTeeth';
    CharTemplate.ForceAppearance.nmTorso = 'CnvMed_Std_C_M';
    CharTemplate.ForceAppearance.nmTorso_Underlay = 'CnvUnderlay_Std_Torsos_A_M';
    CharTemplate.ForceAppearance.nmWeaponPattern = 'Pat_Nothing';
    CharTemplate.ForceAppearance.nmVoice = 'CentralVoice1_Localized';

	class'RTHelpers'.static.RTLog("Adding Whisper's character template!");
	return CharTemplate;
}

static function X2CharacterTemplate CreateQueenTemplate()
{
	local X2CharacterTemplate CharTemplate;

	CharTemplate = CreateSoldierTemplate('RTGhostBerserker');
	
	CharTemplate.DefaultSoldierClass = 'RT_Berserker';
	CharTemplate.DefaultLoadout = 'RT_Berserker';
    CharTemplate.bIsPsionic = true;
    
	CharTemplate.bForceAppearance = true;
	CharTemplate.bAppearanceDefinesPawn = true;

	CharTemplate.ForceAppearance.nmPawn = 'XCom_Soldier_F';
	CharTemplate.ForceAppearance.nmHead = 'Shen_Head';
	CharTemplate.ForceAppearance.nmHaircut = 'Shen_Hair';
	CharTemplate.ForceAppearance.nmBeard = '';
	CharTemplate.ForceAppearance.iArmorTint = 97;
	CharTemplate.ForceAppearance.iArmorTintSecondary = 3;
	CharTemplate.ForceAppearance.iGender = 2;
	CharTemplate.ForceAppearance.iAttitude = 3;
	CharTemplate.ForceAppearance.nmArms = 'Shen_Arms';
	CharTemplate.ForceAppearance.nmArms_Underlay = 'CnvMed_Underlay_A_F';
	CharTemplate.ForceAppearance.nmEye = 'DefaultEyes_2';
	CharTemplate.ForceAppearance.nmFacePropLower = 'Prop_FaceLower_Blank';
	CharTemplate.ForceAppearance.nmFacePropUpper = 'Prop_FaceUpper_Blank';
	CharTemplate.ForceAppearance.nmFlag = 'Country_USA'; // Taiwanese-American -acheng
	CharTemplate.ForceAppearance.nmHelmet = 'Helmet_0_NoHelmet_F';
	CharTemplate.ForceAppearance.nmLegs = 'CnvMed_Std_A_F';
	CharTemplate.ForceAppearance.nmLegs_Underlay = 'CnvUnderlay_Std_A_F';
	CharTemplate.ForceAppearance.nmPatterns = 'Pat_Nothing';
	CharTemplate.ForceAppearance.nmTattoo_LeftArm = 'Tattoo_Arms_BLANK';
	CharTemplate.ForceAppearance.nmTattoo_RightArm = 'DLC_3_Tattoo_Arms_01';
	CharTemplate.ForceAppearance.nmTeeth = 'DefaultTeeth';
	CharTemplate.ForceAppearance.nmTorso = 'CnvMed_Std_A_F';
	CharTemplate.ForceAppearance.nmTorso_Underlay = 'CnvUnderlay_Std_A_F';
	CharTemplate.ForceAppearance.nmWeaponPattern = 'Pat_Nothing';
	CharTemplate.ForceAppearance.iWeaponTint = 3;
	CharTemplate.ForceAppearance.nmVoice = 'ShenVoice1_Localized';

	class'RTHelpers'.static.RTLog("Adding Queen's character template!");
	return CharTemplate;
}

static function X2CharacterTemplate CreateNovaTemplate()
{
	local X2CharacterTemplate CharTemplate;

	CharTemplate = CreateSoldierTemplate('RTGhostGatherer');
	
	CharTemplate.DefaultSoldierClass = 'RT_Gatherer';
	CharTemplate.DefaultLoadout = 'RT_Gatherer';
    CharTemplate.bIsPsionic = true;
    
	CharTemplate.bForceAppearance = true;
	CharTemplate.bAppearanceDefinesPawn = true;

	CharTemplate.ForceAppearance.nmPawn = 'XCom_Soldier_F';
	CharTemplate.ForceAppearance.nmHead = 'Shen_Head';
	CharTemplate.ForceAppearance.nmHaircut = 'Shen_Hair';
	CharTemplate.ForceAppearance.nmBeard = '';
	CharTemplate.ForceAppearance.iArmorTint = 97;
	CharTemplate.ForceAppearance.iArmorTintSecondary = 3;
	CharTemplate.ForceAppearance.iGender = 2;
	CharTemplate.ForceAppearance.iAttitude = 3;
	CharTemplate.ForceAppearance.nmArms = 'Shen_Arms';
	CharTemplate.ForceAppearance.nmArms_Underlay = 'CnvMed_Underlay_A_F';
	CharTemplate.ForceAppearance.nmEye = 'DefaultEyes_2';
	CharTemplate.ForceAppearance.nmFacePropLower = 'Prop_FaceLower_Blank';
	CharTemplate.ForceAppearance.nmFacePropUpper = 'Prop_FaceUpper_Blank';
	CharTemplate.ForceAppearance.nmFlag = 'Country_USA'; // Taiwanese-American -acheng
	CharTemplate.ForceAppearance.nmHelmet = 'Helmet_0_NoHelmet_F';
	CharTemplate.ForceAppearance.nmLegs = 'CnvMed_Std_A_F';
	CharTemplate.ForceAppearance.nmLegs_Underlay = 'CnvUnderlay_Std_A_F';
	CharTemplate.ForceAppearance.nmPatterns = 'Pat_Nothing';
	CharTemplate.ForceAppearance.nmTattoo_LeftArm = 'Tattoo_Arms_BLANK';
	CharTemplate.ForceAppearance.nmTattoo_RightArm = 'DLC_3_Tattoo_Arms_01';
	CharTemplate.ForceAppearance.nmTeeth = 'DefaultTeeth';
	CharTemplate.ForceAppearance.nmTorso = 'CnvMed_Std_A_F';
	CharTemplate.ForceAppearance.nmTorso_Underlay = 'CnvUnderlay_Std_A_F';
	CharTemplate.ForceAppearance.nmWeaponPattern = 'Pat_Nothing';
	CharTemplate.ForceAppearance.iWeaponTint = 3;
	CharTemplate.ForceAppearance.nmVoice = 'ShenVoice1_Localized';

	class'RTHelpers'.static.RTLog("Adding Nova's character template!");
	return CharTemplate;
}