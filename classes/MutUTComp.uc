/*
UTComp - UT2004 Mutator
Copyright (C) 2004-2005 Aaron Everitt & Jo�l Moffatt

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
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/
//-----------------------------------------------------------
//   UTComp Version Src by Aaron 'Lotus' Everitt
//
//   Main Mutator class
//   Last Edited(or, rather, last edited and i bothered to update this)
//    - Mar 15, 2005
//-----------------------------------------------------------
class MutUTComp extends Mutator;

var config bool bEnableVoting;
var config bool bEnableBrightskinsVoting;
var config bool bEnableHitsoundsVoting;
var config bool bEnableWarmupVoting;
var config bool bEnableTeamOverlayVoting;
var config bool bEnableMapVoting;
var config bool bEnableGametypeVoting;
var config bool bEnableTimedOvertimeVoting;
var bool bEnableDoubleDamageVoting;
var config float VotingPercentRequired;
var config float VotingTimeLimit;

var config bool bEnableDoubleDamage;
var config byte EnableBrightSkinsMode;
var config bool bEnableClanSkins;
var config bool bEnableTeamOverlay;
var config byte EnableHitSoundsMode;
var config bool bEnableScoreboard;
var config bool bEnableWarmup;
var config float WarmupReadyPercentRequired;
var config bool bEnableWeaponStats;
var config bool bEnablePowerupStats;
var config bool bShowTeamScoresInServerBrowser;

var config byte ServerMaxPlayers;
var config bool bEnableAdvancedVotingOptions;
var config array<string> AlwaysUseThisMutator;

var config bool bEnableAutoDemoRec;
var config string AutoDemoRecMask;
var config byte EnableWarmupWeaponsMode;
var config int WarmupTime;
var config int WarmupHealth;

var config bool bForceMapVoteMatchPrefix;
var config bool bEnableTimedOvertime;
var config int TimedOverTimeLength;
var config int NumGrenadesOnSpawn;

var bool bDemoStarted;

/* ----Known issues ----
   Mutant:  No Bskins/Forcemodel
   Invasion:  No Bskins/forcemodel on bots (but will on players), no warmup, no custom scoreboard
   Assault:  No Warmup (uses assaults native warmup)
   LMS: No custom scoreboard (original 1 to extend real buggy)
-------------------------- */

struct MapVotePair
{
    var string GametypeOptions;
    var string GametypeName;
};

var config array<MapVotePair> VotingGametype;

var UTComp_ServerReplicationInfo RepInfo;
var UTComp_OverlayUpdate OverlayClass;
var UTComp_VotingHandler VotingClass;
var UTComp_Warmup WarmupClass;
var bool bHasInteraction;

var string origcontroller;
var class<PlayerController> origcclass;


/*    List Of Features to be completed(see utcomp_v2.txt for details)
========Not Started========
Extra Hud Clock
========In Progress========
Overtime
=========Completed=========
Scoreboard
Onjoin box
Voting
Optional Standard Server Compatibility
Force Models
BrightSkins
Autoscreenshot
Clanskins
Hitsounds
Weapon Stats
Client Console Commands
Spectator Console Commands
Powerup Stats
Various Server Settings
InGame Clock
Coaching
Team Overlay
Warmup
Autodemorec
Quick Map Restarts
Crosshair Factory
Colored Names
*/

//==========================
//  Begin Enhanced Netcode stuff
//==========================

var PawnCollisionCopy PCC;

var TimeStamp StampInfo;

var float AverDT;
var float ClientTimeStamp;

var array<float> DeltaHistory;
var bool bEnhancedNetCodeEnabledAtStartOfMap;

var config bool bEnableEnhancedNetCode;
var config bool bEnableEnhancedNetCodeVoting;

var FakeProjectileManager FPM;

const AVERDT_SEND_PERIOD = 4.00;
var float LastReplicatedAverDT;

var class<weapon> WeaponClasses[12];
var string WeaponClassNames[12];
var class<Weapon> ReplacedWeaponClasses[12];

var class<WeaponPickup> ReplacedWeaponPickupClasses[12];
var class<WeaponPickup> WeaponPickupClasses[12];
var string WeaponPickupClassNames[12];


//==========================
//  End Enhanced Netcode stuff
//==========================

function PreBeginPlay()
{
    SetupDD();
    ReplacePawnAndPC();
    SetupTeamOverlay();
    SetupStats();
    SetupWarmup();
    SetupVoting();
    SetupColoredDeathMessages();
    SpawnReplicationClass();
    StaticSaveConfig();
    bEnhancedNetCodeEnabledAtStartOfMap = bEnableEnhancedNetCode;
    super.PreBeginPlay();
}

function SetupDD()
{
   if(Level.Game.IsA('UTComp_Duel'))
      bEnableDoubleDamage=UTComp_Duel(Level.Game).bEnableDoubleDamage;
}

function SetupColoredDeathMessages()
{
    if(Level.Game.DeathMessageClass==class'xGame.xDeathMessage')
        Level.Game.DeathMessageClass=class'UTCompvSrc.UTComp_xDeathMessage';
    else if(Level.Game.DeathMessageClass==Class'SkaarjPack.InvasionDeathMessage')
        Level.Game.DeathMessageClass=class'UTCompvSrc.UTComp_InvasionDeathMessage';
}

function ModifyPlayer(Pawn Other)
{
    local inventory inv;
    local int i;

    if(WarmupClass!=None && !Level.Game.IsA('UTComp_ClanArena')&& (WarmupClass.bInWarmup==True || WarmupClass.bGivePlayerWeaponHack ))                       //Give all weps if its warmup
    {
         switch(EnableWarmupWeaponsMode)
         {
         case 0: break;

         case 3:
                 Other.CreateInventory("Onslaught.ONSGrenadeLauncher");
                 Other.CreateInventory("Onslaught.ONSAVRiL");
                 Other.CreateInventory("Onslaught.ONSMineLayer");
         case 2:
                 Other.CreateInventory("XWeapons.SniperRifle");
                 Other.CreateInventory("XWeapons.RocketLauncher");
                 Other.CreateInventory("XWeapons.FlakCannon");
                 Other.CreateInventory("XWeapons.MiniGun");
                 Other.CreateInventory("XWeapons.LinkGun");
                 Other.CreateInventory("XWeapons.ShockRifle");
                 Other.CreateInventory("XWeapons.BioRifle");
                 Other.CreateInventory("XWeapons.AssaultRifle");
                 Other.CreateInventory("XWeapons.ShieldGun"); break;

        case 1: if(!WarmupClass.bWeaponsChecked)
                    WarmupClass.FindWhatWeaponsToGive();
                for(i=0; i<WarmupClass.sWeaponsToGive.Length; i++)
                    Other.CreateInventory(WarmupClass.sWeaponsToGive[i]);
        }

        for(Inv=Other.Inventory; Inv!=None; Inv=Inv.Inventory)
	        if(Weapon(Inv)!=None)
	        {
                Weapon(Inv).SuperMaxOutAmmo();
	            Weapon(Inv).Loaded();
	        }
	    if (WarmupHealth!=0)
            Other.Health=WarmupHealth;
        else
            Other.Health=199;
    }

    if(bEnhancedNetCodeEnabledAtStartOfMap)
    {
        SpawnCollisionCopy(Other);
        RemoveOldPawns();

     /*   Other.CreateInventory("UTCompvSrc.NewNet_SniperRifle");
        Other.CreateInventory("UTCompvSrc.NewNet_FlakCannon");
        Other.CreateInventory("UTCompvSrc.NewNet_BioRifle");
        Other.CreateInventory("UTCompvSrc.NewNet_MiniGun");
        Other.CreateInventory("UTCompvSrc.NewNet_LinkGun");
        Other.CreateInventory("UTCompvSrc.NewNet_AssaultRifle");
        Other.CreateInventory("UTCompvSrc.NewNet_ShockRifle");
        for(Inv=Other.Inventory; Inv!=None; Inv=Inv.Inventory)
            if(NewNet_SniperRifle(Inv)!=None || NewNet_FlakCannon(inv)!=None
            || NewNet_BioRifle(inv)!=None || NewNet_MiniGun(inv)!=None
            || NewNet_LinkGun(inv)!=None || NewNet_ShockRifle(inv)!=None)
            {
                Weapon(Inv).MaxOutAmmo();
                Weapon(Inv).Loaded();
            }    */
    }

    Super.ModifyPlayer(Other);
}

