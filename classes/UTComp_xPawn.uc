/* UTComp - UT2004 Mutator
Copyright (C) 2004-2005 Aaron Everitt & Joël Moffatt

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA. */

class UTComp_xPawn extends xPawn;

#exec texture import File=textures\purpmark.dds Name=PurpleMarker


var array<Material> SavedSkins;
var bool bSkinsSaved;
var config string FallbackCharacterName;
var color SavedColor, ShieldColor, linkcolor, shockcolor, lgcolor;
var bool bShieldActive, bLinkActive, bShockActive, bLGActive, overlayactive, beffectscleared;
var PlayerController LocalPC;
var PlayerController Pc;
var bool bWeaponsLocked;

struct ClanSkinTripple
{
    var string PlayerName;
    var color PlayerColor;
    var string ModelName;
};

var UTComp_ServerReplicationInfo RepInfo;

var config bool bEnemyBasedSkins;
var config byte ClientSkinModeRedTeammate;
var config byte ClientSkinModeBlueEnemy;
var config byte PreferredSkinColorRedTeammate;
var config byte PreferredSkinColorBlueEnemy;
var config color BlueEnemyUTCompSkinColor;
var config color RedTeammateUTCompSkinColor;
var config bool bBlueEnemyModelsForced;
var config bool bRedTeammateModelsForced;
var config string BlueEnemyModelName;
var config string RedTeammateModelName;
var config bool bEnableDarkSkinning;
var config array<ClanSkinTripple> ClanSkins;
var config array<string> DisallowedEnemyNames;

var config bool bEnemyBasedModels;

var color BrightSkinColors[8];

var byte oldteam;

replication
{
  unreliable if (Role==Role_authority)
     bShieldActive, bLinkActive, bShockActive, bLGactive, overlayActive;
}

simulated function UpdatePrecacheMaterials()
{
	Level.AddPrecacheMaterial(Material'UTCompvSrc.PurpleMarker');
	Super.UpdatePrecacheMaterials();
}

/* --- changed from xPawn's GetTeamNum() to get rid of a bug when
    getting team number in a vehicle client-side ---*/

simulated function int GetTeamNum()
{
    if ( Controller != None )
		return Controller.GetTeamNum();
	if ( (DrivenVehicle != None) && (DrivenVehicle.Controller != None) )
		return DrivenVehicle.Controller.GetTeamNum();
	if ( OldController != None )
		return OldController.GetTeamNum();
    if( PlayerReplicationInfo == none)
	{
        if(DrivenVehicle!=None)
            return DrivenVehicle.GetTeamNum();
        return 255;
	}
	if(PlayerReplicationInfo.Team==None)
        return 255;
    return PlayerReplicationInfo.Team.TeamIndex;
}

simulated function TickFX(float DeltaTime)
{
	local int i,NumSkins;
	local int colormode;

    if ( SimHitFxTicker != HitFxTicker )
    {
        ProcessHitFX();
    }

	if(bInvis && !bOldInvis) // Going invisible
	{
		if ( Left(string(Skins[0]),21) ~= "UT2004PlayerSkins.Xan" )
			Skins[2] = Material(DynamicLoadObject("UT2004PlayerSkins.XanMk3V2_abdomen", class'Material'));

		// Save the 'real' non-invis skin
		NumSkins = Clamp(Skins.Length,2,4);

		for ( i=0; i<NumSkins; i++ )
		{
			RealSkins[i] = Skins[i];
			Skins[i] = InvisMaterial;
		}

		// Remove/disallow projectors on invisible people
		Projectors.Remove(0, Projectors.Length);
		bAcceptsProjectors = false;

		// Invisible - no shadow
		if(PlayerShadow != None)
			PlayerShadow.bShadowActive = false;

		// No giveaway flames either
		RemoveFlamingEffects();
	}
	else if(!bInvis && bOldInvis) // Going visible
	{
		NumSkins = Clamp(Skins.Length,2,4);

		for ( i=0; i<NumSkins; i++ )
			Skins[i] = RealSkins[i];

		bAcceptsProjectors = Default.bAcceptsProjectors;

		if(PlayerShadow != None)
			PlayerShadow.bShadowActive = true;
	}

	bOldInvis = bInvis;

    bDrawCorona = ( !bNoCoronas && !bInvis && (Level.NetMode != NM_DedicatedServer)	&& !bPlayedDeath && (Level.GRI != None) && Level.GRI.bAllowPlayerLights
					&& (PlayerReplicationInfo != None) && Min(RepInfo.EnableBrightSkinsMode, FindSkinMode()) < 3);


	if ( bDrawCorona && (PlayerReplicationInfo.Team != None) )
	{
	    ColorMode=GetColorMode();
        if(ColorMode==0)
		    Texture = Texture'xEffects.GoldGlow';
		else if (ColorMode==1)
		    texture = texture'RedMarker_t';
		else if(ColorMode==2)
            texture = texture'BlueMarker_t';
        else if(ColorMode==3)
            texture = texture'UTCompvSrc.PurpleMarker';
        else if ( PlayerReplicationInfo.Team.TeamIndex == 0 )
			texture = Texture'RedMarker_t';
		else
			Texture = Texture'BlueMarker_t';
	}
}

