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

class UTComp_Scoreboard_Mutant extends UTComp_ScoreBoardDM;


var()	Material	BottomFeederMarker;
var()	Material	MutantMarker;

function ExtraMarking(Canvas Canvas, int PlayerCount, int OwnerOffset, int XPos, int YPos, int YOffset)
{
	local int i, OwnerPos;
	local float IconScale;
	local MutantGameReplicationInfo MutantInfo;

	MutantInfo = MutantGameReplicationInfo(GRI);

	// draw mutant and BF marker
	IconScale = Canvas.ClipX/1024;
	Canvas.DrawColor = HUDClass.default.WhiteColor;
	Canvas.Style = ERenderStyle.STY_Normal;

	for ( i=0; i<PlayerCount; i++ )
	{
		// If this is the bottom feeder
		if( MutantInfo.BottomFeederPRI == GRI.PRIArray[i] )
		{
			Canvas.SetPos(XPos - 64*IconScale, YPos*i + YOffset - 16*IconScale);
			Canvas.DrawTile( BottomFeederMarker, 64*IconScale, 64*IconScale, 0, 0, 256, 256);
		}

		// If this is the mutant (should never be able to be both!!!)
		if( MutantInfo.MutantPRI == GRI.PRIArray[i] )
		{
			Canvas.SetPos(XPos - 64*IconScale, YPos*i + YOffset);
			Canvas.DrawTile( MutantMarker, 64*IconScale, 32*IconScale, 0, 0, 256, 128);
		}
	}

	if ( OwnerOffset >= PlayerCount )
	{
		OwnerPos = YPos*PlayerCount + YOffset;

		// Mutant/Bottom Feeder marker for owner
		if( MutantInfo.BottomFeederPRI == GRI.PRIArray[OwnerOffset] )
		{
			Canvas.SetPos(XPos - 64*IconScale, OwnerPos - 16*IconScale);
			Canvas.DrawTile( BottomFeederMarker, 64*IconScale, 64*IconScale, 0, 0, 256, 256);
		}

		if( MutantInfo.MutantPRI == GRI.PRIArray[OwnerOffset] )
		{
			Canvas.SetPos(XPos - 64*IconScale, OwnerPos);
			Canvas.DrawTile( MutantMarker, 64*IconScale, 32*IconScale, 0, 0, 256, 128);
		}
	}
}

defaultproperties
{
	BottomFeederMarker=Material'MutantSkins.BFeeder_icon'
	MutantMarker=Material'MenuEffects.ScoreboardU_FB'
}

