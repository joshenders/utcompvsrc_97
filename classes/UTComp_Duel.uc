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

class UTComp_Duel extends xDeathMatch;


var config float WarmupTime;
var config bool bEnableDoubleDamage;


var config string DesiredPlayerID, OtherDesiredPlayerID;
var config array<string> SavedLineID;
var config bool bAreWaitingOnSavedPlayers;

var array<float> FORCEINTime;
var array<PlayerController> PlayerToForceIn;
const FORCEINWAIT = 0.5;

var array<float> FORCEOUTTime;
var array<PlayerController> PlayerToForceOut;
const FORCEOUTWAIT = 0.5;

var config bool bTagServer;

var Array<PlayerController> Line;

var bool bWaitingOnRestart;
var float RestartTime;

const MAPRESTARTWAIT = 5.0;
const SHORTMAPRESTARTWAIT =  2.0;

var PlayerController Loser;

const WAITFORPLAYERSTIME = 60;
var float WaitingTime;
var float LastPrintTime;

var UTComp_ServerReplicationInfo repinfo;

event PlayerController Login
(
    string Portal,
    string Options,
    out string Error
)
{
   local bool bForcedPlayerToSpec;
   local PlayerController NewPlayer;

   if(ShouldForceNewPlayerToSpec())
   {
      Options = "?SpectatorOnly=1"$Options;
      bForcedPlayerToSpec=True;
   }
   else if(numPlayers==0 && !bAreWaitingOnSavedPlayers)
   {
       Options = "?SpectatorOnly=0"$Options;
   }
   NewPlayer=Super.Login(Portal, Options, Error);

   if(bForcedPlayerToSpec && NewPlayer !=None && ShouldntHaveForcedToSpec(NewPlayer) )
   {
       NewPlayer.PlayerReplicationInfo.bOnlySpectator = false;
       NewPlayer.PlayerReplicationInfo.bIsSpectator = false;
       NewPlayer.PlayerReplicationInfo.bOutOfLives = false;
       NumSpectators--;
       NumPlayers++;
   }
   else if(bForcedPlayerToSpec && NewPlayer != None)
   {
       AddNewPlayerToLine(NewPlayer);
   }
   if(NewPlayer.PlayerReplicationInfo!=None && !NewPlayer.PlayerReplicationInfo.bOnlySpectator)
       SetRestartTime();
   return NewPlayer;
}

event InitGame( string Options, out string Error )
{
   super.InitGame(Options, Error);
   MaxSpectators=MaxPlayers;
   AddMutator("UTCompvSrc.MutUTComp");
}

function bool BecomeSpectator(PlayerController P)
{
    local bool b;

    b=(Line.Length>0 && super.BecomeSpectator(P));

    if(b)
    {
        PutPlayerAtEndOfList(P);
        if(!bAreWaitingOnSavedPlayers)
            ForceInNewPlayer();
     //   SetShortRestartTime();
    }
  //  else
  //      P.ClientMessage("Sorry, there is noone to take your place in the game.");

    return b;
}

function bool AllowBecomeActivePlayer(PlayerController P)
{
    local bool b;
    b = (numPlayers < 2 && ThisPlayerCanJoin(P) && GameInfoBecomeActive(P));
    if(b)
    {
        RemovePlayerFromLine(P);
        SetShortRestartTime();
    }
    else
    {
     /*   P.ClientMessage("Sorry, you can't become an active player right now");
        if(P.PlayerReplicationInfo == none)
        P.ClientMessage("Denied due to no PRI");
        if(!GameReplicationInfo.bMatchHasBegun)
        P.ClientMessage("Denied to to match not started");
        if(bMustJoinBeforeStart)
        P.ClientMessage("Denied due to bMustJoinBeforeStart");
        if((NumPlayers >= MaxPlayers))
        P.ClientMessage("Denied due to too many players ingame");
        if((MaxLives > 0))
        P.ClientMessage("Denied due to maxlives > 0");
        if(P.IsInState('GameEnded'))
        P.ClientMessage("Denied due to being in state gameended");
        if(P.IsInState('RoundEnded'))
        P.ClientMessage("Denied due to being in state Roundended"); */
    }
    return b;
}

