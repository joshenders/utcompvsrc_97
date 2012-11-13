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

class UTV_BS_xPlayer extends BS_xPlayer;

var string utvOverideUpdate;
var string utvFreeFlight;
var string utvLastTargetName;
var string utvPos;


function LongClientAdjustPosition
(
    float TimeStamp,
    name newState,
    EPhysics newPhysics,
    float NewLocX,
    float NewLocY,
    float NewLocZ,
    float NewVelX,
    float NewVelY,
    float NewVelZ,
    Actor NewBase,
    float NewFloorX,
    float NewFloorY,
    float NewFloorZ
)
{
	local Actor myTarget;

	Super.LongClientAdjustPosition(TimeStamp, newState, newPhysics, NewLocX,NewLocY,NewLocZ,NewVelX,newVelY, newVelZ, NewBase, NewFloorX, NewFloorY, NewFloorZ);

//	ClientMessage(getstatename());
	if(utvOverideUpdate=="true"){
		bUpdatePosition=false;
//		ClientMessage("Adjust position overridden by utvreplication");
		if(utvFreeFlight=="true"){
			bBehindView=false;
			SetViewTarget(self);
			SetLocation(vector(utvPos));
			if(pawn!=none){
				Pawn.SetLocation(vector(utvPos));
			}
		} else {
			target=GetPawnFromName(utvLastTargetName);
			if(myTarget!=none)
				SetViewTarget(myTarget);
		}
	}
}

simulated function Pawn GetPawnFromName(string name)
{
	local Pawn tempPawn;

	foreach AllActors(class'Pawn',tempPawn){
		if(tempPawn.PlayerReplicationInfo!=none && tempPawn.PlayerReplicationInfo.PlayerName==name){
			return tempPawn;
			break;
		}
	}
	return none;
}

state Spectating
{
    simulated function PlayerMove(float DeltaTime)
    {
		local Actor myTarget;

		if(utvOverideUpdate=="true" && !(utvFreeFlight=="true")){
			myTarget=GetPawnFromName(utvLastTargetName);
			if(myTarget!=none){
				SetViewTarget(myTarget);
				TargetViewRotation=myTarget.rotation;
			}
		}
		Super.PlayerMove(DeltaTime);
	}
}

defaultproperties
{
     utvOverideUpdate="false"
     utvFreeFlight="false"
     bAllActorsRelevant=True
}