simulated function string GetDefaultCharacter()
{
    local int i;
    if(Level.NetMode==NM_DedicatedServer)
        return placedcharactername;

    for(i=0; i<default.ClanSkins.Length; i++)
        if(PlayerReplicationInfo!=None && InStrNonCaseSensitive(PlayerReplicationInfo.PlayerName, default.ClanSkins[i].PlayerName))
            return IsAcceptable(default.ClanSkins[i].ModelName);

    if(PawnIsEnemyOrBlue(default.bEnemyBasedModels))
        return IsAcceptable(default.BlueEnemyModelName);
    else
        return IsAcceptable(default.RedTeammateModelName);
}

/* -- S2 in S -- */
simulated function bool InStrNonCaseSensitive(String S, string S2)
{
    local int i;
    for(i=0; i<=(Len(S)-Len(S2)); i++)
    {
        if(Mid(S, i, Len(s2))~=S2)
            return true;
    }
    return false;
}

simulated function bool ShouldForceModel()
{
   if(Level.NetMode==NM_DedicatedServer)
       return true;

   if(PawnIsEnemyOrBlue(default.bEnemyBasedModels))
       return default.bBlueEnemyModelsForced;
   else
       return default.bRedTeammateModelsForced;
}

/*  Includes all defualt characters as of ECE release  */
simulated static function string IsAcceptable(string S)
{
    if (S~="Abaddon");
    else if (S~="Ambrosia");
    else if (S~="Annika");
    else if (S~="Arclite");
    else if (S~="Aryss");
    else if (S~="Asp");
    else if (S~="Axon");
    else if (S~="Azure");
    else if (S~="Baird");
    else if (S~="Barktooth");
    else if (S~="BlackJack");
    else if (S~="Brock");
    else if (S~="Brutalis");
    else if (S~="Cannonball");
    else if (S~="Cathode");
    else if (S~="ClanLord");
    else if (S~="Cleopatra");
    else if (S~="Cobalt");
    else if (S~="Corrosion");
    else if (S~="Cyclops");
    else if (S~="Damarus");
    else if (S~="Diva");
    else if (S~="Divisor");
    else if (S~="Domina");
    else if (S~="Dominator");
    else if (S~="Drekorig");
    else if (S~="Enigma");
    else if (S~="Faraleth");
    else if (S~="Fate");
    else if (S~="Frostbite");
    else if (S~="Gaargod");
    else if (S~="Garrett");
    else if (S~="Gkublok");
    else if (S~="Gorge");
    else if (S~="Greith");
    else if (S~="Guardian");
    else if (S~="Harlequin");
    else if (S~="Horus");
    else if (S~="Hyena");
    else if (S~="Jakob");
    else if (S~="Kaela");
    else if (S~="Kane");
    else if (S~="Karag");
    else if (S~="Komek");
    else if (S~="Kraagesh");
    else if (S~="Kragoth");
    else if (S~="Lauren");
    else if (S~="Lilith");
    else if (S~="Makreth");
    else if (S~="Malcolm");
    else if (S~="Mandible");
    else if (S~="Matrix");
    else if (S~="Mekkor");
    else if (S~="Memphis");
    else if (S~="Mokara");
    else if (S~="Motig");
    else if (S~="Mr.Crow");
    else if (S~="Nebri");
    else if (S~="Ophelia");
    else if (S~="Othello");
    else if (S~="Outlaw");
    else if (S~="Prism");
    else if (S~="Rae");
    else if (S~="Rapier");
    else if (S~="Ravage");
    else if (S~="Reinha");
    else if (S~="Remus");
    else if (S~="Renegade");
    else if (S~="Riker");
    else if (S~="Roc");
    else if (S~="Romulus");
    else if (S~="Rylisa");
    else if (S~="Sapphire");
    else if (S~="Satin");
    else if (S~="Scarab");
    else if (S~="Selig");
    else if (S~="Siren");
    else if (S~="Skakruk");
    else if (S~="Skrilax");
    else if (S~="Subversa");
    else if (S~="Syzygy");
    else if (S~="Tamika");
    else if (S~="Thannis");
    else if (S~="Torch");
    else if (S~="Thorax");
    else if (S~="Virus");
    else if (S~="Widowmaker");
    else if (S~="Wraith");
    else if (S~="Xan");
    else if (S~="Zarina");
    else return "Jakob";

    return S;
}