function bool AtCapacity(bool bSpectator)
{
    return ( NumPlayers + NumSpectators >= MaxPlayers);
}

function bool GameInfoBecomeActive(Playercontroller P)
{
	if ( (P.PlayerReplicationInfo == None) || !GameReplicationInfo.bMatchHasBegun || bMustJoinBeforeStart
	     || (NumPlayers >= MaxPlayers) || (MaxLives > 0) || P.IsInState('RoundEnded') )
	{
		P.ReceiveLocalizedMessage(GameMessageClass, 13);
		return false;
	}
	return true;
}

//c/p
function bool DeathMatchBecomeActive(PlayerController P)
{
    if ( GameInfoBecomeActive(P) )
	{
		if ( (Level.NetMode == NM_Standalone) && (NumBots > InitialBots) )
		{
			RemainingBots--;
			bPlayerBecameActive = true;
		}
		return true;
	}
	return false;
}

function bool ThisPlayerCanJoin(PlayerController PC)
{
    local string ID;
    if(!bAreWaitingOnSavedPlayers)
        return true;
    ID=GetID(PC);
    return (ID==DesiredPlayerID || ID==OtherDesiredPlayerID);
}

function PutPlayerAtEndOfList(PlayerController PC)
{
    local int i;

    for(i=0; i<Line.Length; i++)
    {
       if(PC==Line[i])
          Line.Remove(i,1);
    }
    Line[Line.Length]=PC;
    ReplicateList();
}

function SetupForceIn(PlayerController NewPlayer)
{
    ForceInTime[ForceInTime.Length]=Level.TimeSeconds + FORCEINWAIT;
    PlayerToForceIn[PlayerToForceIn.Length]=NewPlayer;
}

function SetupForceOut(PlayerController NewPlayer)
{
    ForceOutTime[ForceOutTime.Length]=Level.TimeSeconds + FORCEOUTWAIT;
    PlayerToForceOut[PlayerToForceOut.Length]=NewPlayer;
}

function bool ShouldForceNewPlayerToSpec()
{
    if(bAreWaitingOnSavedPlayers || NumPlayers > 1)
        return true;
    return false;
}

function bool ShouldntHaveForcedToSpec(PlayerController PC)
{
    local string ID;
    ID=GetID(PC);
    if(bAreWaitingOnSavedPlayers && (ID==DesiredPlayerID || ID==OtherDesiredPlayerID))
        return true;
    return false;
}

function string GETID(PlayerController PC)
{
   return PC.PlayerReplicationInfo.PlayerName;
}

function AddNewPlayerToLine(PlayerController NewPlayer)
{
 //   local int i;
 /*   for(i=0; i<Line.Length; i++)
    {
       if(NewPlayer==Line[i]);
           Line.Remove(i,1);
    }  */
    Line[Line.Length]=NewPlayer;
    ReplicateList();
}

function RemovePlayerFromLine(PlayerController NewPlayer)
{
    local int i;
    for(i=0; i<Line.Length; i++)
    {
        if(NewPlayer==Line[i])
            Line.Remove(i,1);
    }
    ReplicateList();
}

function Logout( Controller Exiting )
{
   super.Logout(Exiting);
   if(Exiting.IsA('PlayerController'))
   {
       RemovePlayerFromLine(PlayerController(Exiting));
       ForceInNewPlayer();
   }
}

function bool CheckEndGame(PlayerReplicationInfo Winner, string Reason)
{
    local bool b;
    local controller C;

    b=Super.CheckEndGame(Winner, Reason);
    if(b)
    {
     //   Log("Setting restart due to end-game");
        if ( Winner == None )
	    {
		// find winner
		    for ( C=Level.ControllerList; C!=None; C=C.nextController )
			    if ( C.bIsPlayer && !C.PlayerReplicationInfo.bOutOfLives
				    && ((Winner == None) || (C.PlayerReplicationInfo.Score >= Winner.Score)) )
			    {
				    Winner = C.PlayerReplicationInfo;
			    }
	    }
        SetRestartTime();
        for(C=Level.ControllerList; C!=None; C=C.NextController)
        {
            if(PlayerController(C)!=None && C.PlayerReplicationInfo!=None && !C.PlayerReplicationInfo.bOnlySpectator && C.PlayerReplicationInfo!=Winner)
            {
                Loser=PlayerController(C);
            //    Log("Loser is:  "@c.PlayerReplicationInfo.PlayerName);
            }
        }
    }
    return b;
}