function DriverEnteredVehicle(Vehicle V, Pawn P)
{
	SpawnCollisionCopy(V);

    if( NextMutator != none )
		NextMutator.DriverEnteredVehicle(V, P);
}

function SpawnCollisionCopy(Pawn Other)
{

    if(PCC==None)
    {
        PCC = Spawn(class'PawnCollisionCopy');
        PCC.SetPawn(Other);
    }
    else
        PCC.AddPawnToList(Other);

}

function RemoveOldPawns()
{
 //   if(PCC==None)
 //       return;
    PCC = PCC.RemoveOldPawns();
}

function ListPawns()
{
    local PawnCollisionCopy PCC2;
    for(PCC2=PCC; PCC2!=None; PCC2=PCC2.Next)
       PCC2.Identify();
}

static function bool IsPredicted(actor A)
{
   if(A == none || A.IsA('xPawn'))
       return true;
   //Fix up vehicle a bit, we still wanna predict if its in the list w/o a driver
   if((A.IsA('Vehicle') && Vehicle(A).Driver!=None))
       return true;
   return false;
}


function SetupTeamOverlay()
{
    if(!bEnableTeamOverlay || !Level.Game.bTeamGame)
        return;
    if (OverlayClass==None)
    {
        OverlayClass=Spawn(class'UTComp_OverlayUpdate', self);
        OverlayClass.UTCompMutator=self;
        OverlayClass.InitializeOverlay();
    }
}

function SetupWarmup()
{
    if(Level.Game.IsA('UTComp_Duel'))
    {
        bEnableWarmup=True;
    }
    else if(Level.Game.IsA('UTComp_ClanArena'))
    {
       if(!bEnableWarmup)
       {
           bEnableWarmup=true;
           WarmupTime = 30.0;
       }
    }
    else if(!bEnableWarmup || Level.Game.IsA('ASGameInfo') || Level.Game.IsA('Invasion') || Level.Title~="Bollwerk Ruins 2004 - Pro Edition")
    {
        return;
    }

    if(WarmupClass==None)
        WarmupClass=Spawn(Class'UTComp_Warmup', self);

    WarmupClass.iWarmupTime=WarmupTime;

    WarmupClass.fReadyPercent=WarmupReadyPercentRequired;
    WarmupClass.InitializeWarmup();
}

function SetupVoting()
{
    if(!bEnableVoting)
        return;
    if(Level.Game.IsA('UTComp_Duel'))
       bEnableGametypeVoting=False;
    if(VotingClass==None)
    {
        VotingClass=Spawn(class'UTComp_VotingHandler', self);
        VotingClass.fVotingTime=VotingTimeLimit;
        VotingClass.fVotingPercent=VotingPercentRequired;
        VotingClass.InitializeVoting();
        VotingClass.UTCompMutator=Self;
    }
}

function SetupStats()
{
    Class'xWeapons.TransRecall'.Default.Transmaterials[0]=None;
    Class'xWeapons.TransRecall'.Default.Transmaterials[1]=None;

    if(!bEnableWeaponStats)
        return;
    class'xWeapons.AssaultRifle'.default.FireModeClass[0] = Class'UTCompvSrc.UTComp_AssaultFire';
    class'xWeapons.AssaultRifle'.default.FireModeClass[1] = Class'UTCompvSrc.UTComp_AssaultGrenade';

    class'xWeapons.BioRifle'.default.FireModeClass[0] = Class'UTCompvSrc.UTComp_BioFire';
    class'xWeapons.BioRifle'.default.FireModeClass[1] = Class'UTCompvSrc.UTComp_BioChargedFire';

    class'xWeapons.ShockRifle'.default.FireModeClass[0] = Class'UTCompvSrc.UTComp_ShockBeamFire';
    class'xWeapons.ShockRifle'.default.FireModeClass[1] = Class'UTCompvSrc.UTComp_ShockProjFire';

    class'xWeapons.LinkGun'.default.FireModeClass[0] = Class'UTCompvSrc.UTComp_LinkAltFire';
    class'xWeapons.LinkGun'.default.FireModeClass[1] = Class'UTCompvSrc.UTComp_LinkFire';

    class'xWeapons.MiniGun'.default.FireModeClass[0] = Class'UTCompvSrc.UTComp_MinigunFire';
    class'xWeapons.MiniGun'.default.FireModeClass[1] = Class'UTCompvSrc.UTComp_MinigunAltFire';

    class'xWeapons.FlakCannon'.default.FireModeClass[0] = Class'UTCompvSrc.UTComp_FlakFire';
    class'xWeapons.FlakCannon'.default.FireModeClass[1] = Class'UTCompvSrc.UTComp_FlakAltFire';

    class'xWeapons.RocketLauncher'.default.FireModeClass[0] = Class'UTCompvSrc.UTComp_RocketFire';
    class'xWeapons.RocketLauncher'.default.FireModeClass[1] = Class'UTCompvSrc.UTComp_RocketMultiFire';

    class'xWeapons.SniperRifle'.default.FireModeClass[0]= Class'UTCompvSrc.UTComp_SniperFire';
    class'UTClassic.ClassicSniperRifle'.default.FireModeClass[0]= Class'UTCompvSrc.UTComp_ClassicSniperFire';

    class'Onslaught.ONSMineLayer'.default.FireModeClass[0] = Class'UTCompvSrc.UTComp_ONSMineThrowFire';

    class'Onslaught.ONSGrenadeLauncher'.default.FireModeClass[0] =Class'UTCompvSrc.UTComp_ONSGrenadeFire';

    class'OnsLaught.ONSAvril'.default.FireModeClass[0] =Class'UTCompvSrc.UTComp_ONSAvrilFire';

    class'xWeapons.SuperShockRifle'.default.FireModeClass[0]=class'UTCompvSrc.UTComp_SuperShockBeamFire';
    class'xWeapons.SuperShockRifle'.default.FireModeClass[1]=class'UTCompvSrc.UTComp_SuperShockBeamFire';

    /* if(bEnhancedNetCodeEnabledAtStartOfMap)
    {
         Class'XWeapons.DamTypeRocketHoming'.default.WeaponClass = class'NewNet_RocketLauncher';
         Class'XWeapons.DamTypeFlakShell'.default.WeaponClass = class'NewNet_FlakCannon';
         Class'XWeapons.DamTypeMinigunAlt'.default.WeaponClass = class'NewNet_MiniGun';
         Class'XWeapons.DamTypeLinkShaft'.default.WeaponClass = class'NewNet_LinkGun';
         Class'XWeapons.DamTypeShockBall'.default.WeaponClass = class'NewNet_ShockRifle';
         Class'XWeapons.DamTypeAssaultGrenade'.default.WeaponClass = class'NewNet_AssaultRifle';
         Class'XWeapons.DamTypeShockCombo'.default.WeaponClass = class'NewNet_ShockRifle';
         Class'Onslaught.DamTypeONSAVRiLRocket'.default.WeaponClass = class'NewNet_ONSAvril';
         Class'Onslaught.DamTypeONSGrenade'.default.WeaponClass = class'NewNet_ONSGrenadeLauncher';
         Class'Onslaught.DamTypeONSMine'.default.WeaponClass = class'NewNet_ONSMineLayer';
         Class'XWeapons.DamTypeSniperShot'.default.WeaponClass = class'NewNet_SniperRifle';
         Class'XWeapons.DamTypeRocket'.default.WeaponClass = class'NewNet_RocketLauncher';
         Class'XWeapons.DamTypeFlakChunk'.default.WeaponClass = class'NewNet_FlakCannon';
         Class'XWeapons.DamTypeMinigunBullet'.default.WeaponClass = class'NewNet_MiniGun';
         Class'XWeapons.DamTypeLinkPlasma'.default.WeaponClass = class'NewNet_LinkGun';
         Class'XWeapons.DamTypeShockBeam'.default.WeaponClass = class'NewNet_ShockRifle';
         Class'XWeapons.DamTypeBioGlob'.default.WeaponClass = class'NewNet_BioRifle';
         Class'XWeapons.DamTypeAssaultBullet'.default.WeaponClass = class'NewNet_AssaultRifle';
     }
     */
}