simulated function Tick(float DeltaTime)
{
    local UTComp_PRI uPRI;

    if(RepInfo==None)
        foreach DynamicActors(Class'UTComp_ServerReplicationInfo', RepInfo)
            break;
    super.Tick(DeltaTime);

    if(Level.NetMode==NM_DedicatedServer)
    {
        return;
    }
    if(LocalPC==None)
        LocalPC=Level.GetLocalPlayerController();

    if(LocalPC!=None && LocalPC.PlayerReplicationInfo != none && LocalPC.PlayerReplicationInfo.Team!=None && LocalPC.PlayerReplicationInfo.Team.TeamIndex!=OldTeam)
    {
        ColorSkins();
    }
    if(LocalPC!=None && LocalPC.PlayerReplicationInfo!=None && LocalPC.PlayerReplicationInfo.bOnlySpectator)
    {
        uPRI=class'UTComp_Util'.static.GetUTCompPRI(LocalPC.PlayerReplicationInfo);
        if(uPRI!=None && uPRI.CoachTeam != 255)
            if(uPRI.CoachTeam!=GetTeamNum())
                 bNoTeamBeacon=True;
    }
    if((bEffectsCleared && !OverlayActive) || Skins.Length==0 || !Skins[0].IsA('Combiner') || !Combiner(skins[0]).Material2.IsA('ConstantColor'))
        return;
    else
        MakeOverlay();

}


/* -- manages the hit effects for skins
   really big hack necessitated by dx9 renderer -- */
simulated function MakeOverlay()
{
    if(!overlayActive)
    {
         if(ConstantColor(Combiner(Skins[0]).Material2).Color!=SavedColor)
         {
             ConstantColor(Combiner(Skins[0]).Material2).Color=SavedColor;
             OverlayMaterial=None;
             bEffectsCleared=True;
             return;
         }
    }
    if(bShieldActive)
    {
        if(ConstantColor(Combiner(Skins[0]).Material2).Color!=ShieldColor)
        {
            ConstantColor(Combiner(Skins[0]).Material2).Color=ShieldColor;
            bEffectsCleared=False;
        }
        return;
    }
    if(bLinkActive && ConstantColor(Combiner(Skins[0]).Material2).Color!=LinkColor)
    {
        ConstantColor(Combiner(Skins[0]).Material2).Color=LinkColor;
        bEffectsCleared=False;
    }
    else if(bShockActive && ConstantColor(Combiner(Skins[0]).Material2).Color!=ShockColor)
    {
        ConstantColor(Combiner(Skins[0]).Material2).Color=ShockColor;
        bEffectsCleared=False;
    }
    else if(bLGActive)
    {
        ConstantColor(Combiner(Skins[0]).Material2).Color=LGColor;
        bEffectsCleared=False;
    }
}

