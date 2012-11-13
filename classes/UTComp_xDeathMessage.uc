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

class UTComp_xDeathMessage extends xDeathMessage;

var config bool drawcolorednamesindeathmessages;
var config bool bEnableTeamColoredDeaths;

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	local string KillerName, VictimName;
	local UTComp_PRI uPRI;

	if (Class<DamageType>(OptionalObject) == None)
		return "";

	uPRI=class'UTComp_Util'.Static.GetUTCompPRI(RelatedPRI_2);

    if (RelatedPRI_2 == None)
		VictimName = Default.SomeoneString;
    else if(default.bEnableTeamColoredDeaths)
    {
        if(RelatedPRI_2.Team!=None && RelatedPRI_2.Team.TeamIndex == 0)
            VictimName = MakeColorCode(class'BS_xPlayer'.default.RedMessageColor)$RelatedPRI_2.PlayerName$MakeColorCode(class'HUD'.Default.GreenColor);
        else if(RelatedPRI_2.Team!=None && RelatedPRI_2.Team.TeamIndex == 1)
            VictimName = MakeColorCode(class'BS_xPlayer'.default.BlueMessageColor)$RelatedPRI_2.PlayerName$MakeColorCode(class'HUD'.Default.GreenColor);
        else
            VictimName = MakeColorCode(class'Hud'.default.WhiteColor)$RelatedPRI_2.PlayerName$MakeColorCode(class'HUD'.Default.GreenColor);
    }
    else if(default.drawcolorednamesindeathmessages)
	{
    	if(uPRI!=None && uPRI.ColoredName!="")
            VictimName = uPRI.ColoredName$MakeColorCode(class'HUD'.Default.GreenColor);
        else
            VictimName = MakeColorCode(class'Hud'.default.WhiteColor)$RelatedPRI_2.PlayerName$MakeColorCode(class'HUD'.Default.GreenColor);
    }
    else
        VictimName = RelatedPRI_2.PlayerName;
	if ( Switch == 1 )
	{
		// suicide
		return class'GameInfo'.Static.ParseKillMessage(
			KillerName,
			VictimName,
			Class<DamageType>(OptionalObject).Static.SuicideMessage(RelatedPRI_2) );
	}

	uPRI=class'UTComp_Util'.Static.GetUTCompPRI(RelatedPRI_1);

    if (RelatedPRI_1 == None)
		KillerName = Default.SomeoneString;
    else if(default.bEnableTeamColoredDeaths)
    {
        if(RelatedPRI_1.Team!=None && RelatedPRI_1.Team.TeamIndex == 0)
            KillerName = MakeColorCode(class'BS_xPlayer'.default.RedMessageColor)$RelatedPRI_1.PlayerName$MakeColorCode(class'HUD'.Default.GreenColor);
        else if(RelatedPRI_1.Team!=None && RelatedPRI_1.Team.TeamIndex == 1)
            KillerName = MakeColorCode(class'BS_xPlayer'.default.BlueMessageColor)$RelatedPRI_1.PlayerName$MakeColorCode(class'HUD'.Default.GreenColor);
        else
            KillerName = MakeColorCode(class'Hud'.default.WhiteColor)$RelatedPRI_1.PlayerName$MakeColorCode(class'Hud'.default.GreenColor);
    }
    else if(default.drawcolorednamesindeathmessages)
	{
        if(uPRI!=None && uPRI.ColoredName!="")
            KillerName = uPRI.ColoredName$MakeColorCode(class'HUD'.Default.GreenColor);
        else
            KillerName=MakeColorCode(class'Hud'.default.WhiteColor)$RelatedPRI_1.PlayerName$MakeColorCode(class'HUD'.Default.GreenColor);
    }
    else
        KillerName = RelatedPRI_1.PlayerName;

	return class'GameInfo'.Static.ParseKillMessage(
		KillerName,
		VictimName,
		Class<DamageType>(OptionalObject).Static.DeathMessage(RelatedPRI_1, RelatedPRI_2) );
}

static function string MakeColorCode(color NewColor)
{
    // Text colours use 1 as 0.
    if(NewColor.R == 0)
        NewColor.R = 1;

    if(NewColor.G == 0)
        NewColor.G = 1;

    if(NewColor.B == 0)
        NewColor.B = 1;

    return Chr(0x1B)$Chr(NewColor.R)$Chr(NewColor.G)$Chr(NewColor.B);
}

defaultproperties
{
     bEnableTeamColoredDeaths=True
}