simulated function Tick(float DeltaTime)
{
    local PlayerController PC;

    if(Level.NetMode==NM_DedicatedServer)
    {
        if(bEnhancedNetCodeEnabledAtStartOfMap)
        {
            ClientTimeStamp+=DeltaTime;
            AverDT = (9.0*AverDT + DeltaTime) / 10.0;
            StampInfo.ReplicatetimeStamp(ClientTimeStamp);
            if(ClientTimeStamp > LastReplicatedAverDT + AVERDT_SEND_PERIOD)
            {
                StampInfo.ReplicatedAverDT(AverDT);
                LastReplicatedAverDT = ClientTimeStamp;
            }
        }

        if (!bEnableAutoDemoRec || bDemoStarted || default.bEnableWarmup || Level.Game.bWaitingToStartMatch)
            return;
        else
           AutoDemoRecord();
        return;
    }

    if( FPM==None && Level.NetMode == NM_Client)
        FPM = Spawn(Class'FakeProjectileManager');

    if(bHasInteraction)
        return;
    PC=Level.GetLocalPlayerController();

    if(PC!=None)
    {
        PC.Player.InteractionMaster.AddInteraction("UTCompvSrc.UTComp_Overlay", PC.Player);
        bHasInteraction=True;
        class'DamTypeLinkShaft'.default.bSkeletize=false;
    }
}

function ReplacePawnAndPC()
{
    if(Level.Game.DefaultPlayerClassName~="xGame.xPawn")
        Level.Game.DefaultPlayerClassName="UTCompvSrc.UTComp_xPawn";
    if(class'xPawn'.default.ControllerClass==class'XGame.XBot') //bots don't skin otherwise
        class'xPawn'.default.ControllerClass=class'UTCompvSrc.UTComp_xBot';

    Level.Game.PlayerControllerClassName="UTCompvSrc.BS_xPlayer";
}

function SpawnReplicationClass()
{
    local int i;
    if(RepInfo==None)
        RepInfo=Spawn(class'UTComp_ServerReplicationInfo', self);

    RepInfo.bEnableVoting=bEnableVoting;
    RepInfo.EnableBrightSkinsMode=Clamp(EnableBrightSkinsMode,1,3);
    RepInfo.bEnableClanSkins=bEnableClanSkins;
    RepInfo.bEnableTeamOverlay=bEnableTeamOverlay;
    RepInfo.EnableHitSoundsMode=EnableHitSoundsMode;
    RepInfo.bEnableScoreboard=bEnableScoreboard;
    RepInfo.bEnableWarmup=bEnableWarmup;
    RepInfo.bEnableWeaponStats=bEnableWeaponStats;
    RepInfo.bEnablePowerupStats=bEnablePowerupStats;
    RepInfo.bEnableBrightskinsVoting=bEnableBrightskinsVoting;
    RepInfo.bEnableHitsoundsVoting=bEnableHitsoundsVoting;
    RepInfo.bEnableWarmupVoting=bEnableWarmupVoting;
    RepInfo.bEnableTeamOverlayVoting=bEnableTeamOverlayVoting;
    RepInfo.bEnableMapVoting=bEnableMapVoting;
    RepInfo.bEnableGametypeVoting=bEnableGametypeVoting;
    RepInfo.ServerMaxPlayers=ServerMaxPlayers;
    RepInfo.bEnableDoubleDamage=bEnableDoubleDamage;
    RepInfo.bEnableDoubleDamageVoting=bEnableDoubleDamageVoting;
    RepInfo.MaxPlayersClone=Level.Game.MaxPlayers;
    RepInfo.bEnableAdvancedVotingOptions=bEnableAdvancedVotingOptions;
    RepInfo.bEnableTimedOvertimeVoting=bEnableTimedOvertimeVoting;
    RepInfo.bEnableTimedOvertime=bEnableTimedOvertime;
    RepInfo.bEnableEnhancedNetcode=bEnableEnhancedNetcode;
    RepInfo.bEnableEnhancedNetcodeVoting=bEnableEnhancedNetcodeVoting;
    for(i=0; i<VotingGametype.Length && i<ArrayCount(RepInfo.VotingNames); i++)
        RepInfo.VotingNames[i]=VotingGametype[i].GameTypeName;

    for(i=0; i<VotingGametype.Length && i<ArrayCount(RepInfo.VotingOptions); i++)
        RepInfo.VotingOptions[i]=VotingGametype[i].GameTypeOptions;

    if(Level.Game.IsA('CTFGame') || Level.Game.IsA('ONSONslaughtGame') || Level.Game.IsA('ASGameInfo') || Level.Game.IsA('xBombingRun')
    || Level.Game.IsA('xMutantGame') || Level.Game.IsA('xLastManStandingGame') || Level.Game.IsA('xDoubleDom') || Level.Game.IsA('Invasion'))
       bEnableTimedOvertime=False;
}