//ToDo -- move the overly timer to a separate timer class
simulated function SetOverlayMaterial( Material mat, float time, bool bOverride )
{
    if(RepInfo==None)
        foreach DynamicActors(Class'UTComp_ServerReplicationInfo', RepInfo)
            break;
    if(RepInfo!=None && RepInfo.EnableBrightSkinsMode == 3)
	{
        if(mat==Shader'XGameShaders.PlayerShaders.LinkHit')
        {
            if(!overlayactive || (OverlayActive && bLinkActive))
            {
                bLinkActive=True;
                overlayactive=true;
                SetTimer(0.150, false);
            }
        }
        else if(mat==Shader'UT2004Weapons.Shaders.ShockHitShader')
        {
           if(!overlayactive || (OverlayActive && bShockActive))
           {
               bShockActive=True;
               overlayactive=true;
               SetTimer(0.30, false);
           }
        }
        else if(mat==Shader'XGameShaders.PlayerShaders.LightningHit')
        {
            if(!overlayactive || (OverlayActive && bLGActive))
            {
                bLGActive=True;
                overlayactive=true;
                SetTimer(0.30, false);
            }
        }
        else if(mat==ShieldHitMat)
        {
            if(!overlayactive || (OverlayActive && bShieldActive))
            {
                bShieldActive=True;
                overlayactive=true;
                if(time==default.shieldhitmattime)
                    SetTimer(0.250, false);
                else
                    SetTimer(time*0.60, false);
            }
        }
    }
    if ( Level.bDropDetail || Level.DetailMode == DM_Low)
		time *= 0.75;
	Super.SetOverlayMaterial(mat,time,bOverride);
}

function timer()
{
    bShieldActive=False;
    bShockActive=False;
    bLGactive=False;
    bLinkActive=False;
    overlayactive=false;
}

simulated function Setup(xUtil.PlayerRecord rec, optional bool bLoadNow)
{
    if ( (rec.Species == None)
       ||  (Level.NetMode==NM_DedicatedServer && class'DeathMatch'.default.bForceDefaultCharacter) || (Level.NetMode!= NM_DedicatedServer && ShouldForceModel()))
		    rec = class'xUtil'.static.FindPlayerRecord(GetDefaultCharacter());
    // check causes CPB skins to fuckup, erm?
    if(/*Level.NetMode!=NM_DedicatedServer && FindSkinMode()>2 &&*/ !Material(DynamicLoadObject(rec.BodySkinName, class'Material', true)).IsA('Texture') && !Material(DynamicLoadObject(rec.BodySkinName, class'Material', true)).IsA('FinalBlend'))
    {
        rec = class'xUtil'.static.FindPlayerRecord(FallbackCharacterName);
    }
    else if(!ShouldUseModel(Rec.DefaultName))
    {
        rec = class'xUtil'.static.FindPlayerRecord(FallbackCharacterName);
    }
    Species = rec.Species;
	RagdollOverride = rec.Ragdoll;
	if ( !Species.static.Setup(self,rec) )
	{
		rec = class'xUtil'.static.FindPlayerRecord(GetDefaultCharacter());
		if ( !Species.static.Setup(self,rec) )
			return;
	}
	ResetPhysicsBasedAnim();
	if(Level.NetMode==NM_DedicatedServer)
	    return;
    ColorSkins();
}


