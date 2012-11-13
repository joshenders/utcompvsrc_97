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

class UTComp_Menu_AutoDemoSS extends UTComp_Menu_MainMenu;

var automated moCheckBox ch_AutoDemo;
var automated moCheckBox ch_AutoSS;

var automated GUIComboBox co_DemoMask;
var automated GUIComboBox co_SSMask;


var automated GUILabel l_AutoDemoMask;
var automated GUILabel l_AutoSSMask;

var automated GUILabel l_SSHeading, l_DemoHeading;


function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    Super.InitComponent(myController,MyOwner);

    ch_AutoDemo.Checked(class'BS_xPlayer'.default.bEnableUTCompAutoDemorec);
    ch_AutoSS.Checked(class'BS_xPlayer'.default.bEnableAutoScreenshot);

    co_DemoMask.AddItem(class'BS_xPlayer'.default.DemoRecordingMask);

    co_SSMask.AddItem(class'BS_xPlayer'.default.ScreenShotMask);

    DisableStuff();
}

function DisableStuff()
{
    if(!ch_AutoDemo.IsChecked())
        co_DemoMask.DisableMe();
    else
        co_DemoMask.EnableMe();
    if(!ch_AutoSS.IsChecked())
        co_SSMask.DisableMe();
    else
        co_SSMask.EnableMe();
}


function InternalOnChange( GUIComponent C )
{
    switch(C)
    {
        case co_SSMask:   class'BS_xPlayer'.default.ScreenShotMask=co_SSMask.GetText(); break;
        case co_DemoMask:   class'BS_xPlayer'.default.DemoRecordingMask=co_DemoMask.GetText(); break;
        case ch_AutoDemo:   class'BS_xPlayer'.default.bEnableUTCompAutoDemorec=ch_AutoDemo.IsChecked(); break;
        case ch_AutoSS:   class'BS_xPlayer'.default.bEnableAutoScreenshot=ch_AutoSS.IsChecked(); break;
    }
    BS_xPlayer(PlayerOwner()).MakeSureSaveConfig();
    class'BS_xPlayer'.Static.StaticSaveConfig();
    DisableStuff();
}

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
    if (Key == 0x1B)
        return false;
    class'BS_xPlayer'.default.ScreenShotMask=co_SSMask.GetText();
    class'BS_xPlayer'.default.DemoRecordingMask=co_DemoMask.GetText();
    BS_xPlayer(PlayerOwner()).MakeSureSaveConfig();
    class'BS_xPlayer'.Static.StaticSaveConfig();
}

defaultproperties
{
     Begin Object Class=moCheckBox Name=AutoDemoCheck
         Caption="Automatically record a demo of each match."
         OnCreateComponent=AutoDemoCheck.InternalOnCreateComponent
		WinWidth=0.740000
		WinHeight=0.030000
		WinLeft=0.140000
		WinTop=0.412083
         OnChange=UTComp_Menu_AutoDemoSS.InternalOnChange
     End Object
     ch_AutoDemo=moCheckBox'UTCompvSrc.UTComp_Menu_AutoDemoSS.AutoDemoCheck'

     Begin Object Class=moCheckBox Name=AutoSSCheck
         Caption="Automatically take a screenshot at the end of each match."
         OnCreateComponent=AutoSSCheck.InternalOnCreateComponent
		WinWidth=0.740000
		WinHeight=0.030000
		WinLeft=0.140000
		WinTop=0.589168
         OnChange=UTComp_Menu_AutoDemoSS.InternalOnChange
     End Object
     ch_AutoSS=moCheckBox'UTCompvSrc.UTComp_Menu_AutoDemoSS.AutoSSCheck'

     Begin Object Class=GUIComboBox Name=AutoDemoInput
		WinWidth=0.320000
		WinHeight=0.035000
		WinLeft=0.437500
		WinTop=0.460000
         OnChange=UTComp_Menu_AutoDemoSS.InternalOnChange
         OnKeyEvent=UTComp_Menu_AutoDemoSS.InternalOnKeyEvent
     End Object
     co_DemoMask=GUIComboBox'UTCompvSrc.UTComp_Menu_AutoDemoSS.AutoDemoInput'

     Begin Object Class=GUIComboBox Name=AutoSSInput
		WinWidth=0.320000
		WinHeight=0.035000
		WinLeft=0.437500
		WinTop=0.645418
         OnChange=UTComp_Menu_AutoDemoSS.InternalOnChange
         OnKeyEvent=UTComp_Menu_AutoDemoSS.InternalOnKeyEvent
     End Object
     co_SSMask=GUIComboBox'UTCompvSrc.UTComp_Menu_AutoDemoSS.AutoSSInput'

     Begin Object Class=GUILabel Name=DemoMaskLabel
         Caption="Demo Mask:"
         TextColor=(B=255,G=255,R=255)
		WinWidth=1.000000
		WinHeight=0.060000
		WinLeft=0.225000
		WinTop=0.450000
     End Object
     l_AutoDemoMask=GUILabel'UTCompvSrc.UTComp_Menu_AutoDemoSS.DemoMaskLabel'

     Begin Object Class=GUILabel Name=SSMaskLabel
         Caption="Screenshot Mask:"
         TextColor=(B=255,G=255,R=255)
		WinWidth=1.000000
		WinHeight=0.060000
		WinLeft=0.225000
		WinTop=0.632918
     End Object
     l_AutoSSMask=GUILabel'UTCompvSrc.UTComp_Menu_AutoDemoSS.SSMaskLabel'

     Begin Object Class=GUILabel Name=SSHeadingLabel
        Caption="--- Auto Screenshot ---"
        TextColor=(B=0,G=200,R=230)
		WinWidth=1.000000
		WinHeight=0.060000
		WinLeft=0.342188
		WinTop=0.514167
     End Object
     l_SSHeading=GUILabel'UTCompvSrc.UTComp_Menu_AutoDemoSS.SSHeadingLabel'

     Begin Object class=GUILabel Name=DemnoHeadingLabel
        Caption="--- Auto Demo Recording---"
        TextColor=(B=0,G=200,R=230)
		WinWidth=1.000000
		WinHeight=0.060000
		WinLeft=0.326563
		WinTop=0.347500
     End Object
     l_DemoHeading=GUILabel'DemnoHeadingLabel'

}