function PostBeginPlay()
{
	local UTComp_GameRules G;
	local mutator M;

	Super.PostBeginPlay();

	G = spawn(class'UTComp_GameRules');
    G.UTCompMutator=Self;
	G.OVERTIMETIME=TimedOverTimeLength;

    if ( Level.Game.GameRulesModifiers == None )
		Level.Game.GameRulesModifiers = G;
	else
		Level.Game.GameRulesModifiers.AddGameRules(G);

    if(StampInfo == none && bEnhancedNetCodeEnabledAtStartOfMap)
       StampInfo = Spawn(class'TimeStamp');

    for(M=Level.Game.BaseMutator; M!=None; M=M.NextMutator)
    {
        if(string(M.Class)~="SpawnGrenades.MutSN")
            return;
    }
    class'GrenadeAmmo'.default.InitialAmount = NumGrenadesOnSpawn;
}

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

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
    local LinkedReplicationInfo lPRI;
    local int x, i;
	local WeaponLocker L;

    bSuperRelevant = 0;
    if(Other.IsA('pickup') && Level.Game!=None && Level.Game.IsA('utcomp_clanarena'))
        return false;
    if(bEnhancedNetCodeEnabledAtStartOfMap)
    {
        if (xWeaponBase(Other) != None)
    	{
	    	for (x = 0; x < ArrayCount(ReplacedWeaponClasses); x++)
	    		if (xWeaponBase(Other).WeaponType == ReplacedWeaponClasses[x])
	    			xWeaponBase(Other).WeaponType = WeaponClasses[x];
	    	         	return true;
	    }
   /* 	else if (Weapon(Other) != None)
    	{
    		for (x = 0; x < ArrayCount(ReplacedWeaponClasses); x++)
	    		if (Other.Class == ReplacedWeaponClasses[x])
	    	 		return false;
     	}   */
	    else if (WeaponPickup(Other) != None)
    	{
             for (x = 0; x < ArrayCount(ReplacedWeaponClasses); x++)
		    	if ( Other.Class == ReplacedWeaponPickupClasses[x])
		    	{
                    ReplaceWith(Other, WeaponPickupClassNames[x]);
                    return false;
	     		}
	        //sigh, need this in case we can't change the wep-base
    	}
    	else if (WeaponLocker(Other) != None)
    	{
    		if(Level.Game.IsA('UTComp_ClanArena'))
                L.GotoState('Disabled');
            L = WeaponLocker(Other);
    		for (x = 0; x < ArrayCount(ReplacedWeaponClasses); x++)
    			for (i = 0; i < L.Weapons.Length; i++)
    				if (L.Weapons[i].WeaponClass == ReplacedWeaponClasses[x])
    					L.Weapons[i].WeaponClass = WeaponClasses[x];
    		return true;
    	}
	}
    if (PlayerReplicationInfo(Other)!=None)
    {
        if(PlayerReplicationInfo(Other).CustomReplicationInfo!=None)
        {
            lPRI=PlayerReplicationInfo(Other).CustomReplicationInfo;
            while(lPRI.NextReplicationInfo!=None)
            {
                 lPRI=lPRI.NextReplicationInfo;
            }
            lPRI.NextReplicationInfo=Spawn(class'UTComp_PRI', Other.Owner);
            if(bEnhancedNetCodeEnabledAtStartOfMap)
                lPRI.NextReplicationInfo.NextReplicationInfo = Spawn(class'NewNet_PRI', Other.Owner);
        }
        else
        {
            PlayerReplicationInfo(Other).CustomReplicationInfo=Spawn(class'UTComp_PRI', Other.Owner);
            if(bEnhancedNetCodeEnabledAtStartOfMap)
                PlayerReplicationInfo(Other).CustomReplicationInfo.NextReplicationInfo = Spawn(class'NewNet_PRI', Other.Owner);
        }
    }
    if (Other.IsA('UDamagePack') && !GetDoubleDamage())
    {
       return false;
    }
    return true;
}

function bool getDoubleDamage()
{
   SetupDD();
   return bEnableDoubleDamage;
}


function ModifyLogin(out string Portal, out string Options)
{
    local bool bSeeAll;
	local bool bSpectator;


    if (Level.game == none) {
		Log ("utv2004s: Level.game is none?");
		return;
	}

	if (origcontroller != "") {
		Level.Game.PlayerControllerClassName = origcontroller;
		Level.Game.PlayerControllerClass = origcclass;
		origcontroller = "";
	}

    bSpectator = ( Level.Game.ParseOption( Options, "SpectatorOnly" ) ~= "1" );
    bSeeAll = ( Level.Game.ParseOption( Options, "UTVSeeAll" ) ~= "true" );

	if (bSeeAll && bSpectator) {
		Log ("utv2004s: Creating utv controller");
		origcontroller = Level.Game.PlayerControllerClassName;
		origcclass = Level.Game.PlayerControllerClass;
		Level.Game.PlayerControllerClassName = "UTCompvSrc.UTV_BS_xPlayer";
		Level.Game.PlayerControllerClass = none;
	}

    if(Level.Game.ScoreBoardType~="xInterface.ScoreBoardDeathMatch")
    {
        if(bEnableScoreBoard)
            Level.Game.ScoreBoardType="UTCompvSrc.UTComp_ScoreBoard";
        else
            Level.Game.ScoreBoardType="UTCompvSrc.UTComp_ScoreBoardDM";
    }
    else if(Level.Game.ScoreBoardType~="xInterface.ScoreBoardTeamDeathMatch")
    {
        if(bEnableScoreBoard)
            Level.Game.ScoreBoardType="UTCompvSrc.UTComp_ScoreBoard";
        else
            Level.Game.ScoreBoardType="UTCompvSrc.UTComp_ScoreBoardTDM";
    }
    else if(Level.Game.ScoreBoardType~="UT2k4Assault.ScoreBoard_Assault")
    {
        Level.Game.ScoreBoardType="UTCompvSrc.UTComp_ScoreBoard_AS";
    }
    else if(Level.game.scoreboardtype~="BonusPack.MutantScoreboard")
    {
        Level.Game.ScoreBoardType="UTCompvSrc.UTComp_ScoreBoard_Mutant";
    }
/*   else if(Level.Game.ScoreBoardType~="BonusPack.ScoreBoardLMS")
    {
         Level.Game.ScoreBoardType="UTCompvSrc.UTComp_ScoreBoard_LMS";
    }  */

    Super.ModifyLogin(Portal, Options);

    if(level.game.hudtype~="xInterface.HudCTeamDeathmatch")
        Level.Game.HudType="UTCompvSrc.UTComp_HudCTeamDeathmatch";
    else if(level.game.hudtype~="xInterface.HudCDeathmatch")
        Level.Game.HudType="UTCompvSrc.UTComp_HudCDeathmatch";
    else if(level.game.hudtype~="xInterface.HudCBombingRun")
        Level.Game.HudType="UTCompvSrc.UTComp_HudCBombingRun";
    else if(level.game.hudtype~="xInterface.HudCCaptureTheFlag")
        Level.Game.HudType="UTCompvSrc.UTComp_HudCCaptureTheFlag";
    else if(level.game.hudtype~="xInterface.HudCDoubleDomination")
        Level.Game.HudType="UTCompvSrc.UTComp_HudCDoubleDomination";
    else if(level.game.hudtype~="Onslaught.ONSHUDOnslaught")
        Level.Game.HudType="UTCompvSrc.UTComp_ONSHUDOnslaught";
    else if(level.game.hudtype~="SkaarjPack.HudInvasion")
        Level.Game.HudType="UTCompvSrc.UTComp_HudInvasion";
    else if(level.game.hudtype~="BonusPack.HudLMS")
        Level.Game.HudType="UTCompvSrc.UTComp_HudLMS";
    else if(level.game.hudtype~="BonusPack.HudMutant")
        Level.Game.HudType="UTCompvSrc.UTComp_HudMutant";
    else if(level.game.hudtype~="ut2k4assault.Hud_Assault")
        Level.Game.HudType="UTCompvSrc.UTComp_Hud_Assault";
}