simulated function ColorSkins()
{
    local int i;

    if(Level.NetMode==NM_DedicatedServer)
        return;
    for(i=0; i<Skins.Length; i++)
    {
       if(!bSkinsSaved)
           SavedSkins[i]=Skins[i];
       Skins[i]=ChangeColorOfSkin(SavedSkins[i], i);
    }
    bSkinsSaved=True;

    if(LocalPC==None)
    {
        LocalPC=Level.GetLocalPlayerController();
    }
    //used for checking if the player changed teams mid-game
    if(LocalPC!=None && LocalPC.PlayerReplicationInfo !=None && LocalPC.PlayerReplicationInfo.Team!=None)
        oldTeam=LocalPC.PlayerReplicationInfo.Team.TeamIndex;
}

simulated function material ChangeColorOfSkin(material SkinToChange, byte SkinNum)
{
    local byte SkinMode;
    if(RepInfo==None)
        foreach DynamicActors(Class'UTComp_ServerReplicationInfo', RepInfo)
            break;

    if(RepInfo!=None && RepInfo.EnableBrightSkinsMode==0)
        return SkinToChange;

    if(RepInfo!=None)
        SkinMode=Min(RepInfo.EnableBrightSkinsMode, FindSkinMode());
    else
        SkinMode=FindSkinMode();
    switch(SkinMode)
    {
        case 1: bUnlit=False;
                return ChangeOnlyColor(SkinToChange);
        case 2: bUnlit=True;
                return ChangeColorAndBrightness(SkinToChange, SkinNum);
        case 3: bUnlit=True;
                return ChangeToUTCompSkin(SkinToChange, SkinNum);
    }
    return SkinToChange;
}

simulated function byte FindSkinMode()
{
    if(PawnIsEnemyOrBlue(default.bEnemyBasedSkins))
        return  default.ClientSkinModeBlueEnemy;
    else
        return  default.ClientSkinModeRedTeammate;
}

simulated function int GetColorMode()
{
    local int mode;
    mode=Min(RepInfo.EnableBrightSkinsMode, FindSkinMode());
    switch(mode)
    {
        case 2:  return GetColorModeBright();
        case 1:  return GetColorModeEpic();
    }
    return 255;
}

simulated function int GetColorModeBright()
{
    local int colormode;
    if(PawnIsEnemyOrBlue(default.bEnemyBasedSkins))
        ColorMode=default.PreferredSkinColorBlueEnemy;
    else
        ColorMode=default.PreferredSkinColorRedTeammate;
    return Colormode%4;
}

simulated function int GetColorModeEpic()
{
    local byte ColorMode;
    local byte OtherColorMode;

    if(PawnIsEnemyOrBlue(default.bEnemyBasedSkins))
    {
        ColorMode=default.PreferredSkinColorBlueEnemy;
        OtherColorMode=default.PreferredSkinColorRedTeammate;
    }
    else
    {
        ColorMode=default.PreferredSkinColorRedTeammate;
        OtherColorMode=default.PreferredSkinColorBlueEnemy;
    }
    if(ColorMode > 3)
        ColorMode-=4;
    if(OtherColorMode > 3)
        OtherColorMode-=4;
    switch ColorMode
    {
        case 0:  return 0;
        case 1:  return 1;
        case 2:  return 2;
        case 3: if(OtherColorMode<2)
                     return 2;
                 else
                     return 1;
    }
    return 255;
}

simulated function material ChangeOnlyColor(material SkinToChange)
{
    local byte ColorMode;
    local byte OtherColorMode;

    if(PawnIsEnemyOrBlue(default.bEnemyBasedSkins))
    {
        ColorMode=default.PreferredSkinColorBlueEnemy;
        OtherColorMode=default.PreferredSkinColorRedTeammate;
    }
    else
    {
        ColorMode=default.PreferredSkinColorRedTeammate;
        OtherColorMode=default.PreferredSkinColorBlueEnemy;
    }
    if(ColorMode > 3)
        ColorMode-=4;
    if(OtherColorMode > 3)
        OtherColorMode-=4;

    switch ColorMode
    {
        case 0:  return MakeDMSkin(SkinToChange);
        case 1:  return MakeRedSkin(SkinToChange);
        case 2:  return MakeBlueSkin(SkinToChange);
        case 3:  if(OtherColorMode<2)
                     return MakeBlueSkin(SkinToChange);
                 else
                     return MakeRedSkin(SkinToChange);
    }
    return SkinToChange;
}

