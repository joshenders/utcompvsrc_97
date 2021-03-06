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
class NewNet_ShockRifle extends UTComp_ShockRifle
	HideDropDown
	CacheExempt;

var TimeStamp T;
var MutUTComp M;

struct ReplicatedRotator
{
    var int Yaw;
    var int Pitch;
};

struct ReplicatedVector
{
    var float X;
    var float Y;
    var float Z;
};

replication
{
    reliable if( Role<ROLE_Authority )
        NewNet_ServerStartFire,NewNet_OldServerStartFire;
    unreliable if(bDemoRecording)
        SpawnBeamEffect;
}

function DisableNet()
{
    NewNet_ShockBeamFire(FireMode[0]).bUseEnhancedNetCode = false;
    NewNet_ShockBeamFire(FireMode[0]).PingDT = 0.00;
}

//// client only ////
simulated event ClientStartFire(int Mode)
{
    if(Level.NetMode!=NM_Client || !class'BS_xPlayer'.static.UseNewNet() || NewNet_ShockBeamFire(FireMode[Mode]) == None)
        super.ClientStartFire(mode);
    else
        NewNet_ClientStartFire(mode);
}

simulated event NewNet_ClientStartFire(int Mode)
{
    local ReplicatedRotator R;
    local ReplicatedVector V;
    local vector Start;
    local float stamp;

    if ( Pawn(Owner).Controller.IsInState('GameEnded') || Pawn(Owner).Controller.IsInState('RoundEnded') )
        return;
    if (Role < ROLE_Authority)
    {
        if (AltReadyToFire(Mode) && StartFire(Mode))
        {
            if(!ReadyToFire(Mode))
            {
                if(T==None)
                    foreach DynamicActors(class'TimeStamp', T)
                         break;
                Stamp = T.ClientTimeStamp;
                NewNet_OldServerStartFire(Mode,Stamp);
                return;
            }
            R.Pitch = Pawn(Owner).Controller.Rotation.Pitch;
            R.Yaw = Pawn(Owner).Controller.Rotation.Yaw;
            STart=Pawn(Owner).Location + Pawn(Owner).EyePosition();

            V.X = Start.X;
            V.Y = Start.Y;
            V.Z = Start.Z;

            if(T==None)
                foreach DynamicActors(class'TimeStamp', T)
                     break;
            Stamp = T.ClientTimeStamp;

            NewNet_ShockBeamFire(FireMode[mode]).DoInstantFireEffect();
            NewNet_ServerStartFire(Mode, stamp, R, V);
        }
    }
    else
    {
        StartFire(Mode);
    }
}

simulated function bool AltReadyToFire(int Mode)
{
    local int alt;
    local float f;

    //There is a very slight descynchronization error on the server
    // with weapons due to differing deltatimes which accrues to a pretty big
    // error if people just hold down the button...
    // This will never cause the weapon to actually fire slower
    f = 0.015;

    if(!ReadyToFire(Mode))
        return false;

    if ( Mode == 0 )
        alt = 1;
    else
        alt = 0;

    if ( ((FireMode[alt] != FireMode[Mode]) && FireMode[alt].bModeExclusive && FireMode[alt].bIsFiring)
		|| !FireMode[Mode].AllowFire()
		|| (FireMode[Mode].NextFireTime > Level.TimeSeconds + FireMode[Mode].PreFireTime - f) )
    {
        return false;
    }

	return true;
}

function NewNet_ServerStartFire(byte Mode, float ClientTimeStamp, ReplicatedRotator R, ReplicatedVector V/*, bool bBelievesHit, ReplicatedVector BelievedHLDelta, Actor A, vector HN, vector HL*/)
{
	if ( (Instigator != None) && (Instigator.Weapon != self) )
	{
		if ( Instigator.Weapon == None )
			Instigator.ServerChangedWeapon(None,self);
		else
			Instigator.Weapon.SynchronizeWeapon(self);
		return;
	}

	if(M==None)
        foreach DynamicActors(class'MutUTComp', M)
	        break;

    NewNet_ShockBeamFire(FireMode[Mode]).PingDT = M.ClientTimeStamp - ClientTimeStamp + 1.75*M.AverDT;
    NewNet_ShockBeamFire(FireMode[Mode]).bUseEnhancedNetCode = true;
    if ( (FireMode[Mode].NextFireTime <= Level.TimeSeconds + FireMode[Mode].PreFireTime)
		&& StartFire(Mode) )
    {
        FireMode[Mode].ServerStartFireTime = Level.TimeSeconds;
        FireMode[Mode].bServerDelayStartFire = false;
        NewNet_ShockBeamFire(FireMode[Mode]).SavedVec.X = V.X;
        NewNet_ShockBeamFire(FireMode[Mode]).SavedVec.Y = V.Y;
        NewNet_ShockBeamFire(FireMode[Mode]).SavedVec.Z = V.Z;
        NewNet_ShockBeamFire(FireMode[Mode]).SavedRot.Yaw = R.Yaw;
        NewNet_ShockBeamFire(FireMode[Mode]).SavedRot.Pitch = R.Pitch;
        NewNet_ShockBeamFire(FireMode[Mode]).bUseReplicatedInfo=IsReasonable(NewNet_ShockBeamFire(FireMode[Mode]).SavedVec);
    }
    else if ( FireMode[Mode].AllowFire() )
    {
        FireMode[Mode].bServerDelayStartFire = true;
	}
	else
		ClientForceAmmoUpdate(Mode, AmmoAmount(Mode));
}

function NewNet_OldServerStartFire(byte Mode, float ClientTimeStamp)
{
    if(M==None)
        foreach DynamicActors(class'MutUTComp', M)
	        break;
    NewNet_ShockBeamFire(FireMode[Mode]).PingDT = M.ClientTimeStamp - ClientTimeStamp + 1.75*M.AverDT;
    NewNet_ShockBeamFire(FireMode[Mode]).bUseEnhancedNetCode = true;
    ServerStartFire(mode);
}

function bool IsReasonable(Vector V)
{
    local vector LocDiff;
    local float clErr;

    if(Owner == none || Pawn(Owner) == none)
        return true;

    LocDiff = V - (Pawn(Owner).Location + Pawn(Owner).EyePosition());
    clErr = (LocDiff dot LocDiff);

    return clErr < 750.0;
}

simulated function SpawnBeamEffect(vector HitLocation, vector HitNormal, vector Start, rotator Dir, int reflectnum)
{
    local ShockBeamEffect Beam;

    if(bClientDemoNetFunc)
    {
        Start.Z = Start.Z - 64.0;
    }
    Beam = Spawn(class'NewNet_Client_ShockBeamEffect',,, Start, Dir);
    if (ReflectNum != 0) Beam.Instigator = None; // prevents client side repositioning of beam start
       Beam.AimAt(HitLocation, HitNormal);
}


DefaultProperties
{
    FireModeClass(0)=class'UTCompvSrc.NewNet_ShockBeamFire'
    FireModeClass(1)=class'UTCompvSrc.NewNet_ShockProjFire'
    PickupClass=Class'UTCompvSrc.NewNet_ShockRiflePickup'
}
