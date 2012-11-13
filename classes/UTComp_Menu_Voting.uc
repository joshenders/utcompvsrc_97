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

class UTComp_Menu_Voting extends UTComp_Menu_MainMenu;

var automated GUIButton bu_GameTypeMenu, bu_MapChangeMenu, bu_UTCompSettingsMenu;

var automated GUILabel l_VotingLabel;

function bool InternalOnClick(GUIComponent C)
{
    switch(C)
    {
        case bu_GameTypeMenu:  PlayerOwner().ClientReplaceMenu("UTCompvSrc.UTComp_Menu_Voting_GameType"); break;
        case bu_MapChangeMenu:  PlayerOwner().ClientReplaceMenu("UTCompvSrc.UTComp_Menu_Voting_Map");  break;
        case bu_UTCompSettingsMenu:  PlayerOwner().ClientReplaceMenu("UTCompvSrc.UTComp_Menu_Voting_Settings");    break;
    }
    Blehz();
    return super.InternalOnClick(C);
}

event Opened(guicomponent sender)
{
    Super.Opened(sender);

   Blehz();
}

function Blehz()
{
        local UTComp_ServerReplicationInfo RepInfo;

    foreach PlayerOwner().DynamicActors(class'UTComp_ServerReplicationInfo', RepInfo)
         break;
    if(RepInfo.bEnableMapVoting==False || RepInfo.bEnableVoting==False)
        bu_MapChangeMenu.DisableMe();
    else
        bu_MapChangeMenu.EnableMe();
    if(RepInfo.bEnableVoting==False)
        bu_UTCompSettingsMenu.DisableMe();
    else
        bu_UTCompSettingsMenu.EnableMe();
    if(RepInfo.bEnableMapVoting==False || RepInfo.bEnableVoting==False || RepInfo.bEnableGameTypeVoting==False)
        bu_GameTypeMenu.DisableMe();
    else
        bu_GameTypeMenu.EnableMe();
}

defaultproperties
{
     Begin Object Class=GUIButton Name=GameTypeButton
         Caption="Gametype"
		WinWidth=0.180000
		WinHeight=0.123437
		WinLeft=0.312500
		WinTop=0.572916
         OnClick=UTComp_Menu_Voting.InternalOnClick
         OnKeyEvent=GameTypeButton.InternalOnKeyEvent
     End Object
     bu_GameTypeMenu=GUIButton'UTCompvSrc.UTComp_Menu_Voting.GameTypeButton'

     Begin Object Class=GUIButton Name=MapChangeButton
         Caption="Change Map"
		WinWidth=0.373751
		WinHeight=0.123437
		WinLeft=0.315625
		WinTop=0.449999
         OnClick=UTComp_Menu_Voting.InternalOnClick
         OnKeyEvent=MapChangeButton.InternalOnKeyEvent
     End Object
     bu_MapChangeMenu=GUIButton'UTCompvSrc.UTComp_Menu_Voting.MapChangeButton'

     Begin Object Class=GUIButton Name=UTCompSettingsButton
         Caption="Settings"
		WinWidth=0.180000
		WinHeight=0.123437
		WinLeft=0.512501
		WinTop=0.572916
         OnClick=UTComp_Menu_Voting.InternalOnClick
         OnKeyEvent=UTCompSettingsButton.InternalOnKeyEvent
     End Object
     bu_UTCompSettingsMenu=GUIButton'UTCompvSrc.UTComp_Menu_Voting.UTCompSettingsButton'

     Begin Object class=GUILabel Name=DemnoHeadingLabel
        Caption="------- Select your voting type -------"
        TextColor=(B=0,G=200,R=230)
		WinWidth=1.000000
		WinHeight=0.060000
		WinLeft=0.281250
		WinTop=0.385000
     End Object
     l_VotingLabel=GUILabel'DemnoHeadingLabel'

}