simulated function material ChangeColorAndBrightness(material SkinToChange, int SkinNum)
{
    local byte ColorMode;

    if(PawnIsEnemyOrBlue(default.bEnemyBasedSkins))
        ColorMode=default.PreferredSkinColorBlueEnemy;
    else
        ColorMode=default.PreferredSkinColorRedTeammate;
    switch ColorMode
    {
        case 0:  return MakeDMSkin(SkinToChange);  break;
        case 1:  return MakeRedSkin(SkinToChange); break;
        case 2:  return MakeBlueSkin(SkinToChange);  break;
        case 3:  return MakePurpleSkin(SkinToChange);  break;
        case 4:  if(SkinNum==1)
                    return MakeDMSkin(SkinToChange);
                 return MakeBrightDMSkin(SkinToChange);  break;
        case 5:  if(SkinNum==1)
                    return MakeRedSkin(SkinToChange);
                 return MakeBrightRedSkin(SkinToChange);  break;
        case 6:  if(SkinNum==1)
                    return MakeBlueSkin(SkinToChange);
                 return MakeBrightBlueSkin(SkinToChange);  break;
        case 7:  if(SkinNum==1)
                    return SkinToChange;
                 return MakeBrightPurpleSkin(SkinToChange); break;
    }
    return SkinToChange;
}

simulated function material ChangeToUTCompSkin(material SkinToChange, byte SkinNum)
{
    local Combiner C;
    local ConstantColor CC;

    if(SkinNum>0)
        return MakeDMSkin(SkinToChange);

    C=New(None)Class'Combiner';
    CC=New(None)Class'ConstantColor';

    C.CombineOperation=CO_Add;
    C.Material1=MakeDMSkin(SkinToChange);
    if(PawnIsEnemyOrBlue(default.bEnemyBasedSkins))
        CC.Color=MakeClanSkin(default.BlueEnemyUTCompSkinColor);
    else
        CC.Color=MakeClanSkin(default.RedTeammateUTCompSkinColor);
    SavedColor=CC.Color;
    C.Material2=CC;

    if(C!=None)
        return C;
    return SkinToChange;
}

simulated function color MakeClanSkin(color PreviousColor)
{
    local int i;
    if(RepInfo==None || (RepInfo.bEnableClanSkins && !PawnIsEnemyOrBlue(True)))
    {
        for(i=0; i<default.ClanSkins.Length && PlayerReplicationInfo !=None; i++)
            if(InStrNonCaseSensitive(PlayerReplicationInfo.PlayerName, default.ClanSkins[i].PlayerName))
            {
                PreviousColor=default.ClanSkins[i].PlayerColor;
                break;
            }
    }
    return PreviousColor;
}

simulated static function Material MakeDMSkin(material SkinToChange)
{
    local string S;
    local material ReturnMaterial;

    S=String(SkinToChange);

    if(Right(S, 2)~="_0" || Right(S, 2)~="_1")
        ReturnMaterial=Material(DynamicLoadObject(Left(S, Len(S)-2), class'Material', true));
    else if(Right(S, 3)~="_0B" || Right(S, 3)~="_1B")
    {
        S=Left(S, Len(S)-3);
        if(Left(S, 6)~="Bright")
            ReturnMaterial=Material(DynamicLoadObject(Right(S, Len(S)-6), class'Material', true));
    }
    if(ReturnMaterial!=None)
        return ReturnMaterial;
    else
        return SkinToChange;
}

