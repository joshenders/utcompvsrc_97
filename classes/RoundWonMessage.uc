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
//
//-----------------------------------------------------------
class RoundWonMessage extends CriticalEventPlus;

var() localized string RedWon;
var() localized string BlueWon;

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    if(Switch==0)
        return default.RedWon;
    else if(Switch==1)
        return default.BlueWon;
}

static function ClientReceive(
    PlayerController P,
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    super.ClientReceive(P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);

    if(Switch == 0)
		P.QueueAnnouncement( 'red_team_wins_the_round', 1);
    else if(Switch == 1)
		P.QueueAnnouncement( 'blue_team_wins_the_round', 1);

}


DefaultProperties
{
    RedWon="The red team has won the round!"
    BlueWon="The blue team has won the round!"
     DrawColor=(B=0,G=255,R=255)
     StackMode=SM_Down
     PosY=0.850000
     FontSize=0
     bIsConsoleMessage=False
}
