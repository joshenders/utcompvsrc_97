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
class NewNet_AssaultRifle extends UTComp_AssaultRifle
	HideDropDown
	CacheExempt;

var TimeStamp T;
var MutUTComp M;

const MAX_PROJECTILE_FUDGE = 0.075;

replication
{
    reliable if( Role<ROLE_Authority )
        NewNet_ServerStartFire;
    unreliable if(Role == Role_Authority)
        DispatchClientEffect;
}

function DisableNet()
{
    NewNet_AssaultFire(FireMode[0]).bUseEnhancedNetCode = false;
    NewNet_AssaultFire(FireMode[0]).PingDT = 0.00;
    NewNet_AssaultGrenade(FireMode[1]).bUseEnhancedNetCode = false;
    NewNet_AssaultGrenade(FireMode[1]).PingDT = 0.00;
}

//// client only ////
simulated event ClientStartFire(int Mode)
{
    if(Level.NetMode!=NM_Client || !class'BS_xPlayer'.static.UseNewNet())
        super.ClientStartFire(mode);
    else
        NewNet_ClientStartFire(mode);
}

simulated event NewNet_ClientStartFire(int Mode)
{
    if ( Pawn(Owner).Controller.IsInState('GameEnded') || Pawn(Owner).Controller.IsInState('RoundEnded') )
        return;
    if (Role < ROLE_Authority)
    {
        if (StartFire(Mode))
        {
            if(T==None)
                foreach DynamicActors(class'TimeStamp', T)
                     break;

            NewNet_ServerStartFire(mode, T.ClientTimeStamp);
        }
    }
    else
    {
        StartFire(Mode);
    }
}

function NewNet_ServerStartFire(byte Mode, float ClientTimeStamp)
{
    if(M==None)
        foreach DynamicActors(class'MutUTComp', M)
	        break;

    if(NewNet_AssaultFire(FireMode[Mode])!=None)
    {
        NewNet_AssaultFire(FireMode[Mode]).PingDT = M.ClientTimeStamp - ClientTimeStamp + 1.75*M.AverDT;
        NewNet_AssaultFire(FireMode[Mode]).bUseEnhancedNetCode = true;
    }
    else if(NewNet_AssaultGrenade(FireMode[Mode])!=None)
    {
        NewNet_AssaultGrenade(FireMode[Mode]).PingDT = FMin(M.ClientTimeStamp - ClientTimeStamp + 1.75*M.AverDT, MAX_PROJECTILE_FUDGE);
        NewNet_AssaultGrenade(FireMode[Mode]).bUseEnhancedNetCode = true;
    }

    ServerStartFire(Mode);
}


simulated function DispatchClientEffect(Vector V, rotator R)
{
    if(Level.NetMode != NM_Client)
        return;
    Spawn(class'LinkProjectile',,,V,R);
}

DefaultProperties
{
    FireModeClass(0)=class'UTCompvSrc.NewNet_AssaultFire'
    FireModeClass(1)=class'UTCompvSrc.NewNet_AssaultGrenade'
    PickupClass=Class'UTCompvSrc.NewNet_AssaultRiflePickup'
}