simulated static function Material MakeRedSkin(material SkinToChange)
{
    local string SkinString;
    local Material MaterialToReturn;

    SkinString=String(SkinToChange);

    if(Right(SkinString, 3)~="_0B" || Right(SkinString, 3)~="_1B")
        MaterialToReturn=material(DynamicLoadObject(Left(SkinString, Len(SkinString)-3)$"_0B", class'Material', true));
    else if(Right(SkinString, 2)~="_0" || Right(SkinString, 2)~="_1")
    {
        if(Left(SkinString, 10)~="PlayerSkin")
            MaterialToReturn=material(DynamicLoadObject("Bright"$Left(SkinString, Len(SkinString)-2)$"_0B", class'Material', true));
        if(MaterialToReturn==None)
            MaterialToReturn=material(DynamicLoadObject(Left(SkinString, Len(SkinString)-2)$"_0", class'Material', true));
    }
    else
    {
        MaterialToReturn=Material(DynamicLoadObject("Bright"$SkinString$"_0B", class'Material', true));
        if(MaterialToReturn==None)
            MaterialToReturn=Material(DynamicLoadObject(SkinString$"_0", class'Material', true));
    }
    if(MaterialToReturn!=None)
        return MaterialToReturn;
    else
        return SkinToChange;
}

simulated static function Material MakeBlueSkin(material SkinToChange)
{
    local string SkinString;
    local Material MaterialToReturn;

    SkinString=String(SkinToChange);

    if(Right(SkinString, 3)~="_0B" || Right(SkinString, 3)~="_1B")
        MaterialToReturn=material(DynamicLoadObject(Left(SkinString, Len(SkinString)-3)$"_1B", class'Material', true));
    else if(Right(SkinString, 2)~="_0" || Right(SkinString, 2)~="_1")
    {
        if(Left(SkinString, 10)~="PlayerSkin")
            MaterialToReturn=material(DynamicLoadObject("Bright"$Left(SkinString, Len(SkinString)-2)$"_1B", class'Material', true));
        if(MaterialToReturn==None)
            MaterialToReturn=material(DynamicLoadObject(Left(SkinString, Len(SkinString)-2)$"_1", class'Material', true));
    }
    else
    {
        MaterialToReturn=Material(DynamicLoadObject("Bright"$SkinString$"_1B", class'Material', true));
        if(MaterialToReturn==None)
            MaterialToReturn=Material(DynamicLoadObject(SkinString$"_1", class'Material', true));
    }
    if(MaterialToReturn!=None)
        return MaterialToReturn;
    else
        return SkinToChange;
}

simulated function material MakePurpleSkin(material SkinToChange)
{
   local combiner C;
   local combiner C2;

   C=New(None)class'Combiner';
   C2=New(None)class'Combiner';
   C.CombineOperation=CO_Subtract;
   C.Material1=MakeRedSkin(SkinToChange);
   C.Material2=MakeBlueSkin(SkinToChange);
   C2.CombineOperation=CO_Add;
   C2.Material1=C;
   C2.Material2=C.Material1;

   if(C.Material1.IsA('Texture'))
       return C2;
   else
       return ChangeOnlyColor(SkinToChange);
}

simulated static function material MakeBrightDMSkin(material SkinToChange)
{
    local Combiner C;

    C=New(None)class'Combiner';
    C.CombineOperation=CO_Add;
    C.Material1=MakeDMSkin(SkinToChange);
    C.Material2=C.Material1;

    return C;
}

simulated static function material MakeBrightRedSkin(material SkinToChange)
{
    local Combiner C;
    C=New(None)Class'Combiner';

    C.Material1=MakeRedSkin(SkinToChange);
    C.Material2=C.Material1;
    C.CombineOperation=CO_Add;

    if(C.Material1.IsA('Texture'))
        return C;
    else
        return C.Material1;
}

simulated static function material MakeBrightBlueSkin(material SkinToChange)
{
    local Combiner C;
    C=New(None)Class'Combiner';

    C.Material1=MakeBlueSkin(SkinToChange);
    C.Material2=C.Material1;
    C.CombineOperation=CO_Add;

    if(C.Material1.IsA('Texture'))
        return C;
    else
        return C.Material1;
}