function SetRestartTime()
{
   bWaitingOnRestart=True;
   RestartTime=Level.TimeSeconds + MAPRESTARTWAIT;
}

function SetShortRestartTime()
{
   bWaitingOnRestart=True;
   RestartTime=Level.TimeSeconds + SHORTMAPRESTARTWAIT;
}

function ForceInNewPlayer()
{
    if(NumPlayers==0)
    if(Line.Length > 1)
    {
       SetupForceIn(Line[1]);
    }
    if(Line.Length > 0)
    {
        SetupForceIn(Line[0]);
    }
}

function Tick(Float DeltaTime)
{
    super.Tick(DeltaTime);
    if(PlayerToForceOut.Length>0 && ForceOutTime.Length>0 && Level.TimeSeconds > ForceOutTime[0])
    {
       ForcePlayerOut();
    }
    else if(PlayerToForceIn.Length>0 && ForceInTime.Length>0 && Level.TimeSeconds > ForceInTime[0])
    {
       ForcePlayerIn();
    }
    else if(bWaitingOnRestart && Level.TimeSeconds > RestartTime)
    {
        ForceOutLoser();
        ForceInNewPlayer();
        RestartMap();
        bWaitingOnRestart=False;
    }
    if(bAreWaitingOnSavedPlayers && WaitingTime==0.0)
    {
         WaitingTime=Level.TimeSeconds + WAITFORPLAYERSTIME;
    }
    else if(bAreWaitingOnSavedPlayers && Level.TimeSeconds > WaitingTime )
    {
         EndWaiting();
    }
   /* else if(Level.TimeSeconds>LastPrintTime)
    {
        PrintList();
        LastPrintTime=Level.TimeSeconds+30.0;
    }   */
}

function PrintList()
{
   local int i;
   Log("-----GUID List-----");
   for(i=0; i<line.length; i++)
   {
       Log(GetID(Line[i]));
   }
   Log("-----End guid List-----");
}

function EndWaiting()
{
   bAreWaitingOnSavedPlayers=False;
   default.bAreWaitingOnSavedPlayers=False;
   staticsaveconfig();
   ReplaceOldLineWithNewLine();
   ForceInNewPlayer();
}

function ReplaceOldLineWithNewLine()
{
    local array<PlayerController> TempLine;
    local int i, j;
    local string ID;
    local bool bFound;

  /*  Log("-----Saved List Names -----");
    for(i=0; i<SavedLineID.Length; i++)
    Log(SavedLineID[i]);
    Log("------End Saved List -----");
    Log("");
    Log("-------Current List------");
    PrintList();      */

    TempLine.Length=Line.Length;
    for(i=0; i<Line.Length; i++)
    {
       TempLine[i]=Line[i];
    }
    Line.Remove(0,Line.Length);
 //   Log("---This Should Print No Names---");
 //   PrintList();
    for(j=0; j<SavedLineID.Length; j++)
    {
    //   Log("Searching for"@SavedLineID[j]);
       for(i=0; i<TempLine.Length; i++)
       {
          ID=GetID(TempLine[i]);
          if(ID==SavedLineID[j])
          {
        //     Log("Adding saved player"@ID@"To List");
             Line[Line.Length]=TempLine[i];
             TempLine.Remove(i,1);
             bFound=True;
             break;
          }
       }
    //   if(!bFound)
      //    Log("Didnt Find Player"@SavedLineID[j]);
    }
    for(i=0; i<TempLine.Length; i++)
    {
        Line[Line.Length]=TempLine[i];
    }

  //  Log("-----Done Swapping Lists -----");
    //PrintList();
    ReplicateList();
}