function GetServerPlayers( out GameInfo.ServerResponseLine ServerState )
{
    local int i;

    if(!Level.Game.bTeamGame)
        return;

    if(bShowTeamScoresInServerBrowser && TeamGame(Level.Game).Teams[0]!=None)
    {
        i = ServerState.PlayerInfo.Length;
        ServerState.PlayerInfo.Length = i+1;
        ServerState.PlayerInfo[i].PlayerName = Chr(0x1B)$chr(10)$chr(245)$chr(10)$"Red Team Score";
        ServerState.PlayerInfo[i].Score = TeamGame(Level.Game).Teams[0].Score;
     //   ServerState.PlayerInfo[i].Ping = 1337;
    }

    if(bShowTeamScoresInServerBrowser && TeamGame(Level.Game).Teams[1]!=None)
    {
        i = ServerState.PlayerInfo.Length;
        ServerState.PlayerInfo.Length = i+1;
        ServerState.PlayerInfo[i].PlayerName =  Chr(0x1B)$chr(10)$chr(245)$chr(10)$"Blue Team Score";
        ServerState.PlayerInfo[i].Score = TeamGame(Level.Game).Teams[1].Score;
     //   ServerState.PlayerInfo[i].Ping = 1337;
    }
}

function ServerTraveling(string URL, bool bItems)
{
   local string Skinz0r, Sounds, overlay, warmup, dd, TimedOver
   , TimedOverLength, grenadesonspawn;
   local array<string> Parts;
   local int i;

   class'xWeapons.ShockRifle'.default.FireModeClass[1]=Class'XWeapons.ShockProjFire';
   class'GrenadeAmmo'.default.InitialAmount = 4;
   class'xWeapons.AssaultRifle'.default.FireModeClass[0] = Class'xWeapons.AssaultFire';
   class'xWeapons.AssaultRifle'.default.FireModeClass[1] = Class'xWeapons.AssaultGrenade';

    class'xWeapons.BioRifle'.default.FireModeClass[0] = Class'xWeapons.BioFire';
    class'xWeapons.BioRifle'.default.FireModeClass[1] = Class'xWeapons.BioChargedFire';

    class'xWeapons.ShockRifle'.default.FireModeClass[0] = Class'xWeapons.ShockBeamFire';
    class'xWeapons.ShockRifle'.default.FireModeClass[1] = Class'xWeapons.ShockProjFire';

    class'xWeapons.LinkGun'.default.FireModeClass[0] = Class'xWeapons.LinkAltFire';
    class'xWeapons.LinkGun'.default.FireModeClass[1] = Class'xWeapons.LinkFire';

    class'xWeapons.MiniGun'.default.FireModeClass[0] = Class'xWeapons.MinigunFire';
    class'xWeapons.MiniGun'.default.FireModeClass[1] = Class'xWeapons.MinigunAltFire';

    class'xWeapons.FlakCannon'.default.FireModeClass[0] = Class'xWeapons.FlakFire';
    class'xWeapons.FlakCannon'.default.FireModeClass[1] = Class'xWeapons.FlakAltFire';

    class'xWeapons.RocketLauncher'.default.FireModeClass[0] = Class'xWeapons.RocketFire';
    class'xWeapons.RocketLauncher'.default.FireModeClass[1] = Class'xWeapons.RocketMultiFire';

    class'xWeapons.SniperRifle'.default.FireModeClass[0]= Class'xWeapons.SniperFire';
    class'UTClassic.ClassicSniperRifle'.default.FireModeClass[0]= Class'UTClassic.ClassicSniperFire';

    class'Onslaught.ONSMineLayer'.default.FireModeClass[0] = Class'Onslaught.ONSMineThrowFire';

    class'Onslaught.ONSGrenadeLauncher'.default.FireModeClass[0] =Class'UTCompvSrc.UTComp_ONSGrenadeFire';

    class'OnsLaught.ONSAvril'.default.FireModeClass[0] =Class'Onslaught.ONSAvrilFire';

    class'xWeapons.SuperShockRifle'.default.FireModeClass[0]=class'xWeapons.SuperShockBeamFire';
    class'xWeapons.SuperShockRifle'.default.FireModeClass[1]=class'xWeapons.SuperShockBeamFire';
    Split(Url, "?", Parts);

   for(i=0; i<Parts.Length; i++)
   {
       if(Parts[i]!="")
       {
           if(Left(Parts[i],Len("BrightSkinsMode"))~= "BrightSkinsMode")
               Skinz0r=Right(Parts[i], Len(Parts[i])-Len("BrightSkinsMode")-1);
           if(Left(Parts[i],Len("HitSoundsMode"))~= "HitSoundsMode")
               Sounds=Right(Parts[i], Len(Parts[i])-Len("HitSoundsMode")-1);
           if(Left(Parts[i],Len("EnableTeamOverlay"))~= "EnableTeamOverlay")
               Overlay=Right(Parts[i], Len(Parts[i])-Len("EnableTeamOverlay")-1);
           if(Left(Parts[i],Len("EnableWarmup"))~= "EnableWarmup")
               Warmup=Right(Parts[i], Len(Parts[i])-Len("EnableWarmup")-1);
           if(Left(Parts[i],Len("DoubleDamage"))~= "DoubleDamage")
               DD=Right(Parts[i], Len(Parts[i])-Len("DoubleDamage")-1);
           if(Left(Parts[i],Len("EnableTimedOverTime"))~= "EnableTimedOverTime")
               TimedOver=Right(Parts[i], Len(Parts[i])-Len("EnableTimedOverTime")-1);
           if(Left(Parts[i],Len("TimedOverTimeLength"))~= "TimedOverTimeLength")
               TimedOverLength=Right(Parts[i], Len(Parts[i])-Len("TimedOverTimeLength")-1);
           if(Left(Parts[i],Len("GrenadesOnSpawn"))~= "GrenadesOnSpawn")
               GrenadesOnSpawn=Right(Parts[i], Len(Parts[i])-Len("GrenadesOnSpawn")-1);
       }
   }
 //  Log("DD Value"$DD);
   if(Skinz0r !="" && int(Skinz0r)<4 && int(Skinz0r)>0)
       default.EnableBrightskinsMode=Int(Skinz0r);
   if(Sounds !="" && int(Sounds)<3 && int(Sounds)>=0)
       default.EnableHitsoundsMode=Int(Sounds);
   if(Overlay !="" && (Overlay~="False" || Overlay~="True"))
       default.bEnableTeamOverlay=Overlay~="True";
   if(Warmup !="" && (Warmup~="False" || Warmup~="True"))
       default.bEnableWarmup=(Warmup~="True");
   if(DD !="" && (DD~="False" || DD~="True"))
       default.bEnableDoubleDamage=(DD~="True");
   if(TimedOverLength !="" && int(TimedOverLength)>=0)
   {
       if(int(TimedOverLength) == 0)
          default.bEnableTimedOverTime=false;
       else
       {
          default.TimedOvertimeLength=60*Int(TimedOverLength);
          default.bEnableTimedOverTime=True;
       }
   }
   if(GrenadesOnSpawn !="" && int(GrenadesOnSpawn)<9 && int(GrenadesOnSpawn)>=0)
       default.NumGrenadesOnSpawn=Int(GrenadesOnSpawn);
   StaticSaveConfig();
   Super.ServerTraveling(url, bitems);
}