simulated function material MakeBrightPurpleSkin(material SkinToChange)
{
    local Combiner C;

    C=New(None)class'Combiner';
    C.CombineOperation=CO_Add;
    C.Material1=MakeRedSkin(SkinToChange);
    C.Material2=MakeBlueSkin(SkinToChange);
    if(C.Material1.IsA('Texture'))
        return C;
    else
        return ChangeOnlyColor(SkinToChange);
}



simulated function bool PawnIsEnemyOrBlue(bool bEnemyBased)
{
   local int LocalPlayerTeamNum;
   local int PawnTeamNum;

   if(LocalPC==None)
       LocalPC=Level.GetLocalPlayerController();
   LocalPlayerTeamNum=LocalPC.GetTeamNum();
   PawnTeamNum=GetTeamNum();

   if(PawnTeamNum==255)
   {
       if(Controller==None || PlayerController(Controller)==None || PlayerController(Controller) !=LocalPC)
           return true;
       return false;
   }
   if(bEnemyBased && LocalPC.PlayerReplicationInfo!=None &&(!LocalPC.PlayerReplicationInfo.bOnlySpectator || Level.Game.IsA('UTComp_Duel')) )
       return (PawnTeamNum!=LocalPlayerTeamNum);
   else
       return (PawnTeamNum==1);
}

simulated function color CapColor(color ColorToCap, optional int furthercap)
{
   ColorToCap.R=Min(ColorToCap.R, 128);
   ColorToCap.G=Min(ColorToCap.G, 128);
   ColorToCap.B=Min(ColorToCap.B, 128);
   if(furthercap != 0)
   {
      ColorToCap.R=Min(ColorToCap.R, furthercap);
      ColorToCap.G=Min(ColorToCap.G, furthercap);
      ColorToCap.B=Min(ColorToCap.B, furthercap);
   }
   return ColorToCap;
}

state dying
{
    simulated function BeginState()
    {
	    Super.BeginState();
     	AmbientSound = None;
    	DarkSkinMe();
    }
    simulated function DarkSkinMe()
    {
        if(Level.NetMode==NM_DedicatedServer || !default.benableDarkSkinning)
            return;
        if(Skins.Length >= 1 && Skins[0].IsA('Combiner'))
        {
           if(Combiner(Skins[0]).Material2==Combiner(Skins[0]).Material1 || Combiner(skins[0]).Material2.IsA('ConstantColor'))
               Combiner(Skins[0]).CombineOperation=CO_Use_Color_From_Material1;
        }
        OverlayMaterial=None;
        bUnlit=False;
        ambientGlow=0;
    }
}

simulated function bool ShouldUseModel(string S)
{
    local int i;
    for(i=0; i<DisallowedEnemyNames.Length; i++)
    {
        if(DisallowedEnemyNames[i]~=S)
            return false;
    }
    return true;
}

defaultproperties
{
     ClientSkinModeRedTeammate=3
     ClientSkinModeBlueEnemy=3
     PreferredSkinColorRedTeammate=5
     PreferredSkinColorBlueEnemy=6
     BlueEnemyUTCompSkinColor=(B=128,A=255)
     RedTeammateUTCompSkinColor=(R=128,A=255)
     bBlueEnemyModelsForced=True
     bRedTeammateModelsForced=True
     BlueEnemyModelName="Arclite"
     RedTeammateModelName="Arclite"
     bEnableDarkSkinning=True
     BrightSkinColors(0)=(A=255)
     BrightSkinColors(1)=(R=200,A=255)
     BrightSkinColors(2)=(B=200,G=64,R=50,A=255)
     BrightSkinColors(3)=(B=200,G=64,R=200,A=255)
     BrightSkinColors(4)=(A=255)
     BrightSkinColors(5)=(R=200,A=255)
     BrightSkinColors(6)=(B=200,G=64,R=50,A=255)
     BrightSkinColors(7)=(B=200,G=64,R=200,A=255)
     FallbackCharacterName="Arclite"
     ShieldColor=(G=65,R=105)
     LinkColor=(G=100)
     shockcolor=(B=80,R=80)
     lgcolor=(B=80,G=40,R=40)
     beffectscleared=True
}