function ForceOutLoser()
{
    if(Loser!=None)
    {
        SetupForceOut(Loser);
    }
    Loser=None;
}

function RestartMap()
{
   local UTComp_Warmup uWarmup;

   foreach AllActors(class'UTComp_Warmup', uWarmup)
   {
      uWarmup.SoftRestart();
      break;
   }
}

/*function EndGame( PlayerReplicationInfo Winner, string Reason )
{
    // don't end game if not really ready
    if ( !CheckEndGame(Winner, Reason) )
    {
        bOverTime = true;
        return;
    }

  //  bGameEnded = true;
  //  TriggerEvent('EndGame', self, None);
  //  EndLogging(Reason);
} */

function ForcePlayerIn()
{
    PlayerToForceIn[0].BecomeActivePlayer();

 //   RemovePlayerFromLine(PlayerToForceIn[0]);
    PlayerToForceIn.Remove(0,1);
    ForceInTime.Remove(0,1);
}

function ForcePlayerOut()
{
    PlayerToForceOut[0].BecomeSpectator();

  //  AddNewPlayerToLine(PlayerToForceOut[0]);
    PlayerToForceOut.Remove(0,1);
    ForceOutTime.Remove(0,1);
}

function GetServerInfo( out ServerResponseLine ServerState )
{
	super.GetServerInfo(ServerState);
	ServerState.MaxPlayers = 2;
	ServerState.GameType = Mid( string(Class'xDeathMatch'), InStr(string(Class'xDeathMatch'), ".")+1);
	if(bTagServer)
        ServerState.ServerName = "[DUEL]"@ServerState.ServerName;
}

function GetServerDetails( out ServerResponseLine ServerState )
{
    local int i;
    super.GetServerDetails(ServerState);

	i = ServerState.ServerInfo.Length;
	ServerState.ServerInfo.Length = i+1;
	ServerState.ServerInfo[i].Key = "Line_Spots_Remaining";
	ServerState.ServerInfo[i].Value = string(MaxPlayers-NumPlayers-NumSpectators);
}

function ProcessServerTravel( string URL, bool bItems )
{
   local controller C;
   local bool bFound;
   local int i;

   super.ProcessServerTravel(URl, bItems);
   default.OtherDesiredPlayerID="";
   default.DesiredPlayerID="";
   default.SavedLineID.Remove(0,default.SavedLineID.Length);
   for(C=Level.ControllerList; C!=None; C=C.NextController)
   {
      if(bFound && PlayerController(C)!=None && !C.PlayerReplicationInfo.bOnlySpectator)
      {
          default.OtherDesiredPlayerID=GetID(PlayerController(C));
          break;
      }
      if(!bFound && PlayerController(C)!=None && !C.PlayerReplicationInfo.bOnlySpectator)
      {
          default.DesiredPlayerID=GetID(PlayerController(C));
          bFound=True;
      }
   }
   for(i=0; i<Line.Length; i++)
   {
      default.SavedLineID[i]=GetID(Line[i]);
   }
   if(bFound)
       default.bAreWaitingOnSavedPlayers=True;
   StaticSaveConfig();
}

function PlayerReplicationInfo GetPRI(PlayerController PC)
{
   return PC.PlayerReplicationInfo;
}

function ReplicateList()
{
    local int i;

    if(RepInfo==None)
       foreach DynamicActors(class'UTComp_ServerReplicationInfo', RepInfo)
          break;
    for(i=0; i<ArrayCount(RepInfo.LinePRI); i++)
    {
        RepInfo.LinePRI[i]=None;
    }
    for(i=0; i<Line.Length && i<Arraycount(RepInfo.LinePRI); i++)
       RepInfo.LinePRI[i]=getPRI(Line[i]);

}

defaultproperties
{
   WarmupTime=120
   GameName="UTComp Duel(Src)"
   bEnableDoubleDamage=False;
   ScoreBoardType="UTCompvSrc.UTComp_Duel_ScoreBoard"
   Description="1v1-Kill or be killed! Winner stays, loser goes to the end of the line!"
   bForceRespawn=True
   TimeLimit=15
   GoalScore=0
   bTagServer = true
}
