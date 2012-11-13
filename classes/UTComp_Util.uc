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

class UTComp_Util extends xUtil;

simulated static function UTComp_PRI GetUTCompPRI(PlayerReplicationInfo PRI)
{
    local LinkedReplicationInfo lPRI;

    if(PRI.CustomReplicationInfo==None)
        return None;  //shouldn't happen

    if(UTComp_PRI(PRI.CustomReplicationInfo)!=None)
    {
        return UTComp_PRI(PRI.CustomReplicationInfo);
    }

    for(lPRI=PRI.CustomReplicationInfo.NextReplicationInfo; lPRI!=None; lPRI=lPRI.NextReplicationInfo)
    {
        if(UTComp_PRI(lPRI)!=None)
            return UTComp_PRI(lPRI);
    }
    return none;
}

static function string MakeColorCode(color NewColor)
{
    // Text colours use 1 as 0.
    if(NewColor.R == 0)
        NewColor.R = 1;
    else if(NewColor.R == 10)
        NewColor.R = 9;
    else
        NewColor.R = Min(250, NewColor.R);

    if(NewColor.G == 0)
        NewColor.G = 1;
    else if(NewColor.G == 10)
        NewColor.G = 9;
    else
        NewColor.G = Min(250, NewColor.G);

    if(NewColor.B == 0)
        NewColor.B = 1;
    else if(NewColor.B == 10)
        NewColor.B = 9;
    else
        NewColor.B = Min(250, NewColor.B);

    return Chr(0x1B)$Chr(NewColor.R)$Chr(NewColor.G)$Chr(NewColor.B);
}

simulated static function bool InStrNonCaseSensitive(String S, string S2)
{                                //S2 in S
    local int i;
    for(i=0; i<=(Len(S)-Len(S2)); i++)
    {
        if(Mid(S, i, Len(s2))~=S2)
            return true;
    }
    return false;
}

simulated static function UTComp_PRI GetUTCompPRIFor(Controller C)
{
    if(C.PlayerReplicationInfo!=None)
        return GetUTCompPRI(C.PlayerReplicationInfo);
    return none;
}

simulated static function UTComp_PRI GetUTCompPRIForPawn(Pawn P)
{
    if(P.PlayerReplicationInfo!=None)
        return GetUTCompPRI(P.PlayerReplicationInfo);
    else if(P.Controller!=None)
        return GetUTCompPRIFor(P.Controller);
    return none;
}

defaultproperties
{
}