function AutoDemoRecord()
{
    if(class'UTCompvSrc.MutUTComp'.default.bEnableAutoDemorec)
    {
        ConsoleCommand("Demorec"@CreateAutoDemoRecName());
    }
    bDemoStarted=true;
}

function string CreateAutoDemoRecName()
{
    local string S;
    S=class'UTCompvSrc.MutUTComp'.default.AutoDemoRecMask;
    S=Repl(S, "%p", CreatePlayerString());
    S=Repl(S, "%t", CreateTimeString());
    S=StripIllegalWindowsCharacters(S);
    return S;
}

function string CreatePlayerString()
{
    local controller C;
    local array<string> RedPlayerNames;
    local array<string> BluePlayerNames;
    local string ReturnString;
    local int i;

    for(C=Level.ControllerList; C!=None; C=C.NextController)
    {
        if(PlayerController(C)!=None && C.PlayerReplicationInfo!=None && !C.PlayerReplicationInfo.bOnlySpectator && C.PlayerReplicationInfo.PlayerName!="")
        {
            if(C.GetTeamNum()==1)
                BluePlayerNames[BluePlayerNames.Length]=C.PlayerReplicationInfo.PlayerName;
            else
                RedPlayerNames[RedPlayerNames.Length]=C.PlayerReplicationInfo.PlayerName;
        }
    }

    if(BluePlayerNames.Length>0 && RedPlayerNames.Length>0)
    {
         ReturnString=BluePlayerNames[0];
         for(i=1; i<BluePlayerNames.Length && i<4; i++)
         {
             ReturnString$="-"$BluePlayerNames[i];
         }
         ReturnString$="-vs-"$RedPlayerNames[0];
         for(i=1; i<RedPlayerNames.Length && i<4; i++)
         {
             ReturnString$="-"$RedPlayerNames[i];
         }
    }
    else if(RedPlayerNames.Length>0)
    {
        ReturnString=RedPlayerNames[0];
        for(i=1; i<RedPlayerNames.Length && i<8; i++)
        {
            ReturnString$="-vs-"$RedPlayerNames[i];
        }
    }
    else if(BluePlayerNames.Length>0)
    {
         ReturnString=BluePlayerNames[0];
         for(i=1; i<BluePlayerNames.Length && i<4; i++)
         {
             ReturnString$="-"$BluePlayerNames[i];
         }
         returnString$="-vs-EmptyTeam";
    }
    returnstring=Left(returnstring, 100);
    return ReturnString;
}

function GetServerDetails( out GameInfo.ServerResponseLine ServerState )
{
    local int i;
    super.GetServerDetails(ServerState);

	i = ServerState.ServerInfo.Length;
	ServerState.ServerInfo.Length = i+1;
	ServerState.ServerInfo[i].Key = "UTComp_Version";
	ServerState.ServerInfo[i].Value = "Src";
}

function string CreateTimeString()
{
    local string hourdigits, minutedigits;

    if(Len(level.hour)==1)
        hourDigits="0"$Level.Hour;
    else
        hourDigits=Left(level.Hour, 2);
    if(len(level.minute)==1)
        minutedigits="0"$Level.Minute;
    else
        minutedigits=Left(Level.Minute, 2);

   return hourdigits$"-"$minutedigits;
}

simulated function string StripIllegalWindowsCharacters(string S)
{
   S=repl(S, ".", "-");
   S=repl(S, "*", "-");
   S=repl(S, ":", "-");
   S=repl(S, "|", "-");
   S=repl(S, "/", "-");
   S=repl(S, ";", "-");
   S=repl(S, "\\","-");
   S=repl(S, ">", "-");
   S=repl(S, "<", "-");
   S=repl(S, "+", "-");
   S=repl(S, " ", "-");
   S=repl(S, "?", "-");
   return S;
}

static function FillPlayInfo (PlayInfo PlayInfo)
{
	PlayInfo.AddClass(Default.Class);
    PlayInfo.AddSetting("UTComp Settings", "EnableBrightSkinsMode", "Brightskins Mode", 1, 1, "Select", "0;Disabled;1;Epic Style;2;BrighterEpic Style;3;UTComp Style ");
    PlayInfo.AddSetting("UTComp Settings", "EnableHitSoundsMode", "Hitsounds Mode", 1, 1, "Select", "0;Disabled;1;Line Of Sight;2;Everywhere");
    PlayInfo.AddSetting("UTComp Settings", "bEnableWarmup", "Enable Warmup", 1, 1, "Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableDoubleDamage", "Enable Double Damage", 1, 1, "Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableAutoDemoRec", "Enable Serverside Demo-Recording", 1, 1, "Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableTeamOverlay", "Enable Team Overlay", 1, 1, "Check");
    PlayInfo.AddSetting("UTComp Settings", "ServerMaxPlayers", "Voting Max Players",255, 1, "Text","2;0:32",,True,True);
    PlayInfo.AddSetting("UTComp Settings", "NumGrenadesOnSpawn", "Number of grenades on spawn.",255, 1, "Text","2;0:32",,True,True);

    PlayInfo.AddSetting("UTComp Settings", "bEnableVoting", "Enable Voting", 1, 1, "Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableBrightskinsVoting", "Allow players to vote on Brightskins settings.", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableWarmupVoting", "Allow players to vote on Warmup setting.", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableHitsoundsVoting", "Allow players to vote on Hitsounds settings.", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableTeamOverlayVoting", "Allow players to vote on team overlay setting", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableMapVoting", "Allow players to vote for map changes.", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "WarmupTime", "Warmup Time",1, 1, "Text","0;0:1800",,True,True);

    PlayInfo.PopClass();
    super.FillPlayInfo(PlayInfo);
}

