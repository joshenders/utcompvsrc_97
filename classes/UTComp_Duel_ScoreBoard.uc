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

class UTComp_Duel_ScoreBoard extends UTComp_ScoreBoard;

var UTComp_ServerReplicationInfo repinfo;

function ArrangeSpecs(out PlayerReplicationInfo PRI[MAXPLAYERS])
{
    local int i,j;

    if(RepInfo==None)
       foreach DynamicActors(class'UTComp_ServerReplicationInfo', RepInfo)
          break;
    if(repinfo==none)
       return;
    for(i=0; i<ArrayCount(PRI); i++)
       PRI[i]=None;
    for(i=0; i<ArrayCount(repInfo.LinePRI); i++)
    {
       if(repInfo.LinePRI[i]==None)
       {
          j=i;
          break;
       }
       PRI[i]=RepInfo.LinePRI[i];
    }
    for(i=0; i<j; i++)
    {
       PRI[j-i-1]=RepInfo.LinePRI[i];
    }
}

function DrawSpecs(Canvas C, PlayerReplicationInfo PRI, int i)
{
    local string DrawText;
    local float BoxSizeX, BoxSizeY;
    local float StartPosX, StartPosY;
    local float bordersize;
    local UTComp_PRI uPRI;

    if(C.SizeX<630)
        return;
    C.StrLen(" 100% / 100%", BoxSizeX, BoxSizeY);
    StartPosX=C.ClipX-BoxSizeX*1.25;
    StartPosY=(C.ClipY*0.9150-BoxSizeY);
    bordersize=1.0;

    if(PRI==None)
    {
        DrawText="Line";
        C.SetPos(StartPosX, StartPosY-(BoxSizeY+BorderSize)*(i-1)-BorderSize);
        C.DrawTileStretched(material'Engine.WhiteTexture',BoxSizeX,BorderSize);
    }
    else
    {
        DrawText=PRI.PlayerName;
        uPRI=Class'UTComp_Util'.static.GetUTCompPRI(PRI);
    }

    if(uPRI==None || uPRI.CoachTeam==255)
        C.SetDrawColor(10,10,10,155);
    else if(uPRI.CoachTeam==0)
        C.SetDrawColor(250,0,0,155);
    else if(uPRI.CoachTeam==1)
        C.SetDrawColor(0,0,250,155);

    C.SetPos(StartPosX, StartPosY-(BoxSizeY+BorderSize)*i);
    C.DrawTileStretched(material'Engine.WhiteTexture', BoxSizeX, BoxSizeY+BorderSize);
    C.SetDrawColor(255,255,255,255);
    C.DrawTextJustified(DrawText, 1, StartPosX, StartPosY-(BoxSizeY+BorderSize)*i, StartPosX+BoxSizeX,  StartPosY-(BoxSizeY+BorderSize)*i+BoxSizeY);
}


DefaultProperties
{

}