static event string GetDescriptionText(string PropName)
{
	switch (PropName)
	{
		case "bEnableWarmup":	return "Check this to enable Warmup.";
		case "bEnableDoubleDamage":			return "Check this to enable the double damage.";
	    case "EnableBrightSkinsMode":   return "Sets the server-forced brightskins mode.";
	    case "EnableHitSoundsMode":  return "Sets the server-Forced hitsound mode.";
	    case "bEnableAutoDemoRec":  return "Check this to enable a recording of every map, beginning as warmup ends.";
        case "ServerMaxPlayers":  return "Set this to the maximum number of players you wish for to allow a client to vote for.";
        case "NumGrenadesOnSpawn":  return "Set this to the number of Assault Rifle grenades you wish a player to spawn with.";
        case "bEnableTeamOverlay": return "Check this to enable the team overlay.";
        case "bEnableVoting": return "Check this to enable voting.";
        case "bEnableBrightSkinsVoting": return "Check this to enable voting for brightskins.";
        case "bEnablehitsoundsVoting": return "Check this to enable voting for hitsounds.";
        case "bEnableTeamOverlayVoting": return "Check this to enable voting for Team Overlay.";
        case "bEnableWarmupVoting": return "Check this to enable voting for Warmup.";
        case "bEnableMapVoting": return "Check this to enable voting for Maps.";
        case "WarmupTime": return "Time for warmup. Set this to 0 for unlimited, otherwise it is the time in seconds.";
    }
	return Super.GetDescriptionText(PropName);
}

function bool ReplaceWith(actor Other, string aClassName)
{
	local Actor A;
	local class<Actor> aClass;

	if ( aClassName == "" )
		return true;

	aClass = class<Actor>(DynamicLoadObject(aClassName, class'Class'));
	if ( aClass != None )
		A = Spawn(aClass,Other.Owner,Other.tag,Other.Location, Other.Rotation);
	if ( Other.IsA('Pickup') )
	{
		if ( Pickup(Other).MyMarker != None )
		{
			Pickup(Other).MyMarker.markedItem = Pickup(A);
			if ( Pickup(A) != None )
			{
				Pickup(A).MyMarker = Pickup(Other).MyMarker;
				A.SetLocation(A.Location
					+ (A.CollisionHeight - Other.CollisionHeight) * vect(0,0,1));
			}
			Pickup(Other).MyMarker = None;
		}
		else if ( A.IsA('Pickup') && !A.IsA('WeaponPickup') )
			Pickup(A).Respawntime = 0.0;
	}
	if ( A != None )
	{
		A.event = Other.event;
		A.tag = Other.tag;
		return true;
	}
	return false;
}

function string GetInventoryClassOverride(string InventoryClassName)
{
	// here, in mutator subclass, change InventoryClassName if desired.  For example:
	// if ( InventoryClassName == "Weapons.DorkyDefaultWeapon"
	//		InventoryClassName = "ModWeapons.SuperDisintegrator"

    local int x;
    if(bEnhancedNetCodeEnabledAtStartOfMap)
    {
        for(x=0; x<ArrayCount(WeaponClassNames); x++)
        {
           if(InventoryClassName ~= WeaponClassNames[x])
           {
               return string(WeaponClasses[x]);
           }
        }
    }
    if ( NextMutator != None )
		return NextMutator.GetInventoryClassOverride(InventoryClassName);
	return InventoryClassName;
}


defaultproperties
{
     bAddToServerPackages=True
     bEnableVoting=True
     bEnableBrightskinsVoting=True
     bEnableHitsoundsVoting=True
     bEnableWarmupVoting=True
     bEnableTeamOverlayVoting=True
     bEnableMapVoting=True
     bEnableGametypeVoting=True
     VotingPercentRequired=51.000000
     VotingTimeLimit=30.000000
     benableDoubleDamage=True
     EnableBrightSkinsMode=3
     bEnableClanSkins=True
     bEnableTeamOverlay=True
     EnableHitSoundsMode=1
     bEnableScoreboard=True
     bEnableWarmup=True
     WarmupReadyPercentRequired=100.000000
     bEnableWeaponStats=True
     bEnablePowerupStats=True

     bShowTeamScoresInServerBrowser=True
     ServerMaxPlayers=12
     AlwaysUseThisMutator(0)="UTCompvSrc.mututcomp"
     AutoDemoRecMask="%d-(%t)-%m-%p"
     EnableWarmupWeaponsMode=1
     WarmupHealth=199

     VotingGametype(0)=(GametypeOptions="?game=XGame.xDeathMatch?timelimit=15?minplayers=0?goalscore=0?Mutator=XWeapons.MutNoSuperWeapon,XGame.MutNoAdrenaline?weaponstay=False?DoubleDamage=False?GrenadesOnSpawn=4?TimedOverTimeLength=0",GametypeName="1v1")
     VotingGametype(1)=(GametypeOptions="?game=XGame.xDeathMatch?timelimit=15?minplayers=0?goalscore=50?weaponstay=True?DoubleDamage=True?GrenadesOnSpawn=4?TimedOverTimeLength=0",GametypeName="FFA")
     VotingGametype(2)=(GametypeOptions="?game=XGame.xTeamGame?timelimit=20?goalscore=0?minplayers=0?Mutator=XWeapons.MutNoSuperWeapon?FriendlyfireScale=1.00?weaponstay=False?DoubleDamage=True?GrenadesOnSpawn=1?TimedOverTimeLength=5",GametypeName="Team Deathmatch")
     VotingGametype(3)=(GametypeOptions="?game=XGame.xCTFGame?timelimit=20?goalscore=0?minplayers=0?mutator=XGame.MutNoAdrenaline,XWeapons.MutNoSuperWeapon?friendlyfirescale=0?weaponstay=true?DoubleDamage=True?GrenadesOnSpawn=4?TimedOverTimeLength=0",GametypeName="Capture the Flag")
     VotingGametype(4)=(GametypeOptions="?game=Onslaught.ONSOnslaughtGame?timelimit=20?goalscore=1?mutator=XWeapons.MutNoSuperWeapon?minplayers=0?friendlyfirescale=0?weaponstay=True?DoubleDamage=True?GrenadesOnSpawn=4?TimedOverTimeLength=0",GametypeName="Onslaught")
     VotingGametype(5)=(GametypeOptions="?game=UTCompvSrc.UTComp_ClanArena?goalscore=7?TimeLimit=2?FriendlyFireScale=0?GrenadesOnSpawn=4?TimedOverTimeLength=0",GametypeName="Clan Arena")
     VotingGametype(6)=(GametypeOptions="?game=UT2k4Assault.ASGameInfo?timelimit=20?goalscore=1?FriendlyFireScale=0,WeaponStay=True?mutator=XWeapons.MutNoSuperWeapon?DoubleDamage=True?GrenadesOnSpawn=4?TimedOverTimeLength=0",GametypeName="Assault")
     VotingGametype(7)=(GametypeOptions="?game=XGame.xDoubleDom?timelimit=20?goalscore=0?FriendlyFireScale=0,WeaponStay=True?mutator=XWeapons.MutNoSuperWeapon?DoubleDamage=True?GrenadesOnSpawn=4?TimedOverTimeLength=0",GametypeName="Double Domination")
     VotingGametype(8)=(GametypeOptions="?game=XGame.xBombingRun?timelimit=20?goalscore=0?FriendlyFireScale=0,WeaponStay=True?mutator=XWeapons.MutNoSuperWeapon?DoubleDamage=True?GrenadesOnSpawn=4?TimedOverTimeLength=0",GametypeName="Bombing Run")


     FriendlyName="UTComp Version Src"
     Description="A mutator for warmup, brightskins, hitsounds, and various other features."
     bNetTemporary=True
     bAlwaysRelevant=True
     RemoteRole=ROLE_SimulatedProxy
     bEnableAdvancedVotingOptions=True
     bForceMapVoteMatchPrefix=True
     TimedOverTimeLength=300
     bEnableTimedOvertimeVoting=True
     NumGrenadesOnSpawn = 4
     bEnableEnhancedNetCode = false
     bEnableEnhancedNetCodeVoting = true

      WeaponClasses(0)=Class'UTCompvSrc.NewNet_ShockRifle'
     WeaponClasses(1)=Class'UTCompvSrc.NewNet_LinkGun'
     WeaponClasses(2)=Class'UTCompvSrc.NewNet_MiniGun'
     WeaponClasses(3)=Class'UTCompvSrc.NewNet_FlakCannon'
     WeaponClasses(4)=Class'UTCompvSrc.NewNet_RocketLauncher'
     WeaponClasses(5)=Class'UTCompvSrc.NewNet_SniperRifle'
     WeaponClasses(6)=Class'UTCompvSrc.NewNet_BioRifle'
     WeaponClasses(7)=Class'UTCompvSrc.NewNet_AssaultRifle'
     WeaponClasses(8)=Class'UTCompvSrc.NewNet_ClassicSniperRifle'
     WeaponClasses(9)=Class'UTCompvSrc.NewNet_ONSAVRiL'
     WeaponClasses(10)=Class'UTCompvSrc.NewNet_ONSMineLayer'
     WeaponClasses(11)=Class'UTCompvSrc.NewNet_ONSGrenadeLauncher'
     WeaponClassNames(0)="xWeapons.ShockRifle"
     WeaponClassNames(1)="xWeapons.LinkGun"
     WeaponClassNames(2)="xWeapons.MiniGun"
     WeaponClassNames(3)="xWeapons.FlakCannon"
     WeaponClassNames(4)="xWeapons.RocketLauncher"
     WeaponClassNames(5)="xWeapons.SniperRifle"
     WeaponClassNames(6)="xWeapons.BioRifle"
     WeaponClassNames(7)="xWeapons.AssaultRifle"
     WeaponClassNames(8)="UTClassic.ClassicSniperRifle"
     WeaponClassNames(9)="Onslaught.ONSAVRiL"
     WeaponClassNames(10)="Onslaught.ONSMineLayer"
     WeaponClassNames(11)="Onslaught.ONSGrenadeLauncher"
     ReplacedWeaponClasses(0)=Class'XWeapons.ShockRifle'
     ReplacedWeaponClasses(1)=Class'XWeapons.LinkGun'
     ReplacedWeaponClasses(2)=Class'XWeapons.Minigun'
     ReplacedWeaponClasses(3)=Class'XWeapons.FlakCannon'
     ReplacedWeaponClasses(4)=Class'XWeapons.RocketLauncher'
     ReplacedWeaponClasses(5)=Class'XWeapons.SniperRifle'
     ReplacedWeaponClasses(6)=Class'XWeapons.BioRifle'
     ReplacedWeaponClasses(7)=Class'XWeapons.AssaultRifle'
     ReplacedWeaponClasses(8)=Class'UTClassic.ClassicSniperRifle'
     ReplacedWeaponClasses(9)=Class'Onslaught.ONSAVRiL'
     ReplacedWeaponClasses(10)=Class'Onslaught.ONSMineLayer'
     ReplacedWeaponClasses(11)=Class'Onslaught.ONSGrenadeLauncher'
     ReplacedWeaponPickupClasses(0)=Class'XWeapons.ShockRiflePickup'
     ReplacedWeaponPickupClasses(1)=Class'XWeapons.LinkGunPickup'
     ReplacedWeaponPickupClasses(2)=Class'XWeapons.MinigunPickup'
     ReplacedWeaponPickupClasses(3)=Class'XWeapons.FlakCannonPickup'
     ReplacedWeaponPickupClasses(4)=Class'XWeapons.RocketLauncherPickup'
     ReplacedWeaponPickupClasses(5)=Class'XWeapons.SniperRiflePickup'
     ReplacedWeaponPickupClasses(6)=Class'XWeapons.BioRiflePickup'
     ReplacedWeaponPickupClasses(7)=Class'XWeapons.AssaultRiflePickup'
     ReplacedWeaponPickupClasses(8)=Class'UTClassic.ClassicSniperRiflePickup'
     ReplacedWeaponPickupClasses(9)=Class'Onslaught.ONSAVRiLPickup'
     ReplacedWeaponPickupClasses(10)=Class'Onslaught.ONSMineLayerPickup'
     ReplacedWeaponPickupClasses(11)=Class'Onslaught.ONSGrenadePickup'
     WeaponPickupClasses(0)=Class'UTCompvSrc.NewNet_ShockRiflePickup'
     WeaponPickupClasses(1)=Class'UTCompvSrc.NewNet_LinkGunPickup'
     WeaponPickupClasses(2)=Class'UTCompvSrc.NewNet_MiniGunPickup'
     WeaponPickupClasses(3)=Class'UTCompvSrc.NewNet_FlakCannonPickup'
     WeaponPickupClasses(4)=Class'UTCompvSrc.NewNet_RocketLauncherPickup'
     WeaponPickupClasses(5)=Class'UTCompvSrc.NewNet_SniperRiflePickup'
     WeaponPickupClasses(6)=Class'UTCompvSrc.NewNet_BioRiflePickup'
     WeaponPickupClasses(7)=Class'UTCompvSrc.NewNet_AssaultRiflePickup'
     WeaponPickupClasses(8)=Class'UTCompvSrc.NewNet_ClassicSniperRiflePickup'
     WeaponPickupClasses(9)=Class'UTCompvSrc.NewNet_ONSAVRiLPickup'
     WeaponPickupClasses(10)=Class'UTCompvSrc.NewNet_ONSMineLayerPickup'
     WeaponPickupClasses(11)=Class'UTCompvSrc.NewNet_ONSGrenadePickup'
     WeaponPickupClassNames(0)="UTCompvSrc.NewNet_ShockRiflePickup"
     WeaponPickupClassNames(1)="UTCompvSrc.NewNet_LinkGunPickup"
     WeaponPickupClassNames(2)="UTCompvSrc.NewNet_MiniGunPickup"
     WeaponPickupClassNames(3)="UTCompvSrc.NewNet_FlakCannonPickup"
     WeaponPickupClassNames(4)="UTCompvSrc.NewNet_RocketLauncherPickup"
     WeaponPickupClassNames(5)="UTCompvSrc.NewNet_SniperRiflePickup"
     WeaponPickupClassNames(6)="UTCompvSrc.NewNet_BioRiflePickup"
     WeaponPickupClassNames(7)="UTCompvSrc.NewNet_AssaultRiflePickup"
     WeaponPickupClassNames(8)="UTCompvSrc.NewNet_ClassicSniperRiflePickup"
     WeaponPickupClassNames(9)="UTCompvSrc.NewNet_ONSAVRiLPickup"
     WeaponPickupClassNames(10)="UTCompvSrc.NewNet_ONSMineLayerPickup"
     WeaponPickupClassNames(11)="UTCompvSrc.NewNet_ONSGrenadePickup"
}
